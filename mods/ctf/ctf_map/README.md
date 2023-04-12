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

### 3. Select an area

1. Decide where you will build your map. The area can be maximum 230x230 blocks in surface area, but it can be lesser.
2. Grant yourself the `ctf_map_editor` privilege by running `/grantme ctf_map_editor`
3. Run `/ctf_map editor`
4. Select "Create New Map"
5. Select a position to be one corner of the map.
6. Select a position in the opposite corner. Place it higher/lower than the first one to give the map height.

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
	- Flags. Place it, then right-click it to choose flag color.
	- "Indestructible Barrier Glass" (`ctf_map:ind_glass`) around the edge of the world.
	- "Indestructible Red Barrier Glass" (`ctf_map:ind_glass_red`) for the build-time wall.
	- "Indestructible Red Barrier Stone" (`ctf_map:ind_stone_red`) for underground build-time wall.

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
* We can only accept Free Software licenses, e.g.`CC BY-SA 4.0`.
* Please know what you are doing when choosing a certain license. For example, you can read information about various licenses and/or consult a lawyer.

#### Map Hint
Does your map have hidden treasures? You can hint about them with the hint field.

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

#### Map start_time
What time of the day the match begins at. Changing this field will instantly update the time of day in the world you are editing.

* `0` is for midnight
* `1000` is for 1 AM
* `2000` is for 2 AM
* etc.

#### Zone Bounds
How far the players of a certain team may go during build time.
**Note:** Even standing on the boundary sends the player back. They do not have to go beyond it. Place the boundaries accordingly.

#### Chest Zones
Areas where chests can be placed. Some maps allow placing chests anywhere, while others only place them in certain locations.

### 6. Export

1. Press "Finish Editing"
2. Find the exported map
3. Move to \[Minetest folder]/games/capturetheflag/mods/ctf/ctf_map/maps

### 7. Play

1. Create a new world with the `singlenode` mapgen.
2. Make sure creative mode is disabled
3. Grant yourself `ctf_admin` by issuing `/grantme ctf_admin`
4. Type `/maps`
5. Select your map
6. Press "Skip to map"

### 8. Screenshot

If you choose to submit your map, include a screenshot of it in the exported map's folder. It should have an aspect ratio of 3:2 (screenshot 600x400px is suggested).
You can take a screenshot easily by doing the following:
1. Hide the HUD. By default <kbd>F1</kbd> does that.
2. Hide the chat log. By default <kbd>F2</kbd> does that.
3. Try to find a good view that shows most of the map.
4. *(Optional)* Increase your view range if important parts of the map cannot be seen. By default the <kbd>=</kbd> (or <kbd>+</kbd>) and <kbd>-</kbd> keys do that.
5. Take a screenshot **from Minetest**. By default <kbd>F12</kbd> does that.
6. You can find the screenshot in `[Minetest folder]/screenshots` unless you have changed the path in settings.
Crop the screenshot into the aspect ratio mentioned above using a tool of your choice, and put the screenshot inside your exported map's folder. It should be named `screenshot.png`.
