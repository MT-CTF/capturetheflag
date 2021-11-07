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
		if [ -d ${f}/skybox/ ]; then
			cp ${f}/skybox/Up.png    ../textures/${f}Up.png
			cp ${f}/skybox/Down.png  ../textures/${f}Down.png
			cp ${f}/skybox/Front.png ../textures/${f}Front.png
			cp ${f}/skybox/Back.png  ../textures/${f}Back.png
			cp ${f}/skybox/Left.png  ../textures/${f}Left.png
			cp ${f}/skybox/Right.png ../textures/${f}Right.png
		fi
	fi
done
