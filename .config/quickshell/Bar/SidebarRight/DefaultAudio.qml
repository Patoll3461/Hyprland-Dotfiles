import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire

pragma ComponentBehavior: Bound

Rectangle {
    color: "#110531"
    width: parent.width
    height: 160
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    radius: 10

    ComboBox {
        id: outBox

        property var sinkNodes: Pipewire.nodes.values.filter(n =>
            n.isSink &&
            n.properties["media.class"] != undefined &&
            n.properties["media.class"] === "Audio/Sink"
        )

        property var defaultSource: Pipewire.defaultAudioSink

        Timer {
            interval: 100
            running: true
            repeat: true

            onTriggered: {
                outBox.sinkNodes = Pipewire.nodes.values.filter(n =>
                    n.isSink &&
                    n.properties["media.class"] != undefined &&
                    n.properties["media.class"] === "Audio/Sink"
                )
            }
        }

        anchors.left: parent.left
        height: 75
        anchors.bottom: parent.bottom
        width: parent.width
        anchors.bottomMargin: 0

        onCurrentIndexChanged: {
            Pipewire.preferredDefaultAudioSink = sinkNodes[currentIndex]
        }

        background: Rectangle {
            id: outButton

            color: "#9372f0"
            radius: 10

            NumberAnimation on topRightRadius {
                id: topRightAnim

                from: 10
                to: 0
                running: false
                duration: 150

                onStopped: {
                    if (from == 0) {
                        from = 10
                        to = 0
                    }
                }
            }

            NumberAnimation on topLeftRadius {
                id: topLeftAnim

                from: 10
                to: 0
                running: false
                duration: 150

                onStopped: {
                    if (from == 0) {
                        from = 10
                        to = 0
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
            }
        }

        contentItem: Text {
            text: outBox.defaultSource ? "[Out] " + outBox.defaultSource.description : "No Source"
            font.pixelSize: 18
            color: "#ffffff"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            anchors.left: parent.left
            anchors.leftMargin: 10
            elide: Text.ElideRight
            font.bold: true
        }

        popup: Popup {
            id: outPopup

            //visible: true

            y: -height

            //opacity: 0

            width: parent.width
            height: outBox.sinkNodes.length * 28 + 20

            clip: true
            
            NumberAnimation on height {
                id: heightAnim

                from: 0
                to: outBox.sinkNodes.length * 28 
                running: false
                duration: 200
                easing.type: Easing.OutCubic

                onStopped: {
                    if (to == 0) {
                        outButton.topLeftRadius = 10
                        outButton.topRightRadius = 10

                        outPopup.visible = false
                        heightAnim.from = 0
                        heightAnim.to = outBox.sinkNodes.length * 28 + 20
                        //console.log(heightAnim.to)
                    }
                }
            }

            NumberAnimation on opacity {
                id: opacityAnim

                from: 0
                to: 1
                running: false

                duration: 150
                easing.type: Easing.InOutQuad

                onStopped: {
                    if (to == 0) {
                        opacityAnim.from = 0
                        opacityAnim.to = 1
                    }
                }
            }

            onVisibleChanged: { 
                if (visible && opacityAnim.to == 1) {
                    heightAnim.to = outBox.sinkNodes.length * 28 + 20

                    outPopup.opacity = 0
                    outPopup.height = 0

                    opacityAnim.start()
                    topRightAnim.start()
                    topLeftAnim.start()
                    heightAnim.start()
                }
            }

            onClosed: {
                //console.log("closed")
                //console.log(opacityAnim.to)
                if (heightAnim.to == 0) return                
                //heightAnim.stop()
                //opacityAnim.stop()

                heightAnim.from = outBox.sinkNodes.length * 28 + 20
                heightAnim.to = 0

                topRightAnim.from = 0
                topRightAnim.to = 10

                topLeftAnim.from = 0
                topLeftAnim.to = 10

                opacityAnim.from = 1
                opacityAnim.to = 0

                outPopup.visible = true

                heightAnim.start()
                topRightAnim.start()
                topLeftAnim.start()
                opacityAnim.start()
            }

            background: Rectangle {
                color: "#9372f0"
                topLeftRadius: 10
                topRightRadius: 10
            }

            contentItem: ListView {
                id: outList

                clip: true
                model: outBox.sinkNodes
                currentIndex: outBox.highlightedIndex
                interactive: true
                width: 250
                height: contentItem.implicitHeight

                delegate: ItemDelegate {
                    required property var modelData
                    required property var index

                    id: outDelegate
                    width: parent.width
                    height: 28

                    contentItem: Text {
                        text: outDelegate.modelData.description
                        color: "#ffffff"
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        rightPadding: 10
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        radius: 10
                        color: "#574291"
                        border.color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            outBox.currentIndex = outDelegate.index
                            outPopup.close()
                        }
                    }

                    highlighted: true
                }
            }
        }
    }

    ComboBox {
        id: inBox

        property var sourceNodes: Pipewire.nodes.values.filter(n =>
            !n.isSink &&
            n.properties["media.class"] != undefined &&
            n.properties["media.class"] === "Audio/Source"
        )

        property var defaultSource: Pipewire.defaultAudioSource

        Timer {
            interval: 100
            running: true
            repeat: true

            onTriggered: {
                inBox.sourceNodes = Pipewire.nodes.values.filter(n =>
                    !n.isSink &&
                    n.properties["media.class"] != undefined &&
                    n.properties["media.class"] === "Audio/Source"
                )
            }
        }

        anchors.left: parent.left
        height: 75
        anchors.top: parent.top
        width: parent.width
        //anchors.topMargin: 20

        onCurrentIndexChanged: {
            Pipewire.preferredDefaultAudioSource = sourceNodes[currentIndex]
        }

        background: Rectangle {
            id: inButton

            color: "#9372f0"
            radius: 10

            NumberAnimation on topRightRadius {
                id: inTopRightAnim

                from: 10
                to: 0
                running: false
                duration: 150

                onStopped: {
                    if (from == 0) {
                        from = 10
                        to = 0
                    }
                }
            }

            NumberAnimation on topLeftRadius {
                id: inTopLeftAnim

                from: 10
                to: 0
                running: false
                duration: 150

                onStopped: {
                    if (from == 0) {
                        from = 10
                        to = 0
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
            }
        }

        contentItem: Text {
            text: inBox.defaultSource != null ? "[In] " + inBox.defaultSource.description : "No Source"
            font.pixelSize: 18
            color: "#ffffff"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            anchors.left: parent.left
            anchors.leftMargin: 10
            elide: Text.ElideRight
            font.bold: true
        }

        popup: Popup {
            id: inPopup

            //visible: true

            y: -height

            //opacity: 0

            width: parent.width
            height: inBox.sourceNodes != undefined ? inBox.sourceNodes.length * 28 + 20 : 0

            clip: true
            
            NumberAnimation on height {
                id: inHeightAnim

                from: 0
                to: inBox.sourceNodes != undefined ? inBox.sourceNodes.length * 28 + 20 : 0
                running: false
                duration: 200
                easing.type: Easing.OutCubic

                onStopped: {
                    if (to == 0) {
                        inButton.topLeftRadius = 10
                        inButton.topRightRadius = 10

                        inPopup.visible = false
                        inHeightAnim.from = 0
                        inHeightAnim.to = inBox.sourceNodes.length * 28 + 20
                        //console.log(heightAnim.to)
                    }
                }
            }

            NumberAnimation on opacity {
                id: inOpacityAnim

                from: 0
                to: 1
                running: false

                duration: 150
                easing.type: Easing.InOutQuad

                onStopped: {
                    if (to == 0) {
                        inOpacityAnim.from = 0
                        inOpacityAnim.to = 1
                    }
                }
            }

            onVisibleChanged: { 
                if (visible && inOpacityAnim.to == 1) {
                    inHeightAnim.to = inBox.sourceNodes.length * 28 + 20

                    inPopup.opacity = 0
                    inPopup.height = 0

                    inOpacityAnim.start()
                    inTopRightAnim.start()
                    inTopLeftAnim.start()
                    inHeightAnim.start()
                }
            }

            onClosed: {
                //console.log("closed")
                //console.log(opacityAnim.to)
                if (inHeightAnim.to == 0) return                
                //heightAnim.stop()
                //opacityAnim.stop()

                inHeightAnim.from = inBox.sourceNodes.length * 28 + 20
                inHeightAnim.to = 0

                inTopRightAnim.from = 0
                inTopRightAnim.to = 10

                inTopLeftAnim.from = 0
                inTopLeftAnim.to = 10

                inOpacityAnim.from = 1
                inOpacityAnim.to = 0

                inPopup.visible = true

                inHeightAnim.start()
                inTopRightAnim.start()
                inTopLeftAnim.start()
                inOpacityAnim.start()
            }

            background: Rectangle {
                color: "#9372f0"
                topLeftRadius: 10
                topRightRadius: 10
            }

            contentItem: ListView {
                id: inList

                clip: true
                model: inBox.sourceNodes
                currentIndex: inBox.highlightedIndex
                interactive: true
                width: 250
                height: contentItem.implicitHeight

                delegate: ItemDelegate {
                    required property var modelData
                    required property var index

                    id: inDelegate
                    width: parent.width
                    height: 28

                    contentItem: Text {
                        text: inDelegate.modelData.description
                        color: "#ffffff"
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        rightPadding: 10
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        radius: 10
                        color: "#574291"
                        border.color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            inBox.currentIndex = inDelegate.index
                            inPopup.close()
                        }
                    }

                    highlighted: true
                }
            }
        }
    }
}