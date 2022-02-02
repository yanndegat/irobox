#!/usr/bin/env bash

set -eEuo pipefail

: "${SUBSYSTEM:?"env var is mandatory"}"

if [[ ! -d "${SUBSYSTEM}" ]]; then
  echo "${SUBSYSTEM} is wrong. must be existing sub directory." >&2
  exit 1
fi


SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENVFILE="${SUBSYSTEM}/.env"

COMMON_VARS=""
if [[ -f "vars/common.env" ]]; then
  COMMON_VARS="vars/common.env"
fi

SUBSYSTEM_VARS=""
if [[ -f "vars/${SUBSYSTEM}.env" ]]; then
  SUBSYSTEM_VARS="vars/${SUBSYSTEM}.env"
fi


# load ??*.env files
for i in $SCRIPTDIR/??*.env; do
  if [[ -f "$i" ]]; then
      source "$i"
  fi
done


# openstack setup default vars
export OS_REGION_NAME=${OS_REGION_NAME:="RegionOne"}
export OS_DOMAIN_NAME=${OS_DOMAIN_NAME:="Default"}
export OS_PROJECT_DOMAIN_NAME=${OS_PROJECT_DOMAIN_NAME:="Default"}
export USER_OS_PROJECT_NAME=${USER_OS_PROJECT_NAME:="MyProject"}
export OS_USER_DOMAIN_NAME=${OS_USER_DOMAIN_NAME:="Default"}
export USER_OS_USERNAME=${USER_OS_USERNAME:="superuser"}
export IRONIC_DEV_MODE="${IRONIC_DEV_MODE:=false}"
export SERVICE_INTERFACE="${SERVICE_INTERFACE:=$(ip route get 1.2.3.4 | awk '/src/ {print $5}')}"
export SERVICE_IP="${SERVICE_IP:=$(ip -brief addr show dev "${SERVICE_INTERFACE}" | awk '{print $3}' | cut -d / -f1)}"
export SSH_KEY_FILE="${SSH_KEY_FILE:="$HOME/.ssh/id_rsa.pub"}"
export SSH_PUB_KEY="$(cat ${SSH_KEY_FILE})"

MARIADB_PASSWORD=${MARIADB_PASSWORD:-""}

if [ -z "${MARIADB_PASSWORD}" ]; then
    # reuse password if .env already exists
    if grep -q MARIADB_PASSWORD "${ENVFILE}" 2>/dev/null; then
        eval $(grep MARIADB_PASSWORD "${ENVFILE}" | xargs -n1 echo export)
    else
      MARIADB_PASSWORD=$(echo "$(date;hostname)"|sha256sum |cut -c-20)
    fi
fi
export MARIADB_PASSWORD
export MYSQL_PASSWORD="${MARIADB_PASSWORD}"

KEYSTONE_ADMIN_PASSWORD=${KEYSTONE_ADMIN_PASSWORD:-""}
if [ -z "${KEYSTONE_ADMIN_PASSWORD}" ]; then
    # reuse password if .env already exists
    if grep -q KEYSTONE_ADMIN_PASSWORD "keystone/.env" 2>/dev/null; then
        eval $(grep KEYSTONE_ADMIN_PASSWORD "keystone/.env" | xargs -n1 echo export)
    else
      KEYSTONE_ADMIN_PASSWORD=$(echo "$(date;hostname)"|sha256sum |cut -c-20)
    fi
fi
export KEYSTONE_ADMIN_PASSWORD


RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS:-""}

if [ -z "${RABBITMQ_DEFAULT_PASS}" ]; then
    # reuse password if .env already exists
    if grep -q RABBITMQ_DEFAULT_PASS "${ENVFILE}" 2>/dev/null; then
        eval $(grep RABBITMQ_DEFAULT_PASS "${ENVFILE}" | xargs -n1 echo export)
    else
      RABBITMQ_DEFAULT_PASS=$(echo "$(date;hostname)"|sha256sum |cut -c-20)
    fi
fi
export RABBIT_DEFAULT_PASS



if [ -f "$COMMON_VARS" ]; then
      envsubst < "$COMMON_VARS"  > "${ENVFILE}"
fi

if [ -f "$SUBSYSTEM_VARS" ]; then
      envsubst < "$SUBSYSTEM_VARS" >> "${ENVFILE}"
fi
