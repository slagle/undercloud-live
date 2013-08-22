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

# This provides the unbuffer command
sudo yum -y install expect

unbuffer $(dirname $0)/undercloud-install.sh 2>&1 | tee -a $LOG
unbuffer $(dirname $0)/undercloud-configure.sh 2>&1 | tee -a $LOG
unbuffer $(dirname $0)/undercloud-network.sh 2>&1 | tee -a $LOG

# starts all services and runs os-refresh-config (via os-collect-config
# service)
unbuffer sudo systemctl daemon-reload 2>&1 | tee -a $LOG
unbuffer sudo os-refresh-config 2>&1 | tee -a $LOG

unbuffer $(dirname $0)/undercloud-setup.sh 2>&1 | tee -a $LOG

echo "undercloud.sh run complete."
