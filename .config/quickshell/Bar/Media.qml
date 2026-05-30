import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Quickshell.Io

PanelWindow {
    id: mediaRoot

    property var players: Mpris.players.values
    property int index: 0

    property string cachedArtUrl: ""
    property string prevArtUrl: ""

    property var currentPlayer: players.length > 0 ? players[index] : null


    Image {
        id: prevImg
        source: mediaRoot.prevArtUrl
        cache: false
        asynchronous: true
    }

    Image {
        id: currImg
        source: mediaRoot.cachedArtUrl
        cache: false
        asynchronous: true
    }


    Process {
        id: copyProcess

        property string srcPath: ""

        command: []

        onExited: {
            // force reload with cache bust
            img.source = ""
            img.source = "file:///home/patoll/.config/quickshell/art/current.png?" + Date.now()
        }
    }

    Process {
        id: delProcess
        command: ["rm", "/home/patoll/.config/quickshell/art/current.png"]
    }


    Connections {
        target: mediaRoot.currentPlayer

        function onTrackArtUrlChanged() {
            let url = target.trackArtUrl

            if (!url || url === "")
                return

            // first time setup
            if (mediaRoot.cachedArtUrl === "") {
                mediaRoot.cachedArtUrl = url
                mediaRoot.prevArtUrl = url

                copyProcess.command = [
                    "cp",
                    url.replace("file://", ""),
                    "/home/patoll/.config/quickshell/art/current.png"
                ]
                copyProcess.running = true
                return
            }

            mediaRoot.prevArtUrl = mediaRoot.cachedArtUrl
            mediaRoot.cachedArtUrl = url

            // only compare when images are ready
            if (currImg.status === Image.Ready && prevImg.status === Image.Ready) {

                let currSize = currImg.sourceSize.width * currImg.sourceSize.height
                let prevSize = prevImg.sourceSize.width * prevImg.sourceSize.height

                if (currSize > prevSize) {
                    copyProcess.command = [
                        "cp",
                        url.replace("file://", ""),
                        "/home/patoll/.config/quickshell/art/current.png"
                    ]
                    copyProcess.running = true
                }
            }
        }


        function onTrackTitleChanged() {
            mediaRoot.prevArtUrl = ""
            mediaRoot.cachedArtUrl = ""
        }
    }


    visible: root.mediaWidgetOpened
    color: "#000d053d"
    exclusiveZone: 0

    anchors.top: true
    anchors.left: true

    margins.left: 98
    margins.top: 5

    implicitHeight: 175
    implicitWidth: 400


    Rectangle {
        anchors.fill: parent
        color: "#0d053d"
        radius: 10

        Rectangle {
            color: "#1c065a"
            radius: 10
            width: 400
            height: 150

            Image {
                id: img
                source: ""

                cache: false
                asynchronous: true

                anchors.left: parent.left
                anchors.leftMargin: 12.5
                anchors.top: parent.top
                anchors.topMargin: 10

                height: 100
                width: 100

                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true

                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: img.width
                        height: img.height

                        Rectangle {
                            anchors.centerIn: parent
                            width: img.width
                            height: img.height
                            radius: 10
                        }
                    }
                }
            }
        
            // everything below unchanged
            Rectangle {
                color: "#00000000"

                width: 100
                height: 32

                anchors.top: parent.top
                anchors.left: parent.left

                anchors.leftMargin: 12.5
                anchors.topMargin: 114

                Rectangle {
                    width: 28
                    height: 28

                    anchors.left: parent.left

                    radius: 5

                    border.color: "#ffffff"
                    border.width: 5

                    Text {
                        text: "⏮️"
                        font.pixelSize: 25
                        font.bold: true
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 0.5
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: mediaRoot.players[mediaRoot.index].canGoPrevious ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mediaRoot.players[mediaRoot.index].previous()
                    }
                }

                Rectangle {
                    width: 28
                    height: 28

                    anchors.horizontalCenter: parent.horizontalCenter

                    radius: 5

                    border.color: "#ffffff"
                    border.width: 5

                    Text {
                        text: area.initLabel()
                        font.pixelSize: 25
                        font.bold: true
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 0.5
                    }

                    MouseArea {
                        id: area

                        function initLabel() {
                            return mediaRoot.players[mediaRoot.index].isPlaying ? "⏸️" : "▶️"
                        }

                        function changeLabel() {
                            return mediaRoot.players[mediaRoot.index].isPlaying ? "▶️" : "⏸️"
                        }

                        anchors.fill: parent
                        cursorShape: mediaRoot.players[mediaRoot.index].canPause ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mediaRoot.players[mediaRoot.index].togglePlaying()
                    }
                }

                Rectangle {
                    width: 28
                    height: 28

                    anchors.right: parent.right

                    radius: 5

                    border.color: "#ffffff"
                    border.width: 5

                    Text {
                        text: "⏭️"
                        font.pixelSize: 25
                        font.bold: true
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 0.5
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: mediaRoot.players[mediaRoot.index].canGoNext ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mediaRoot.players[mediaRoot.index].next()
                    }
                }
            }

            Rectangle {
                color: "#0032cf13"
                width: 275
                height: 150

                anchors.left: parent.left
                anchors.leftMargin: 125

                Text {
                    text: mediaRoot.players[mediaRoot.index].trackTitle
                    width: parent.width - 20
                    color: "#ffffff"
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.topMargin: 22
                    elide: Text.ElideRight
                    font.bold: true
                    font.pixelSize: 25
                }

                Text {
                    text: mediaRoot.players[mediaRoot.index].trackArtist
                    width: parent.width - 20
                    color: "#ffffff"
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.topMargin: 50
                    elide: Text.ElideRight
                    font.bold: true
                    font.pixelSize: 16
                }

                Text {
                    text: mediaRoot.players[mediaRoot.index].trackAlbum
                    width: parent.width - 20
                    color: "#ffffff"
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.topMargin: 70
                    elide: Text.ElideRight
                    font.bold: true
                    font.pixelSize: 16
                }

                ProgressBar {
                    function getProgress() {
                        if (mediaRoot.players.length == 0) return 200
                        var player = mediaRoot.players[mediaRoot.index]
                        return (player.position / player.length) * 200
                    }

                    id: progressBar
                    width: parent.width - 30
                    height: 30
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.topMargin: 112
                    from: 0
                    to: 200
                    value: 0

                    background: Rectangle {
                        color: "#0d053d"
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
        }

        Rectangle {
            color: "#004400ff"
            width: 400
            height: 25
            anchors.bottom: parent.bottom

            Text {
                text: mediaRoot.index + 1 + " / " + mediaRoot.players.length
                color: "#ffffff"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 50
                font.bold: true
                font.pixelSize: 16
            }

            Rectangle {
                width: 100
                height: 25
                color: "#000000ff"
                anchors.right: parent.right
                anchors.rightMargin: 85

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    width: 25
                    height: 25
                    radius: 10
                    color: mediaRoot.index == 0 ? "#724e00" : "#cc8b00"

                    Text {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: 5
                        text: "<"
                        font.bold: true
                        font.pixelSize: 20
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: mediaRoot.index == 0 ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: {
                            if (mediaRoot.index == 0) return
                            mediaRoot.index--
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    width: 25
                    height: 25
                    radius: 10
                    color: mediaRoot.index == mediaRoot.players.length - 1 ? "#724e00" : "#cc8b00"

                    Text {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: 7
                        text: ">"
                        font.bold: true
                        font.pixelSize: 20
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: mediaRoot.index == mediaRoot.players.length - 1 ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: {
                            if (mediaRoot.index == mediaRoot.players.length - 1) return
                            mediaRoot.index++
                        }
                    }
                }
            }
        }
    }
}