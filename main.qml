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

    property var paths : [ [], [] ]

    function initializeMap(coord)
    {
        var script = "map.setCenter(new google.maps.LatLng(%1,%2));\n";
        web.runJavaScript(script.arg(coord.lat).arg(coord.lng));
    }

    function getRotation(fromPt, toPt)
    {
        var dx = toPt.x - fromPt.x
        var dy = toPt.y - fromPt.y

        if (dx == 0 && dy == 0)
            return 0;
        else if (dx == 0)
            return dy > 0 ? 90 : 270;

        var rotate = Math.atan2(dy, dx)*180/Math.PI;

        return rotate >= 0 ? rotate : rotate + 360;
    }

    function drawObject(nObject)
    {
        hideObject(nObject)
        var script = "drawObject(%1, %2, %3, %4, %5);\n";
        var len = paths[nObject].length
        if(len > 0)
        {
            var toPt = paths[nObject][len-1]
            var fromPt = toPt;
            if(len >= 2)
                fromPt = paths[nObject][len-2]

            var lat = toPt.x
            var lng = toPt.y
            var rotate = getRotation(fromPt, toPt)
            var colorStr = ""
            if(nObject === 0)
                colorStr = "'red'"
            else
                colorStr = "'blue'"
            web.runJavaScript(script.arg(lat).arg(lng).arg(rotate).arg(colorStr).arg(nObject));

            console.log(script.arg(lat).arg(lng).arg(rotate).arg(colorStr).arg(nObject))
        }
    }

    function hideObject(nObject)
    {
        web.runJavaScript("removeObject(%1);\n".arg(nObject));
    }

    function drawRoute(nPath)
    {
        web.runJavaScript("removePath(%1);\n".arg(nPath))
        var len = paths[nPath].length
        if(len >= 2)
        {
            var script = "";
            script += "myCoordinates = [\n";
            for(var i = 0; i < len; i++)
            {
                var lat = paths[nPath][i].x
                var lng = paths[nPath][i].y
                script += "new google.maps.LatLng(%1 , %2),\n".arg(lat).arg(lng);
            }
            script += "];\n";
            var colorStr = ""
            if(nPath === 0)
                colorStr = "#FF0000"
            else
                colorStr = "#0000FF"
            script += "myColor = '" + colorStr + "';\n";
            script += "nPath = '" + nPath + "';\n";
            script += "drawRoute(myCoordinates, myColor, nPath);\n";
            web.runJavaScript(script);
        }
    }

    function removeRoute(nPath)
    {
        paths[nPath] = []
        web.runJavaScript("removePath(%1);\n".arg(nPath))
    }

    function addToPath(nPath, location)
    {
        paths[nPath].push(location);
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal
        Layout.minimumWidth: 1000
        Layout.minimumHeight: 500

        Rectangle {
            Layout.minimumWidth: 320
            color: "red"

            VideoMetaWidget {
                anchors.fill: parent
                anchors.margins: 5
                //mrl: "rtsp://192.168.10.218:1234";
                ip: "192.168.10.218"
                onLocationChanged: {
                    paths[0].push(newPt);
                    drawRoute(0)
                    drawObject(0)
                }
                onStarted: { }
                onStopped: removeRoute(0)
            }
        }

        Rectangle {
            Layout.minimumWidth: 320
            color: "blue"

            VideoMetaWidget {
                anchors.fill: parent
                anchors.margins: 5
                //mrl: "rtsp://192.168.10.176:1234";
                ip: "192.168.10.176"
                onLocationChanged: {
                    paths[1].push(newPt);
                    drawRoute(1)
                    drawObject(1)
                }
                onStarted: { }
                onStopped: removeRoute(1)
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
                    }
                }

                RowLayout {
                    id : mapRowLayout
                    spacing : 2
                    Layout.alignment: Qt.AlignBottom

                    Button {
                        text : "remove routes"
                        onClicked: {
                            removeRoute(0);
                            removeRoute(1);
                        }
                    }
                    //temporary buttons, will be removed in future
                    Button {
                        text: "go route 0"
                        onClicked: {
                            paths[0].push({x:   37.387635 + Math.random()%0.01,
                                           y: -121.963427 + Math.random()%0.01});
                            drawRoute(0)
                            drawObject(0)
                        }
                    }
                    Button {
                        text: "go route 1"
                        onClicked: {
                            paths[1].push({x:   37.387635 + Math.random()%0.01,
                                           y: -121.963427 + Math.random()%0.01});
                            drawRoute(1)
                            drawObject(1)
                        }
                    }
                }
            }
        }
    }
}

