#!/bin/bash
echo "Cleaning up PyInstaller files..."
rm -rf build/
rm -rf dist/
rm -f *.spec
echo "Done."
