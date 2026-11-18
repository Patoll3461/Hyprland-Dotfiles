pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import "../theme"

PopupWindow {
    id: root

    property real popupX: 0
    property real popupY: 0
    property real popupHeight: 1
    property real animationTime: 600
    property list<QsMenuEntry> menuElements: []

    implicitHeight: popupHeight
    implicitWidth: 100

    anchor.window: barWindow
    anchor.rect: Qt.rect(popupX - width / 2, popupY, 0, 0)

    grabFocus: true

    color: "#00ffffff"

    onClosed: {
        popupY = 0
        popupHeight = 1
    }

    property bool animateOpening: false

    function toggle(x, y, elements) {
        animateOpening = true

        popupX = x
        popupY = y
        menuElements = elements
        popupHeight = elements.length > 0 ? elements.length * Size.sysTrayMenuEntrySize : 1

        let maxWidth = 0
        const padding = 100
        const itemHeight = Size.sysTrayMenuEntrySize

        for (let i = 0; i < elements.length; i++) {
            metrics.text = elements[i].text ?? elements[i].label ?? ""

            maxWidth = Math.max(maxWidth, metrics.width)
        }
        
        popupHeight = Math.max(1, elements.length * itemHeight)
        implicitWidth = Math.max(100, maxWidth + padding)
        
        animateOpening = false

        visible = true

        //console.log(root.menuElements.map(i => i.isSeparator))
    }

    function close() {
        visible = false
        popupY = 0
        popupHeight = 1
    }

    Behavior on popupHeight {
        enabled: root.animateOpening        

        NumberAnimation {
            duration: root.animationTime
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: mainRect

        anchors.fill: parent

        radius: Size.radius

        color: Colors.surface0

        border.color: Colors.surface2
        border.width: 2
    }

    TextMetrics {
        id: metrics
        font.pixelSize: Size.fontSize
    }

    Column {
        anchors.left: parent.left
        anchors.top: parent.top

        width: parent.width
        height: parent.height

        Repeater {
            model: root.menuElements

            anchors.fill: parent

            delegate: Loader {
                id: delegate

                required property QsMenuEntry modelData

                width: parent.width
                height: Size.sysTrayMenuEntrySize

                TrayMenuEntry { 
                    popupWindow: root
                    modelData: delegate.modelData
                }

                TrayMenuSeperator { 
                    visible: delegate.modelData.isSeparator
                }
            }
        }
    }
}