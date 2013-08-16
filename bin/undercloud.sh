#!/bin/bash

set -eux

$(dirname $0)/undercloud-install.sh
$(dirname $0)/undercloud-configure.sh

# starts all services and runs os-refresh-config (via os-collect-config
# service)
sudo systemctl daemon-reload
sudo systemctl isolate multi-user.target

# Wait for os-collect-config (os-refresh-config) to finish.
while true; do
    systemctl show os-collect-config | grep Result=success
    rc=$?
    if [ $rc -eq 0 ]; then
        break
    fi
    echo "os-collect-config not yet done, sleeping..."
    sleep 10
done

# Download images
$(dirname $0)/undercloud-images.sh
$(dirname $0)/undercloud-setup.sh
