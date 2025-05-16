#!/bin/bash
set -e

# Go back if we're inside the scripts folder
if [ -f setup_maps.sh ]; then
	cd ..
fi

cd mods/ctf/ctf_map/maps/

for f in *; do
	if [ -d ${f} ]; then
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
	fi
done
