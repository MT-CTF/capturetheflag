git pull &&
cd mods/crafting &&
git pull origin master &&
cd ../ctf/ctf_map/maps &&
git pull origin master &&
cp ./*.png ../textures/ &&
cd ../../../.. &&
./build.sh ../games/capturetheflag
