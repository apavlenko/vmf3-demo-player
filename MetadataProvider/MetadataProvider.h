#ifndef METADATAPROVIDER_H
#define METADATAPROVIDER_H

#include <vmf/vmf.hpp>

#include <QObject>
#include <QPointF>
#include <QQmlListProperty>

#include <atomic>
#include <mutex>
#include <thread>

class Location
{
    Q_GADGET

    Q_PROPERTY(double latitude READ latitude WRITE setLatitude)
    Q_PROPERTY(double longitude READ longitude WRITE setLongitude)
//    Q_PROPERTY(double altitude READ altitude WRITE setAltitude)
//    Q_PROPERTY(double accuracy READ accuracy WRITE setAccuracy)
//    Q_PROPERTY(double speed READ speed WRITE setSpeed)

public:
    double latitude() const { return m_latitude; }
    void setLatitude(double latitude) { m_latitude = latitude; }

    double longitude() const { return m_longitude; }
    void setLongitude(double longitude) { m_longitude = longitude; }

//    double altitude() const { return m_altitude; }
//    void setAltitude(double altitude) { m_altitude = altitude; }

//    double accuracy() const { return m_accuracy; }
//    void setAccuracy(double accuracy) { m_accuracy = accuracy; }

//    double speed() const { return m_speed; }
//    void setSpeed(double speed) { m_speed = speed; }

private:
    double m_latitude;
    double m_longitude;
//    double m_altitude;
//    double m_accuracy;
//    double m_speed;
};

Q_DECLARE_METATYPE(Location)

class MetadataProvider : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
//    Q_PROPERTY(QList<Location> locations READ locations NOTIFY locationsChanged)
//    Q_PROPERTY(QQmlListProperty<Location> locations READ locations NOTIFY locationsChanged)
//    Q_PROPERTY(QString locations READ locations NOTIFY locationsChanged)
    Q_PROPERTY(QPointF locations READ locations NOTIFY locationsChanged)
//    Q_PROPERTY(QList<QPointF> locations READ locations NOTIFY locationsChanged)

public:
    explicit MetadataProvider(QObject *parent = 0);
    ~MetadataProvider();

    QString address();
    void setAddress(const QString& address);

//    QList<Location> locations() const;
//    QQmlListProperty<Location> locations();
//    QString locations();
    QPointF locations() const;
//    QList<QPointF> locations() const;

signals:
    void addressChanged();
    void segmentAdded();
    void schemaAdded();
    void metadataAdded();
//    void locationsChanged(QQmlListProperty<Location> locations);
//    void locationsChanged(QString locations);
    void locationsChanged(QPointF locations);
//    void locationsChanged(QList<Location> locations);

public slots:
    void start();
    void stop();

private:
    QString getAddress() const;
    bool putAddress(const QString& address);
    int m_ip;
    int m_port;

    bool connect();
    void disconnect();
    void execute();

    void updateLocations();
    static double getFieldValue(std::shared_ptr<vmf::Metadata> md, const std::string& name);

    std::thread m_worker;
    std::atomic<bool> m_working;
    std::atomic<bool> m_exiting;
    int m_sock;

    vmf::MetadataStream m_ms;
//    QList<Location*> m_locations;
    std::vector<QPointF> m_locations;
//    QList<QPointF> m_locations;
    mutable std::mutex m_lock;

    class ConnectionLock;
};

#endif // METADATAPROVIDER_H
