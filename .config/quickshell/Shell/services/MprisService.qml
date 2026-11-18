pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import "."

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") + "/"

    //Delete old arts
    Process {
        id: cleanup
        command: ["find", `${root.home}.config/quickshell/Shell/art/`, "-type", "f", "-delete"]
        running: false
    }

    //On startup run this
    Component.onCompleted: {
        cleanup.running = true
    }

    //All players as objects
    property list<MprisPlayerObject> players

    //All player objects
    Instantiator {
        model: Mpris.players.values

        delegate: MprisPlayerObject {
            required property var modelData

            player: modelData
        }

        //Add to list
        onObjectAdded:   (i, obj) => { root.players = [...root.players, obj] }
        onObjectRemoved: (i, obj) => { root.players = root.players.filter(p => p !== obj) }
    }

    property MprisPlayerObject previousPlayer: players[0]

    //Get first active player
    readonly property MprisPlayerObject activePlayer: {
        for (let p of players) {
            if (p.isPlaying) {
                previousPlayer = p
                return p
            } 
        }
        if (previousPlayer) return previousPlayer
        return players.length > 0 ? players[0] : null
    }
}