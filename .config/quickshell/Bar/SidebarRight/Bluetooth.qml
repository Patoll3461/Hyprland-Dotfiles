import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth

Rectangle {
    id: btRoot

    property var btDevices: Bluetooth.defaultAdapter.devices.values
        .filter(obj => obj.deviceName && obj.deviceName.trim() !== "")
        .sort((a, b) => Number(b.connected) - Number(a.connected))


    width: 350
    height: 800
    anchors.horizontalCenter: parent.horizontalCenter
    y: 100
    color: "#1c065a"
    visible: false
    radius: 10

    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: parent.width
        contentHeight: columnContent.height + 40

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.alwaysOn
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 5
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            height: 100
            width: 8
            active: true

            contentItem: Rectangle {
                radius: 4
                color: "#9372f0"
            }

            background: Rectangle {
                radius: 4
                color: "#4c3ac2"
            }
        }

        Rectangle {
            color: "#9372f0"

            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.leftMargin: 25
            radius: 10

            width: 180
            height: 60

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter

                color: "#ffffff"
                text: "Search"
            
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                font.bold: true
                font.pixelSize: 20
            }

            Switch {
                id: discovering

                anchors.left: parent.left
                anchors.leftMargin: 100
                anchors.verticalCenter: parent.verticalCenter

                height: 30
                width: 60

                //text: qsTr("Search")
                checked: Bluetooth.defaultAdapter.discovering
                onClicked: Bluetooth.defaultAdapter.discovering = checked

                indicator: Rectangle {
                    property alias control: discovering

                    implicitWidth: 60
                    implicitHeight: 30
                    radius: height / 2
                    color: control.checked ? "#cc8b00" : "#4c3ac2"

                    Rectangle {
                        id: knob

                        width: parent.height - 6
                        height: parent.height - 6
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.control.checked ? parent.width - width - 3 : 3
                        color: "#ffffff"
                        border.color: "#9372f0"

                        Behavior on x {
                            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad}
                        }
                    }
                }
            }
        }

        /*MouseArea {
            width: 300
            height: 100
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering
            }

            Rectangle {
                anchors.fill: parent
                radius: 10

                Text {
                    anchors.centerIn: parent

                    text: Bluetooth.defaultAdapter.discovering ? "Cancel Scan" : "Scan for Devices"
                }
            }
        }*/

        Column {
            id: columnContent

            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 100

            spacing: 20

            Repeater {
                model: btRoot.btDevices

                delegate: Rectangle {
                    id: delegate

                    required property var index
                    required property var modelData

                    color: index === 0 && modelData.connected ? "#9372f0" : "#4c3ac2"

                    width: 300
                    height: 100
                    anchors.horizontalCenter: parent.horizontalCenter

                    radius: 10

                    Column {
                        width: 180
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        spacing: 2


                        Text {
                            width: 180

                            elide: Text.ElideRight

                            font.bold: true
                            font.pixelSize: 22

                            text: delegate.modelData.deviceName

                            color: "#ffffff"
                        }

                        Text {
                            width: 180

                            elide: Text.ElideRight

                            font.pixelSize: 14

                            text: parent.getStatus()

                            color: "#ffffff"
                        }

                        function getStatus() {
                            if (delegate.modelData.paired) {
                                if (delegate.modelData.connected) {
                                    return "Connected"
                                } else {
                                    return "Paired"
                                }
                            } else {
                                return "New"
                            }
                        }
                    }

                    Rectangle {
                        color: delegate.index === 0 && delegate.modelData.connected ? "#4c3ac2" : "#9372f0"
                        width: delegate.modelData.paired ? 130 : 180
                        height: 25
                        y: 60
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        radius: 10

                        Text {
                            color: "#ffffff"
                            text: parent.getState()
                            anchors.centerIn: parent
                            font.pixelSize: 18
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent

                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (delegate.modelData.paired) {
                                    if (delegate.modelData.connected) {
                                        delegate.modelData.disconnect()
                                    } else {
                                        delegate.modelData.connect()
                                    }
                                } else {
                                    delegate.modelData.pair()
                                }
                            }
                        }

                        function getState() {
                            if (delegate.modelData.paired) {
                                if (delegate.modelData.connected) {
                                    return "Disconnect"
                                } else {
                                    return "Connect"
                                }
                            } else {
                                return "Pair"
                            }
                        }
                    }

                    Rectangle {
                        visible: delegate.modelData.paired

                        color: delegate.index === 0 && delegate.modelData.connected  ? "#4c3ac2" : "#9372f0"
                        width: 30
                        height: 25
                        y: 60
                        anchors.left: parent.left
                        anchors.leftMargin: 145
                        radius: 10

                        Text {
                            color: "#ffffff"
                            anchors.left: parent.left
                            anchors.leftMargin: 9.3
                            anchors.top: parent.top
                            anchors.topMargin: 1.2
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 18
                            font.bold: true
                            text: "X"
                        }

                        MouseArea {
                            anchors.fill: parent

                            cursorShape: Qt.PointingHandCursor


                            onClicked: {
                                delegate.modelData.forget()
                            }
                        }
                    }

                    Image {
                        visible: delegate.modelData.icon !== ""
                        source: Quickshell.iconPath(delegate.modelData.icon)
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        height: 95
                        width: 95
                    }
                }
            }
        }
    }
}