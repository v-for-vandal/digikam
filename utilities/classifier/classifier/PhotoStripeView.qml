import QtQuick 2.0

Item {
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
                //opacity: 0.7
                /*
                RawPhotoView {
                    anchors.centerIn: parent
                    photoID: model.photoID
                }*/
                Item {
                    anchors.fill: parent
                    id: photoPlaceHolder
                }

                MouseArea {
                    anchors.fill: parent
                    drag.target: wrapper
                    drag.axis: Drag.YAxis
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
                    // Load photo onto self
                    d.loadPhoto();
                    d.updateHighlight(cursorObject);
                    //console.log( "Photo delegate is created: ", model.photoID)
                }

                Component.onDestruction: {
                    //console.log( "Photo delegate is destroyed: ", model.photoID);
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
                            //console.log("already highlighted");
                            return;
                        }

                        // If it theoretically possible to have something else in highlightItem
                        // Removing it
                        removeCurrentHighlight();

                        // Now move cursor's highlight item onto self
                        //console.log("Current highlight item: ", cursor.highlightItem)
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
                        //console.log( "Updating highlight on delegate for photo: ", model.photoID)
                        // If we are highlighted:
                        if( cursorObject.currentPhotoID === model.photoID) {
                            d.highlightSelf(cursorObject);
                        } else {
                            removeCurrentHighlight();
                        }
                    }

                    function loadPhoto() {
                        var id = model.photoID
                        if( id === undefined ) {
                            throw false
                        }
                        if( visualControlObject === null || visualControlObject === undefined ) {
                            console.error("Visual control object is not present");
                            return;
                        }

                        var photo = visualControlObject.requestPhoto(id);
                        // For now - just plain reparenting, without animation
                        if( photo !== undefined && photo !== null ) {
                            photo.parent = photoPlaceHolder
                            photo.anchors.centerIn = photoPlaceHolder
                        } else {
                            console.error( "VisualControl failed to give us requested photo")
                        }
                    }
                }
            }

            add : Transition {
                NumberAnimation { properties: "x,y"; duration: 500; from: 200 }
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
