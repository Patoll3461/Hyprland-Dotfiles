import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import "../theme"

Item {
    id: root

    required property var popupWindow
    required property QsMenuEntry modelData

    height: Size.sysTrayMenuEntrySize
    width: parent.width

    Text {
        verticalAlignment: Text.AlignVCenter

        text: modelData.text

        font.pixelSize: Size.fontSize
        font.bold: true

        color: modelData.enabled ? Colors.text : Colors.muted

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Size.sysTrayTextLeftMargin
    
    }

    Image {
        id: iconImage

        visible: root.modelData.buttonType == QsMenuButtonType.None

        source: root.modelData.icon
        width: 15
        height: 15

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Size.textMargin

        layer.enabled: true
        layer.effect: MultiEffect {
            brightness: 1.0
            colorization: 1.0
            colorizationColor: '#ffffff'
        }
    }

    CheckBox {
        visible: root.modelData.buttonType == QsMenuButtonType.CheckBox

        width: 15
        height: 15

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Size.textMargin

        checked: root.modelData.checkState
    }

    RadioButton {
        visible: root.modelData.buttonType == QsMenuButtonType.RadioButton

        width: 15
        height: 15

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Size.textMargin

        checked: root.modelData.checkState
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.modelData.enabled && !root.modelData.isSeparator ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            if (root.modelData.isSeparator || !root.modelData.enabled) return
            root.modelData.triggered()
            root.popupWindow.close()
        }
    }

    Shape {
        width: Size.triangleSize
        height: Size.triangleSize
        
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Size.triangleRightMargin

        visible: root.modelData.hasChildren
        
        ShapePath {
            strokeWidth: 4
            strokeColor: "red"
            fillColor: "red"

            startX: Size.triangleSize / 2; startY: 0
            PathLine { relativeX: -(Size.triangleSize / 2); y: Size.triangleSize }
            PathLine { relativeX: Size.triangleSize; y: Size.triangleSize }
            PathLine { relativeX: -(Size.triangleSize / 2); y: 0 }
        }
    }    
}