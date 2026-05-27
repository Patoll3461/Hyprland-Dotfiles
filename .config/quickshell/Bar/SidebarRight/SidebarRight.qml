import Quickshell
import Quickshell.Hyprland
import QtQuick


PanelWindow {
    id: rightPanel

    //screen: Quickshell.screens[1]

    implicitWidth: 400
    visible: root.sideBarOpened
    color: "#0d053d"
    focusable: true

    onVisibleChanged: {
        if (visible) {
            exitFocus.focus = true
        }
    }

    property var exitFocus: exitFocus

    anchors {
        right: true
        bottom: true
        top: true
    }
    //TestComment

    HyprlandFocusGrab {
        id: grab
        windows: [ rightPanel ]
        active: root.sideBarOpened
        onCleared: () => {
            if (!active) root.sideBarOpened = false
            //root.notifications.length = 0
            //console.log(root.notifications.length)
        }
    }

    Item {
        id: exitFocus

        anchors.fill: parent
        focus: true

        onFocusChanged: {
            if (!focus) {
                if (!rootWindow.mayFocusSidebar) return
                focus = true
            }
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                //console.log("test")
                root.sideBarOpened = false 
                //root.notifications.length = 0
                //console.log(root.notifications.length)
            } 
        }
    }

    exclusiveZone: 0

    Controls { }
}