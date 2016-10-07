FROM alpine:3.4

ENV KAPACITOR_VERSION 1.0.2
RUN apk add --no-cache --virtual .build-deps wget gnupg tar ca-certificates && \
    update-ca-certificates && \
    gpg --keyserver hkp://ha.pool.sks-keyservers.net \
        --recv-keys 05CE15085FC09D18E99EFB22684A14CF2582E0C5 && \
    wget -q https://dl.influxdata.com/kapacitor/releases/kapacitor-${KAPACITOR_VERSION}-static_linux_amd64.tar.gz.asc && \
    wget -q https://dl.influxdata.com/kapacitor/releases/kapacitor-${KAPACITOR_VERSION}-static_linux_amd64.tar.gz && \
    gpg --batch --verify kapacitor-${KAPACITOR_VERSION}-static_linux_amd64.tar.gz.asc kapacitor-${KAPACITOR_VERSION}-static_linux_amd64.tar.gz && \
    mkdir -p /usr/src && \
    tar -C /usr/src -xzf kapacitor-${KAPACITOR_VERSION}-static_linux_amd64.tar.gz && \
    rm -f /usr/src/kapacitor-*/kapacitor.conf && \
    chmod +x /usr/src/kapacitor-*/* && \
    cp -a /usr/src/kapacitor-*/* /usr/bin/ && \
    rm -rf *.tar.gz* /usr/src /root/.gnupg && \
    apk del .build-deps

ENV DOCKERIZE_VERSION 0.2.0
RUN \
    apk add --no-cache curl && \
    mkdir -p /usr/local/bin/ &&\
    curl -SL https://github.com/jwilder/dockerize/releases/download/v${DOCKERIZE_VERSION}/dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz \
    | tar xzC /usr/local/bin

RUN mkdir -p /etc/kapacitor
COPY kapacitor.tmpl /etc/kapacitor

EXPOSE 9092
VOLUME /var/lib/kapacitor

ENV KAPACITOR_HOSTNAME kapacitor

ENV INFLUXDB_HOST influxdb
ENV INFLUXDB_USER metrics
ENV INFLUXDB_PASSWORD metrics

ENV INFLUXDB_SUBSCRIPTION_ENABLED false
ENV INFLUXDB_SUBSCRIPTION_DB metrics
ENV INFLUXDB_SUBSCRIPTION_DB_RP default

ENV ALERTA_ENABLED true
ENV ALERTA_API_URL http://alerta-api:8000
ENV ALERTA_TOKEN ""

CMD dockerize \
    -template /etc/kapacitor/kapacitor.tmpl:/etc/kapacitor/kapacitor.conf \
    kapacitord -config /etc/kapacitor/kapacitor.conf
