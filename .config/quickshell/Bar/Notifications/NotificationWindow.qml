import Quickshell
import QtQuick 

pragma ComponentBehavior: Bound

PanelWindow {
    id: notificationRoot

    //screen: Quickshell.screens.values[0]

    anchors.top: true
    exclusiveZone: 0
    implicitWidth: 400
    implicitHeight: rootWindow.popupNotificationNumber * 114 + 8//108
    color: "#00000000"
    
    property var notifyRepeater: notifyRepeater

    Repeater {
        id: notifyRepeater

        model: rootWindow.popupNotifications 

        delegate: Rectangle {
            required property var index
            required property var modelData
            
            id: notifyPopup

            //opacity: 0

            color: "#1c065a"
            y: (index) * 114 + 8
            height: 108
            width: 400
            radius: 10

            property var bodyText: bodyText
            property bool timer: false

            MouseArea {
                id: dragArea

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.left: parent.left
                width: 400
                height: 70
                drag.target: parent
                drag.axis: Drag.XAxis

                onReleased: {
                    if (parent.x > 400 || parent.x < -400) {
                        rootWindow.discardWithoutAnimating(notifyPopup.index)
                    } else {
                        parent.x = 0
                    }
                }
            }

            Text {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 100
                anchors.topMargin: 3
                elide: Text.ElideRight
                font.pixelSize: 22
                width: parent.width - anchors.leftMargin
                font.bold: true
                text: parent.modelData.summary
                color: "#ffffff"
            }

            Text {
                id: bodyText

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 100
                anchors.topMargin: 35
                font.pixelSize: 14
                text: parent.modelData.body
                wrapMode: Text.Wrap
                width: 280
                elide: Text.ElideRight
                maximumLineCount: 2
                color: "#ffffff"
            }

            Image {
                source: parent.modelData.image !== "" ? parent.modelData.image : Quickshell.iconPath(parent.modelData.appIcon)
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.topMargin: 2
                width: 70
                height: 70
            }

            Repeater {
                id: actionRepeater

                model: parent.modelData.actions

                delegate: Rectangle {
                    required property var modelData
                    required property var index
                    property int count: actionRepeater.model.length + 1
                    
                    id: actionRect

                    color: "#7c5dd3"
                    width: (400 - 2 * 10 - (count) * 10) / count
                    height: 30
                    anchors.bottom: notifyPopup.bottom
                    anchors.bottomMargin: 5
                    x: 10 + index * (width + 10)
                    radius: 10

                    Text {
                        text: parent.modelData.text
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 14
                        anchors.fill: parent
                        elide: Text.ElideRight
                        anchors.centerIn: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            rootWindow.invokeAt(notifyPopup.index, actionRect.index) 
                            //parent.modelData.invoke()
                        }
                    }
                }
            }

            Rectangle {
                color: "#7c5dd3"
                width: actionRepeater.model.length ? (400 - 2 * 10 - (actionRepeater.model.length + 1) * 10) / (actionRepeater.model.length + 1) : 380 //(400 - 2 * 10 - (actionRepeater.model.length + 1) * 10) / (actionRepeater.model.length + 1)
                height: 30
                x: actionRepeater.model.length ? 10 + actionRepeater.model.length + actionRepeater.model.length * (width + 10) : 10
                anchors.bottom: notifyPopup.bottom
                anchors.bottomMargin: 5
                radius: 10

                Text {
                    text: "Close"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked:  {
                        //console.log(notifyPopup.x)
                        //console.log(notifyPopup.index)
                        rootWindow.discardAt(notifyPopup.index)
                    }
                }
            }

            NumberAnimation on opacity {
                id: opacityAnim

                property var count: 100
                property var actionIndex
                from: 1
                to: 0
                duration: 250
                running: false

                onStopped: {
                    //console.log(opacityAnim.to + " to")
                    //console.log(opacityAnim.from + " from")
                    if (rootWindow.popupNotificationNumber > 5) {
                        rootWindow.popupNotificationNumber = 5
                    }

                    if (count === 1) {
                        //console.log("test")
                        rootWindow.popupNotificationNumber--
                    } else if (count === 2) {
                        //rootWindow.popupNotificationNumber--
                        rootWindow.popupNotificationNumber--

                        if (notifyPopup.timer) return;
                        notifyPopup.modelData.tracked = false
                        //notifyPopup.modelData.tracked = false
                    } else if (count === 3) {
                        //rootWindow.popupNotificationNumber--
                        //console.log(actionRepeater.itemAt(opacityAnim.actionIndex).modelData.text)
                        actionRepeater.itemAt(opacityAnim.actionIndex).modelData.invoke()
                    }

                    if (opacityAnim.to == 1) {
                        //console.log("changed")
                        opacityAnim.from = 1
                        opacityAnim.to = 1
                    }
                }
            }

            NumberAnimation on y {
                id: yAnim

                //property bool fromCloseAction: false

                from: notifyPopup.y
                to: notifyPopup.y - 114
                running: false
                duration: 250
            }

            NumberAnimation on y {
                id: belowAnim

                from: notifyPopup.y + 114
                to: notifyPopup.y
                running: false
                duration: 250
            }

            NumberAnimation on x {
                id: xAnim
                
                from: 0
                to: 400
                running: false
                duration: 250
            }

            function closeAndFade(count) {
                //console.log("Fade Out")
                opacityAnim.count = count
                opacityAnim.from = 1
                opacityAnim.to = 0

                //console.log(opacityAnim.count) + "count"

                opacityAnim.start()
            }

            function openAndFade() {
                opacity = 0
                opacityAnim.from = 0
                opacityAnim.to = 1
                //opacityAnim.count = count
                //console.log("test")

                opacityAnim.start()
            }

            function moveUp(fromCloseAction) {
                //yAnim.fromCloseAction = fromCloseAction
                //console.log("movingUp" + index)
                yAnim.start()
            }

            function moveSide() {
                xAnim.start()
            }

            function invokeAction(index) {
                opacity = 1
                opacityAnim.count = 3
                opacityAnim.from = 1
                opacityAnim.to = 0
                opacityAnim.actionIndex = index

                opacityAnim.start()
            }

            function discard() {
                discardNotifyTimer.running = true
            }

            Timer {
                id: discardNotifyTimer

                interval: 5000
                running: true
                repeat: false

                onTriggered: {
                    notifyPopup.timer = true;
                    rootWindow.discardAt(notifyPopup.index)
                }
            }
        }
    }
}
