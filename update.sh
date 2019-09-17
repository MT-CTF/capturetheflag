# Update repo and submodules
git pull &&
git submodule update --init --recursive &&

# Copy map screenshots to ctf_map/textures
cd mods/ctf/ctf_map && cp maps/*.png textures/ &&

# Pre-process `ctf.setting` calls
cd ../../.. && ./build.sh ../games/capturetheflag
