import QtQuick

Item {
    id: mainRoot

    anchors.fill: parent

    property var departures   
    property var showMain

    visible: showMain;

    Column {
        property var departures: parent.departures

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 1
        anchors.rightMargin: 1

        spacing: 1

        Repeater {
            model: parent.departures  

            required property var modelData

            delegate: Rectangle {
                id: delegate

                width: parent.width
                height: 40
                color: '#ffffff'

                Row {
                    anchors.fill: parent

                    spacing: 1

                    Rectangle {
                        id: tripTimes

                        color: "#024aad"

                        width: parent.width * 0.155
                        height: parent.height

                        Column {
                            spacing: 0
                            anchors.fill: parent

                            Text {
                                text: mainRoot.setPrefix(modelData.route_short_name, modelData.vehicle)
                                font.pixelSize: 11
                                
                                width: parent.width
                                height: parent.height * 0.33

                                anchors.left: parent.left
                                anchors.leftMargin: 10

                                color: "#ffffff"
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 10

                                spacing: 20

                                Text {
                                    text: mainRoot.stripSeconds(modelData.departure_time)
                                    font.pixelSize: 20

                                    color: "#ffffff"

                                    width: 45
                                }

                                Rectangle {
                                    //visible: modelData.delay > 0

                                    height: parent.height;
                                    width: 80

                                    color: '#ffffff'

                                    Text {
                                        text: addDelay(modelData.departure_time, modelData.delay)
                                        font.pixelSize: 18
                                        font.bold: true
                                        
                                        anchors.left: parent.left
                                        anchors.leftMargin: 18
                                        anchors.top: parent.top
                                        anchors.topMargin: 1

                                        color: '#000000'
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: destinations

                        color: "#024aad"

                        width: parent.width - tripTimes.width - 400
                        height: parent.height

                        Column {
                            spacing: 0
                            anchors.fill: parent

                            Text {
                                text: mainRoot.getImportantStations(modelData)
                                font.pixelSize: 12

                                anchors.left: parent.left
                                anchors.leftMargin: 10

                                color: "#ffffff"
                            }

                            Text {
                                text: modelData.trip_headsign
                                font.pixelSize: 20
                                font.bold: true

                                anchors.left: parent.left
                                anchors.leftMargin: 10

                                color: "#ffffff"
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width - tripTimes.width - destinations.width - 2
                        height: parent.height

                        color: "#024aad"

                        Column {
                            anchors.fill: parent

                            Text {
                                text: "Von:"
                                font.pixelSize: 12
                                font.italic: true

                                anchors.left: parent.left
                                anchors.leftMargin: 10

                                color: "#ffffff"
                            }

                            Text {
                                text: modelData.stationName
                                font.pixelSize: 20
                                font.bold: true
                                font.italic: true

                                anchors.left: parent.left
                                anchors.leftMargin: 10

                                color: "#ffffff"
                            }
                        }
                    }
                }
            }
        }
    }

    function setPrefix(routeName, vehicleType) {
        if (vehicleType === "metro" && /^[0-9]/.test(routeName)) return "U" + routeName;
        if (vehicleType === "bus") return "Bus " + routeName;
        if (vehicleType === "lux express") return "LUX " + routeName;
        if (vehicleType === "tram") return "STR " + routeName;
        return routeName;
    }

    function stripSeconds(t) {
        let time = t;
        
        if (time.length == 7) {
            time = "0" + time;
        }

        return time.slice(0, -3);
    }

    function addDelay(t, delay) {
        let time = t;

        let [hours, minutes] = time.split(":");

        minutes = Number(minutes);
        hours = Number(hours);

        minutes += delay;

        if (minutes >= 60) {
            hours += Math.floor(minutes / 60);
            minutes -= Math.floor(minutes / 60) * 60
        }

        minutes = String(minutes);
        hours = String(hours);

        if (minutes.length == 1) minutes = "0" + minutes;
        if (hours.length == 1) hours = "0" + hours;

        return [hours, minutes].join(":");
    }

    function getImportantStations(departure) {
        if (!departure.importantStops || departure.importantStops.length === 0) {
            return "-";
        }

        let names = departure.importantStops.map(stop => stop.stop_name);

        return names.join(" - ");
    }
}