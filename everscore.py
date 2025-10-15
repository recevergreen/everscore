#!/usr/bin/env python3
"""
Virtual Scoreboard Client
--------------------------
Displays a virtual Daktronics-style basketball scoreboard in QML.
The operating mode is controlled entirely by the switches in the UI.
"""

from __future__ import annotations

import argparse
import json
import os
import signal
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
#  UI Mode Interrogation
# --------------------------------------------------------------------- #
def is_auto_mode() -> bool:
    """
    Interrogate the QML scene and return True when the “Automatic” switch
    is unchecked. If the switch or window is not yet available, falls back to True.
    """
    try:
        windows = QGuiApplication.allWindows()
        if not windows:
            return True
        root_obj: QObject = windows[0]
        sw: QObject | None = root_obj.findChild(QObject, "manualSwitch")
        if sw is not None:
            return not bool(sw.property("checked"))
    except Exception:
        pass  # Fallback on any error
    return True  # Safest default


def is_send_mode() -> bool:
    """
    Interrogate the QML scene and return True when the “Send” switch
    is checked. If the switch or window is not yet available, falls back to False.
    """
    try:
        windows = QGuiApplication.allWindows()
        if not windows:
            return False
        root_obj: QObject = windows[0]
        sw: QObject | None = root_obj.findChild(QObject, "sendSwitch")
        if sw is not None:
            return bool(sw.property("checked"))
    except Exception:
        pass
    return False


# --------------------------------------------------------------------- #
#  Helper: Get local IP address
# --------------------------------------------------------------------- #
def get_local_ip() -> str:
    """Get the local IP address of the machine."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
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
# Qt signal bridges and controllers
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
    """Controller for handling UI events like quitting and manual updates."""

    def __init__(
        self,
        udp_sock: socket.socket,
        dest_addr: tuple[str, int],
        parent: QObject | None = None,
    ):
        super().__init__(parent)
        self._udp_sock = udp_sock
        self._dest_addr = dest_addr

    @Slot()
    def prepareToQuit(self):
        """This slot is called from QML when the window is closing."""
        print("Shutdown sequence initiated. Arming process group termination.")

        def kill_process_group():
            print("Failsafe timer fired. Terminating process group.")
            try:
                os.killpg(os.getpgrp(), signal.SIGKILL)
            except Exception as e:
                print(f"Failed to kill process group: {e}. Falling back to os._exit().")
                os._exit(1)

        threading.Timer(0.5, kill_process_group).start()

    @Slot()
    def sendManualUpdate(self):
        """Gathers state from QML and sends it over UDP if in manual+send mode."""
        if is_auto_mode() or not is_send_mode():
            return

        state = self._build_state_from_qml()
        if state and not _shutdown_event.is_set():
            try:
                self._udp_sock.sendto(json.dumps(state).encode(), self._dest_addr)
            except OSError as e:
                print(f"⚠️  Failed to send manual update: {e}")

    def _build_state_from_qml(self) -> dict:
        """Reconstructs the entire game state dictionary from QML properties."""
        state = {}
        try:
            windows = QGuiApplication.allWindows()
            if not windows:
                return {}
            root = windows[0]
            basketballDigits = root.findChild(QQuickItem, "basketballDigits")
            if not basketballDigits:
                return {}

            h = (
                basketballDigits.property("homeHundredsDigit") * 100
                + basketballDigits.property("homeTensDigit") * 10
                + basketballDigits.property("homeOnesDigit")
            )
            state["home_score"] = h

            v = (
                basketballDigits.property("awayHundredsDigit") * 100
                + basketballDigits.property("awayTensDigit") * 10
                + basketballDigits.property("awayOnesDigit")
            )
            state["visitor_score"] = v

            shot = basketballDigits.property(
                "shotTensDigit"
            ) * 10 + basketballDigits.property("shotOnesDigit")
            state["shot"] = shot

            hf = basketballDigits.property(
                "homeSmallTensDigit"
            ) * 10 + basketballDigits.property("homeSmallOnesDigit")
            state["home_fouls"] = hf

            vf = basketballDigits.property(
                "awaySmallTensDigit"
            ) * 10 + basketballDigits.property("awaySmallOnesDigit")
            state["visitor_fouls"] = vf

            state["period"] = basketballDigits.property("periodDigit")

            minuteTensItem = root.findChild(QQuickItem, "minuteTens")
            fastTenthsItem = root.findChild(QQuickItem, "fastTenths")

            if fastTenthsItem and fastTenthsItem.property("visible"):
                sec = basketballDigits.property(
                    "fastTensDigit"
                ) * 10 + basketballDigits.property("fastOnesDigit")
                tenths = basketballDigits.property("fastTenthsDigit")
                state["clock"] = f"{sec}.{tenths}"
            elif minuteTensItem:
                mins_val = 0
                if minuteTensItem.property("visible"):
                    mins_val += basketballDigits.property("minuteTensDigit") * 10
                mins_val += basketballDigits.property("minuteOnesDigit")
                secs_tens = basketballDigits.property("secondTensDigit")
                secs_ones = basketballDigits.property("secondOnesDigit")
                state["clock"] = f"{mins_val}:{secs_tens}{secs_ones}"
            else:
                state["clock"] = "0:00"
        except Exception as e:
            print(f"❌ Error building state from QML: {e}")
            return {}
        return state


# --------------------------------------------------------------------------- #
# Main application
# --------------------------------------------------------------------------- #
def main() -> None:
    # --------------------------------------------------------------------- #
    # Parse CLI arguments
    # --------------------------------------------------------------------- #
    parser = argparse.ArgumentParser(description="Virtual Basketball Scoreboard")
    parser.add_argument(
        "--host",
        default="255.255.255.255",
        help="Broadcast destination for 'send' mode.",
    )
    parser.add_argument("--port", type=int, default=54545, help="UDP port.")
    args = parser.parse_args()

    # --------------------------------------------------------------------- #
    # Unified Networking Setup
    # --------------------------------------------------------------------- #
    udp_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    udp_sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

    try:
        udp_sock.bind(("0.0.0.0", args.port))
        print(f"📡 Listening for scoreboard data on UDP 0.0.0.0:{args.port}")
    except OSError as e:
        print(f"❌ Failed to bind UDP socket on 0.0.0.0:{args.port}: {e}")
        sys.exit(1)

    send_host = "<broadcast>" if args.host == "255.255.255.255" else args.host
    dest_addr = (send_host, args.port)

    # --------------------------------------------------------------------- #
    # Initialise Qt/QML scene
    # --------------------------------------------------------------------- #
    app = QGuiApplication(sys.argv)
    app.setQuitOnLastWindowClosed(True)
    engine = QQmlApplicationEngine()

    app_controller = AppController(udp_sock, dest_addr)
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
        print("aboutToQuit signal received. Disconnecting callback.")
        _shutdown_event.set()

    app.aboutToQuit.connect(on_quit)

    # --------------------------------------------------------------------- #
    # Expose properties to QML
    # --------------------------------------------------------------------- #
    root.setProperty("localIpAddress", get_local_ip())

    # --------------------------------------------------------------------- #
    # Get QML objects for diagnostics
    # --------------------------------------------------------------------- #
    basketballDigits = root.findChild(QQuickItem, "basketballDigits")
    if not basketballDigits:
        print(
            "❌ Critical error: Could not find QML item with objectName 'basketballDigits'. UI will not update."
        )

    # --------------------------------------------------------------------- #
    # Signal handlers / slots
    # --------------------------------------------------------------------- #
    score_updater = ScoreUpdater()
    score_updater.updateScore.connect(
        lambda data: handle_score_update(data, basketballDigits)
    )

    @Slot(dict)
    def handle_serial_data(data):
        if not is_auto_mode():
            return

        score_updater.updateScore.emit(data)

        if is_send_mode() and not _shutdown_event.is_set():
            try:
                udp_sock.sendto(json.dumps(data).encode(), dest_addr)
            except OSError as e:
                if not _shutdown_event.is_set():
                    print(f"⚠️  Failed to send UDP packet: {e}")

    @Slot(str, str)
    def handle_udp_packet(payload_str, ip_addr):
        if is_send_mode() or not is_auto_mode():
            return

        sourceIpInput = root.findChild(QQuickItem, "sourceIpInput")
        target_ip = ""
        if sourceIpInput:
            target_ip = sourceIpInput.property("text")

        if target_ip and ip_addr != target_ip:
            return
        try:
            state = json.loads(payload_str)
            if isinstance(state, dict):
                score_updater.updateScore.emit(state)
        except json.JSONDecodeError:
            print("⚠️  Received invalid JSON packet, ignoring.")

    # --------------------------------------------------------------------- #
    # Always-on Worker Threads
    # --------------------------------------------------------------------- #
    serial_manager = SerialDataManager()
    serial_manager.data_received.connect(handle_serial_data)

    def serial_thread_target():
        port = find_prolific_port() or "/dev/cu.PL2303-00001014"
        print(f"🔌 Attempting to open scoreboard serial port: {port}")
        try:
            basketball = Basketball(port)
            basketball.on_update = serial_manager.data_received.emit
            # Block and read from the serial port until shutdown
            basketball.export()
        except Exception as e:
            print(
                f"❌ Serial port thread failed: {e}. Serial functionality will be disabled."
            )
        print("Serial thread finished.")

    threading.Thread(target=serial_thread_target, daemon=True).start()

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
                if not _shutdown_event.is_set():
                    print("UDP socket error in receive loop.")
                return
        print("UDP receive thread finished.")

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

    minuteTensItem = root.findChild(QQuickItem, "minuteTens")
    minuteOnesItem = root.findChild(QQuickItem, "minuteOnes")
    secondTensItem = root.findChild(QQuickItem, "secondTens")
    secondOnesItem = root.findChild(QQuickItem, "secondOnes")
    fastTensItem = root.findChild(QQuickItem, "fastTens")
    fastOnesItem = root.findChild(QQuickItem, "fastOnes")
    fastTenthsItem = root.findChild(QQuickItem, "fastTenths")

    h = to_int(state.get("home_score"))
    basketballDigits.setProperty("homeHundredsDigit", (h // 100) % 10)
    basketballDigits.setProperty("homeTensDigit", (h // 10) % 10)
    basketballDigits.setProperty("homeOnesDigit", h % 10)

    v = to_int(state.get("visitor_score"))
    basketballDigits.setProperty("awayHundredsDigit", (v // 100) % 10)
    basketballDigits.setProperty("awayTensDigit", (v // 10) % 10)
    basketballDigits.setProperty("awayOnesDigit", v % 10)

    shot = to_int(state.get("shot"))
    basketballDigits.setProperty("shotTensDigit", (shot // 10) % 10)
    basketballDigits.setProperty("shotOnesDigit", shot % 10)

    home_fouls = to_int(state.get("home_fouls"))
    basketballDigits.setProperty("homeSmallTensDigit", (home_fouls // 10) % 10)
    basketballDigits.setProperty("homeSmallOnesDigit", home_fouls % 10)

    visitor_fouls = to_int(state.get("visitor_fouls"))
    basketballDigits.setProperty("awaySmallTensDigit", (visitor_fouls // 10) % 10)
    basketballDigits.setProperty("awaySmallOnesDigit", visitor_fouls % 10)

    period_str = str(state.get("period", ""))
    period_num = next((int(ch) for ch in period_str if ch.isdigit()), 0)
    basketballDigits.setProperty("periodDigit", period_num)

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

    if all(i is not None for i in clock_items):
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
