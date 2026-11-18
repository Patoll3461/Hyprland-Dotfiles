pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import "../theme"
import "../common"
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    width: Size.sysTrayBarWidth
    height: parent.height

    clip: true

    radius: Size.radius

    color: Colors.base

    Item {
        id: sysTrayWrapper

        anchors.left: parent.left
        anchors.top: parent.top

        width: UPower.displayDevice.isLaptopBattery ? Size.sysTrayBarWidth - Size.batteryIndicatorWidth : Size.sysTrayBarWidth
        height: parent.height

        property int count: SystemTray.items.values.length

        property int maxCount: Size.sysTrayMaxCount
        property int itemSize: Size.sysTrayCellSize

        property real spacing: (width - (itemSize * maxCount)) / (maxCount + 1)

        Row {
            width: sysTrayWrapper.itemSize
            height: sysTrayWrapper.itemSize

            anchors.verticalCenter: parent.verticalCenter

            leftPadding: sysTrayWrapper.spacing
            rightPadding: sysTrayWrapper.spacing
            spacing: sysTrayWrapper.spacing

            Repeater {
                model: SystemTray.items.values

                delegate: Image {
                    id: sysDelegate

                    required property SystemTrayItem modelData
                    required property int index

                    width: Size.sysTrayCellSize
                    height: Size.sysTrayCellSize

                    anchors.verticalCenter: parent.verticalCenter

                    source: modelData.icon.includes("?") ? Quickshell.iconPath(modelData.id) : modelData.icon

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: sysDelegate.modelData.hasMenu ? Qt.PointingHandCursor : Qt.ArrowCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: (mouse) => {
                            var pos = sysDelegate.mapToItem(barWindow.contentItem, 0, 0)

                            if (mouse.button == Qt.LeftButton) {
                                trayItemMenu.toggle(pos.x + (sysDelegate.width / 2), Size.barHeight, qsMenuOpener.children.values)
                            } else if (mouse.button == Qt.RightButton) {
                                sysDelegate.modelData.activate()
                            } else if (mouse.button == Qt.MiddleButton) {
                                sysDelegate.modelData.secondaryActivate()
                            }
                        }                   
                    }

                    QsMenuOpener {
                        id: qsMenuOpener

                        menu: sysDelegate.modelData.menu
                    }
                }
            }

            TrayItemPopup {
                id: trayItemMenu
            }
        }
    }

    Rectangle {
        visible: UPower.displayDevice.isLaptopBattery

        id: batteryIndicator

        width: Size.batteryIndicatorWidth
        height: parent.height

        anchors.right: parent.right
        anchors.rightMargin: Size.textMargin

        radius: Size.radius

        color: Colors.surface1

        VCenterText {
            text: Math.round(UPower.displayDevice.percentage * 100) + "%"
            font.bold: true
            width: 24
            anchors.left: parent.left
            anchors.leftMargin: 10
            horizontalAlignment: Text.AlignVCenter
            font.pixelSize: 14
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
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 3
        }

        function getPercentage() {
            var percentage = Math.round(UPower.displayDevice.percentage * 10) * 10
            if (percentage != 100) {
                percentage = "0" + percentage
            }
            if (percentage == 0) {
                percentage = "000"
            }
            return percentage
        }
    }
}