ARG BASE=openstackhelm/neutron:wallaby-ubuntu_focal

FROM $BASE

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y gcc librdkafka-dev && pip3 install "oslo.messaging[kafka]" networking-baremetal networking-generic-switch
