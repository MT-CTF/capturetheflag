ctf_marker = {}

-- Locally cache list of team members when adding
-- marker, because the members in the team needn't
-- be the same within an extended duration of time
local teams = {}
local visibility_time = 30

-- Convenience function that returns passed
-- string enclosed by color escape codes
local function msg(str)
	if not str then
		return
	end
	return minetest.colorize("#ABCDEF", str)
end

-- Remove waypoint element for valid players in team tname
function ctf_marker.remove_marker(tname)
	if not teams[tname] then return end

	for name, hud in pairs(teams[tname].players) do
		local player = minetest.get_player_by_name(name)
		if player then
			player:hud_remove(hud)
		end
	end
	teams[tname] = nil
end

-- Add waypoint element to all players in the same team as name
function ctf_marker.add_marker(name, tname, pos, str)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	local team = ctf.team(tname)

	teams[tname] = {
		players = {},
		time = 0
	}

	for pname, _ in pairs(team.players) do
		local tplayer = minetest.get_player_by_name(pname)
		if tplayer then
			teams[tname].players[pname] = tplayer:hud_add({
				hud_elem_type = "waypoint",
				name          = str,
				number        = tonumber(ctf.flag_colors[team.data.color]),
				world_pos     = pos
			})
		end
		minetest.log("action", name .. " placed a marker at " ..
				minetest.pos_to_string(pos) .. ": '" .. str .. "'")
		minetest.chat_send_player(pname,
				msg("* " .. name .. " placed a marker!"))
	end
end

minetest.register_globalstep(function(dtime)
	for tname, team in pairs(teams) do
		-- Increment time of team marker
		local time = team.time + dtime
		teams[tname].time = time

		-- If time > visibility_time, destroy team marker
		if time >= visibility_time then
			ctf_marker.remove_marker(tname)
		end
	end
end)

minetest.register_chatcommand("m", {
	param = "[Optional description]",
	description = "Allows players to share the location of where " ..
			"they're looking at with their team-mates.",
	privs = { interact = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end

		-- Calculate marker pos
		local dir = player:get_look_dir()
		local p1 = vector.add(player:get_pos(),
				{ x = 0, y = player:get_properties().eye_height, z = 0 })
		p1 = vector.add(p1, dir)
		local p2 = vector.add(p1, vector.multiply(dir, 500))
		local pointed = minetest.raycast(p1, p2, true, true):next()

		if not pointed then
			minetest.chat_send_player(name, msg("Pointed thing out of range!"))
			return
		end

		local tname = ctf.player(name).team

		-- Handle waypoint string
		local str = (param and param:trim() ~= "") and param or name .. "'s marker"
		if pointed.type == "object" then
			local concat
			local obj = pointed.ref
			local entity = obj:get_luaentity()

			-- If object is a player, append player name to display text
			-- Else if obj is item entity, append item description and count to str.
			if obj:is_player() then
				concat = obj:get_player_name()
			elseif entity then
				if entity.name == "__builtin:item" then
					local stack = ItemStack(entity.itemstring)
					local itemdef = minetest.registered_items[stack:get_name()]

					-- Fallback to itemstring if description doesn't exist
					concat = itemdef.description or entity.itemstring
					concat = concat .. " " .. stack:get_count()
				else
					-- Pointed thing is a trivial entity, abort
					minetest.chat_send_player(name,
							msg("Invalid marker position. Please try again."))
					return
				end
			end
			str = concat and str .. " <" .. concat .. ">"
		end
		str = "[" .. str .. "]"

		-- Remove existing marker if it exists
		ctf_marker.remove_marker(tname)

		ctf_marker.add_marker(name, tname, minetest.get_pointed_thing_position(pointed), str)
	end
})
