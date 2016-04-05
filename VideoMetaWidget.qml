import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

import QmlVlc 0.1
import QtMultimedia 5.0

Rectangle {
    property alias mrl: vlcPlayer.mrl
    property alias altText: label.text

    Text {
        id: label
        anchors.centerIn: parent
    }
    VlcPlayer {
        id: vlcPlayer;
    }
    VlcVideoSurface {
        id: vlcSurface;
        source: vlcPlayer;
        anchors.fill: parent;
    }
}

