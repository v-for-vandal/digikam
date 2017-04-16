import QtQuick 2.0

/* Not used. Discard ?
Rectangle {
    id: wrapper
    width: model.width
    height: ListView.view.height
    border.color: model.color
    border.width: 5
    opacity: 0.7
    Rectangle {
        color: "yellow"
        width: parent.width
        height: Math.min(parent.height * 0.05, 40)
        anchors.top: parent.top
        anchors.left: parent.left
        visible: wrapper.ListView.isCurrentItem
    }
    Rectangle {
        color: "yellow"
        width: parent.width
        height: Math.min(parent.height * 0.05, 40)
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        visible: wrapper.ListView.isCurrentItem
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            ListView.currentIndex = index
        }
    }
}*/
