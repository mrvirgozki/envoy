#!/bin/sh
set -e
echo "Starting Xray..."
xray run -c /etc/xray.json &
echo "Starting Envoy..."
exec envoy -c /etc/envoy/envoy.yaml --service-cluster proxy -l debug
