# -*- mode: python ; coding: utf-8 -*-

# This is a PyInstaller spec file for Windows.

from PySide6.QtCore import QCoreApplication
from os.path import join, normpath

block_cipher = None

# Get the path to the PySide6 plugins
pyside6_plugins_path = ''
for path in QCoreApplication.libraryPaths():
    if "PySide6" in path:
        pyside6_plugins_path = path
        break

a = Analysis(
    ['everscore.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('main.qml', '.'),
        ('media', 'media'),
        (normpath(join(pyside6_plugins_path, 'platforms')), 'platforms'),
        (normpath(join(pyside6_plugins_path, 'multimedia')), 'multimedia'),
        (normpath(join(pyside6_plugins_path, 'imageformats')), 'imageformats'),
    ],
    hiddenimports=[
        'serial',
        'serial.tools.list_ports_osx',
        'serial.tools.list_ports_linux',
        'serial.tools.list_ports_windows',
        'serial.tools.list_ports_common',
        'PySide6.QtQml',
        'PySide6.QtCore',
        'PySide6.QtGui',
        'PySide6.QtQuick',
        'PySide6.QtMultimedia',
        'consoles',
        'PySide6.QtNetwork',
        'PySide6.QtWidgets',
        'PySide6.QtQuick.Controls',
        'PySide6.QtQuick.Layouts',
    ],
    hookspath=[],
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    name='everscore',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    # Set to False for production
    console=True,
    icon='icon.ico',
)
