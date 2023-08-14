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

Decide where you will build your map. The area can be maximum 230x230 blocks in surface area, but it can be lesser.
1. Run `ctf_map editor` 
2. Press `Create New Map`
3. Select a position to be one corner of the map.
4. Select a position in the opposite corner. Place it higher/lower than the first one to give the map height.
**Note:** you can change your area at any time by typing `/ctf_map editor` and pressing the "Corners" button.

### 4. Build

- You could add
	- buildings
	- lakes
	- hills
	- etc.
- Many blocks have an indestructible variant
- Don't forget to add
	- Team chests
	- Indestructible blocks under the flag. The minimum is 5x5 blocks in surface area.
	- "Indestructible Barrier Glass" (`ctf_map:ind_glass`) around the edge of the world.
	- "Indestructible Red Barrier Glass" (`ctf_map:ind_glass_red`) for the build-time wall. This will disappear once the match begins.
	- "Indestructible Red Barrier Stone" (`ctf_map:ind_stone_red`) for underground build-time wall. This will turn to stone(`default:stone`) once the match begins.

If you wish to save your map for later edits, follow the note in the section about exporting the map.

### 5. Fill out information about the map

Run `/ctf_map editor`.
An explanation of some of the fields is given below.

#### Map Enabled
Whether or not the map is available for play. You will want to check this.

#### License
* Every map must have its own license.
* If attribution is required (for example if you modify other's map and you have to tell who is author of the original map), that has to be appended to the `license` field.
If you want to give more information, you can use the `Other info` field.
* If you don't know which license to use, [this list of CC licenses](https://creativecommons.org/use-remix/cc-licenses/) can help you.
* We can only accept the free culture licences like `CC BY-SA 4.0`. Note that not licences in the Creative Commons family are free(as in freedom). For instance those with `ND` are not.
* Please know what you are doing when choosing a certain license. For example, you can read information about various licenses and/or consult a lawyer.

#### Map Hint
Does your map have hidden treasures? You can hint about them with the "Map Hint" field.

#### Treasures
A list of treasures that could end up in treasure chests

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

> **Note:** Even standing on the boundary sends the player back. They do not have to go beyond it. Place the boundaries accordingly.

#### Chest Zones
Areas where chests can be placed. Some maps allow placing chests anywhere, while others only place them in certain locations. 

#### Barrier Area
Area where the Indestructible "Red Barrier Glass and/or Indestructible Red Barrier Stone" wall is located. Setting this will allow the game to know where to make them disappear when the match begins. You can leave this by default unless the game is taking a long time to remove your barriers. If it is so and it is a two-team map, then set the Barrier Area to the region of the barriers only. However, it is not possible to do this with four-team maps.

### 6. Export 

1. Press "Finish Editing"
2. Find the exported map located in `[Mintest folder]/worlds/[Map World]/schems/[Exported Map folder]`
3. Move the exported map folder to `\[Minetest folder]/games/capturetheflag/mods/ctf/ctf_map/maps`.

You can access the exported map by running `/ctf_map editor`, clicking on the exported map folder from the list of maps, and then by pressing "Resume Editing". 

### 7. Play

1. Create a new world with the `singlenode` mapgen.
2. Make sure creative mode is disabled
3. Grant yourself `ctf_admin` by issuing `/grantme ctf_admin`
4. Type `/maps`
5. Select your map
6. Press "Skip to map"

### 8. Screenshot

If you choose to submit your map, include a screenshot of it in the exported map's folder. It should be taken with on texture packs enabled and have an aspect ratio of 3:2 (screenshot 600x400px is suggested).

You can take a screenshot easily by doing the following:
1. Hide the HUD. By default <kbd>F1</kbd> does that.
2. Hide the chat log. By default <kbd>F2</kbd> does that.
3. Try to find a good view that shows most of the map.
4. *(Optional)* Increase your view range if important parts of the map cannot be seen. By default the <kbd>=</kbd> (or <kbd>+</kbd>) and <kbd>-</kbd> keys do that.
5. Take a screenshot **from Minetest**. By default <kbd>F12</kbd> does that.
6. You can find the screenshot in `[Minetest folder]/screenshots` unless you have changed the path in settings.

Crop the screenshot into the aspect ratio mentioned above using a tool of your choice, and put the screenshot inside your exported map's folder. It should be named `screenshot.png`.

### 9. Submission

> Your PR should contain the Map Folder that should include the files `map.conf`, `map.mts`, and `screenshot.png`.

Maps can be submitted to the CTF Maps repository through PRs (Pull Requests). If you don't know how to make them, you could ask someone else to make it for you or make your own GitHub account and make it yourself. A benefit of making it on your own is that you can actively engage in the testing and development of the map PR. If you are new to making PRs and forks, you can learn about them by reading these documentations:
- [https://docs.github.com/en/get-started/quickstart/fork-a-repo](https://docs.github.com/en/get-started/quickstart/fork-a-repo "https://docs.github.com/en/get-started/quickstart/fork-a-repo") 
- [https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork "https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork")

If you are creating the PR yourself, it is always better to make each PR on a different branch of your fork of the repo. For example if you want to add a map, then make a separate branch for it, and so on. This will obviate and possible conflicts with any of your already open PRs.  
