local old = ctf.get_spawn
function ctf.get_spawn(tname)
	local team = ctf.team(tname)
	if team and #team.flags >= 1 then
		local flag = team.flags[1]
		local i = 0
		local r = 6
		while i < 6 do
			i = i + 1
			local pos = {x=0, z=0}
			pos.x = flag.x + math.random() * 40 - 20
			pos.z = math.random() * 30 + 49
			if pos.x < -99 then
				pos.x = -99
			end
			if pos.x > 99 then
				pos.x = 99
			end
			if team.flags[1].z < 0 then
				pos.z = -pos.z
			end
			local res = minetest.find_nodes_in_area_under_air(
				{ x = pos.x - r, y = 2, z = pos.z - r},
				{ x = pos.x + r, y = 17, z = pos.z + r},
				{"default:dirt_with_grass"})
			if #res > 0 then
				res[1].y = res[1].y + 1
				team.spawn = res[1]
				return res[1]
			end
		end
		return team.spawn or old(tname)
	else
		return team.spawn
	end
end


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

local colors = {"red", "blue"}
for _, color in pairs(colors) do
	minetest.register_node("ctf_team_base:chest_" .. color, {
		description = "Chest",
		tiles = {
			"default_chest_top_" .. color .. ".png",
			"default_chest_top_" .. color .. ".png",
			"default_chest_side_" .. color .. ".png",
			"default_chest_side_" .. color .. ".png",
			"default_chest_side_" .. color .. ".png",
			"default_chest_front_" .. color .. ".png"},
		paramtype2 = "facedir",
		groups = {immortal = 1},
		legacy_facedir_simple = true,
		is_ground_content = false,
		sounds = default.node_sound_wood_defaults(),
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", chest_formspec)
			meta:set_string("infotext", "Chest")
			local inv = meta:get_inventory()
			inv:set_size("main", 8*4)
		end,
		can_dig = function(pos,player)
			return false
		end,
		on_metadata_inventory_move = function(pos, from_list, from_index,
				to_list, to_index, count, player)
			minetest.log("action", player:get_player_name() ..
				" moves stuff in chest at " .. minetest.pos_to_string(pos))
		end,
	    on_metadata_inventory_put = function(pos, listname, index, stack, player)
			minetest.log("action", player:get_player_name() ..
				" moves " .. (stack:get_name() or "stuff") .. " " .. (stack:get_count() or 0)  .. " to chest at " .. minetest.pos_to_string(pos))
		end,
	    on_metadata_inventory_take = function(pos, listname, index, stack, player)
			minetest.log("action", player:get_player_name() ..
				" takes " .. (stack:get_name() or "stuff") .. " " .. (stack:get_count() or 0) .. " from chest at " .. minetest.pos_to_string(pos))
		end
	})
end

minetest.register_on_generated(function(minp, maxp, seed)
	for tname, team in pairs(ctf.teams) do
		for _, flag in pairs(team.flags) do
			if minp.x <= flag.x and maxp.x >= flag.x and
					minp.y <= flag.y and maxp.y >= flag.y and
					minp.z <= flag.z and maxp.z >= flag.z then
				-- Spawn ind base
				for x = flag.x - 2, flag.x + 2 do
					for z = flag.z - 2, flag.z + 2 do
						minetest.set_node({ x = x, y = flag.y - 1, z = z},
							{name = "default:cobble"})
					end
				end
				minetest.set_node({ x = flag.x, y = flag.y - 1, z = flag.z},
					{name = "ctf_barrier:ind_stone"})

				-- Check for trees
				for y = flag.y, flag.y + 3 do
					for x = flag.x - 3, flag.x + 3 do
						for z = flag.z - 3, flag.z + 3 do
							local pos = {x=x, y=y, z=z}
							if minetest.get_node(pos).name == "default:tree" then
								minetest.set_node(pos, {name="air"})
							end
						end
					end
				end

				-- Spawn chest
				local chest = {name = "ctf_team_base:chest_" .. team.data.color}
				local dz = 2
				if flag.z < 0 then
					dz = -2
					chest.param2 = minetest.dir_to_facedir({x=0,y=0,z=-1})
				end
				local pos = {
					x = flag.x,
					y = flag.y,
					z = flag.z + dz
				}
				minetest.set_node(pos, chest)
				local inv = minetest.get_inventory({type = "node", pos=pos})
				inv:add_item("main", ItemStack("default:cobble 99"))
				inv:add_item("main", ItemStack("default:cobble 99"))
				inv:add_item("main", ItemStack("default:wood 99"))
				inv:add_item("main", ItemStack("default:glass 10"))
				inv:add_item("main", ItemStack("default:torch 10"))
			end
		end
	end
end)
