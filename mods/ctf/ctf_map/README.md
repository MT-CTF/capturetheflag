# CTF Map - Map maker

## Creating a new map

### 1. Dependencies

- Minetest 5.0.0 or later (https://minetest.net/)
- `Capture the Flag` game (https://content.minetest.net/packages/rubenwardy/capturetheflag/)
- *Optional:* `worldedit` (https://content.minetest.net/packages/sfan5/worldedit/)

### 2. Create the world

1. Select the `Capture the Flag` subgame.
2. Create a new world. You can select any mapgen you like.
3. Enable creative mode. This will enable `mapedit` mode.
4. *Optional:* Enable `worldedit`

> You can grant yourself the `ctf_map_editor` privilege by running `/grantme ctf_map_editor` or by running `/grantme all` which grants you all the privileges that will be useful for map making.

###  3. Selecting the Map Area

Decide where you will build your map. We recommend you don't make your map larger than 230x230x230 blocks.
1. Run `ctf_map editor` 
2. Press `Create New Map`
3. Select a position to be one corner of the map.
4. Select a position in the opposite corner. Place it higher/lower than the first one to give the map height.
**Note:** you can change your map area at any time by typing `/ctf_map editor` and pressing the "Corners" button.

### 4. Build

- You could add
	- buildings
	- lakes
	- hills
	- etc.
- Many blocks have an indestructible variant
- Don't forget to add
	- Team chests
	- Indestructible blocks under the flag. The minimum is 5x5 blocks, with the flag on top of them in the center.
	- "Indestructible Barrier Glass" (`ctf_map:ind_glass`) around the sides of the world (You don't need it on the ceiling)
	- "Indestructible Red Barrier Glass" (`ctf_map:ind_glass_red`) for the build-time wall. This will disappear once the match begins. (More on that later)
	- "Indestructible Red Barrier Stone" (`ctf_map:ind_stone_red`) for underground build-time wall. This will turn into stone(`default:stone`) once the match begins. (More on that below)

The positions the `Indestructible Red Barrier` and the `Indestructible Red Barrier Stone` are automatically calculated when you save the map. 
If you wish to save your map for later edits, follow the note in the section about exporting the map.

### 5. Fill out information about the map

Run `/ctf_map editor`.
An explanation of some of the fields is given below.

#### Map Enabled
Whether or not the map is available for play. You will want to make sure it's enabled.

#### License
* Every map must have its own license.
* You can append any attribution you need to give to the `license` field (For example: If you modified someone's map or used one of their builds you'd list their name and what map/build of theirs that you modified/used). If you want to give more information, you can use the `Other info` field.
* If you don't know which license to use, [this list of CC licenses](https://creativecommons.org/use-remix/cc-licenses/) can help you.
* We can only accept the free culture licenses like `CC BY-SA 4.0`. Note that not all licenses in the Creative Commons family are free(as in freedom) (e.g `CC BY-ND`).
* Please make sure you know what you are doing when choosing a license. You could do a little research about various licenses, ask a parent for help if you're young and haven't dealt with licenses before, and/or consult a lawyer.

#### Map Hint
Does your map have hidden treasures? You can hint about them with the "Map Hint" field.

#### Treasures *(optional)*
A list of treasures that can be added specifically for your map that don't end up in chests by default.

Format:
```
[name];[min_count];[max_count];[max_stacks];[rarity];[TREASURE_VERSION];
```

* `rarity` is a value between 0 and 1 specifying the probability it will be added to a chest.
* `TREASURE_VERSION` should currently be set to one.

Example:
```
default:lava_source;1;10;1;0.2;1;default:water_source;1;10;1;0.2;1;
```

#### Map Initial Stuff
`initial_stuff` are the items given to players at their (re)spawn. The `initial_stuff` field is located in the `map.conf` file. At least a pickaxe and some torches should be given in the map's `initial_stuff`.

An example of `initial_stuff` value that registers a stone pickaxe, 30 cobblestones, 5 torches and a pistol is given below.

```
default:pick_stone,default:cobble 30,default:torch 5,ctf_ranged:pistol_loaded
```

#### Map Constants
1. `Map Shadow Intensity`: Sets the intensity of the shadows.
2. `Map Gravity`: Gravitational constant of the map. (default = 1)
3. `Map Movement Speed`: Regulates the speed at which players move. (default = 1)
4. `Map Jump Height`: Regulates the height of jumps. (default = 1)
5. `Map start_time`: Sets time of the day the match begins at. Changing this field will instantly update the time of day in the world you are editing.
	* `0` is for midnight
	* `1000` is for 1 AM
	* `2000` is for 2 AM
	* etc.

#### Flag Positions
Positions where team flags are placed. You can select the teams that you want on the map and place the flags accordingly. 

#### Zone Bounds
How far the players of a certain team may go during build time. The zone bounds should overlap at the Red Barrier wall.

> **Note:** Even players standing on the edge of their team zone are sent back to their base. It doesn't just trigger when they go beyond it.

#### Chest Zones
Areas where treasure chests are placed. Some maps have treasure chests placed throughout the entire map, while others only have them placed in certain small areas/rooms. What you choose for your map is up to you.

### 6. Map Saving

#### Saving your changes
* Run `/ctf_map editor` and press "Finish Editing" after scrolling to the bottom

#### Moving your map to where CTF can load it
* Find the exported map located in <ins>your map editor save folder</ins>`[Minetest folder]/worlds/[Map World]/schems/[Exported Map folder]`
* Move the exported map folder to the <ins>CTF map folder</ins> `[Minetest folder]/games/capturetheflag/mods/ctf/ctf_map/maps`.

#### Resuming editing
Once you've moved your map once (See above) you can make edits to your map without having to move it again by running `/ctf_map editor`, clicking on your map in the list of maps, and then pressing `Resume Editing`, which tells CTF not to use the blocks in the map you copied to the <ins>CTF map folder</ins>.
* Any changes you make to the `/ctf_map editor` gui (chest zones, etc) won't apply. You have to copy the map for that.
* If you accidentally press `Start Editing` instead of `Resume Editing` you need to close the game without saving *copy your map to where CTF can load it* (See above). Otherwise your changes will be lost, because `Start Editing` tells CTF to use the blocks in the map you moved to the <ins>CTF map folder</ins>, which will be outdated if you've made changes since you last moved your map over.

### 7. Play

1. Create a new world with the `singlenode` mapgen.
2. Make sure creative mode is disabled before joining
3. Grant yourself `ctf_admin` by issuing `/grantme ctf_admin`
4. Run `/ctf_next -f <map_name>` Using your map's folder (or technical) name instead of `<map_name>`

### 8. Screenshot

If you choose to submit your map, include a screenshot of it in the exported map's folder. It should be taken without any texture packs enabled and must have an aspect ratio of 3:2 (screenshot `600px`x`400px` is suggested).

You can take a screenshot easily by doing the following:
1. Hide the HUD. By default <kbd>F1</kbd> does that.
2. Hide the chat log. By default <kbd>F2</kbd> does that.
3. See if your screenshot looks better with/without fog enabled. You can toggle it with <kbd>F3</kbd> by default
4. Try to find a good view that shows most of the map.
5. *(Optional)* Increase your view range if important parts of the map cannot be seen. By default the <kbd>=</kbd> (or <kbd>+</kbd>) and <kbd>-</kbd> keys do that.
6. Take a screenshot **from Minetest**. By default <kbd>F12</kbd> does that.
7. You can find the screenshot in `[Minetest folder]/screenshots` unless you have changed the path in settings.

Crop the screenshot into the aspect ratio mentioned above using a tool of your choice, and put the screenshot inside your exported map's folder. It should be named `screenshot.png`.

### 9. Submission

> Your PR should contain the Map Folder that should include the files `map.conf`, `map.mts`, and `screenshot.png`.

Maps can be submitted to the CTF Maps repository through PRs (Pull Requests). If you don't know how to make them, you could ask someone else to make it for you or make your own GitHub account and make it yourself. A benefit of making it on your own is that you can actively engage in the testing and development of the map PR. If you are new to making PRs and forks, you can learn about them by reading these documentations:
- [https://docs.github.com/en/get-started/quickstart/fork-a-repo](https://docs.github.com/en/get-started/quickstart/fork-a-repo "https://docs.github.com/en/get-started/quickstart/fork-a-repo") 
- [https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork "https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork")

If you are creating the PR yourself, it is always better to make each PR on a different branch of your fork of the repo. For example if you want to add a map, then make a separate branch for it, and so on. This will obviate and possible conflicts with any of your already open PRs.  
