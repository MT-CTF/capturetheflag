local function do_capture(attname, flag, returned)
	local team = flag.team
	local attacker = ctf.player(attname)

	local flag_name = ""
	if flag.name then
		flag_name = flag.name .. " "
	end
	flag_name = team .. "'s " .. flag_name .. "flag"


	if ctf.setting("flag.capture_take") and not returned then
		for i = 1, #ctf_flag.registered_on_prepick_up do
			if not ctf_flag.registered_on_prepick_up[i](attname, flag) then
				return
			end
		end

		minetest.chat_send_all(flag_name.." has been picked up by "..
				attname.." (team "..attacker.team..")")

		ctf.action("flag", attname .. " picked up " .. flag_name)

		-- Post to flag owner's board
		ctf.post(team, {
				msg = flag_name .. " has been taken by " .. attname .. " of ".. attacker.team,
				icon="flag_red" })

		-- Post to attacker's board
		ctf.post(attacker.team, {
				msg = attname .. " snatched '" .. flag_name .. "' from " .. team,
				icon="flag_green"})

		-- Add to claimed list
		flag.claimed = {
			team = attacker.team,
			player = attname
		}

		ctf.hud.updateAll()

		ctf_flag.update(flag)

		for i = 1, #ctf_flag.registered_on_pick_up do
			ctf_flag.registered_on_pick_up[i](attname, flag)
		end
	else
		for i = 1, #ctf_flag.registered_on_precapture do
			if not ctf_flag.registered_on_precapture[i](attname, flag) then
				return
			end
		end

		minetest.chat_send_all(flag_name.." has been captured "..
				" by "..attname.." (team "..attacker.team..")")

		ctf.action("flag", attname .. " captured " .. flag_name)

		-- Post to flag owner's board
		ctf.post(team, {
				msg = flag_name .. " has been captured by " .. attacker.team,
				icon="flag_red"})

		-- Post to attacker's board
		ctf.post(attacker.team, {
				msg = attname .. " captured '" .. flag_name .. "' from " .. team,
				icon="flag_green"})

		-- Take flag
		if ctf.setting("flag.allow_multiple") then
			ctf_flag.delete(team, vector.new(flag))
			ctf_flag.add(attacker.team, vector.new(flag))
		else
			minetest.set_node(pos,{name="air"})
			ctf_flag.delete(team,pos)
		end

		for i = 1, #ctf_flag.registered_on_capture do
			ctf_flag.registered_on_capture[i](attname, flag)
		end
	end

	ctf.needs_save = true
end

local function player_drop_flag(player)
	return ctf_flag.player_drop_flag(player:get_player_name())
end
minetest.register_on_dieplayer(player_drop_flag)
minetest.register_on_leaveplayer(player_drop_flag)


ctf_flag = {
	on_punch_top = function(pos, node, puncher)
		pos.y = pos.y - 1
		ctf_flag.on_punch(pos, node, puncher)
	end,
	on_rightclick_top = function(pos, node, clicker)
		pos.y = pos.y - 1
		ctf_flag.on_rightclick(pos, node, clicker)
	end,
	on_rightclick = function(pos, node, clicker)
		local name = clicker:get_player_name()
		local flag = ctf_flag.get(pos)
		if not flag then
			return
		end

		if flag.claimed then
			if ctf.setting("flag.capture_take") then
				minetest.chat_send_player(name, "This flag has been taken by "..flag.claimed.player)
				minetest.chat_send_player(name, "who is a member of team "..flag.claimed.team)
				return
			else
				minetest.chat_send_player(name, "Oops! This flag should not be captured. Reverting...")
				flag.claimed = nil
			end
		end
		ctf.gui.flag_board(name, pos)
	end,
	on_punch = function(pos, node, puncher)
		local name = puncher:get_player_name()
		if not puncher or not name then
			return
		end

		local flag = ctf_flag.get(pos)
		if not flag then
			return
		end

		if flag.claimed then
			if ctf.setting("flag.capture_take") then
				minetest.chat_send_player(name, "This flag has been taken by " .. flag.claimed.player)
				minetest.chat_send_player(name, "who is a member of team " .. flag.claimed.team)
				return
			else
				minetest.chat_send_player(name, "Oops! This flag should not be captured. Reverting.")
				flag.claimed = nil
			end
		end

		local team = flag.team
		if not team then
			return
		end

		if ctf.team(team) and ctf.player(name).team then
			if ctf.player(name).team == team then
				-- Clicking on their team's flag
				if ctf.setting("flag.capture_take") then
					ctf_flag._flagret(name)
				end
			else
				-- Clicked on another team's flag
				local diplo = ctf.diplo.get(team, ctf.player(name).team) or
						ctf.setting("default_diplo_state")

				if diplo ~= "war" then
					minetest.chat_send_player(name, "You are at peace with this team!")
					return
				end

				do_capture(name, flag)
			end
		else
			minetest.chat_send_player(name, "You are not part of a team!")
		end
	end,
	_flagret = function(name)
		local claimed = ctf_flag.collect_claimed()
		for i = 1, #claimed do
			local flag = claimed[i]
			if flag.claimed.player == name then
				do_capture(name, flag, true)
			end
		end
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Unowned flag")
		minetest.get_node_timer(pos):start(5)
	end,
	after_place_node = function(pos, placer)
		local name = placer:get_player_name()
		if not pos or not name then
			minetest.set_node(pos, {name="air"})
			return
		end

		local meta = minetest.get_meta(pos)
		if not meta then
			minetest.set_node(pos, {name="air"})
			return
		end

		local tplayer = ctf.player_or_nil(name)
		if tplayer and ctf.team(tplayer.team) then
			if not minetest.check_player_privs(name, {ctf_place_flag=true}) then
				minetest.chat_send_player(name, "You're not allowed to place flags! Reported to admin for investigation.")
				minetest.set_node(pos, {name="air"})
				if minetest.global_exists("chatplus") then
					chatplus.send_mail("*SERVER*", minetest.settings:get("name"),
						"player " .. name .. " attempted to place flag!")
				end
				return
			end

			local tname = tplayer.team
			local team = ctf.team(tplayer.team)
			meta:set_string("infotext", tname.."'s flag")

			-- add flag
			ctf_flag.add(tname, pos)

			-- TODO: fix this hackiness
			if team.spawn and not ctf.setting("flag.allow_multiple") and
					minetest.get_node(team.spawn).name == "ctf_flag:flag"  then
				-- send message
				minetest.chat_send_all(tname .. "'s flag has been moved")
				minetest.set_node(team.spawn, {name="air"})
				minetest.set_node({
					x = team.spawn.x,
					y = team.spawn.y+1,
					z = team.spawn.z
				}, {name="air"})
				team.spawn = pos
			end

			ctf.needs_save = true

			local pos2 = {
				x = pos.x,
				y = pos.y + 1,
				z = pos.z
			}

			if not team.data.color then
				team.data.color = "red"
				ctf.needs_save = true
			end

			minetest.set_node(pos2, {name="ctf_flag:flag_top_"..team.data.color})

			local meta2 = minetest.get_meta(pos2)

			meta2:set_string("infotext", tname.."'s flag")
		else
			minetest.chat_send_player(name, "You are not part of a team!")
			minetest.set_node(pos, {name="air"})
		end
	end
}
