import QtQuick
import QtQuick.Controls
import Quickshell.Services.Mpris

Rectangle {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    color: "#00ffffff"
    height: 28
    width: 200

    ProgressBar {
        function getProgress() {
            if (Mpris.players.values.length == 0) return 200
            var player = Mpris.players.values[0]
            return (player.position / player.length) * 200
        }

        id: progressBar
        width: parent.width
        height: parent.height
        from: 0
        to: 200
        value: 0

        background: Rectangle {
            color: "#1c065a"
            radius: 10
        }

        contentItem: Rectangle {
            color: "#7c5dd3"
            radius: 10
            width: progressBar.visualPosition < 0.03 ? 0.03 * parent.width : progressBar.visualPosition * parent.width
        }
 
        Timer {
            interval: 100
            running: true
            repeat: true
            onTriggered: progressBar.value = progressBar.getProgress()
        }
    }
}