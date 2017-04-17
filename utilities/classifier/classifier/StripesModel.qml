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
        return d.stripesModels[stripeIndex];
    }

    // Current amount of stripes
    function stripesCount() {
        return d.stripesModels.length;
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
        if (d.stripesModels.length === 0) {
            return -1
        }
        if( targetLevel === -1) {
            return -1;
        }

        // Assumption that all stripes are sequential and no stripe is missing
        // And stipesModels is also reversed
        var firstStripeLevel = d.stripesModels[0].level
        var result = firstStripeLevel
                - targetLevel // Because sequential and without missing stripes.
        // But let's check anyway
        console.assert(d.stripesModels[result].level === targetLevel,
                       "d.stripesModels is not sequential!")
        return result
    }

    // Returns index of photo with given photoID in given stripe. -1 if stripe has no such photo
    function findPhotoIndexInStripeByPhotoID(stripeIndex, targetPhotoID) {
        console.log("Searching photo with ID ", targetPhotoID,
                    " in stripe on index ", stripeIndex)
        if (stripeIndex < 0 || stripeIndex >= d.stripesModels.length) {
            console.log("Stripe index is out of range")
            return -1
        }
        var stripe = d.stripesModels[stripeIndex]
        var result = Algorithm.binarySearch(stripe, targetPhotoID,
                                            d.photoIDStripeAccessor, 0,
                                            stripe.count)
        return result
    }

    // Move photo on given index to given level. index is QPoint(index in stripe, stripe index)
    //  See photoIndexByPhotoID function
    function movePhotoByIndexToLevel( photoIndex, newLevel ) {
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
            // photo index in stripe is out of range
            return;
        }

        var photoID = stripe.get(photoIndexInStripe).photoID;

        var targetStripeIndex = findStripeIndexForLevel(newLevel)
        if( targetStripeIndex === -1 || targetStripeIndex === undefined ) {
            return;
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

    // Adds empty stripe 'above'
    function addNewStripe() {
        var newStripe = d.createStripeModel();
        newStripe.sourcePhotoModel = sourcePhotoModel;
        if( d.stripesModels.lengt > 0) {
            // Array is inverted!
            newStripe.level = d.stripesModels[0].level
        } else {
            newStripe.level = 0;
        }

        d.stripesModels.insert( 0, newStripe );
        d.stripesModelsByLevel[newStripe.level] = newStripe;
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
                d.stripesModels = []
                d.stripesModelsByLevel = {}
                for( var i = 0; i < messageObject.models.length; i++) {
                    var sourceIndex = messageObject.models[i];
                    console.log( "Model index in source array ", sourceIndex)
                    var sourceModel = sourceStripesModels[sourceIndex];
                    sourceModel.level = messageObject.levels[sourceIndex];
                    sourceModel.sourcePhotoModel = sourcePhotoModel
                    console.log( "Stripe. Level ", sourceModel.level, " Photos count: ", sourceModel.count);

                    d.stripesModels.push( sourceModel );
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
           return Qt.createQmlObject(
                                            "import QtQuick 2.0; PhotoStripeModel {}",
                                            photoStripesView, "levelModel") // TODO: Use null as a parent ?
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
