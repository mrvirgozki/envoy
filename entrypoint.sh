#!/bin/sh
set -e
# Patakbuhin ang Xray sa background at i-suppress ang unnecessary logs kung kinakailangan
xray run -c /etc/xray.json &

# Magbigay ng 1-second allowance para mag-bind ang Xray sa mga port nito
sleep 1

# Patakbuhin ang Envoy bilang pangunahing proseso (PID 1)
exec envoy -c /etc/envoy/envoy.yaml --service-cluster proxy
