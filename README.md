Irobox
======

This repo contains the files needed to run a standalone Ironic service easily.


Description
-----------

WIP!

This repo is based on the work done by the [metal3.io](https://github.com/metal3-io/ "metal3.io")_ project.

This is a wrap up of docker-compose.yml files to setup all useful openstack services in order to get a friendly ironic environment.

This includes:

- keystone for user management
- glance for image management
- horizon for UI
- neutron for networking management 
- dicious: golang example project to collect ironic notifications

_DISCLAIMER_: This is *NOT FOR PRODUCTION* :)

Pre-requisites
--------------

You need a installation of docker + docker-compose, and an ssh pub key.

Run Ironic 
----------

``` sh
git clone https://github.com/yanndegat/irobox
cd irobox
make up
...
./baremetal driver list
```

Access the horizon interface `http://YOURIP|localhost:8080/horizon/admin` 

logins are either `admin` or `superuser` (cf: `./docker-compose.env.sh`).
password is the same for all users:

```sh
awk -F= '/KEYSTONE_ADMIN_PASSWORD/ {print $2}' ironic/.env
```


Run Ironic from source
----------------------

You can easily run this ironic service from ironic source by editing the `vars/ironic.env` file:


``` ironic.env
...

IRONIC_DEV_MODE=true
IRONIC_VERSION=stable/xena
IRONIC_LIB_REPO="https://opendev.org/openstack/ironic-lib.git"
IRONIC_REPO="https://opendev.org/openstack/ironic.git"
IRONIC_INSPECTOR_REPO="https://opendev.org/openstack/ironic-inspector.git"
```


Hack openstack configuragion
-------------------------

Leverage `oslo.config` configuragion by environment variables.

Edit `vars/` env files and customize conf:

``` ironic.env
OS_DEFAULT__AUTH_STRATEGY=noauth
OS_DEFAULT__DEBUG=True
OS_DEFAULT__DEFAULT_BOOT_INTERFACE=ipxe
OS_DEFAULT__DEFAULT_DEPLOY_INTERFACE=direct
OS_DEFAULT__DEFAULT_INSPECT_INTERFACE=inspector
OS_DEFAULT__DEFAULT_NETWORK_INTERFACE=noop
OS_DEFAULT__ENABLED_BOOT_INTERFACES=ipxe
OS_DEFAULT__ENABLED_DEPLOY_INTERFACES=direct,fake
OS_DEFAULT__ENABLED_HARDWARE_TYPES=ipmi
OS_DEFAULT__ENABLED_INSPECT_INTERFACES=inspector
```

You can of course edit components conf files directly (e.g.: `./neutron/etc/plugins/ml2/ml2_conf.ini`)

Non Goals
----------

- HA deployment
- Production hardening
- kubernetes
- become an official openstack project

Motivation
----------

- have an easy setup for ironic dev/POCs.
- POC ironic+neutron to pilot baremetal hosts & TOR switches.
- maybe at some point, use a small ironic to pilot my NUCs & Pis at home.

Other (non)similar projects
---------------------------

There are many other similar projects which you could use to have an ironic environment, such as:

- [bifrost](https://opendev.org/openstack/bifrost) 
- [kayobe](https://opendev.org/openstack/kayobe)
- or even [devstack](https://opendev.org/openstack/devstack)

This project typically differs from these in:

- it's very opinionated, there's no feature that you can easily enable/disable without having to hack the code/conf.
- it's more like a quick way to boot ironic+neutron and hack it for POC environments.
- it's (at least in my opinion) much simpler to use than devstack for this single purpose.
