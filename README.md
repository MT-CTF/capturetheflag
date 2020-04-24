# Capture The Flag
[![Build Status](https://travis-ci.org/MT-CTF/capturetheflag.svg?branch=master)](https://travis-ci.org/MT-CTF/capturetheflag)

* Fast rounds of CTF games.
* Removed nodes for focus.

## Installation

Capture the flag uses several submodules. Make sure to grab them all by cloning like this:

```sh
git clone --recursive https://github.com/MT-CTF/capturetheflag.git
```

## System Requirements

### Recommended

Hosting your server using the `dummy` backend.

### Minimum

Hosting your server using the `leveldb` or `redis` backend.

Hosting using `sqlite3` on an SSD or ramdisk ([with this guide](https://forum.minetest.net/viewtopic.php?f=10&t=9588)).

## License

Created by [rubenwardy](https://rubenwardy.com/).
Code: LGPLv2.1+
Textures: CC-BY-SA 3.0

### Textures

* ctf_classes_skin_* created by GreenDimond/GreenXenith
    * ctf_classes_skin_rocketeer with help from Lone_Wolf

### Mods

Check out [mods/](mods/) to see all the installed mods and their respective licenses.

## update.sh

Content in this repository and its sub-modules are arranged in a manner best optimised for distribution. For all features of CTF to work properly, run update.sh instead of manually syncing the local copy. update.sh automatically pulls the latest master of the repository and all its submodules, and does some extra processing to make stuff work.
