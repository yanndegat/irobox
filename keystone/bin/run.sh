#!/bin/bash

set -ex

COMMAND="${@:-start}"

function start () {
    if [ ! "$(ls -A /etc/keystone/fernet-keys/)" ]; then
       echo "no fernet keys. exiting"
       exit 1
    fi

    if [ ! "$(ls -A /etc/keystone/credential-keys/)" ]; then
        echo "no credential keys. exiting"
        exit 1
    fi

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
