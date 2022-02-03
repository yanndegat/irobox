#!/bin/bash

set -eEuo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=.env
source "${SCRIPTDIR}/ironic/.env"

cat > clouds.yaml <<EOF
clouds:
  ironic:
    # auth_type: http_basic
    # auth:
    #   username: userxxx
    #   password: passyyy


    #cacert: /etc/openstack/ironic-ca.crt
    baremetal_endpoint_override: ${IRONIC_ENDPOINT}
    baremetal_introspection_endpoint_override: ${IRONIC_INSPECTOR_ENDPOINT}
EOF
