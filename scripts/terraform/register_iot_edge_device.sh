#!/bin/bash

set -e

create() {
    az iot hub device-identity create --device-id "$iot_edge_device_name" --edge-enabled --hub-name "$iot_hub_name" --output none
    # shellcheck disable=SC2162
    read
}

read() {
    az iot hub device-identity connection-string show --device-id "$iot_edge_device_name" --hub-name "$iot_hub_name"
}

delete() {
    az iot hub device-identity delete --device-id "$iot_edge_device_name" --hub-name "$iot_hub_name"
}

# Check if the function exists (bash specific)
if declare -f "$1" >/dev/null; then
    # call arguments verbatim
    "$@"
else
    # Show a helpful error
    echo "'$1' is not a known function name" >&2
    exit 1
fi
