local items_to_sell = {
	{ "default:sword_diamond 1", "default:gold_ingot 6" },
	{ "default:sword_mese 1", "default:gold_ingot 5" },
}

local function get_shop_formspec()
	local result = ""
	local size_w = 0
	local size_h = 0
	for _, trade in pairs(items_to_sell) do
		result = result ..
			string.format("item_image_button[%d,%d;%d,%d;%s;%s;]", size_w + 1, size_h + 1, 1, 1, trade[2], trade[2])
		result = result ..
			string.format("item_image[%d,%d;%d,%d;%s]", size_w + 2, size_h + 1, 1, 1, trade[1])
		size_h = size_h + 1
		if size_h >= 5 then
			size_w = size_w + 3
			size_h = 0
		end
	end
	return string.format("size[%d,%d]", size_w + 2, 5)
end


minetest.register_node("ctf_mode_flagwars:shop", {
	walkable = true,
	pointable = true,
	diggable = false,
	on_rightclick = function(pos, node, clicker, itemstack)
		local pname = clicker:get_player_name()
		if pname == "" then
			return
		end
		local team = ctf_teams.get_team(pname)
		local meta = minetest.get_meta(pos)
		if team ~= meta:get_string("team") then
			minetest.chat_send_player(pname, "You are not on this shop's team")
			return itemstack
		end

		minetest.show_formspec(pname, "ctf_modes_flagwars:shop", get_shop_formspec())
		return itemstack
	end,
	on_construct = function(pos)
		if not ctf_map.current_map then
			return
		end
		local closest_team = { team = "none", distance = -1 }
		for team, team_props in pairs(ctf_map.current_map.teams) do
			local dist = vector.distance(team_props.flag_pos, pos)
			if dist < closest_team["distance"] then
				closest_team["distance"] = dist
				closest_team["team"] = team
			end
		end
		local team_number = string.match(closest_team["team"], "team.(.*)")
		local team_color
		local i = 0
		for team, _ in pairs(ctf_teams["team"]) do
			if i == team_number then
				team_color = team
			end
			i = i + 1
		end
		local meta = minetest.get_meta(pos)
		meta:set_string("team", team_color)
	end
})
