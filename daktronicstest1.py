#!/usr/bin/env python3
"""
Virtual Scoreboard Client
--------------------------

Connects to a physical Daktronics-compatible scoreboard over USB-serial (Prolific PL2303)
and prints real-time updates to stdout.

Usage:
  1. Plug your PL2303-based cable into macOS, install/approve the driver.
  2. Run this script. It will auto-detect the serial port (if possible),
	 or fall back to the default path.
  3. Watch the console for scoreboard updates!
"""

import sys
import serial.tools.list_ports
from consoles.sports import Basketball

def find_prolific_port():
	"""
	Scan all serial ports and return the first one
	whose description or manufacturer mentions Prolific/PL2303.
	"""
	for port in serial.tools.list_ports.comports():
		desc = (port.description or "").lower()
		manf = (port.manufacturer or "").lower()
		if "pl2303" in desc or "prolific" in manf:
			return port.device
	return None

def main():
	# Try auto-detect; if not found, hard-code your known /dev/cu.* path here
	port = find_prolific_port() or "/dev/cu.PL2303-00001014"
	print(f"Opening scoreboard serial port: {port}")

	try:
		basketball = Basketball(port)
	except Exception as e:
		print(f"❌ Failed to open port {port}: {e}", file=sys.stderr)
		sys.exit(1)

	# Whenever the scoreboard state changes, print it.
	basketball.on_update = lambda state: print(state)

	# Start the read loop (this call will block until you Ctrl-C)
	try:
		basketball.export()
	except KeyboardInterrupt:
		print("\n🛑 Interrupted by user, exiting.")
	except Exception as e:
		print(f"\n❌ Runtime error: {e}", file=sys.stderr)

if __name__ == "__main__":
	main()