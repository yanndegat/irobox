# Global Architure

WIP!


Keystone
--------

Keystone is the service which is responsible for:

- global user / project /roles management.
- Service API catalog. (e.g.: "Q: where/what is my image api? A: glance at http://1.2.3.4/v1 ") 

Keystone is just an wsgi api behind an apache server. It's setup with its own Db service (mariadb) and cache service (memcached).
Notifications are not enabled on keystone.

Here, there's a list of post setup scripts to automatically register all services and create a super user.

- `keystone/bin/post-setup.sh`
- `glance/bin/keystone-post-setup.sh`
- `ironic/bin/keystone-post-setup.sh`
- `neutron/bin/keystone-post-setup.sh`


Glance
------

Glance is a cloud image registy service (not to be confused with a docker image service).

Glance is just an wsgi api behind an apache server. It's setup with its own Db service (mariadb) and cache service (memcached).
Notifications are not enabled on glance.

Here, glance is setup to store its images on the controller filesystem. (as opposed to a typical glance deployment where images are usely
stored in a swift container).

Images are served by glance on http, and ironic and its conductor service will cache the files locally. So images may be stored twice on the same fs at some point in time.

4 images a preloaded in glance by a post-setup script (`glance/bin/post-setup.sh`):

- debian11: so you have an image to test your deployments
- a prebuilt [ironic python agent](https://docs.openstack.org/ironic-python-agent/latest/) kernel image 
- a prebuilt [ironic python agent](https://docs.openstack.org/ironic-python-agent/latest/) ramdisk image
- the previous IPA ramdisk hacked so that your ssh pub key is injected into it. This is useful if you want to ssh into the IPA for debugging purposes (when the host is in manageable state.)

The IPA prebuilt is done by metal3, and the download is done through the use of their "quay.io/metal3-io/ironic-ipa-downloader:main" docker image.
You may want to use your own prebuilt/downloader. If so, you have to hack the `glance/docker-compose.yml` file to replace the `ipa-downloader` service
by your own impl.

Horizon
-------

Horizon is the official openstack UI. There's a new kid on the block (skyline) with a more modern UI, but it's harder to deploy, and ironic features
aren't yet available.

Even on horizon with the additional ironic-ui package installed, all ironic features aren't available through the UI and you may prefer the use of a proper CLI.

Horizon is just an wsgi service behind an apache server. It's setup with its own cache service (memcached).


Ironic
------

Ironic is the baremetal controller.

It's composed of several micro services:

- a wsgi api behind an apache server
- a conductor agent which is the main service which manage/pilots the baremetal hosts.
- a dnsmasq service which will act as a dhcp + tftp service for PXE boots.
- an inspector service, which is mainly an API that the baremetal hosts will contact to send their introspection infos (netifs, harddisks, cpus, ...).
  superficial quick summary: when a host is in `manageable` state, the conductor has generated an ipxe config containing the
  inspector API endpoint and booted the host with the "Ironic-Python-Agent" ramdisk image (stored in glance). When a host inspection is requested
  through the api, the IPA collects info about the host and sends them to the inspector API, which are then stored into the inspector's own DB.
- a log-watch service on which the IPA is supposed to send its logs.
  
  
  cf: [ironic state machine](https://docs.openstack.org/ironic/latest/_images/states.svg)


The API and conductor share their Db service (mariadb) and cache service (memcached).
The inspector has its own db service (mariadb).

In a typical openstack deployment, the API contacts the conductor by making RPC calls through the use of a rabbitmq message bus.
Here, in the setup made by metal3, these RPC calls are based on a json-rpc implementation. (cf https://github.com/metal3-io/ironic-image)

In a typical openstack deployment, authentication and authorizations are realized through the integration of the keystone service.
Here, we keep the choice of metal3 to leave ironic in a noauth strategy because at some point in time, we'd like to see if metal3 baremetal-operator
could be used with this setup.

Notifications are enabled on ironic and they are sent to a kafka broker, deployed by the `dicious` service.


Neutron
-------

WIP

it's still very obscure what has to be done on the neutron + ironic neutron integration setups.

see `doc/networking.md`.

Dicious
-------

Dicious is a small embedded golang project which collects some ironic notifications and stores them in a local sqlite db.
The main goal behind this small service is to see if some could eventually build a complete external system which would rely on 
info collected from several ironic deployments.

The example usecase here is: have a searcheable central db (per host, per rack, per switch, per ip, ... ) to know where (in which rack, room, ironic deployment) a host is localed.

We typically identified that ironic doesn't send region info in notifications messages, and that oslo.messaging[kafka] is lacking the integration of the kafka header feature which could have serve this purpose.


Ironic standalone vs Nova
-------------------------

Ironic is kept in a standalone mode on purpose. One of the goal is to see if metal3 baremetal operator could make use of such ironic deployment.


CLI(s)
-----

The setup comes with a small helper script to have access to the baremetal API:

```sh
./baremetal help
```

But there are plenty other CLIs you could use and for which there's no helper script (yet).

one typical hack i use is:

```sh
docker exec -it keystone_api_1 bash
source admin_openrc.sh
openstack catalog list
...
pip3 install python-ironicclient metalsmith
...
openstack baremetal node list
...
metalsmith deploy --help
```


Makefiles & docker-compose & hacks
--------------------------

all makefiles are mostly wrap ups around docker-compose commands.

The root makefile calls makefiles in the subdirectories.

They are useful to have everything up quickly. But it's often more efficient to directly
use the docker-compose / docker CLIs.

Examples:

1. boot only glance
  ```sh 
  make glance-up
  ```
1. clean neutron dbs
  ```sh 
  make neutron-down neutron-clean # will kill neutron containers & rm docker volumes
  ```
1. logs keystone

```sh
cd keystone
docker-compose logs -f api
```
or

```sh
docker logs -f keytone_api_1
```

1. hack a python script

```sh 
docker exec -it ironic_api_1 bash
apt update && apt install -y vim
vi ....
exit
docker restart ironic_api_1
```

Ironic from source
------------------

There's a specific hack for ironic:

We run a docker image based on [metal3 ironic-image](https://github.com/metal3-io/ironic-image), 
and if the `vars/ironic.env`:`IRONIC_DEV_MODE` is set to `true`, we git clone:
- IRONIC_LIB_REPO="https://opendev.org/openstack/ironic-lib.git"
- IRONIC_REPO="https://opendev.org/openstack/ironic.git"
- IRONIC_INSPECTOR_REPO="https://opendev.org/openstack/ironic-inspector.git"

and pip install them instead of the package pre installed in the image.

