local function explode(pos)
	-- TODO:
	-- make some blasts
	-- damage nearby players?
	-- destroy destructible nearby nodes?
end

minetest.register_node("ctf_modes_flagwars:shop", {
	walkable = true,
	pointable = true,
	diggable = false,
	on_punch = function(pos, node, puncher, pointed_thing)
		local pname = puncher:get_player_name()
		if pname == "" then
			return
		end
		local meta = minetest.get_meta(pos)
		if ctf_teams.get(pname) == meta:get_string("team") then
			return
		end
		local hp = tonumber(meta:get_string("hp"))
		hp = hp - 1
		if hp <= 0 then
			minetest.remove_node(pos)
			explode(pos)
			return
		end
		meta:set_string("hp" tostring(hp))
		-- TODO: play some notifying sound
	end,
	on_construct = function(pos)
		-- shop team must be set by the game stored in "team"
		local meta = minetest.get_meta(pos)
		meta:set_string("hp", tostring(150))		
	end,
})
