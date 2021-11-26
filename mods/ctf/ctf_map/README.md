# CTF Map - Map maker

## Creating a new map

### Youtube tutorial


### 1. Dependencies



### 2. Find an area



### 3. Select the area



### 4. Place barriers



### 5. Meta data



### 6. Export



## Documentation

### Map meta


#### `license`

* Every map must have its own license. Once you've chosen your license, <...>

* If attribution is required (for example if you modify other's map and you have to tell who is author of the original map), that has to be appended to the `license` field.
If you want to tell more infomation, you can use:



* If you don't know which license to use, [this list of CC licenses](https://creativecommons.org/use-remix/cc-licenses/) can help you.
* We can only accept Free Software licenses, e.g.`CC BY-SA 4.0`.
* Please know what you are doing when choosing a certain license. For example, you can read information about various licenses and/or consult a lawyer.


#### `treasures`


#### `initial_stuff`
`initial_stuff` are the items given to players at their (re)spawn. The `initial_stuff` field is located in the `map.conf` file. At least a pickaxe and some torches should be given in the map's `initial_stuff`.

An example of `initial_stuff` value that registers a stone pickaxe, 30 cobblestones, 5 torches and a pistol is given below.

```properties
initial_stuff = default:pick_stone,default:cobble 30,default:torch 5,ctf_ranged:pistol_loaded
```

### `screenshot`

Every map must have its own screenshot in map's folder. It should have an aspect ratio of 3:2 (screenshot 600x400px is suggested).

It should be named `screenshot.png`.

### `skybox` [Optional]

Six images which should be in map's folder (in a `skybox` folder).

* `skybox/Up.png` - up
* `skybox/Down.png` - down
* `skybox/Front.png` - east
* `skybox/Back.png` - west
* `skybox/Left.png` - south
* `skybox/Right.png` - north

You have to include skybox license in your `license` field. We can only accept Free Software licenses, e.g. `CC0`, `CC BY 3.0`, `CC BY 4.0`, `CC BY-SA 3.0`, `CC BY-SA 4.0`.
Before you test your skybox images in local CTF game, run the `update.sh` file in the `games/capturetheflag/` folder.

You can find some good skyboxes with suitable licenses at [opengameart.org](https://opengameart.org/art-search-advanced?field_art_tags_tid=skybox) or [www.humus.name](https://www.humus.name/index.php?page=Textures).
## Editing exported map


