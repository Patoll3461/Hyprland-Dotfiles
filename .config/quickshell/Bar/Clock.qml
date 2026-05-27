import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    anchors.fill: parent
    color: "#00000000"
    id: time
    property string time
    property string date

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        onDateChanged: time.updateTime()
    }

    Row {
        anchors.centerIn: parent
        spacing: 8
        Text {
            text: time.time
            font.pixelSize: 24
            font.bold: true
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            text: "● " + time.date
            font.pixelSize: 18
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        }
    }

    function updateTime() {
        let now = clock.date
        time.time = Qt.formatDateTime(now, "hh:mm:ss")
        time.date = Qt.formatDateTime(now, "dddd, dd/MM")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: parent.updateTime()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            //root.recentNotifications = []
            //console.log(root.notificationPopupOpen)
            root.sideBarOpened = root.sideBarOpened ? false : true
        }
    }
}