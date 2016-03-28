#include <QApplication>
#include <QQmlApplicationEngine>

#include <QmlVlc.h>
#include <QmlVlc/QmlVlcConfig.h>

int main(int argc, char *argv[])
{
    RegisterQmlVlc();
    QmlVlcConfig& config = QmlVlcConfig::instance();
    //config.enableDebug( true );

    QApplication app(argc, argv);

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    return app.exec();
}

