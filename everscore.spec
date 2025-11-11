# everscore.spec
import os, PySide6
from PyInstaller.utils.hooks import collect_submodules, collect_data_files

block_cipher = None

# Grab all PySide6 data (includes Qt plugins). QML often needs extra help:
pyside6_datas = collect_data_files('PySide6', include_py_files=False)

# Explicitly include the Qt/QML tree:
qml_dir = os.path.join(os.path.dirname(PySide6.__file__), "Qt", "qml")
pyside6_datas += [(qml_dir, "PySide6/Qt/qml")]

# Your app data:
app_datas = [
    ('main.qml', '.'),
    ('media', 'media'),
]

hidden = collect_submodules('serial') + ['serial.tools.list_ports']

a = Analysis(
    ['everscore.py'],
    pathex=[],
    binaries=[],
    datas=pyside6_datas + app_datas,
    hiddenimports=hidden,
    noarchive=False,
)

exe = EXE(
    a.pure, a.scripts, a.binaries, a.zipfiles, a.datas,
    name='Everscore',
    console=False,
    icon='everscore.icns',
)

app = BUNDLE(
    exe,
    name='Everscore.app',
    icon='everscore.icns',
    bundle_identifier='com.rainmultimedia.everscore',
    info_plist={
        'NSHighResolutionCapable': True,
        'CFBundleName': 'Everscore',
        'CFBundleDisplayName': 'Everscore',
        'CFBundleShortVersionString': '1.0.0',
        'CFBundleVersion': '1.0.0',
        'LSMinimumSystemVersion': '11.0',
    },
)