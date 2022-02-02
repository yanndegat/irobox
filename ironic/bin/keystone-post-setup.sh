#!/usr/bin/env bash

set -eEuox pipefail

source /admin-openrc.sh

PROJECT_DOMAIN_ID=$(openstack domain show -f value -c id "${OS_PROJECT_DOMAIN_NAME}")

######################
# IRONIC SERVICE SETUP
# ####################
IRONIC_SVC_ID=$(create_svc baremetal ironic "Ironic baremetal provisioning service")

SVC_PROJECT_ID=$(openstack project show -f value -c id --domain="${PROJECT_DOMAIN_ID}" "admin");

create_endpoint "${IRONIC_SVC_ID}" admin "http://${IRONIC_NODE}:6385"
create_endpoint "${IRONIC_SVC_ID}" public "http://${IRONIC_NODE}:6385"
create_endpoint "${IRONIC_SVC_ID}" internal "http://${IRONIC_NODE}:6385"

assign_endpoint baremetal public "${SVC_PROJECT_ID}"
assign_endpoint baremetal internal "${SVC_PROJECT_ID}"
assign_endpoint baremetal admin "${SVC_PROJECT_ID}"

openstack role create baremetal_admin || true
openstack role create baremetal_observer || true

# setup ironic svc users
IRONIC_USER_DESC="IRONIC Service User for ${OS_REGION_NAME}/${OS_USER_DOMAIN_NAME}"
IRONIC_USER_ID=$(openstack user create --or-show --enable -f value -c id \
    --domain="${OS_DOMAIN_NAME}" \
    --project-domain="${PROJECT_DOMAIN_ID}" \
    --project="${SVC_PROJECT_ID}" \
    --description="${IRONIC_USER_DESC}" \
    "ironic");
# Manage user password (we do this in a seperate step to ensure the password is updated if required)
set +x
echo "Setting ironic user password via: openstack user set --password=xxxxxxx ${IRONIC_USER_ID}"
openstack user set --password="${IRONIC_OS_PASSWORD}" --ignore-lockout-failure-attempts "${IRONIC_USER_ID}"
set -x

assign_user_role "${IRONIC_USER_ID}" "${SVC_PROJECT_ID}" admin

USER_PROJECT_ID=$(openstack project show -f value -c id "${USER_OS_PROJECT_NAME}")
assign_endpoint image public "${USER_PROJECT_ID}"
assign_endpoint image admin "${USER_PROJECT_ID}"

USER_ID=$(openstack user show -f value -c id "${USER_OS_USERNAME}")
assign_user_role "${USER_ID}" "${USER_PROJECT_ID}" baremetal_admin
assign_user_role "${USER_ID}" "${USER_PROJECT_ID}" baremetal_observer
