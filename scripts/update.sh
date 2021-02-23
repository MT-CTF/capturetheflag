#!/bin/bash

# Update capturetheflag
git pull

# Update all submodules
git submodule update --init --recursive

# Queue restart
if [[ -d ../../worlds/ctf ]]; then
	touch ../../worlds/ctf/queue_restart.txt
fi
