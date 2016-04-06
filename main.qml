import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

import QmlVlc 0.1
import QtMultimedia 5.0

import QtWebEngine 1.2

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
        var coord  = {lat : 37.235 + 0.01 + Math.random()%0.001, lng : -115.811 + 0.01 + Math.random()%0.001};
        var rotate = 45;
        web.runJavaScript(script.arg(coord.lat).arg(coord.lng).arg(rotate));
    }

    function removeObject()
    {
        web.runJavaScript("removeObject();\n");
    }

    function drawRoute()
    {
        removeRoute();
        var coord1  = {lat : 37.235, lng : -115.811};
        var coord2  = {lat : coord1.lat + Math.random()%0.005, lng : coord1.lng - Math.random()%0.005};
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

    function removeRoute()
    {
        web.runJavaScript("removePath();\n");
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal
        Layout.minimumWidth: 1000
        Layout.minimumHeight: 500

        Rectangle {
            Layout.minimumWidth: 320
            color: "green"

            VideoMetaWidget {
                anchors.fill: parent
                mrl: "rtsp://192.168.10.218:1234";
                altText: "Video 1"
            }
        }

        Rectangle {
            Layout.minimumWidth: 320
            color: "yellow"

            VideoMetaWidget {
                anchors.fill: parent
                mrl: "rtsp://192.168.10.176:1234";
                altText: "Video 2"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 320

            ColumnLayout {
                spacing : 2
                anchors.fill: parent

                Rectangle {
                    anchors.top : parent.top
                    anchors.bottom: mapRowLayout.top
                    anchors.left: parent.left
                    anchors.right: parent.right

                    //Layout.fillHeight: true
                    //Layout.fillWidth: true
                    //Layout.alignment: Qt.AlignTop

                    WebEngineView {
                        id: web
                        anchors.fill: parent
                        url: "map.html"
                        //url: "democss.html"
                    }
                }

                RowLayout {
                    id : mapRowLayout
                    spacing : 2
                    Layout.alignment: Qt.AlignBottom

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
                        }
                    }
                    Button {
                        text : "draw route"
                        onClicked: {
                            drawRoute();
                        }
                    }
                    Button {
                        text : "remove object"
                        onClicked: {
                            removeObject();
                        }
                    }
                    Button {
                        text : "remove route"
                        onClicked: {
                            removeRoute();
                        }
                    }
                }
            }
        }
    }
}

