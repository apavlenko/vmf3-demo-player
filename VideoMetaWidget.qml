import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

import QmlVlc 0.1
import QtMultimedia 5.0

import vmf3.demo.metadata 1.0

Rectangle {
    property string ip
    property bool playing : false
    property double invAspectRatio : 1.0
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
        console.debug("vlcPlayer stopped")
        mdProvider.stop()
        console.debug("mdProvider stopped")
        startStopButton.text = "Start"

        compressorIdLabel.text  = "(None)"
        encryptionPwdLabel.text = "(None)"
        countLabel.text   = "(None)"
        minLatLabel.text  = "(None)"
        avgLatLabel.text  = "(None)"
        lastLatLabel.text = "(None)"

        playing = false
        //emit signal
        stopped()
    }

    Component.onCompleted: {
        ipCombo.model.append({text: ip})
    }

    onInvAspectRatioChanged: {
        videoPanel.height = videoPanel.width*invAspectRatio
    }

    SplitView
    {
        anchors.fill: parent
        orientation: Qt.Vertical

        Rectangle {
            id: videoPanel
            Layout.minimumHeight: 120
            //Layout.fillHeight: true
            height: width*invAspectRatio

            onWidthChanged: {
                height = width*invAspectRatio
            }

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

            GridLayout {
                columns: 2
                anchors.fill: parent

                Text {
                    text: "Wrapping info"
                    font.bold: true
                    Layout.row: 0
                    Layout.column: 0
                }

                Text {
                    text: "compressor ID: "
                    Layout.row: 1
                    Layout.column: 0
                }

                Text {
                    id: compressorIdLabel
                    font.italic: true
                    Layout.row: 1
                    Layout.column: 1
                    text: "(None)"
                }

                Text {
                    text: "encryption passphrase: "
                    Layout.row: 2
                    Layout.column: 0
                }

                Text {
                    id: encryptionPwdLabel
                    font.italic: true
                    Layout.row: 2
                    Layout.column: 1
                    text: "(None)"
                }

                Text {
                    text: "Stat info"
                    font.bold: true
                    Layout.row: 3
                    Layout.column: 0
                }

                Text {
                    text: "count: "
                    Layout.row: 4
                    Layout.column: 0
                }

                Text {
                    id: countLabel
                    Layout.row: 4
                    Layout.column: 1
                    text: "(None)"
                }

                Text {
                    text: "min Lat: "
                    Layout.row: 5
                    Layout.column: 0
                }

                Text {
                    id: minLatLabel
                    Layout.row: 5
                    Layout.column: 1
                    text: "(None)"
                }

                Text {
                    text: "avg Lat: "
                    Layout.row: 6
                    Layout.column: 0
                }

                Text {
                    id: avgLatLabel
                    Layout.row: 6
                    Layout.column: 1
                    text: "(None)"
                }

                Text {
                    text: "last Lat: "
                    Layout.row: 7
                    Layout.column: 0
                }

                Text {
                    id: lastLatLabel
                    Layout.row: 7
                    Layout.column: 1
                    text: "(None)"
                }
            }

            MetadataProvider {
                id: mdProvider;
                onMetadataAdded: {
                    console.debug("onMetadataAdded()")
                    invAspectRatio = vlcPlayer.video.height/vlcPlayer.video.width
                    compressorIdLabel.text  = mdProvider.wrappingInfo.compressionID
                    encryptionPwdLabel.text = mdProvider.wrappingInfo.passphrase
                    countLabel.text   = mdProvider.statInfo.count
                    minLatLabel.text  = mdProvider.statInfo.minLat
                    avgLatLabel.text  = mdProvider.statInfo.avgLat
                    lastLatLabel.text = mdProvider.statInfo.lastLat

                    trajectoryChanged(mdProvider.locations);
                }
            }
        }
    }


}

