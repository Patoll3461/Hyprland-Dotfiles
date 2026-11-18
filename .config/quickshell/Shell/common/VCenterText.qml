import QtQuick
import "../theme"

Text {
    anchors.verticalCenter: parent.verticalCenter
    font.pixelSize: Size.fontSize
    color: Colors.text
    font.bold: true

    anchors.left: parent.left
    anchors.right: parent.right

    anchors.leftMargin: Size.textMargin
    anchors.rightMargin: Size.textMargin
}