# Capture The Flag

[![ContentDB](https://content.minetest.net/packages/rubenwardy/capturetheflag/shields/downloads/)](https://content.minetest.net/packages/rubenwardy/capturetheflag/)  [![Build status](https://github.com/MT-CTF/capturetheflag/workflows/build/badge.svg)](https://github.com/MT-CTF/capturetheflag/actions)


## Installation

### Git

Capture the flag uses several submodules. Make sure to grab them all by cloning like this:

```sh
git clone --recursive https://github.com/MT-CTF/capturetheflag.git
```
(Using ssh to clone is recommended for developers/contributors)

### ContentDB

Simply download the game with the ingame content browser.
Note that this version may be slightly behind the git version, but it will be a little more stable.

## Recommended Setup

* Hosting your server using the `dummy` backend.

### For public servers:
* Storing rankings using the `redis` backend, all steps are required:
  * Install redis, luarocks, and luaredis (Ubuntu)
    * `sudo apt install luarocks redis`
    * `sudo luarocks install luaredis`
  * Add `ctf_rankings` to your `secure.trusted_mods`
	* Make sure you don't add any malicious mods to your server. **It is possible they can breach the sandbox through `ctf_rankings` when it is a trusted mod**
  * Run something like this when starting your server: `(cd minetest/worlds/yourworld && redis-server) | <command to launch your minetest server>`
    * If you run your Minetest server using a system service it is recommended to run redis-server on a seperate service, with the Minetest service depending upon it

## Starting a game (GUI instructions)
* Create a new `singlenode` world
* Turn on `Enable Damage` and `Host Server`, turn off `Creative Mode`, *memorize* your port
* Click `Host Game`, a round should automatically start as soon as you join in
* Players on your LAN can join using your local IP and the port you *memorize*d

## Development

* If you use Visual Studio Code we recommend these extensions:
  * https://marketplace.visualstudio.com/items?itemName=sumneko.lua
  * https://marketplace.visualstudio.com/items?itemName=dwenegar.vscode-luacheck

## License

Created by [rubenwardy](https://rubenwardy.com/).
Developed by [LandarVargan](https://github.com/LoneWolfHT).
Previous Developers: [savilli](https://github.com/savilli).

Licenses where not specified:
Code: LGPLv2.1+
Textures: CC-BY-SA 3.0

### Textures

* [Header](menu/header.png): CC BY-SA 4.0 by xenonca
* [Background Image](menu/background.png): CC0 (where applicable) by Apelta (Uses [Minetest Game](https://github.com/minetest/minetest_game) textures, the majority of which are licensed CC-BY-SA 3.0). The player skin used is licensed CC-BY-SA 3.0

### Mods

Check out [mods/](mods/) to see all the installed mods and their respective licenses.
