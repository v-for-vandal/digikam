import QtQuick 2.0

Rectangle { // TODO: Make Item before deploying
    // Caution - this property won't be updated if data inside(!) model changed.
    // Do not query photoItem for user-changable properties, such as 'level'
    readonly property var photoSource: stripeModel.sourcePhotoModel.get(
                                         model.photoID)
    id: wrapper
    // Dimensions must be the same as RawPhotoView, otherwise animations suffers
    width: photoSource.width
    height: ListView.view.height
    border.color: "pink"
    border.width: 2
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
            console.log( "Global coords: ", wrapper.mapToItem(photoStripeView.visualControlObject, 0,0) )
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
        d.loadPhoto(model.photoID);
        d.photoID = model.photoID;
        d.updateHighlight(cursorObject);
        //console.log( "Photo delegate is created: ", model.photoID)
    }

    Component.onDestruction: {
        //console.log( "Photo delegate is destroyed: ", model.photoID);
        // model.photoID is unavailable because connection to model is already severed
        d.releasePhoto(d.photoID);
    }

    ParallelAnimation {
        id: photoMovementAnimation

        NumberAnimation {
            id: xMovement
            properties: "x"
            to: 0 // We always move photo to 0 coordinate of placeholder
            duration: 3000
        }
        NumberAnimation {
            id: yMovement
            properties: "y"
            to: 0 // We always move photo to 0 coordinate of placeholder
            duration: 3000
        }

        onStopped: {
            d.finishLoadingPhoto();
        }

    }

    QtObject {
        id: d

        // Highlight item. Might be null
        property var highlightItem : null
        // Photo item
        property var photoItem;
        // Our id
        property int photoID;

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
                highlightSelf(cursorObject);
            } else {
                removeCurrentHighlight();
            }
        }

        function loadPhoto(id) {
            if( id === undefined ) {
                throw false
            }
            if( visualControlObject === null || visualControlObject === undefined ) {
                console.error("Visual control object is not present");
                return;
            }

            photoItem = visualControlObject.requestPhotoItem(id, photoPlaceHolder);
        }

        function releasePhoto(id) {
            if( id === undefined ) {
                throw false
            }
            if( visualControlObject === null || visualControlObject === undefined ) {
                console.error("Visual control object is not present");
                return;
            }

            visualControlObject.releasePhotoItem(id);
        }

        /* TODO: Not needed
        function finishLoadingPhoto() {
            photoItem.parent = photoPlaceHolder
            photoItem.anchors.centerIn = photoPlaceHolder
        }*/
    }
}
