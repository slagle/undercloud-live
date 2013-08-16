#!/bin/bash

set -eux

$(dirname $0)/undercloud-install.sh
$(dirname $0)/undercloud-configure.sh
$(dirname $0)/undercloud-network.sh

# starts all services and runs os-refresh-config (via os-collect-config
# service)
sudo systemctl daemon-reload
sudo os-refresh-config

# Download images
$(dirname $0)/undercloud-images.sh
$(dirname $0)/undercloud-setup.sh
