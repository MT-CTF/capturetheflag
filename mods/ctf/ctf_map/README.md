# CTF Map

This mod handles creating and loading maps.

## Attributions

- Indestructible nodes adapted from various mods in `minetest_game`.

## Creating a new map

### 1. Dependencies

* Minetest 0.4.16 or later.
* Mods
  * ctf_map (by copying the folder from this game to `minetest/mods`)
  * worldedit and worldedit_commands.

### 2. Find an area

* Can use Minetest Game and any mapgen.
* It must be a cube, and the barrier will be in the exact center.
* It should be around 230x230 in surface area, but this can vary.
* Feel free to modify the area to your needs.

### 3. Select the area

There are multiple ways do this, this is the simplist in most cases.

* If you haven't modified the map at all, do the following to speed up barrier placement:
  * Stop Minetest.
  * Open up the world's world.mt
  * Set backend to "dummy".
  * Save.
* Using worldedit, select the area.
* Type /gui, and click "From WE" then "To WE".
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
* Copy the two files from `worlddir/schems/` to `ctf_map/maps/`.
* Rename the files so the two prefixed numbers are consistent to existing maps.
* Profit!

## Documentation

### Map meta

Each map's metadata is stored in an accompanying .conf file containing the following data:

* `name`: Name of map.
* `author`: Author of the map.
* `hint`: [Optional] Helpful hint or tip for unique maps, to help players understand the map.
* `rotation`: Rotation of the schem. [`x`|`z`]
* `schematic`: Name of the map's schematic.
* `initial_stuff`: [Optional] Comma-separated list of itemstacks to be given to the player
 on join and on respawn.
* `treasures`: [Optional] List of treasures to be registered for the map, in a serialized
format. Refer to the `treasures` sub-section for more details.
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

(See [here](../../other/treasurer/README.md) to understand the magic numbers)

## Indestructible nodes

- `ctf_map` provides indestructible nodes for most nodes from default, and all nodes from
stairs.

- All indestructible nodes have the same item name with the mod prefix being `ctf_map:`
instead of their original prefixes (e.g. `default:stone` -> `ctf_map:stone` and
`stairs:stair_stone` -> `ctf_map:stair_stone`) with the exception of wool, whose
indestructible nodes have slightly different names from the original node names -
`ctf_map:wool_<color>`. This is because the original nomenclature becomes meaningless
if the modname prefix is changed.
