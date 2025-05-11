import QtQuick
import QtQuick.Window
import QtMultimedia
import QtQuick.Controls

Window {
	id: mainWindow
	visible: true
	width: 960
	height: 540
	title: qsTr("everscore")
	color: "black"
	
	property int xanimationduration: 0
	
	// animate any change to `width`
	Behavior on width {
		NumberAnimation {
			duration: 1000
			easing.type: Easing.InOutQuad
		}
	}
	
	// animate any change to `x`
	Behavior on x {
		NumberAnimation {
			duration: xanimationduration
			easing.type: Easing.InOutQuad
		}
	}
	
	MediaPlayer {
		id: player
		source: "file:media/splash.mp4"
		autoPlay: true
		videoOutput: videoOutput
	
		onMediaStatusChanged: {
			if (mediaStatus === MediaPlayer.EndOfMedia) {
				// this will trigger the Behavior above
				xanimationduration = 1000
				mainWindow.width = 1365
				mainWindow.x = x - 202
				mainInterface.visible = true
				
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
					source: "file:media/basketballbg.png"
					fillMode: Image.PreserveAspectFit
					}
				
				// Sprites and Graphics for Basketball:
				
				Item {
					id: basketballDigits
					objectName: "basketballDigits"
				
					// design canvas in 1080p, scaled down to fit basketballView
					width: 1920; height: 1080
					transformOrigin: Item.TopLeft
					scale: basketballView.width / width
				
					// digit properties exposed to Python
					property int awayHundredsDigit:   0
					property int awayTensDigit:       0
					property int awayOnesDigit:       0
					property int awaySmallTensDigit:  0
					property int awaySmallOnesDigit:  0
					property int fastTensDigit:       0
					property int fastOnesDigit:       0
					property int fastTenthsDigit:     0
					property int homeHundredsDigit:   0
					property int homeTensDigit:       0
					property int homeOnesDigit:       0
					property int homeSmallTensDigit:  0
					property int homeSmallOnesDigit:  0
					property int minuteTensDigit:     0
					property int minuteOnesDigit:     0
					property int periodDigit:         0
					property int playerFoulDigit:     0
					property int playerOnesDigit:     0
					property int playerTensDigit:     0
					property int secondTensDigit:     0
					property int secondOnesDigit:     0
					property int shotTensDigit:       0
					property int shotOnesDigit:       0
				
					// single-frame PNG: no clipping needed
					Item {
						id: awayHundreds
						x: 1089; y: 361
						width: 161; height: 325
						visible: basketballDigits.awayHundredsDigit === 1
				
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
						x: 1263; y: 361
						width: 200; height: 325
				
						Image {
							source: "media/awayTens.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.awayTensDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: awayOnes
						objectName: "awayOnes"
						x: 1470; y: 362
						width: 225; height: 324
				
						Image {
							source: "media/awayOnes.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.awayOnesDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: awaySmallTens
						objectName: "awaySmallTens"
						x: 1695; y: 361
						width: 114; height: 195
				
						Image {
							source: "media/awaySmallTens.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.awaySmallTensDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: awaySmallOnes
						objectName: "awaySmallOnes"
						x: 1810; y: 361
						width: 110; height: 196
				
						Image {
							source: "media/awaySmallOnes.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.awaySmallOnesDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: fastTens
						objectName: "fastTens"
						visible: false
						x: 1077; y: 716
						width: 208; height: 339
				
						Image {
							source: "media/fastTens.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.fastTensDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: fastOnes
						objectName: "fastOnes"
						visible: false
						x: 1291; y: 717
						width: 218; height: 338
				
						Image {
							source: "media/fastOnes.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.fastOnesDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: fastTenths
						objectName: "fastTenths"
						visible: false
						x: 1603; y: 715
						width: 224; height: 340
				
						Image {
							source: "media/fastTenths.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.fastTenthsDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: homeHundreds
						objectName: "homeHundreds"
						x: 1089; y: 20
						width: 177; height: 324
						visible: basketballDigits.homeHundredsDigit === 1
				
						Image {
							source: "media/homeHundreds.png"
							anchors.fill: parent
							fillMode: Image.Stretch
						}
					}
				
					Item {
						id: homeTens
						objectName: "homeTens"
						x: 1260; y: 20
						width: 201; height: 323
				
						Image {
							source: "media/homeTens.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.homeTensDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: homeOnes
						objectName: "homeOnes"
						x: 1465; y: 21
						width: 230; height: 322
				
						Image {
							source: "media/homeOnes.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.homeOnesDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: homeSmallTens
						objectName: "homeSmallTens"
						x: 1697; y: 21
						width: 115; height: 194
				
						Image {
							source: "media/homeSmallTens.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.homeSmallTensDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: homeSmallOnes
						objectName: "homeSmallOnes"
						x: 1810; y: 21
						width: 110; height: 196
				
						Image {
							source: "media/homeSmallOnes.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.homeSmallOnesDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: minuteTens
						objectName: "minuteTens"
						visible: false
						x: 1016; y: 756
						width: 184; height: 252
				
						Image {
							source: "media/minuteTens.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.minuteTensDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: minuteOnes
						objectName: "minuteOnes"
						visible: true
						x: 1206; y: 759
						width: 185; height: 245
				
						Image {
							source: "media/minuteOnes.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.minuteOnesDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: period
						objectName: "period"
						x: 165; y: 818
						width: 181; height: 220
				
						Image {
							source: "media/period.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.periodDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: playerFoul
						objectName: "playerFoul"
						visible: false
						x: 778; y: 848
						width: 114; height: 151
				
						Image {
							source: "media/playerFoul.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.playerFoulDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: playerOnes
						objectName: "playerOnes"
						visible: false
						x: 631; y: 848
						width: 111; height: 149
				
						Image {
							source: "media/playerOnes.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.playerOnesDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: playerTens
						objectName: "playerTens"
						visible: false
						x: 514; y: 848
						width: 120; height: 152
				
						Image {
							source: "media/playerTens.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.playerTensDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: secondTens
						objectName: "secondTens"
						visible: true
						x: 1487; y: 762
						width: 189; height: 248
				
						Image {
							source: "media/secondTens.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.secondTensDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: secondOnes
						objectName: "secondOnes"
						visible: true
						x: 1674; y: 761
						width: 193; height: 235
				
						Image {
							source: "media/secondOnes.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.secondOnesDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: shotTens
						objectName: "shotTens"
						visible: true
						x: 524; y: 763
						width: 185; height: 240
				
						Image {
							source: "media/shotTens.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.shotTensDigit,
								width,
								height
							)
						}
					}
				
					Item {
						id: shotOnes
						objectName: "shotOnes"
						visible: true
						x: 712; y: 767
						width: 176; height: 236
				
						Image {
							source: "media/shotOnes.png"
							anchors.fill: parent
							fillMode: Image.Stretch
							sourceClipRect: Qt.rect(
								0,
								height * basketballDigits.shotOnesDigit,
								width,
								height
							)
						}
					}
				}
				
				
				
			}
			

			
			
		}
	
		Rectangle {
			width: 405
			height: 540
			anchors.right: parent.right
			color: "white"
			// tool controls go here
		}
	}
}