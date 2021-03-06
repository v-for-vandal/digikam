import QtQuick 2.6
import QtQml.StateMachine 1.0 as DSM

Item {
    id: photoStripesView
    // User properties
    property int stripesVisible: 3
    property alias sourcePhotoModel : stripesModelObject.sourcePhotoModel
	readonly property int stripeHeight : Math.floor( height/ stripesVisible) // TODO: Make user-settable
	property Item debugArea : null

    // Main view area. Mostly used internally
    readonly property Item viewAreaItem : viewArea
    // Cursor item
    readonly property QtObject cursorObject : cursor
    // Visual control item
    readonly property Item visualControlObject : visualControl

    // Returns current item
    function getCurrentPhoto() {
        if (currentPhotoID < 0 || currentPhotoID >= sourcePhotoModel.count) {
            return undefined
        }

        return sourcePhotoModel.get(currentPhotoID)
    }

    function getStripeViewItem(stripeIndex) {
        return stripesRepeater.itemAt(stripeIndex)
    }

    function ensureStripeVisibility(stripeIndex, forceTop) {
		//console.log("Ensuring visibility of stripe index ", stripeIndex)
        if( mainView.contentHeight == 0) {
            return; // There is nothing in view
        }
        if( forceTop == undefined ) {
            forceTop = false;
        }

        // In case this item was removed from the model. See Qt documentation.
        if (stripeIndex >= 0) {
            visibilityScrollingAnimation.stop()
            var pos = mainView.contentY
            var destPos;
            // Stripe itself
            var stripe = getStripeViewItem(stripeIndex);
            // To make stripe visible we need to either scroll flickable up if stripe is below current view area,
            // or down - if stripe is above. Or, if stripe is visible, than do nothing at all

            // stripe coordinates relative to contentItem and scaled to range [0,1]
            var stripeYStart = stripe.y / mainView.contentHeight;
            var stripeYEnd = (stripe.y + stripe.height) / mainView.contentHeight

            var visibleAreaStart = mainView.visibleArea.yPosition;
            var visibleAreaEnd = mainView.visibleArea.yPosition + mainView.visibleArea.heightRatio;

            if( forceTop ) {
                destPos = stripeYStart * mainView.contentHeight;
            } else {

            // Checking if stripe is already visible
            if( stripeYStart >= visibleAreaStart && stripeYEnd <= visibleAreaEnd ) {
                // Stripe is visible. do nothing
                return;
            }

            if( stripeYStart < visibleAreaStart ) {
                destPos = stripeYStart * mainView.contentHeight;
            } else if( stripeYEnd > visibleAreaEnd ) {
                var startDistance = stripeYStart - visibleAreaStart;
                var endDistance = stripeYEnd - visibleAreaEnd;
                console.assert(startDistance >= 0, "Error in algorithm");
                console.assert(endDistance >= 0, "Error in algorithm");
                if( startDistance <= endDistance ) {
                    destPos = stripeYStart * mainView.contentHeight;
                } else {
                    destPos = (stripeYEnd - mainView.visibleArea.heightRatio) * mainView.contentHeight;
                }

            } else {
                console.assert(false, "Error in algorithm")
                destPos = mainView.contentY;
            }
            }

            visibilityScrollingAnimation.from = pos
            visibilityScrollingAnimation.to = destPos
            visibilityScrollingAnimation.start()
        }
    }

    function ensurePhotoVisibility( stripeIndex, photoIndexInStripe ) {
        var stripe = getStripeViewItem(stripeIndex);
        stripe.ensurePhotoVisibility(photoIndexInStripe);
    }

    function expandStripe( stripeIndex ) {
        var stripe = getStripeViewItem(stripeIndex);
        stripe.expand()
    }

    function collapseStripe( stripeIndex ) {
        var stripe = getStripeViewItem(stripeIndex);
        stripe.collapse()
    }

    function raiseStripeZ( stripeIndex ) {
		var stripe = getStripeViewItem(stripeIndex);
        stripe.z = 2
    }

    function restoreStripeZ( stripeIndex ) {
        var stripe = getStripeViewItem(stripeIndex);
        stripe.z = 1
    }

    Component.onCompleted: {
        console.log("Self? :", photoStripesView)
        console.log( "Cursor object: ", cursor)
        console.log("StripesModel object: ", stripesModelObject)

        cursor.stripesModel = stripesModelObject // Why do we need this ?
    }

    // Stripes model
    StripesModel {
        id: stripesModelObject
    }

    Cursor {
        id: cursor
        stripesModel: photoStripesView.stripesModel // Because name clash
        highlight: CurrentPhotoHighlight {}
    }

    VisualControl {
        id: visualControl
        anchors.fill: parent // We need to draw it all over the view area
        stripeViews: photoStripesView
        stripesModel: stripesModelObject
        z : 4
    }

    FlickableSynchronizer {
        id: synchronizer
        flickables: columnPositioner.children
        mainFlickable: null
    }

    Item {
        id: viewArea
        anchors.fill: parent
        objectName: "ViewArea" // For debug purposes

        // We use Flickable + Column + Repeater instead of ListView because there won't be many stripes
        // and unlike ListView which may destroy delegates out of view, all stripes in Column will
        // always exist.
        Flickable {

            id: mainView // TODO: Rename overview
            anchors.fill: parent
            contentWidth: contentItem.childrenRect.width
            contentHeight: contentItem.childrenRect.height
            Column {
                id: columnPositioner
                spacing: 30
                Repeater {
                    id: stripesRepeater;
                    model: stripesModelObject.stripesModels

                    delegate: PhotoStripeViewDelegate {
                        width: mainView.width
                        height: stripeHeight
                        cursorObject: cursor
                        visualControlObject: visualControl
                        stripeModel: stripe // 'stripe' is the name of the role. This is delegate and thus it has direct access to roles of it's element
                    }
                }
            }


        }
    }

    NumberAnimation {
        id: visibilityScrollingAnimation
        target: mainView
        property: "contentY"
        duration: 500
		easing.type: Easing.OutQuad
    }

    Connections {
        target: cursor

        onCurrentPhotoIndexChanged: {
            // Search mainView for stipe with this level
            var currentPhotoIndex = cursor.currentPhotoIndex;
            var stripeIndex = currentPhotoIndex.y
            if (stripeIndex >= 0) {
                ensureStripeVisibility(stripeIndex)
            }
            var photoIndex = currentPhotoIndex.x
            if (photoIndex >= 0
                    && photoIndex < stripesModelObject.getStripe(stripeIndex).count) {
                ensurePhotoVisibility( stripeIndex, photoIndex);
            }
        }
    }


    DSM.StateMachine {
        id: stateMachine
        initialState : sInit
        running: true
        DSM.State {
            id: sInit
            onEntered : {
                console.log( "Initializing main view")
                mainView.visible = false;
            }

            DSM.SignalTransition {
                targetState: sRunning
                signal: stripesModelObject.initializationFinished
            }
        }

        DSM.State {
			id: sRunning
			initialState: sOverview

            onEntered : {
                console.log( "Running main view")
                mainView.visible = true
                stripesRepeater.model = stripesModelObject.stripesModels
                synchronizer.mainFlickable = getStripeViewItem(0)
            }

            DSM.SignalTransition {
                targetState: sInit
                signal: stripesModelObject.initializationStarted
            }

			// In this state all stripes are visible
			DSM.State {
				id: sOverview

				onEntered : {
					// Close current expanded stripe
					d.expandedStripe.collapse()
				}
			}

			// In this state one stripe is expanded across the screen
			DSM.State {
				id: sStripeView
			}

			// This state is continuation of sStripeView - only one photo
			// is visible at a time
			DSM.State {
				id: sPhotoView
			}
        }

    }

	Rectangle {
		parent: debugArea
		x: 0
		y: 0
		width: childrenRect.width
		height: childrenRect.height
		id: dbgView
		Column {
			Repeater {
				model: columnPositioner.children
				delegate : Rectangle {
					property var targetFlickable : modelData
					property bool isFlickable : ("stripeContentX" in targetFlickable)
					width: isFlickable ? childrenRect.width : 0
					height: isFlickable ? childrenRect.height : 0
					visible: isFlickable
					Grid {
						columns: 2
						spacing: 2
						horizontalItemAlignment: Grid.AlignLeft
						Text {
							text: "Flickable: "
						}
						Text {
							text: index
						}

						Text {
							text : "origin: "
						}
						Text {
							text : targetFlickable.stripeOriginX.toPrecision(3)
						}

						Text {
							text : "width: "
						}
						Text {
							text : targetFlickable.stripeContentWidth.toPrecision(3)
						}

						Text {
							text : "Position: "
						}
						Text {
							text : targetFlickable.stripeContentX.toPrecision(3)
						}
						Text {
							text : "Vis. x: "
						}
						Text {
							text : targetFlickable.stripeVisibleArea.xPosition.toPrecision(3)
						}
						Text {
							text : "Vis. width: "
						}
						Text {
							text : targetFlickable.stripeVisibleArea.widthRatio.toPrecision(3)
						}
						Text {
							text : "===="
						}
						Text {
							text : "===="
						}
					}
				}
			}
		}
	}

    /*
    onSourcePhotoModelChanged: {
        photoStripesView.state = "initializing"
        // clearing up
        d.stripesModels = []
        d.stripesModelsByLevel = {}

        // Take all photos from the model and see their levels
        if (sourcePhotoModel.count == 0) {
            return
        }

        var maxLevel = sourcePhotoModel.get(0).level
        var minLevel = sourcePhotoModel.get(0).level

        console.log("Source model has ", sourcePhotoModel.count, " photos")
        for (var i = 0; i < sourcePhotoModel.count; i++) {
            var item = sourcePhotoModel.get(i)
            //console.log("Item", item, "level ", item.level)
            if (item.level > maxLevel) {
                maxLevel = item.level
            }
            if (item.level < minLevel) {
                minLevel = item.level
            }
        }
        console.log("Max level is: ", maxLevel)
        if (maxLevel == undefined || minLevel == undefined) {
            // How is this possible ?
            return
        }

        // Create that much stripe models
        for (var i = minLevel; i <= maxLevel; i++) {
            var levelModel = Qt.createQmlObject(
                        "import QtQuick 2.0; PhotoStripeModel {}",
                        photoStripesView, "levelModel")
            levelModel.level = i
            d.stripesModels.push(levelModel)
            d.stripesModelsByLevel[i] = levelModel
        }

        // Reverse array
        d.stripesModels.reverse();
        console.log("Stripes models: ", d.stripesModels)

        // Populate stripes models
        for (var i = 0; i < sourcePhotoModel.count; i++) {
            var item = sourcePhotoModel.get(i)
            //console.log( "photo level: ", item.level, " index: ", i);
            var itemModel = d.stripesModelsByLevel[item.level]
            //console.log("model ", itemModel);
            itemModel.append({
                                 photoID: i
                             })
        }

        currentPhotoID = 0 // TODO: Make first photo in lowest possible level

        photoStripesView.state = "running"
    }*/

    // All private properties
    QtObject {
        id: d
    }
}
