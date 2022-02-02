#!/usr/bin/env bash

set -ex

HORIZON_DIR="${HORIZON_DIR:=/var/lib/horizon}"

COMMAND="${@:-start}"

function start () {
    a2dissite 000-default
    if [ -f /etc/apache2/envvars ]; then
        # Loading Apache2 ENV variables
        source /etc/apache2/envvars
    fi

    if [ -f /var/run/apache2/apache2.pid ]; then
        # Remove the stale pid for debian/ubuntu images
        rm -f /var/run/apache2/apache2.pid
    fi

    # Start Apache2
    exec apache2 -DFOREGROUND
}

function stop () {
    apache2 -k graceful-stop
}

$COMMAND
