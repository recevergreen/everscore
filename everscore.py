#!/usr/bin/env python3
"""
Virtual Scoreboard Client
--------------------------
Displays a virtual Daktronics-style basketball scoreboard in QML.

Two operating modes are supported:

SEND     –  Read the game state from the physical scoreboard over USB-serial
                                                                                                and broadcast that state on the network as JSON over UDP.

RECEIVE  –  Listen for JSON scoreboard packets on the network and drive the
                                                                                                on-screen scoreboard with the received data.

Usage:
                                python everscore.py --mode send     # default
                                python everscore.py --mode receive  # network listener
"""

from __future__ import annotations

import argparse
import json
import os
import socket
import sys
import threading
from typing import Any

import serial.tools.list_ports
from consoles.sports import Basketball
from PySide6.QtCore import QObject, QTimer, Signal, Slot
from PySide6.QtGui import QGuiApplication, QCloseEvent
from PySide6.QtQuick import QQuickItem
from PySide6.QtQml import QQmlApplicationEngine

# Event to signal shutdown to background threads
_shutdown_event = threading.Event()


def no_op(*args, **kwargs):
    """A no-operation function to silence callbacks during shutdown."""
    pass


# --------------------------------------------------------------------- #
#  Helper: figure out whether the UI is currently in “automatic” mode
# --------------------------------------------------------------------- #
def is_auto_mode() -> bool:
    """
    Interrogate the QML scene and return True when the “Automatic” switch
    is checked. If the switch or window is not yet available, falls back to True.
    """
    try:
        windows = QGuiApplication.allWindows()
        if not windows:
            return True
        root_obj: QObject = windows[0]
        sw: QObject | None = root_obj.findChild(QObject, "manualSwitch")  # type: ignore
        if sw is not None:
            return not bool(sw.property("checked"))
    except Exception:
        pass  # Fallback on any error
    return True  # Safest default


# --------------------------------------------------------------------- #
#  Helper: Get local IP address
# --------------------------------------------------------------------- #
def get_local_ip() -> str:
    """Get the local IP address of the machine."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Doesn't have to be reachable
        s.connect(("10.255.255.255", 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = "127.0.0.1"
    finally:
        s.close()
    return IP


def find_prolific_port() -> str | None:
    """
    Scan serial ports and return the first PL2303/Prolific device, if any.
    """
    for port in serial.tools.list_ports.comports():
        if (
            "pl2303" in (port.description or "").lower()
            or "prolific" in (port.manufacturer or "").lower()
        ):
            return port.device
    return None


# --------------------------------------------------------------------------- #
# Qt signal bridges for thread-safe communication
# --------------------------------------------------------------------------- #
class ScoreUpdater(QObject):
    """Updates the main scoreboard GUI."""

    updateScore = Signal(dict)


class SerialDataManager(QObject):
    """Handles data coming from the serial thread."""

    data_received = Signal(dict)


class UdpDataManager(QObject):
    """Handles data coming from the UDP thread."""

    packet_received = Signal(str, str)  # payload, ip_address


class AppController(QObject):
    @Slot()
    def prepareToQuit(self):
        """This slot is called from QML when the window is closing."""
        print("Shutdown sequence initiated from QML. Arming failsafe exit.")
        # Use a Python threading.Timer, which does not depend on the Qt event loop.
        # This guarantees that os._exit will be called even if the Qt loop is blocked.
        threading.Timer(0.5, lambda: os._exit(0)).start()


# --------------------------------------------------------------------------- #
# Main application
# --------------------------------------------------------------------------- #
def main() -> None:
    # --------------------------------------------------------------------- #
    # Parse CLI arguments
    # --------------------------------------------------------------------- #
    parser = argparse.ArgumentParser(description="Virtual Basketball Scoreboard")
    parser.add_argument(
        "--mode", choices=("send", "receive"), default="send", help="Operating mode."
    )
    parser.add_argument(
        "--host",
        default="255.255.255.255",
        help="Destination for 'send' mode, bind address for 'receive' mode.",
    )
    parser.add_argument("--port", type=int, default=54545, help="UDP port.")
    args = parser.parse_args()

    # --------------------------------------------------------------------- #
    # Prepare networking
    # --------------------------------------------------------------------- #
    udp_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    dest_addr: tuple[str, int] | None = None
    basketball_instance = None
    send_thread = None

    if args.mode == "send":
        if args.host.endswith(".255") or args.host == "255.255.255.255":
            udp_sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        dest_addr = (args.host, args.port)
    else:  # receive
        bind_addr = args.host if args.host != "255.255.255.255" else "0.0.0.0"
        try:
            udp_sock.bind((bind_addr, args.port))
            print(f"📡 Listening for scoreboard data on UDP {bind_addr}:{args.port}")
        except OSError as e:
            print(f"❌ Failed to bind UDP socket on {bind_addr}:{args.port}: {e}")
            sys.exit(1)

    # --------------------------------------------------------------------- #
    # Initialise Qt/QML scene
    # --------------------------------------------------------------------- #
    app = QGuiApplication(sys.argv)
    app.setQuitOnLastWindowClosed(True)

    engine = QQmlApplicationEngine()

    # Create and register the AppController
    app_controller = AppController()
    engine.rootContext().setContextProperty("appController", app_controller)

    engine.quit.connect(app.quit)
    engine.load("main.qml")

    if not engine.rootObjects():
        print("❌ Failed to load QML")
        sys.exit(1)

    root = engine.rootObjects()[0]

    # --------------------------------------------------------------------- #
    # Shutdown Logic
    # --------------------------------------------------------------------- #
    def on_quit():
        """Perform quick, non-blocking cleanup."""
        print("aboutToQuit signal received. Disconnecting callback.")
        _shutdown_event.set()
        if basketball_instance:
            basketball_instance.on_update = no_op

    app.aboutToQuit.connect(on_quit)

    # --------------------------------------------------------------------- #
    # Expose properties to QML
    # --------------------------------------------------------------------- #
    root.setProperty("receiveMode", args.mode == "receive")
    root.setProperty("localIpAddress", get_local_ip())

    # --------------------------------------------------------------------- #
    # Get QML objects
    # --------------------------------------------------------------------- #
    basketballDigits: QQuickItem | None = root.findChild(QQuickItem, "basketballDigits")
    sourceIpInput: QQuickItem | None = root.findChild(QQuickItem, "sourceIpInput")

    # --------------------------------------------------------------------- #
    # Signal handlers / slots (now running in the main GUI thread)
    # --------------------------------------------------------------------- #
    score_updater = ScoreUpdater()
    score_updater.updateScore.connect(
        lambda data: handle_score_update(data, basketballDigits)
    )

    @Slot(dict)
    def handle_serial_data(data):
        """Handles data from the serial port thread."""
        if is_auto_mode():
            score_updater.updateScore.emit(data)
        if dest_addr and not _shutdown_event.is_set():
            try:
                udp_sock.sendto(json.dumps(data).encode(), dest_addr)
            except OSError as e:
                if not _shutdown_event.is_set():
                    print(f"⚠️  Failed to send UDP packet: {e}")

    @Slot(str, str)
    def handle_udp_packet(payload_str, ip_addr):
        """Handles packets from the UDP listener thread."""
        target_ip = ""
        if sourceIpInput:
            target_ip = sourceIpInput.property("text")

        # print(f"[Debug] Received packet from {ip_addr}. Target IP is '{target_ip}'.")

        if target_ip and ip_addr != target_ip:
            # print("[Debug] IP does not match. Ignoring packet.")
            return
        try:
            state = json.loads(payload_str)
            if isinstance(state, dict) and is_auto_mode():
                score_updater.updateScore.emit(state)
        except json.JSONDecodeError:
            print("⚠️  Received invalid JSON packet, ignoring.")

    # --------------------------------------------------------------------- #
    # Mode-specific worker threads
    # --------------------------------------------------------------------- #
    if args.mode == "send":
        port = find_prolific_port() or "/dev/cu.PL2303-00001014"
        print(f"🔌 Opening scoreboard serial port: {port}")
        try:
            basketball = Basketball(port)
            basketball_instance = basketball
            serial_manager = SerialDataManager()
            basketball.on_update = serial_manager.data_received.emit
            serial_manager.data_received.connect(handle_serial_data)
            send_thread = threading.Thread(target=basketball.export, daemon=True)
            send_thread.start()
        except Exception as e:
            print(f"❌ Failed to open serial port {port}: {e}")
            sys.exit(1)
    else:  # receive
        udp_manager = UdpDataManager()
        udp_manager.packet_received.connect(handle_udp_packet)

        def receive_loop():
            udp_sock.settimeout(1.0)
            while not _shutdown_event.is_set():
                try:
                    payload, addr = udp_sock.recvfrom(8192)
                    udp_manager.packet_received.emit(payload.decode(), addr[0])
                except socket.timeout:
                    continue
                except OSError:
                    return

        threading.Thread(target=receive_loop, daemon=True).start()

    # --------------------------------------------------------------------- #
    # Final setup and execution
    # --------------------------------------------------------------------- #
    sys.exit(app.exec())


def handle_score_update(state: dict, basketballDigits: QQuickItem):
    """The actual GUI update logic."""
    if not basketballDigits:
        return

    def to_int(val, default=0):
        try:
            return int(val)
        except (TypeError, ValueError):
            return default

    root = basketballDigits.window()
    if not root:
        return

    # Find clock items dynamically
    minuteTensItem = root.findChild(QQuickItem, "minuteTens")
    minuteOnesItem = root.findChild(QQuickItem, "minuteOnes")
    secondTensItem = root.findChild(QQuickItem, "secondTens")
    secondOnesItem = root.findChild(QQuickItem, "secondOnes")
    fastTensItem = root.findChild(QQuickItem, "fastTens")
    fastOnesItem = root.findChild(QQuickItem, "fastOnes")
    fastTenthsItem = root.findChild(QQuickItem, "fastTenths")

    # Home score
    h = to_int(state.get("home_score"))
    basketballDigits.setProperty("homeHundredsDigit", (h // 100) % 10)
    basketballDigits.setProperty("homeTensDigit", (h // 10) % 10)
    basketballDigits.setProperty("homeOnesDigit", h % 10)

    # Visitor score
    v = to_int(state.get("visitor_score"))
    basketballDigits.setProperty("awayHundredsDigit", (v // 100) % 10)
    basketballDigits.setProperty("awayTensDigit", (v // 10) % 10)
    basketballDigits.setProperty("awayOnesDigit", v % 10)

    # Shot clock
    shot = to_int(state.get("shot"))
    basketballDigits.setProperty("shotTensDigit", (shot // 10) % 10)
    basketballDigits.setProperty("shotOnesDigit", shot % 10)

    # Team fouls
    home_fouls = to_int(state.get("home_fouls"))
    basketballDigits.setProperty("homeSmallTensDigit", (home_fouls // 10) % 10)
    basketballDigits.setProperty("homeSmallOnesDigit", home_fouls % 10)

    visitor_fouls = to_int(state.get("visitor_fouls"))
    basketballDigits.setProperty("awaySmallTensDigit", (visitor_fouls // 10) % 10)
    basketballDigits.setProperty("awaySmallOnesDigit", visitor_fouls % 10)

    # Period
    period_str = str(state.get("period", ""))
    period_num = next((int(ch) for ch in period_str if ch.isdigit()), 0)
    basketballDigits.setProperty("periodDigit", period_num)

    # Clock
    clock = state.get("clock", "0:00")
    clock_items = [
        minuteTensItem,
        minuteOnesItem,
        secondTensItem,
        secondOnesItem,
        fastTensItem,
        fastOnesItem,
        fastTenthsItem,
    ]
    if all(clock_items):
        if "." in clock:
            for item in (
                minuteTensItem,
                minuteOnesItem,
                secondTensItem,
                secondOnesItem,
            ):
                item.setProperty("visible", False)
            for item in (fastTensItem, fastOnesItem, fastTenthsItem):
                item.setProperty("visible", True)
            sec_part, tenths_part = clock.split(".", maxsplit=1)
            sec = to_int(sec_part)
            tenths = to_int(tenths_part[:1] if tenths_part else 0)
            basketballDigits.setProperty("fastTensDigit", (sec // 10) % 10)
            basketballDigits.setProperty("fastOnesDigit", sec % 10)
            basketballDigits.setProperty("fastTenthsDigit", tenths)
        elif ":" in clock:
            for item in (fastTensItem, fastOnesItem, fastTenthsItem):
                item.setProperty("visible", False)
            for item in (minuteOnesItem, secondTensItem, secondOnesItem):
                item.setProperty("visible", True)
            minutes, seconds = clock.split(":", maxsplit=1)
            seconds = seconds.zfill(2)
            if len(minutes) == 2:
                minuteTensItem.setProperty("visible", True)
                basketballDigits.setProperty("minuteTensDigit", to_int(minutes[0]))
            else:
                minuteTensItem.setProperty("visible", False)
            basketballDigits.setProperty("minuteOnesDigit", to_int(minutes[-1]))
            basketballDigits.setProperty("secondTensDigit", to_int(seconds[0]))
            basketballDigits.setProperty("secondOnesDigit", to_int(seconds[1]))


if __name__ == "__main__":
    main()
