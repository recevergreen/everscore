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
import multiprocessing
import os
import os.path
import platform
import signal
import socket
import sys
import threading
from typing import Any

import serial.tools.list_ports
from consoles.sports import Basketball
from PySide6.QtCore import Property, QObject, QSettings, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QCloseEvent, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickItem

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
        if sw is None:
            print(
                "⚠️  is_auto_mode: Could not find 'manualSwitch' in QML. Defaulting to True (automatic mode)."
            )
            return True
        return not bool(sw.property("checked"))
    except Exception as e:
        print(f"❌ Error in is_auto_mode: {e}")
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
        sw: QObject | None = root_obj.findChild(QObject, "modeSwitch")
        if sw is None:
            print(
                "⚠️  is_send_mode: Could not find 'modeSwitch' in QML. Defaulting to False (receive mode)."
            )
            return False
        return bool(sw.property("checked"))
    except Exception as e:
        print(f"❌ Error in is_send_mode: {e}")
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


def find_serial_port() -> str | None:
    """
    Scan serial ports and return the first Prolific PL2303 device, if any.
    This function is OS-aware.
    """
    system = platform.system()
    for port in serial.tools.list_ports.comports():
        if system == "Windows":
            if "prolific" in (port.description or "").lower():
                return port.device
        else:  # macOS or Linux
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

        self.settings = QSettings("The Evergreen State College", "everscore")

    # --- Settings Properties ---

    _homeColorChanged = Signal()

    @Property(str, notify=_homeColorChanged)
    def homeColor(self):
        return self.settings.value("homeColor", "red")

    @homeColor.setter
    def homeColor(self, value):
        self.settings.setValue("homeColor", value)
        self._homeColorChanged.emit()

    _opponentColorChanged = Signal()

    @Property(str, notify=_opponentColorChanged)
    def opponentColor(self):
        return self.settings.value("opponentColor", "blue")

    @opponentColor.setter
    def opponentColor(self, value):
        self.settings.setValue("opponentColor", value)
        self._opponentColorChanged.emit()

    _opponentLogoChanged = Signal()

    @Property(str, notify=_opponentLogoChanged)
    def opponentLogo(self):
        return self.settings.value("opponentLogo", "")

    @opponentLogo.setter
    def opponentLogo(self, value):
        self.settings.setValue("opponentLogo", value)
        self._opponentLogoChanged.emit()

    _homeLogoChanged = Signal()

    @Property(str, notify=_homeLogoChanged)
    def homeLogo(self):
        return self.settings.value("homeLogo", "")

    @homeLogo.setter
    def homeLogo(self, value):
        self.settings.setValue("homeLogo", value)
        self._homeLogoChanged.emit()

    _homeNameChanged = Signal()

    @Property(str, notify=_homeNameChanged)
    def homeName(self):
        return self.settings.value("homeName", "HOME")

    @homeName.setter
    def homeName(self, value):
        self.settings.setValue("homeName", value)
        self._homeNameChanged.emit()

    _opponentNameChanged = Signal()

    @Property(str, notify=_opponentNameChanged)
    def opponentName(self):
        return self.settings.value("opponentName", "GUEST")

    @opponentName.setter
    def opponentName(self, value):
        self.settings.setValue("opponentName", value)
        self._opponentNameChanged.emit()

    _fontFamilyChanged = Signal()

    @Property(str, notify=_fontFamilyChanged)
    def fontFamily(self):
        return self.settings.value("fontFamily", "")

    @fontFamily.setter
    def fontFamily(self, value):
        self.settings.setValue("fontFamily", value)
        self._fontFamilyChanged.emit()

    _shotClockChanged = Signal()

    @Property(bool, notify=_shotClockChanged)
    def shotClock(self):
        return self.settings.value("shotClock", True, type=bool)

    @shotClock.setter
    def shotClock(self, value):
        self.settings.setValue("shotClock", value)
        self._shotClockChanged.emit()

    _showFoulsChanged = Signal()

    @Property(bool, notify=_showFoulsChanged)
    def showFouls(self):
        return self.settings.value("showFouls", True, type=bool)

    @showFouls.setter
    def showFouls(self, value):
        self.settings.setValue("showFouls", value)
        self._showFoulsChanged.emit()

    _logoChanged = Signal()

    @Property(bool, notify=_logoChanged)
    def logo(self):
        return self.settings.value("logo", False, type=bool)

    @logo.setter
    def logo(self, value):
        self.settings.setValue("logo", value)
        self._logoChanged.emit()

    _backgroundChanged = Signal()

    @Property(int, notify=_backgroundChanged)
    def background(self):
        return self.settings.value("background", 1, type=int)

    @background.setter
    def background(self, value):
        self.settings.setValue("background", value)
        self._backgroundChanged.emit()

    _manualModeChanged = Signal()

    @Property(bool, notify=_manualModeChanged)
    def manualMode(self):
        return self.settings.value("manualMode", False, type=bool)

    @manualMode.setter
    def manualMode(self, value):
        self.settings.setValue("manualMode", value)
        self._manualModeChanged.emit()

    _sendModeChanged = Signal()

    @Property(bool, notify=_sendModeChanged)
    def sendMode(self):
        return self.settings.value("sendMode", False, type=bool)

    @sendMode.setter
    def sendMode(self, value):
        self.settings.setValue("sendMode", value)
        self._sendModeChanged.emit()

    _sourceIpChanged = Signal()

    @Property(str, notify=_sourceIpChanged)
    def sourceIp(self):
        return self.settings.value("sourceIp", "10.20.67.92")

    @sourceIp.setter
    def sourceIp(self, value):
        self.settings.setValue("sourceIp", value)
        self._sourceIpChanged.emit()

    @Slot()
    def prepareToQuit(self):
        """This slot is called from QML when the window is closing."""
        print("Shutdown sequence initiated. Arming process group termination.")

        def kill_process():
            print("Failsafe timer fired. Terminating process.")
            try:
                if platform.system() == "Windows":
                    os.kill(os.getpid(), signal.SIGTERM)
                else:
                    os.killpg(os.getpgrp(), signal.SIGKILL)
            except Exception as e:
                print(f"Failed to kill process: {e}. Falling back to os._exit().")
                os._exit(1)

        threading.Timer(0.5, kill_process).start()

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
    # Suppress FFmpeg warnings
    os.environ["QT_LOGGING_RULES"] = "qt.multimedia.ffmpeg.warning=false"

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

    # Resolve path to QML file for PyInstaller
    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        # This is the path to the temporary folder where PyInstaller unpacks the app
        qml_file = os.path.join(sys._MEIPASS, "main.qml")
    else:
        # Running as a script
        qml_file = "main.qml"

    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        print("❌ Failed to load QML")
        sys.exit(1)
    root = engine.rootObjects()[0]
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
        port = find_serial_port()
        if not port:
            print("ℹ️ No Prolific serial port found. Serial input will be disabled.")
            return

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

    controlPanel = root.findChild(QObject, "controlPanel")
    if not controlPanel:
        return

    h = to_int(state.get("home_score"))
    controlPanel.setScoreDigits("home", h)

    v = to_int(state.get("visitor_score"))
    controlPanel.setScoreDigits("visitor", v)

    shot = to_int(state.get("shot"))
    basketballDigits.setProperty("shotTensDigit", (shot // 10) % 10)
    basketballDigits.setProperty("shotOnesDigit", shot % 10)

    home_fouls = to_int(state.get("home_fouls"))
    controlPanel.setFoulDigits("home", home_fouls)

    visitor_fouls = to_int(state.get("visitor_fouls"))
    controlPanel.setFoulDigits("visitor", visitor_fouls)

    period_str = str(state.get("period", ""))
    period_num = next((int(ch) for ch in period_str if ch.isdigit()), 0)
    basketballDigits.setProperty("periodDigit", period_num)

    clock = state.get("clock", "0:00")

    if controlPanel:
        new_clock_time_in_tenths = 0
        if "." in clock:
            parts = clock.split(".", 1)
            sec = to_int(parts[0])
            tenths = to_int(parts[1][:1]) if len(parts) > 1 and parts[1] else 0
            new_clock_time_in_tenths = sec * 10 + tenths
        elif ":" in clock:
            parts = clock.split(":", 1)
            minutes = to_int(parts[0])
            seconds = to_int(parts[1]) if len(parts) > 1 else 0
            new_clock_time_in_tenths = (minutes * 60 + seconds) * 10

        if is_auto_mode():
            if new_clock_time_in_tenths > 0:
                new_clock_time_in_tenths -= 1

        # Ensure clock doesn't go negative
        if new_clock_time_in_tenths < 0:
            new_clock_time_in_tenths = 0

        controlPanel.setProperty("clockTimeInTenths", new_clock_time_in_tenths)


if __name__ == "__main__":
    multiprocessing.freeze_support()
    main()
