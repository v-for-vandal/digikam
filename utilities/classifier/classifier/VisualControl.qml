import QtQuick 2.0

// Item is used for various movement-related functionality that requires visual information.
// It is an Item and it must be visible and preferably spread over and above(!) main view area. Some
// animations use it as a temporary parent when moving between stripes, because it allows drawing over
// other stripes. (Normally, stripes are siblings and when some Item is parented to stripe X and is moved
// from point A to point B, it will be drawn beneath some stripes-siblings)
Item {
    id: visualControl
    clip: true // visualControl should clip it values because it utilizes 'offscreen' area for some movement animations

    property var stripeViews;
    property var stripesModel;

    function movementStarted( initiator ) {
        //connenc
    }

    // == Photo cache
    // VisualControl serves as cache for photo Items. It is used for correct animation
    // when moving photos between layers.
    // Photo Items in this cache has VisualControl QObject-parent, but their visual
    // parent is delegate where they are currently displayed.
    // Only currently visible'ish photos are stored in cache (Technically, photos that are reference
    // by existing delegate. Delegates are managed by ListView and it usually destroys delegate
    // when it is no longer visible).
    // Cache is necessary for correct animation when moving photos between stripes.

    // This function starts animation that will move Item from current position to newParent and automatically assign it once finished.
    // It also returns specified Item - but you should abstain with doing any operations with it before movement is finished
    // QObject-parent of this item is always VisualControl itself,
    // but visual parent may change.
    // Return structure is:
    // {
    //     "item": Item itself,
    //     "movementAnimation" : animation that moves item to specified position and reparents it once done.
    // }
    function requestPhotoItem( photoID, newParent ) {
        if( stripesModel === undefined || stripesModel === null) {
            console.error( "Stripes model is undefined");
            return null
        }

        if( newParent === null || newParent === undefined ) {
            console.error("Can't move to null parent")
            return null
        }

        if( photoID === undefined || photoID === null
                || photoID < 0 || photoID >= stripesModel.sourcePhotoModel.count) {
            console.warn( "Requested PhotoID is invalid")
            return null
        }

        console.log( "Request to move photo with ID ", photoID, "to new parent ", newParent)
        var photoObject = d.photoItemsCache[photoID];
        if( photoObject === undefined || photoObject === null ) {
            // Cache record as a whole is missing
            photoObject = {};
        }

        if( photoObject.item === undefined || photoObject.item === null ) {
            // Cache record contains no item - because item was already released
            console.log("VC: cache miss. Creating object.")
            console.assert(d.rawPhotoViewComponent !== null && d.rawPhotoViewComponent !== undefined)

            var photo = stripesModel.sourcePhotoModel.get(photoID);
            console.log( "Creating photo item. width: ", photo.width, "border.color: ", photo.color)
            var item = d.rawPhotoViewComponent.createObject(visualControl,
                                                            {"photoID" : photoID,
                                                                "width": photo.width,
                                                                "height" : photoStripesView.stripeHeight, // TODO: Must be binging
                                                                "border.color": photo.color } )
            item.parent = null
            photoObject.item = item

            d.photoItemsCache[photoID] = photoObject;
        }

        d.initiateMovement(photoObject, newParent);
        return photoObject;
    }

    function releasePhotoItem(photoID) {
        // TODO: Idea: replace value with undefined. Once size of dict grows to 100+ items, most of which are undefines, - create new object without undefines and copy it over
        // TODO: Update to previous todo - most 'removed' items will be objects with only visualControlCoords
        var cacheObject = d.photoItemsCache[photoID];
        if( cacheObject === undefined || cacheObject === null) {
            return;
        }

        var item = cacheObject.item
        var animation = cacheObject.movementAnimation

        if( animation !== undefined && animation !== null) {
            animation.stop();
        }

        if( item != undefined && item != null && item.parent != null ) {
            // Preserve coordinates for futher use
            var coordsInOurSystem = item.mapToItem(visualControl, 0, 0)
            cacheObject.visualControlCoords = coordsInOurSystem;
        }

        // Erase item
        cacheObject.item = undefined
        cacheObject.animation = undefined;

        // TODO: IMplement ring buffer to store last 10(?) items
    }

    QtObject {
        id: d

        // Cache of photo items. Key is photoID
        property var photoItemsCache : null

        // RawPhotoView component used for dynamic creation
        property var rawPhotoViewComponent : null

        // MoveReparentAnimation component used for dynamic creation
        property Component moveReparentAnimationComponent

        Component.onCompleted: {
            rawPhotoViewComponent = Qt.createComponent("RawPhotoView.qml");
            moveReparentAnimationComponent =  Qt.createComponent("animations/MoveReparentAnimation.qml")
            if( moveReparentAnimationComponent.status != Component.Ready ) {
                if( moveReparentAnimationComponent.status == Component.Error ) {
                    console.log( "Error when loading MoveReparentAnimation.qml: ", moveReparentAnimationComponent.errorString());
                    throw false;
                }
            }

           photoItemsCache = {} // TODO: REMOVE ?
        }

        function initiateMovement( photoObject, newParent ) {
            if( photoObject.movementAnimation !== undefined && photoObject.movementAnimation !== null ) {
                // Interrupt current animation. We do not complete it, because it is unclear whether there currently
                // exist old-parent-target or not. Also, no point in unnecessary reparenting
                photoObject.movementAnimation.stop();
            }

            // Move item to VisualControl, preserving it's coordinates. If item.parent is currently null, then place
            // it in 'offscreen' area for now
            var item = photoObject.item
            var animate = true
            console.log( "Initiating movement from ", item.parent, " to ", newParent);

            if( item.parent === null || item.parent === undefined ) {
                // parent == null means:
                // 1. Not a movement between stripes
                //      1.1 initial population
                //      1.2. delegate regeneration or some other internal list view operation.
                // 2. current delegate with photo has already destroyed self

                /*item.parent = visualControl // TODO: REMOVE
                item.x = -item.width - 20 // Just in case
                item.y = visualControl.height / 2*/
                var cachedCoords = photoObject.visualControlCoords
                if( cachedCoords !== undefined) {
                    console.log( "Using cached coords")
                    item.parent = visualControl
                    item.x = cachedCoords.x
                    item.y = cachedCoords.y
                } else {
                    item.parent = newParent
                    item.x = 0
                    item.y = 0
                    animate = false
                }
            } else {
                var coordsInOurSystem = item.parent.mapToItem(visualControl, item.x, item.y);
                // Detach current parent and attach to self
                item.parent = visualControl
                item.x = coordsInOurSystem.x
                item.y = coordsInOurSystem.y
            }


            if( animate === true ) {
                // TODO: REMOVE
                {
                    var dbgTargetCoords = visualControl.mapFromItem( newParent, 0, 0);
                    console.log( "VC: moving from (", item.x, ",", item.y, ") to ", dbgTargetCoords);
                }

                var newParentCoordsInOurSystemBinding = Qt.binding( function() { return visualControl.mapFromItem( newParent, 0, 0); } );
                // Let's forget old animation entirely. It's state is unclear - it may have already finished,
                // it may have been interrupted by previous statement, etc
                photoObject.movementAnimation = d.moveReparentAnimationComponent.createObject(visualControl,
                                                                                              {
                                                                                                  "target" : item,
                                                                                                  "newParent" : newParent,
                                                                                                  "duration" : 5000,
                                                                                                  "targetPoint" : newParentCoordsInOurSystemBinding
                                                                                              });
                photoObject.movementAnimation.start();
            }

        }


    }
}
