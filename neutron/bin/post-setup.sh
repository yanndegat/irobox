#!/usr/bin/env bash

set -eEuox pipefail

source /admin-openrc.sh
: "${BM_NET_NAME:?mandatory}"

: "${ADMIN_NET_NAME:?mandatory}"
: "${ADMIN_NET_GW_IP:?mandatory}"
: "${ADMIN_NET_CIDR:?mandatory}"
: "${ADMIN_NET_START_IP:?mandatory}"
: "${ADMIN_NET_END_IP:?mandatory}"

: "${USER_NET_NAME:?mandatory}"
: "${USER_NET_CIDR:?mandatory}"
: "${USER_NET_START_IP:?mandatory}"
: "${USER_NET_END_IP:?mandatory}"

if ! openstack network show -c id -f value "${ADMIN_NET_NAME}" > /dev/null; then
    openstack network create --project admin "${ADMIN_NET_NAME}" \
        --provider-network-type flat --provider-physical-network "${BM_NET_NAME}"
fi

if ! openstack subnet show -c id -f value "${ADMIN_NET_NAME}" > /dev/null; then
    openstack subnet create "${ADMIN_NET_NAME}" --network "${ADMIN_NET_NAME}" \
        --subnet-range "${ADMIN_NET_CIDR}" --ip-version 4 --gateway "${ADMIN_NET_GW_IP}" \
        --allocation-pool "start=${ADMIN_NET_START_IP},end=${ADMIN_NET_END_IP}" --dhcp
fi

if ! openstack network show -c id -f value "${USER_NET_NAME}" > /dev/null; then
    openstack network create --project "${USER_OS_PROJECT_NAME}" "${USER_NET_NAME}" \
        --provider-network-type vlan --provider-physical-network "${BM_NET_NAME}"
fi

if ! openstack subnet show -c id -f value "${USER_NET_NAME}" > /dev/null; then
    openstack subnet create "${USER_NET_NAME}" --network "${USER_NET_NAME}" \
        --subnet-range "${USER_NET_CIDR}" --ip-version 4 --gateway none \
        --allocation-pool "start=${USER_NET_START_IP},end=${USER_NET_END_IP}" --dhcp
fi

DHCP_AGENT_ID=$(openstack network agent list --agent-type dhcp --host $(hostname) -c State -c ID -f value | awk '/True/ {print $1}')

if [[ -z "${DHCP_AGENT_ID}" ]]; then
    echo "Could not find alive DHCP agent on host $(hostname)." >&2
    exit 1
fi

openstack network agent add network --dhcp "${DHCP_AGENT_ID}" "${ADMIN_NET_NAME}"
openstack network agent add network --dhcp "${DHCP_AGENT_ID}" "${USER_NET_NAME}"
