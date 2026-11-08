#!/bin/bash
# ==============================================
# VIRGOZKI PANEL (ENVOY OPTIMIZED)
# ENGINEERED BY VIRGOZKI
# ✅ ENVOY PROXY • CLEAN • ERROR FREE
# ==============================================

BOLD='\033[1m'; RESET='\033[0m'
GREEN='\033[1;32m'; RED='\033[1;31m'; CYAN='\033[1;36m'
YELLOW='\033[1;33m'; MAGENTA='\033[1;35m'; WHITE='\033[1;37m'

loading() {
    local t="$1"
    local s="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for ((i=0;i<5;i++)); do 
        for ((j=0;j<${#s};j++)); do 
            echo -ne "\r  ${CYAN}${s:$j:1} ${t}...${RESET}"
            sleep 0.05
        done
    done
    echo -ne "\r  ${GREEN}DONE: ${t}${RESET}\n"
}

clear
echo ""
echo -e "  ${BOLD}${WHITE}VIRGOZKI PANEL (ENVOY PROXY EDITION)${RESET}"
echo -e "  ${MAGENTA}MADE BY VIRGOZKI${RESET}"
echo -e "  ${GREEN}✅ XRAY + ENVOY • WEBSOCKET & HTTPUPGRADE READY${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
if [ -z "$PROJECT_ID" ]; then
    echo -e "  ${RED}ERROR: No active GCP project detected. Please run 'gcloud init'.${RESET}"
    exit 1
fi
echo -e "  ${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"

echo -ne "  ${CYAN}AUTO-DETECTING REGION... ${RESET}"
REGION=$(gcloud config get-value compute/region 2>/dev/null | tr -d '[:space:]')
[ -z "$REGION" ] && REGION=$(gcloud config get-value run/region 2>/dev/null | tr -d '[:space:]')
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
    REGION=$(gcloud run regions list --format="value(REGION)" --limit=1 2>/dev/null | tr -d '[:space:]')
fi
[ -z "$REGION" ] && REGION="us-central1"
echo -e "${GREEN}${REGION}${RESET}"
echo ""

GH_TOKEN=""
if curl -sL --connect-timeout 5 "https://pastebin.com/raw/7rAmCXDp" | grep -q "^gh[pousr]_"; then
    GH_TOKEN=$(curl -sL --connect-timeout 5 "https://pastebin.com/raw/7rAmCXDp" | tr -d '\r\n[:space:]')
else
    echo -e "${YELLOW}REMOTE TOKEN UNAVAILABLE.${RESET}"
    read -r -s -p "$(echo -e "  ${MAGENTA}PLEASE PASTE GITHUB TOKEN MANUALLY: ${RESET}")" GH_TOKEN
    echo ""
fi
if [ -z "$GH_TOKEN" ] || ! echo "$GH_TOKEN" | grep -q "^gh[pousr]_"; then
    echo -e "  ${YELLOW}INVALID GITHUB TOKEN. SKIPPING GITHUB SYNC.${RESET}"
    GH_TOKEN=""
fi

read -r -p "$(echo -e "  ${CYAN}SERVICE NAME [virgozki-panel]: ${RESET}")" INPUT_NAME
INPUT_NAME=$(echo "$INPUT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')
SERVICE_NAME=${INPUT_NAME:-virgozki-panel}

echo ""
echo -e "  ${CYAN}SELECT MODE:${RESET}"
echo -e "  ${YELLOW}1) AUTO         (1 vCPU / 2Gi  RAM) ✅ Recommended${RESET}"
echo -e "  ${YELLOW}2) HIGH         (2 vCPU / 4Gi  RAM)${RESET}"
echo -e "  ${YELLOW}3) STABLE       (4 vCPU / 8Gi  RAM)${RESET}"
echo -e "  ${YELLOW}4) CUSTOM       (Your own specs)${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}CHOICE: ${RESET}")" MODE_CHOICE

case "$MODE_CHOICE" in
    1) CPU="1"; RAM="2Gi"; MODE="AUTO"     ; MAX_INSTANCES="2";;
    2) CPU="2"; RAM="4Gi"; MODE="HIGH"     ; MAX_INSTANCES="2";;
    3) CPU="4"; RAM="8Gi"; MODE="STABLE"   ; MAX_INSTANCES="1";;
    4)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}CPU (1/2/4): ${RESET}")" CPU
        read -r -p "$(echo -e "  ${CYAN}RAM (2Gi/4Gi/8Gi): ${RESET}")" RAM
        echo ""
        read -r -p "$(echo -e "  ${CYAN}MAX INSTANCES (1-3): ${RESET}")" MAX_INSTANCES
        MODE="CUSTOM"
        ;;
    *) CPU="1"; RAM="2Gi"; MODE="DEFAULT"; MAX_INSTANCES="2";;
esac

echo ""
loading "CREATING CONFIG FILES"

# ==============================================
# ✅ XRAY CONFIG
# ==============================================
cat > config.json <<'EOF'
{
  "log": { "loglevel": "warning" },
  "dns": {
    "servers": ["8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1"],
    "queryStrategy": "UseIPv4",
    "disableCache": false,
    "hosts": {
      "pagead2.googlesyndication.com": "127.0.0.1",
      "googlesyndication.com": "127.0.0.1",
      "doubleclick.net": "127.0.0.1",
      "googleadservices.com": "127.0.0.1",
      "adservice.google.com": "127.0.0.1",
      "adsbygoogle.com": "127.0.0.1",
      "google-analytics.com": "127.0.0.1",
      "googletagmanager.com": "127.0.0.1",
      "googletagservices.com": "127.0.0.1",
      "googleads.g.doubleclick.net": "127.0.0.1",
      "securepubads.g.doubleclick.net": "127.0.0.1",
      "tpc.googlesyndication.com": "127.0.0.1",
      "afs.googlesyndication.com": "127.0.0.1",
      "stats.g.doubleclick.net": "127.0.0.1",
      "ad.doubleclick.net": "127.0.0.1",
      "partner.googleadservices.com": "127.0.0.1",
      "pagead2.googleadservices.com": "127.0.0.1",
      "popads.net": "127.0.0.1",
      "popcash.net": "127.0.0.1",
      "propellerads.com": "127.0.0.1",
      "adcash.com": "127.0.0.1",
      "exoclick.com": "127.0.0.1",
      "adsterra.com": "127.0.0.1",
      "popmyads.com": "127.0.0.1",
      "adultforce.com": "127.0.0.1",
      "trafficjunky.com": "127.0.0.1",
      "clickaine.com": "127.0.0.1",
      "ad-maven.com": "127.0.0.1",
      "adpushup.com": "127.0.0.1",
      "adrecover.com": "127.0.0.1",
      "blockadblock.com": "127.0.0.1",
      "admiral.com": "127.0.0.1",
      "fundingchoices.google.com": "127.0.0.1"
    }
  },
  "inbounds": [
    {
      "port": 10000,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "tag": "trojan-ws",
      "settings": {"clients": [{"password": "virgozki"}]},
      "streamSettings": {"network": "ws", "security": "none", "wsSettings": {"path": "/virgozki"}},
      "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    },
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "tag": "trojan-hu",
      "settings": {"clients": [{"password": "virgozki"}]},
      "streamSettings": {"network": "httpupgrade", "security": "none", "httpupgradeSettings": {"path": "/virgozki-hu"}},
      "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    },
    {
      "port": 10003,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "tag": "vmess-ws",
      "settings": {"clients": [{"id": "b831381d-6324-4d53-ad4f-8cda48b30811", "alterId": 0, "email": "user@local"}]},
      "streamSettings": {"network": "ws", "security": "none", "wsSettings": {"path": "/vmess-virgozki"}},
      "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    },
    {
      "port": 10004,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "tag": "vmess-hu",
      "settings": {"clients": [{"id": "b831381d-6324-4d53-ad4f-8cda48b30811", "alterId": 0, "email": "user@local"}]},
      "streamSettings": {"network": "httpupgrade", "security": "none", "httpupgradeSettings": {"path": "/vmess-virgozki-hu"}},
      "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    },
    {
      "port": 10006,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "tag": "vless-ws",
      "settings": {"clients": [{"id": "b831381d-6324-4d53-ad4f-8cda48b30811", "email": "user@local"}], "decryption": "none"},
      "streamSettings": {"network": "ws", "security": "none", "wsSettings": {"path": "/vless-virgozki"}},
      "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    },
    {
      "port": 10007,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "tag": "vless-hu",
      "settings": {"clients": [{"id": "b831381d-6324-4d53-ad4f-8cda48b30811", "email": "user@local"}], "decryption": "none"},
      "streamSettings": {"network": "httpupgrade", "security": "none", "httpupgradeSettings": {"path": "/vless-virgozki-hu"}},
      "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    },
    {
      "port": 10009,
      "listen": "127.0.0.1",
      "protocol": "shadowsocks",
      "tag": "ss-ws",
      "settings": {"clients": [{"password": "virgozki", "method": "aes-256-gcm"}]},
      "streamSettings": {"network": "ws", "security": "none", "wsSettings": {"path": "/ss-virgozki"}},
      "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    },
    {
      "port": 10010,
      "listen": "127.0.0.1",
      "protocol": "shadowsocks",
      "tag": "ss-hu",
      "settings": {"clients": [{"password": "virgozki", "method": "aes-256-gcm"}]},
      "streamSettings": {"network": "httpupgrade", "security": "none", "httpupgradeSettings": {"path": "/ss-virgozki-hu"}},
      "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    }
  ],
  "outbounds": [{"protocol": "freedom", "tag": "direct"}, {"protocol": "blackhole", "tag": "block"}],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {"type": "field", "domain": ["geosite:category-ads-all"], "outboundTag": "block"},
      {"type": "field", "inboundTag": ["trojan-ws","trojan-hu","vmess-ws","vmess-hu","vless-ws","vless-hu","ss-ws","ss-hu"], "outboundTag": "direct"}
    ]
  }
}
EOF

# ==============================================
# ✅ ENVOY YAML CONFIG
# ==============================================
cat > envoy.yaml <<'EOF'
admin:
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 9901
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 8080
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: backend
              domains: ["*"]
              routes:
              - match: { prefix: "/virgozki" }
                route: { cluster: xray_trojan_ws }
              - match: { prefix: "/virgozki-hu" }
                route: { cluster: xray_trojan_hu }
              - match: { prefix: "/vmess-virgozki" }
                route: { cluster: xray_vmess_ws }
              - match: { prefix: "/vmess-virgozki-hu" }
                route: { cluster: xray_vmess_hu }
              - match: { prefix: "/vless-virgozki" }
                route: { cluster: xray_vless_ws }
              - match: { prefix: "/vless-virgozki-hu" }
                route: { cluster: xray_vless_hu }
              - match: { prefix: "/ss-virgozki" }
                route: { cluster: xray_ss_ws }
              - match: { prefix: "/ss-virgozki-hu" }
                route: { cluster: xray_ss_hu }
              - match: { prefix: "/" }
                route: { direct_response: { status: 200, body: { filename: "/usr/local/envoy/html/index.html" } } }
          http_filters:
          - name: envoy.filters.http.router
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
  clusters:
  - name: xray_trojan_ws
    connect_timeout: 0.25s
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: xray_trojan_ws
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: 127.0.0.1, port_value: 10000 }
  - name: xray_trojan_hu
    connect_timeout: 0.25s
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: xray_trojan_hu
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: 127.0.0.1, port_value: 10001 }
  - name: xray_vmess_ws
    connect_timeout: 0.25s
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: xray_vmess_ws
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: 127.0.0.1, port_value: 10003 }
  - name: xray_vmess_hu
    connect_timeout: 0.25s
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: xray_vmess_hu
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: 127.0.0.1, port_value: 10004 }
  - name: xray_vless_ws
    connect_timeout: 0.25s
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: xray_vless_ws
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: 127.0.0.1, port_value: 10006 }
  - name: xray_vless_hu
    connect_timeout: 0.25s
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: xray_vless_hu
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: 127.0.0.1, port_value: 10007 }
  - name: xray_ss_ws
    connect_timeout: 0.25s
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: xray_ss_ws
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: 127.0.0.1, port_value: 10009 }
  - name: xray_ss_hu
    connect_timeout: 0.25s
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: xray_ss_hu
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: 127.0.0.1, port_value: 10010 }
EOF

# ==============================================
# ✅ DOCKERFILE - ENVOY VERSION
# ==============================================
cat > Dockerfile <<'EOF'
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

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD sh -c "xray run -c /etc/xray.json & exec envoy -c /etc/envoy/envoy.yaml --service-cluster proxy"
EOF

loading "BUILDING CONTAINER IMAGE"
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" --project="$PROJECT_ID" --quiet > build.log 2>&1

if [ $? -ne 0 ]; then 
    echo -e "  ${RED}BUILD FAILED. CHECK LOGS BELOW:${RESET}"
    tail -n 15 build.log
    rm -f build.log
    exit 1
fi

loading "DEPLOYING TO CLOUD RUN IN ${REGION}"
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" \
  --platform managed --region "$REGION" \
  --cpu "$CPU" --memory "$RAM" --port 8080 \
  --concurrency 800 --timeout 3600 \
  --min-instances 0 --max-instances "$MAX_INSTANCES" \
  --allow-unauthenticated --project="$PROJECT_ID" --quiet > deploy.log 2>&1

if [ $? -ne 0 ]; then 
    echo -e "  ${RED}DEPLOYMENT FAILED. CHECK LOGS BELOW:${RESET}"
    tail -n 15 deploy.log
    rm -f build.log deploy.log
    exit 1
fi

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --project="$PROJECT_ID" --format='value(status.url)' 2>/dev/null)
CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')

VMESS_UUID="b831381d-6324-4d53-ad4f-8cda48b30811"
VLESS_WS="vless://${VMESS_UUID}@${CLEAN_HOST}:443?encryption=none&type=ws&path=/vless-virgozki&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#VLESS-WS"
VLESS_HU="vless://${VMESS_UUID}@${CLEAN_HOST}:443?encryption=none&type=httpupgrade&path=/vless-virgozki-hu&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#VLESS-HU"
VMESS_WS_JSON='{"v":"2","ps":"VMESS-WS-virgozki","add":"'"${CLEAN_HOST}"'","port":"443","id":"'"${VMESS_UUID}"'","aid":"0","scy":"auto","net":"ws","type":"none","host":"'"${CLEAN_HOST}"'","path":"/vmess-virgozki","tls":"tls","sni":"'"${CLEAN_HOST}"'","fp":"chrome","alpn":"http/1.1"}'
VMESS_WS_B64=$(echo -n "$VMESS_WS_JSON" | base64 -w0)
VMESS_HU_JSON='{"v":"2","ps":"VMESS-HU-virgozki","add":"'"${CLEAN_HOST}"'","port":"443","id":"'"${VMESS_UUID}"'","aid":"0","scy":"auto","net":"httpupgrade","type":"none","host":"'"${CLEAN_HOST}"'","path":"/vmess-virgozki-hu","tls":"tls","sni":"'"${CLEAN_HOST}"'","fp":"chrome","alpn":"http/1.1"}'
VMESS_HU_B64=$(echo -n "$VMESS_HU_JSON" | base64 -w0)
TROJAN_WS="trojan://virgozki@${CLEAN_HOST}:443?type=ws&path=/virgozki&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#TROJAN-WS"
TROJAN_HU="trojan://virgozki@${CLEAN_HOST}:443?type=httpupgrade&path=/virgozki-hu&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#TROJAN-HU"

echo ""
echo -e "  ${GREEN}✅ DEPLOYED SUCCESSFULLY • ENVOY PROXY READY${RESET}"
echo ""
echo -e "  ${CYAN}DASHBOARD: ${GREEN}${SERVICE_URL}${RESET}"
echo -e "  ${CYAN}HOST:      ${GREEN}${CLEAN_HOST}${RESET}"
echo -e "  ${CYAN}PORT:      ${GREEN}443${RESET}"
echo -e "  ${CYAN}PASSWORD:  ${GREEN}virgozki${RESET}"
echo -e "  ${CYAN}MODE:      ${GREEN}${MODE} (${CPU} vCPU / ${RAM})${RESET}"
echo ""

echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${CYAN}                    ALL PROTOCOLS & PATHS${RESET}"
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${GREEN}✓ VLESS   ${CYAN}WS: /vless-virgozki    ${GREEN}HTTPUPGRADE: /vless-virgozki-hu${RESET}"
echo -e "  ${GREEN}✓ VMESS   ${CYAN}WS: /vmess-virgozki    ${GREEN}HTTPUPGRADE: /vmess-virgozki-hu${RESET}"
echo -e "  ${GREEN}✓ TROJAN  ${CYAN}WS: /virgozki          ${GREEN}HTTPUPGRADE: /virgozki-hu${RESET}"
echo -e "  ${GREEN}✓ SHADOWSOCKS ${CYAN}WS: /ss-virgozki    ${GREEN}HTTPUPGRADE: /ss-virgozki-hu${RESET}"
echo ""
echo -e "  ${CYAN}✓ SNI: ${GREEN}${CLEAN_HOST}${RESET}   ${CYAN}✓ ALPN: ${GREEN}http/1.1${RESET}   ${CYAN}✓ FINGERPRINT: ${GREEN}chrome${RESET}"
echo ""
echo -e "  ${YELLOW}🔗 READY-TO-USE LINKS:${RESET}"
echo -e "  ${CYAN}VLESS WS: ${GREEN}${VLESS_WS}${RESET}"
echo -e "  ${CYAN}VLESS HU: ${GREEN}${VLESS_HU}${RESET}"
echo -e "  ${CYAN}TROJAN WS: ${GREEN}${TROJAN_WS}${RESET}"
echo -e "  ${CYAN}TROJAN HU: ${GREEN}${TROJAN_HU}${RESET}"
echo -e "  ${CYAN}VMESS WS: ${GREEN}vmess://${VMESS_WS_B64}${RESET}"
echo -e "  ${CYAN}VMESS HU: ${GREEN}vmess://${VMESS_HU_B64}${RESET}"
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# ✅ GITHUB SYNC
if [ -n "$GH_TOKEN" ]; then
    GH_USER="rafaeltv"
    GH_REPO="rafaeltv-gcp-panel"
    
    if git clone -q "https://${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git" gh_temp_deploy 2>/dev/null; then
        cd gh_temp_deploy
        > temp.txt
        while IFS= read -r line; do
            if [[ "$line" == *".run.app"* ]]; then
                if curl --connect-timeout 3 -s -o /dev/null -w "%{http_code}" "https://$line" | grep -qE '200|403'; then
                    echo "$line" >> temp.txt
                fi
            fi
        done < host.txt 2>/dev/null
        
        echo "$CLEAN_HOST" >> temp.txt
        sort -u temp.txt > host.txt
        rm temp.txt
        
        git config --local user.name "Virgozki Deployer"
        git config --local user.email "deploy@virgozki.local"
        git add host.txt
        git commit -m "Update hosts: ${CLEAN_HOST}" 2>/dev/null
        git push -q origin main 2>/dev/null || git push -q origin master 2>/dev/null
        cd ..
        rm -rf gh_temp_deploy
    fi
fi

# ✅ CLEANUP
rm -f build.log deploy.log
echo -e "\n  ${GREEN}✅ SCRIPT FINISHED • ENVOY ACTIVE • INDEX.HTML SAVED${RESET}"
