FROM envoyproxy/envoy:v1.31.0-alpine

RUN apk add --no-cache ca-certificates wget unzip tini

RUN wget --timeout=120 -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/v24.10.31/Xray-linux-64.zip && \
    unzip -q /tmp/xray.zip -d /tmp/xray/ && \
    mv /tmp/xray/xray /usr/local/bin/ && \
    mkdir -p /usr/local/share/xray/ && \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/ && \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf /tmp/xray /tmp/xray.zip

COPY config.json /etc/xray.json
COPY envoy.yaml /etc/envoy/envoy.yaml
COPY index.html /usr/local/envoy/html/index.html
COPY entrypoint.sh /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
EXPOSE 8080

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
