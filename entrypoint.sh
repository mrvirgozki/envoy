#!/bin/sh
xray run -c /etc/xray.json &
exec envoy -c /etc/envoy/envoy.yaml --service-cluster proxy
