#!/bin/bash

# Update capturetheflag
git pull

# Update all submodules
git submodule update --init --recursive

# Run post-processing actions for maps
./setup_maps.sh

# Run build.sh
./build.sh ../games/capturetheflag

# Queue restart
if [[ -d ../worlds/ctf ]]; then
	touch ../worlds/ctf/queue_restart.txt
fi
