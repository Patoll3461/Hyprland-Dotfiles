pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import "../theme"

Rectangle {
    id: root

    width: Size.vDesktopWidth
    height: parent.height

    radius: Size.radius
    color: Colors.base

    property int count: 10
    property int itemSize: Size.vDesktopCellWidth

    property real spacing: (width - (count * itemSize)) / (count + 1)

    Row {
        id: row

        width: parent.width
        height: parent.height

        anchors.verticalCenter: parent.verticalCenter

        leftPadding: root.spacing
        rightPadding: root.spacing
        spacing: root.spacing

        Repeater {
            id: workspaceRepeater

            model: root.count

            delegate: Rectangle {
                required property int index

                width: root.itemSize
                height: root.itemSize
                anchors.verticalCenter: parent.verticalCenter

                radius: Size.radius / 2

                property var workspaces: Hyprland.workspaces.values
                property int workspaceId: index + 1

                property bool isActive: workspaces.some(ws => ws.id === workspaceId)
                property bool isFocused: {
                    const ws = Hyprland.workspaces.values.find(ws => ws.focused)
                    return ws ? ws.id === workspaceId : false
                }
                
                color: {
                    if (isFocused) return Colors.accent
                    if (isActive) return Colors.surface1
                    return Colors.surface0
                }
                
                border.color: {
                    if (!isFocused && !isActive) return Colors.overlay1
                    return Colors.surface2
                }
                border.width: 3

                Text {
                    text: parent.index + 1

                    width: parent.width
                    height: parent.height

                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter

                    font.pixelSize: 22
                    font.bold: true
                    color: Colors.text
                }

                MouseArea {
                    anchors.fill: parent

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${parent.workspaceId} })`)
                    }
                }
            }
        }
    }
}