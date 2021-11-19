#!/usr/bin/env bash

set -eEuo pipefail

export IRONIC_DEV_MODE=${IRONIC_DEV_MODE:-"false"}
if [ "${IRONIC_DEV_MODE}" == "true" ] && [ -d "/src" ]; then
    (cp -Rf /src /tmp; cd /tmp/src; rm -Rf dist/*;
     SKIP_GENERATE_AUTHORS=1 SKIP_WRITE_GIT_CHANGELOG=1 python3 setup.py sdist;
     pip3 uninstall -y ironic || true
     pip3 install --prefix /usr dist/$(ls -tr1 dist | tail -1))
fi

exec "$@"
