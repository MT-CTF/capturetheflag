local respawn_delay = {}
local hud = mhud.init()

minetest.register_entity("ctf_modebase:respawn_movement_freezer", {
	is_visible = false,
	physical = false,
	makes_footstep_sound = false,
	backface_culling = false,
	static_save = false,
	pointable = false,
	on_punch = function() return true end,
})

local function finish_respawn(player, immunity_after)
	local pname = player:get_player_name()

	if respawn_delay[pname].state == true then
		hud:remove(pname, "left")
	end

	local hp_max = respawn_delay[pname].hp_max
	player:set_properties({hp_max = hp_max, pointable = not immunity_after})
	player:set_hp(hp_max)

	physics.remove(pname, "ctf_modebase:respawn_freeze")

	if respawn_delay[pname].obj then
		respawn_delay[pname].obj:remove()
	end

	if respawn_delay[pname].timer then
		respawn_delay[pname].timer:cancel()
	end
end

local function run_respawn_timer(pname)
	if not respawn_delay[pname] then return end

	respawn_delay[pname].left = respawn_delay[pname].left - 1

	if respawn_delay[pname].left > 0 then
		hud:change(pname, "left", {
			text = string.format("Respawning in %ds", respawn_delay[pname].left)
		})

		respawn_delay[pname].timer = minetest.after(1, run_respawn_timer, pname)
	else
		local player = minetest.get_player_by_name(pname)
		local immunity_after = respawn_delay[pname].immunity_after

		finish_respawn(player, immunity_after)
		respawn_delay[pname] = nil

		if immunity_after then
			minetest.after(immunity_after, function()
				if player then
					player:set_properties({pointable = true})
				end
			end)
		end

		ctf_modebase.player.empty_inv(player)
		ctf_modebase.player.give_initial_stuff(player)

		RunCallbacks(minetest.registered_on_respawnplayers, player)
	end
end

ctf_modebase.respawn_delay = {}

-- Returns true unless player has already been prepped
function ctf_modebase.respawn_delay.prepare(player)
	local pname = player:get_player_name()
	if respawn_delay[pname] then return end

	respawn_delay[pname] = {state = false, hp_max = player:get_properties().hp_max}

	player:set_properties({hp_max = 0, pointable = false})

	physics.set(pname, "ctf_modebase:respawn_freeze", {speed = 0, jump = 0, gravity = 0})

	local obj = minetest.add_entity(player:get_pos(), "ctf_modebase:respawn_movement_freezer")
	if obj then
		player:set_attach(obj)
		respawn_delay[pname].obj = obj
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

	respawn_delay[pname].left = time
	respawn_delay[pname].immunity_after = immunity_after
	respawn_delay[pname].state = true

	hud:add(pname, "left", {
		hud_elem_type = "text",
		position = {x = 0.5, y = 0.1},
		alignment = {x = "center", y = "down"},
		text_scale = 2,
		color = 0xA000B3,
	})

	run_respawn_timer(pname)

	return true
end

ctf_modebase.register_on_match_end(function()
	for pname in pairs(respawn_delay) do
		finish_respawn(minetest.get_player_by_name(pname), nil)
	end
	respawn_delay = {}
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	if respawn_delay[pname] then
		if respawn_delay[pname].obj then
			respawn_delay[pname].obj:remove()
		end
		if respawn_delay[pname].timer then
			respawn_delay[pname].timer:cancel()
		end
		respawn_delay[pname] = nil
	end
end)
