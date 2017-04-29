import QtQuick 2.0


// Item is used for various movement-related functionality that requires visual information.
// It is an Item and it must be visible and preferably spread over and above(!) main view area. Some
// animations use it as a temporary parent when moving between stripes, because it allows drawing over
// other stripes. (Normally, stripes are siblings and when some Item is parented to stripe X and is moved
// from point A to point B, it will be drawn beneath some stripes-siblings)
Item {
	id: visualControl
	clip: true // visualControl should clip it values because it utilizes 'offscreen' area for some movement animations

	property var stripeViews
	property var stripesModel


    // ==== Synchronized movement of stripes ====

	function movementStarted(initiator) {//connenc
		// Synchronious movement - just bind ranges of inactive stripes [0, contentX - widthRatio] to same range in active stripeHeight
		// Essenctially we map every stripe to [0,1] and move them all in this a-la coords/system synchroniously
	}

	// ==== Simple movements ====
	// Functions in this section provide non-animated movement between stripes.

	// Moves given photo to new level.
	// photoIndexOrId - if PhotoID is givel, it will be automatically resolved to photoIndex
	// preserveCursorInLine - if photoIndexOrID is current photo for cursor, then cursor will switch to next
	//						  photo in stripe. If this is last photo, then to prev one. If there are no more
	//						  photos in stripe, then become -1 (a.k.a unset, a.k.a no current photo)
	// Function returns true if movement occured, false if did not - whether it is because of some erro
	// or by design. E.g. when one' cant create any more levels, or photo already at desired level
	function movePhotoToLevel(photoIndexOrID, newLevel, preserveCursorInLine) {
		var photoIndex = undefined
		if( typeof(photoIndexOrID) === "number") {
			photoIndex = stripesModel.photoIndexByPhotoID(photoIndexOrID)
		} else {
			photoIndex = photoIndexOrID
		}

		var newCursorPhotoID = undefined
		if (preserveCursorInLine && cursor.currentPhotoIndex === photoIndex) {
			newCursorPhotoID = cursor.findPreservationPhotoIDInLevel()
		}

		var success = stripesModel.movePhotoByIndexToLevel(
					photoIndex, newLevel, true)
		if (success) {
			// Changing position
			if (newCursorPhotoID !== undefined) {
				cursor.currentPhotoID = newCursorPhotoID
			} else {
				// forcefull updating cursor to pick up changes in 'level' property of current photo
				cursor.forceUpdate()
			}
			// Making sure current photo under cursor is visible
		}

		return success;
	}
	function moveCurrentPhotoUpLevel(preserveCursorInStripe) {
		movePhotoToLevel(cursor.currentPhotoIndex,
							   cursor.currentLevel + 1,
							   preserveCursorInStripe )
	}
	function moveCurrentPhotoDownLevel(preserveCursorInLine) {
		movePhotoToLevel(cursor.currentPhotoIndex,
							   cursor.currentLevel - 1,
							   preserveCursorInLine )
	}

	// ==== Visual movements ===
	// Functions in this section provides animated movements between stripes in overview mode

	// general method for (visual) moving photos between stripes. It is preferable
	// to use specialized methods - they automatically provide correct arguments
	// preserveCursorInStripe - cursor stays within stripe. If there is no more photos in
	//   stripe, then cursor becomes -1
	// animate - make movement animated. If animate == false, then call is equal to movePhotoToLevel
	function visualMovePhotoToLevel(photoIndexOrID, newLevel, preserveCursorInLine, animate) {
		var photoID = -1;
		var photoIndex = -1;
		// Resolving photoIndexOrID into 2 variables - photoID and photoIndex
		if( typeof(photoIndexOrID) === "number" ) {
			photoID = photoIndexOrID;
			photoIndex = stripesModel.photoIndexByPhotoID(photoID)
		} else {
			photoIndex = photoIndexOrID
			stripesModel.getPhotoID(photoIndex)
		}
		if (photoID === -1) {
			console.error("No photo matching this photoIndex ", photoIndex)
			throw false
		}

        // TODO: Idea: in delegate "onRemove" free item and put it into cache
        // in delegate Component.onCompleted request item. If item is marked for "movement", then
        // it is not returned, because delegate "onAdd" slot will be called soon. If it is not
        // marked for movement, then it is returned

		// This variable will be filled only if needed
		var photoObject = null
		var photoItemPreservation = null

		// Animation is complicated. We have source delegate and we have target delegate. The problem is
		// that any or both of those can be null now, and we have no control when they will be created.
		// Example:
		// 1. Moving from stripe 1 with photo visible to stripe 4. In stripe 4 position where this photo is due to appear
		//    is currently invisible - so there is no delegate. Futher more, we don't know when this delegate will appear -
		//    user may scroll to that position 5 minutes later. It will be weird if 5 minutes later when photo is about to
		//    appear on screen a movement animation will start playing.
		//
		// 2. Oposite variant. Source delegate is not on screen, and target delegate is about to be created in visible area.
		//    Where from should the photo move ? We can't even move it from 'offscreen' - because from left ? from right ?
		//    Was source delegate scrolled to the right or to the left ? Calculating this is unreliable and complicated
		//
		// 3. Combined. Source is not present, target is not present. Then, 5 minutes later target delegate is scrolled into view.
		//    Now we play animation that moves photo from where ? Of screen ?
		//
		// To circumvent all this we only perform animation if both target and source are present.

		if( animate ) {
			// If animation is required, we store current position of photo item
			// relative to our coords system. It is necessary because once movePhotoToLevel
			// is executed, the delegate currently containing  photo item is destroyed
			// and we loose that information
			photoObject = d.photoItemsCache[photoID];
			// We might not have photo item in cache, or it may not have any parent already
			if( photoObject === null || photoObject === undefined
					|| photoObject.item === undefined || photoObject.item === null
					|| photoObject.item.parent === undefined || photoObject.item.parent === null) {
				// Well, we don't have source point for animation. Nothing to be done
				console.log( "Photo item ", photoID, "has no source. Disabling animation")
				animate = false;
			} else {
				// We have item in cache and it has parent. We don't know what is it parent - some delegate,
				// or perhaps even ourselves if it is currently inside movement animation.
				// There is a potential for animation, so we preserve item (which is not owned by any object and lives as long
				// as there is any reference to it) across call to movePhotoToLevel
				photoItemPreservation = photoObject.item
				// Let's store it coordinates in photoObject before it is destroyed. Coordinates are in our coords/system
				photoObject.sourceCoords = photoItemPreservation.parent.mapToItem( visualControl, photoItemPreservation.x, photoItemPreservation.y)
				console.log( "Photo ", photoID, " source coords: ", photoObject.sourceCoords)
			}
		}

		var success = movePhotoToLevel(photoIndex, newLevel,
									   preserveCursorInLine)
		// Sucessful call to movePhotoToLevel  immediately leads to the destruction of the old delegate
		// and appropriate call to releasePhotoItem().
		// This all is done even before control returns from movePhotoToLevel

		if (success) {
			// Animation
			if (animate) {
				/*
				var refCount = d.movementRegistry[photoID]
				if (refCount === undefined) {
					refCount = 1
				} else {
					refCount++
				}*/ // TODO: REMOVE
				d.animatedMovementRegistry[photoID] = 1
				// Restore preserved item
				photoObject.item = photoItemPreservation
				d.prepareForAnimation(photoObject)
				console.log("Animated movement for ", photoID,
							" requested.")
				// d.movementRegistry[photoID] = refCount // TODO: REMOVE
			}
		} else {
			if( animate ) {
				// Clear unused data
				if( photoObject !== null && photoObject !== undefined ) {
					photoObject.sourceCoords = undefined
				}
			}
		}
	}
	function visualMoveCurrentPhotoUpLevel(preserveCursorInStripe) {
		visualMovePhotoToLevel(cursor.currentPhotoIndex,
							   cursor.currentLevel + 1,
							   preserveCursorInStripe, true)
	}
	function visualMoveCurrentPhotoDownLevel(preserveCursorInLine) {
		visualMovePhotoToLevel(cursor.currentPhotoIndex,
							   cursor.currentLevel - 1,
							   preserveCursorInLine, true)
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
	//	 "item": Item itself,
	//	 "movementAnimation" : animation that moves item to specified position and reparents it once done.
	// }
	// Delegate MUST keep reference to item as long as it lives, because item has no QObject-parent.
	function requestPhotoItem(photoID, newParent) {
		if (stripesModel === undefined || stripesModel === null) {
			console.error("Stripes model is undefined")
			return null
		}

		if (newParent === null || newParent === undefined) {
			console.error("Can't move to null parent")
			return null
		}

		if (photoID === undefined || photoID === null || photoID < 0
				|| photoID >= stripesModel.sourcePhotoModel.count) {
			console.warn("Requested PhotoID is invalid")
			return null
		}

		console.log("Request to move photo with ID ", photoID,
					"to new parent ", newParent)
		var photoObject = d.photoItemsCache[photoID]
		if (photoObject === undefined || photoObject === null) {
			// Cache record as a whole is missing
			console.log("VC: Photo", photoID, ": ", " cache miss. Creating cache object.")
			photoObject = {
				photoID: photoID
			}
		}

		if (photoObject.item === undefined || photoObject.item === null) {
			// Cache record contains no item - because item was already released
			console.log("VC: Photo", photoID, ": ","Cache object has no item. Creating item.")
			console.assert(d.rawPhotoViewComponent !== null
						   && d.rawPhotoViewComponent !== undefined)

			var photo = stripesModel.sourcePhotoModel.get(photoID)
			console.log("VC: Photo", photoID, ": ","Creating photo item. width: ", photo.width,
						"border.color: ", photo.color)
			// TODO: Must be binging height
			// Item has no QObject-parent. It exists as long as there is any reference to it.
			var item = d.rawPhotoViewComponent.createObject(null, {
																"photoID": photoID,
																"width": photo.width,
																"height": photoStripesView.stripeHeight,
																"border.color" : photo.color
															})
			item.parent = null
			photoObject.item = item

			d.photoItemsCache[photoID] = photoObject
		}

		// If there is a registered animated movement request, then try to animate
		if( d.animatedMovementRegistry[photoID] > 0) {
			d.initiateAnimatedMovement(photoObject, newParent)
		} else {
			// transfer immediately
			d.nonAnimatedMovement(photoObject.item, newParent)
		}

		return photoObject
	}

	function releasePhotoItem(photoID) {
		// TODO: Idea: replace value with undefined. Once size of dict grows to 100+ items, most of which are undefines, - create new object without undefines and copy it over
		// TODO: Update to previous todo - most 'removed' items will be objects with only visualControlCoords

		var cacheObject = d.photoItemsCache[photoID]
		if (cacheObject === undefined || cacheObject === null) {
			return
		}
		/*
		var item = cacheObject.item
		var animation = cacheObject.movementAnimation

		if (animation !== undefined && animation !== null) {
			animation.stop()
		}*/

		/* TODO: REMOVE unnecessary. Such animated precision is not needed
				if( item != undefined && item != null && item.parent != null ) {
							// Preserve coordinates for futher use
										var coordsInOurSystem = item.mapToItem(visualControl, 0, 0)
													cacheObject.visualControlCoords = coordsInOurSystem;
																console.log( "Caching coordinates for photoID ", photoID, ":", coordsInOurSystem)
																		}*/

		// Erase item. It will destroy it unless there is some other reference to it. For example in animation or another delegate.
		console.log("VC: Photo", photoID, " Releasing item");
		cacheObject.item = undefined
		//cacheObject.animation = undefined

		// TODO: IMplement ring buffer to store last 10(?) items
	}

	// We use one global timer instead of one timer per animation. No one is capable of
	// moving photos at rate one per sec
	Timer {
		id: pendingTimer
		interval : 1000
		repeat: false
		onTriggered: d.clearAnimations(); // TODO: Implement
	}

	QtObject {
		id: d

		// Cache of photo items. Key is photoID
		property var photoItemsCache: null

		// Registry of movements that must be animated. Basically
		// it is a pair PhotoID -> refCounter. refCounter is needed to track situation
		// when movement of the photo is interrupted by another movement of the same photo.
		// TODO: Do we need this variable ?
		// TODO: Do we really need to count references ?
		property var animatedMovementRegistry

		property var pendingAnimations
		property var pendingItems

		// RawPhotoView component used for dynamic creation
		property var rawPhotoViewComponent: null

		// MoveReparentAnimation component used for dynamic creation
		property Component moveReparentAnimationComponent

		Component.onCompleted: {
			rawPhotoViewComponent = Qt.createComponent("RawPhotoView.qml")
			moveReparentAnimationComponent = Qt.createComponent(
						"animations/MoveReparentAnimation.qml")
			if (moveReparentAnimationComponent.status != Component.Ready) {
				if (moveReparentAnimationComponent.status == Component.Error) {
					console.log("Error when loading MoveReparentAnimation.qml: ",
								moveReparentAnimationComponent.errorString())
					throw false
				}
			}

			photoItemsCache = {

			} // TODO: REMOVE ?
			animatedMovementRegistry = {

			}
			pendingAnimations = []
			pendingItems = []
		}

		function clearAnimations() {
			pendingItems = []
		}

		function prepareForAnimation(photoObject) {
			console.assert(photoObject.item !== undefined && photoObject.item !== null, "Error: can't prepare unexistent item for animation" );
			// We give only one second to initiate animation. We target delegate is not created within one second, then
			// no animation will be played
			pendingAnimations.push(photoObject) // TODO: What is this member for ?
			pendingItems.push(photoObject.item) // That will preserve item from being destroyed by garbage collector
			// Restart timer
			pendingTimer.restart();
		}

		// Function will initiate movement of photo item to specified newParent.
		// It will fallback to non-animated movement under certain conditions
		function initiateAnimatedMovement(photoObject, newParent) {

			if (photoObject.movementAnimation !== undefined
					&& photoObject.movementAnimation !== null) {
				// Interrupt current animation. We do not complete it, because it is unclear whether there currently
				// exist old-parent-target or not. Also, no point in unnecessary reparenting
				photoObject.movementAnimation.stop()
			}

			var item = photoObject.item
			console.log( "VC: Photo ", photoObject.photoID, " New parent in visualControl c/s: ", visualControl.mapFromItem(newParent, 0, 0))

			var sourceCoordsInNewParent
			// If item still has parent, then use it to find current coordinates
			if( item.parent !== null ) {
				// Item might still be moving from previous animation. So don't do item.mapToItem(newParent, 0, 0).
				sourceCoordsInNewParent = item.parent.mapToItem( newParent, item.x, item.y);
				console.log( "VC: Photo ", photoObject.photoID, " Source coords are taken from existing parent")
			} else {
				var sourceCoordsInVC = photoObject.sourceCoords
				if( sourceCoordsInVC !== undefined && sourceCoordsInVC !== null ) {
					sourceCoordsInNewParent = visualControl.mapToItem(newParent, sourceCoordsInVC.x, sourceCoordsInVC.y);
				}
				console.log( "VC: Photo ", photoObject.photoID, " Source coords are taken from cache. Global: ", sourceCoordsInVC,
							"local: ", sourceCoordsInNewParent)
			}

			if( sourceCoordsInNewParent === undefined || sourceCoordsInNewParent === null ) {
				// No animation
				console.log("Executing non-animated movement. Photo: ",
							photoObject.photoID)
				d.nonAnimatedMovement(item, newParent);
				return
			}

			/* REMOVE
			var refCount = d.movementRegistry[photoObject.photoID]
			// Non-animated movement
			if (refCount === undefined || refCount === 0) {
				console.log("Executing non-animated movement. Photo: ",
							photoObject.photoID)
				d.nonAnimatedMovement(item, newParent)
				return
			}
			refCount--
			d.movementRegistry[photoObject.photoID] = refCount*/



			// Reparent to newParent
			item.parent = newParent
			item.x = sourceCoordsInNewParent.x
			item.y = sourceCoordsInNewParent.y

			// TODO: REMOVE
			{
				var dbgTargetCoords = Qt.point(
					0, 0) //visualControl.mapFromItem( newParent, 0, 0);
				var dbgVCCoords = visualControl.mapFromItem(newParent,
															item.x, item.y)
				console.log("VC: moving from (", item.x, ",", item.y,
							") (global:", dbgVCCoords, ") to ", dbgTargetCoords)
			}

			var stripeIndex = stripesModel.findStripeIndexForPhotoID()
			var stripeObject = {
				raiseStripeZ: function () {
					return photoStripesView.raiseStripeZ(stripeIndex)
				},
				restoreStripeZ: function () {
					return photoStripesView.restoreStripeZ(stripeIndex)
				}
			}

			/*
			var newParentCoordsInOurSystemBinding = Qt.binding(function () {
				return visualControl.mapFromItem(newParent, 0, 0)
			})*/
			// Let's forget old animation entirely. It's state is unclear - it may have already finished,
			// it may have been interrupted by previous statement, etc
			photoObject.movementAnimation = d.moveReparentAnimationComponent.createObject(
						visualControl, {
							target: item,
							newParent: newParent,
							duration: 5000,
							stripeObject//"targetPoint" : newParentCoordsInOurSystemBinding,
							: stripeObject
						})
			photoObject.movementAnimation.start()
		}

		function nonAnimatedMovement(item, newParent) {
			item.parent = newParent
			item.x = 0
			item.y = 0
			item.anchors.fill = item.parent
		}

	}
}
