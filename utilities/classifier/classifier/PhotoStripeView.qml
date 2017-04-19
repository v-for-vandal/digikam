import QtQuick 2.0

Item {
    id: photoStripeView
    // User settings
    property alias stripeModel: stripeView.model
    property var cursorObject // TODO: make property Cursor instead of property var
    property VisualControl visualControlObject
    // Read-only properties
    readonly property bool isCurrentLevel: cursorObject.currentLevel === stripeModel.level

    Rectangle {
        anchors.fill: parent
        border.color: "black"
        border.width: 5

        ListView {
            id: stripeView
            anchors.fill: parent
            orientation: Qt.Horizontal
            cacheBuffer: 0
            delegate: PhotoDelegate {
            }

            /*
            add : Transition {
                NumberAnimation { properties: "x,y"; duration: 500; from: 200 }
            }*/
            addDisplaced : Transition {
                NumberAnimation { properties: "x,y"; duration: 500 }
            }
        }
    }

    onStripeModelChanged: {
        console.log("This stripe has: ", stripeModel.count, " photos, it's level is ", stripeModel.level)
    }

    function ensureVisibilityByIndex( indexInStripe ) {
        if( indexInStripe < 0 || indexInStripe >= stripeModel.count ) {
            console.error("index in stripe is out of bounds");
            return;
        }
        stripeView.positionViewAtIndex(indexInStripe, ListView.Contain);
    }
}
