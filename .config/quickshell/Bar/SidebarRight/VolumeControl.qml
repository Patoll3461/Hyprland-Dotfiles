import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick.Controls

pragma ComponentBehavior: Bound

Rectangle {
    id: volumeControlRoot

    width: 350
    height: 800
    anchors.horizontalCenter: parent.horizontalCenter
    y: 100
    color: "#1c065a"
    visible: false
    radius: 10

    DefaultAudio { }

    property var streamNodes: Pipewire.nodes.values.filter(n =>
        n.isStream &&
        //n.properties["media.class"] != undefined &&
        //n.properties["media.class"] !== "Stream/Input/Audio" &&
        !(n.name && n.name.toLowerCase().indexOf("pulseaudio") !== -1)
    )

    Timer {
        interval: 500
        running: true
        repeat: true

        onTriggered: {
            volumeControlRoot.streamNodes = Pipewire.nodes.values.filter(n =>
                n.isStream &&
                n.properties &&
                n.properties["media.class"] == "Stream/Output/Audio" &&
                !(n.name && n.name.toLowerCase().indexOf("pulseaudio") !== -1)
            )
        }
    }


    PwObjectTracker {
        id: tracker
        objects: Pipewire.nodes.values
    }

    Text {
        visible: parent.streamNodes.length === 0
        text: "No Audio Sources"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 300
        color: "#ffffff"
        font.pixelSize: 30
        font.bold: true
    }

    Repeater {
        model: volumeControlRoot.streamNodes

        delegate: Item {
            id: volumeContainer
            required property var index
            required property var modelData

            y: index * 40 + 20
            anchors.left: parent.left
            anchors.leftMargin: 20

            Text {
                y: volumeContainer.index * 40
                //id: label
                font.pixelSize: 18
                font.bold: true
                color: "#ffffff"
                text: volumeContainer.modelData.properties["application.name"] + " ● " + volumeContainer.modelData.properties["media.name"]
                elide: Text.ElideRight
                width: 300
                //text: volumeContainer.modelData.properties["media.class"]
            }

            Slider {
                id: slider
                from: 0
                to: 150
                width: 300
                value: volumeContainer.modelData.audio.volume * 100
                height: 15
                y: volumeContainer.index * 40 + 35

                //topInset: volumeContainer.index * 40 + 35
                //topPadding: volumeContainer.index * 40 + 35

                Rectangle {
                    //y: volumeContainer.index * 40 + 35
                    anchors.left: parent.left
                    height: 12
                    width: (slider.value - slider.from) / (slider.to - slider.from) * slider.width
                    color: "#ffffff"
                    radius: 10
                    z: 2
                }

                Rectangle {
                    //y: volumeContainer.index * 40 + 35
                    anchors.left: parent.left
                    width: slider.width + 2
                    height: 12
                    color: "#000000"
                    radius: 10
                }

                handle: Rectangle {
                    width: 0
                    height: 0
                }

                onValueChanged: {
                    volumeContainer.modelData.audio.volume = slider.value / 100
                }
            }
        }
    }
}