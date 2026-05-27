import QtQuick
import Quickshell
import Qt5Compat.GraphicalEffects

pragma ComponentBehavior: Bound

Rectangle {
    id: controlRoot

    property var controlWindows: [recentNotifications, volumeControl, wifi, bluetooth]
    property var controlWindowIcons: [Quickshell.iconPath("stock_bell"), Quickshell.iconPath("audio-volume-high") , Quickshell.iconPath("network-wireless-signal-good"), Quickshell.iconPath("bluetooth-online")]
    property var visibleIndex: 0

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 70
    width: 300
    height: 50
    radius: 10
    color: "#1c065a"

    Row {
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            model: 5

            delegate : Rectangle {
                required property var index

                height: 40
                width: 40
                radius: 100
                color: controlRoot.visibleIndex === index ? "#4c3ac2" : "#9372f0"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (parent.index == controlRoot.visibleIndex) return
                        controlRoot.controlWindows[parent.index].visible = true
                        controlRoot.controlWindows[controlRoot.visibleIndex].visible = false
                        controlRoot.visibleIndex = parent.index
                    }
                }

                Image {
                    source: controlRoot.controlWindowIcons[parent.index]
                    anchors.centerIn: parent
                    width: 30
                    height: 30
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: "#ffffff"
                    }
                }
            }
        }
    }

    RecentNotifications {
        id: recentNotifications
    }

    VolumeControl { 
        id: volumeControl
    }

    Wifi {
        id: wifi
    }

    Bluetooth {
        id: bluetooth
    }
}
