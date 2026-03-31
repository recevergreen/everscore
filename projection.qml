import QtQuick
import QtQuick.Window

Window {
    id: projectionWindow
    width: 960
    height: 540
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
        function onCloseRequested() {
            projectionWindow.close();
        }
    }

    // Scale the 960×540 scoreboard canvas to fill the window while preserving
    // aspect ratio (same behaviour as the old Image.PreserveAspectFit grab).
    Rectangle {
        id: scoreboardRect
        width: 960
        height: 540
        color: "forestgreen"

        property real scaleF: Math.min(projectionWindow.width / 960,
                                       projectionWindow.height / 540)
        x: (projectionWindow.width  - 960 * scaleF) / 2
        y: (projectionWindow.height - 540 * scaleF) / 2
        scale: scaleF
        transformOrigin: Item.TopLeft

        Image {
            anchors.fill: parent
            source: ["media/volleyballbg.png",
                     "media/basketballbg.png",
                     "media/wrestlingbg.png"][appController.background]
            fillMode: Image.PreserveAspectFit
        }

        // Design canvas is 1920×1080, scaled down to fit the 960×540 rect.
        Item {
            id: projDigits
            width: 1920
            height: 1080
            transformOrigin: Item.TopLeft
            scale: scoreboardRect.width / width

            // Mirror every digit property from the main window's basketballDigits
            // element (exposed as sharedBasketballDigits context property).
            property int awayHundredsDigit: sharedBasketballDigits.awayHundredsDigit
            property int awayTensDigit:     sharedBasketballDigits.awayTensDigit
            property int awayOnesDigit:     sharedBasketballDigits.awayOnesDigit
            property int awaySmallTensDigit: sharedBasketballDigits.awaySmallTensDigit
            property int awaySmallOnesDigit: sharedBasketballDigits.awaySmallOnesDigit
            property int fastTensDigit:     sharedBasketballDigits.fastTensDigit
            property int fastOnesDigit:     sharedBasketballDigits.fastOnesDigit
            property int fastTenthsDigit:   sharedBasketballDigits.fastTenthsDigit
            property int homeHundredsDigit: sharedBasketballDigits.homeHundredsDigit
            property int homeTensDigit:     sharedBasketballDigits.homeTensDigit
            property int homeOnesDigit:     sharedBasketballDigits.homeOnesDigit
            property int homeSmallTensDigit: sharedBasketballDigits.homeSmallTensDigit
            property int homeSmallOnesDigit: sharedBasketballDigits.homeSmallOnesDigit
            property int minuteTensDigit:   sharedBasketballDigits.minuteTensDigit
            property int minuteOnesDigit:   sharedBasketballDigits.minuteOnesDigit
            property int periodDigit:       sharedBasketballDigits.periodDigit
            property int playerFoulDigit:   sharedBasketballDigits.playerFoulDigit
            property int playerOnesDigit:   sharedBasketballDigits.playerOnesDigit
            property int playerTensDigit:   sharedBasketballDigits.playerTensDigit
            property int secondTensDigit:   sharedBasketballDigits.secondTensDigit
            property int secondOnesDigit:   sharedBasketballDigits.secondOnesDigit
            property int shotTensDigit:     sharedBasketballDigits.shotTensDigit
            property int shotOnesDigit:     sharedBasketballDigits.shotOnesDigit
            property int wgHundredsDigit:   sharedBasketballDigits.wgHundredsDigit
            property int wgTensDigit:       sharedBasketballDigits.wgTensDigit
            property int wgOnesDigit:       sharedBasketballDigits.wgOnesDigit

            // ── Logos & colour overlays ──────────────────────────────────────
            Image {
                x: 38; y: 29; width: 1051; height: 319
                source: appController.homeLogo
                fillMode: Image.PreserveAspectFit
                opacity: 0.5
            }
            Image {
                x: 38; y: 363; width: 1048; height: 324
                source: appController.opponentLogo
                fillMode: Image.PreserveAspectFit
                opacity: 0.5
            }
            Rectangle {
                x: 38; y: 30; width: 1048; height: 315
                color: appController.homeColor
                opacity: 0.5
            }
            Rectangle {
                x: 38; y: 363; width: 1048; height: 324
                color: appController.opponentColor
                opacity: 0.5
            }

            // ── Clock separator (colon / decimal point) ──────────────────────
            Image {
                x: sharedControlPanel.isFastClockActive ? 1523 : 1409
                y: 833; width: 65; height: 163
                visible: sharedControlPanel.isFastClockActive
                         || sharedControlPanel.clockTimeInTenths > 0
                source: sharedControlPanel.isFastClockActive
                        ? "media/decimalpoint.png" : "media/colon.png"
            }

            // ── Away score ───────────────────────────────────────────────────
            Item {
                opacity: sharedControlPanel.visitorScore >= 100 ? 1 : 0
                x: 1089; y: 361; width: 161; height: 325
                Image { source: "media/awayHundreds.png"; anchors.fill: parent; fillMode: Image.Stretch }
            }
            Item {
                opacity: sharedControlPanel.visitorScore >= 10 ? 1 : 0
                x: 1263; y: 361; width: 200; height: 325
                Image { source: "media/awayTens.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.awayTensDigit, width, height) }
            }
            Item {
                x: 1470; y: 362; width: 225; height: 324
                Image { source: "media/awayOnes.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.awayOnesDigit, width, height) }
            }

            // ── Away fouls ───────────────────────────────────────────────────
            Item {
                opacity: sharedControlPanel.visitorFouls >= 10 ? 1 : 0
                x: 1695; y: 361; width: 114; height: 195
                Image { source: "media/awaySmallTens.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.awaySmallTensDigit, width, height) }
            }
            Item {
                x: 1810; y: 361; width: 110; height: 196
                Image { source: "media/awaySmallOnes.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.awaySmallOnesDigit, width, height) }
            }

            // ── Fast clock (< 1 minute) ──────────────────────────────────────
            Item {
                visible: sharedControlPanel.isFastClockActive
                x: 1077; y: 716; width: 208; height: 339
                Image { source: "media/fastTens.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.fastTensDigit, width, height) }
            }
            Item {
                visible: sharedControlPanel.isFastClockActive
                x: 1291; y: 717; width: 218; height: 338
                Image { source: "media/fastOnes.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.fastOnesDigit, width, height) }
            }
            Item {
                visible: sharedControlPanel.isFastClockActive
                x: 1603; y: 715; width: 224; height: 340
                Image { source: "media/fastTenths.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.fastTenthsDigit, width, height) }
            }

            // ── Home score ───────────────────────────────────────────────────
            Item {
                opacity: sharedControlPanel.homeScore >= 100 ? 1 : 0
                x: 1089; y: 20; width: 177; height: 324
                Image { source: "media/homeHundreds.png"; anchors.fill: parent; fillMode: Image.Stretch }
            }
            Item {
                opacity: sharedControlPanel.homeScore >= 10 ? 1 : 0
                x: 1260; y: 20; width: 201; height: 323
                Image { source: "media/homeTens.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.homeTensDigit, width, height) }
            }
            Item {
                x: 1465; y: 21; width: 230; height: 322
                Image { source: "media/homeOnes.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.homeOnesDigit, width, height) }
            }

            // ── Home fouls ───────────────────────────────────────────────────
            Item {
                opacity: sharedControlPanel.homeFouls >= 10 ? 1 : 0
                x: 1697; y: 21; width: 115; height: 194
                Image { source: "media/homeSmallTens.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.homeSmallTensDigit, width, height) }
            }
            Item {
                x: 1810; y: 21; width: 110; height: 196
                Image { source: "media/homeSmallOnes.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.homeSmallOnesDigit, width, height) }
            }

            // ── Minute clock (>= 1 minute) ───────────────────────────────────
            Item {
                visible: !sharedControlPanel.isFastClockActive
                x: 1016; y: 756; width: 184; height: 252
                Image { source: "media/minuteTens.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.minuteTensDigit, width, height) }
            }
            Item {
                visible: !sharedControlPanel.isFastClockActive
                x: 1206; y: 759; width: 185; height: 245
                Image { source: "media/minuteOnes.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.minuteOnesDigit, width, height) }
            }

            // ── Second clock ─────────────────────────────────────────────────
            Item {
                visible: !sharedControlPanel.isFastClockActive
                x: 1487; y: 762; width: 189; height: 248
                Image { source: "media/secondTens.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.secondTensDigit, width, height) }
            }
            Item {
                visible: !sharedControlPanel.isFastClockActive
                x: 1674; y: 761; width: 193; height: 235
                Image { source: "media/secondOnes.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.secondOnesDigit, width, height) }
            }

            // ── Period ───────────────────────────────────────────────────────
            Item {
                x: 165; y: 818; width: 181; height: 220
                Image { source: "media/period.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.periodDigit, width, height) }
            }

            // ── Player foul display (hidden — controlled elsewhere) ───────────
            Item {
                visible: false
                x: 778; y: 848; width: 114; height: 151
                Image { source: "media/playerFoul.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.playerFoulDigit, width, height) }
            }
            Item {
                visible: false
                x: 631; y: 848; width: 111; height: 149
                Image { source: "media/playerOnes.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.playerOnesDigit, width, height) }
            }
            Item {
                visible: false
                x: 514; y: 848; width: 120; height: 152
                Image { source: "media/playerTens.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.playerTensDigit, width, height) }
            }

            // ── Shot clock ───────────────────────────────────────────────────
            Item {
                visible: appController.shotClock
                x: 524; y: 763; width: 185; height: 240
                Image { source: "media/shotTens.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.shotTensDigit, width, height) }
            }
            Item {
                visible: appController.shotClock
                x: 712; y: 767; width: 176; height: 236
                Image { source: "media/shotOnes.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.shotOnesDigit, width, height) }
            }

            // ── Fouls cover ──────────────────────────────────────────────────
            Image {
                x: 1695; y: 0; width: 225; height: 687
                source: "media/coverfouls.png"
                visible: !appController.showFouls
            }

            // ── Logo / sponsor image ─────────────────────────────────────────
            Image {
                x: 491; y: 720; width: 423; height: 322
                source: appController.logo ? "media/uenlogo.png" : "media/speedykick.png"
                visible: !appController.shotClock
            }

            // ── Wrestling overlays ───────────────────────────────────────────
            Image {
                source: "media/wrestlingclockcover.png"
                x: 1010; y: 720; width: 858; height: 320
                visible: appController.isWrestlingMode
            }
            Item {
                opacity: 0
                x: 1183; y: 805; width: 177; height: 235
                visible: appController.isWrestlingMode && !sharedControlPanel.isHeavyweight
                Image { source: "media/wgHundreds.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.wgHundredsDigit, width, height) }
            }
            Item {
                opacity: 0
                x: 1361; y: 805; width: 172; height: 235
                visible: appController.isWrestlingMode && !sharedControlPanel.isHeavyweight
                Image { source: "media/wgTens.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.wgTensDigit, width, height) }
            }
            Item {
                x: 1533; y: 805; width: 179; height: 235
                visible: appController.isWrestlingMode && !sharedControlPanel.isHeavyweight
                Image { source: "media/wgOnes.png"; anchors.fill: parent; fillMode: Image.Stretch
                        sourceClipRect: Qt.rect(0, height * projDigits.wgOnesDigit, width, height) }
            }
            Image {
                source: "media/heavy.png"
                x: 1010; y: 812; width: 858; height: 228
                visible: appController.isWrestlingMode && sharedControlPanel.isHeavyweight
            }

            // ── Team name text ───────────────────────────────────────────────
            Item {
                x: 38; y: 29; width: 1051; height: 319
                Text {
                    text: appController.fontFamily.toLowerCase().includes("serpentine")
                          ? appController.homeName.toLowerCase() : appController.homeName
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
                x: 38; y: 363; width: 1048; height: 324
                Text {
                    text: appController.fontFamily.toLowerCase().includes("serpentine")
                          ? appController.opponentName.toLowerCase() : appController.opponentName
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
