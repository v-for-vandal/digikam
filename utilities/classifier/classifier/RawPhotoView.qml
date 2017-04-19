import QtQuick 2.0

Rectangle {
    property int photoID
    border.width: 5

    Text {
        anchors.centerIn: parent
        text: "Photo ID: " + photoID
    }
}
