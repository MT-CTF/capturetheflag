# `hud_score`

`hud_score` provides an API to display HUD score elements which can be used to
display kill scores, bounty scores, etc.

## Methods

- `hud_score.new(name, score_def)`: Adds a new HUD score element to player `name`.
  - `name` [string]: Player name
  - `score_def` [table]: HUD score element definition. See below.

## HUD score element definition

HUD score element definition table, passed to `hud_score.new`.

Example definition:

```lua
{
    name  = "ctf_stats:kill_score", -- Can be any arbitrary string
    color = "0x00FF00",             -- Should be compatible with Minetest's HUD def
    value = 50,                     -- The actual number to be displayed
    -- Field `time` is automatically added by `hud_score.new`
    -- to keep track of element expiry
}
```

## `players` table

This is a table of tables, indexed by player names. This table holds the HUD
data of all online players. Each sub-table is a list of score tables, which
are added by `hud_score.new`.

```lua
local players = {
    ["name"] = {
        [1] = <score_def>,
        [2] = <score_def>,
        [3] = <score_def>
        ...
    },
    ["name2"] = {
        ...
    },
    ...
}
```
