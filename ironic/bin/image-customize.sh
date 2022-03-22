#!/usr/bin/env bash

set -eEuo pipefail

: "${IRONIC_DEV_MODE:="false"}"
: "${IRONIC_VERSION:="master"}"
: "${IRONIC_LIB_REPO:="https://opendev.org/openstack/ironic-lib.git"}"
: "${IRONIC_REPO:="https://opendev.org/openstack/ironic.git"}"
: "${IRONIC_INSPECTOR_REPO:="https://opendev.org/openstack/ironic-inspector.git"}"

install_pkg(){
    project="$1"
    repo="$2"
    (cd /tmp;
     git clone "$repo" --branch "${IRONIC_VERSION}" --single-branch "${project}";
     cd "/tmp/$project"; rm -Rf dist/*;
     SKIP_GENERATE_AUTHORS=1 SKIP_WRITE_GIT_CHANGELOG=1 python3 setup.py sdist;
     pip3 uninstall -y "$project" || true
     pip3 install --prefix /usr dist/$(ls -tr1 dist | tail -1))
}

# TMPHACK: 404 issues with delorean repos
rm -Rf /etc/yum.repos.d/delorean*

rpm --import https://packages.confluent.io/rpm/7.0/archive.key
cat > /etc/yum.repos.d/confluent.repo <<EOF
[Confluent-Clients]
name=Confluent Clients repository
baseurl=https://packages.confluent.io/clients/rpm/centos/\$releasever/\$basearch
gpgcheck=1
gpgkey=https://packages.confluent.io/clients/rpm/archive.key
enabled=1
EOF

dnf groupinstall -y "development tools"
dnf install -y openssl-devel pam-devel zlib-devel python3-devel librdkafka-devel iputils mtr socat vim
pip3 install "oslo.messaging[kafka]"

if [ "${IRONIC_DEV_MODE}" == "true" ]; then
    install_pkg ironic-lib "${IRONIC_LIB_REPO}"
    install_pkg ironic "${IRONIC_REPO}"
    install_pkg ironic-inspector "${IRONIC_INSPECTOR_REPO}"
fi

## shell in a box install
(cd /tmp;
 git clone https://github.com/shellinabox/shellinabox.git && cd shellinabox;
 autoreconf -i; ./configure LIBS="-lssl -lcrypto" && make && make install;
 cp etc-pam.d-shellinabox-example /etc/pam.d/shellinabox;
 cd /tmp; rm -Rf shellinabox )
