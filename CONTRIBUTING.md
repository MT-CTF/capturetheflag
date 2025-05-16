# Getting Started

It's pretty easy to set-up a local server in order to test and contribute to the development of this game.
The game engine used is [Luanti](https://www.luanti.org/), a free, open source game engine formerly known as Minetest.

It's recommended to use [Visual Studio Code](https://code.visualstudio.com/download) as a code editor, it also gives you a basic GUI for using git, which is required to make contributions.
If you use Visual Studio Code we recommend these extensions:
- https://marketplace.visualstudio.com/items?itemName=sumneko.lua
- https://marketplace.visualstudio.com/items?itemName=dwenegar.vscode-luacheck
- https://marketplace.visualstudio.com/items?itemName=GreenXenith.minetest-tools

### Fork Project
- You can create a clone of the project by using git from the CLI. The `--recursive` option is important, as that fetches submodules (external mods/apis that CTF uses)
- You should perform the git clone inside your Luanti `games` folder. That way it will show up in your Luanti client. Note that this will interfere with downloading CTF from the ContentDB
```
git clone --recursive https://github.com/MT-CTF/capturetheflag.git
```
(Using ssh to clone is recommended for developers/contributors)

- If you don't want to use a CLI and want a more beginner-friendly GUI interface you could try using [Github Desktop](https://github.com/apps/desktop).

# Getting Involved
### Report Issues
If you encounter any problems you can report them on our GitHub issue tracker. In the case of problems like game crashes it would be really helpful if you provided game logs (debug.txt).

### Contribute
The main programming language used is Lua, feel free to create patches and propose them by making a pull request on Github. You should look around on the GitHub Issue tracker for open issues or the `#suggestions-note` channel on Discord to implement new features in the game. When contributing from suggestions in the Discord server, please make sure the suggestion is not controversial, and has at least 10 stars (With 'X's subtracted).
You can join the Discord server [here](https://discord.gg/vcZTRPX). If you are a new contributor, feel free to ask the other fellow devs any questions you have.
If you are just starting out, you can begin with making pull requests that only fix minor bugs, which is much easier to do than submitting a major feature/bugfix.

### New Maps
More into design than coding? No worries, you can still help us out by creating new unique and fun maps. The maps are present on a seperate [Github Repository](https://github.com/MT-CTF/maps/)

Here are a few resources to get you started with map making:
- Map Makers Readme: https://github.com/MT-CTF/capturetheflag/tree/master/mods/ctf/ctf_map
- A more detailed Handbook: https://ctf-handbooks.github.io/

# Contribution Guidelines
Please ensure your pull request adheres to the following guidelines:
* Search for previous suggestions/pull requests before making a new one, as yours may be a duplicate.
* Make an individual pull request for each suggestion/bug fix.
* Improvements to the existing code are welcome.
* Check your spelling and grammar.
* Make sure your code editor is set to
  * Remove trailing whitespace
  * Indent with tabs (not spaces)
* When creating a pull request based on a Discord suggestion, please include the message URL and optionally a screenshot of the message in your pull request. Ensure that it's not controversial and has at least 10 stars (With 'X's subtracted) before working on it.

Thank you for your time!

You can also help out the project by ★ starring this repository on Github.
