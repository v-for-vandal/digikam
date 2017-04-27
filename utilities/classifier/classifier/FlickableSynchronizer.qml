import QtQuick 2.0

Item {
	parent: null // Undrawable
	width: 0
	height: 0

	// Current 'main' flickable
	property var mainFlickable: null

	// list of all flickables
	property var flickables: []

	function makeActive(object) {
		if (object === undefined) {
			object = null
		}

		mainFlickable = object
	}

	onMainFlickableChanged: {
		console.log("FS: New main flickable: ", mainFlickable)
	}
	onFlickablesChanged: {
		console.log("FS: Flickables changed. Object is ", flickables)
	}

	/*
		Connections {
				target: mainFlickable
						onStripeContentXChanged : {
									console.log( "new contentX: ", mainFlickable.stripeContentX)
											}
												}*/

	// Main binding
	/*
		Binding {
				when: mainFlickable !== null && mainFlickable.stripeVisibleArea !== undefined
						target : d
								property : "syncPosition"
										value: mainFlickable.stripeVisibleArea.xPosition
											}*/

	// slave bingins
	Repeater {
		model: flickables
		delegate: Item {
			property var targetFlickable: flickables[index]
			property bool shouldBeActive: ("stripeContentX" in targetFlickable)
										  && ("stripeVisibleArea" in targetFlickable)

			property var bindingLock: false

			function getQuantifiedPosition() {
				var visWidth = targetFlickable.stripeVisibleArea.widthRatio;
				console.log("FS: getQuantPos: visWidth: ", visWidth, " xPos ",
							targetFlickable.stripeVisibleArea.xPosition)
				console.assert( !isNaN(targetFlickable.stripeVisibleArea.widthRatio),
							   "FS: getQuantPos: visWidth is NaN")
				if( visWidth >= 0.99 ) {
					return 0;
				}

				return Math.floor(
							targetFlickable.stripeVisibleArea.xPosition
							/ (1 - visWidth)
							* 100) // 100 - quantinization
			}

			Connections {
				target: targetFlickable
				enabled: shouldBeActive && !d.updateLock
				ignoreUnknownSignals: true
				onStripeVisibleAreaChanged: {
					// console.log( "FS: stripe visible area changed")
					updateQuantifiedPosition()
				}
				onStripeContentXChanged: {
					//console.log( "FS: stripe visible area changed")
					updateQuantifiedPosition()
				}
				onStripeContentWidthChanged : {
					updateQuantifiedPosition()
				}
				onStripeOriginXChanged : {
					updateQuantifiedPosition()
				}
			}

			Connections {
				target: d
				enabled: shouldBeActive

				onSyncPositionChanged: {
					// Binding lock prevent updating ourself when user flicks us.
					// Otherwise, the follwoing happens:
					// user flicks -> Flickable moves ContentX with it's own animation ->
					// d.syncPosition changes -> updateFlickablePosition is called ->
					// updateFlickablePosition launches it's own animation moving Flickable.
					if (!bindingLock) {
						updateFlickablePosition()
					}
				}
			}

			NumberAnimation {
				id: artificialFlickAnimation
				target: targetFlickable
				property: "stripeContentX"
				easing.type: Easing.InOutQuad
				duration: 200
			}

			Connections {
				target: artificialFlickAnimation

				onStopped : {
					recalibrateFlickablePosition();
				}

				/*
				onStripeContentWidthChanged : {
					recalibrateFlickablePosition()
				}
				onStripeOriginXChanged : {
					recalibrateFlickablePosition()
				}*/
				/*
				onStopped : {
					recalibrateFlickablePosition()
				}*/
			}

			function updateQuantifiedPosition() {
				// If stripe has zero width/visual area, then do nothing - it's either not visible,
				// or has not finished initializing
				if( isNaN(targetFlickable.stripeVisibleArea.widthRatio) || isNaN(targetFlickable.stripeVisibleArea.xPosition) ) {
					return
				}

				// If inside animation, do nothing
				if( artificialFlickAnimation.running ) {
					return;
				}
				console.log( "FS: Flickable ", index, " contentX: ", targetFlickable.stripeContentX,
						" originX: ", targetFlickable.stripeOriginX, "width: ", targetFlickable.stripeContentWidth)

				// Global lock for signals
				d.updateLock = true
				// Local lock for bingin
				bindingLock = true
				// Updating position
				d.syncPosition = getQuantifiedPosition()
				// Releasing locks
				d.updateLock = false
				bindingLock = false
			}

			// Returns content position matching current d.syncPosition
			function getContentPositionFromSynced() {
				// If visibleArea.widthRatio === Nan, then stripe is either invisible,
				// or has not initialized itself
				if( targetFlickable.stripeVisibleArea.widthRatio === NaN ) {
					return 0;
				}

				var calibratedInterval = 1 - targetFlickable.stripeVisibleArea.widthRatio
				var newContentPosition = ((d.syncPosition / 100.0
										  * calibratedInterval)
										  * targetFlickable.stripeContentWidth
										  + targetFlickable.stripeOriginX)
				// No bouncing in slave movement
				newContentPosition = Math.max( newContentPosition, targetFlickable.stripeOriginX)
				newContentPosition = Math.min( newContentPosition,
										  targetFlickable.stripeOriginX
										  + targetFlickable.stripeContentWidth * calibratedInterval )
				return newContentPosition
			}

			// Update's flickable content position when d.syncPosition changed
			function updateFlickablePosition() {
				/*
				console.log("FS: updateFlickablePosition. ", targetFlickable,
							"target q/p: ", getQuantifiedPosition(),
							" sync/p ", d.syncPosition)*/
				if (getQuantifiedPosition() !== d.syncPosition ) {
					console.log("FS: Flickable ", index, " updating position")
					/*
					console.log("FS: New content position: ",
								newContentPosition)*/
					var newContentPosition = getContentPositionFromSynced()
					if( animateMovementToPosition(newContentPosition)) {
						console.log("FS: Flickable ", index, " slave movement from ", artificialFlickAnimation.from,
								" to ", artificialFlickAnimation.to, " duration ", artificialFlickAnimation.duration)
					}
				} else {
					console.log( "FS: Flickable ", index, " is within current quant")

					//return targetFlickable.stripeOriginX; // Don't change
				}
			}

			// When OUR width or originPoint changes, we neet to recalibrate OURSELF
			function recalibrateFlickablePosition() {
				var newContentPosition = getContentPositionFromSynced()
				if( animateMovementToPosition(newContentPosition)) {
					console.log("FS: Flickable ", index, " slave movement(recalibration) from ", artificialFlickAnimation.from,
							" to ", artificialFlickAnimation.to, " duration ", artificialFlickAnimation.duration)
				}

			}

			// If newPos is different then current pos, restart animation that chagnes stripeContentX.
			// Returns true if animation war started
			function animateMovementToPosition( newPos ) {
				artificialFlickAnimation.stop();
				artificialFlickAnimation.to = newPos;
				artificialFlickAnimation.from = targetFlickable.stripeContentX
				artificialFlickAnimation.duration = (
							Math.abs(artificialFlickAnimation.to - artificialFlickAnimation.from)
							/ 2 )
				if( artificialFlickAnimation.to !== artificialFlickAnimation.from) {
					artificialFlickAnimation.start();
					return true
				}

				return false
			}

/*
Component.onCompleted:  {
console.log("FS: Target flickable is: ", targetFlickable)
if( "stripeVisibleArea" in targetFlickable) {
targetFlickable.stripeVisibleAreaChanged.connect(updateQuantifiedPosition)
console.log("FS: Contains stripeVisibleAreaChanged signal")
}
}*/

		}
	}

	QtObject {
		id: d

		// Unified position. Range is 0.0 - 1.0(double), but quantified to [0-100](int)
		property real syncPosition: 0
		// Update lock. To prevent binding loops
		property bool updateLock: false

		onSyncPositionChanged: {
			console.log("FS: sync position is ", syncPosition)
		}
	}
}
