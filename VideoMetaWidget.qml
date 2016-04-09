import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

import QmlVlc 0.1
import QtMultimedia 5.0

import vmf3.demo.metadata 1.0

Rectangle {
    property string ip
    property bool playing : false
    signal trajectoryChanged(variant trajectory)
    signal started()
    signal stopped()

    function getMrl(ipText)
    {
        return "rtsp://"+ipText+":1234";
    }

    function getVMFaddr(ipText)
    {
        return ipText+":4321";
    }

    function updateIp(newIp)
    {
        console.debug("updateIp")
        if(ip !== newIp)
        {
            ip = newIp
            start()
        }
        console.debug("ip="+ip)
    }

    function togglePlaying()
    {
        if(!playing)
            start()
        else
            stop()
    }

    //start sequence is the following:
    //start() => vlcPlayer.onMediaPlayerPlaying() => playerStarted() => emit started()
    function start()
    {
        console.debug("start")
        videoLabel.text = ip
        if(vlcPlayer.playing)
            vlcPlayer.stop()
        vlcPlayer.mrl = getMrl(ip)
        vlcPlayer.play()
    }

    function playerStarted()
    {
        mdProvider.stop()
        mdProvider.address = getVMFaddr(ip)
        mdProvider.start()
        //emit signal
        started()
        startStopButton.text = "Stop"
        playing = true
    }

    function stop()
    {
        console.debug("stop")
        videoLabel.text = "Stopped"
        vlcPlayer.stop()
        mdProvider.stop()
        startStopButton.text = "Start"
        playing = false
        //emit signal
        stopped()
    }

    Component.onCompleted: {
        ipCombo.model.append({text: ip})
    }

    SplitView
    {
        anchors.fill: parent
        orientation: Qt.Vertical

        Rectangle {
            id: videoPanel
            Layout.minimumHeight: 120
            //Layout.fillHeight: true
            Text {
                id: videoLabel
                text: "No video"
                anchors.centerIn: parent
            }
            VlcPlayer {
                id: vlcPlayer;
                onMediaPlayerPlaying: playerStarted();
            }
            VlcVideoSurface {
                id: vlcSurface;
                source: vlcPlayer;
                anchors.fill: parent;
            }
        }

        Rectangle {
            id: buttonsPanel
            Layout.minimumHeight: 30
            Layout.maximumHeight: 30

            RowLayout {
                anchors.fill: parent

                ComboBox {
                    id: ipCombo
                    editable: true
                    Layout.fillWidth: true
                    model: ListModel { }
                    onAccepted: {
                        console.debug("onAccepted")
                        if (find(currentText) === -1) {
                            ipCombo.model.append({text: editText})
                            currentIndex = find(editText)
                        }
                        updateIp(editText)
                    }
                    onActivated: {
                        console.debug("onActivated")
                        updateIp(textAt(index))
                    }
                }
                Button {
                    id: startStopButton
                    width: 25
                    text: "Start"
                    onClicked: togglePlaying()
                }
            }
        }

        Rectangle {
            id: infoPanel
            Layout.minimumHeight: 75
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignBottom
            Text {
                text: "Info panel"
            }

            MetadataProvider {
                id: mdProvider;
                onLocationsChanged: {
                    videoPanel.width  = vlcPlayer.video.width
                    videoPanel.height = vlcPlayer.video.height

                    trajectoryChanged(mdProvider.locations);
                    //trajectoryChanged(locations);
                }
            }

            BusyIndicator {
                anchors.fill: parent
                height: 20
            }
        }
    }


}

