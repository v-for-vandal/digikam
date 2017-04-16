import QtQuick 2.0

// Photos separated into layers
// Item instead of QtObject because QtObject doesn't allow to declare other QtObjects inside self
// Some error in Qml itself, complains on 'unexistent default property'
Item {
    parent: null // You won't draw it anyway
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

    // returns object containing stripe model and index in that model
    // for photo with given id
    function findByPhotoID(targetPhotoID) {
        if (targetPhotoID < 0
                || targetPhotoID >= photoStripesView.sourcePhotoModel.count) {
            return undefined
        }

        var photo = photoStripesView.sourcePhotoModel.get(targetPhotoID)
        var level = photo.level
        var stripeModel = d.stripesModelsByLevel[level]
        var i = 0
        for (; i < stripeModel.count; i++) {
            var iPhoto = stripeModel.get(i)
            var iPhotoId = iPhoto.photoID
            if (iPhotoId == targetPhotoID) {
                break
            }
        }
        if (i >= stripeModel.count) {
            console.error("Cant' find photo with photoID ", targetPhotoID,
                          "in it's stripe")
        }
        return {
            stripe: stripeModel,
            index: i
        }
    }

    // Returns index of a photo in a given stripe with PhotoID closest to the given one
    function findNearestInStripeByPhotoID(targetPhotoID, stripeModel) {
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
        if (d.stripesModels.length == 0) {
            return -1
        }

        // Assumption that all stripes are sequential and no stripe is missing
        // And stipesModels is also reversed
        var firstStripeLevel = d.stripesModels[0].level
        var result = firstStripeLevel
                - targetLevel // Because sequential and without missing stripes.
        // But let's check anyway
        console.assert(d.stripesModels[result].level == targetLevel,
                       "d.stripesModels is not sequential!")
        return result
    }

    // Returns index of photo with given photoID in given stripe. -1 if stripe has no such photo
    function findPhotoIndexInStripeByPhotoID(stripeIndex, targetPhotoID) {
        console.log("Searching photo with ID ", targetPhotoID,
                    " in stripe on index ", stripeIndex)
        if (stripeIndex < 0 || stripeIndex >= d.stripesModels.length) {
            console.log("Stripe is empty")
            return -1
        }
        var stripe = d.stripesModels[stripeIndex]
        var result = Algorithm.binarySearch(stripe, targetPhotoID,
                                            photoIDStripeAccessor, 0,
                                            stripe.count)
        return result
    }

    QtObject {
        id: wtf
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
                d.initializationStarted();
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
                    console.log( "Stripe. Level ", sourceModel.level, " Photos count: ", sourceModel.count);

                    d.stripesModels.push( sourceModel );
                    d.stripesModelsByLevel[sourceModel.level] = sourceModel;
                }

                console.log( "Stripes models: ", d.stripesModels)
                console.log( "Stripes models map: ", d.stripesModelsByLevel)
                requestData[messageObject.requestId] = undefined
                console.log( "Initialization finished");
                d.initializationFinished();
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
        console.log( "Component status: ", d.componentCompleted)
        console.log( "New model is ", sourcePhotoModel);
        if( d.componentCompleted ) {
            d.initializeAsync();
        }
    }

    Component.onCompleted: {
        console.log( "Component finished initialization")
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
            if (item == undefined) {
                return undefined
            }
            return item.photoID
        }

        function initializeAsync() {
            console.log( "Asynchronious initialization");
            // Clear current results
            d.stripesModels = []
            d.stripesModelsByLevel = {}
            // Create as much stripe models as we need
            var sourceStripeModels = []
            // Model could be undefined
            if( sourcePhotoModel != undefined ) {
                for( var i = 0; i < sourcePhotoModel.numberOfLevels; i++ ) {
                    var levelModel = Qt.createQmlObject(
                                "import QtQuick 2.0; PhotoStripeModel {}",
                                photoStripesView, "levelModel")
                    sourceStripeModels.push(levelModel)
                }
            }

            initializationWorker.startInitialization(sourceStripeModels);
        }
    }
}
