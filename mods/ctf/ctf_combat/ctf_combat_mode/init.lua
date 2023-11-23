local hud = mhud.init()
local hitters = {}
local healers = {}

ctf_combat_mode = {}

local function update(player)
	local combat = hitters[player]

	if combat.time <= 0 then
		hud:remove(player, "combat_indicator")
		hitters[player] = nil
		return
	end

	local hud_message = "You are in combat [%ds left] \n%s"
	hud_message = hud_message:format(combat.time, combat.suffocation_message)

	if hud:exists(player, "combat_indicator") then
		hud:change(player, "combat_indicator", {
			text = hud_message
		})
	else
		hud:add(player, "combat_indicator", {
			hud_elem_type = "text",
			position = {x = 1, y = 0.2},
			alignment = {x = "left", y = "down"},
			offset = {x = -6, y = 0},
			text = hud_message,
			color = 0xF00000,
		})
	end

	local pos = vector.offset(minetest.get_player_by_name(player):get_pos(), 0, 0.5, 0)
	local node = minetest.registered_nodes[minetest.get_node(pos).name]

	if node.groups.real_suffocation then -- From real_suffocation mod
		combat.time = combat.time + 0.5
		combat.suffocation_message = "You are inside blocks. Move out to stop your combat timer from increasing."
	else
		combat.time = combat.time - 1
		combat.suffocation_message = ""
	end

	combat.timer = minetest.after(1, update, player)
end

function ctf_combat_mode.add_hitter(player, hitter, weapon_image, time)
	player = PlayerName(player)
	hitter = PlayerName(hitter)

	if not hitters[player] then
		hitters[player] = {hitters={}, time=time}
	end

	local combat = hitters[player]
	combat.hitters[hitter] = true
	combat.time = time
	combat.last_hitter = hitter
	combat.weapon_image = weapon_image
	combat.suffocation_message = ""

	if not combat.timer then
		update(player)
	end
end

function ctf_combat_mode.add_healer(player, healer, time)
	player = PlayerName(player)
	healer = PlayerName(healer)

	if not healers[player] then
		healers[player] = {healers={}, timer=minetest.after(time, function()
			healers[player] = nil
		end)}
	end

	healers[player].healers[healer] = true
end

function ctf_combat_mode.get_last_hitter(player)
	player = PlayerName(player)

	if hitters[player] then
		return hitters[player].last_hitter, hitters[player].weapon_image
	end
end

function ctf_combat_mode.get_other_hitters(player, last_hitter)
	player = PlayerName(player)

	local ret = {}

	if hitters[player] then
		for pname in pairs(hitters[player].hitters) do
			if pname ~= last_hitter then
				table.insert(ret, pname)
			end
		end
	end

	return ret
end


function ctf_combat_mode.get_healers(player)
	player = PlayerName(player)

	local ret = {}

	if healers[player] then
		for pname in pairs(healers[player].healers) do
			table.insert(ret, pname)
		end
	end

	return ret
end

function ctf_combat_mode.is_only_hitter(player, hitter)
	player = PlayerName(player)

	if not hitters[player] then
		return false
	end

	for pname in pairs(hitters[player].hitters) do
		if pname ~= hitter then
			return false
		end
	end

	return true
end

function ctf_combat_mode.set_kill_time(player, time)
	player = PlayerName(player)

	if hitters[player] then
		hitters[player].time = time
	end
end

function ctf_combat_mode.in_combat(player)
	return hitters[PlayerName(player)] and true or false
end

function ctf_combat_mode.end_combat(player)
	player = PlayerName(player)

	if hitters[player] then
		if hud:exists(player, "combat_indicator") then
			hud:remove(player, "combat_indicator")
		end

		hitters[player].timer:cancel()
		hitters[player] = nil
	end

	if healers[player] then
		healers[player].timer:cancel()
		healers[player] = nil
	end
end

ctf_api.register_on_match_end(function()
	for _, combat in pairs(hitters) do
		combat.timer:cancel()
	end
	hitters = {}
	for _, combat in pairs(healers) do
		combat.timer:cancel()
	end
	healers = {}
	hud:remove_all()
end)
