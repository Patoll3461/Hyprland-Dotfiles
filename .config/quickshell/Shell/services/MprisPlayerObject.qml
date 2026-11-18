import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick


Item {
    id: root

    readonly property string home: Quickshell.env("HOME") + "/" //Home dir 

    required property MprisPlayer player //Mpris player object
            
    //Passthrough properties
    readonly property string identity:     player.identity      ?? ""
    readonly property string trackTitle:   player.trackTitle    ?? ""
    readonly property string trackArtist:  player.trackArtist   ?? ""
    readonly property string trackAlbum:   player.trackAlbum    ?? ""
    readonly property bool   isPlaying:    player.isPlaying     ?? false
    readonly property bool   canPlay:      player.canPlay       ?? false
    readonly property bool   canPause:     player.canPause      ?? false
    readonly property bool   canGoNext:    player.canGoNext     ?? false
    readonly property bool   canGoPrevious:player.canGoPrevious ?? false
    property real   position:     player.position      ?? 0
    readonly property real   length:       player.length        ?? 0
    property string bestArtUrl:   ""
    property string trackArtUrl:  player.trackArtUrl

    //Control Passthrough
    function play()          { player.play() }
    function pause()         { player.pause() }
    function togglePlaying() { player.togglePlaying() }
    function next()          { player.next() }
    function previous()      { player.previous() }
    property var resolutions: []

    //When new track art is emitted check if its higher res
    onTrackArtUrlChanged: {
        getBestArt()
    }

    function getBestArt() {
        if (trackArtUrl.includes("https://") || trackArtUrl.includes("http://")) {
            bestArtUrl = trackArtUrl
            return
        }

        //If its the first art accept it as best
        if (bestArtUrl === "") {
            let dir = `${root.home}.config/quickshell/Shell/art/${Date.now()}-${trackTitle.replace(/\s+/g, "")}.png`
            copyProcess.command = ["cp", player.trackArtUrl.replace("file://", ""), dir]
            copyProcess.running = true
            bestArtUrl = `file://${dir}`

            return
        }

        //Reset temporary comparison variable
        resolutions = []

        //Get the Resolution of the new track art
        if (player.trackArtUrl.replace("file://", "") !== "") {
            resProcessNew.command = ["sh", `${root.home}.config/quickshell/Shell/scripts/getRes.sh`, player.trackArtUrl.replace("file://", "")]
            resProcessNew.running = true
        }

        //Get the Resolution of the current best art
        if (bestArtUrl.replace("file://", "") !== "") {
            resProcessBest.command = ["sh", `${root.home}.config/quickshell/Shell/scripts/getRes.sh`, bestArtUrl.replace("file://", "")]
            resProcessBest.running = true
        }
    }

    //If a new track is playing reset the track art
    onTrackTitleChanged: {
        delProcess.running = true
        bestArtUrl = ""
    }

    Process {
        id: resProcessNew

        command: []
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                //Set the temporary variable resolution for comparison
                var res = text.replace("Resolution: ", "").replace(/(\r\n|\n|\r)/gm, "").split("x")
                if (res == undefined) return
                root.resolutions[0] = res
                //Compare
                root.compareResolutions()
            }
        }
    }

    Process {
        id: resProcessBest

        command: []
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                //Set the temporary variable resolution for comparison
                var res = text.replace("Resolution: ", "").replace(/(\r\n|\n|\r)/gm, "").split("x")
                if (res == undefined) return
                root.resolutions[1] = res
                //Compare
                root.compareResolutions()
            }
        }
    }

    function compareResolutions() {
        //Check if all resolutions are present/known
        if (resolutions.length === 2 && !resolutions.includes(undefined)) {
            const w0 = Number(resolutions[0][0])
            const h0 = Number(resolutions[0][1])
            const w1 = Number(resolutions[1][0])
            const h1 = Number(resolutions[1][1])

            //Check number of pixels and compare
            if (w0 * h0 > w1 * h1) {
                //Set new best art and copy file
                let dir = `${root.home}.config/quickshell/Shell/art/${Date.now()}-${trackTitle.replace(/\s+/g, "")}.png`
                copyProcess.command = ["cp", player.trackArtUrl.replace("file://", ""), dir]
                copyProcess.running = true
                bestArtUrl = `file://${dir}`
            }
        }
    }

    //Process for copying the best art
    Process {
        id: copyProcess

        command: []
        running: false
    }

    //Process for deleting the currently stored art
    Process {
        id: delProcess

        command: ["find", root.bestArtUrl.replace("file://", ""), "-type", "f", "-delete"]
        running: false
    }

    //Update position
    Timer {
        interval: 50
        repeat: true
        running: true

        onTriggered: {
            root.position = root.player.position
        }
    }
}