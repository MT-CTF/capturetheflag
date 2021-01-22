# CTF Map - Map maker

## Creating a new map

### Youtube tutorial
https://youtu.be/orBsC9wViUw


### 1. Dependencies

* Minetest 5.0.0 or later.
* `ctf_map` modpack (by copying the folder from this game to `minetest/mods`)
* `worldedit` and `worldedit_commands`.

### 2. Find an area

* Can use Minetest Game and any mapgen.
* It must be a cube, and the barrier will be in the exact center.
* It should be around 230x230 in surface area, but this can be lesser.
* Feel free to modify the area to your needs.

### 3. Select the area

There are multiple ways do this, this is the simplest in most cases.

* If you haven't modified the map at all, do the following to speed up barrier placement:
  * Stop Minetest.
  * Open up the world's world.mt
  * Set backend to "dummy".
  * Save.
* Using worldedit, select the area.
* Type `/gui`, and click `Player pos` then `From WE` and then `To WE`.
* Check that the center location is the right place for the barrier to go.
* Check that the bounds extend far enough.

### 4. Place barriers

* Set the middle barrier direction. The barrier is a plane defined by a co-ordinate = 0.
  If the barrier is X=0, then it will placed with every node of the barrier having X=0.
  If the barrier is Z=0, then it will placed with every node of the barrier having Z=0.
* Click "place barrier". Note that this command does not have an undo.
* After placing barriers you should place 2 flags where you want bases to be. You get flags in `/gui` --> `Giveme flags`

### 5. Meta data

* Set the meta data

### 6. Export

* Click export, and wait until completion.
* Copy the resultant folder from `worlddir/schems/` into `games/capturetheflag/mods/ctf/ctf_map/ctf_map_core/maps/`.
* Profit!


## Documentation

### Map meta

Each map's metadata is stored in an accompanying `map.conf` file containing the following data:

* `name`: Name of map.
* `author`: Author of the map.
* `hint`: [Optional] Helpful hint or tip for unique maps, to help players understand the map.
* `rotation`: Rotation of the schem. [`x`|`z`]
* `r`: Radius of the map.
* `h`: Height of the map.
* `team.i`: Name of team `i`.
* `team.i.color`: Color of team `i`.
* `team.i.pos`: Position of team `i`'s flag, relative to center of schem.
* `chests.i.from`, `chests.i.to`: [Optional] Positions of diagonal corners of custom chest
zone `i`, relative to the center of the schem.
* `chests.i.n`: [Optional] Number of chests to place in custom chest zone `i`.
* `license`: Name of the license of the map.
* `other`: [Optional] Misc. information about the map. This is displayed in the maps catalog.
* `base_node`: [Optional] Technical name of node to be used for the team base.
* `initial_stuff`: [Optional] Comma-separated list of itemstacks to be given to the player
 on join and on respawn.
* `treasures`: [Optional] List of treasures to be registered for the map, in a serialized
format. Refer to the `treasures` sub-section for more details.
* `start_time`: [Optional] Time at start of match. Defaults to `0.4` [`0` - `1`].
* `time_speed`: [Optional] Time speed multiplier. Accepts any valid number. Defaults to 1.
* `phys_speed`: [Optional] Player speed multiplier. Accepts any valid number. Defaults to 1.
* `phys_jump`: [Optional] Player jump multiplier. Accepts any valid number. Defaults to 1.
* `phys_gravity`: [Optional] Player gravity multiplier. Accepts any valid number. Defaults to 1.

#### `license`

* Every map must have its own license. Once you've chosen your license, simply add the following line to the `map.conf` file:

  ```properties
  license = <name>
  ```

* If attribution is required (for example if you modify other's map and you have to tell who is author of the original map), that has to be appended to the `license` field.
If you want to tell more infomation, you can use:

  ```properties
  others = <description>
  ```

* If you don't know which license to use, [this list of CC licenses](https://creativecommons.org/use-remix/cc-licenses/) can help you.
* We can only accept Free Software licenses, e.g.`CC BY-SA 4.0`.
* Please know what you are doing when choosing a certain license. For example, you can read information about various licenses and/or consult a lawyer.


#### `treasures`

`treasures` is a list of treasures to be registered for this map in serialized format.

An example `treasures` value that registers steel pick, shotgun, and grenade:

```properties
treasures = default:pick_steel,0.5,5,1,10;shooter:shotgun,0.04,2,1;shooter:grenade,0.08,2,1
```

(See [here](../../../other/treasurer/README.md) to understand the magic numbers)

#### `initial_stuff`
The `initial_stuff` are the items given to everyone at their (re)spawn. A pickaxe and a torch is promoted to be given in the maps `initial_stuff`.

An example `initial_stuff` value that registers a stone pickaxe, 30 cobblestones and 5 torches is given below.

```properties
initial_stuff = default:pick_stone,default:cobble 30,default:torch 5
```

### `screenshot`

Every map must have its own screenshot in map's folder. It should have an aspect ratio of 3:2 (screenshot 600x400px is suggested).

It should be named `screenshot.png`.

### `skybox` [Optional]

Six images which should be in map's folder.

* `skybox_1.png` - up
* `skybox_2.png` - down
* `skybox_3.png` - east
* `skybox_4.png` - west
* `skybox_5.png` - south
* `skybox_6.png` - north

You have to include skybox license in `license` in `.conf` file. We can only accept Free Software licenses, e.g. `CC0`, `CC BY 3.0`, `CC BY 4.0`, `CC BY-SA 3.0`, `CC BY-SA 4.0`.

You can find some good skyboxes with suitable licenses at [https://opengameart.org](https://opengameart.org/art-search-advanced?field_art_tags_tid=skybox).

## Editing exported map

The easiest way to edit exported maps is the following:
* Create a world using `singlenode` mapgen. Enable `WorldEdit` and `ctf_map` mod,
* Go in the world's folder, create a folder named `schems`, and place the `.mts` file inside,
* Start the game, `/grantme all` and enable `fly` (there is no ground in singlenode mapgen),
* Do `//1` to set the position where you will generate the map,
* Do `//mtschemplace yourschematic` (where `yourschematic` is the name of the mts file without `.mts`).

When you finish:

* Place `//1` and `//2` exactly in opposite corners of map (cube),
* Do `//mtschemcreate <new_name>` to create new edited `.mts` file. It will be saved in `schems` folder.
