import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell
import Qt5Compat.GraphicalEffects


Rectangle {
    anchors.centerIn: parent
    anchors.fill: parent
    color: "#00000000"
    id: anchorWindow

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 4

        Repeater {
            model: SystemTray.items.values

            delegate: Item {
                id: sysDelegate

                width: 24
                height: 24
                required property var modelData
                required property var index

                Image {
                    source: sysDelegate.modelData.icon.includes("?") ? Quickshell.iconPath(sysDelegate.modelData.id) : sysDelegate.modelData.icon
                    width: parent.width
                    height: parent.height
                    fillMode: Image.PreserveAspectFit

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: sysDelegate.modelData.hasMenu ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            sysDelegate.modelData.display(root, 1215 + sysDelegate.index * 28, 30)
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        visible: UPower.displayDevice.isLaptopBattery
        anchors.right: parent.right
        width: 70
        height: 25
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        radius: 10

        color: "#7c5dd3"

        Text {
            text: Math.round(UPower.displayDevice.percentage * 100) + "%"
            font.bold: true
            width: 24
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 14
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
        }
        
        Image {
            source: UPower.displayDevice.state === UPowerDeviceState.Charging ? Quickshell.iconPath("battery-" + parent.getPercentage() + "-charging") : Quickshell.iconPath("battery-" + parent.getPercentage())
            height: 26
            width: 26
            fillMode: Image.PreserveAspectFit
            layer.enabled: true
            layer.effect: ColorOverlay {
                color: "#ffffff"
            }
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 5
        }

        function getPercentage() {
            var percentage = Math.round(UPower.displayDevice.percentage * 10) * 10
            if (percentage != 100) {
                percentage = "0" + percentage
            }
            if (percentage == 0) {
                percentage = "000"
            }
            //console.log(percentage)
            return percentage
        }
    }
}
/*
Image {
        source: SystemTray.items.values[0].icon
        width: parent.height
        height: parent.height

        MouseArea {
            cursorShape: SystemTray.items.values[0].hasMenu ? Qt.PointingHandCursor : Qt.ArrowCursor
            anchors.fill: parent
            onClicked: {
                SystemTray.items.values[0].display(root, 1215, 30)
            }
        }
    }
    */