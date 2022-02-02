#!/usr/bin/env bash

set -eEuo pipefail

chown -R keystone:keystone /etc/keystone/fernet-keys/ /etc/keystone/credential-keys/
keystone-manage db_sync
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap \
    --bootstrap-project-name "admin" \
    --bootstrap-role-name "admin" \
    --bootstrap-service-name "keystone" \
    --bootstrap-username "${KEYSTONE_ADMIN_USERNAME}" \
    --bootstrap-password "${KEYSTONE_ADMIN_PASSWORD}" \
    --bootstrap-admin-url "http://${SERVICE_IP}:5000/v3/" \
    --bootstrap-internal-url "http://${SERVICE_IP}:5000/v3/" \
    --bootstrap-public-url "http://${SERVICE_IP}:5000/v3/" \
    --bootstrap-region-id RegionOne
