# CTF Map - Map maker

## Creating a new map

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
* Type `/gui`, and click "From WE" then "To WE".
* Check that the center location is the right place for the barrier to go.
* Check that the bounds extend far enough.

### 4. Place barriers

* Set the middle barrier direction. The barrier is a plane defined by a co-ordinate = 0.
  If the barrier is X=0, then it will placed with every node of the barrier having X=0.
  If the barrier is Z=0, then it will placed with every node of the barrier having Z=0.
* Click "place barrier". Note that this command does not have an undo.

### 5. Meta data

* Set the meta data

### 6. Export

* Click export, and wait until completion.
* Copy the resultant folder from `worlddir/schems/` into `ctf_map/ctf_map_core/maps/`.
* Profit!

## Documentation

### Map meta

Each map's metadata is stored in an accompanying .conf file containing the following data:

* `name`: Name of map.
* `author`: Author of the map.
* `hint`: [Optional] Helpful hint or tip for unique maps, to help players understand the map.
* `rotation`: Rotation of the schem. [`x`|`z`]
* `screenshot`: File name of screenshot of the map; should include file extension.
* `license`: Name of the license of the map.
* `other`: [Optional] Misc. information about the map. This is displayed in the maps catalog.
* `base_node`: [Optional] Technical name of node to be used for the team base.
* `schematic`: Name of the map's schematic.
* `initial_stuff`: [Optional] Comma-separated list of itemstacks to be given to the player
 on join and on respawn.
* `treasures`: [Optional] List of treasures to be registered for the map, in a serialized
format. Refer to the `treasures` sub-section for more details.
* `start_time`: [Optional] Time at start of match. Defaults to `0.4` [`0` - `1`].
* `time_speed`: [Optional] Time speed multiplier. Accepts any valid number. Defaults to 1.
* `r`: Radius of the map.
* `h`: Height of the map.
* `team.i`: Name of team `i`.
* `team.i.color`: Color of team `i`.
* `team.i.pos`: Position of team `i`'s flag, relative to center of schem.
* `chests.i.from`, `chests.i.to`: [Optional] Positions of diagonal corners of custom chest
zone `i`, relative to the center of the schem.
* `chests.i.n`: [Optional] Number of chests to place in custom chest zone `i`.

#### `treasures`

`treasures` is a list of treasures to be registered for this map in serialized format.

An example `treasures` value that registers steel pick, shotgun, and grenade:

```lua
treasures = default:pick_steel,0.5,5,1,10;shooter:shotgun,0.04,2,1;shooter:grenade,0.08,2,1
```

(See [here](../../../other/treasurer/README.md) to understand the magic numbers)
