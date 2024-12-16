#!/bin/bash

MOD_PREFIX=mtg_
MODS_TO_KEEP=(binoculars bucket butterflies creative default doors dye fire fireflies flowers map player_api screwdriver sfinv stairs tnt vessels walls wool xpanes)

cd "$(dirname "$0")/../mods/mtg/"

if [ ! -f ./modpack.conf ]; then
	echo "May have changed into the wrong directory, aborting."
	exit
fi

git clone git@github.com:minetest/minetest_game.git
echo ""

mv ./minetest_game/mods .

echo "Updating mods..."

for mod in "${MODS_TO_KEEP[@]}"; do
	rm -r "${MOD_PREFIX}${mod}/";
	mv "mods/${mod}" "${MOD_PREFIX}${mod}";
done

echo "Done. Removing unneeded folders..."

rm -r ./mods

rm -rf ./minetest_game

echo "Done. minetest_game mods are updated!"

echo ""
echo "Applying redef mod..."

rm -r ./redef

echo ""
git clone https://git.0x7be.net/dirk/redef.git
echo ""

rm -rf ./redef/.git

sed -i -e "s/\['Maximum Stack Size'\]/--\['Maximum Stack Size'\]/g" ./redef/init.lua # Comment out the stack size change
sed -i -e "s/\['Grass Box Height'\]/--\['Grass Box Height'\]/g" ./redef/init.lua # Comment out the stack size change

echo "Done. redef applied!"