import QtQuick 2.0

Item {
    Rectangle {
        color: "yellow"
        width: parent.width
        height: Math.min(parent.height * 0.05, 40)
        anchors.top: parent.top
        anchors.left: parent.left
    }
    Rectangle {
        color: "yellow"
        width: parent.width
        height: Math.min(parent.height * 0.05, 40)
        anchors.bottom: parent.bottom
        anchors.left: parent.left
    }
}
