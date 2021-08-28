if ctf_core.settings.server_mode == "play" then
	local old_protected = minetest.is_protected
	minetest.is_protected = function(pos, ...)
		local foundpos = minetest.find_node_near(pos, 2, "ctf_modebase:flag", true)

		if foundpos and pos.y > foundpos.y-1 then
			-- Allow placement of blocks in the corners of the 3x3 flag area (at all heights)
			if vector.distance(vector.new(foundpos.x, 0, foundpos.z), vector.new(pos.x, 0, pos.z)) < 2.8 then
				return true
			end
		end

		return old_protected(pos, ...)
	end
end

local function flag_taken(puncher)
	minetest.chat_send_player(PlayerName(puncher), "This flag was taken!")
end

local function show_flag_color_form(player, target_pos, param2)
	ctf_gui.show_formspec(player, "ctf_modebase:flag_color_select", {
		title = "Flag Color Selection",
		description = "Choose a color for this flag",
		privs = {ctf_map_editor = true},
		elements = {
			teams = {
				type = "dropdown",
				pos = {"center", 0.5},
				items = ctf_teams.teamlist,
			},
			choose = {
				type = "button",
				label = "Choose",
				exit = true,
				pos = {"center", 1.5},
				func = function(playername, fields, field_name)
					if not target_pos or not fields.teams then return end

					minetest.set_node(target_pos, {name = "ctf_modebase:flag_top_"..fields.teams, param2 = param2})
				end,
			},
		},
	})
end

-- The flag
minetest.register_node("ctf_modebase:flag", {
	description = "Flag",
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500}
		}
	},
	groups = {immortal=1,is_flag=1,flag_bottom=1},
	on_punch = function(pos, node, puncher, pointed_thing, ...)
		local pos_above = vector.offset(pos, 0, 1, 0)
		local node_above = minetest.get_node(pos_above)

		if node_above.name ~= "ctf_modebase:flag_captured_top" then
			ctf_modebase.flag_on_punch(puncher, pos_above, node_above)
		end

		minetest.node_punch(pos, node, puncher, pointed_thing, ...)
	end,
	on_rightclick = function(pos, node, clicker)
		local pos_above = vector.offset(pos, 0, 1, 0)
		local node_above = minetest.get_node(pos_above)

		if ctf_core.settings.server_mode == "mapedit" then
			show_flag_color_form(clicker, pos_above, node.param2)
		else
			ctf_modebase.on_flag_rightclick(clicker, pos_above, node_above)
		end
	end,
})

minetest.register_alias("ctf_map:flag", "ctf_modebase:flag")

for name, def in pairs(ctf_teams.team) do
	local color = def.color
	minetest.register_node("ctf_modebase:flag_top_"..name,{
		description = "You are not meant to have this! - flag top",
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		walkable = false,
		buildable_to = false,
		pointable = ctf_core.settings.server_mode ~= "mapedit",
		tiles = {
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"default_wood.png^([combine:16x16:4,0=wool_white.png^[colorize:"..color..":200)",
			"default_wood.png^([combine:12x16:0,0=wool_white.png^[colorize:"..color..":200)"
		},
		node_box = {
			type = "fixed",
			fixed = {
				{0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500},
				{-0.5,0,0.000000,0.250000,0.500000,0.062500}
			}
		},
		groups = {immortal=1,is_flag=1,flag_top=1,not_in_creative_inventory=1,[name]=1},
		on_punch = function(pos, node, puncher, pointed_thing, ...)
			if node.name ~= "ctf_modebase:flag_captured_top" then
				ctf_modebase.flag_on_punch(puncher, pos, node)
			end

			minetest.node_punch(pos, node, puncher, pointed_thing, ...)
		end,
		on_rightclick = function(pos, node, clicker)
			if ctf_core.settings.server_mode == "mapedit" then
				show_flag_color_form(clicker, pos, node.param2)
			else
				ctf_modebase.on_flag_rightclick(clicker, pos, node)
			end
		end,
	})
end

minetest.register_node("ctf_modebase:flag_captured_top",{
	description = "You are not meant to have this! - flag captured",
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500}
		}
	},
	groups = {immortal=1,is_flag=1,flag_top=1,not_in_creative_inventory=1},
	on_punch = function(pos, node, puncher, pointed_thing)
		flag_taken(puncher)
	end,
})
