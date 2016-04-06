import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

import QmlVlc 0.1
import QtMultimedia 5.0

import QtWebEngine 1.2

import vmf3.demo.metadata 1.0

ApplicationWindow {
    visible: true
    title: qsTr("VMF-3 Demo Player")

    function initializeMap()
    {
        var coord  = {lat : 37.235, lng : -115.811};
        var script = "map.setCenter(new google.maps.LatLng(%1,%2));\n";
        web.runJavaScript(script.arg(coord.lat).arg(coord.lng));
    }

    function drawObject()
    {
        var script = "drawObject(%1 , %2,  %3);\n";
        var coord  = {lat : 37.235 + 0.01, lng : -115.811 + 0.02};
        var rotate = 45;
        web.runJavaScript(script.arg(coord.lat).arg(coord.lng).arg(rotate));
    }

    function drawRoute()
    {
        var coord1  = {lat : 37.235, lng : -115.811};
        var coord2  = {lat : coord1.lat + 0.01, lng : coord1.lng - 0.02};
        var script = "";
        script += "myCoordinates = [\n";
        for(var i = 0; i < 25; i++)
        {
            var t = 1.0*i/24;
            var lat = t*coord1.lat + (1.0-t)*coord2.lat;
            var lng = t*coord1.lng + (1.0-t)*coord2.lng;
            script += "new google.maps.LatLng(%1 , %2),\n".arg(lat).arg(lng);
        }
        script += "];\n";
        script += "myColor = '#FF0000';\n";
        script += "drawRoute(myCoordinates, myColor);\n";
        web.runJavaScript(script);
    }

    function drawVertex(coord1, coord2)
    {
        var script = "";
        script += "myCoordinates = [\n";
        {
            var lat = coord1.x;
            var lng = coord1.y;
            script += "new google.maps.LatLng(%1 , %2),\n".arg(lat).arg(lng);
        }
        {
            var lat = coord2.x;
            var lng = coord2.y;
            script += "new google.maps.LatLng(%1 , %2),\n".arg(lat).arg(lng);
        }
        script += "];\n";
        script += "myColor = '#FF0000';\n";
        script += "drawRoute(myCoordinates, myColor);\n";
        web.runJavaScript(script);
    }

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
                    mrl: "rtsp://192.168.10.218:1234";
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
                mrl: "rtsp://192.168.10.176:1234";
            }
            VlcVideoSurface {
                id: vlcVideoOut2;
                source: vlcPlayer2;
                anchors.fill: parent;
            }
            MetadataProvider {
                id: mdprovider2;
                address: "192.168.10.176:4321"
                property var points : [];
                onLocationsChanged: {
                    points[points.length] = locations;
                    if (points.length >= 2) {
                        var p1 = points[points.length-2];
                        var p2 = points[points.length-1];
                        drawVertex(p1, p2);
                    }
                }
            }
        }

        SplitView {
            orientation: Qt.Vertical

            Button {
                text: "init"
                onClicked: {
                    initializeMap();
                }
            }
            Button {
                text : "draw object"
                onClicked: {
                    drawObject();
                    console.debug("mouse2 clicked");
                    mdprovider2.start();
                }
            }
            Button {
                text : "draw route"
                onClicked: {
                    drawRoute();
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 320
            color: "red"

            WebEngineView {
                id: web
                anchors.fill: parent
                url: "map.html"
            }

        }
    }

}

