Networking setup
================

There's a lot of fog in the content of this file.

Requirements
------------

For your setup, you need at least 2 networks(nics?) on your control host:

- one network with internet access (netpub), on which you'll be able to ssh and to reach the APIs/horizon UI.
- one network to reach the hosts ipmi and switches control interface (netpriv), and on which the hosts will be inspected/rescued/provisioned.

The setup will launch an openvswitch service which will bridge the netpriv and launch dhcp services on this brigde.
As this project is more than just immature, it may completely take down your netpriv network interface. So be careful 
with this project, because if you mess netpub & netpriv, you may loose access to your host.

Useful links
------------

- small cloud design https://docs.openstack.org/ironic/latest/install/refarch/small-cloud-trusted-tenants.html#networking
- trunk api https://docs.openstack.org/api-ref/network/v2/index.html?expanded=show-trunk-details-detail#show-trunk-details
- generic switch https://docs.openstack.org/networking-generic-switch/latest/configuration.html
- netmiko https://github.com/ktbyers/netmiko
- neutron ml2 setup https://docs.openstack.org/neutron/latest/admin/config-ml2.html
- baremetal network setup https://docs.openstack.org/ironic/latest/admin/multitenancy.html
- baremetal network setup https://docs.openstack.org/ironic/latest/install/configure-networking.html
- baremetal network setup https://docs.openstack.org/networking-baremetal/latest/install/index.html
- baremetal network configure tenant networks https://docs.openstack.org/ironic/latest/install/configure-tenant-networks.html
- networking cisco https://networking-cisco.readthedocs.io/projects/test/en/latest/install/howto.html
- TheJulia genericswitch bifrost patch:
   - https://review.opendev.org/c/openstack/bifrost/+/452514/
   - https://review.opendev.org/c/openstack/bifrost/+/498271
   - https://review.opendev.org/c/openstack/bifrost/+/452515
   - https://review.opendev.org/c/openstack/bifrost/+/498972
