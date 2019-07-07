# Update capturetheflag
git pull

# Update crafting submodule
cd mods/crafting
git pull origin master

# Update maps submodule
cd ../ctf/ctf_map/maps
git pull origin master

# Run post-processing actions for maps
cd ../../../..
./setup_maps.sh

# Run build.sh
./build.sh ../games/capturetheflag
