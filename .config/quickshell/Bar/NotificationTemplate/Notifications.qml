import QtQuick
import Quickshell
import Quickshell.Services.Notifications

pragma ComponentBehavior: Bound

Rectangle {
    id: notificationRoot

    visible: true
    height: 800
    width: 350
    y: 100
    radius: 10
    anchors.horizontalCenter: parent.horizontalCenter
    color: "#1c065a"

    property var server: server
    //property var notifications: []
    //property var lastNotificationObject: null

    RecentNotifications { }

    NotificationServer {
        id: server

        keepOnReload: false
        Component.onCompleted: {
            server.notification.connect(handleNotifcation)
        }
    }


    Timer {
        repeat: true
        running: true
        interval: 10

        onTriggered: {
            //console.log(notificationRoot.notifications.length + " before")
            root.notifications = [...new Set(root.notifications)]
            //console.log(notificationRoot.notifications.length + " after")
        }
    }

    function handleNotifcation(notification) {
        if (notification != undefined)

        notification.tracked = true

        if (root.notifications.length >= 5) {
            root.notifications.shift()
        }

        if (root.notifications.includes(notification)) return

        root.notifications.push(notification)

        //console.log("nooooo")
    }

    property var windows: windows

    NotificationWindow { }
}