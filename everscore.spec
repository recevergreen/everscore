# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['everscore.py'],
    pathex=['/Users/kady/Projects/everscore/everscore'],
    binaries=[],
    datas=[
        ('main.qml', '.'),
        ('media', 'media'),
        ('/opt/homebrew/lib/python3.13/site-packages/PySide6/Qt/plugins/platforms', 'platforms'),
        ('/opt/homebrew/lib/python3.13/site-packages/PySide6/Qt/plugins/multimedia', 'multimedia'),
        ('/opt/homebrew/lib/python3.13/site-packages/PySide6/Qt/plugins/imageformats', 'imageformats'),
    ],
    hiddenimports=[
        'serial',
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
    [],
    exclude_binaries=True,
    name='everscore',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='everscore',
)
app = BUNDLE(
    coll,
    name='everscore.app',
    icon='icon.icns',
    bundle_identifier='com.evergreen.everscore',
)
