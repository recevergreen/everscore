import QtQuick
import QtQuick.Window

Window {
    id: projectionWindow
    width: 1024
    height: 768
    visible: false
    title: "Projection"
    color: "black"

    property var controller_prop: null

    Shortcut {
        sequence: "Esc"
        onActivated: {
            if (controller_prop) {
                controller_prop.toggleProjection(false);
            }
        }
    }

    Connections {
        target: controller_prop
        function onImageUpdated() {
            // Appending a changing value forces the image to reload from the provider
            viewportClone.source = "image://projection/viewport?" + new Date().getTime();
        }
        function onCloseRequested() {
            projectionWindow.close();
        }
    }

    Image {
        id: viewportClone
        anchors.fill: parent
        source: "image://projection/viewport"
        fillMode: Image.PreserveAspectFit
        cache: false
    }
}
