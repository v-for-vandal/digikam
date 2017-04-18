import QtQuick 2.0

import "algorithm.js" as Algorithm

// Photos separated into layers
// Item instead of QtObject because QtObject doesn't allow to declare other QtObjects inside self
// Some error in Qml itself, complains on 'unexistent default property'
Item {
    id: thisObject
    parent: null // We won't draw it anyway
    visible: false
    enabled : false

    // Input property - photo source model
    property var sourcePhotoModel
    // Input property - maximum number of levels
    property int maximumAllowedLevel : 100 // TODO: Handle this limitation in WorkerScript

    // Generated properties
    // Holds array of all stripe models. In reverse order - because, for some unbelievable
    // (and unknown) reason, QML Column can't place it's children in bottom-to-top direction
    readonly property var stripesModels : d.stripesModels
    // Same models, but in a dict, with level as a key
    readonly property var stripesModelsByLevel : d.stripesModelsByLevel
    // Initialization error, if any
    readonly property string initializationError : d.initializationError

    // Signals
    signal initializationStarted;
    signal initializationFinished;

    // Returns stripe object by stripe index. undefined for indices out of range
    function getStripe( stripeIndex ) {
        var proxy = d.stripesModels.get(stripeIndex);
        if( proxy === undefined ) {
            return undefined;
        }
        return proxy.stripe;
    }

    // Current amount of stripes
    function stripesCount() {
        return d.stripesModels.count;
    }

    // Returns photo index of a photo with given ID. photo index is QPoint( index in stripe, stripe index)
    // undefined if photo with such ID do not exist
    function photoIndexByPhotoID(targetPhotoID) {
        if (targetPhotoID < 0
                || targetPhotoID >= stripesModels.sourcePhotoModel.count) {
            return undefined
        }

        var photo = d.stripesModels.sourcePhotoModel.get(targetPhotoID)
        var level = photo.level
        var stripeIndex = findStripeIndexForLevel(level)
        var photoIndexInStripe = findPhotoIndexInStripeByPhotoID(stripeIndex, targetPhotoID)

        return Qt.point(photoIndexInStripe, stripeIndex)
    }

    // Returns index of a photo in a given stripe with PhotoID closest to the given one
    function findNearestInStripeByPhotoID(targetPhotoID, stripeIndex) {
        var stripeModel = getStripe(stripeIndex);
        // Searching for the photo with closed photoID
        console.assert(stripeModel != undefined)
        var closestPhotoIndex = 0
        var closestPhotoID = stripeModel.get(0).photoID
        var minimumDistance = Math.abs(targetPhotoID - closestPhotoID)
        for (var photoIndex = 0; photoIndex < stripeModel.count; photoIndex++) {
            var photoID = stripeModel.get(photoIndex).photoID
            var distance = Math.abs(photoID - targetPhotoID)
            if (distance <= minimumDistance) {
                closestPhotoIndex = photoIndex
                closestPhotoID = photoID
                minimumDistance = distance
            }
            if (distance == 0) {
                break
            }
        }

        return closestPhotoIndex
    }

    // Returns index of a stripe in d.stripesModels for given level
    // Returns -1 on error
    function findStripeIndexForLevel(targetLevel) {
        if (d.stripesModels.count === 0) {
            return -1
        }
        if( targetLevel === -1) {
            return -1;
        }

        // Assumption that all stripes are sequential and no stripe is missing
        // And stipesModels is also reversed
        var firstStripeLevel = getStripe(0).level

        console.log( "Looking targetLevel: ", targetLevel, " Total stripes count: ", d.stripesModels.count, " firstStripeLevel: ", firstStripeLevel);

        var result = firstStripeLevel
                - targetLevel // Because sequential and without missing stripes.

        if( result < 0 || result >= d.stripesModels.count) {
            // No stripe for this level, level is out of range
            return -1;
        }

        // But let's check anyway
        console.assert(getStripe(result).level === targetLevel,
                       "d.stripesModels is not sequential! Stripe for level ", targetLevel, "at index ", result, " has level property set to: ", getStripe(result).level)
        return result
    }

    // Returns index of photo with given photoID in given stripe. -1 if stripe has no such photo
    function findPhotoIndexInStripeByPhotoID(stripeIndex, targetPhotoID) {
        console.log("Searching photo with ID ", targetPhotoID,
                    " in stripe on index ", stripeIndex)
        if (stripeIndex < 0 || stripeIndex >= d.stripesModels.count) {
            console.log("Stripe index is out of range")
            return -1
        }
        var stripe = getStripe(stripeIndex)
        var result = Algorithm.binarySearch(stripe, targetPhotoID,
                                            d.photoIDStripeAccessor, 0,
                                            stripe.count)
        return result
    }

    // Move photo on given index to given level. index is QPoint(index in stripe, stripe index)
    //  See photoIndexByPhotoID function
    // if autoCreateLevel is true, then in case of absence newLevel and all missing levels below it will be created
    function movePhotoByIndexToLevel( photoIndex, newLevel, autoCreateLevel ) {
        console.log( "Move photo ", photoIndex, " to new level ", newLevel)
        if( autoCreateLevel === undefined ) {
            autoCreateLevel = false;
        }

        if( newLevel < 0 ) {
            return;
        }

        var stripeIndex = photoIndex.y
        var stripe = getStripe(stripeIndex);
        if( stripe === undefined ) {
            // stripe index out of range
            return;
        }

        // If newLevel is equal to current level, then do nothing
        if( stripe.level === newLevel ) {
            return;
        }

        var photoIndexInStripe = photoIndex.x
        if( photoIndexInStripe < 0 || photoIndexInStripe >= stripe.count) {
            // photo index in current stripe is out of range
            return;
        }

        var photoID = stripe.get(photoIndexInStripe).photoID;

        var targetStripeIndex = findStripeIndexForLevel(newLevel)
        console.log( "Stripe lookup result: ", targetStripeIndex)
        if( targetStripeIndex === -1 || targetStripeIndex === undefined ) {
            console.log( "No stirpe for level ", newLevel)
            if( autoCreateLevel ) {
                if( !ensureLevelExists(newLevel) ) {
                    console.error( "Can't create necessary level");
                    return;
                }

                targetStripeIndex = findStripeIndexForLevel(newLevel);
                if( targetStripeIndex === -1 || targetStripeIndex === undefined ) {
                    console.error("Error: can't create new stripes. Desired level is: ", newLevel);
                    return;
                }
            } else {
                return;
            }
        }

        var targetStripe = getStripe(targetStripeIndex);
        var insertionPosition = Algorithm.binarySearch( targetStripe, photoID, d.photoIDStripeAccessor, 0, targetStripe.count );
        // insertionPosition must be negative. Positive one means that photo is already in the stripe
        if( insertionPosition >= 0) {
            console.error( "Photo is already in target stripe");
            return;
        }

        insertionPosition = -(insertionPosition+1);
        // Removing from current stripe
        stripe.remove( photoIndexInStripe, 1);
        // Adding to new Positioner
        var photo = {
            'photoID' : photoID
        }

        targetStripe.insert(insertionPosition, photo);

        // Changing level in source photo
        sourcePhotoModel.get(photoID).level = newLevel
    }

    // Makes sure stripe for given level exists. Creates as many levels as necessary.
    // Returns true on success, false if stripe for requested level could not be created
    // Usually because level is below 0 or more than maximum allowed levels
    // Returns false if targetLevel is invalid - null, undefined, -1
    function ensureLevelExists(targetLevel) {
        console.log( "Ensure level exists ", targetLevel)
        if( targetLevel === undefined || targetLevel === null || targetLevel < 0 || targetLevel > maximumAllowedLevel) {
            return false;
        }

        if( d.stripesModels.count === 0) {
            // Easy. Just creating one level
            var stripe = createNewStripe()
            stripe.level = targetLevel;
            d.stripesModels.insert(0, {'stripe' : newStripe})
            d.stripesModelsByLevel[targetLevel] = stipe;
            return true;
        } else {
            // d.stripes is inverted!
            var maxLevel = getStripe(0).level
            var minLevel = getStripe(d.stripesModels.count - 1).level
            if( targetLevel > maxLevel ) {
                return d.addNewStripesAbove(targetLevel - maxLevel);
            } else if( targetLevel < minLevel ) {
                console.log( "Adding ", minLevel - targetLevel, " stripes below");
                return d.addNewStripesBelow(minLevel - targetLevel)
            } else {
                // targetLevel already exists
                return true;
            }
        }
    }

    WorkerScript {
        id: initializationWorker
        source: "workers/photoStripesViewInitializer.js"
        property var requestData
        property int nextRequestId : 0

        function startInitialization(sourceStripeModels) {
            if( requestData == undefined ) {
                requestData = {}
            }
            var currentRequestId = nextRequestId;

            // We need to save sourceStipeModels in requestData for access from onMessage handler
            var workerArgs = {
                'sourcePhotoModel' : sourcePhotoModel,
                'sourceStripesModels' : sourceStripeModels,
                'requestId' : currentRequestId
            }
            requestData[currentRequestId] = sourceStripeModels.slice();
            console.log( "Request data: ", requestData[currentRequestId]);
            nextRequestId++;

            initializationWorker.sendMessage(workerArgs);
        }

        onMessage: {
            var requestId = messageObject.requestId;
            console.assert(requestId != undefined, "RequestId is undefined")
            console.assert( requestData[requestId] != undefined, "No data matching requestId");

            if( messageObject.status == 'started') {
                console.log( "Initialization started");
                thisObject.initializationStarted();
            } else if( messageObject.status == 'finished' ) {
                var sourceStripesModels = requestData[requestId]
                console.assert(sourceStripesModels != undefined, 'Somehow input for request was lost. RequestId is', requestId);
                // d.stripesModels = [] TODO: Decide
                d.stripesModels = Qt.createQmlObject("import QtQuick 2.0; ListModel {}", d)
                d.stripesModelsByLevel = {}
                for( var i = 0; i < messageObject.models.length; i++) {
                    var sourceIndex = messageObject.models[i];
                    console.log( "Model index in source array ", sourceIndex)
                    var sourceModel = sourceStripesModels[sourceIndex];
                    sourceModel.level = messageObject.levels[sourceIndex];
                    sourceModel.sourcePhotoModel = sourcePhotoModel
                    console.log( "Stripe. Level ", sourceModel.level, " Photos count: ", sourceModel.count);

                    //d.stripesModels.push( sourceModel ); // TODO: Decide
                    d.stripesModels.append({"stripe" : sourceModel });
                    d.stripesModelsByLevel[sourceModel.level] = sourceModel;
                }

                console.log( "Stripes models: ", d.stripesModels)
                console.log( "Stripes models map: ", d.stripesModelsByLevel)
                requestData[messageObject.requestId] = undefined
                console.log( "Initialization finished");
                thisObject.initializationFinished();
            } else if( messageObject.status == 'error') {
                d.initializationError = messageObject.errorMsg;
                requestData[messageObject.requestId] = undefined
                console.error( "Initialization error: ", d.initializationError);
            } else {
                requestData[messageObject.requestId] = undefined
                console.error( "Unknown initialization error");
            }
        }
    }

    onSourcePhotoModelChanged: {
        //console.log( "Component status: ", d.componentCompleted)
        //console.log( "New model is ", sourcePhotoModel);
        if( d.componentCompleted ) {
            d.initializeAsync();
        }
    }

    Component.onCompleted: {
        //console.log( "Component finished initialization")
        d.componentCompleted = true;
        d.initializeAsync();
    }

    QtObject {
        id: d
        // Generated properties
        // Holds array of all stripe models. In reverse order - because, for some unbelievable
        // (and unknown) reason, QML Column can't place it's children in bottom-to-top direction
        property var stripesModels
        // Same models, but in a dict, with level as a key
        property var stripesModelsByLevel
        // Initialization error, if any
        property string initializationError
        // Is initialization of the component completed. Before that we can't call
        // asynchronious initialization
        property bool componentCompleted : false;

        function photoIDStripeAccessor(stripeModel, index) {
            var item = stripeModel.get(index)
            if (item === undefined) {
                return undefined
            }
            return item.photoID
        }

        function createStripeModel() {
            var result = Qt.createQmlObject(
                        "import QtQuick 2.0; PhotoStripeModel {}",
                        photoStripesView, "levelModel") // TODO: Use null as a parent ?
            result.sourcePhotoModel = sourcePhotoModel;
            return result;
        }

        // Adds empty stripe 'above' top one. true if success, false if failed,
        // for example because exceeded maximumAllowedLevel
        // if stripesModels is empty (no stripes), then creates stripe with level 0.
        function addNewStripeAbove() {
            var newLevel = undefined;
            if( stripesModels.count > 0) {
                // Array is inverted!
                newLevel = getStripe(0).level + 1
            } else {
                newLevel = 0;
            }

            if( newLevel > maximumAllowedLevel) {
                return false;
            }

            var newStripe = createStripeModel();
            newStripe.level = newLevel

            d.stripesModels.insert( 0, {'stripe' : newStripe } );
            d.stripesModelsByLevel[newLevel] = newStripe;

            return true;
        }

        // Add N empty stripes 'above' top one. False if unsuccessful.
        // It either will create count stripes and success, or create 0 stripes and fail.
        function addNewStripesAbove(count) {
            if( count === undefined) {
                count = 1
            }
            // Checking that we can create count stripes above
            var maxLevel = undefined;
            if( stripesModels.count === 0) {
                maxLevel = -1
            } else {
                maxLevel = getStripe(0).level
            }

            if( maxLevel + count > maximumAllowedLevel) {
                return false;
            }

            for( var i = 0; i < count; i++ ) {
                if( !addNewStripeAbove() ) {
                    throw false;
                }
            }
            return true
        }

        // Same as addNewStripeAbove, but 'below' bottom one. Won't create
        // stripes if level is negative, obviously. In case of error returns false
        // If there are no stripes, then DOES NOTHING - unlike addNewStripeAbove(!) - and returns false
        function addNewStripeBelow() {
            if( stripesModels.count === 0) {
                return false;
            }

            var newLevel = getStripe(stripesModels.count-1).level - 1;
            if( newLevel < 0) {
                return false;
            }
            var newStripe = createStripeModel();
            newStripe.level = newLevel
            console.log( "New stripe below level is ", newLevel)

            d.stripesModels.append( {'stripe' : newStripe } );
            d.stripesModelsByLevel[newLevel] = newStripe;
            return true
        }

        function addNewStripesBelow(count) {
            if( count === undefined ) {
                count = 1
            }
            console.log( "Adding ", count, " stripes below");
            if( stripesModels.count === 0) {
                return false;
            }
            var minLevel = getStripe( stripesModels.count - 1).level;
            if( minLevel - count < 0) {
                return false;
            }

            for( var i = 0; i < count; i++) {
                if( !addNewStripeBelow() ) {
                    throw false;
                }
            }
            return true;
        }

        function initializeAsync() {
            console.log( "Asynchronious initialization");
            // Clear current results
            d.stripesModels = []
            d.stripesModelsByLevel = {}
            // Create as much stripe models as we need
            var sourceStripeModels = []
            // Model could be undefined
            if( sourcePhotoModel !== undefined ) {
                for( var i = 0; i < sourcePhotoModel.numberOfLevels; i++ ) {
                    var levelModel = createStripeModel();
                    sourceStripeModels.push(levelModel)
                }
            }

            initializationWorker.startInitialization(sourceStripeModels);
        }
    }
}
