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

    // general method for moving photos between stripes. It is preferable
    // to use specialized methods - they automatically provide correct arguments
    // preserveCursorInStripe - cursor stays within stripe. If there is no more photos in
    //   stripe, then cursor becomes -1
    // animate - make movement animated
    function movePhotoToLevel( photoIndex, newLevel, preserveCursorInLine, animate )
    {
        var photoID = stripesModelObject.getPhotoID(photoIndex)
        if( photoID === -1) {
            console.error( "No photo matching this photoIndex ", photoIndex)
            throw false
        }

        var newCursorPhotoID = undefined
        if( preserveCursorInLine && cursor.currentPhotoIndex === photoIndex ) {
            newCursorPhotoID = cursor.findPreservationPhotoIDInLevel();
        }

        var success = stripesModelObject.movePhotoByIndexToLevel( cursor.currentPhotoIndex, newLevel, true);

        if( success ) {
            // Animation
            if( animate ) {
               var refCount = d.movementRegistry[photoID];
                if(refCount === undefined ) {
                    refCount = 1
                } else {
                    refCount ++;
                }
                console.log( "Animated movement for ", photoID, " requested. RefCount: ", refCount)
                d.movementRegistry[photoID] = refCount
            }

        // Changing position
            if( newCursorPhotoID !== undefined) {
                cursor.currentPhotoID = newCursorPhotoID;
            } else {
                // forcefull updating cursor to pick up changes in 'level' property of current photo
                cursor.forceUpdate()
            }
        }
    }
    function moveCurrentPhotoUpLevel( preserveCursorInStripe ) {
        movePhotoToLevel( cursor.currentPhotoIndex, cursor.currentLevel + 1, preserveCursorInStripe, true )
    }
    function moveCurrentPhotoDownLevel( preserveCursorInLine ) {
        movePhotoToLevel( cursor.currentPhotoIndex, cursor.currentLevel - 1, preserveCursorInLine, true )
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
            photoObject = {"photoID" : photoID };
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

        /* TODO: REMOVE unnecessary. Such animated precision is not needed
        if( item != undefined && item != null && item.parent != null ) {
            // Preserve coordinates for futher use
            var coordsInOurSystem = item.mapToItem(visualControl, 0, 0)
            cacheObject.visualControlCoords = coordsInOurSystem;
            console.log( "Caching coordinates for photoID ", photoID, ":", coordsInOurSystem)
        }*/

        // Erase item
        cacheObject.item = undefined
        cacheObject.animation = undefined;

        // TODO: IMplement ring buffer to store last 10(?) items
    }

    QtObject {
        id: d

        // Cache of photo items. Key is photoID
        property var photoItemsCache : null

        // Registry of movements that must be animated. Basically
        // it is a pair PhotoID -> refCounter. refCounter is needed to track situation
        // when movement of the photo is interrupted by another movement of the same photo.
        property var movementRegistry

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
           movementRegistry = {}
        }

        // Function will initiate movement of photo item to specified newParent. If there is
        // registered stripe-to-stripe movement in d.movementRegistry, then it will be animated.
        // If there is not, then it is immediate
        function initiateMovement( photoObject, newParent ) {
            if( photoObject.movementAnimation !== undefined && photoObject.movementAnimation !== null ) {
                // Interrupt current animation. We do not complete it, because it is unclear whether there currently
                // exist old-parent-target or not. Also, no point in unnecessary reparenting
                photoObject.movementAnimation.stop();
            }

            var item = photoObject.item

            var refCount = d.movementRegistry[photoObject.photoID];
        // Non-animated movement
            if( refCount === undefined || refCount === 0) {
                console.log( "Executing non-animated movement. Photo: ", photoObject.photoID )
                d.nonAnimatedMovement(item, newParent)
                return
            }

            //
            refCount --;
            d.movementRegistry[photoObject.photoID] = refCount;

            var coordsInNewParent = undefined
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
                /* TODO: REMOVE CACHE
                var cachedCoords = photoObject.visualControlCoords
                if( cachedCoords !== undefined) {
                    coordsInNewParent = newParent.mapFromItem( visualControl,
                                                                              cachedCoords.x,
                                                                              cachedCoords.y)
                    console.log( "Using cached coords: ", cachedCoords, " (in local c/s): ", cachedCoordsInNewParentSystem)
                    item.parent = newParent
                    item.x = cachedCoordsInNewParentSystem.x
                    item.y = cachedCoordsInNewParentSystem.y
                } else {
                    item.parent = newParent
                    item.x = 0
                    item.y = 0
                    animate = false
                }*/
                // For now - general offscreen coordinates
                console.log( "using general off-screen coordinates")
                coordsInNewParent = visualControl.mapToItem(newParent, -item.width*2, visualControl.height / 2)
            } else {
                console.log( "using current position")
                coordsInNewParent = item.mapToItem(newParent, 0, 0);
            }

    // Reparent to newParent
    item.parent = newParent
    item.x = coordsInNewParent.x
    item.y = coordsInNewParent.y


                // TODO: REMOVE
                {
                    var dbgTargetCoords = Qt.point(0,0) //visualControl.mapFromItem( newParent, 0, 0);
                   var dbgVCCoords = visualControl.mapFromItem(newParent, item.x, item.y)
                    console.log( "VC: moving from (", item.x, ",", item.y, ") (global:", dbgVCCoords,") to ", dbgTargetCoords);
                }

                var stripeIndex = stripesModel.findStripeIndexForPhotoID()
                var stripeObject = {
                    "raiseStripeZ" : function() { return photoStripesView.raiseStripeZ(stripeIndex); },
                    "restoreStripeZ" : function() { return photoStripesView.restoreStripeZ(stripeIndex); }
                }

                var newParentCoordsInOurSystemBinding = Qt.binding( function() { return visualControl.mapFromItem( newParent, 0, 0); } );
                // Let's forget old animation entirely. It's state is unclear - it may have already finished,
                // it may have been interrupted by previous statement, etc
                photoObject.movementAnimation =
                        d.moveReparentAnimationComponent.createObject(
                            visualControl,
                            {
                                "target" : item,
                                "newParent" : newParent,
                                "duration" : 5000,
                                //"targetPoint" : newParentCoordsInOurSystemBinding,
                                "stripeObject" : stripeObject
                            });
                photoObject.movementAnimation.start();
        }

    function nonAnimatedMovement( item, newParent ) {
    item.parent = newParent
    item.x = 0
    item.y = 0
    }

    function initiateAnimatedMovement( item, newParent ) {

    }



    }
}
