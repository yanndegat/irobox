ARG BASE=quay.io/metal3-io/ironic:main

FROM $BASE

ARG IRONIC_DEV_MODE=false
ARG IRONIC_VERSION=master
ARG IRONIC_LIB_REPO https://opendev.org/openstack/ironic-lib.git
ARG IRONIC_REPO https://opendev.org/openstack/ironic.git
ARG IRONIC_INSPECTOR_REPO https://opendev.org/openstack/ironic-inspector.git

ADD bin/image-customize.sh /tmp

RUN /tmp/image-customize.sh
