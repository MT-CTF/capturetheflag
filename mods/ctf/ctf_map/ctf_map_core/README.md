# CTF Map Core

This mod handles creating and loading maps.

## Attributions

- Indestructible nodes adapted from various mods in `minetest_game`.

## Indestructible nodes

- `ctf_map_core` provides indestructible nodes for most nodes from default, and all nodes from
stairs.

- All indestructible nodes have the same item name with the mod prefix being `ctf_map:`
instead of their original prefixes (e.g. `default:stone` -> `ctf_map:stone` and
`stairs:stair_stone` -> `ctf_map:stair_stone`) with the exception of wool, whose
indestructible nodes have slightly different names from the original node names -
`ctf_map:wool_<color>`. This is because the original nomenclature becomes meaningless
if the modname prefix is changed.
