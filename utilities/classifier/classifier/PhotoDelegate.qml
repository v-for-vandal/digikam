import QtQuick 2.0

Rectangle { // TODO: Make Item before deploying
	id: wrapper
	// Caution - this property is a dict and it won't be updated if data inside(!) model changed.
	// Do not bind/query photoSource for user-changable properties, such as 'level'
    readonly property var photoSource: stripeModel.sourcePhotoModel.get(
										 model.photoID)
	// This property is true when PhotoDelegate needs to be visible above everything else - for
	// example when drag operation is in progress
	readonly property alias needsVisibility : d.needVisibility;

    // Dimensions must be the same as RawPhotoView, otherwise animations suffers
	width: ListView.view.height / photoSource.height * photoSource.width
    height: ListView.view.height
    border.color: "pink"
    border.width: 2

    Item {
		// These values are 'default' state of object. Object must never be in default state,
		// so we use these values as indicator of an error
		width: 200
		height: 200

        id: photoPlaceHolder
		Drag.active: mouseHandler.drag.active
		Drag.dragType: Drag.Internal

		/*
		Behavior on y {
			NumberAnimation {
				duration: 300
				easing.type: Easing.OutQuad
			}
		}*/

		Drag.onDragStarted: {
			console.log("PD: Drag started")
		}
		Drag.onDragFinished: {
			console.log("PD: On drag finished")
		}
		Drag.onActiveChanged: {
			console.log("PD: drag active changed")
		}

		Drag.onHotSpotChanged: {
			console.log("PD: drag hot point:", Drag.hotSpot)
		}

		states : [
			State {
				name : "normal"
				when: !mouseHandler.drag.active
				ParentChange {
					target: photoPlaceHolder;
					parent: wrapper
					/*
					Component.onCompleted: {
						x = photoPlaceHolder.mapToItem(visualControlObject, photoPlaceHolder.x, photoPlaceHolder.y).x
						y = photoPlaceHolder.mapToItem(visualControlObject, photoPlaceHolder.x, photoPlaceHolder.y).y

					}*/
				}
				AnchorChanges {
					target: photoPlaceHolder;
					anchors.verticalCenter: undefined;
					anchors.horizontalCenter: undefined;
					anchors.top: wrapper.top;
					anchors.bottom: wrapper.bottom
					anchors.left: wrapper.left
					anchors.right: wrapper.right
				}
			},

			State {
				name: "inDrag"
				when: mouseHandler.drag.active
				AnchorChanges {
					target: photoPlaceHolder;
					anchors.verticalCenter: undefined;
					anchors.horizontalCenter: undefined;
					anchors.top: undefined;
					anchors.bottom: undefined
					anchors.left: undefined
					anchors.right: undefined
				}
				ParentChange {
					target: photoPlaceHolder;
					parent: photoStripeView.visualControlObject
					/*
					x: wrapper.mapToItem(visualControlObject, 0, 0).x
					y: wrapper.mapToItem(visualControlObject, 0, 0).y
					*/
				}
			}
		]

		transitions: [
			Transition {
				from: "inDrag"
				to: "*"
				// It is imperative for reparenting to finish before anchor's are restored
				// and animated.
				SequentialAnimation {
					ParentAnimation {}
					AnchorAnimation {
						easing.type: Easing.OutQuad
						duration: 350
					}
				}
			}

		]
    }

	MouseArea {
		id: mouseHandler
        anchors.fill: parent
		drag.target: photoPlaceHolder
        drag.axis: Drag.YAxis
        onClicked: {
            console.log( "Clicked on photo: ", model.photoID);
            console.log( "Global coords: ", wrapper.mapToItem(photoStripeView.visualControlObject, 0,0) )
            cursorObject.currentPhotoID = model.photoID;
        }
		/*
		onMouseYChanged: {
			console.log("PD: MouseY ", mouseY)
		}*/

		/*
		onPressed: photoPlaceHolder.grabToImage(function(result) {
						  photoPlaceHolder.Drag.imageSource = result.url
					  })*/
		onReleased: {
			if( drag.active) {
				var dropSuccessfull = false;
				if( drag.target.Drag.target !== null && ("dropLevel" in drag.target.Drag.target) ) {
					// It must be stripe. No way to check for it beforehand
					var targetLevel = drag.target.Drag.target.dropLevel
					// It's possible to drop onto self.
					if( targetLevel !== stripeModel.level ) {
						console.log("PD: Drag&Drop - moving photo to level ", targetLevel)
						dropSuccessfull = photoStripeView.visualControlObject.movePhotoToLevel(model.photoID, targetLevel)
					}
				}
			}
		}
    }

    Connections {
        target: cursorObject

        onCurrentPhotoIDChanged : {
            d.updateHighlight(cursorObject)
        }
    }
    function loadPhoto() {
        d.loadPhoto(d.photoID)
    }

    Component.onCompleted: {
        // Load photo onto self
        d.photoID = model.photoID;
        loadPhoto();
        d.updateHighlight(cursorObject);
        console.log( "Photo delegate is created: ", model.photoID)
    }

    Component.onDestruction: {
        //console.log( "Photo delegate is destroyed: ", model.photoID);
        // model.photoID is unavailable because connection to model is already severed
		//d.releasePhoto(d.photoID);
    }


    QtObject {
        id: d

        // Highlight item. Might be null
        property var highlightItem : null
		// Photo item. Photo item has no QObject-parent, so it is imperative
		// to have explicit reference to it as long as it needed
        property var photoItem;
        // Our id
        property int photoID;
		// True if we need to be visible above everyone else. For example during drag operation
		property bool needVisibility

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

			photoItem = visualControlObject.requestPhotoItem(id, photoPlaceHolder).item;
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
