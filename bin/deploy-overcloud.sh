#!/bin/bash

set -eux

source $HOME/undercloudrc

heat stack-create -f /opt/stack/tripleo-heat-templates/overcloud.yaml overcloud
