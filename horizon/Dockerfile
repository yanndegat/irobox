FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
  apache2 \
  gettext \
  git \
  libapache2-mod-wsgi-py3 \
  openstack-dashboard \
  python-is-python3 \
  python3 \
  python3-pip \
  python3-ironic-ui \
  && pip3 install python-ironicclient==2.8.0 \
  && rm -Rf /usr/lib/python3/dist-packages/ironicclient \
  && cp -Rf /usr/local/lib/python3.8/dist-packages/ironicclient /usr/lib/python3.8/site-packages/
#  && pip3 install --upgrade horizon \
#  && pip3 install --upgrade ironic-ui \


ENTRYPOINT ["/usr/bin/bash"]
