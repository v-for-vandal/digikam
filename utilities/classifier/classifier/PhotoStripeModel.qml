import QtQuick 2.0
import QtQml.Models 2.2

ListModel {
    property int level
}

/* TODO: Discard
DelegateModel {
    id: stripeModel

    property int level

    function insertByLevel() {
        var i = 0;
        console.log( "Source photos", sourceItems.count)
        console.log( "Our 'level'", stripeModel.level)
        while( i < sourceItems.count ) {
            var item = sourceItems.get(i)

            console.log( "Checking item number ", i, " item level: ", item.model.level);
            if( item.model.level == stripeModel.level ) {
                item.groups = "items";
            } else {
                i += 1;
            }
        }
    }

    delegate: PhotoDelegate {}

    items.includeByDefault: false
    groups: [
        DelegateModelGroup {
            id: sourceItems
            includeByDefault: true
            name : "source"
            onChanged: {
                insertByLevel();
            }
        }

    ]

}*/
