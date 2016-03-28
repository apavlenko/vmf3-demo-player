import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

import QmlVlc 0.1
import QtMultimedia 5.0

ApplicationWindow {
    visible: true
    title: qsTr("VMF-3 Demo Player")

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal
        Layout.minimumWidth: 1000
        Layout.minimumHeight: 500

        Rectangle {
            Layout.minimumWidth: 320
            color: "green"
                Text {
                    text: "Video 1"
                    anchors.centerIn: parent
                }
                VlcPlayer {
                    id: vlcPlayer;
                    mrl: "rtsp://192.168.10.218:3414";
                }
                VlcVideoSurface {
                    id: vlcSurface;
                    source: vlcPlayer;
                    anchors.fill: parent;
                }
        }
        Rectangle {
            Layout.minimumWidth: 320
            color: "yellow"
            Text {
                text: "Video 2"
                anchors.centerIn: parent
            }
            VlcPlayer {
                id: vlcPlayer2;
                mrl: "rtsp://192.168.10.190:1234";
            }
            VlcVideoSurface {
                id: vlcVideoOut2;
                source: vlcPlayer2;
                anchors.fill: parent;
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 320
            color: "red"
            Text {
                text: "Map"
                anchors.centerIn: parent
            }
        }
    }

}

