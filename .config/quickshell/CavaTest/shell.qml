import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    width: 300
    height: 300
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    focusable: false

    property var spectrum: []

    anchors.top: true
    anchors.right: true

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            Hyprland.refreshToplevels()
            //console.log("h")
        }
    }

    readonly property var watchedClasses: ["firefox", "kitty", "spotify", "Spotify"]
    readonly property bool shouldShow: {
        const ws = Hyprland.focusedMonitor?.activeWorkspace

        for (let i = 0; i < ws.toplevels.values.length; i++) {
            const t = ws.toplevels.values[i]
            const cls = t.lastIpcObject?.class ?? ""
            console.log(cls)
            if (root.watchedClasses.includes(cls)) return true
        }
        return false
    }
    

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: root.shouldShow ? WlrLayer.Top : WlrLayer.Bottom

    Process {
        id: cava
        command: ["/home/patoll/.config/quickshell/scripts/cava.sh"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.spectrum = data.trim().split(";")
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 120
        height: 120
        radius: width / 2
        color: '#00222222'
        border {
            width: 5
            color: "#5A3F9E"
        }
    }

    Repeater {
        model: root.spectrum.length

        Item {
            required property int index
            readonly property real value: Number(root.spectrum[index] || 0)
            readonly property real barHeight: Math.max(8, value * 0.5)

            // Fixed position at center — rotation does all the placement
            x: root.width / 2
            y: root.height / 2

            transform: Rotation {
                origin.x: 0
                origin.y: 0
                angle: index * (360 / root.spectrum.length)
            }

            Rectangle {
                width: 6
                // Anchored so bar grows outward from a fixed radius
                y: -60 - height   // 60 = circle radius, bar extends outward
                x: -width / 2
                height: parent.barHeight
                radius: width / 2
                color: "white"

                Behavior on height {
                    NumberAnimation { duration: 50 }
                }
            }
        }
    }
}