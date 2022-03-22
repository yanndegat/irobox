#!/usr/bin/env bash

set -eEuox pipefail

: "${DEFAULT_RAMDISK_IMG_NAME:="ironic-python-agent.initramfs"}"
: "${DISCOVERY_RAMDISK_IMG_NAME:="ironic-python-agent.initramfs"}"
: "${DISCOVERY_KERNEL_IMG_NAME:="ironic-python-agent.kernel"}"
: "${DISCOVERY_IPMI_USERNAME:="admin"}"
: "${DISCOVERY_IPMI_PASSWORD:?mandatory}"
: "${SERVICE_IP:?mandatory}"


source /admin-openrc.sh

RAMDISK_IMG_ID=$(openstack image show -c id -f value "${DISCOVERY_RAMDISK_IMG_NAME}")
KERNEL_IMG_ID=$(openstack image show -c id -f value "${DISCOVERY_KERNEL_IMG_NAME}")

if [[ -z "${RAMDISK_IMG_ID}" ]]; then
    echo "Could not find ramdiskc image with name "${DISCOVERY_RAMDISK_IMG_NAME}"." >&2
    exit 1
fi

if [[ -z "${KERNEL_IMG_ID}" ]]; then
    echo "Could not find ramdiskc image with name "${DISCOVERY_KERNEL_IMG_NAME}"." >&2
    exit 1
fi

# save images locally for auto enroll
openstack image save --file "/shared/html/images/${DISCOVERY_RAMDISK_IMG_NAME}" "${RAMDISK_IMG_ID}"
openstack image save --file "/shared/html/images/${DISCOVERY_KERNEL_IMG_NAME}" "${KERNEL_IMG_ID}"

if [[ ! -f "/shared/html/images/${DEFAULT_RAMDISK_IMG_NAME}" ]]; then
    ln -fs "/shared/html/images/${DISCOVERY_RAMDISK_IMG_NAME}" "/shared/html/images/${DEFAULT_RAMDISK_IMG_NAME}"
fi

# add introspection rules to auto setup ipmi and deploy images
cat > /dev/shm/rules.json <<EOF
[{
    "description": "Set IPMI driver_info if no credentials",
    "actions": [
        {"action": "set-attribute", "path": "driver", "value": "ipmi"},
        {"action": "set-attribute", "path": "driver_info/ipmi_username",
         "value": "${DISCOVERY_IPMI_USERNAME}"},
        {"action": "set-attribute", "path": "driver_info/ipmi_password",
         "value": "${DISCOVERY_IPMI_PASSWORD}"}
    ],
    "conditions": [
        {"op": "is-empty", "field": "node://driver_info.ipmi_password"},
        {"op": "is-empty", "field": "node://driver_info.ipmi_username"}
    ]
},{
    "description": "Set deploy info if not already set on node",
    "actions": [
        {"action": "set-attribute", "path": "driver_info/deploy_kernel",
         "value": "${KERNEL_IMG_ID}"},
        {"action": "set-attribute", "path": "driver_info/deploy_ramdisk",
         "value": "${RAMDISK_IMG_ID}"}
    ],
    "conditions": [
        {"op": "is-empty", "field": "node://driver_info.deploy_ramdisk"},
        {"op": "is-empty", "field": "node://driver_info.deploy_kernel"}
    ]
}]
EOF

eval "$(env | awk -F= '/^OS_/ { print "unset " $1 ";" }')"

pip3 install python-ironicclient python-ironic-inspector-client
baremetal introspection rule import --os-endpoint "http://${SERVICE_IP}:5050" --os-auth-type none /dev/shm/rules.json
