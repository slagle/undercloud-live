#!/bin/bash

set -eux

$(dirname $0)/undercloud-install.sh
$(dirname $0)/undercloud-init.sh
