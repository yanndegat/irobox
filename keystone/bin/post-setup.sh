#!/usr/bin/env bash

source /admin-openrc.sh

set -eEuox pipefail

PROJECT_DOMAIN_ID=$(openstack domain create --or-show --enable -f value -c id \
                              --description="Domain for ${OS_REGION_NAME}/${OS_PROJECT_DOMAIN_NAME}" \
                              "${OS_PROJECT_DOMAIN_NAME}")

USER_DOMAIN_ID=$(openstack domain create --or-show --enable -f value -c id \
    --description="Domain for ${OS_REGION_NAME}/${OS_USER_DOMAIN_NAME}" \
    "${OS_USER_DOMAIN_NAME}")

# USER PROJECT SETUP
# Manage project domain
# Manage user project
USER_PROJECT_DESC="Service Project for ${OS_REGION_NAME}/${OS_PROJECT_DOMAIN_NAME}"
USER_PROJECT_ID=$(openstack project create --or-show --enable -f value -c id \
    --domain="${PROJECT_DOMAIN_ID}" \
    --description="${USER_PROJECT_DESC}" \
    "${USER_OS_PROJECT_NAME}");

# Manage users
USER_DESC="User for ${OS_REGION_NAME}/${OS_USER_DOMAIN_NAME}/${USER_OS_USERNAME}"
USER_ID=$(openstack user create --or-show --enable -f value -c id \
    --domain="${USER_DOMAIN_ID}" \
    --project-domain="${PROJECT_DOMAIN_ID}" \
    --project="${USER_PROJECT_ID}" \
    --description="${USER_DESC}" \
    --password="${USER_OS_PASSWORD}" \
    "${USER_OS_USERNAME}");

# Manage user password (we do this in a seperate step to ensure the password is updated if required)
set +x
echo "Setting user password via: openstack user set --password=xxxxxxx ${USER_ID}"
openstack user set --password="${USER_OS_PASSWORD}" "${USER_ID}"
set -x

assign_endpoint identity public "${USER_PROJECT_ID}"
assign_endpoint identity admin "${USER_PROJECT_ID}"
assign_endpoint identity internal "${USER_PROJECT_ID}"

assign_user_role "${USER_ID}" "${USER_PROJECT_ID}" admin
assign_user_role "${USER_ID}" "${USER_PROJECT_ID}" member
