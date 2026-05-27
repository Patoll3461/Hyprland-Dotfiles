import QtQuick
import Quickshell
import QtTextToSpeech
import Quickshell.Io
import "Main.qml"
import "Departure.qml"

PanelWindow  {
    id: root;

    property var stations
    property var routes
    property var departures: []
    property var delayed: {}

    property var currentDeparture: {}

    property var showMain: true;
    property var showDeparture: false;

    anchors {
        top: true
        left: true
    }

    implicitWidth: 1102
    implicitHeight: 288
    height: 300

    color: "#ffffff"

    Component.onCompleted: loadSettings()

    Timer {
        interval: 60000;
        running: true;
        repeat: true;
        
        onTriggered: getDepartures()
    }

    Main {
        departures: root.departures 
        showMain: root.showMain  
    }

    Departure {
        currentDeparture: root.currentDeparture
        showDeparture: root.showDeparture
    }

    Process {
        id: ttsProcess
        running: false
        command: [ "/home/patoll/.pyenv/shims/python", "/home/patoll/python/coqui_tts.py", "Tes" ]
    }

    Timer {
        id: jingleTimer
        running: false
        repeat: false
        interval: 3000
        onTriggered: {
            jingleProcess.running = true
        }
    }

    Process {
        id: jingleProcess
        running: false 
        command: ["mpg123", "/home/patoll/.config/quickshell/opnv/gong.mp3"]
    }

    function sayTTS(text) {
        var pythonPath = "/home/patoll/.pyenv/versions/3.11.10/bin/python3"
        var scriptPath = "/home/patoll/python/coqui_tts.py"
        // Wrap input text in single quotes
        var cmd = pythonPath + " " + scriptPath + " '" + text + "'"
        Qt.openUrlExternally("bash -c \"" + cmd + "\"")
    }

    function loadSettings() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "settings.json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var data = JSON.parse(xhr.responseText);

                    stations = data.stations;
                    routes = data.routes;

                    getDepartures();
                } else {
                    console.log("failed to load settings: " + xhr.status);
                }
            }
        }
        xhr.send();
    }

    function getDepartures() {
        if (!delayed) delayed = {};

        let params = [];

        if (stations.length > 0) {
            params.push(`stops=${stations.join(",")}`);
        }

        if (routes.length > 0) {
            params.push(`routes=${routes.join(",")}`);
        }

        let delayedKeys = Object.keys(delayed);
        if (delayedKeys.length > 0) {
            params.push(`delayed=${delayedKeys.join(",")}`);
        }
        
        let queryString = params.length > 0 ? `?${params.join("&")}` : "";

        const delayedArray = Object.entries(delayed).map(([id, start_stop]) => ({
            id,
            start_stop
        }));

        const requestBody = {
            stops: stations,
            routes: routes,
            delayed: delayedArray
        }

        var xhr = new XMLHttpRequest();
        xhr.open("POST", `http://localhost:3050/refresh${queryString}`);
        //xhr.open("GET", "data.json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var data = JSON.parse(xhr.responseText);

                    departures = data.departures;

                    root.showMain = true;
                    root.showDeparture = false;
                    //root.currentDeparture = departures[0]

                    //console.log(JSON.stringify(departures, null, 2));

                    let nowStr = getLocalTime();

                    //let nowStr = "18:55"

                    console.log(nowStr)

                    departures = departures.filter(dep => {
                        let totalTime = dep.departure_time;

                        if (dep.delay > 0) {
                            totalTime = addDelay(dep.departure_time, dep.delay);

                            // store only trip_id → stationName
                            delayed[dep.trip_id] = dep.stationName;
                        }

                        let depTimeShort = totalTime.split(":").slice(0, 2).join(":");

                        if (depTimeShort < nowStr) {
                            delete delayed[dep.trip_id];
                            return false;
                        }

                        if (depTimeShort == nowStr) {
                            //console.log("test")

                            root.showMain = false;
                            root.currentDeparture = dep;
                            root.showDeparture = true;

                            console.log("executing...")

                            // Find the important stop with the highest route_number
                            let mainStop = dep.importantStops.reduce((prev, curr) => {
                                return (Number(curr.route_number) > Number(prev.route_number)) ? curr : prev;
                            }, dep.importantStops[0]);

                            // Construct announcement using only that stop
                            let routeSpoken = spellRoute(setPrefix(dep.route_short_name, dep.vehicle));

                            jingleTimer.running = true

                            ttsProcess.command[2] = `Abfahrt, ${routeSpoken}, von, ${dep.stationName}, über, ${mainStop.stop_name}, nach, ${dep.trip_headsign}.`;
                            console.log(ttsProcess.command[2])
                            ttsProcess.running = true
                        }

                        return true;
                    });

                    console.log("refreshed!");
                } else {
                    console.log("failed to refresh data: " + xhr.status);
                }
            }
        }
        console.log("refreshing...");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify(requestBody));
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

    function getBerlinTime() {
        let now = new Date(); // system local time
        let utc = now.getTime() + (now.getTimezoneOffset() * 60000); // convert local to UTC

        // Berlin offset in minutes: 60 in winter, 120 in summer
        // Simple DST check: Berlin observes DST from last Sunday in March to last Sunday in October
        let year = now.getFullYear();

        // Last Sunday in March
        let dMarch = new Date(year, 2, 31);
        dMarch.setDate(31 - dMarch.getDay());

        // Last Sunday in October
        let dOct = new Date(year, 9, 31);
        dOct.setDate(31 - dOct.getDay());

        let offset = 60; // CET default
        if (now >= dMarch && now < dOct) offset = 120; // CEST

        let berlinTime = new Date(utc + offset * 60000);

        let hours = berlinTime.getHours().toString().padStart(2, "0");
        let minutes = berlinTime.getMinutes().toString().padStart(2, "0");

        return hours + ":" + minutes; // HH:MM
    }

    function getLocalTime() {
        const now = new Date(); // already local time

        const hours = now.getHours().toString().padStart(2, "0");
        const minutes = now.getMinutes().toString().padStart(2, "0");

        return `${hours}:${minutes}`;
    }

    function setPrefix(routeName, vehicleType) {
        if (vehicleType === "metro" && /^[0-9]/.test(routeName)) return "U" + routeName;
        if (vehicleType === "bus") return "Bus " + routeName;
        if (vehicleType === "lux express") return "LUX " + routeName;
        if (vehicleType === "tram") return "STR " + routeName;
        return routeName;
    }

    function spellRoute(route) {
        const letterMap = {
            "A":"ah","B":"be","C":"ceh","D":"deh","E":"eh","F":"ef","G":"geh","H":"ha",
            "I":"i","J":"jot","K":"kah","L":"el","M":"em","N":"en","O":"oh","P":"peh",
            "Q":"ku","R":"er","S":"es","T":"teh","U":"uu","V":"fau","W":"weh","X":"ix",
            "Y":"ypsilon","Z":"tset"
        };

        const numMap = ["null","eins","zwei","drei","vier","fünf","sechs","sieben","acht","neun"];

        let result = [];
        let letterCluster = [];

        function flushLetters() {
            if (letterCluster.length > 0) {
                const originalWord = letterCluster.join("");
                if (originalWord.toLowerCase() === "beuues") {
                    result.push("Bus");
                } else {
                    result.push(letterCluster.join(" "));
                }
                result.push(", ")
                letterCluster = [];
            }
        }

        for (let c of route) {
            if (/[0-9]/.test(c)) {
                flushLetters();
                result.push(numMap[Number(c)]);
            } else {
                let upper = c.toUpperCase();
                if (letterMap[upper]) {
                    letterCluster.push(letterMap[upper]);
                } else {
                    flushLetters();
                    result.push(c);
                }
            }
        }

        // flush remaining letters at the end
        flushLetters();

        return result.join(" ");
    }
}