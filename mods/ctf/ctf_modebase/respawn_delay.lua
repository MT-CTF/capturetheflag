local RESPAWN_SECONDS = 7
local AUTO_RESPAWN_TIME = 0.4
local respawn_delay = {--[[
	pname = {
		obj = <freeze object>,
		timer = <minetest.after job>,
		timer = <minetest.after job>,
		hp_max = <Player's max hp before respawn process started>,
		left = <Time left to respawn>,
		state = <?>,
	}
]]}
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

local function finish_respawn(player)
	local pname = player:get_player_name()

	if respawn_delay[pname].state == true then
		hud:remove(pname, "left")
	end

	local hp_max = respawn_delay[pname].hp_max
	player:set_properties({hp_max = hp_max, pointable = true})
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

		finish_respawn(player)
		respawn_delay[pname] = nil

		ctf_modebase.on_respawnplayer(player)
	end
end

local function respawn(player, time)
	local pname = player:get_player_name()
	if not respawn_delay[pname] or respawn_delay[pname].state == true then return end

	assert(time >= 1, "Delay time must be >= 1!")

	respawn_delay[pname].left = time
	respawn_delay[pname].state = true

	hud:add(pname, "left", {
		hud_elem_type = "text",
		position = {x = 0.5, y = 0.1},
		alignment = {x = "center", y = "down"},
		text_scale = 2,
		color = 0xA000B3,
	})

	run_respawn_timer(pname)
end

local function trigger_respawn(pname)
	if respawn_delay[pname] then
		if respawn_delay[pname].autorespawn then
			respawn_delay[pname].autorespawn:cancel()
			respawn_delay[pname].autorespawn = nil
		end

		respawn(minetest.get_player_by_name(pname), RESPAWN_SECONDS)
	else
		local player = minetest.get_player_by_name(pname)

		if player then
			ctf_modebase.on_respawnplayer(player)
		end
	end
end

function ctf_modebase.prepare_respawn_delay(player)
	local pname = player:get_player_name()
	if respawn_delay[pname] then return end

	respawn_delay[pname] = {state = false, hp_max = player:get_properties().hp_max}

	player:set_properties({hp_max = 0})

	physics.set(pname, "ctf_modebase:respawn_freeze", {speed = 0, jump = 0, gravity = 0})

	local obj = minetest.add_entity(player:get_pos(), "ctf_modebase:respawn_movement_freezer")
	if obj then
		player:set_attach(obj)
		respawn_delay[pname].obj = obj
	end

	respawn_delay[pname].autorespawn = minetest.after(AUTO_RESPAWN_TIME, function()
		minetest.close_formspec(pname, "") -- This is the only way to close clientside formspecs
		trigger_respawn(pname)
	end)
end

ctf_api.register_on_match_end(function()
	for pname in pairs(respawn_delay) do
		finish_respawn(minetest.get_player_by_name(pname))
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
		if respawn_delay[pname].autorespawn then
			respawn_delay[pname].autorespawn:cancel()
		end
		player:set_properties({hp_max = respawn_delay[pname].hp_max})
		respawn_delay[pname] = nil
	end

	player:set_hp(player:get_properties().hp_max)
end)

minetest.register_on_respawnplayer(function(player)
	local pname = player:get_player_name()

	trigger_respawn(pname)

	return true
end)
