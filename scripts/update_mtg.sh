#!/bin/bash

MOD_PREFIX=mtg_
MODS_TO_KEEP=(binoculars bucket butterflies creative default doors dye fire fireflies flowers map player_api screwdriver sfinv stairs tnt vessels walls wool xpanes)

cd ../mods/mtg/ # Will work if we run from inside the scripts folder
cd mods/mtg/    # Will work if we run from inside the capturetheflag folder

git clone git@github.com:minetest/minetest_game.git

mv minetest_game/mods .

echo "Updating mods..."

for mod in "${MODS_TO_KEEP[@]}"; do
	rm -r "${MOD_PREFIX}${mod}/";
	mv "mods/${mod}" "${MOD_PREFIX}${mod}";
done

echo "Done. Removing unneeded folders..."

rm -r mods/

rm -rf minetest_game/

echo "Done. minetest_game mods are updated!"
