//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
import "SidebarRight"
import "Notifications"

pragma ComponentBehavior: Bound

NotificationWindow {
    id: rootWindow

    property bool mayFocusSidebar: true
    property bool mayFocusMediaWidget: false
    
    property var notifications: []
    property bool notificationPopupOpen: false  
    property double popupNotificationNumber: 0
    property var recentNotifications: []
    property var popupNotifications: []
    property var isOverFive: false
    property var previousNotificationCount: -1
    
    function discardAt(index) {
        rootWindow.notifyRepeater.itemAt(index).closeAndFade(2)
        rootWindow.notifyRepeater.itemAt(index).moveSide()
        for (var i = index + 1; i < rootWindow.popupNotifications.length; i++) {
            //console.log(i)
            rootWindow.notifyRepeater.itemAt(i).moveUp()
        }
    }

    function discardWithoutAnimating(index) {
        rootWindow.notifyRepeater.itemAt(index).discard()
        for (var i = index + 1; i < rootWindow.popupNotifications.length; i++) {
            //console.log(i)
            rootWindow.notifyRepeater.itemAt(i).moveUp()
        }
    }

    function invokeAt(popupIndex, actionIndex) {
        rootWindow.notifyRepeater.itemAt(popupIndex).closeAndFade(3)
        rootWindow.notifyRepeater.itemAt(popupIndex).moveSide()
        rootWindow.notifyRepeater.itemAt(popupIndex).invokeAction(actionIndex)
        for (var i = popupIndex + 1; i < rootWindow.popupNotifications.length; i++) {
            //console.log(i)
            rootWindow.notifyRepeater.itemAt(i).moveUp()
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true

        onTriggered: {
            rootWindow.recentNotifications = notificationServer.trackedNotifications.values
            if (rootWindow.popupNotificationNumber > 0) {
                rootWindow.popupNotifications = rootWindow.recentNotifications.slice(-1 * rootWindow.popupNotificationNumber)
                rootWindow.notificationPopupOpen = true
                //console.log(rootWindow.isOverFive)
                if (rootWindow.popupNotifications.length >= 4 && rootWindow.isOverFive) {
                    rootWindow.isOverFive = false
                    rootWindow.notifyRepeater.itemAt(5).openAndFade()
                    rootWindow.notifyRepeater.itemAt(0).closeAndFade()
                    for (var i = 0; i < rootWindow.popupNotifications.length; i++) {
                        rootWindow.notifyRepeater.itemAt(i).moveUp(0)
                    }
                } 
            } else {
                rootWindow.popupNotifications = []
                rootWindow.notificationPopupOpen = false
            }

            for (var i = 0; i < rootWindow.popupNotifications.length; i++) {
                    rootWindow.notifyRepeater.itemAt(i).bodyText.text = rootWindow.popupNotifications[i].body
            }
            //console.log(notificationServer.trackedNotifications.values.length)
            //console.log(rootWindow.isOverFive)
        }
    }

    NotificationServer {
        id: notificationServer
        keepOnReload: false

        Component.onCompleted: {
            //console.log(SystemTray.items.values.length + " test")
            notificationServer.notification.connect(handleNotification)
        }

        onNotification: {
            if (rootWindow.popupNotificationNumber < 0) {
                rootWindow.popupNotificationNumber = 0
            }
            if (rootWindow.popupNotificationNumber >= 5) {
                rootWindow.isOverFive = true
                rootWindow.popupNotificationNumber = 5
            }  
            //if (rootWindow.sideBarOpened) return
                    
            rootWindow.popupNotificationNumber += 1
            //console.log(rootWindow.popupNotificationNumber)
        }
    }

    function handleNotification(notification) {
        notification.tracked = true
        //console.log(notificationServer.trackedNotifications.values.length)
        //console.log("hi")
        //notification.resident = true
    }


    Variants {

        model: Quickshell.screens

        delegate: Component {
            PanelWindow {

                id: root

                property bool sideBarOpened: false
                property bool mediaWidgetOpened: false
               
                required property var modelData 

                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                }

                color: "#009de4e8"

                implicitHeight: 30

                Rectangle  {

                    anchors.fill: parent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#0d053d"
                    bottomLeftRadius: 10
                    bottomRightRadius: 10
                    Item {
                        width: 615
                        anchors.left: parent.left
                        anchors.leftMargin: 50
                        anchors.verticalCenter: parent.verticalCenter

                        PlayButton { }

                        NextButton { }

                        LastButton { }

                        SongInfo { }

                        MediaProgress { }
                    }
                }


                Rectangle {
                    height: parent.height
                    width: 400
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#1c065a"
                    radius: 10

                    VirtualDesktops { }
                }

                Rectangle {
                    height: parent.height
                    width: 300
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 50
                    color: "#1c065a"
                    radius: 10
                    Clock { }
                }
            
                Rectangle {
                    height: parent.height
                    width: 300
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 405
                    color: "#1c065a"
                    radius: 10
                    SystemTrayBar { }
                }

                SidebarRight { }  

                onSideBarOpenedChanged: {
                    //if (!root.notificationPopupOpen)
                    rootWindow.popupNotificationNumber = root.sideBarOpened ? 0 : rootWindow.popupNotificationNumber
                }

                Timer {
                    id: discardTimer
                    
                    running: true
                    interval: 750000
                    repeat: true

                    onTriggered: {
                        rootWindow.notifyRepeater.itemAt(0).closeAndFade(1)
                        for (var i = 0; i < rootWindow.popupNotifications.length; i++) {
                            rootWindow.notifyRepeater.itemAt(i).moveUp(0)
                        }
                    }
                }

                Media { }
            }
        }
    }
}
