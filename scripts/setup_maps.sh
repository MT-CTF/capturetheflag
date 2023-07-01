#!/bin/bash
set -e

# Go back if we're inside the scripts folder
if [ -f setup_maps.sh ]; then
	cd ..
fi

cd mods/ctf/ctf_map/maps/

# Copy textures from map sub-dirs to ctf_map_core/textures
for f in *; do
	if [ -d ${f} ]; then
		# Copy map screenshot to textures dir
		if [ -f ${f}/screenshot.png ]; then
			cp ${f}/screenshot.png ../textures/${f}_screenshot.png
		fi

		# Move skybox textures into map skybox folder if they aren't already there
		if [ -f ${f}/skybox_1.png ]; then
			if ![ -d ${f}/skybox/ ]; then
				mkdir ${f}/skybox/
			fi

			cp ${f}/skybox_1.png ${f}/skybox/Up.png
			cp ${f}/skybox_2.png ${f}/skybox/Down.png
			cp ${f}/skybox_3.png ${f}/skybox/Front.png
			cp ${f}/skybox_4.png ${f}/skybox/Back.png
			cp ${f}/skybox_5.png ${f}/skybox/Left.png
			cp ${f}/skybox_6.png ${f}/skybox/Right.png
			rm ${f}/skybox_*.png
		fi

		# Move skybox textures to textures dir where Minetest can find them
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
