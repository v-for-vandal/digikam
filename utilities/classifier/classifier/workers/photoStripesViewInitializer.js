function prepareEmptyFinishedResult( result, requestId ) {
    result.status = 'finished'
    result.requestId = requestId;
    result.models = []
    result.levels = {}
}

function prepareErrorResult( result, requestId, errorMsg ) {
    result.status = 'error'
    result.models = []
    result.requestId = requestId;
    result.errorMsg = errorMsg
    result.levels = {}
}

// Input structure must contain:
// sourcePhotoModel - model with all photos
// sourceStripesModels = [ QListModel1, QListModel2, ..., QListModelN]
//                      Pre-generated QListModels that will be filled with data for stripes. There must be >= models then
//                      number of levels in sourcePhotoModel, because script can't generate new models (No access to QML context)
// requestId = int
//                      Unique request id. Will be copied directly to result messages. No internal use.
//
// It will send back result in the form of the following structure:
// status : 'started' | 'finished' | 'error'.
//              'finished' and 'error' messages are guaranteed to be the final ones
// models = [ index1, index2, .., indexN]
//              Qml prevents us from returning QListModel, even if it is taken from an input args. Instead we return indices
//              in the source array
// levels = { index1 -> level1, index2->level2, ...]
//              Changes made to the user properties of ListModel are not propogated to main thread. We store stripe level as
//              such user property and thus we need to return it explicitly
WorkerScript.onMessage = function(message) {
    // We can't create QListModel inside WorkerScript, so we have to pass necessary amount of models
    // in input parameters
    var sourcePhotoModel = message.sourcePhotoModel;
    var sourceStripesModels = message.sourceStripesModels
    var requestId = message.requestId;

    if( requestId == undefined ) {
        console.warn("Request id is undefined");
    }

    var stripesModels = [] // Rearranged and populated sourceStripesModels, model is represented as index in sourceStripesModels
    var stripesLevels = {} // Index of the stripe model -> level of this stripe
    var stripesModelsByLevel = {} // internal hash, level -> model
    var result = {
        'status' : 'started',
        'requestId' : requestId
    }

    // Notification that we started processing
    WorkerScript.sendMessage(result);

    // Take all photos from the model and see their levels
    if (sourcePhotoModel.count == 0) {
        prepareEmptyFinishedResult(result, requestId);
        WorkerScript.sendMessage(result);
        return
    }

    var maxLevel = sourcePhotoModel.get(0).level
    var minLevel = sourcePhotoModel.get(0).level

    console.log("Source model has ", sourcePhotoModel.count, " photos");
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
        prepareErrorResult(result, requestId, "Internal error: Can't determine min/max levels");
        WorkerScript.sendMessage(result);
        return
    }

    // Lets check that we have enough ListModel objects in sourceStripesModels. We can't create new one,
    // so if there is not enough, we are screwed.
    console.assert(sourceStripesModels.length >= (maxLevel - minLevel + 1), "Not enough source models" )

    // Create that much stripe models
    var indexOfNextSourceModel = 0
    for (var i = minLevel; i <= maxLevel; i++) {
        var levelModel = sourceStripesModels[indexOfNextSourceModel];

        levelModel.clear(); // Erase all previous content, if any
        levelModel.level = i // Irrelevant now, won't be propogated to main thread

        stripesModels.push(indexOfNextSourceModel)
        stripesLevels[indexOfNextSourceModel] = i;

        stripesModelsByLevel[i] = levelModel

        indexOfNextSourceModel++;
    }

    // Reverse array
    stripesModels.reverse();

    // Populate stripes models
    for (var i = 0; i < sourcePhotoModel.count; i++) {
        var item = sourcePhotoModel.get(i)
        //console.log( "photo level: ", item.level, " index: ", i);
        var itemModel = stripesModelsByLevel[item.level]
        //console.log("model ", itemModel);
        itemModel.append({
                             photoID: i
                         })
    }

    // Synchronizing
    for (var i = minLevel; i <= maxLevel; i++) {
        var levelModel = stripesModelsByLevel[i]
        levelModel.sync();
        console.log( "Stripe model. Level: ", levelModel.level, "Has photos: ", levelModel.count );
    }

    // prepare result
    result.status = 'finished'
    result.requestId = requestId;
    result.models = stripesModels
    result.levels = stripesLevels
    console.log("Stripes models: ", result.models)
    WorkerScript.sendMessage(result);
}
