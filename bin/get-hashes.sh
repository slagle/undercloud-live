#!/bin/bash

set -eu

STACK_DIR=/opt/stack

repos=$(for d in `find $STACK_DIR -type d -name .git`; do basename `dirname $d`; done)

for repo in $repos; do
    echo "found git repo at $STACK_DIR/$repo"

    pushd $STACK_DIR/$repo

    hash=$(git log -1 --format=format:"%H")
    echo "$repo $hash"
    remote=$(git remote show -n origin | grep 'Fetch URL' | awk '{print $3}')

    if [ -d $remote ]; then
        pushd $remote
        remote=$(git remote show -n origin | grep 'Fetch URL' | awk '{print $3}')
        popd
    fi

    src_repo_file=$STACK_DIR/tripleo-image-elements/elements/$repo/source-repository-$repo

    if [ -f $src_repo_file ]; then
        echo "saving hash in tripleo-image-elements"
        echo $repo git $STACK_DIR/$repo $remote $hash > $src_repo_file
    else
        echo "repo not found in tripleo-image-elements"
    fi

    popd

    echo
done
