#!/bin/bash

set -eux

mkdir -p $HOME/.undercloud-live
LOG=$HOME/.undercloud-live/undercloud.log

PIP_DOWNLOAD_CACHE=${PIP_DOWNLOAD_CACHE:-""}

if [ -z "$PIP_DOWNLOAD_CACHE" ]; then
    mkdir -p $HOME/.cache/pip
    PIP_DOWNLOAD_CACHE=$HOME/.cache/pip
    export PIP_DOWNLOAD_CACHE
fi

$(dirname $0)/undercloud-install.sh 2>&1 | tee -a $LOG
$(dirname $0)/undercloud-configure.sh 2>&1 | tee -a $LOG

# need to exec to pick up the new group
if ! id | grep libvirtd; then
    exec sudo su -l $USER $0
fi

$(dirname $0)/undercloud-network.sh 2>&1 | tee -a $LOG

# starts all services and runs os-refresh-config (via os-collect-config
# service)
sudo systemctl daemon-reload 2>&1 | tee -a $LOG
sudo os-refresh-config 2>&1 | tee -a $LOG

# Need to wait for services to finish coming up
sleep 10
$(dirname $0)/undercloud-setup.sh 2>&1 | tee -a $LOG

echo "undercloud.sh run complete."
