FROM envoyproxy/envoy:v1.31.0
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget unzip tini && \
    rm -rf /var/lib/apt/lists/*

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

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
EXPOSE 8080

RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'xray run -c /etc/xray.json &' >> /entrypoint.sh && \
    echo 'exec envoy -c /etc/envoy/envoy.yaml --service-cluster proxy' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
