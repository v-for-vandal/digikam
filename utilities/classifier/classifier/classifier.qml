import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Layouts 1.3

Window {
    id: root
    visible: true
    width: 640
    height: 480
    title: qsTr("Hello World")

    PhotoStripesView {
        id: photoStripesView
        anchors.fill: parent
        sourcePhotoModel : imageModel
        focus: true
		debugArea: stripesDebugInfo

        Keys.onRightPressed: {
            console.log("Right pressed");
            photoStripesView.cursorObject.currentPhotoID = photoStripesView.cursorObject.nextPhotoInLevel();
            event.accepted = true;
        }
        Keys.onLeftPressed: {
            console.log("Left pressed");
            photoStripesView.cursorObject.currentPhotoID = photoStripesView.cursorObject.previousPhotoInLevel();
            event.accepted = true;
        }
        Keys.onUpPressed: {
            console.log("Up pressed");
            photoStripesView.cursorObject.currentPhotoID = photoStripesView.cursorObject.photoInLevelUpByPhotoID();
            event.accepted = true;
        }
        Keys.onDownPressed: {
            console.log("Down pressed");
            photoStripesView.cursorObject.currentPhotoID = photoStripesView.cursorObject.photoInLevelDownByPhotoID();
            event.accepted = true;
        }
        Keys.onEnterPressed: {
            console.log("Enter pressed");
            photoStripesView.expandStripe(photoStripesView.cursorObject.currentPhotoIndex.y);
            event.accepted = true;
        }
        Keys.onEscapePressed: {
            console.log("Esc pressed");
            photoStripesView.collapseStripe(photoStripesView.cursorObject.currentPhotoIndex.y);
            event.accepted = true;
        }
        Keys.onDigit8Pressed: {
			photoStripesView.visualControlObject.moveCurrentPhotoUpLevel(true);
        }
        Keys.onDigit2Pressed: {
			photoStripesView.visualControlObject.moveCurrentPhotoDownLevel(true);
        }
    }

    Rectangle {
        id: debugInfo
        anchors.left : parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        opacity: 0.5
		width: childrenRect.width + 20
        property color textColor : "red"

			Grid {
				id: mainInfo
				columns: 2
				spacing: 2
				horizontalItemAlignment: Grid.AlignLeft

				Text {
					text: "Current photo id:"
					color: debugInfo.textColor
				}
				Text {
					text: photoStripesView.cursorObject.currentPhotoID
					color: debugInfo.textColor
				}
				Text {
					text: "Current level:"
					color: debugInfo.textColor
				}
				Text {
					text: photoStripesView.cursorObject.currentLevel
					color: debugInfo.textColor
				}
				Text {
					text: "Current stripe index:"
					color: debugInfo.textColor
				}
				Text {
					text: photoStripesView.cursorObject.currentPhotoIndex.y
					color: debugInfo.textColor
				}
				Text {
					text: "Current photo index:"
					color: debugInfo.textColor
				}
				Text {
					text: photoStripesView.cursorObject.currentPhotoIndex.x
					color: debugInfo.textColor
				}
			}

			Rectangle {
				anchors.top : mainInfo.bottom
				border.color: "black"
				border.width: 2
				id: stripesDebugInfo
				width: childrenRect.width
			}

    }

    /*
    Component {
        id: highlightBar
        Rectangle {
            width: 200
            height: 50
            color: "#FFFF88"
            // y: listView.currentItem.y;
            Behavior on y {
                SpringAnimation {
                    spring: 2
                    damping: 0.1
                }
            }
        }
    }

    PhotoStripeModel {
        model: imageModel
        level: 1
        id: level1Model
    }
    PhotoStripeModel {
        model: imageModel
        level: 2
        id: level2Model
    }

    Column {
        anchors.fill: parent

        ListView {
            height: root.height / root.stripsCount
            width: parent.width
            //id: photoView
            model: level2Model
            currentIndex: 0
            orientation: ListView.Horizontal
            //delegate: PhotoDelegate {}
            //anchors.fill: parent
            //highlight: highlightBar
            //highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
            focus: true
        }
        ListView {
            //id: photoView
            height: root.height / root.stripsCount
            width: parent.width
            model: level1Model
            currentIndex: 0
            orientation: ListView.Horizontal
            //delegate: PhotoDelegate {}
            //anchors.fill: parent
            //highlight: highlightBar
            //highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
            focus: true
        }
    }
    */
}
