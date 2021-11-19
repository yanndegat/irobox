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


Hack Ironic configuragion
-------------------------

Leverage `oslo.config` configuragion by environment variables.

Create an env file and customize ironic conf:

``` sh
cat > ironic-conf.env <<
OS_DEFAULT__AUTH_STRATEGY=noauth
OS_DEFAULT__DEBUG=True
OS_DEFAULT__DEFAULT_BOOT_INTERFACE=ipxe
OS_DEFAULT__DEFAULT_DEPLOY_INTERFACE=direct
OS_DEFAULT__DEFAULT_INSPECT_INTERFACE=inspector
OS_DEFAULT__DEFAULT_NETWORK_INTERFACE=noop
OS_DEFAULT__ENABLED_BOOT_INTERFACES=ipxe
OS_DEFAULT__ENABLED_DEPLOY_INTERFACES=direct,fake
OS_DEFAULT__ENABLED_HARDWARE_TYPES=ovhapi
OS_DEFAULT__ENABLED_INSPECT_INTERFACES=inspector
EOF
```

Then export the following variable and make up again.

``` sh
export IRONIC_EXTRA_VARS=./ironic-conf.env
make .env up
```


Motivation
----------

- have an easy setup for ironic dev.
- maybe at some point, use a small ironic pilot my nucs at home.
