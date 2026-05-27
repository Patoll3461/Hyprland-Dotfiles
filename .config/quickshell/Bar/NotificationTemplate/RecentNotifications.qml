import QtQuick
import Quickshell
import QtQuick.Controls

Flickable {
    id: flickable
    width: parent.width
    height: parent.height
    contentWidth: width
    contentHeight: contentItem.childrenRect.height + 10
    clip: true

    Repeater {
        model: notificationRoot.server.trackedNotifications.values.length

        delegate: Rectangle {
            id: rect

            required property var index
            property int revIndex: notificationRoot.server.trackedNotifications.values.length - 1 - index

            color: "#ffffff"
            width: 300
            height: 90
            y: index * 100 + 10
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 10

            Text {
                text: notificationRoot.server.trackedNotifications.values[parent.revIndex].summary
                font.bold: true
                font.pixelSize: 18
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 10
                color: "#000000"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    const index = root.notifications.indexOf(notificationRoot.server.trackedNotifications.values[parent.revIndex])
                    rect.visible = false
                }
            }
        }
    }

    ScrollBar.vertical: ScrollBar {
        width: 14
        topPadding: 10
        bottomPadding: 10
        rightPadding: 5
        policy: ScrollBar.AlwaysOn

        contentItem: Rectangle {
            color: "#ffffff"
            radius: 4
        }
    }
}
