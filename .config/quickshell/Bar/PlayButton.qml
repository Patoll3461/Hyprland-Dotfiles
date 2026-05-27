import QtQuick
import Quickshell.Services.Mpris

Rectangle {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 40
    bottomLeftRadius: 10
    bottomRightRadius: 10

    Item {
        visible: Mpris.players
        Rectangle {
            color: "#00000000"
            width: 28
            height: 28
            anchors.centerIn: parent

            border.color: "#ffffff"
            border.width: 10
            radius: 5

            Text {
                anchors.centerIn: parent
                text: "▶️"
                color: "#fff"
                font.pixelSize: 25
                font.bold: true
            }
        }
    }

    Repeater {
        model: Mpris.players

        delegate: Item {
            required property var modelData

            id: delegate
            property var player: Mpris.players.values[0]


            function initLabel() {
                return player.isPlaying ? "⏸️" : "▶️"
            }

            function changeLabel() {
                return player.isPlaying ? "▶️" : "⏸️"
            }

            Rectangle {
                id: rect

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
                    id: playLabelText

                    anchors.centerIn: parent
                    text: delegate.initLabel()
                    color: "#ffffff"
                    font.pixelSize: 25
                    font.bold: true

                    Timer {
                        interval: 100
                        running: true
                        repeat: true
                        onTriggered: playLabelText.text = delegate.initLabel()
                    }
                }
        

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    cursorShape: delegate.player.canPause ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        delegate.player.togglePlaying()
                    }
                }
            }
        }
    }
}   