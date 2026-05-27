pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Rectangle {
    id: wifiRoot

    property var availableWifis: []

    property var isEntering: false

    width: 350
    height: 800
    anchors.horizontalCenter: parent.horizontalCenter
    y: 100
    color: "#1c065a"
    visible: false
    radius: 10

    Text {
        visible: parent.availableWifis.length === 0
        text: "No Wifis available"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 340
        color: "#ffffff"
        font.pixelSize: 30
        font.bold: true
    }

    ScrollView {
        visible: parent.availableWifis.length !== 0

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

        Column {
            id: columnContent

            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            //anchors.bottom: parent.bottom
            //anchors.bottomMargin: 10
            
            //anchors.bottomMargin: 20
            spacing: 20

            Repeater {
                //anchors.fill: parent

                model: wifiRoot.availableWifis

                delegate: Rectangle {
                    id: delegate

                    required property var index
                    required property var modelData

                    property var requiresPassword: modelData.security !== ""

                    width: 300
                    height: 100
                    //y: index * 120 + 20
                    color: index === 0 ? "#9372f0" : "#4c3ac2"
                    radius: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width: 180
                        height: 80
                        radius: 10
                        color: parent.index === 0 ?  "#9372f0": "#4c3ac2"

                        Column {
                            width: 180
                            //height: 100
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            spacing: 2

                            Text {
                                width: 180
                                text: delegate.modelData.ssid
                                font.pixelSize: 22
                                font.bold: true
                                elide: Text.ElideRight
                                color: "#ffffff"
                            }

                            Text {
                                width: 180
                                text: delegate.modelData.security != "" ? delegate.modelData.security : "No Security"
                                font.pixelSize: 14
                                //font.bold: true
                                elide: Text.ElideRight
                                color: "#ffffff"
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            color: delegate.index === 0 ? "#4c3ac2" : "#9372f0"
                            width: 180
                            height: 25
                            radius: 10
                            y: 60

                            MouseArea {
                                id: button

                                property var isClicked: false

                                anchors.fill: parent
                                cursorShape: delegate.index === 0 ? Qt.ArrowCursor : Qt.PointingHandCursor
                                enabled: true

                                onClicked: {
                                    if (delegate.index === 0) return
                                    if (isClicked) return

                                    //rootWindow.mayFocusSidebar = false

                                    hasCredentials.running = true
                                }

                                Text {
                                    visible: !parent.isClicked

                                    anchors.centerIn: parent
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#ffffff"

                                    text: delegate.index === 0 ? "Connected" : "Connect"
                                }
                            }

                            TextField {
                                id: pwdField

                                z: 10
                                focus: button.isClicked
                                visible: button.isClicked
                                width: 180
                                placeholderText: qsTr("Password")
                                echoMode: TextInput.Password
                                //color: "#ffffff"

                                palette {
                                    placeholderText: "#ffffff"
                                    text: "#ffffff"
                                }
                            
                                background: Rectangle {
                                    color: "#9372f0"
                                    radius: 10
                                }

                                onAccepted: {
                                    delegate.setCredentials(delegate.modelData.ssid, text, delegate.modelData.security)
                                    connect.running = true
                                    button.enabled = true
                                    button.isClicked = false
                                    wifiRoot.isEntering = false
                                    //rootWindow.mayFocusSidebar = true
                                }

                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Escape) {
                                        button.enabled = true
                                        button.isClicked = false
                                        button.visible = true
                                        rootWindow.mayFocusSidebar = true
                                        rightPanel.exitFocus.focus = true
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 15
                        width: 70
                        height: 70
                        color: "#cc8b00"
                        radius: 10

                        Image {
                            source: Quickshell.iconPath("network-wireless-connected-" + Math.round(delegate.modelData.signal / 25) * 25)
                            anchors.centerIn: parent
                            width: 60
                            height: 60
                        }
                    }

                    Process {
                        id: connect

                        running: false

                        property var ssid
                        property var pwd: ""
                        property var security: ""

                        command: ["sh", "/home/patoll/.config/quickshell/scripts/connectWifi.sh", ssid, pwd, security]

                        stdout: StdioCollector {
                            onStreamFinished: {
                                if (this.text.toLowerCase().includes("failed")) {
                                    button.enabled = true
                                    button.isClicked = false
                                    button.visible = true
                                    rootWindow.mayFocusSidebar = true
                                    //rootWidnow.mayFocusMediaWidget = true
                                    rightPanel.exitFocus.focus = true
                                    pwdField.text = ""
                                }
                            }
                        }

                        onExited: {
                            button.enabled = true
                            button.isClicked = false
                            button.visible = true
                            rootWindow.mayFocusSidebar = true
                            rightPanel.exitFocus.focus = true
                        }
                    }

                    function setCredentials(ssid, pwd, security) {
                        connect.ssid = ssid
                        connect.pwd = pwd
                        connect.security = security
                    }

                    Process {
                        id: hasCredentials

                        running: false

                        property var ssid: delegate.modelData.ssid

                        command: ["sh", "/home/patoll/.config/quickshell/scripts/hasCredentials.sh", ssid]

                        stdout: StdioCollector {
                            onStreamFinished: {
                                console.log(this.text)
                                if (this.text.trim() === "true") {
                                    connectExisting.running = true
                                    return
                                }

                                if (!delegate.requiresPassword) {
                                    delegate.setCredentials(delegate.modelData.ssid, "", "")
                                    connect.running = true
                                    return
                                }
                                rootWindow.mayFocusSidebar = false
                                button.isClicked = true
                                button.enabled = false
                                button.visible = false
                                wifiRoot.isEntering = true
                            }
                        }
                    }

                    Process {
                        id: connectExisting

                        running: false

                        property var ssid: delegate.modelData.ssid

                        command: ["nmcli", "connection", "up", "id", ssid]

                        onExited: {
                            rootWindow.mayFocusSidebar = true
                            rightPanel.exitFocus.focus = true
                            button.isClicked = true
                            button.enabled = false
                            button.visible = false
                        }   
                    }
                }
            }
        }
    }


    Process {
        id: getWifi

        command: ["sh", "/home/patoll/.config/quickshell/scripts/getWifi.sh"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                availableWifis = (new Function("return " + this.text))();
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            if (wifiRoot.isEntering) return
            getWifi.running = true
        }
    }
}