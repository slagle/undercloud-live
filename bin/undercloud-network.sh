#!/bin/bash

PUBLIC_INTERFACE=${PUBLIC_INTERFACE:-ucl0}

sudo sed -i "s/bridge name='brbm'/bridge name='br-ctlplane'/" /opt/stack/tripleo-incubator/templates/brbm.xml
/opt/stack/tripleo-incubator/scripts/setup-network

sudo ip link add $PUBLIC_INTERFACE type dummy
# init-neutron-ovs is also executed by os-refresh-config, but it's done here
# because we can stop and make sure it's done the right thing easier to debug,
# etc.
sudo init-neutron-ovs

