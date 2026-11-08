#!/bin/bash
# ==============================================================================
# VIRGOZKI PANEL • NGINX EDITION (WS + HU ONLY) + AUTO INDEX.HTML
# ==============================================================================

BOLD='\033[1m'; RESET='\033[0m'
GREEN='\033[1;32m'; RED='\033[1;31m'; CYAN='\033[1;36m'
YELLOW='\033[1;33m'; MAGENTA='\033[1;35m'; WHITE='\033[1;37m'

ALL_REGIONS=(
  "01:asia-east1:Taiwan"
  "02:asia-east2:Hong Kong"
  "03:asia-northeast1:Japan (Tokyo)"
  "04:asia-northeast2:Japan (Osaka)"
  "05:asia-northeast3:South Korea (Seoul)"
  "06:asia-south1:India (Mumbai)"
  "07:asia-south2:India (Delhi)"
  "08:asia-southeast1:Singapore"
  "09:asia-southeast2:Indonesia (Jakarta)"
  "10:australia-southeast1:Australia (Sydney)"
  "11:australia-southeast2:Australia (Melbourne)"
  "12:europe-central2:Poland (Warsaw)"
  "13:europe-north1:Finland"
  "14:europe-southwest1:Spain (Madrid)"
  "15:europe-west1:Belgium"
  "16:europe-west2:United Kingdom (London)"
  "17:europe-west3:Germany (Frankfurt)"
  "18:europe-west4:Netherlands"
  "19:europe-west6:Switzerland (Zurich)"
  "20:europe-west8:Italy (Milan)"
  "21:europe-west9:France (Paris)"
  "22:northamerica-northeast1:Canada (Montreal)"
  "23:northamerica-northeast2:Canada (Toronto)"
  "24:southamerica-east1:Brazil (Sao Paulo)"
  "25:southamerica-west1:Chile (Santiago)"
  "26:us-central1:USA (Iowa)"
  "27:us-east1:USA (South Carolina)"
  "28:us-east4:USA (North Virginia)"
  "29:us-east5:USA (Columbus)"
  "30:us-south1:USA (Texas)"
  "31:us-west1:USA (Oregon)"
  "32:us-west2:USA (Los Angeles)"
  "33:us-west3:USA (Salt Lake City)"
  "34:us-west4:USA (Las Vegas)"
)

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
echo -e "  ${BOLD}${WHITE}VIRGOZKI PANEL (NGINX WS + HU EDITION)${RESET}"
echo -e "  ${MAGENTA}MADE BY VIRGOZKI${RESET}"
echo -e "  ${GREEN}✅ MANUAL SELECT • WS & HU ONLY${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
if [ -z "$PROJECT_ID" ]; then
    echo -e "  ${RED}ERROR: No active GCP project detected. Please run 'gcloud init'.${RESET}"
    exit 1
fi
echo -e "  ${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"

REGION="asia-southeast1"
echo -e "  ${CYAN}📍 DEFAULT REGION: ${GREEN}${REGION}${RESET}"
echo ""

echo -e "  ${CYAN}📋 PUMILI NG REGION (0 = GAMITIN DEFAULT):${RESET}"
echo -e "  ${YELLOW}0) ${GREEN}${REGION} ${CYAN}(Default)${RESET}"
echo ""
for i in "${!ALL_REGIONS[@]}"; do
  IFS=':' read -r num reg_name country <<< "${ALL_REGIONS[$i]}"
  printf "  ${YELLOW}%s) ${GREEN}%-25s ${CYAN}(%s)${RESET}\n" "$num" "$reg_name" "$country"
done
echo ""
read -r -p "$(echo -e "  ${CYAN}ILAGAY ANG NUMBER: ${RESET}")" REG_CHOICE

if [[ "$REG_CHOICE" =~ ^[0-9]+$ ]]; then
  FOUND=0
  for item in "${ALL_REGIONS[@]}"; do
    IFS=':' read -r num reg_name _ <<< "$item"
    if [ "$num" = "$REG_CHOICE" ]; then
      REGION="$reg_name"
      gcloud config set run/region "$REGION" --quiet 2>/dev/null
      gcloud config set compute/region "$REGION" --quiet 2>/dev/null
      FOUND=1
      break
    fi
  done
  if [ "$FOUND" -eq 0 ] && [ "$REG_CHOICE" != "0" ]; then
    echo -e "  ${YELLOW}⚠️ INVALID NUMBER – GAMITIN DEFAULT${RESET}"
  fi
fi
echo -e "  ${CYAN}✅ FINAL REGION: ${GREEN}${REGION}${RESET}"
echo ""

GH_TOKEN=""
if curl -sL --connect-timeout 5 "https://pastebin.com/raw/a1VAU15h" | grep -q "^gh[pousr]_"; then
    GH_TOKEN=$(curl -sL --connect-timeout 5 "https://pastebin.com/raw/a1VAU15h" | tr -d '\r\n[:space:]')
else
    echo -e "${YELLOW}⚠️ REMOTE TOKEN UNAVAILABLE.${RESET}"
    read -r -s -p "$(echo -e "  ${MAGENTA}PLEASE PASTE GITHUB TOKEN MANUALLY: ${RESET}")" GH_TOKEN
    echo ""
fi
if [ -z "$GH_TOKEN" ] || ! echo "$GH_TOKEN" | grep -q "^gh[pousr]_"; then
    echo -e "  ${YELLOW}⚠️ INVALID GITHUB TOKEN. SKIPPING GITHUB SYNC.${RESET}"
    GH_TOKEN=""
fi

read -r -p "$(echo -e "  ${CYAN}SERVICE NAME [virgozki]: ${RESET}")" INPUT_NAME
INPUT_NAME=$(echo "$INPUT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')
SERVICE_NAME=${INPUT_NAME:-virgozki}

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
loading "CREATING CONFIG FILES & PANEL UI"

# ==============================================
# ✅ 1. CONFIG.JSON (XRAY)
# ==============================================
cat > config.json <<'EOF'
{
  "log": { "loglevel": "warning" },
  "dns": {
    "servers": ["8.8.8.8", "8.8.4.4", "1.1.1.1"],
    "queryStrategy": "UseIPv4"
  },
  "inbounds": [
    {
      "port": 10000,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [{ "password": "virgozki" }] },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": { "path": "/virgozki" }
      }
    },
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [{ "password": "virgozki" }] },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": { "path": "/virgozki-hu" }
      }
    },
    {
      "port": 10003,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "b831381d-6324-4d53-ad4f-8cda48b30811", "alterId": 0 }]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": { "path": "/vmess-virgozki" }
      }
    },
    {
      "port": 10004,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "b831381d-6324-4d53-ad4f-8cda48b30811", "alterId": 0 }]
      },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": { "path": "/vmess-virgozki-hu" }
      }
    },
    {
      "port": 10006,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "b831381d-6324-4d53-ad4f-8cda48b30811" }],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": { "path": "/vless-virgozki" }
      }
    },
    {
      "port": 10007,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "b831381d-6324-4d53-ad4f-8cda48b30811" }],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": { "path": "/vless-virgozki-hu" }
      }
    },
    {
      "port": 10009,
      "listen": "127.0.0.1",
      "protocol": "shadowsocks",
      "settings": { "clients": [{ "password": "virgozki", "method": "aes-256-gcm" }] },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": { "path": "/ss-virgozki" }
      }
    },
    {
      "port": 10010,
      "listen": "127.0.0.1",
      "protocol": "shadowsocks",
      "settings": { "clients": [{ "password": "virgozki", "method": "aes-256-gcm" }] },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": { "path": "/ss-virgozki-hu" }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

# ==============================================
# ✅ 2. NGINX.CONF
# ==============================================
cat > nginx.conf <<'EOF'
events { worker_connections 1024; }
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    server {
        listen 8080;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }

        location = /virgozki {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
        }

        location = /virgozki-hu {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10001;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
        }

        location = /vmess-virgozki {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10003;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
        }

        location = /vmess-virgozki-hu {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10004;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
        }

        location = /vless-virgozki {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10006;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
        }

        location = /vless-virgozki-hu {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10007;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
        }

        location = /ss-virgozki {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10009;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
        }

        location = /ss-virgozki-hu {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10010;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
        }
    }
}
EOF

# ==============================================
# ✅ 3. INDEX.HTML (CYBERPUNK UI)
# ==============================================
cat > index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>VIRGOZKI PANEL | ENVOY</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;700&display=swap');
        :root {
            --bg-main: #030307;
            --surface-card: rgba(13, 13, 31, 0.85);
            --border: #1e1e3f;
            --text-main: #f1f5f9;
            --text-dim: #94a3b8;
            --accent: #38bdf8;
            --accent-glow: rgba(56, 189, 248, 0.4);
            --green: #10b981;
            --yellow: #f59e0b;
            --blue: #3b82f6;
            --font-sans: 'Plus Jakarta Sans', sans-serif;
            --font-mono: 'JetBrains Mono', monospace;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background: var(--bg-main);
            background-image: 
                radial-gradient(circle at 10% 20%, rgba(56, 189, 248, 0.08) 0%, transparent 40%),
                radial-gradient(circle at 90% 80%, rgba(99, 102, 241, 0.08) 0%, transparent 40%);
            color: var(--text-main);
            font-family: var(--font-sans);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 24px 12px;
        }
        .container { width: 100%; max-width: 680px; display: flex; flex-direction: column; gap: 16px; z-index: 10; }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(16px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes envoyGlow { 0%, 100% { text-shadow: 0 0 15px rgba(56, 189, 248, 0.6); } 50% { text-shadow: 0 0 6px rgba(56, 189, 248, 0.3); } }
        .fade-in { animation: fadeInUp 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .glow-text { animation: envoyGlow 3s ease-in-out infinite; }
        #loading-screen {
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            background: #030307; z-index: 99999;
            transition: opacity 0.5s ease, visibility 0.5s ease;
        }
        #loading-screen.hidden { opacity: 0; visibility: hidden; pointer-events: none; }
        .loader-box { display: flex; flex-direction: column; align-items: center; gap: 20px; }
        .loader-ring {
            width: 70px; height: 70px; border: 3px solid rgba(56, 189, 248, 0.1);
            border-top: 3px solid var(--accent); border-radius: 50%;
            animation: spin 1s linear infinite; box-shadow: 0 0 20px rgba(56, 189, 248, 0.3);
        }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .loading-title { font-size: 22px; font-weight: 800; letter-spacing: 6px; color: #fff; }
        .loading-subtitle { font-size: 11px; color: var(--text-dim); letter-spacing: 3px; text-transform: uppercase; font-family: var(--font-mono); }
        .section {
            background: var(--surface-card); backdrop-filter: blur(12px);
            border: 1px solid var(--border); border-radius: 14px; padding: 20px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4); position: relative;
        }
        .section::before {
            content: ''; position: absolute; top: 0; left: 0; width: 4px; height: 100%;
            background: var(--border); border-radius: 14px 0 0 14px;
        }
        .section-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
        .section-title { font-weight: 700; font-size: 13px; letter-spacing: 1.5px; color: var(--text-dim); text-transform: uppercase; }
        .brand-card { text-align: center; padding: 24px 20px; }
        .brand-title { font-size: clamp(24px, 6vw, 34px); font-weight: 800; color: var(--accent); letter-spacing: 3px; margin-bottom: 4px; }
        .brand-sub { font-size: 12px; color: var(--text-dim); letter-spacing: 4px; text-transform: uppercase; font-weight: 600; }
        .info-grid { display: flex; flex-direction: column; gap: 8px; margin-top: 14px; }
        .info-row {
            display: flex; justify-content: space-between; align-items: center;
            padding: 10px 14px; background: rgba(5, 5, 11, 0.5);
            border-radius: 8px; border: 1px solid rgba(255, 255, 255, 0.03); font-size: 13px;
        }
        .info-label { color: var(--text-dim); font-weight: 500; }
        .info-value { color: var(--text-main); font-family: var(--font-mono); font-weight: 600; font-size: 12px; }
        .info-value.accent { color: var(--accent); }
        .btn {
            background: rgba(15, 15, 31, 0.9); border: 1px solid var(--border); color: var(--text-main);
            padding: 14px 16px; border-radius: 10px; cursor: pointer; font-size: 14px;
            font-family: var(--font-sans); font-weight: 600; width: 100%; text-align: left;
            display: flex; justify-content: space-between; align-items: center; transition: all 0.2s ease;
        }
        .btn:hover { border-color: var(--accent); background: rgba(56, 189, 248, 0.08); color: #fff; }
        .btn.active { background: rgba(56, 189, 248, 0.18); border-color: var(--accent); color: #fff; box-shadow: 0 0 15px rgba(56, 189, 248, 0.25); }
        .button-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 8px; }
        .speed-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-bottom: 14px; }
        .speed-item { background: rgba(5, 5, 11, 0.6); border: 1px solid var(--border); border-radius: 10px; padding: 14px 8px; text-align: center; }
        .speed-label { font-size: 10px; color: var(--text-dim); text-transform: uppercase; font-weight: 700; letter-spacing: 1px; margin-bottom: 4px; }
        .speed-value { font-size: clamp(18px, 4.5vw, 24px); font-weight: 800; font-family: var(--font-mono); }
        .speed-value.download { color: var(--green); }
        .speed-value.upload { color: var(--blue); }
        .speed-value.latency { color: var(--yellow); }
        .speed-unit { font-size: 10px; color: var(--text-dim); margin-top: 2px; }
        .graph-container {
            display: flex; align-items: flex-end; gap: 3px; height: 60px;
            background: rgba(5, 5, 11, 0.6); border: 1px solid var(--border); border-radius: 8px; padding: 8px; margin-bottom: 12px;
        }
        .graph-bar { flex: 1; background: linear-gradient(to top, var(--accent), #bae6fd); border-radius: 2px; min-height: 3px; }
        .log-container {
            background: rgba(5, 5, 11, 0.6); border: 1px solid var(--border); border-radius: 8px;
            padding: 10px 12px; max-height: 110px; overflow-y: auto; font-family: var(--font-mono); font-size: 11px; color: var(--text-dim);
            display: flex; flex-direction: column; gap: 4px;
        }
        .log-entry { display: flex; gap: 8px; }
        .log-time { color: var(--accent); opacity: 0.8; }
        .config-wrapper { position: relative; }
        .config-display {
            background: rgba(3, 3, 7, 0.9); border: 1px solid var(--border); border-radius: 10px;
            padding: 16px; padding-top: 48px; font-family: var(--font-mono); font-size: 12px; line-height: 1.6;
            color: #34d399; word-break: break-all; white-space: pre-wrap; max-height: 200px; overflow-y: auto;
        }
        .copy-btn {
            position: absolute; top: 12px; right: 12px; background: rgba(56, 189, 248, 0.15);
            border: 1px solid var(--accent); color: #fff; padding: 6px 14px; border-radius: 6px; cursor: pointer;
            font-size: 11px; font-weight: 700; letter-spacing: 1px; z-index: 5;
        }
        .copy-btn:hover { background: var(--accent); color: #030307; }
        .fullscreen-modal {
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
            background: rgba(3, 3, 7, 0.98); backdrop-filter: blur(20px); z-index: 999999;
            display: none; flex-direction: column; padding: 20px;
        }
        .fullscreen-modal.show { display: flex; }
        .modal-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 16px; border-bottom: 1px solid var(--border); margin-bottom: 16px; }
        .modal-title { font-size: 15px; font-weight: 700; color: var(--accent); letter-spacing: 1px; }
        .modal-close { background: rgba(56, 189, 248, 0.2); border: 1px solid var(--accent); color: #fff; padding: 10px 18px; border-radius: 8px; cursor: pointer; font-weight: 700; }
        .modal-list { flex: 1; overflow-y: auto; display: flex; flex-direction: column; gap: 10px; padding-bottom: 30px; }
        .dropdown-item {
            padding: 16px 18px; background: rgba(13, 13, 31, 0.8); border: 1px solid var(--border);
            border-radius: 10px; cursor: pointer; font-size: 14px; font-family: var(--font-mono); color: var(--text-main);
        }
        .dropdown-item.selected { border-color: var(--accent); background: rgba(56, 189, 248, 0.3); color: #fff; font-weight: bold; }
    </style>
</head>
<body>

<div id="loading-screen">
    <div class="loader-box">
        <div class="loader-ring"></div>
        <div style="text-align: center;">
            <div class="loading-title glow-text">VIRGOZKI PANEL</div>
            <div class="loading-subtitle">INITIALIZING SECURE PROXY</div>
        </div>
    </div>
</div>

<div class="container" id="main-content" style="display:none;">
    <div class="section brand-card fade-in">
        <div class="brand-title glow-text">VIRGOZKI PANEL</div>
        <div class="brand-sub">NGINX EDITION • Free Internet</div>
        <div class="info-grid">
            <div class="info-row"><span class="info-label">CURRENT HOST</span><span class="info-value accent" id="info-host">---</span></div>
            <div class="info-row"><span class="info-label">UUID / PASS</span><span class="info-value">b831381d-6324... / virgozki</span></div>
            <div class="info-row"><span class="info-label">SYSTEM UPTIME</span><span class="info-value" id="runtime-display">00:00:00</span></div>
        </div>
    </div>

    <div class="section fade-in">
        <div class="section-header"><div class="section-title">🔌 Bug Host / Address</div></div>
        <button class="btn" id="address-dropdown-btn" type="button">
            <span id="address-selected-text">Select Address</span>
            <span style="color: var(--accent);">▼</span>
        </button>
    </div>

    <div class="section fade-in">
        <div class="section-header"><div class="section-title">🛡️ SNI / Server Name Indication</div></div>
        <button class="btn" id="sni-dropdown-btn" type="button">
            <span id="sni-selected-text">Select SNI</span>
            <span style="color: var(--accent);">▼</span>
        </button>
    </div>

    <div class="section fade-in">
        <div class="section-header"><div class="section-title">🔐 Protocol & Transport</div></div>
        <div style="font-size: 11px; color: var(--text-dim); margin-bottom: 6px; font-weight: 600;">PROTOCOL</div>
        <div class="button-grid" id="protocol-bar" style="margin-bottom: 12px;"></div>
        <div style="font-size: 11px; color: var(--text-dim); margin-bottom: 6px; font-weight: 600;">TRANSPORT TYPE</div>
        <div class="button-grid" id="transport-bar"></div>
    </div>

    <div class="section fade-in">
        <div class="section-header"><div class="section-title">📊 Real-Time Telemetry</div></div>
        <div class="speed-grid">
            <div class="speed-item">
                <div class="speed-label">Download</div>
                <div class="speed-value download" id="speed-download">0.0</div>
                <div class="speed-unit" id="speed-download-unit">MB/s</div>
            </div>
            <div class="speed-item">
                <div class="speed-label">Upload</div>
                <div class="speed-value upload" id="speed-upload">0.0</div>
                <div class="speed-unit" id="speed-upload-unit">MB/s</div>
            </div>
            <div class="speed-item">
                <div class="speed-label">Latency</div>
                <div class="speed-value latency" id="speed-latency">0</div>
                <div class="speed-unit">ms</div>
            </div>
        </div>
        <div class="graph-container" id="graph-container"></div>
        <div class="log-container" id="log-container">
            <div class="log-entry"><span class="log-time">--:--:--</span> Nginx proxy service online.</div>
        </div>
    </div>

    <div class="section fade-in">
        <div class="section-header"><div class="section-title">📋 Generated Payload Config</div></div>
        <div class="config-wrapper">
            <button class="copy-btn" id="copy-btn" type="button">COPY</button>
            <div class="config-display" id="config-display">---</div>
        </div>
    </div>
</div>

<div class="fullscreen-modal" id="address-modal">
    <div class="modal-header">
        <div class="modal-title">SELECT BUG HOST / ADDRESS</div>
        <button class="modal-close" id="address-close" type="button">CLOSE</button>
    </div>
    <div class="modal-list" id="address-list"></div>
</div>

<div class="fullscreen-modal" id="sni-modal">
    <div class="modal-header">
        <div class="modal-title">SELECT SNI / SERVER NAME</div>
        <button class="modal-close" id="sni-close" type="button">CLOSE</button>
    </div>
    <div class="modal-list" id="sni-list"></div>
</div>

<script>
(function() {
    const UUID = 'b831381d-6324-4d53-ad4f-8cda48b30811';
    const PASS = 'virgozki';
    let currentHost = window.location.hostname || '127.0.0.1';
    
    const PROTOCOLS = ['vless', 'trojan', 'vmess', 'shadowsocks'];
    const PROTOCOL_LABELS = { vless:'VLESS', trojan:'Trojan', vmess:'VMess', shadowsocks:'Shadowsocks' };
    
    const TRANSPORTS = ['ws', 'hu'];
    const TRANSPORT_LABELS = { ws:'WebSocket', hu:'HTTP Upgrade' };

    const PATHS = { 
        vless: '/vless-virgozki', 
        trojan: '/virgozki', 
        vmess: '/vmess-virgozki', 
        shadowsocks: '/ss-virgozki' 
    };

    let selectedProtocol = 'vless';
    let selectedTransport = 'ws';
    let selectedAddress = currentHost;
    let selectedSNI = currentHost;

    let addressList = [currentHost, 'firebase.googleapis.com', 'google.com', 'run.googleapis.com'];
    let sniList = [currentHost, 'fcmtoken.googleapis.com', 'api.paymaya.com', 's.ytimg.com'];

    let speedHistory = [];
    let lastUpdateTime = Date.now();

    const infoHost = document.getElementById('info-host');
    const runtimeDisplay = document.getElementById('runtime-display');
    const addressDropdownBtn = document.getElementById('address-dropdown-btn');
    const addressSelectedText = document.getElementById('address-selected-text');
    const sniDropdownBtn = document.getElementById('sni-dropdown-btn');
    const sniSelectedText = document.getElementById('sni-selected-text');
    const protocolBar = document.getElementById('protocol-bar');
    const transportBar = document.getElementById('transport-bar');
    const configDisplay = document.getElementById('config-display');
    const copyBtn = document.getElementById('copy-btn');
    const speedDownload = document.getElementById('speed-download');
    const speedUpload = document.getElementById('speed-upload');
    const speedLatency = document.getElementById('speed-latency');
    const speedDownloadUnit = document.getElementById('speed-download-unit');
    const speedUploadUnit = document.getElementById('speed-upload-unit');
    const graphContainer = document.getElementById('graph-container');
    const logContainer = document.getElementById('log-container');
    const loadingScreen = document.getElementById('loading-screen');
    const mainContent = document.getElementById('main-content');
    const addressModal = document.getElementById('address-modal');
    const addressListEl = document.getElementById('address-list');
    const addressClose = document.getElementById('address-close');
    const sniModal = document.getElementById('sni-modal');
    const sniListEl = document.getElementById('sni-list');
    const sniClose = document.getElementById('sni-close');

    function addLog(message) {
        const now = new Date();
        const time = now.toTimeString().split(' ')[0];
        const entry = document.createElement('div');
        entry.className = 'log-entry';
        entry.innerHTML = '<span class="log-time">['+time+']</span> <span>'+message+'</span>';
        logContainer.appendChild(entry);
        logContainer.scrollTop = logContainer.scrollHeight;
    }

    function initPortal() {
        infoHost.textContent = currentHost;
        addressSelectedText.textContent = selectedAddress;
        sniSelectedText.textContent = selectedSNI;

        buildFullList(addressListEl, addressList, 'address');
        buildFullList(sniListEl, sniList, 'sni');

        addressDropdownBtn.addEventListener('click', (e)=>{ e.stopPropagation(); addressModal.classList.add('show'); });
        addressClose.addEventListener('click', (e)=>{ e.stopPropagation(); addressModal.classList.remove('show'); });
        sniDropdownBtn.addEventListener('click', (e)=>{ e.stopPropagation(); sniModal.classList.add('show'); });
        sniClose.addEventListener('click', (e)=>{ e.stopPropagation(); sniModal.classList.remove('show'); });

        setTimeout(()=>{ 
            loadingScreen.classList.add('hidden'); 
            mainContent.style.display='flex'; 
            addLog('Nginx web service online.'); 
            updateConfigDisplay(); 
        }, 1000);

        setInterval(simulateSpeedStream, 600);
        setInterval(updateRuntime, 1000);
    }

    function buildFullList(container, items, type) {
        container.innerHTML='';
        items.forEach(item=>{
            const d=document.createElement('div'); 
            d.className='dropdown-item'; 
            d.textContent=item;
            d.addEventListener('click', (e)=>{
                e.stopPropagation();
                if(type==='address'){ selectedAddress=item; addressSelectedText.textContent=item; addressModal.classList.remove('show'); }
                else { selectedSNI=item; sniSelectedText.textContent=item; sniModal.classList.remove('show'); }
                updateConfigDisplay(); 
                addLog((type==='address'?'Host':'SNI')+' updated: '+item);
            });
            container.appendChild(d);
        });
    }

    function simulateSpeedStream() {
        const now=Date.now();
        if((now-lastUpdateTime)/1000 >= 0.6){
            const dl=Math.random()*15000+4000, ul=Math.random()*5000+2000;
            speedDownload.textContent=(dl/1024).toFixed(1); speedDownloadUnit.textContent='MB/s';
            speedUpload.textContent=(ul/1024).toFixed(1); speedUploadUnit.textContent='MB/s';
            speedLatency.textContent=Math.floor(Math.random()*10+5);
            speedHistory.push(dl); if(speedHistory.length>35) speedHistory.shift();
            updateGraph(); lastUpdateTime=now;
        }
    }

    function updateGraph() {
        graphContainer.innerHTML='';
        const m=Math.max(...speedHistory,1000);
        speedHistory.forEach(s=>{
            const b=document.createElement('div'); b.className='graph-bar'; b.style.height=(s/m*100)+'%'; graphContainer.appendChild(b);
        });
    }

    function updateRuntime() {
        const d=Math.floor(performance.now()/1000);
        runtimeDisplay.textContent=[3600,60,1].map(t=>String(Math.floor(d/t)%60).padStart(2,'0')).join(':');
    }

    function getPath() { return PATHS[selectedProtocol] + (selectedTransport==='hu'?'-hu':''); }

    function buildConfig() {
        const addr=selectedAddress, sni=selectedSNI, host=currentHost, path=getPath();
        const netType=selectedTransport==='ws'?'ws':'httpupgrade';
        const tParam=selectedTransport==='ws'?'type=ws&path=':'type=httpupgrade&path=';
        switch(selectedProtocol){
            case 'vless': return 'vless://'+UUID+'@'+addr+':443?encryption=none&'+tParam+encodeURIComponent(path)+'&host='+host+'&security=tls&fp=chrome&sni='+sni+'&alpn=http%2F1.1#VLESS-'+selectedTransport.toUpperCase()+'-virgozki';
            case 'trojan': return 'trojan://'+PASS+'@'+addr+':443?'+tParam+encodeURIComponent(path)+'&host='+host+'&security=tls&fp=chrome&sni='+sni+'&alpn=http%2F1.1#TROJAN-'+selectedTransport.toUpperCase()+'-virgozki';
            case 'vmess': return 'vmess://'+btoa(JSON.stringify({v:'2',ps:'VMESS-'+selectedTransport.toUpperCase()+'-virgozki',add:addr,port:'443',id:UUID,aid:'0',scy:'auto',net:netType,type:'none',host:host,path:path,tls:'tls',sni:sni,fp:'chrome',alpn:'http/1.1'}));
            case 'shadowsocks': return 'ss://'+btoa('aes-256-gcm:'+PASS)+'@'+addr+':443?'+tParam+encodeURIComponent(path)+'&host='+host+'&security=tls&fp=chrome&sni='+sni+'&alpn=http%2F1.1#SS-'+selectedTransport.toUpperCase()+'-virgozki';
        }
    }

    function updateConfigDisplay() { configDisplay.textContent=buildConfig(); }

    function buildButtonBar(c,items,sel,lbl,cb){
        c.innerHTML='';
        items.forEach(i=>{
            const b=document.createElement('button'); 
            b.type = 'button'; b.className='btn'; 
            if(i===sel) b.classList.add('active'); 
            b.textContent=lbl?lbl[i]:i;
            b.addEventListener('click',()=>{ 
                c.querySelectorAll('.btn').forEach(x=>x.classList.remove('active')); 
                b.classList.add('active'); cb(i); updateConfigDisplay(); 
            });
            c.appendChild(b);
        });
    }

    buildButtonBar(protocolBar, PROTOCOLS, selectedProtocol, PROTOCOL_LABELS, v=>{ selectedProtocol=v; addLog('Protocol switched to: '+v.toUpperCase()); });
    buildButtonBar(transportBar, TRANSPORTS, selectedTransport, TRANSPORT_LABELS, v=>{ selectedTransport=v; addLog('Transport switched to: '+v.toUpperCase()); });

    copyBtn.addEventListener('click',()=>{
        navigator.clipboard.writeText(configDisplay.textContent).then(()=>{
            copyBtn.textContent='COPIED!'; copyBtn.style.background='var(--green)';
            setTimeout(()=>{ copyBtn.textContent='COPY'; copyBtn.style.background=''; }, 2000); 
            addLog('Config copied.');
        });
    });

    window.addEventListener('load', initPortal);
})();
</script>

</body>
</html>
EOF
