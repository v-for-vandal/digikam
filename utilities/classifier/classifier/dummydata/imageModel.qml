import QtQuick 2.0

ListModel {
    id: photoModel
    readonly property int numberOfLevels : 5; // For optimization properties. Needed to ofload some work to separate thread

    ListElement {
        width : 400
        height : 300
        color : "#FF0000";
        level : 1;
    }
    ListElement {
        width : 200
        height : 300
        color : "#00FF00"
        level : 1
    }
    ListElement {
        width : 350
        height : 300
        color : "#0F00F0"
        level : 2
    }
    ListElement {
        width : 150
        height : 300
        color : "#AA0F55"
        level : 2
    }
    ListElement {
        width : 500
        height : 300
        color : "#A0E705"
        level : 1
    }
    ListElement {
        width : 400
        height : 300
        color : "#FF0000";
        level : 1;
    }
    ListElement {
        width : 200
        height : 300
        color : "#00FF00"
        level : 1
    }
    ListElement {
        width : 350
        height : 300
        color : "#0F00F0"
        level : 2
    }
    ListElement {
        width : 150
        height : 300
        color : "#AA0F55"
        level : 2
    }
    ListElement {
        width : 500
        height : 300
        color : "#A0E705"
        level : 2
    }
    ListElement {
        width : 500
        height : 300
        color : "#A0E705"
        level : 1
    }
    ListElement {
        width : 400
        height : 300
        color : "#FF0000";
        level : 4;
    }
    ListElement {
        width : 200
        height : 300
        color : "#00FF00"
        level : 4
    }
    ListElement {
        width : 350
        height : 300
        color : "#0F00F0"
        level : 2
    }
    ListElement {
        width : 150
        height : 300
        color : "#AA0F55"
        level : 3
    }
    ListElement {
        width : 500
        height : 300
        color : "#A0E705"
        level : 3
    }

}
