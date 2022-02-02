#!/usr/bin/env bash

set -eEuo pipefail

ovsdbrun_cmd() {
    /usr/sbin/ovsdb-server \
        /var/lib/openvswitch/conf.db \
        --pidfile=/var/run/openvswitch/ovsdb-server.pid \
        --remote=punix:/var/run/openvswitch/db.sock \
        --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
        --run "${@}"
}

ovsdbrun_cmd "/usr/sbin/ovs-vswitchd unix:/var/run/openvswitch/db.sock -vconsole:warn -vsyslog:info -vfile:info --mlockall --pidfile=/var/run/openvswitch/ovs-vswitchd.pid"
