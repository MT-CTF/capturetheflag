local respawn_delay = {}
local hud = mhud.init()

local function finish_respawn(pname, player, immunity_after)
	if respawn_delay[pname].state == true then
		hud:remove(pname, "timer")
	end

	local hp_max = respawn_delay[pname].hp_max
	player:set_properties({hp_max = hp_max, pointable = not immunity_after})
	player:set_hp(hp_max)

	physics.remove(pname, "ctf_modebase:respawn_freeze")
end

local function run_respawn_timer(pname)
	if not respawn_delay[pname] then return end

	respawn_delay[pname].timer = respawn_delay[pname].timer - 1

	if respawn_delay[pname].timer > 0 then
		hud:change(pname, "timer", {
			text = string.format("Respawning in %ds", respawn_delay[pname].timer)
		})

		minetest.after(1, run_respawn_timer, pname)
	else
		local player = minetest.get_player_by_name(pname)
		local immunity_after = respawn_delay[pname].immunity_after

		finish_respawn(pname, player, immunity_after)

		if immunity_after then
			minetest.after(immunity_after, function()
				if player then
					player:set_properties({pointable = true})
				end
			end)
		end

		respawn_delay[pname] = nil

		RunCallbacks(minetest.registered_on_respawnplayers, player)
	end
end

ctf_modebase.respawn_delay = {}

-- Returns true unless player has already been prepped
function ctf_modebase.respawn_delay.prepare(player)
	local pname = player:get_player_name()

	if not respawn_delay[pname] then
		respawn_delay[pname] = {state = false, hp_max = player:get_properties().hp_max}

		player:set_properties({hp_max = 0, pointable = false})

		physics.set(pname, "ctf_modebase:respawn_freeze", {speed = 0, jump = 0, gravity = 0})

		return true
	end
end

-- Returns false if timer is up, true if timer is ongoing
function ctf_modebase.respawn_delay.respawn(player, time, immunity_after)
	local pname = player:get_player_name()
	if not respawn_delay[pname] then return false end

	if respawn_delay[pname].state == true then
		return true
	end

	assert(time >= 1, "Delay time must be >= 1!")

	respawn_delay[pname].timer = time
	respawn_delay[pname].immunity_after = immunity_after
	respawn_delay[pname].state = true

	hud:add(pname, "timer", {
		hud_elem_type = "text",
		position = {x = 0.5, y = 0.1},
		alignment = {x = "center", y = "down"},
		text_scale = 2,
		color = 0xA000B3,
	})

	run_respawn_timer(pname)

	return true
end

function ctf_modebase.respawn_delay.on_match_end()
	for pname in pairs(respawn_delay) do
		finish_respawn(pname, minetest.get_player_by_name(pname), nil)
	end
	respawn_delay = {}
end

minetest.register_on_leaveplayer(function(player)
	respawn_delay[player:get_player_name()] = nil
end)
