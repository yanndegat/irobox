#!/usr/bin/env bash

set -eEuox pipefail

source /admin-openrc.sh

PROJECT_DOMAIN_ID=$(openstack domain show -f value -c id "${OS_PROJECT_DOMAIN_NAME}")

######################
# NEUTRON SERVICE SETUP
# ####################
NEUTRON_SVC_ID=$(create_svc network neutron "Neutron network service")
SVC_PROJECT_ID=$(openstack project show -f value -c id --domain="${PROJECT_DOMAIN_ID}" "admin");

create_endpoint "${NEUTRON_SVC_ID}" admin "http://${NEUTRON_NODE}:9696"
create_endpoint "${NEUTRON_SVC_ID}" public "http://${NEUTRON_NODE}:9696"
create_endpoint "${NEUTRON_SVC_ID}" internal "http://${NEUTRON_NODE}:9696"

assign_endpoint network public "${SVC_PROJECT_ID}"
assign_endpoint network internal "${SVC_PROJECT_ID}"
assign_endpoint network admin "${SVC_PROJECT_ID}"

# setup neutron svc users
NEUTRON_USER_DESC="NEUTRON Service User for ${OS_REGION_NAME}/${OS_USER_DOMAIN_NAME}"
NEUTRON_USER_ID=$(openstack user create --or-show --enable -f value -c id \
    --domain="${OS_DOMAIN_NAME}" \
    --project-domain="${PROJECT_DOMAIN_ID}" \
    --project="${SVC_PROJECT_ID}" \
    --description="${NEUTRON_USER_DESC}" \
    "neutron");
# Manage user password (we do this in a seperate step to ensure the password is updated if required)
set +x
echo "Setting neutron user password via: openstack user set --password=xxxxxxx ${NEUTRON_USER_ID}"
openstack user set --password="${NEUTRON_OS_PASSWORD}" --ignore-lockout-failure-attempts "${NEUTRON_USER_ID}"
set -x

assign_user_role "${NEUTRON_USER_ID}" "${SVC_PROJECT_ID}" admin

USER_PROJECT_ID=$(openstack project show -f value -c id "${USER_OS_PROJECT_NAME}")

assign_endpoint network public "${USER_PROJECT_ID}"
assign_endpoint network admin "${USER_PROJECT_ID}"
