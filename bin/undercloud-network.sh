#!/bin/bash

PUBLIC_INTERFACE=${PUBLIC_INTERFACE:-ucl0}

sudo ip link add eth1 type dummy
# init-neutron-ovs is also executed by os-refresh-config, but it's done here
# because we can stop and make sure it's done the right thing easier to debug,
# etc.
sudo init-neutron-ovs

