#!/usr/bin/env bash

set -eEuo pipefail

export DEBIAN_FRONTEND=noninteractive
apt update && apt install -y curl

SSH_PUB_KEY="${SSH_PUB_KEY:=""}"

setup_http_image(){
   img_name="$1"
   img_url="$2"
   img_file="$(basename "${img_url}")"

   if ! openstack image show -c id -f value "${img_name}" > /dev/null; then
       if [[ ! -f "/images/${img_file}" ]]; then
           echo "dl $img_url" >&2
           curl -fsSL -o "/images/${img_file}" "${img_url}"
       fi

       echo "create img $img_name" >&2
       openstack image create \
           --public \
           --disk-format qcow2 \
           --container-format bare \
           --file "/images/${img_file}" \
           "${img_name}"
   fi
}

setup_file_image(){
   img_file="$1"
   img_name="$(basename "${img_file}")"

   if ! openstack image show -c id -f value "${img_name}" > /dev/null; then
       if [[ ! -f "${img_file}" ]]; then
           echo "file ${img_file} doesn't exist." >&2
           exit 1
       fi

       echo "create img $img_name" >&2
       openstack image create \
           --public \
           --disk-format qcow2 \
           --container-format bare \
           --file "${img_file}" \
           "${img_name}"
   fi
}

setup_http_image debian11 "https://cloud.debian.org/images/cloud/bullseye/daily/20220106-879/debian-11-generic-amd64-daily-20220106-879.qcow2"
setup_file_image /images/ironic-python-agent.kernel
setup_file_image /images/ironic-python-agent.initramfs

# if ssh pub key is defined, inject it into ipa ramdisk
if [[ -n "${SSH_PUB_KEY}" ]]; then
    export DEBIAN_FRONTEND=noninteractive
    apt update && apt install -y gzip cpio
    ROOTDIR="$(mktemp -d)"
    (
        cd "${ROOTDIR}"
        gzip -dc /images/ironic-python-agent.initramfs | cpio -id
        mkdir -p ./root/.ssh
        printf '%s\n' "${SSH_PUB_KEY}" > ./root/.ssh/authorized_keys
        find . | cpio -H newc -o | gzip -c > /images/ironic-python-agent-with-sshkey.initramfs
        setup_file_image /images/ironic-python-agent-with-sshkey.initramfs
    )
fi
