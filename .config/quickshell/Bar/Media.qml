import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtMultimedia

PanelWindow {
    id: mediaRoot

    property var players: Mpris.players.values
    property var index: 0
    property var cachedArtUrl

    visible: root.mediaWidgetOpened
    color: "#000d053d"
    exclusiveZone: 0

    anchors.top: true
    anchors.left: true

    margins.left: 98
    margins.top: 5
    
    
    implicitHeight: 175
    implicitWidth: 400

    /*MediaPlayer {
        id: player
        source: "file:///home/patoll/Downloads/test.mp4"
        videoOutput: videoOut
        audioOutput: audioOut

        //Component.onCompleted: play()
    }

    VideoOutput {
        id: videoOut
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
        //renderType: videoOutput.Software
    }

    AudioOutput {
        id: audioOut
        volume: 1.0
        device: AudioDevice.default
        muted: false
    }

    onVisibilityChanged: {
        if (visible === true) {
            player.play()
        } else {
            player.stop()
        }
    }*/

    

    

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

                source: {
                    console.log("Test")
                    var url = mediaRoot.players[mediaRoot.index].trackArtUrl

                    if (url && url.length > 0) {
                        mediaRoot.cachedArtUrl = url
                        return url
                    }

                    return mediaRoot.cachedArtUrl
                }

                //anchors.horizontalCenter: parent.horizontalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12.5
                anchors.top: parent.top
                anchors.topMargin: 10

                height: 100
                width: 100

                fillMode: Image.PreserveAspectCrop

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

                        onClicked: {
                            mediaRoot.players[mediaRoot.index].previous()
                        }
                    }
                }

                Rectangle {
                    width: 28
                    height: 28

                    anchors.horizontalCenter: parent.horizontalCenter
                    //anchors.leftMargin: 50 - 14

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

                        onClicked: {
                            mediaRoot.players[mediaRoot.index].togglePlaying()
                        }
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

                        onClicked: {
                            mediaRoot.players[mediaRoot.index].next()
                        }
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
                        onTriggered:{ 
                            progressBar.value = progressBar.getProgress()
                            //console.log(Mpris.players.values.length)
                        } 
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