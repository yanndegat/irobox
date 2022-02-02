#!/usr/bin/env bash

assign_user_role() {
   user="${1}"
   project="${2}"
   role="${3}"

   role_id=$(openstack role create --or-show -f value -c id "${role}");

   # Manage user role assignment
   openstack role add \
             --user="${user}" \
             --project="${project}" \
             "${role_id}"
}

assign_endpoint() {
   endpoint_type="${1}"
   endpoint_interface="${2}"
   project_id="${3}"

   endpoint_id=$(openstack endpoint list -f value -c ID \
                           --region "${OS_REGION_NAME}" \
                           --service "${endpoint_type}" \
                           --interface "${endpoint_interface}");

   # In case the endpoint is already associated, we delete it first
   # But there is no way to check the endpoint is already associated so that's
   # one way to do it...
   set +e
   openstack endpoint remove project "${endpoint_id}" "${project_id}"
   set -e

   openstack endpoint add project "${endpoint_id}" "${project_id}"
}

create_endpoint() {
   endpoint_type="${1}"
   endpoint_interface="${2}"
   endpoint_url="${3}"

   endpoint_id=$(openstack endpoint list -f value -c ID \
                           --region "${OS_REGION_NAME}" \
                           --service "${endpoint_type}" \
                           --interface "${endpoint_interface}");

   if [ -z "${endpoint_id}" ]; then
       openstack endpoint create --region "${OS_REGION_NAME}" "${endpoint_type}" "${endpoint_interface}"  "${endpoint_url}"
   fi
}

create_svc() {
   svc_type="${1}"
   svc_name="${2}"
   svc_desc="${3}"

   svc_id=$(openstack service list -f value -c ID -c Name -c Type | grep "${svc_name} ${svc_type}$" | cut -d\  -f 1)

   if [ -z "${svc_id}" ]; then
       echo $(openstack service create --enable -f value -c id \
           --name="${svc_name}" \
           --description="${svc_desc}" \
           "${svc_type}")
   else
       echo "${svc_id}"
   fi
}

export OS_USERNAME=admin
export OS_PASSWORD=$KEYSTONE_ADMIN_PASSWORD
export OS_PROJECT_NAME="admin"
export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_DOMAIN_NAME="Default"
export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL=${OS_AUTH_URL:-"http://api:5000/v3"}
export OS_REGION_NAME="RegionOne"
