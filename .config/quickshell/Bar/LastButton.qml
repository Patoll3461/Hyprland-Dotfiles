import QtQuick
import Quickshell.Services.Mpris

Rectangle {
    anchors {
        left: parent.left
        leftMargin: 0
        verticalCenter: parent.verticalCenter
    }
    color: "#0d053d"
    bottomLeftRadius: 10
    bottomRightRadius: 10

    Rectangle {
        color: "#1c065a"
        width: 28
        height: 28
        border.color: "#ffffff"
        border.width: 10
        radius: 5
        anchors.centerIn: parent

        anchors  {
             left: parent.left
             leftMargin: 25
        }

        Text {
            anchors.centerIn: parent
            text: "⏮️"
            color: "#ffffff"
            font.pixelSize: 25
            font.bold: true
        }

        Repeater {
            anchors.fill: parent

            model: Mpris.players

            delegate: Item {

                required property var modelData

                anchors.fill: parent

                id: delegate
                property var player: Mpris.players.values[0]

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    cursorShape: delegate.player.canGoPrevious ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        delegate.player.previous()
                    }
                }
            }
        }
    }
}