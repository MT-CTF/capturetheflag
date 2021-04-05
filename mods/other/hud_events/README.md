# `hud_events`

Forked and edited from `hud_score` by ANAND (ClobberXD), licensed under the LGPLv2.1+ license.  

`hud_events` provides an API to display HUD event elements which can be used to
display various hints and messages.

## Methods

- `hud_event.new(name, event_def)`: Adds a new HUD event element to player `name`.
  - `name` [string]: Player name
  - `event_def` [table]: HUD event element definition. See below.

## HUD event element definition

HUD event element definition table, passed to `hud_event.new`.

Example definition:

```lua
{
    name  = "ctf_bandages:healing", -- Can be any arbitrary string
    color = "0x00FF00",             -- Should be compatible with Minetest's HUD def
    value = "x has healed y",                     -- The actual event to be displayed
    -- Field `time` is automatically added by `hud_event.new`
    -- to keep track of element expiry
}
```

## `players` table

This is a table of tables, indexed by player names. This table holds the HUD
data of all online players. Each sub-table is a list of HUD event elements,
which are added by `hud_event.new`.

```lua
local players = {
    ["name"] = {
        [1] = <hud_event_element>,
        [2] = <hud_event_element>,
        [3] = <hud_event_element>
        ...
    },
    ["name2"] = {
        ...
    },
    ...
}
```

## Changes

Changes that have been made compared to the original `hud_score` mod. Lines mentioned underneath refer to the lines in the `hud_events`' init.lua file.  
- replaced all occurences of `score` with `event` (10th March 2021)
- changed variables and arguments in the lines 5, 6 and 36 (10th march 2021)
- edited and added arguments in line 39 and 40 (10th march 2021)
- deleted an `if` statement after line 28 (10th march 2021)
