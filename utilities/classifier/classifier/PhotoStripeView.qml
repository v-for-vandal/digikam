import QtQuick 2.0

Item {
    // User settings
    property alias stripeModel: stripeView.model
    property var cursorObject
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
            delegate: Rectangle {
                // Caution - this property won't be updated if data inside(!) model changed.
                // Do not query photoItem for user-changable properties, such as 'level'
                readonly property var photoItem: stripeModel.sourcePhotoModel.get(
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

                /* CurrentPhotoHighlight { // TODO: REMOVE
                    anchors.fill: parent
                    visible: model.photoID === cursorObject.currentPhotoID
                }*/

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log( "Clicked on photo: ", model.photoID);
                        cursorObject.currentPhotoID = model.photoID;
                    }
                }

                Connections {
                    target: cursorObject

                    onCurrentPhotoIDChanged : {
                        d.updateHighlight(cursorObject)
                    }
                }

                Component.onCompleted: {
                    d.updateHighlight(cursorObject);
                }

                QtObject {
                    id: d

                    // Highlight item. Might be null
                    property Item highlightItem : null

                    function highlightSelf(cursor) {
                        if( cursor === null || cursor === undefined
                                || cursor.highlightItem === null || cursor.highlightItem === undefined) {
                            removeCurrentHighlight();
                        }

                        // If current highlight item is cursor's current highlight item,
                        // do nothing
                        if( highlightItem === cursor.highlightItem ) {
                            console.log("already highlighted");
                            return;
                        }

                        // If it theoretically possible to have something else in highlightItem
                        // Removing it
                        removeCurrentHighlight();

                        // Now move cursor's highlight item onto self
                        console.log("Current highlight item: ", cursor.highlightItem)
                        highlightItem = cursor.highlightItem // could be null
                        if( highlightItem !== null ) {
                            highlightItem.parent = wrapper
                            highlightItem.z = 1
                            highlightItem.visible = true
                        }
                    }

                    function removeCurrentHighlight() {
                        if( highlightItem !== null && highlightItem !== undefined ) {
                            // For every change in current photo calls for every delegate will
                            // be issued. Order of those calls is undefined. This it may happen that
                            // new delegate with highlight will recieve call before old delegate.
                            // To prevent setting highlightItem.parent to null by old delegate, we
                            // check for parent explicitly
                            if( highlightItem.parent === wrapper ) {
                                highlightItem.parent = null
                            }
                            highlightItem = null
                        }
                    }

                    function updateHighlight(cursor) {
                        console.log( "Updating highlight on delegate for photo: ", model.photoID)
                        // If we are highlighted:
                        if( cursorObject.currentPhotoID === model.photoID) {
                            d.highlightSelf(cursorObject);
                        } else {
                            removeCurrentHighlight();
                        }
                    }
                }
            }

            add : Transition {
                NumberAnimation { properties: "x,y"; duration: 500 }
            }
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
