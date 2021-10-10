#!/bin/bash
set -e

cd mods/ctf/ctf_map/maps/

# Copy textures from map sub-dirs to ctf_map_core/textures
for f in *; do
	if [ -d ${f} ]; then
		# Screenshot
		if [ -f ${f}/screenshot.png ]; then
			cp ${f}/screenshot.png ../textures/${f}_screenshot.png
		fi

		# Skybox textures
		if [ -f ${f}/skybox_1.png ]; then
			cp ${f}/skybox_1.png ../textures/${f}_skybox_1.png
			cp ${f}/skybox_2.png ../textures/${f}_skybox_2.png
			cp ${f}/skybox_3.png ../textures/${f}_skybox_3.png
			cp ${f}/skybox_4.png ../textures/${f}_skybox_4.png
			cp ${f}/skybox_5.png ../textures/${f}_skybox_5.png
			cp ${f}/skybox_6.png ../textures/${f}_skybox_6.png
		fi
	fi
done
