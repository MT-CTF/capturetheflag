# Select Item API
With this API you can open the item selection dialog as well as
catch events when players select an item from this dialog.

You can safely optionally depend on this mod, just make sure
to check for the mod's existence first (`core.get_modpath`
returns non-`nil` value).

## Functions
### `select_item.show_dialog(playername, dialogname, filter, compare)`
Shows an item selection dialog to a player. The player can choose
one item (which triggers a callback) or abort selection
(in which case nothing happens).

By default, this displays all items with the exception of unknown
items and `ignore`. This also includes items which players may
normally not be supposed to see, like those usually not found in
so-called “creative inventories”. You should set the `filter` argument
to filter out unwanted items.

The items are also sorted by a sorting rule.

#### Parameters
* `playername`: Name of player to show dialog to
* `dialogname`: Identifier of the dialog (must not contain “%%”)
* `filter`: (optional) Filter function to narrow down the visible
            items (see below)
* `compare`: (optional) Custom compare function for sorting,
             used in `table.sort`.

Recommended form of `dialogname` is “`<modname>:<name>`”. Almost all
names are allowed, but they must never contain the substring “%%”.
Example: `example:select_my_item`

Default sorting sorts items alphabetically by itemstring. It
moves items with empty description to the end, preceded by items
with description, but `not_in_creative_inventory=1`, and then
everything else to the beginning.

##### Filter function
The filter function has the function signature `filter(itemstring)`.
This function will be called for each item with the itemstring
given as argument. The function must return `true` if the item
in question is allowed in the selection dialog and `false` if
it must not appear.

You can also choose one of the following pre-defined filter functions:

* `select_item.filters.creative`: Removes all items with group
  `not_in_creative_inventory=1` and/or empty `description`
* `select_item.filters.all`: Does not filter anything. Same as `nil`.

### `select_item.register_on_select_item(callback)`
Register a call function `callback` to the `select_item` mod.
Whenever a player selects an item or cancels the selection,
`callback` is called.

#### `callback` function
This has the function signature `callback(playername, dialogname, itemstring)`.

* `playername` is the name of the player who selected the item
* `dialogname` is the dialog identifier of the item selection dialog being used
* `itemstring` is the itemstring of the chosen item or `nil` if aborted

Normally, if the player pushes any button, the formspec is closed.
But if you return `false` in this callback, the formspec is *not* closed.

## Examples
Display all items from Creative inventory to Player 1:

```
select_item.show_dialog("Player 1", "example:creative", select_item.filters.creative)
```

Display all flammable to Player 1:

```
select_item.show_dialog("Player 1", "example:flammable", function(itemstring)
	if core.get_item_group(itemstring, "flammable") >= 1 then
		return true
	else
		return false
	end
end
```

Note the different values for `dialogname`.

Adding a selected to the player's inventory after player selected item in the “Creative” dialog
above:

```
select_item.register_on_select_item(function(playername, dialogname, itemstring)
	--[[ Check for the dialog type you care about. This check should almost always be done
	to ensure interoperability with other mods. ]]
	if dialogname == "example:creative" then
		local inv = core.get_inventory({type="player", location=playername})
		inv:add_item("main", ItemStack(itemstring))
	end
end)
```
