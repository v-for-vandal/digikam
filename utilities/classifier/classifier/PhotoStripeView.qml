import QtQuick 2.0

Item {
    // User settings
    property alias stripeModel: stripeView.model
    property var photoView
    // Read-only properties
    readonly property bool isCurrentLevel: photoView.currentLevel == stripeModel.level

    Rectangle {
        anchors.fill: parent
        border.color: "black"
        border.width: 5

        ListView {
            id: stripeView
            anchors.fill: parent
            orientation: Qt.Horizontal
            delegate: Rectangle {
                readonly property var photoItem: photoView.sourcePhotoModel.get(
                                                     model.photoID)
                id: wrapper
                width: photoItem.width
                height: ListView.view.height
                border.color: photoItem.color
                border.width: 5
                opacity: 0.7
                Text {
                    anchors.centerIn: parent
                    text: "Photo ID: " + model.photoID
                }

                CurrentPhotoHighlight {
                    anchors.fill: parent
                    visible: model.photoID == photoView.currentPhotoID
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log( "Clicked on photo: ", model.photoID);
                        photoView.currentPhotoID = model.photoID;
                    }
                }
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
