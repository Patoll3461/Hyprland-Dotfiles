import QtQuick

Rectangle {
    id: departureRoot

    property var currentDeparture
    property var showDeparture
    property var stopsAlongTrip

    onCurrentDepartureChanged: getImportantStations(currentDeparture.trip_id, currentDeparture.stationName)

    anchors.fill: parent

    visible: showDeparture

    color: "#024aad"

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 60
        anchors.verticalCenter: parent.verticalCenter

        width: 602

        spacing: 5

        Text {
            text: departureRoot.setPrefix(departureRoot.currentDeparture.route_short_name, departureRoot.currentDeparture.vehicle)
            font.pixelSize: 18
            font.bold: true

            color: "#ffffff"
        }

        Row {
            height: 40
            width: parent.width
            
            spacing: 20

            Rectangle {
                height: parent.height
                width: 80

                color: "#024aad"

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: departureRoot.stripSeconds(departureRoot.currentDeparture.departure_time)
                    font.pixelSize: 30
                    font.bold: true

                    color: '#ffffff'
                }
            }

            Rectangle {
                height: parent.height - 8
                width: 80

                color: "#ffffff"

                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent

                    text: departureRoot.addDelay(departureRoot.currentDeparture.departure_time, departureRoot.currentDeparture.delay)
                    font.pixelSize: 24
                    font.bold: true

                    color: "#000000"
                }
            }
        }

        Text {
            id: headsign

            height: 65

            text: departureRoot.currentDeparture.trip_headsign
            font.pixelSize: 60
            font.bold: true

            color: "#ffffff"
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10

            text: "Von: " + departureRoot.currentDeparture.stationName
            font.pixelSize: 20

            color: "#ffffff"
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        width: 500
        height: parent.height
        color: "#063f8f"

        Grid {
            anchors.centerIn: parent
            width: parent.width

            columns: 1
            rowSpacing: 10

            Repeater {
                model: Math.ceil(departureRoot.stopsAlongTrip.length / 3)

                delegate: Row {
                    spacing: 10
                    width: parent.width
                    height: 30

                    property int firstIndex: index * 3
                    property int secondIndex: index * 3 + 1
                    property int thirdIndex: index * 3 + 2

                    // STOP 1
                    Rectangle {
                        width: parent.width / 3 - 40
                        height: 30
                        color: "#063f8f"
                        radius: 3
                        visible: firstIndex < departureRoot.stopsAlongTrip.length

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 6   // IMPORTANT: give it a width!
                            text: departureRoot.stopsAlongTrip[firstIndex].stop_name
                            font.pixelSize: 16
                            font.bold: true
                            color: "#ffffff"

                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            maximumLineCount: 1
                        }
                    }

                    // ARROW 1
                    Text {
                        width: 30
                        height: 30
                        text: "→"
                        font.pixelSize: 20
                        font.bold: true
                        color: "#ffffff"
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        visible: secondIndex < departureRoot.stopsAlongTrip.length
                    }

                    // STOP 2
                    Rectangle {
                        width: parent.width / 3 - 40
                        height: 30
                        color: "#063f8f"
                        radius: 3
                        visible: secondIndex < departureRoot.stopsAlongTrip.length

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 6   // IMPORTANT: give it a width!
                            text: departureRoot.stopsAlongTrip[secondIndex].stop_name
                            font.pixelSize: 16
                            font.bold: true
                            color: "#ffffff"
                        
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            maximumLineCount: 1
                        }
                    }

                    // ARROW 2
                    Text {
                        width: 30
                        height: 30
                        text: "→"
                        font.pixelSize: 20
                        font.bold: true
                        color: "#ffffff"
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        visible: thirdIndex < departureRoot.stopsAlongTrip.length
                    }

                    // STOP 3
                    Rectangle {
                        width: parent.width / 3 - 40
                        height: 30
                        color: "#063f8f"
                        radius: 3
                        visible: thirdIndex < departureRoot.stopsAlongTrip.length

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 6   // IMPORTANT: give it a width!
                            text: departureRoot.stopsAlongTrip[thirdIndex].stop_name
                            font.pixelSize: 16
                            font.bold: true
                            color: "#ffffff"
                        
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            maximumLineCount: 1
                        }
                    }
                }
            }
        }
    }

    function setPrefix(routeName, vehicleType) {
        console.log(vehicleType)
        console.log(routeName)
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

    function getImportantStations(trip_id, start_stop) {
        //console.log("Start stop: " + start_stop)

        var xhr = new XMLHttpRequest();
        xhr.open("GET", `http://localhost:3050/trips/${trip_id}/stops?start_stop=${start_stop}`);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var data = JSON.parse(xhr.responseText);

                    stopsAlongTrip = data.result;
                    return data;
                } else {
                    console.log("failed to get stops: " + xhr.status)
                }
            }
        }
        xhr.send();
    }
}