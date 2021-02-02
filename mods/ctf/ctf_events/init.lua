local hud = hudkit()

minetest.register_on_leaveplayer(function(player)
	hud.players[player:get_player_name()] = nil
end)

local NUM_EVT = 6

ctf_events = {
	events = {}
}

function ctf_events.post(action, one, two, assistant)
	table.insert(ctf_events.events, 1, {
		action = action,
		one = one,
		two = two,
		assist = assistant
	})

	while #ctf_events.events > NUM_EVT do
		table.remove(ctf_events.events, #ctf_events.events)
	end
end

function ctf_events.update_row(i, player, name, tplayer, evt)
	local idx = "ctf_events:" .. i .. "_one"
	local idxa = "ctf_events:" .. i .. "_action"
	local idx2 = "ctf_events:" .. i .. "_two"

	if not evt then
		hud:remove(player, idx)
		hud:remove(player, idxa)
		hud:remove(player, idx2)
		return
	end

	local y_pos = i * 20

	-- One
	if evt.one then
		local tcolor = ctf_colors.get_color(ctf.player(evt.one))
		local txt = evt.assist or evt.one
		if hud:exists(player, idx) then
			hud:change(player, idx, "text", txt)
			hud:change(player, idx, "number", tcolor.hex)
		else
			local tmp = {
				hud_elem_type = "text",
				position      = {x = 0, y = 0.8},
				scale         = {x = 200, y = 100},
				text          = txt,
				number        = tcolor.hex,
				offset        = {x = 145, y = -y_pos},
				alignment     = {x = -1, y = 0}
			}
			hud:add(player, idx, tmp)
		end
	else
		hud:remove(player, idx)
	end

	-- Two
	if evt.two then
		local tcolor = ctf_colors.get_color(ctf.player(evt.two))
		if hud:exists(player, idx2) then
			hud:change(player, idx2, "text", evt.two)
			hud:change(player, idx2, "number", tcolor.hex)
		else
			local tmp = {
				hud_elem_type = "text",
				position      = {x = 0, y = 0.8},
				scale         = {x = 200, y = 100},
				text          = evt.two,
				number        = tcolor.hex,
				offset        = {x = 175, y = -y_pos},
				alignment     = {x = 1, y = 0}
			}
			hud:add(player, idx2, tmp)
		end
	else
		hud:remove(player, idx2)
	end

	-- Action
	if evt.action then
		if hud:exists(player, idxa) then
			hud:change(player, idxa, "text", "ctf_events_" .. evt.action .. ".png")
		else
			local tmp = {
				hud_elem_type = "image",
				position      = {x = 0, y = 0.8},
				scale         = {x = 1, y = 1},
				text          = "ctf_events_" .. evt.action .. ".png",
				offset        = {x = 160, y = -y_pos},
				alignment     = {x = 0, y = 0}
			}
			hud:add(player, idxa, tmp)
		end
	else
		hud:remove(player, idxa)
	end
end

function ctf_events.update(player)
	local name = player:get_player_name()
	local tplayer = ctf.player_or_nil(name)
	if tplayer then
		for i=1, NUM_EVT do
			local evt = nil
			if #ctf_events.events >= i then
				evt = ctf_events.events[i]
			end
			ctf_events.update_row(i, player, name, tplayer, evt)
		end
	end
end

function ctf_events.update_all()
	for _, player in pairs(minetest.get_connected_players()) do
		ctf_events.update(player)
	end
end

local good_weapons = {
	"default:sword_steel",
	"default:sword_bronze",
	"default:sword_mese",
	"default:sword_diamond",
	"default:pick_mese",
	"default:pick_diamond",
	"default:axe_mese",
	"default:axe_diamond",
	"default:shovel_mese",
	"default:shovel_diamond",
	"shooter:grenade",
	"shooter:shotgun",
	"shooter:rifle",
	"shooter:machine_gun",
	"sniper_rifles:rifle_762",
	"sniper_rifles:rifle_magnum",
}

local function invHasGoodWeapons(inv)
	for _, weapon in pairs(good_weapons) do
		if inv:contains_item("main", weapon) then
			return true
		end
	end
	return false
end

local function calculateKillReward(victim, killer, toolcaps)
	local vmain, victim_match = ctf_stats.player(victim)

	if not vmain or not victim_match then return 5 end

	-- +5 for every kill they've made since last death in this match.
	local reward = victim_match.kills_since_death * 5
	ctf.log("ctf_stats", "Player " .. victim .. " has made " .. reward ..
			" score worth of kills since last death")

	-- 30 * K/D ratio, with variable based on player's score
	local kdreward = 30 * vmain.kills / (vmain.deaths + 1)
	local max = vmain.score / 5
	if kdreward > max then
		kdreward = max
	end
	if kdreward > 100 then
		kdreward = 100
	end
	reward = reward + kdreward

	-- Limited to  5 <= X <= 250
	if reward > 250 then
		reward = 250
	elseif reward < 5 then
		reward = 5
	end

	-- Half if no good weapons, +50% if combat logger
	local inv = minetest.get_inventory({ type = "player", name = victim })

	if toolcaps.damage_groups.combat_log == 1 then
		ctf.log("ctf_stats", "Player " .. victim .. " is a combat logger")
		reward = reward * 1.5
	elseif not invHasGoodWeapons(inv) then
		ctf.log("ctf_stats", "Player " .. victim .. " has no good weapons")
		reward = reward * 0.5
	else
		ctf.log("ctf_stats", "Player " .. victim .. " has good weapons")
	end

	return reward
end

ctf.register_on_killedplayer(function(victim, killer, stack, tool_caps)
	local reward = calculateKillReward(victim, killer, tool_caps)
	reward = math.floor(reward * 100) / 100
	ctf.reward_assists(victim, killer, reward)
	local type = "sword"

	if tool_caps.damage_groups.grenade then
		type = "grenade"
	elseif tool_caps.damage_groups.rocket then
		type = "rocket"
	elseif tool_caps.damage_groups.ranged then
		type = "bullet"
	elseif tool_caps.damage_groups.sniper then
		type = "sniper"
	end

	if tool_caps.damage_groups.combat_log then
		victim = victim .. " (Combat Log)"
	elseif tool_caps.damage_groups.suicide then
		victim = victim .. " (Suicide?)"
	end

	local assistant = ctf.get_last_assist(victim)
	local assistname = nil
	if assistant then
		assistname = assistant.." + "..killer
	end
	ctf_events.post("kill_" .. type, killer, victim, assistname)
	ctf_events.update_all()
	ctf.clear_assists(victim)
end)

minetest.register_on_joinplayer(function(player)
	ctf_events.update(player)
end)

ctf_match.register_on_new_match(function()
	ctf_events.events = {}
	ctf_events.update_all()
end)
