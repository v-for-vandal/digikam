import QtQuick 2.0

Item {
    id: visualControl
    width: 0
    height: 0

    property var stripeViews;
    property var stripesModel;

    function movementStarted( initiator ) {
        //connenc
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

    // This function returns Item for given photoID.
    // QObject-parent of this item is always VisualControl itself,
    // but visual parent may change.
    function requestPhoto( photoID ) {
        if( stripesModel === undefined || stripesModel === null) {
            console.error( "Stripes model is undefined");
            return null
        }

        if( photoID === undefined || photoID === null
                || photoID < 0 || photoID >= stripesModel.sourcePhotoModel.count) {
            console.warn( "Requested PhotoID is invalid")
            return null
        }
        var inCacheItem = d.photoItemsCache[photoID];
        if( inCacheItem !== undefined && inCacheItem !== null) {
            return inCacheItem
        }

        if( d.rawPhotoView === null || d.rawPhotoView === undefined ) {
            d.rawPhotoView = Qt.createComponent("RawPhotoView.qml");
            console.assert(d.rawPhotoView !== null && d.rawPhotoView !== undefined)
        }

        var item = d.rawPhotoView.createObject(visualControl)
        d.photoItemsCache[photoID] = item;
        return item;
    }

    function releasePhoto(photoID) {
        d.photoItemsCache[photoID] = undefined; // TODO: Check that this is correct way to remove from dict
    }

    QtObject {
        id: d

        // Cache of photo items. Key is photoID
        property var photoItemsCache : null

        // RawPhotoView component used for dynamic creation
        property var rawPhotoView : null

        Component.onCompleted: {
            photoItemsCache = {}
        }
    }
}
