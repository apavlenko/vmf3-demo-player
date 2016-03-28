TEMPLATE = app

QT += qml quick widgets

include(3dparty/QmlVlc/QmlVlc.pri)
INCLUDEPATH += 3dparty

SOURCES += main.cpp

RESOURCES += qml.qrc

CONFIG += c++11

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

macx {
    LIBS += -L/Applications/VLC.app/Contents/MacOS/lib
}
