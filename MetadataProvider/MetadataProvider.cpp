#include "MetadataProvider.h"

#if defined(WIN32)
# include <winsock2.h>
# include <stdio.h>
# include <windows.h>
//# pragma comment(lib, "ws2_32.lib")
#else //if defined(__linux__)
# include <arpa/inet.h>
# include <netinet/in.h>
# include <sys/socket.h>
# include <unistd.h>
#endif

#include <stdlib.h>

#include <iostream>
#include <sstream>
#include <stdexcept>

//#define USE_NATIVE_ENDIAN
#define USE_SIZES_ON_HANDSHAKE

#if defined(USE_NATIVE_ENDIAN)
# define zzntohl(_sz) (_sz)
#else
# define zzntohl(_sz) ntohl(_sz)
#endif

static ssize_t sendMessage(int fd, const char* buf, size_t msgSize)
{
    return ::send(fd, (void*) buf, msgSize, 0);
}

static ssize_t receiveMessage(int fd, char* buf, size_t bufSize, bool doWait = false)
{
    const int  flags = (doWait ? MSG_WAITALL : 0);
    uint32_t sz = 0;
    ssize_t size = ::recv(fd, (void*) &sz, 4, flags);
    if ((size == 4) && ((sz = zzntohl(sz)) < bufSize))
    {
        size = ::recv(fd, (void*) buf, sz, flags);
        if (size == sz)
        {
            buf[sz] = 0;
            return size;
        }
    }
    return (ssize_t)-1;
}

static ssize_t receiveMessageRaw(int fd, char* buf, size_t msgSize)
{
#if defined(USE_SIZES_ON_HANDSHAKE)
    return receiveMessage(fd, buf, msgSize, true);
#else
    return ::recv(fd, (void*) buf, msgSize, true);
#endif
}

class MetadataProvider::ConnectionLock
{
public:
    ConnectionLock(MetadataProvider* mp)
        : m_this(mp)
        , m_success(false)
        { m_success = m_this->connect(); }
    ~ConnectionLock()
        { m_this->disconnect(); }
    bool isSuccessful() const
        { return m_success; }
private:
    MetadataProvider* m_this;
    bool m_success;
};

MetadataProvider::MetadataProvider(QObject *parent)
    : QObject(parent)
    , m_ip(0)
    , m_port(0)
    , m_working(false)
    , m_exiting(false)
    , m_sock(-1)
{
    vmf::Log::setVerbosityLevel(vmf::LogLevel::LOG_ERROR);
}

MetadataProvider::~MetadataProvider()
{
    stop();
}

QString MetadataProvider::address()
{
    return getAddress();
}

void MetadataProvider::setAddress(const QString& address)
{
    if (putAddress(address))
        emit addressChanged();
}

QString MetadataProvider::getAddress() const
{
    struct in_addr in;
    in.s_addr = m_ip;
    QString ipStr(inet_ntoa(in));

    std::stringstream ss;
    ss << ntohs(m_port);
    QString portStr(ss.str().c_str());

    return ipStr + ":" + portStr;
}

bool MetadataProvider::putAddress(const QString& address)
{
    QStringList list = address.split(":");
    if (list.size() == 2)
    {
        const QString& ipStr = list.first();
        const QString& portStr = list.last();

        struct in_addr in;
        if (inet_aton(ipStr.toStdString().c_str(), &in))
        {
            bool ok = false;
            int port = portStr.toInt(&ok, 10);
            if (ok)
            {
                port = htons(port);
                if (((int)in.s_addr != m_ip) || (port != m_port))
                {
                    m_ip = in.s_addr;
                    m_port = port;
                    return true;
                }
                return false;
            }
        }
    }
    throw std::runtime_error("syntax error in ip:port address string");
}

void MetadataProvider::start()
{
    std::cerr << "*** MetadataProvider::start()" << std::endl;
    if (!m_working)
    {
        std::cerr << "*** MetadataProvider::start() : start worker" << std::endl;
        m_worker = std::thread(&MetadataProvider::execute, this);
    }
}

void MetadataProvider::stop()
{
    std::cerr << "*** MetadataProvider::stop()" << std::endl;
    if (m_working)
    {
        std::cerr << "*** MetadataProvider::stop() : stop worker" << std::endl;
        m_exiting = true;
        m_worker.join();
        m_working = false;
        disconnect();
    }
}

bool MetadataProvider::connect()
{
    const int domain = AF_INET;
    const int type = SOCK_STREAM;
    const int protocol = 0;

    m_sock = ::socket(domain, type, protocol);
    if (m_sock >= 0)
    {
        struct sockaddr_in server;

        memset(&server, 0, sizeof(server));
        server.sin_family = domain;
        server.sin_addr.s_addr = m_ip; //inet_addr(ip.toStdString().c_str());
        server.sin_port = m_port; //htons(port);

        int status = ::connect(m_sock, (const struct sockaddr*) &server, sizeof(struct sockaddr));
        if (status >= 0)
        {
            char buf[40000];

            // VMF/VMF
            ssize_t size = receiveMessageRaw(m_sock, buf, sizeof(buf));
            if ((size == 3) && (buf[0] == 'V') && (buf[1] == 'M') && (buf[2] == 'F'))
            {
                size = sendMessage(m_sock, buf, 3);

                // XML/OK
                size = receiveMessageRaw(m_sock, buf, sizeof(buf));
                if ((size == 3) && (buf[0] == 'X') && (buf[1] == 'M') && (buf[2] == 'L'))
                {
                    buf[0] = 'O';
                    buf[1] = 'K';
                    size = sendMessage(m_sock, buf, 2);

                    return true;
                }
            }
        }

        ::close(m_sock);
        m_sock = -1;
    }
    return false;
}

void MetadataProvider::disconnect()
{
    if (m_sock >= 0)
    {
        char buf[4];

        buf[0] = 'B';
        buf[1] = 'Y';
        buf[2] = 'E';
        sendMessage(m_sock, buf, 3);

        ::close(m_sock);
        m_sock = -1;
    }
}

void MetadataProvider::execute()
{
    std::cerr << "*** MetadataProvider::execute()" << std::endl;
    try
    {
        m_working = true;

        std::cerr << "*** MetadataProvider::execute() : trying to connect" << std::endl;
        ConnectionLock connection(this);
        std::cerr << "*** MetadataProvider::execute() : connect : " << (connection.isSuccessful() ? "SUCC" : "FAIL") << std::endl;
        if (connection.isSuccessful())
        {
            vmf::FormatXML xml;
//            std::vector<std::shared_ptr<vmf::MetadataInternal>> metadata;
            std::vector<vmf::MetadataInternal> metadata;
            std::vector<std::shared_ptr<vmf::MetadataSchema>> schemas;
            std::vector<std::shared_ptr<vmf::MetadataStream::VideoSegment>> segments;
            vmf::Format::AttribMap attribs;
            vmf::Format::ParseCounters c;

            char buf[10240];

            if (!m_exiting)
            {
                ssize_t size = receiveMessage(m_sock, buf, sizeof(buf), true);
                if (size > 0)
                {
                    c = xml.parse(std::string(buf), metadata, schemas, segments, attribs);
                    if (!(c.segments > 0))
                        throw std::runtime_error("expected video segment(s) not sent by server");
                    for (auto segment : segments)
                    {
                        std::unique_lock< std::mutex > lock( m_lock );
                        m_ms.addVideoSegment(segment);
                    }
                    emit segmentAdded();
                }
            }

            if (!m_exiting)
            {
                ssize_t size = receiveMessage(m_sock, buf, sizeof(buf), true);
                if (size > 0)
                {
                    c = xml.parse(std::string(buf), metadata, schemas, segments, attribs);
                    if (!(c.schemas > 0))
                        throw std::runtime_error("expected video schema(s) not sent by server");
                    for (auto schema : schemas)
                    {
                        std::unique_lock< std::mutex > lock( m_lock );
                        m_ms.addSchema(schema);
                    }
                    emit schemaAdded();
                }
            }

            while (!m_exiting)
            {
                ssize_t size = receiveMessage(m_sock, buf, sizeof(buf), true);
                if (size > 0)
                {
                    metadata.clear();
                    c = xml.parse(std::string(buf), metadata, schemas, segments, attribs);
                    if (!(c.metadata > 0))
                        throw std::runtime_error("expected metadata not sent by server");
                    int num = 0;
                    for (auto md : metadata)
                    {
                        std::unique_lock< std::mutex > lock( m_lock );
                        m_ms.add(md);
                        updateLocations();
                        ++num;
                    }
                    std::cerr << "*** MetadataProvider::execute() : points per message = " << num << std::endl;
                    emit metadataAdded();
//                    emit locationsChanged(m_locations);
//                    emit locationsChanged(QQmlListProperty<Location>(this, m_locations));
//                    emit locationsChanged(QPointF(135.7, -97.13));
                }
            }
        }
    }
    catch (const std::exception& e)
    {
        std::cerr << "[MetadataProvider] EXCEPTION: " << e.what() << std::endl;
    }
    std::cerr << "*** MetadataProvider::execute() ***" << std::endl;
}

//QList<Location> MetadataProvider::locations() const
//QQmlListProperty<Location> MetadataProvider::locations()
//QString MetadataProvider::locations()
QPointF MetadataProvider::locations() const
//QList<QPointF> MetadataProvider::locations() const
{
//    std::unique_lock< std::mutex > lock( m_lock );
//    return QQmlListProperty<Location>(this, m_locations);
//    return QString(">>= location(s)");
    return QPointF(-135.7, 97.13);
}

double MetadataProvider::getFieldValue(std::shared_ptr<vmf::Metadata> md, const std::string& name)
{
    try
    {
        vmf::Variant fv = md->getFieldValue(name);
        if (fv.getType() == vmf::FieldValue::type_real)
            return fv.get_real();
        else
            return 0;
    }
    catch (const std::exception& e)
    {
        return 0;
    }
}

void MetadataProvider::updateLocations()
{
    vmf::MetadataSet ms = m_ms.getAll();

    for(int i = (int)m_locations.size(); i < (int)ms.size(); ++i)
    {
        std::shared_ptr<vmf::Metadata> md = ms[i];

//        Location* loc = new Location;
        QPointF loc;

//        loc->setLatitude(getFieldValue(md, "latitude"));
//        loc->setLongitude(getFieldValue(md, "longitude"));
//        loc.setAltitude(getFieldValue(md, "altitude"));
//        loc.setAccuracy(getFieldValue(md, "accuracy"));
//        loc.setSpeed(getFieldValue(md, "speed"));

        loc.setX(getFieldValue(md, "latitude"));
        loc.setY(getFieldValue(md, "longitude"));

//        m_locations.push_back(loc);
        m_locations.push_back(loc);
        emit locationsChanged(loc);
    }
}

