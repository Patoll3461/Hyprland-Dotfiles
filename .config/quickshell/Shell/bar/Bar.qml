import Quickshell
import QtQuick
import "../theme"

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: barWindow

            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Size.barHeight

            color: Colors.mantle

            MediaControl {
                anchors.leftMargin: Size.barLeftMargin
            }

            VirtualDesktops { 
                anchors.horizontalCenter: parent.horizontalCenter
            }

            SysTray {
                anchors.right: parent.right
                anchors.rightMargin: Size.barRightMargin
            }
        }
    }
}