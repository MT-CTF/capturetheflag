<p align="center">
 <img width="100px" src="/menu/icon.png" align="center" alt="Capture the Flag" />
 <h1 align="center">Capture the Flag</h1>
 <p align="center">Combat the enemy with swords, guns, grenades, and more as you try to capture their flag before they capture yours!</p>
</p>
  <p align="center">
	<a href="https://content.minetest.net/packages/rubenwardy/capturetheflag/">
      <img alt="ContentDB" src="https://content.minetest.net/packages/rubenwardy/capturetheflag/shields/downloads/" />
    </a>
	<a href="[https://content.minetest.net/packages/rubenwardy/capturetheflag/](https://github.com/MT-CTF/capturetheflag/actions)">
      <img alt="Build Status" src="https://github.com/MT-CTF/capturetheflag/workflows/build/badge.svg" />
    </a>
    <a href="https://github.com/MT-CTF/capturetheflag/graphs/contributors">
      <img alt="GitHub Contributors" src="https://img.shields.io/github/contributors/MT-CTF/capturetheflag" />
    </a>
    <a href="https://github.com/MT-CTF/capturetheflag/issues">
      <img alt="Issues" src="https://img.shields.io/github/issues/MT-CTF/capturetheflag?color=0088ff" />
    </a>
    <a href="https://github.com/MT-CTF/capturetheflag/pulls">
      <img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/MT-CTF/capturetheflag?color=0088ff" />
    </a>
    <br />
    <br />
  </p>

  <p align="center">
	  <h4 align="center">Official Server</h4>
	  <p align="center">Address: <code>ctf.rubenwardy.com</code> Port: <code>30001</code></p>
   	  <p align="center" >You will need a Luanti (formerly Minetest) Client to join. </p>
  </p>

<hr>

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
Note that downloading from ContentDB will probably delete any existing CTF folder downloaded via git, unless you move it out of the Luanti `games` directory first.

## Recommended Setup

* [!] You should host your server using the `dummy` backend if it's not in mapedit mode, this will prevent Luanti from writing the map to disk, which speeds up map operations (and general server speed as a result) a lot, especially on HDDs.

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
* Players on your LAN can join using your local IP and the port you *memorize*d. You will have to port forward for other people on the internet to join

## Development

* CTF API Docs: Lua API Reference - [Link](docs/ctf-api.md)
* If you use Visual Studio Code we recommend these extensions:
  * https://marketplace.visualstudio.com/items?itemName=sumneko.lua
  * https://marketplace.visualstudio.com/items?itemName=dwenegar.vscode-luacheck
  * https://marketplace.visualstudio.com/items?itemName=GreenXenith.minetest-tools

## Contributing
* Contributions are always welcome! Please read the [contribution guidelines](CONTRIBUTING.md) first.

## License

Created by [rubenwardy](https://rubenwardy.com/).
Developed by [LandarVargan](https://github.com/LoneWolfHT).
Previous Developers: [savilli](https://github.com/savilli).

Check out [mods/](mods/) to see all the installed mods and their respective licenses.

Licenses where not specified:\
Code: [GNU LGPLv2.1+](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html)\
Media: [CC BY-SA 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/)

### Textures

* [Header](menu/header.png): [CC BY 3.0 Unported](https://creativecommons.org/licenses/by/3.0/) by [SuddenSFD](https://github.com/SuddenSFD)
* [Background Image](menu/background.png): [CC BY-SA 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/) (where applicable) by [GreenBlob](https://github.com/a-blob) (Uses [Minetest Game](https://github.com/minetest/minetest_game) textures, the majority of which are licensed [CC BY-SA 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/)). The player skins used are licensed under [CC BY-SA 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/)
* [Icon](menu/icon.png): [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) by [SuddenSFD](https://github.com/SuddenSFD)
