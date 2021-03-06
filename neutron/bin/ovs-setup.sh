#!/usr/bin/env bash

set -eEuo pipefail

: "${BR_EXT:=br-ext}"
: "${BR_EXT_NETIF:=eth0}"

ovsdbrun_cmd() {
    /usr/sbin/ovsdb-server \
        /var/lib/openvswitch/conf.db \
        --pidfile=/var/run/openvswitch/ovsdb-server.pid \
        --remote=punix:/var/run/openvswitch/db.sock \
        --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
        --run "${@}"
}

modprobe openvswitch
if [[ -f /var/lib/openvswitch/conf.db ]]; then
    echo "DB already exists. rm (if you want to start fresh). exiting." >&1
    exit 0
fi

mkdir -p "/var/run/openvswitch"
ovsdb-tool create "/var/lib/openvswitch/conf.db"
ovsdbrun_cmd "ovs-vsctl --no-wait -- init"
ovsdbrun_cmd "ovs-appctl -t ovsdb-server ovsdb-server/add-remote db:Open_vSwitch,Open_vSwitch,manager_options"
ovsdbrun_cmd "ovs-vsctl --no-wait --may-exist add-br ${BR_EXT}"
ovsdbrun_cmd "ovs-vsctl --no-wait --may-exist add-port ${BR_EXT} ${BR_EXT_NETIF}"
