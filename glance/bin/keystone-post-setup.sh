#!/usr/bin/env bash

set -eEuox pipefail

source /admin-openrc.sh

PROJECT_DOMAIN_ID=$(openstack domain show -f value -c id "${OS_PROJECT_DOMAIN_NAME}")

######################
# GLANCE SERVICE SETUP
# ####################
GLANCE_SVC_ID=$(create_svc image glance "Glance image service")
SVC_PROJECT_ID=$(openstack project show -f value -c id --domain="${PROJECT_DOMAIN_ID}" "admin");

create_endpoint "${GLANCE_SVC_ID}" admin "http://${GLANCE_NODE}:9292"
create_endpoint "${GLANCE_SVC_ID}" public "http://${GLANCE_NODE}:9292"
create_endpoint "${GLANCE_SVC_ID}" internal "http://${GLANCE_NODE}:9292"

assign_endpoint image public "${SVC_PROJECT_ID}"
assign_endpoint image internal "${SVC_PROJECT_ID}"
assign_endpoint image admin "${SVC_PROJECT_ID}"

# setup glance svc users
GLANCE_USER_DESC="GLANCE Service User for ${OS_REGION_NAME}/${OS_USER_DOMAIN_NAME}"
GLANCE_USER_ID=$(openstack user create --or-show --enable -f value -c id \
    --domain="${OS_DOMAIN_NAME}" \
    --project-domain="${PROJECT_DOMAIN_ID}" \
    --project="${SVC_PROJECT_ID}" \
    --description="${GLANCE_USER_DESC}" \
    "glance");
# Manage user password (we do this in a seperate step to ensure the password is updated if required)
set +x
echo "Setting glance user password via: openstack user set --password=xxxxxxx ${GLANCE_USER_ID}"
openstack user set --password="${GLANCE_OS_PASSWORD}" --ignore-lockout-failure-attempts "${GLANCE_USER_ID}"
set -x

assign_user_role "${GLANCE_USER_ID}" "${SVC_PROJECT_ID}" admin
openstack role add --user "${GLANCE_USER_ID}" --system all reader

USER_PROJECT_ID=$(openstack project show -f value -c id "${USER_OS_PROJECT_NAME}")
assign_endpoint image public "${USER_PROJECT_ID}"
assign_endpoint image admin "${USER_PROJECT_ID}"
