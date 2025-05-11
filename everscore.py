#!/usr/bin/env python3
"""
Virtual Scoreboard Client
--------------------------
Connects to a physical Daktronics-compatible scoreboard over USB-serial (Prolific PL2303)
and renders a virtual scoreboard via QML, streaming frames over NDI.
"""

import sys
import numpy as np
import NDIlib as ndi
import serial.tools.list_ports
from threading import Thread
from consoles.sports import Basketball

from PySide6.QtCore import QTimer, Qt, QObject, Signal
from PySide6.QtGui import QGuiApplication, QImage
from PySide6.QtQuick import QQuickItem
from PySide6.QtQml import QQmlApplicationEngine

# Bridge to marshal scoreboard updates onto the Qt main thread
class ScoreUpdater(QObject):
	updateScore = Signal(dict)

score_updater = ScoreUpdater()


def find_prolific_port():
	"""
	Scan serial ports and return the first PL2303/Prolific device, if any.
	"""
	for port in serial.tools.list_ports.comports():
		desc = (port.description or "").lower()
		manf = (port.manufacturer or "").lower()
		if "pl2303" in desc or "prolific" in manf:
			return port.device
	return None


def main():
	# Initialize NDI
	if not ndi.initialize():
		print("❌ Failed to initialize NDI")
		sys.exit(1)
	settings = ndi.SendCreate()
	settings.ndi_name = "everscore"
	ndi_send = ndi.send_create(settings)
	if not ndi_send:
		print("❌ Could not create NDI sender – is the NDI runtime installed?")
		sys.exit(1)
	video_frame = ndi.VideoFrameV2()

	# Initialize Qt/QML
	app = QGuiApplication(sys.argv)
	engine = QQmlApplicationEngine()
	engine.load("main.qml")
	if not engine.rootObjects():
		print("❌ Failed to load QML")
		sys.exit(1)

	root = engine.rootObjects()[0]
	# Find QML items
	viewport           = root.findChild(QQuickItem, "viewportToStream")
	basketballDigits   = root.findChild(QQuickItem, "basketballDigits")
	minuteTensItem     = root.findChild(QQuickItem, "minuteTens")
	minuteOnesItem     = root.findChild(QQuickItem, "minuteOnes")
	secondTensItem     = root.findChild(QQuickItem, "secondTens")
	secondOnesItem     = root.findChild(QQuickItem, "secondOnes")
	fastTensItem       = root.findChild(QQuickItem, "fastTens")
	fastOnesItem       = root.findChild(QQuickItem, "fastOnes")
	fastTenthsItem     = root.findChild(QQuickItem, "fastTenths")

	if None in (viewport, basketballDigits,
				minuteTensItem, minuteOnesItem,
				secondTensItem, secondOnesItem,
				fastTensItem, fastOnesItem, fastTenthsItem):
		print("❌ Could not find required QML items")
		sys.exit(1)

	# Prepare NDI frame buffer
	w, h = int(viewport.width()), int(viewport.height())
	frame_buffer = np.empty((h, w, 4), dtype=np.uint8)
	video_frame.data = frame_buffer
	video_frame.xres = w
	video_frame.yres = h
	video_frame.FourCC = ndi.FOURCC_VIDEO_TYPE_BGRA
	video_frame.frame_rate_N = 24
	video_frame.frame_rate_D = 1

	# Frame grab + NDI send
	pending = []
	def grab_and_send():
		if not root.isVisible(): return
		gr = viewport.grabToImage()
		if not gr: return
		pending.append(gr)
		def on_ready():
			img = gr.image().convertToFormat(QImage.Format_ARGB32)
			img = img.scaled(w, h, Qt.IgnoreAspectRatio, Qt.FastTransformation)
			raw = img.bits()[:w*h*4]
			arr = np.frombuffer(raw, dtype=np.uint8).reshape(h, w, 4)
			frame_buffer[:] = arr
			ndi.send_send_video_v2(ndi_send, video_frame)
			gr.ready.disconnect(on_ready)
			pending.remove(gr)
		gr.ready.connect(on_ready)

	timer = QTimer()
	timer.timeout.connect(grab_and_send)
	timer.start(int(1000/24))

	# Score update handler with debug, fouls, period, and clock logic
	def handle_score_update(state):
		print("[DEBUG] handle_score_update:", state)
		def to_int(x, default=0):
			try: return int(x)
			except (TypeError, ValueError): return default

		# Home score
		h = to_int(state.get('home_score'))
		basketballDigits.setProperty("homeHundredsDigit", (h // 100) % 10)
		basketballDigits.setProperty("homeTensDigit",     (h // 10)  % 10)
		basketballDigits.setProperty("homeOnesDigit",     h % 10)

		# Visitor score
		v = to_int(state.get('visitor_score'))
		basketballDigits.setProperty("awayHundredsDigit", (v // 100) % 10)
		basketballDigits.setProperty("awayTensDigit",     (v // 10)  % 10)
		basketballDigits.setProperty("awayOnesDigit",     v % 10)

		# Shot clock
		shot = to_int(state.get('shot'))
		basketballDigits.setProperty("shotTensDigit",     (shot // 10) % 10)
		basketballDigits.setProperty("shotOnesDigit",     shot % 10)

		# Team fouls
		home_fouls = to_int(state.get('home_fouls'))
		basketballDigits.setProperty("homeSmallTensDigit", (home_fouls // 10) % 10)
		basketballDigits.setProperty("homeSmallOnesDigit", home_fouls % 10)
		visitor_fouls = to_int(state.get('visitor_fouls'))
		basketballDigits.setProperty("awaySmallTensDigit", (visitor_fouls // 10) % 10)
		basketballDigits.setProperty("awaySmallOnesDigit", visitor_fouls % 10)

		# Period (always treat as string)
		period_raw = state.get('period', '')
		print(f"[DEBUG] raw period: {period_raw!r} ({type(period_raw)})")
		period_str = str(period_raw)
		print(f"[DEBUG] coerced period_str: {period_str!r} ({type(period_str)})")
		period_num = 0
		for ch in period_str:
			if ch.isdigit():
				period_num = int(ch)
				break
		basketballDigits.setProperty("periodDigit", period_num)

		# Game clock formatting
		clock = state.get('clock', "0:00")
		if '.' in clock:
			# Fast clock: S.T
			minuteTensItem.setProperty("visible", False)
			minuteOnesItem.setProperty("visible", False)
			secondTensItem.setProperty("visible", False)
			secondOnesItem.setProperty("visible", False)
			fastTensItem.setProperty("visible", True)
			fastOnesItem.setProperty("visible", True)
			fastTenthsItem.setProperty("visible", True)
			parts = clock.split('.')
			sec = to_int(parts[0])
			tenths = to_int(parts[1][0] if len(parts) > 1 else 0)
			basketballDigits.setProperty("fastTensDigit",   (sec // 10) % 10)
			basketballDigits.setProperty("fastOnesDigit",    sec % 10)
			basketballDigits.setProperty("fastTenthsDigit",  tenths)
		elif ':' in clock:
			# Standard clock: M:SS or MM:SS
			fastTensItem.setProperty("visible", False)
			fastOnesItem.setProperty("visible", False)
			fastTenthsItem.setProperty("visible", False)
			parts = clock.split(':')
			m = parts[0]; s = parts[1] if len(parts) > 1 else '00'
			if len(m) == 2:
				minuteTensItem.setProperty("visible", True)
				basketballDigits.setProperty("minuteTensDigit", to_int(m) // 10)
			else:
				minuteTensItem.setProperty("visible", False)
			minuteOnesItem.setProperty("visible", True)
			secondTensItem.setProperty("visible", True)
			secondOnesItem.setProperty("visible", True)
			basketballDigits.setProperty("minuteOnesDigit", to_int(m) % 10)
			basketballDigits.setProperty("secondTensDigit",  to_int(s) // 10)
			basketballDigits.setProperty("secondOnesDigit",  to_int(s) % 10)
		else:
			# Fallback: hide all clock elements
			minuteTensItem.setProperty("visible", False)
			minuteOnesItem.setProperty("visible", False)
			secondTensItem.setProperty("visible", False)
			secondOnesItem.setProperty("visible", False)
			fastTensItem.setProperty("visible", False)
			fastOnesItem.setProperty("visible", False)
			fastTenthsItem.setProperty("visible", False)

	# Connect signal → handler and start reader
	score_updater.updateScore.connect(handle_score_update)
	port = find_prolific_port() or "/dev/cu.PL2303-00001014"
	print(f"🔌 Opening scoreboard serial port: {port}")
	basketball = Basketball(port)
	basketball.on_update = score_updater.updateScore.emit
	Thread(target=basketball.export, daemon=True).start()

	# Run and cleanup
	exit_code = app.exec()
	ndi.send_destroy(ndi_send)
	ndi.destroy()
	sys.exit(exit_code)

if __name__ == "__main__":
	main()
