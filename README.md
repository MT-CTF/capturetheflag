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

## FAQ

### 1. Why mobs aren't added?

Mobs have been suggusted from very early days of CTF from several. The question has always been no. The short answer is that mobs use a lot of resources without adding much gameplay. The longer answer is that smart mobs usually require a lot of CPU, the network usage is high. The same resource could be allocated to more players who add much more to the gameplay comparing to mobs. However, there are many unofficial servers which might have mods, you can play there if you like them. Or, since CTF is FOSS, free open source software, you can fork it and do whatever you like. Maybe you could prove the developers they are wrong by adding efficient *and* smart mobs :)

### 2. I'm trying to run a CTF server but it crashes soon after it gets started.

If you are having a small VPS, like with 2GB of RAM, it is likely that the crash is because of lack of memory. You can turn `ctf_low_ram_mode` on my setting it to `true` in your `minetest.conf` file(or whatever your config file name is) to solve the issue.

### 3. I want to host a CTF public server with X players. How much resources do I need?

TBD

### 4. I have started a server but rankings don't persist.

That's because they are not saved in somewhere persistant. Launch a Redis instance and configure `ctf_rankings_backend` to `redis` and `ctf_rankings_server_port` to your instance's port on localhost.

## Starting a game (GUI instructions)
* Create a new `singlenode` world
* Turn on `Enable Damage` and `Host Server`, turn off `Creative Mode`, *memorize* your port
* Click `Host Game`, a round should automatically start as soon as you join in
* Players on your LAN can join using your local IP and the port you *memorize*d

## Development

* ### [WIP CTF API DOCS](docs/ctf-api.md)
* If you use Visual Studio Code we recommend these extensions:
  * https://marketplace.visualstudio.com/items?itemName=sumneko.lua
  * https://marketplace.visualstudio.com/items?itemName=dwenegar.vscode-luacheck

## License

Created by [rubenwardy](https://rubenwardy.com/).
Developed by [LandarVargan](https://github.com/LoneWolfHT).
Previous Developers: [savilli](https://github.com/savilli).

Check out [mods/](mods/) to see all the installed mods and their respective licenses.

Licenses where not specified:
Code: LGPLv2.1+
Textures: CC-BY-SA 3.0

### Textures

* [Header](menu/header.png): CC-BY-3.0 by [SuddenSFD](https://github.com/SuddenSFD)
* [Background Image](menu/background.png): CC BY-SA 4.0 (where applicable) by [GreenBlob](https://github.com/a-blob) (Uses [Minetest Game](https://github.com/minetest/minetest_game) textures, the majority of which are licensed CC-BY-SA 3.0). The player skins used are licensed CC-BY-SA 3.0
* [Icon](menu/icon.png): CC-BY-3.0 by [SuddenSFD](https://github.com/SuddenSFD)
