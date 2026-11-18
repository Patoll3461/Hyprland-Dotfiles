import QtQuick
import "../theme"
import "../services"
import "../common"

Rectangle {
    id: root

    clip: true

    height: parent.height
    width: Size.mediaBarWidth

    anchors.left: parent.left

    radius: Size.radius

    color: Colors.base

    Rectangle {
        clip: true

        height: parent.height
        width: Size.mediaBarTextWidth

        anchors.left: parent.left
        anchors.top: parent.top

        radius: Size.radius
        
        color: parent.color

        VHCenterText {
            id: titleText
            text: root.songInfo.length > 0 ? root.songInfo : ""
            elide: Text.ElideRight
        }
    }

    Canvas {
        id: progressIndicator

        width: Size.buttonSize
        height: Size.buttonSize

        anchors.rightMargin: Size.textMargin
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent

            cursorShape: Qt.PointingHandCursor

            onClicked: {
                MprisService.activePlayer.togglePlaying()
            }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var centerX = width / 2
            var centerY = height / 2
            var radius = Math.min(width, height) / 2 - 3

            // Background circle
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
            ctx.fillStyle = Colors.surface0
            ctx.fill()

            if (!MprisService.activePlayer) return

            // Progress arc
            var pos = MprisService.activePlayer.position / MprisService.activePlayer.length
            var arcRadius = Math.min(pos * Math.PI * 2, Math.PI * 2)

            ctx.beginPath()
            ctx.arc(
                centerX,
                centerY,
                radius,
                -Math.PI / 2,
                -Math.PI / 2 + (pos * Math.PI * 2)
            )
            ctx.strokeStyle = Colors.accent
            ctx.lineWidth = 3.5
            ctx.lineCap = "round"
            ctx.stroke()

            ctx.fillStyle = Colors.text   // or any color you want
            ctx.font = "bold 14px sans-serif"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"

            var symbol = MprisService.activePlayer.isPlaying ? "⏸" : "▶"
            var offset = MprisService.activePlayer.isPlaying ? 1 : -1

            ctx.fillText(symbol, centerX - offset, centerY + offset)
        }

        Connections {
            target: MprisService.activePlayer
            function onPositionChanged() {
                progressIndicator.requestPaint()
            }
        }

        Connections {
            target: MprisService
            function onActivePlayerChanged() {
                progressIndicator.requestPaint()
            }
        }
    }
    

    readonly property string songInfo: {
        if (!MprisService.activePlayer) {
            return "No Media"
        }

        var title = MprisService.activePlayer.trackTitle || ""
        var artist = MprisService.activePlayer.trackArtist || ""

        if (artist === "" && title === "") {
            return "No Media"
        }

        const maxLength = 40
        const maxTitleLength = 28
        const maxArtistLength = 12

        if (title.length > maxTitleLength && artist.length > maxArtistLength) {
            title = trim(title, maxTitleLength)
            artist = trim(artist, maxArtistLength)
        } else if (title.length >= maxTitleLength && artist.length <= maxArtistLength) {
            title = trim(title, maxLength - artist.length)
        } else if (title.length <= maxTitleLength && artist.length >= maxArtistLength) {
            artist = trim(artist, maxLength - title.length)
        }

        return title + "  ●  " + artist
    }

    function trim(str, limit) {
        if (str.length > limit)
            return str.slice(0, limit - 3) + "..."
        return str
    }
}