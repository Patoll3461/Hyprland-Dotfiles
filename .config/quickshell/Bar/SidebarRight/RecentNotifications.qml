import QtQuick
import QtQuick.Controls

Rectangle {
    id: recentRoot

    property var notifications: rootWindow.notifications
    property bool notificationPopupOpen: rootWindow.notificationPopupOpen 
    property double popupNotificationNumber: rootWindow.popupNotificationNumber
    property var recentNotifications: rootWindow.recentNotifications
    property var popupNotifications: rootWindow.popupNotifications
    property var isOverFive: rootWindow.isOverFive
    property var previousNotificationCount: rootWindow.previousNotificationCount

    width: 350
    height: 800
    anchors.horizontalCenter: parent.horizontalCenter
    y: 100
    color: "#1c065a"
    visible: true
    radius: 10

    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: parent.width
        contentHeight: columnContent.height + 40

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.alwaysOn
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 5
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            height: 100
            width: 8
            active: true

            contentItem: Rectangle {
                radius: 4
                color: "#9372f0"
            }

            background: Rectangle {
                radius: 4
                color: "#4c3ac2"
            }
        }

         Column {
            id: columnContent

            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20

            spacing: 20

            Repeater {
                model: recentRoot.recentNotifications

                delegate: Rectangle {
                    id: delegate

                    required property var index
                    required property var modelData

                    width: 300
                    height: 100
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 10

                    Text {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: 80
                        anchors.topMargin: 3
                        font.pixelSize: 22
                        font.bold: true
                        text: parent.modelData.summary
                        width: parent.width - anchors.leftMargin
                        elide: Text.ElideRight
                        color: "#000000"
                    }

                    Text {
                        id: bodyText

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: 80
                        anchors.topMargin: 35
                        font.pixelSize: 14
                        text: parent.modelData.body 
                        wrapMode: Text.Wrap
                        width: 200
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        color: "#000000"
                    }

                    Image {
                        source: parent.modelData.image !== "" ? parent.modelData.image : Quickshell.iconPath(parent.modelData.appIcon)
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.topMargin: 3
                        width: 50
                        height: 50
                    }
                }
            }
        }
    }

}