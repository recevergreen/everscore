import QtQuick
import QtQuick.Window
import QtMultimedia
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects

Window {
    id: mainWindow
    visible: true

    property int lockedWidth: 960
    width: lockedWidth
    height: 540

    title: qsTr("everscore")
    color: "black"

    property int xanimationduration: 0
    property bool receiveMode: false
    property string localIpAddress: "127.0.0.1"

    onClosing: {
        // Call the Python slot to arm the failsafe timer
        appController.prepareToQuit();
    }

    ColorDialog {
        id: colorDialog
        title: "Select Opponent Color"
        selectedColor: appController.opponentColor
        onAccepted: {
            var newColor = colorDialog.selectedColor;
            if (newColor) {
                appController.opponentColor = newColor;
            }
        }
    }

    ColorDialog {
        id: homeColorDialog
        title: "Select Home Color"
        selectedColor: appController.homeColor
        onAccepted: {
            var newColor = homeColorDialog.selectedColor;
            if (newColor) {
                appController.homeColor = newColor;
            }
        }
    }

    FileDialog {
        id: opponentLogoDialog
        title: "Select Opponent Logo"
        onAccepted: {
            appController.opponentLogo = opponentLogoDialog.selectedFile;
        }
    }

    FileDialog {
        id: homeLogoDialog
        title: "Select Home Logo"
        onAccepted: {
            appController.homeLogo = homeLogoDialog.selectedFile;
        }
    }

    FontDialog {
        id: fontDialog
        title: "Select Font"
        onAccepted: {
            var newFont = fontDialog.selectedFont;
            appController.fontFamily = newFont.family;
        }
    }

    // animate any change to `lockedWidth`
    Behavior on lockedWidth {
        NumberAnimation {
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }

    // animate any change to `x`
    Behavior on x {
        NumberAnimation {
            duration: mainWindow.xanimationduration
            easing.type: Easing.InOutQuad
        }
    }

    MediaPlayer {
        id: player
        source: "media/splash.mp4"
        autoPlay: true
        videoOutput: videoOutput

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) {
                // this will trigger the Behavior above
                mainWindow.xanimationduration = 1000;
                mainWindow.lockedWidth = 1365;
                mainWindow.x = mainWindow.x - 202;
                mainInterface.visible = true;
            }
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
    }

    Rectangle {
        id: mainInterface
        visible: false
        width: 1365
        height: 540
        anchors.left: parent.left

        Rectangle {
            id: viewportToStream
            objectName: "viewportToStream"
            width: 960
            height: 540
            color: "forestgreen"
            // your streamable content goes here

            Rectangle {
                id: basketballView
                anchors.fill: parent

                Image {
                    id: background
                    anchors.fill: parent
                    source: ["media/volleyballbg.png", "media/basketballbg.png", "media/wrestlingbg.png"][appController.background]
                    fillMode: Image.PreserveAspectFit
                }

                // Sprites and Graphics for Basketball:

                Item {
                    id: basketballDigits
                    objectName: "basketballDigits"

                    // design canvas in 1920x1080, scaled down to fit basketballView
                    width: 1920
                    height: 1080
                    transformOrigin: Item.TopLeft
                    scale: basketballView.width / width

                    // digit properties exposed to Python
                    property int awayHundredsDigit: 0
                    property int awayTensDigit: 0
                    property int awayOnesDigit: 0
                    property int awaySmallTensDigit: 0
                    property int awaySmallOnesDigit: 0
                    property int fastTensDigit: 0
                    property int fastOnesDigit: 0
                    property int fastTenthsDigit: 0
                    property int homeHundredsDigit: 0
                    property int homeTensDigit: 0
                    property int homeOnesDigit: 0
                    property int homeSmallTensDigit: 0
                    property int homeSmallOnesDigit: 0
                    property int minuteTensDigit: 0
                    property int minuteOnesDigit: 0
                    property int periodDigit: controlPanel.period
                    property int playerFoulDigit: 0
                    property int playerOnesDigit: 0
                    property int playerTensDigit: 0
                    property int secondTensDigit: 0
                    property int secondOnesDigit: 0
                    property int shotTensDigit: 0
                    property int shotOnesDigit: 0
                    property int wgHundredsDigit: 0
                    property int wgTensDigit: 0
                    property int wgOnesDigit: 0

                    Image {
                        id: homeLogo
                        x: 38
                        y: 29
                        width: 1051
                        height: 319
                        source: appController.homeLogo
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.5
                    }

                    Image {
                        id: opponentLogo
                        x: 38
                        y: 363
                        width: 1048
                        height: 324
                        source: appController.opponentLogo
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.5
                    }

                    Rectangle {
                        id: homeColorOverlay
                        x: 38
                        y: 30
                        width: 1048
                        height: 315
                        color: appController.homeColor
                        opacity: 0.5
                    }

                    Rectangle {
                        id: opponentColorOverlay
                        x: 38
                        y: 363
                        width: 1048
                        height: 324
                        color: appController.opponentColor
                        opacity: 0.5
                    }

                    Image {
                        id: clockSeparator
                        x: controlPanel.isFastClockActive ? 1523 : 1409
                        y: 833
                        width: 65
                        height: 163
                    }

                    // single-frame PNG: no clipping needed
                    Item {
                        id: awayHundreds
                        opacity: 0
                        x: 1089
                        y: 361
                        width: 161
                        height: 325

                        Image {
                            source: "media/awayHundreds.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                        }
                    }

                    // ten-frame strips: clip by parent.height & parent.width
                    Item {
                        id: awayTens
                        objectName: "awayTens"
                        opacity: 0
                        x: 1263
                        y: 361
                        width: 200
                        height: 325

                        Image {
                            source: "media/awayTens.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.awayTensDigit, width, height)
                        }
                    }

                    Item {
                        id: awayOnes
                        objectName: "awayOnes"
                        x: 1470
                        y: 362
                        width: 225
                        height: 324

                        Image {
                            source: "media/awayOnes.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.awayOnesDigit, width, height)
                        }
                    }

                    Item {
                        id: awaySmallTens
                        objectName: "awaySmallTens"
                        opacity: 0
                        x: 1695
                        y: 361
                        width: 114
                        height: 195

                        Image {
                            source: "media/awaySmallTens.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.awaySmallTensDigit, width, height)
                        }
                    }

                    Item {
                        id: awaySmallOnes
                        objectName: "awaySmallOnes"
                        x: 1810
                        y: 361
                        width: 110
                        height: 196

                        Image {
                            source: "media/awaySmallOnes.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.awaySmallOnesDigit, width, height)
                        }
                    }

                    Item {
                        id: fastTens
                        objectName: "fastTens"
                        x: 1077
                        y: 716
                        width: 208
                        height: 339

                        Image {
                            source: "media/fastTens.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.fastTensDigit, width, height)
                        }
                    }

                    Item {
                        id: fastOnes
                        objectName: "fastOnes"
                        x: 1291
                        y: 717
                        width: 218
                        height: 338

                        Image {
                            source: "media/fastOnes.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.fastOnesDigit, width, height)
                        }
                    }

                    Item {
                        id: fastTenths
                        objectName: "fastTenths"
                        x: 1603
                        y: 715
                        width: 224
                        height: 340

                        Image {
                            source: "media/fastTenths.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.fastTenthsDigit, width, height)
                        }
                    }

                    Item {
                        id: homeHundreds
                        objectName: "homeHundreds"
                        opacity: 0
                        x: 1089
                        y: 20
                        width: 177
                        height: 324

                        Image {
                            source: "media/homeHundreds.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                        }
                    }

                    Item {
                        id: homeTens
                        objectName: "homeTens"
                        opacity: 0
                        x: 1260
                        y: 20
                        width: 201
                        height: 323

                        Image {
                            source: "media/homeTens.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.homeTensDigit, width, height)
                        }
                    }

                    Item {
                        id: homeOnes
                        objectName: "homeOnes"
                        x: 1465
                        y: 21
                        width: 230
                        height: 322

                        Image {
                            source: "media/homeOnes.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.homeOnesDigit, width, height)
                        }
                    }

                    Item {
                        id: homeSmallTens
                        objectName: "homeSmallTens"
                        opacity: 0
                        x: 1697
                        y: 21
                        width: 115
                        height: 194

                        Image {
                            source: "media/homeSmallTens.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.homeSmallTensDigit, width, height)
                        }
                    }

                    Item {
                        id: homeSmallOnes
                        objectName: "homeSmallOnes"
                        x: 1810
                        y: 21
                        width: 110
                        height: 196

                        Image {
                            source: "media/homeSmallOnes.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.homeSmallOnesDigit, width, height)
                        }
                    }

                    Item {
                        id: minuteTens
                        objectName: "minuteTens"
                        x: 1016
                        y: 756
                        width: 184
                        height: 252

                        Image {
                            source: "media/minuteTens.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.minuteTensDigit, width, height)
                        }
                    }

                    Item {
                        id: minuteOnes
                        objectName: "minuteOnes"
                        x: 1206
                        y: 759
                        width: 185
                        height: 245

                        Image {
                            source: "media/minuteOnes.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.minuteOnesDigit, width, height)
                        }
                    }

                    Item {
                        id: period
                        objectName: "period"
                        x: 165
                        y: 818
                        width: 181
                        height: 220

                        Image {
                            source: "media/period.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.periodDigit, width, height)
                        }
                    }

                    Item {
                        id: playerFoul
                        objectName: "playerFoul"
                        visible: false
                        x: 778
                        y: 848
                        width: 114
                        height: 151

                        Image {
                            source: "media/playerFoul.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.playerFoulDigit, width, height)
                        }
                    }

                    Item {
                        id: playerOnes
                        objectName: "playerOnes"
                        visible: false
                        x: 631
                        y: 848
                        width: 111
                        height: 149

                        Image {
                            source: "media/playerOnes.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.playerOnesDigit, width, height)
                        }
                    }

                    Item {
                        id: playerTens
                        objectName: "playerTens"
                        visible: false
                        x: 514
                        y: 848
                        width: 120
                        height: 152

                        Image {
                            source: "media/playerTens.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.playerTensDigit, width, height)
                        }
                    }

                    Item {
                        id: secondTens
                        objectName: "secondTens"
                        x: 1487
                        y: 762
                        width: 189
                        height: 248

                        Image {
                            source: "media/secondTens.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.secondTensDigit, width, height)
                        }
                    }

                    Item {
                        id: secondOnes
                        objectName: "secondOnes"
                        x: 1674
                        y: 761
                        width: 193
                        height: 235

                        Image {
                            source: "media/secondOnes.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.secondOnesDigit, width, height)
                        }
                    }

                    Item {
                        id: shotTens
                        objectName: "shotTens"
                        visible: shotClockSwitch.checked
                        x: 524
                        y: 763
                        width: 185
                        height: 240

                        Image {
                            source: "media/shotTens.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.shotTensDigit, width, height)
                        }
                    }

                    Item {
                        id: shotOnes
                        objectName: "shotOnes"
                        visible: shotClockSwitch.checked
                        x: 712
                        y: 767
                        width: 176
                        height: 236

                        Image {
                            source: "media/shotOnes.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.shotOnesDigit, width, height)
                        }
                    }

                    Image {
                        id: coverFoulsImage
                        x: 1695
                        y: 0
                        width: 225
                        height: 687
                        source: "media/coverfouls.png"
                        visible: !showFoulsSwitch.checked
                    }

                    Image {
                        id: speedyKickImage
                        x: 491
                        y: 720
                        width: 423
                        height: 322
                        source: logoSwitch.checked ? "media/uenlogo.png" : "media/speedykick.png"
                        visible: !shotClockSwitch.checked
                    }

                    Image {
                        id: wrestlingClockCover
                        source: "media/wrestlingclockcover.png"
                        x: 1010
                        y: 720
                        width: 858
                        height: 320
                        visible: appController.isWrestlingMode
                    }

                    Item {
                        id: wgHundreds
                        x: 1183
                        y: 805
                        width: 177
                        height: 235
                        opacity: 0
                        visible: appController.isWrestlingMode && !controlPanel.isHeavyweight
                        Image {
                            source: "media/wgHundreds.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.wgHundredsDigit, width, height)
                        }
                    }

                    Item {
                        id: wgTens
                        x: 1361
                        y: 805
                        width: 172
                        height: 235
                        opacity: 0
                        visible: appController.isWrestlingMode && !controlPanel.isHeavyweight
                        Image {
                            source: "media/wgTens.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.wgTensDigit, width, height)
                        }
                    }

                    Item {
                        id: wgOnes
                        x: 1533
                        y: 805
                        width: 179
                        height: 235
                        visible: appController.isWrestlingMode && !controlPanel.isHeavyweight
                        Image {
                            source: "media/wgOnes.png"
                            anchors.fill: parent
                            fillMode: Image.Stretch
                            sourceClipRect: Qt.rect(0, height * basketballDigits.wgOnesDigit, width, height)
                        }
                    }

                    Image {
                        id: heavyImage
                        source: "media/heavy.png"
                        x: 1010
                        y: 812
                        width: 858
                        height: 228
                        visible: appController.isWrestlingMode && controlPanel.isHeavyweight
                    }

                    Item {
                        x: 38
                        y: 29
                        width: 1051
                        height: 319
                        Text {
                            id: homeNameText
                            text: appController.fontFamily.toLowerCase().includes("serpentine") ? appController.homeName.toLowerCase() : appController.homeName
                            font.family: appController.fontFamily
                            anchors.fill: parent
                            anchors.leftMargin: 50
                            anchors.rightMargin: 50
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            font.bold: true
                            color: "white"
                            font.pixelSize: 200
                            minimumPixelSize: 10
                            fontSizeMode: Text.Fit
                            wrapMode: Text.WordWrap
                            lineHeight: 0.8
                        }
                    }

                    Item {
                        x: 38
                        y: 363
                        width: 1048
                        height: 324
                        Text {
                            id: opponentNameText
                            text: appController.fontFamily.toLowerCase().includes("serpentine") ? appController.opponentName.toLowerCase() : appController.opponentName
                            font.family: appController.fontFamily
                            anchors.fill: parent
                            anchors.leftMargin: 50
                            anchors.rightMargin: 50
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            font.bold: true
                            color: "white"
                            font.pixelSize: 200
                            minimumPixelSize: 10
                            fontSizeMode: Text.Fit
                            wrapMode: Text.WordWrap
                            lineHeight: 0.8
                        }
                    }
                }
            }
        }

        Rectangle {
            width: 405
            height: 540
            anchors.right: parent.right
            color: Application.styleHints.colorScheme === Qt.ColorScheme.Dark ? "#424242" : "white"

            RowLayout {
                id: topControlsRow
                spacing: 16
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 16
                }

                GroupBox {
                    id: controlModeGroup
                    title: "Control Mode"
                    Layout.fillHeight: true
                    rightPadding: 8
                    Column {
                        spacing: 4
                        Row {
                            spacing: 8
                            Switch {
                                id: manualSwitch
                                objectName: "manualSwitch"
                                onToggled: {
                                    appController.manualMode = checked;
                                    if (checked) {
                                        modeSwitch.checked = true; // Manual mode always sends
                                        appController.sendMode = true;
                                    }
                                    if (!checked) {
                                        // Switched to Automatic
                                        controlPanel.clockRunning = false;
                                    }
                                }
                            }
                            Label {
                                id: modeText
                                text: manualSwitch.checked ? "Manual" : "Automatic"
                                font.pixelSize: 18
                            }
                        }
                    }
                }

                GroupBox {
                    title: "Operating Mode"
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Column {
                        spacing: 4
                        Row {
                            spacing: 8
                            Switch {
                                id: modeSwitch
                                objectName: "modeSwitch"
                                enabled: !manualSwitch.checked // Listen is only available in Automatic mode
                                onToggled: appController.sendMode = checked
                            }
                            Label {
                                id: modeLabel
                                text: modeSwitch.checked ? "Send" : "Listen"
                                font.pixelSize: 18
                            }
                        }
                    }
                }

                Button {
                    id: settingsButton
                    checkable: true
                    checked: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    Layout.rightMargin: -7
                    Layout.bottomMargin: -6

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        color: "black"
                        opacity: 0.1
                        radius: 4
                        visible: Application.styleHints.colorScheme !== Qt.ColorScheme.Dark
                    }

                    Image {
                        source: "media/settings.svg"
                        width: parent.width * 0.6
                        height: parent.height * 0.6
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }

            Column {
                id: controlPanel
                objectName: "controlPanel"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.top: topControlsRow.bottom
                anchors.topMargin: 16
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 16
                spacing: 16

                property int homeScore: 0
                property int visitorScore: 0
                property int homeFouls: 0
                property int visitorFouls: 0
                property int period: 1
                readonly property bool isHeavyweight: (parseInt(appController.weightClass, 10) > 199) || (appController.weightClass.trim().length > 0 && appController.weightClass.trim().toLowerCase().startsWith("h"))

                property int clockTimeInTenths: 0
                property bool clockRunning: false

                onClockRunningChanged: {
                    if (!clockRunning && clockTimeInTenths <= 0) {
                        basketballDigits.fastTensDigit = 0;
                        basketballDigits.fastOnesDigit = 0;
                        basketballDigits.fastTenthsDigit = 0;
                    }
                }

                Component.onCompleted: {
                    updateClockDisplay();
                }

                // Read-only properties for display
                readonly property int clockCurrentTotalSeconds: Math.floor(controlPanel.clockTimeInTenths / 10)
                readonly property int clockCurrentMinutes: Math.floor(controlPanel.clockCurrentTotalSeconds / 60)
                readonly property int clockCurrentSeconds: controlPanel.clockCurrentTotalSeconds % 60
                readonly property int clockCurrentTenths: controlPanel.clockTimeInTenths % 10

                readonly property bool isFastClockActive: controlPanel.clockTimeInTenths < 600

                Timer {
                    id: clockTimer
                    interval: 100 // Run every 100ms for tenths of a second
                    repeat: true
                    // Only advance the clock in manual mode; automatic/serial mode should not tick locally.
                    running: controlPanel.clockRunning && manualSwitch.checked
                    onTriggered: {
                        if (countDownSwitch.checked) {
                            if (controlPanel.clockTimeInTenths > 0) {
                                controlPanel.clockTimeInTenths--;
                            } else {
                                controlPanel.clockRunning = false;
                            }
                        } else {
                            // Cap counting up at 99:59.9
                            if (controlPanel.clockTimeInTenths < 59999) {
                                controlPanel.clockTimeInTenths++;
                            } else {
                                controlPanel.clockRunning = false;
                            }
                        }
                    }
                }

                onClockTimeInTenthsChanged: {
                    updateClockDisplay();
                }

                function updateClockDisplay() {
                    var showFast = isFastClockActive;

                    // Set visibility for all clock components
                    minuteTens.visible = !showFast;
                    minuteOnes.visible = !showFast;
                    secondTens.visible = !showFast;
                    secondOnes.visible = !showFast;
                    fastTens.visible = showFast;
                    fastOnes.visible = showFast;
                    fastTenths.visible = showFast;
                    clockSeparator.visible = showFast || clockTimeInTenths > 0;
                    clockSeparator.source = showFast ? "media/decimalpoint.png" : "media/colon.png";

                    // Set digit values
                    if (showFast) {
                        var seconds = clockCurrentSeconds;
                        var tenths = clockCurrentTenths;
                        basketballDigits.fastTensDigit = Math.floor(seconds / 10) % 10;
                        basketballDigits.fastOnesDigit = seconds % 10;
                        basketballDigits.fastTenthsDigit = tenths;
                    } else {
                        var minutes = clockCurrentMinutes;
                        var seconds = clockCurrentSeconds;
                        basketballDigits.minuteTensDigit = Math.floor(minutes / 10) % 10;
                        basketballDigits.minuteOnesDigit = minutes % 10;
                        basketballDigits.secondTensDigit = Math.floor(seconds / 10) % 10;
                        basketballDigits.secondOnesDigit = seconds % 10;
                    }

                    appController.sendManualUpdate();

                    // Update UI text fields
                    if (clockRunning) {
                        clockMinutesInput.text = clockCurrentMinutes.toString().padStart(2, '0');
                        clockSecondsInput.text = clockCurrentSeconds.toString().padStart(2, '0');
                    }
                }

                function setScoreDigits(team, value) {
                    if (value < 0)
                        value = 0;
                    if (value > 999)
                        value = 999;
                    if (team === "home") {
                        homeHundreds.opacity = value >= 100 ? 1 : 0;
                        homeTens.opacity = value >= 10 ? 1 : 0;
                        basketballDigits.homeHundredsDigit = Math.floor(value / 100) % 10;
                        basketballDigits.homeTensDigit = Math.floor(value / 10) % 10;
                        basketballDigits.homeOnesDigit = value % 10;
                        homeScore = value;
                    } else {
                        awayHundreds.opacity = value >= 100 ? 1 : 0;
                        awayTens.opacity = value >= 10 ? 1 : 0;
                        basketballDigits.awayHundredsDigit = Math.floor(value / 100) % 10;
                        basketballDigits.awayTensDigit = Math.floor(value / 10) % 10;
                        basketballDigits.awayOnesDigit = value % 10;
                        visitorScore = value;
                    }
                }

                function setFoulDigits(team, value) {
                    if (value < 0)
                        value = 0;
                    if (value > 99)
                        value = 99;
                    if (team === "home") {
                        homeSmallTens.opacity = value >= 10 ? 1 : 0;
                        basketballDigits.homeSmallTensDigit = Math.floor(value / 10) % 10;
                        basketballDigits.homeSmallOnesDigit = value % 10;
                        homeFouls = value;
                    } else {
                        awaySmallTens.opacity = value >= 10 ? 1 : 0;
                        basketballDigits.awaySmallTensDigit = Math.floor(value / 10) % 10;
                        basketballDigits.awaySmallOnesDigit = value % 10;
                        visitorFouls = value;
                    }
                }

                function setPeriodDigit(value) {
                    if (value < 0)
                        value = 0;
                    if (value > 9)
                        value = 9;
                    basketballDigits.periodDigit = value;
                    controlPanel.period = value;
                }

                Column {
                    id: mainControls
                    width: parent.width
                    spacing: 16
                    visible: !settingsButton.checked

                    GroupBox {
                        title: "Network"
                        width: parent.width

                        StackLayout {
                            width: parent.width
                            currentIndex: modeSwitch.checked ? 0 : 1

                            Column {
                                spacing: 4
                                Label {
                                    text: "Broadcasting to network from:"
                                }
                                Label {
                                    text: mainWindow.localIpAddress
                                    font.bold: true
                                }
                            }
                            Column {
                                spacing: 4
                                Label {
                                    text: "Source IP Address"
                                }
                                TextField {
                                    id: sourceIpInput
                                    objectName: "sourceIpInput"
                                    width: parent.width
                                    text: appController.sourceIp
                                    placeholderText: "Leave empty to accept from any IP"
                                    onEditingFinished: appController.sourceIp = text
                                }
                            }
                        }
                    }

                    GroupBox {
                        title: "Team Names"
                        width: parent.width
                        visible: appController.isWrestlingMode && manualSwitch.checked
                        Column {
                            width: parent.width
                            spacing: 8
                            TextField {
                                placeholderText: "Home Name"
                                text: appController.homeName
                                onTextChanged: {
                                    if (appController.homeName !== text) {
                                        appController.homeName = text;
                                        appController.sendManualUpdate();
                                    }
                                }
                                width: parent.width
                            }
                            TextField {
                                placeholderText: "Away Name"
                                text: appController.opponentName
                                onTextChanged: {
                                    if (appController.opponentName !== text) {
                                        appController.opponentName = text;
                                        appController.sendManualUpdate();
                                    }
                                }
                                width: parent.width
                            }
                        }
                    }

                    GroupBox {
                        title: "Clock"
                        width: parent.width
                        visible: manualSwitch.checked && !appController.isWrestlingMode

                        Column {
                            spacing: 8
                            Row {
                                spacing: 8
                                TextField {
                                    id: clockMinutesInput
                                    width: 60
                                    placeholderText: "MM"
                                    validator: IntValidator {
                                        bottom: 0
                                        top: 99
                                    }
                                    text: "00"
                                    enabled: !controlPanel.clockRunning
                                    onEditingFinished: {
                                        controlPanel.clockTimeInTenths = (parseInt(text) * 60 + parseInt(clockSecondsInput.text)) * 10;
                                    }
                                }
                                Label {
                                    text: ":"
                                }
                                TextField {
                                    id: clockSecondsInput
                                    width: 60
                                    placeholderText: "SS"
                                    validator: IntValidator {
                                        bottom: 0
                                        top: 59
                                    }
                                    text: "00"
                                    enabled: !controlPanel.clockRunning
                                    onEditingFinished: {
                                        controlPanel.clockTimeInTenths = (parseInt(clockMinutesInput.text) * 60 + parseInt(text)) * 10;
                                    }
                                }
                                Button {
                                    id: startStopButton
                                    text: controlPanel.clockRunning ? "Stop" : "Start"
                                    onClicked: {
                                        if (!controlPanel.clockRunning) {
                                            // When starting, make sure clockTimeInTenths is up to date
                                            controlPanel.clockTimeInTenths = (parseInt(clockMinutesInput.text) * 60 + parseInt(clockSecondsInput.text)) * 10;
                                        }
                                        controlPanel.clockRunning = !controlPanel.clockRunning;
                                    }
                                }
                            }
                            Row {
                                spacing: 8
                                Switch {
                                    id: countDownSwitch
                                    checked: true // Default to count down
                                    enabled: !controlPanel.clockRunning
                                }
                                Label {
                                    text: countDownSwitch.checked ? "Counting Down" : "Counting Up"
                                }
                            }
                        }
                    }

                    GridLayout {
                        columns: 2
                        width: parent.width
                        columnSpacing: 16
                        rowSpacing: 16

                        GroupBox {
                            title: appController.homeScoreLabel
                            Layout.fillWidth: true
                            visible: manualSwitch.checked
                            Column {
                                spacing: 4
                                Row {
                                    spacing: 4
                                    Button {
                                        text: "▲"
                                        onClicked: {
                                            controlPanel.setScoreDigits("home", controlPanel.homeScore + 1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                    Button {
                                        text: "▼"
                                        onClicked: {
                                            controlPanel.setScoreDigits("home", controlPanel.homeScore - 1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                    Button {
                                        text: "⟲"
                                        onClicked: {
                                            controlPanel.setScoreDigits("home", 0);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                }
                            }
                        }

                        GroupBox {
                            title: appController.awayScoreLabel
                            Layout.fillWidth: true
                            visible: manualSwitch.checked
                            Column {
                                spacing: 4
                                Row {
                                    spacing: 4
                                    Button {
                                        text: "▲"
                                        onClicked: {
                                            controlPanel.setScoreDigits("visitor", controlPanel.visitorScore + 1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                    Button {
                                        text: "▼"
                                        onClicked: {
                                            controlPanel.setScoreDigits("visitor", controlPanel.visitorScore - 1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                    Button {
                                        text: "⟲"
                                        onClicked: {
                                            controlPanel.setScoreDigits("visitor", 0);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                }
                            }
                        }

                        GroupBox {
                            id: homeFoulsBox
                            title: appController.homeFoulsLabel
                            Layout.fillWidth: true
                            visible: manualSwitch.checked && showFoulsSwitch.checked
                            Column {
                                spacing: 4
                                Row {
                                    spacing: 4
                                    Button {
                                        text: "▲"
                                        onClicked: {
                                            controlPanel.setFoulDigits("home", controlPanel.homeFouls + 1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                    Button {
                                        text: "▼"
                                        onClicked: {
                                            controlPanel.setFoulDigits("home", controlPanel.homeFouls - 1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                    Button {
                                        text: "⟲"
                                        onClicked: {
                                            controlPanel.setFoulDigits("home", 0);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                }
                            }
                        }

                        GroupBox {
                            id: visitorFoulsBox
                            title: appController.awayFoulsLabel
                            Layout.fillWidth: true
                            visible: manualSwitch.checked && showFoulsSwitch.checked
                            Column {
                                spacing: 4
                                Row {
                                    spacing: 4
                                    Button {
                                        text: "▲"
                                        onClicked: {
                                            controlPanel.setFoulDigits("visitor", controlPanel.visitorFouls + 1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                    Button {
                                        text: "▼"
                                        onClicked: {
                                            controlPanel.setFoulDigits("visitor", controlPanel.visitorFouls - 1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                    Button {
                                        text: "⟲"
                                        onClicked: {
                                            controlPanel.setFoulDigits("visitor", 0);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                }
                            }
                        }

                        GroupBox {
                            title: "Period"
                            Layout.fillWidth: true
                            Layout.columnSpan: appController.isWrestlingMode ? 1 : 2
                            visible: manualSwitch.checked
                            Column {
                                spacing: 4
                                Row {
                                    spacing: 4
                                    Button {
                                        id: periodButton
                                        text: "▲"
                                        onClicked: {
                                            controlPanel.setPeriodDigit(controlPanel.period + 1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                    Button {
                                        text: "▼"
                                        onClicked: {
                                            controlPanel.setPeriodDigit(controlPanel.period - 1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                    Button {
                                        text: "⟲"
                                        onClicked: {
                                            controlPanel.setPeriodDigit(1);
                                            appController.sendManualUpdate();
                                        }
                                    }
                                }
                            }
                        }

                        GroupBox {
                            title: "Weight Class"
                            Layout.fillWidth: true
                            visible: appController.isWrestlingMode && manualSwitch.checked
                            TextField {
                                id: weightClassInput
                                placeholderText: "Enter weight class"
                                text: appController.weightClass
                                onTextChanged: {
                                    if (appController.weightClass !== text) {
                                        appController.weightClass = text;
                                        appController.sendManualUpdate();
                                    }
                                    var value = parseInt(text);
                                    if (isNaN(value) || value < 0) {
                                        value = 0;
                                    }
                                    if (value > 999) {
                                        value = 999;
                                    }

                                    wgHundreds.opacity = value >= 100 ? 1 : 0;
                                    wgTens.opacity = value >= 10 ? 1 : 0;

                                    basketballDigits.wgHundredsDigit = Math.floor(value / 100) % 10;
                                    basketballDigits.wgTensDigit = Math.floor(value / 10) % 10;
                                    basketballDigits.wgOnesDigit = value % 10;
                                }
                                implicitHeight: periodButton.height
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                background: Rectangle {
                                    radius: 2
                                    border.width: 1
                                    border.color: weightClassInput.activeFocus ? "orange" : "gray"
                                    color: Application.styleHints.colorScheme === Qt.ColorScheme.Dark ? "#333" : "#fff"
                                }
                            }
                        }
                    }
                }
                Column {
                    id: settingsControls
                    width: parent.width
                    spacing: 12
                    visible: settingsButton.checked

                    Row {
                        spacing: 16
                        Row {
                            spacing: 8
                            Label {
                                text: "Home Color"
                                font.pixelSize: 18
                            }
                            Button {
                                text: "Select"
                                onClicked: {
                                    homeColorDialog.open();
                                }
                            }
                        }
                        Row {
                            spacing: 8
                            Label {
                                text: "Home Logo"
                                font.pixelSize: 18
                            }
                            Button {
                                text: "Select"
                                onClicked: {
                                    homeLogoDialog.open();
                                }
                            }
                        }
                    }
                    Row {
                        spacing: 16
                        Row {
                            spacing: 8
                            Label {
                                text: "Away Color"
                                font.pixelSize: 18
                            }
                            Button {
                                text: "Select"
                                onClicked: {
                                    colorDialog.open();
                                }
                            }
                        }
                        Row {
                            spacing: 8
                            Label {
                                text: "Away Logo"
                                font.pixelSize: 18
                            }
                            Button {
                                text: "Select"
                                onClicked: {
                                    opponentLogoDialog.open();
                                }
                            }
                        }
                    }
                    Row {
                        spacing: 8
                        Item {
                            width: childrenRect.width
                            height: homeNameInput.height
                            Label {
                                text: "Home Name"
                                font.pixelSize: 18
                                anchors.centerIn: parent
                            }
                        }
                        TextField {
                            id: homeNameInput
                            placeholderText: "Enter Home Name"
                            text: appController.homeName
                            onTextChanged: {
                                if (appController.homeName !== text) {
                                    appController.homeName = text;
                                    appController.sendManualUpdate();
                                }
                            }
                        }
                        Item {
                            width: localNamesSwitch.width
                            height: homeNameInput.height
                            Switch {
                                id: localNamesSwitch
                                text: "Local"
                                checked: appController.localNames
                                onToggled: appController.localNames = checked
                                anchors.centerIn: parent
                            }
                        }
                    }
                    Row {
                        spacing: 8
                        Label {
                            text: "Away Name"
                            font.pixelSize: 18
                        }
                        TextField {
                            id: opponentNameInput
                            placeholderText: "Enter Opponent Name"
                            text: appController.opponentName
                            onTextChanged: {
                                if (appController.opponentName !== text) {
                                    appController.opponentName = text;
                                    appController.sendManualUpdate();
                                }
                            }
                        }
                    }
                    Row {
                        spacing: 8
                        Label {
                            text: "Team Name Font"
                            font.pixelSize: 18
                        }
                        Button {
                            text: "Select"
                            onClicked: {
                                fontDialog.open();
                            }
                        }
                    }
                    Row {
                        spacing: 8
                        Switch {
                            id: shotClockSwitch
                            checked: appController.shotClock
                            onToggled: appController.shotClock = checked
                        }
                        Label {
                            text: "Shot Clock"
                            font.pixelSize: 18
                        }
                    }
                    Row {
                        spacing: 8
                        Switch {
                            id: showFoulsSwitch
                            checked: appController.showFouls
                            onCheckedChanged: appController.showFouls = checked
                        }
                        Label {
                            text: "Show Fouls/Sets"
                            font.pixelSize: 18
                        }
                    }
                    Row {
                        spacing: 8
                        Switch {
                            id: logoSwitch
                            checked: appController.logo
                            onCheckedChanged: appController.logo = checked
                        }
                        Label {
                            text: logoSwitch.checked ? "UEN Logo" : "Mascot Logo"
                            font.pixelSize: 18
                        }
                    }
                    Row {
                        spacing: 8
                        Label {
                            text: "Sport Mode"
                            font.pixelSize: 18
                        }
                        ComboBox {
                            id: backgroundSelector
                            model: ["Volleyball", "Basketball", "Wrestling"]
                            font.pixelSize: 18
                            currentIndex: appController.background
                            onActivated: appController.background = currentIndex
                        }
                    }
                    Row {
                        spacing: 8
                        Button {
                            text: "Clear Graphics"
                            font.pixelSize: 18
                            onClicked: appController.clearGraphics()
                        }
                    }
                }
            }
        }
    }
}
