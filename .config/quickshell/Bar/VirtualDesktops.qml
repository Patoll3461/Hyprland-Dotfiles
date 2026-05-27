import QtQuick
import Quickshell.Hyprland

pragma ComponentBehavior: Bound

Item {
    anchors.fill: parent
    id: container
    anchors.leftMargin: 5

    property var activeWorkspaces
    property bool blocked: false
    property var focusedWorkspace

    Repeater {
        model: 10

        delegate : Rectangle {
            required property int index

            function isWorkspaceActive(mode) {
                if (container.blocked) return
                container.activeWorkspaces = []
                for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                    if (Hyprland.focusedWorkspace.id == bg.index + 1) {
                        container.activeWorkspaces.push(Hyprland.focusedWorkspace.id)
                        container.focusedWorkspace = Hyprland.focusedWorkspace.id
                        return mode == 0 ? "#cc8b00" : "#ffffff"
                    } else if (Hyprland.workspaces.values[i].id == bg.index + 1){
                        container.activeWorkspaces.push(Hyprland.workspaces.values[i].id)
                        return mode == 0 ? "#cc8b00" : "#9372f0"
                    } 
                }
                return mode == 0 ? "#724e00" : "#381f7e"
            }

            id: bg
            anchors.verticalCenter: container.verticalCenter
            width: 40
            height: 30
            x: 40 * index - 5
            radius: 10
            border.color: "#ffffff"
            border.width: 1


            MouseArea {
                function sleep(ms) {
                    return new Promise(resolve => setTimeout(resolve, ms))
                }

                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: {
                    var desktop = bg.index + 1
                    Hyprland.dispatch(`hl.dsp.focus({ workspace = ${desktop} })`)
                    sleep(100)
                    bg.color = bg.isWorkspaceActive(0)
                    if (bg.index + 1 == Hyprland.focusedWorkspace.id) {
                        label.color = "#000000"
                    } else {
                        label.color = "#ffffff"
                    }
                    desktopRect.color = bg.isWorkspaceActive(1)
                }
            }

            Rectangle {
                id: desktopRect
                
                anchors.centerIn: parent
                width: 25
                height: 25
                radius: 100

                Text {
                    id: label
                    text: bg.index + 1
                    anchors.centerIn: parent
                    font.family: "Monospace"
                    font.styleName: ""
                    font.pixelSize: 15
                    font.bold: true
                    color: "#ffffff"
                }

                Timer {
                    running: true
                    repeat: true
                    interval: 100

                    onTriggered: {
                        bg.color = bg.isWorkspaceActive(0)
                        if (Hyprland.focusedWorkspace)
                        if (bg.index + 1 == Hyprland.focusedWorkspace.id) {
                            label.color = "#000000"
                        } else {
                            label.color = "#ffffff"
                        }
                        desktopRect.color = bg.isWorkspaceActive(1)
                    }
                }
            }
        }
    }
}