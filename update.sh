git pull &&
cd mods/ctf_pvp_engine &&
git pull origin master &&
cd ../crafting &&
git pull origin master &&
cd ../ctf/ctf_map/maps &&
git pull origin master &&
cd ../../.. &&
./build.sh ../games/capturetheflag
