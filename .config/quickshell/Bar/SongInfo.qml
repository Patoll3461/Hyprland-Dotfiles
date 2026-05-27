import QtQuick
import Quickshell.Services.Mpris

pragma ComponentBehavior: Bound

Rectangle {
    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
        horizontalCenterOffset: 215
        rightMargin: 210
    }
     
    width: 300
    height: 28
    color: "#1c065a"
    radius: 10

    MouseArea {
        anchors.fill: parent

        cursorShape: Mpris.players.values.length != 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            if (Mpris.players.values.length == 0) return
            root.mediaWidgetOpened = !root.mediaWidgetOpened
        }
    }

    Text {
        id: noMedia
        text: "No Media"
        color: "#ffffff"
        font.bold: true
        font.pixelSize: 13
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    Repeater {
        anchors.fill: parent

        model: Mpris.players

        delegate: Item {

            anchors.fill: parent

            id: delegate
            required property var modelData
            property var player: Mpris.players.values[0]

            Text {
                function getSongInfo() {
                    var title = delegate.player.trackTitle
                    var artist = delegate.player.trackArtist

                    const maxLength = 36

                    if (title.length > 24 && artist.length > 10) {
                        title = title.slice(0, 24) + "..."
                        artist = artist.slice(0, 10) + "..."
                    } else if (title.length >= 24 && artist.length <= 10) {
                        title.length > maxLength - artist.length ? title = title.slice(0, maxLength - artist.length) + "..." : title = title.slice(0, maxLength - artist.length)
                    } else if (title.length <= 24 && artist.length >= 10) {
                        artist.length > maxLength - title.length ? artist = artist.slice(0, maxLength - title.length) + "..." : artist = artist.slice(0, maxLength - title.length)
                    } 

                    noMedia.text = ""

                    if (!artist && !title) {
                        noMedia.text = "No Media"
                    }

                    return title + "  ●  " + artist
                }

                anchors.fill: parent
                text: getSongInfo()
                color: "#ffffff"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 13
                font.bold: true
            }
        }  
    }
}