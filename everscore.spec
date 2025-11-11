# everscore.spec
# PyInstaller >= 5.x/6.x
from PyInstaller.utils.hooks import collect_submodules
from PyInstaller.building.build_main import Analysis, PYZ, EXE, BUNDLE
from PyInstaller.building.datastruct import Tree
import os

block_cipher = None

app_name = "everscore"
bundle_id = "org.rain.everscore"   # change if you have a registered ID
icon_path = "assets/everscore.icns"  # <-- put your .icns here (required for mac app icon)

# Add your project root so relative paths resolve while building
pathex = [os.path.abspath(".")]

# Data to ship inside the bundle
# - main.qml at the app base dir
# - media/ directory as a resource directory
datas = [
    ("main.qml", "."),            # e.g. dist/everscore.app/.../main.qml
    Tree("media", prefix="media") # e.g. dist/everscore.app/.../media/...
]

# Hidden imports that PyInstaller sometimes misses
hiddenimports = (
    collect_submodules("serial") +        # pyserial
    collect_submodules("consoles") +      # your consoles.sports.Basketball
    [
        "PySide6.QtQml",
        "PySide6.QtQuick",
        "PySide6.QtGui",
        "PySide6.QtCore",
    ]
)

# Lean on the built-in Qt hooks; don’t force extra plugin groups unless needed.
# If you find a plugin missing, you can add hooksconfig={"qt_plugins": ["platforms","imageformats", ...]}
a = Analysis(
    ["everscore.py"],
    pathex=pathex,
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},   # add qt_plugins here if you discover a missing plugin
    runtime_hooks=[],
    excludes=[],
    noarchive=False
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

# Windowed app (no console)
exe = EXE(
    a.scripts,
    pyz,
    name=app_name,
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,           # GUI app
    disable_windowed_traceback=False,
    argv_emulation=False,    # leave False; you parse args yourself
)

# Create the .app bundle; rely on Analysis to pull in Qt frameworks.
app = BUNDLE(
    exe,
    name=f"{app_name}.app",
    icon=icon_path,                 # must be .icns
    bundle_identifier=bundle_id,
    info_plist={
        "CFBundleDisplayName": app_name,
        "CFBundleName": app_name,
        "NSHighResolutionCapable": True,
        # If you need network perms prompts, entitlements come at codesign time, not here.
    },
)