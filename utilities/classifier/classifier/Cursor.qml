import QtQuick 2.0

// Cursor is responsible for maintaining:
// 1. Current photo and operations for moving across all PhotoStripeModel
// 2. (Multiple)selection. Independent from current photo
Item {
    id: cursor
    // ==  User settings: ==
    // StripesModel object
    property var stripesModel
    // Lock in horizontal movement (in stripe) only
    property bool lockInStripe : false

    // == Operational properties ==

    // PhotoID of current photo. -1 if there is no current photo. Could be set by user
    property int currentPhotoID : -1
    // See comment to d.forceUpdater and forceUpdate() method why it is needed
    readonly property var currentPhoto: d.forceUpdater, currentPhotoID >= 0 ? stripesModel.sourcePhotoModel.get(currentPhotoID) : undefined
    readonly property int currentLevel: currentPhoto !== undefined ? currentPhoto.level : -1
    // 2d coordinates of the current photo. y attribute is stripe index, x attribute is photo index in stripe
    readonly property point currentPhotoIndex: {
        if( currentPhotoID === -1) {
            return Qt.point(-1,-1);
        }

        // It is better to query photo level explicitly instead of relying on currentLevel property - because order of properties
        // binding updates is undetermined and currentLevel might be incorrect when currentPhotoIndex is updated;
        var photoLevel = stripesModel.sourcePhotoModel.get(currentPhotoID).level
        var stripeIndex = stripesModel.findStripeIndexForLevel(photoLevel)
        var photoIndex = stripesModel.findPhotoIndexInStripeByPhotoID(
                    stripeIndex, currentPhotoID)

        return Qt.point(photoIndex, stripeIndex)
    }

    // Component to use as highlight
    property Component highlight

    // Highlight item. Auto-generated from highlight component
    readonly property alias highlightItem : d.highlightItem

    // Returns id of the next photo in current level. You can assign it to currentPhotoId
    function nextPhotoInLevel() {
        if( currentPhotoID === -1 || stripesModel === null) {
            return -1;
        }

        var stripeModel = stripesModel.getStripe(currentPhotoIndex.y)
        var index = currentPhotoIndex.x

        // If there is next photo in this stripe
        if (index + 1 < stripeModel.count) {
            return stripeModel.get(index + 1).photoID
        } else {
            // if there isn't, then return currentPhotoID
            return currentPhotoID
        }
    }

    // Returns id of the previous photo in current level
    function previousPhotoInLevel() {
        var stripeModel = stripesModel.getStripe(currentPhotoIndex.y)
        var index = currentPhotoIndex.x

        // If there is next photo in this stripe
        if (index - 1 >= 0) {
            return stripeModel.get(index - 1).photoID
        } else {
            // if there isn't, then return currentPhotoID
            return currentPhotoID
        }
    }

    // Returns id of the photo in current stripe where cursor should be placed if current photo was removed from this stripe
    // If there is photo after current in stripe, then it will be selected
    // If there isn't, then previous in stripe will be selected
    // If there aren't previous and next, then -1 will be returned
    function findPreservationPhotoIDInLevel() {
        if( currentPhotoID === -1) {
            return -1;
        }

        var newCursorPhotoID = nextPhotoInLevel();
        if( newCursorPhotoID === currentPhotoID) {
            newCursorPhotoID = previousPhotoInLevel();
        }
        if( newCursorPhotoID === currentPhotoID) {
            return -1;
        }

        return newCursorPhotoID;
    }

    // Returns PhotoID of the 'next' photo in the level below current with closest photoID
    // that resides in one level above
    // If level below current exists, but is empty, then search upwards for the first non-empty level
    function photoInLevelDownByPhotoID() {
        if( lockInStripe ) {
            return;
        }

        // Checking if there is any level above that
        var levelIndex = currentPhotoIndex.y
        if (levelIndex >= stripesModel.stripesCount()) {
            console.error("Can't find model for current level")
            return currentPhotoID
        }
        // Searching for next populated levelIndex
        var nextPopulatedLevelIndex = levelIndex + 1 // +1 because d.stripesModels is inversed
        var count = stripesModel.stripesCount();
        for (; nextPopulatedLevelIndex < count; nextPopulatedLevelIndex++) {
            if (stripesModel.getStripe(nextPopulatedLevelIndex).count > 0) {
                break
            }
        }

        if (nextPopulatedLevelIndex >= count) {
            // Well, there is no level above that one.
            return currentPhotoID
        }

        var nextLevelModel = stripesModel.getStripe(nextPopulatedLevelIndex)
        var closestPhotoIndex = stripesModel.findNearestInStripeByPhotoID(currentPhotoID,
                                                               nextPopulatedLevelIndex)

        return nextLevelModel.get(closestPhotoIndex).photoID
    }

    // Returns PhotoID of the 'next' photo in the level above current with closest photoID
    // that resides in one level above
    // If level above current exists, but is empty, then search upwards for the first non-empty level
    function photoInLevelUpByPhotoID() {
        if( lockInStripe ) {
            return;
        }

        // Checking if there is any level above that
        var levelIndex = currentPhotoIndex.y
        if (levelIndex >= stripesModel.stripesCount()) {
            console.error("Can't find model for current level")
            return currentPhotoID
        }
        // Searching for next populated levelIndex
        var nextPopulatedLevelIndex = levelIndex - 1 // -1 because d.stripesModels is inverted
        for (; nextPopulatedLevelIndex >= 0; nextPopulatedLevelIndex--) {
            if (stripesModel.getStripe(nextPopulatedLevelIndex).count > 0) {
                break
            }
        }

        if (nextPopulatedLevelIndex < 0) {
            // Well, there is no level below that one.
            return currentPhotoID
        }

        var nextLevelModel = stripesModel.getStripe(nextPopulatedLevelIndex)
        var closestPhotoIndex = stripesModel.findNearestInStripeByPhotoID(currentPhotoID,
                                                               nextPopulatedLevelIndex)

        return nextLevelModel.get(closestPhotoIndex).photoID
    }

    // When data inside source photo model changes, cursor must be updated. ListModel has no 'changed' signal,
    // so it must be done manually
    // Example - when changing 'level' property of photo
    function forceUpdate() {
        d.forceUpdater = (d.forceUpdater + 1) % 2
    }

    onCurrentLevelChanged: {
		//console.log("Current level is now: ", currentLevel)
    }

    onStripesModelChanged: {
		//console.log("New stripes model is: ", stripesModel)
    }

    QtObject {
        id: d

        // Property is used to trick QML into updating some bindings when data in model (not model itself, but data inside it)
        // is changed.
        property int forceUpdater : 0;

        // Current highlight item. It visual parent may change,
        // but it's QObject parent is always cursor
        property Item highlightItem
    }

    Component.onCompleted: {
        // Cursor itself is not drawable
        parent = null
    }

    onHighlightChanged: {
        // Safely erase previous highlight item
        if( d.highlightItem !== null && d.highlightItem !== undefined ) {
            d.highlightItem.parent = null
            d.highlightItem = 0;
        }
        if( highlight !== undefined && highlight !== null) {
            var newHighlight = highlight.createObject(cursor)
            newHighlight.parent = null
            d.highlightItem = newHighlight
        }
    }
}
