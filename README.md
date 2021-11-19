Irobox
======

This repo contains the files needed to run a standalone Ironic service easily.

Description
-----------

This repo is 100% based on the work done by the [metal3.io](https://github.com/metal3-io/ "metal3.io")_ project.

This is a simpe wrap up in a docker-compose.yml file.

_DISCLAIMER_: This is *NOT FOR PRODUCTION* :)

Pre-requisites
--------------

You need a installation of docker + docker-compose.

Run Ironic 
----------

``` sh
cd $HOME
mkdir -p src
cd src
git clone https://github.com/yanndegat/irobox
cd irobox
make .env up
./baremetal driver list
```

Run Ironic from source
----------------------

You can easily run this ironic service from ironic source.


``` sh
cd $HOME
mkdir -p src
cd src
git clone https://opendev.org/openstack/ironic
git clone https://github.com/yanndegat/irobox
cd irobox
export IRONIC_DEV_MODE=true
make .env up
```

_Note_: you can change ironic source dir by changing the env var `IRONIC_SRC_DIR` accordingly. 


Motivation
----------

- have an easy setup for ironic dev.
- maybe at some point, use a small ironic pilot my nucs at home.
