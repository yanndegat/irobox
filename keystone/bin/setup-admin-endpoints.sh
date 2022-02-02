#!/usr/bin/env bash

set -eEuo pipefail

clean(){
   rm /root/.my.cnf
}
trap clean EXIT

cat > /root/.my.cnf <<EOF
[client]
password='${MARIADB_PASSWORD}'
user=keystone
host=db
port=3306
database=keystone
EOF

mysql -e "replace into project_endpoint (endpoint_id, project_id) select e.id as endpoint_id, p.id from project p, endpoint e join service s on s.id = e.service_id where s.type = 'identity' and p.name = 'admin'"
