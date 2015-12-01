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


local chest_formspec =
	"size[8,9]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
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
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if player then
			minetest.chat_send_player(player:get_player_name(), "You're not allowed to put things in chests!")
			return 0
		else
			--minetest.chat_send_all("Error! Non player putting things in chests")
			return -1
		end
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", chest_formspec)
		meta:set_string("infotext", "Chest")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
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
		minetest.log("action", player:get_player_name() ..
			" takes stuff from chest at " .. minetest.pos_to_string(pos))
		local inv = minetest.get_inventory({type = "node", pos=pos})
		if not inv or inv:is_empty("main") then
			minetest.set_node(pos, {name="air"})
			minetest.show_formspec(player:get_player_name(), "", player:get_inventory_formspec())
		end
	end,
})

--[[ here are some configuration variables ]]

local chests_per_chunk = 5	-- number of chests per chunk. 15 is a bit high, an actual mod might have a lower number
local h_min = -1  		-- minimum chest spawning height, relative to water_level
local h_max = 15		-- maximum chest spawning height, relative to water_level
local t_min = 3			-- minimum amount of treasures found in a chest
local t_max = 6			-- maximum amount of treasures found in a chest

--[[ here comes the generation code
	the interesting part which involes treasurer comes way below
]]
minetest.register_on_generated(function(minp, maxp, seed)
	-- get the water level and convert it to a number
	local water_level = minetest.setting_get("water_level")
	if water_level == nil or type(water_level) ~= "number" then
		water_level = 1
	else
		water_level = tonumber(water_level)
	end

	-- chests minimum and maximum spawn height
	local height_min = water_level + h_min
	local height_max = water_level + h_max

	if(maxp.y < height_min or minp.y > height_max) then
		return
	end
	local y_min = math.max(minp.y, height_min)
	local y_max = math.min(maxp.y, height_max)
	local get_node = minetest.get_node
	local env = minetest.env
	for i=1, chests_per_chunk do
		local pos = {x=math.random(minp.x,maxp.x),z=math.random(minp.z,maxp.z), y=minp.y}

		-- Find ground level
		local ground = nil
		local top    = y_max
                for y=y_max,y_min,-1 do
			local p = {x=pos.x,y=y,z=pos.z}
			local name = get_node(p).name
			if name == "air" or name == "default:water_source" or name == "default:lava_source" then
				top = y
				break
			end
		end
		for y=top,y_min,-1 do
			local p = {x=pos.x,y=y,z=pos.z}
                        local name = get_node(p).name
			if name ~= "air" and name ~= "default:water_source" and name ~= "default:lava_source" then
				ground = y
				break
			end
		end

		if ground~=nil then
			local chest_pos = {x=pos.x,y=ground+1, z=pos.z}
			if chest_pos.z == 0 then
				chest_pos.z = -1
			end
			local nn = minetest.get_node(chest_pos).name	-- chest node name (before it becomes a chest)
			if nn == "air" or nn == "default:water_source" then
				-->>>> chest spawning starts here <<<<--

				-- first: spawn the chest
				local chest = {name = "tsm_chests:chest"}

				-- secondly: rotate the chest
				-- find possible faces
				local xp, xm, zp, zm
				xp = minetest.get_node({x=pos.x+1,y=ground+1, z=pos.z})
				xm = minetest.get_node({x=pos.x-1,y=ground+1, z=pos.z})
				zp = minetest.get_node({x=pos.x,y=ground+1, z=pos.z+1})
				zm = minetest.get_node({x=pos.x,y=ground+1, z=pos.z-1})

				local facedirs = {}
				if(xp.name=="air" or xp.name=="default:water_source") then
					table.insert(facedirs, minetest.dir_to_facedir({x=-1,y=0,z=0}))
				end
				if(xm.name=="air" or xm.name=="default:water_source") then

					table.insert(facedirs, minetest.dir_to_facedir({x=1,y=0,z=0}))
				end
				if(zp.name=="air" or zp.name=="default:water_source") then
					table.insert(facedirs, minetest.dir_to_facedir({x=0,y=0,z=-1}))
				end
				if(zm.name=="air" or zm.name=="default:water_source") then
					table.insert(facedirs, minetest.dir_to_facedir({x=0,y=0,z=1}))
				end

				-- choose a random face (if possible)
				if(#facedirs == 0) then
					minetest.set_node({x=pos.x,y=ground+1, z=pos.z+1},{name=nn})
					chest.param2 = minetest.dir_to_facedir({x=0,y=0,z=1})
				else
					chest.param2 = facedirs[math.floor(math.random(#facedirs))]
				end

				-- Lastly: place the chest
				minetest.set_node(chest_pos,chest)
				--minetest.chat_send_all("Placed chest! " .. dump(chest_pos))

				--->>>>>>>>>> At this point we are finally going to involve Treasurer. <<<<<<<<<<<<<<--
				-- determine a random amount of treasures
				local treasure_amount = math.ceil(math.random(t_min, t_max))

				-- calculate preciousness of treasures based on height. higher = more precious
				local height = math.abs(h_min) - math.abs(h_max)
				local y_norm = (ground+1) - h_min
				local scale = 1 - (y_norm/height)
				local minp = 0 --scale*4		-- minimal preciousness:   0..4
				local maxp = 10 --scale*4+2.1	-- maximum preciousness: 2.1..6.1

				-- now use these values to finally request the treasure(s)
				local treasures = treasurer.select_random_treasures(treasure_amount,minp,maxp)
				-- That’s it!

				-- Get the inventory of the chest to place the treasures in
				local meta = minetest.get_meta(chest_pos)
				local inv = meta:get_inventory()

				--[[ Now that we got both our treasures and the chest’s inventory,
				let’s place the treasures one for one into it. ]]
				for i=1,#treasures do
					inv:set_stack("main",i,treasures[i])
				end
			end
		end
	end
end)
