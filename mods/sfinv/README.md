# Simple Fast Inventory (WIP)

![SFINV Screeny](https://cdn.pbrd.co/images/1yQhd1TI.png)

A cleaner, simpler, solution to having an advanced inventory in Minetest.  
Formspec style based on the creative inventory.

Written by rubenwardy.  
License: WTFPL

## Aims

* Unified Inventory API compatible (a mod using UI's api will work with this)
* Themable.
* Clean API.

# API

## Formspec Parser

sfinv has a variable based parser. Here is the formspec of the crafting tab:

	{{ layout }}
	list[current_player;craft;1.75,0.5;3,3;]
	list[current_player;craftpreview;5.75,1.5;1,1;]
	image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]
	listring[current_player;main]
	listring[current_player;craft]
	image[0,4.25;1,1;gui_hb_bg.png]
	image[1,4.25;1,1;gui_hb_bg.png]
	image[2,4.25;1,1;gui_hb_bg.png]
	image[3,4.25;1,1;gui_hb_bg.png]
	image[4,4.25;1,1;gui_hb_bg.png]
	image[5,4.25;1,1;gui_hb_bg.png]
	image[6,4.25;1,1;gui_hb_bg.png]
	image[7,4.25;1,1;gui_hb_bg.png]

`{{ layout }}` will be replaced by the following:

	size[8,8.6]
	bgcolor[#080808BB;true]
	background[5,5;1,1;gui_formbg.png;true]
	{{ nav }}
	listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]
	list[current_player;main;0,4.25;8,1;]
	list[current_player;main;0,5.5;8,3;8]

and `{{ nav }}` will be replaced by something like the following:

	tabheader[0,0;tabs;Crafting,Page 1, Page 2;1]

Only two levels of variable parsing is guaranteed to succeed, as only two
passes are done.

Here is another example, this time a page with no inventory:

	size[8,8.6]
	bgcolor[#080808BB;true]
	background[5,5;1,1;gui_formbg.png;true]
	{{ nav }}
	textlist[0,0;7.85,8.5;help;one,two,three]

The following variables are provided by the API:

* `name` - name of the player viewing
* `nav` - the navigation, probably a tabset
* `layout` - a default layout which has the players inventory at the bottom.


## sfinv.register_page

sfinv.register_page(name, def)

def is a table containing:

* `title(player, context)` - human readable page name (required)
* `get(player, context)` - returns a formspec string. See formspec variables. (required)
* `is_in_nav(player, context)` - return true if it appears in tab header
* `on_player_receive_fields(player, context, fields)` - on formspec submit

planned:

* `on_enter(player, context)` - when coming to this page from another
* `on_leave(player, context)` - when leaving this page to go to another
