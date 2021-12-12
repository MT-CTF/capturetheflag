local hud = mhud.init()
local combats = {}

ctf_combat_mode = {}

local function update(player)
	local combat = combats[player]

	if combat.time <= 0 then
		hud:remove(player, "combat_indicator")
		combats[player] = nil
		return
	end

	local hud_message = "You are in combat [%ds left]"
	hud_message = hud_message:format(combat.time)

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

	local pos = vector.offset(minetest.get_player_by_name(player):get_pos(), 0, 1, 0)
	local node = minetest.registered_nodes[minetest.get_node(pos).name]

	if node.walkable == false then
		combat.time = combat.time - 1
	else
		combat.time = combat.time + 0.5
	end

	combat.timer = minetest.after(1, update, player)
end

function ctf_combat_mode.set(player, combatant, type, time, in_combat)
	player = PlayerName(player)
	combatant = PlayerName(combatant)

	if not combats[player] then
		combats[player] = {combatants = {}, in_combat = false}
	end

	combats[player].combatants[combatant] = type

	if in_combat then
		combats[player].in_combat = true
		combats[player].time = time

		if combats[player].timer then
			combats[player].timer:cancel()
		end

		update(player)
	elseif not combats[player].in_combat then
		if combats[player].timer then
			combats[player].timer:cancel()
		end

		combats[player].timer = minetest.after(time, function()
			combats[player] = nil
		end)
	end
end

function ctf_combat_mode.get(player, type)
	player = PlayerName(player)

	local ret = {}

	if combats[player] then
		for k, v in pairs(combats[player].combatants) do
			if v == type then
				table.insert(ret, k)
			end
		end
	end

	return ret
end

function ctf_combat_mode.set_time(player, time)
	player = PlayerName(player)
	if combats[player] and combats[player].in_combat then
		combats[player].timer.cancel()
		combats[player].time = time
		update(player)
	end
end

function ctf_combat_mode.in_combat(player)
	player = PlayerName(player)
	if combats[player] and combats[player].in_combat then
		return true
	end
	return false
end

function ctf_combat_mode.remove(player)
	player = PlayerName(player)

	if combats[player] then
		if combats[player].in_combat then
			hud:remove(player, "combat_indicator")
		end

		combats[player].timer.cancel()
		combats[player] = nil
	end
end

ctf_modebase.register_on_match_end(function()
	for _, combat in pairs(combats) do
		combat.timer.cancel()
	end
	combats = {}
	hud:remove_all()
end)
