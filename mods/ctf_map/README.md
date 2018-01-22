# CTF Map

This mod handles multiple maps.

# Creating a new map

## 1. Dependencies

* Minetest 0.4.16 or later.
* Mods
    * ctf_map (by copying the folder from this game to `minetest/mods`)
    * worldedit and worldedit_commands.

## 2. Find an area

* Can use Minetest Game and any mapgen.
* It must be a cube, and the barrier will be in the exact center.
* It should be around 230x230 in surface area, but this can vary.
* Feel free to modify the area to your needs.

## 3. Select the area

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

## 4. Place barriers

* Set the middle barrier direction. The barrier is a plane defined by a co-ordinate = 0.
  If the barrier is X=0, then it will placed with every node of the barrier having X=0.
  If the barrier is Z=0, then it will placed with every node of the barrier having Z=0.
* Click "place barrier". Note that this command does not have an undo.

## 5. Meta data

* Set the meta data

## 6. Export

* Click export, and wait until completion.
* Copy the two files from `worlddir/schemes/` to `ctf_map/maps/`.
* Rename the files so the two prefixed numbers are consistent to existing maps.
* Profit!
