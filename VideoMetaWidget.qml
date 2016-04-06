import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

import QmlVlc 0.1
import QtMultimedia 5.0

Rectangle {
    property string ip

    function getMrl(ipText)
    {
        return "rtsp://"+ipText+":1234";
    }

    function getVMFaddr(ipText)
    {
        return ipText+":1234";
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

    function start()
    {
        console.debug("start")
        videoLabel.text = ip
        if(vlcPlayer.playing)
            vlcPlayer.stop()
        vlcPlayer.mrl = getMrl(ip);
        vlcPlayer.play();
    }

    function stop()
    {
        console.debug("stop")
        videoLabel.text = "Stopped"
        vlcPlayer.stop();
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
            //Layout.preferredHeight:
            Layout.fillHeight: true
            Text {
                id: videoLabel
                text: "No video"
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

        Rectangle {
            id: buttonsPanel
            Layout.minimumHeight: 30

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
                    id: startButton
                    width: 25
                    text: "Start"
                    onClicked: start()
                }
                Button {
                    id: stopButton
                    width: 25
                    text: "Stop"
                    onClicked: stop()
                }
            }
        }

        Rectangle {
            id: infoPanel
            Layout.minimumHeight: 75
            Layout.alignment: Qt.AlignBottom
            Text {
                text: "Info panel"
            }
            BusyIndicator {
                anchors.fill: parent
                height: 20
            }
        }
    }


}

