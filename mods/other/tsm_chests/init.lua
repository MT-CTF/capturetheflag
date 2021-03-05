--[[
	This is an example treasure spawning mod (TSM) for the default mod.
	It needs the mods “treasurer” and “default” to work.
	For an example, it is kinda advanced.

	A TSM’s task is to somehow bring treasures (which are ItemStacks) into the world.
	This is also called “spawning treasures”.
	How it does this task is completely free to the programmer of the TSM.

	This TSM spawns the treasures by placing chests (tsm_chests:chest) between 20 and 200 node lengths below the water surface. This cau
	The chests are provided by the default mod, therefore this TSM depends on the default mod.
	The treasures are requested from the treasurer mod. The TSM asks the treasurer mod for some treasures.

	However, the treasurer mod comes itself with no treasures whatsoever. You need another mod which tells the treasurer what treasures to add. These mods are called “treasure registration mods” (TRMs).
	For this, there is another example mod, called “trm_default_example”, which registers a bunch of items of the default mod, like default:gold_ingot.
]]

tsm_chests = {}

local non_ground_nodes = {
	"air",
	"default:water_source",
	"default:lava_source",
	"default:lava_flowing",
	"tsm_chests:chest"
}

local chest_formspec =
	"size[8,9]" ..
	"list[current_name;main;0,0.3;8,4;]" ..
	"list[current_player;main;0,4.85;8,1;]" ..
	"list[current_player;main;0,6.08;8,3;8]" ..
	"listring[current_name;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0,4.85)

minetest.register_node("tsm_chests:chest", {
	description = "Chest",
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
	paramtype2 = "facedir",
	groups = {oddly_breakable_by_hand = 1, choppy = 3},
	light_source = 3,
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	drop = "",
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if player then
			minetest.chat_send_player(player:get_player_name(),
				"You're not allowed to put things in treasure chests!")
			return 0
		end
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", chest_formspec)
		meta:set_string("infotext", "Chest")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	on_destruct = function(pos)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		-- iterate over chest contents, drop all
		for index, stack in pairs(inv:get_list("main")) do
			if not minetest.is_yes(minetest.settings:get("remove_items")) then
				local obj = minetest.add_item(pos, stack:take_item(stack:get_count()))
				_ = obj and obj:set_velocity({x = math.random(-1, 1), y = 5, z = math.random(-1, 1)})
			end
			inv:set_stack("main", index, nil)
		end
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)
		minetest.log("action", player:get_player_name() ..
			" moves stuff in chest at " .. minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() ..
			" moves stuff to chest at " .. minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local inv = minetest.get_inventory({type = "node", pos = pos})
		local swapped_item = inv:get_stack(listname, index)

		if swapped_item:get_name() ~= "" then
			inv:remove_item(listname, swapped_item)
			player:get_inventory():add_item("main", swapped_item)
		end

		minetest.log("action", player:get_player_name() ..
			" takes stuff from chest at " .. minetest.pos_to_string(pos))

		if not inv or inv:is_empty("main") then
			minetest.set_node(pos, {name="air"})
			minetest.show_formspec(player:get_player_name(), "", player:get_inventory_formspec())
		end
	end,
})

--[[ here are some configuration variables ]]

local t_min = 4  -- minimum amount of treasures found in a chest
local t_max = 7  -- maximum amount of treasures found in a chest
local get_node = minetest.get_node

local function findGroundLevel(pos, y_min, y_max)
	local ground = nil
	local top    = y_max
	for y = y_max, y_min, -1 do
		local p = {x=pos.x,y=y,z=pos.z}
		local name = get_node(p).name
		if table.indexof(non_ground_nodes, name) ~= -1 then
			top = y
			break
		end
	end
	for y=top,y_min,-1 do
		local p = {x=pos.x,y=y,z=pos.z}
		local name = get_node(p).name
		if table.indexof(non_ground_nodes, name) == -1 then
			ground = y
			break
		end
	end
	return ground
end

local function getFacedirs(pos, ground)
	-- secondly: rotate the chest
	-- find possible faces
	local xp, xm, zp, zm
	xp = minetest.get_node({x=pos.x+1, y=ground+1, z=pos.z})
	xm = minetest.get_node({x=pos.x-1, y=ground+1, z=pos.z})
	zp = minetest.get_node({x=pos.x, y=ground+1, z=pos.z+1})
	zm = minetest.get_node({x=pos.x, y=ground+1, z=pos.z-1})

	-- Set Facedirs
	local facedirs = {}
	if xp.name=="air" or xp.name=="default:water_source" then
		table.insert(facedirs, minetest.dir_to_facedir({x=-1,y=0,z=0}))
	end
	if xm.name=="air" or xm.name=="default:water_source" then
		table.insert(facedirs, minetest.dir_to_facedir({x=1,y=0,z=0}))
	end
	if zp.name=="air" or zp.name=="default:water_source" then
		table.insert(facedirs, minetest.dir_to_facedir({x=0,y=0,z=-1}))
	end
	if zm.name=="air" or zm.name=="default:water_source" then
		table.insert(facedirs, minetest.dir_to_facedir({x=0,y=0,z=1}))
	end

	return facedirs
end

local function placeChest(pos, chest_pos, ground, nn)
	local chest = {name = "tsm_chests:chest"}
	local facedirs = getFacedirs(pos, ground)

	-- choose a random face (if possible)
	if #facedirs == 0 then
		minetest.set_node({x=pos.x,y=ground+1, z=pos.z+1}, {name=nn})
		chest.param2 = minetest.dir_to_facedir({x=0,y=0,z=1})
	else
		chest.param2 = facedirs[math.floor(math.random(#facedirs))]
	end

	-- Lastly: place the chest
	minetest.set_node(chest_pos, chest)

	-- Get treasure
	local treasure_amount = math.ceil(math.random(t_min, t_max))
	-- local height = math.abs(h_min) - math.abs(h_max)
	-- local y_norm = (ground+1) - h_min
	-- local scale = 1 - (y_norm/height)
	local minp = 0 --scale*4		-- minimal preciousness:   0..4
	local maxp = 10 --scale*4+2.1	-- maximum preciousness: 2.1..6.1
	local treasures = treasurer.select_random_treasures(treasure_amount, minp, maxp)

	-- Add Treasure to Chst
	local meta = minetest.get_meta(chest_pos)
	local inv = meta:get_inventory()
	for i=1, #treasures do
		inv:set_stack("main", i, treasures[i])
	end
end

--[[ here comes the generation code
	the interesting part which involes treasurer comes way below
]]
function tsm_chests.place_chests(minp, maxp, number_chests)
	local attempts = 0
	local chests_placed = 0
	while chests_placed < number_chests and attempts < number_chests + 12 do
		attempts = attempts + 1
		local pos = {
			x = math.random(minp.x, maxp.x),
			y = minp.y,
			z = math.random(minp.z, maxp.z)
		}

		-- Find ground level
		local ground = findGroundLevel(pos, minp.y, maxp.y)
		if ground ~= nil then
			local chest_pos = {x = pos.x, y = ground + 1, z = pos.z}

			-- chest node name (before it becomes a chest)
			local nn = minetest.get_node(chest_pos).name
			if nn == "air" or nn == "default:water_source" then
				placeChest(pos, chest_pos, ground, nn)
				chests_placed = chests_placed + 1
			end
		end
	end

	minetest.log("info", "Spawned " .. chests_placed .. "/" .. number_chests .. " chests after " .. attempts .. " attempts!")
end
