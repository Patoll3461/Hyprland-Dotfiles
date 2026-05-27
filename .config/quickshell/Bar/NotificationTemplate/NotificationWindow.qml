import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Repeater {
    id: windows
    visible: true
    model: root.notifications.length

    delegate: Item {
        id: notificationPanel

        required property var index
        //required property var modelData

        PanelWindow {
            id: notifyPanel
            implicitHeight: root.notifications.length * 100 + 10
            implicitWidth: 400
            color: "#00ffffff"
            anchors.top: true

            visible: root.notifications.length != 0 ? true : false

            Timer {
                interval: 100
                running: true
                repeat: true

                onTriggered: {
                    //console.log(root.notifications.length)
                    visible = root.notifications.length != 0 ? true : false
                }
            }
            
            focusable: false
            exclusiveZone: 0

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                width: 300
                height: 90
                radius: 10
                anchors.topMargin: 10 + (100 * notificationPanel.index)
                anchors.rightMargin: 50
                opacity: 0.8

                Text {
                    text: root.notifications[notificationPanel.index] == undefined ? "no" : root.notifications[notificationPanel.index].summary
                    font.bold: true
                    font.pixelSize: 18
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 10
                }

                Timer {
                    repeat: false
                    running: true
                    interval: 5000

                    onTriggered: {
                        console.log("hmmmm")
                        root.notifications = []
                    }
                }

                Timer {
                    repeat: false
                    running: true
                    interval: 10 
                }
            }
        }
    }
}