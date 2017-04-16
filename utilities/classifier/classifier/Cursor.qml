import QtQuick 2.0

// Cursor is responsible for maintaining:
// 1. Current photo and operations for moving across all PhotoStripeModel
// 2. (Multiple)selection. Independent from current photo
QtObject {
    // ==  User settings: ==
    // StripesModel object
    property var stripesModel : null

    // == Operational properties ==

    // PhotoID of current photo. -1 if there is no current photo. Could be set by user
    property int currentPhotoID : -1
    readonly property var currentPhoto: currentPhotoID > 0 ? sourcePhotoModel.get(currentPhotoID) : null
    readonly property int currentLevel: currentPhoto != null ? currentPhoto.level : -1
    // 2d coordinates of the current photo. y attribute is stripe index, x attribute is photo index in stripe
    readonly property point currentPhotoIndex: {
        var stripeIndex = stripeModel.findStripeIndexForLevel(currentLevel)
        var photoIndex = stripeModel.findPhotoIndexInStripeByPhotoID(
                    stripeIndex, photoStripesView.currentPhotoID)
        return Qt.point(photoIndex, stripeIndex)
    }

    // Returns id of the next photo in current level. You can assign it to currentPhotoId
    function nextPhotoInLevel() {
        if( currentPhotoID === -1 || stripesModel === null) {
            return -1;
        }

        var stripeModel = stripesModels[currentPhotoIndex.y]
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
        var stripeModel = d.stripesModels[currentPhotoIndex.y]
        var index = currentPhotoIndex.x

        // If there is next photo in this stripe
        if (index - 1 >= 0) {
            return stripeModel.get(index - 1).photoID
        } else {
            // if there isn't, then return currentPhotoID
            return currentPhotoID
        }
    }

    // Returns PhotoID of the 'next' photo in the level below current with closest photoID
    // that resides in one level above
    // If level below current exists, but is empty, then search upwards for the first non-empty level
    function photoInLevelDownByPhotoID() {
        // Checking if there is any level above that
        var levelIndex = currentPhotoIndex.y
        if (levelIndex >= d.stripesModels.length) {
            console.error("Can't find model for current level")
            return currentPhotoID
        }
        // Searching for next populated levelIndex
        var nextPopulatedLevel = levelIndex + 1 // +1 because d.stripesModels is inversed
        for (; nextPopulatedLevel < d.stripesModels.length; nextPopulatedLevel++) {
            if (d.stripesModels[nextPopulatedLevel].count > 0) {
                break
            }
        }

        if (nextPopulatedLevel >= d.stripesModels.length) {
            // Well, there is no level above that one.
            return currentPhotoID
        }

        var nextLevelModel = d.stripesModels[nextPopulatedLevel]
        var closestPhotoIndex = d.findNearestInStripeByPhotoID(currentPhotoID,
                                                               nextLevelModel)

        return nextLevelModel.get(closestPhotoIndex).photoID
    }

    // Returns PhotoID of the 'next' photo in the level above current with closest photoID
    // that resides in one level above
    // If level above current exists, but is empty, then search upwards for the first non-empty level
    function photoInLevelUpByPhotoID() {
        // Checking if there is any level above that
        var levelIndex = currentPhotoIndex.y
        if (levelIndex >= d.stripesModels.length) {
            console.error("Can't find model for current level")
            return currentPhotoID
        }
        // Searching for next populated levelIndex
        var nextPopulatedLevel = levelIndex - 1 // -1 because d.stripesModels is inverted
        for (; nextPopulatedLevel >= 0; nextPopulatedLevel--) {
            if (d.stripesModels[nextPopulatedLevel].count > 0) {
                break
            }
        }

        if (nextPopulatedLevel < 0) {
            // Well, there is no level below that one.
            return currentPhotoID
        }

        var nextLevelModel = d.stripesModels[nextPopulatedLevel]
        var closestPhotoIndex = d.findNearestInStripeByPhotoID(currentPhotoID,
                                                               nextLevelModel)

        return nextLevelModel.get(closestPhotoIndex).photoID
    }

    onCurrentLevelChanged: {
        console.log("Current level is now: ", currentLevel)
    }

}
