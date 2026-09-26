local RESPAWN_IMMUNITY_SECONDS = 6

local immune_players = { --[[
	pname = {
		timer = <core.after job> | false,
		particles = <particlespawner id>,
		immunity_duration = <seconds>,
		accumulated_time = <seconds>,
	},
	...
]] }

local mhud = mhud.init()

local function create_immune_hud(player, respawn_timer)
	local pname = player:get_player_name()
	local info = immune_players[pname]

	-- Screen tint overlay
	mhud:add(player, "ctf_immune_overlay", {
		hud_elem_type = "image",
		position = {x = 0.5, y = 0.5},
		offset = {x = 0, y = 0},
		alignment = {x = 0, y = 0},
		scale = {x = -120, y = -120},
		text = "[fill:1x1:#22DDFF22",
		z_index = -400,
	})

	-- Countdown HUD
	mhud:add(player, "ctf_immune", {
		hud_elem_type = "text",
		position = {x = 0.5, y = 1},
		offset = {x = 0, y = -132},
		alignment = {x = "center", y = "bottom"},
		text = "Immune to enemy dmg: " .. respawn_timer .. "s",
		color = 0x00FFFF,
		text_scale = 1.5,
	})
	info.immunity_duration = respawn_timer
	info.accumulated_time = 0
end

local function remove_immune_hud(info, player)
	if player then
		if mhud:exists(player, "ctf_immune") then
			mhud:remove(player, "ctf_immune")
		end
		if mhud:exists(player, "ctf_immune_overlay") then
			mhud:remove(player, "ctf_immune_overlay")
		end
	end

	info.immunity_duration = nil
	info.accumulated_time = nil
end

local hud_update_timer = 0
core.register_globalstep(function(dtime)
	hud_update_timer = hud_update_timer + dtime
	if hud_update_timer < 0.4 then return end

	for pname, info in pairs(immune_players) do
		if info.accumulated_time then
			info.accumulated_time = info.accumulated_time + hud_update_timer
		end
	end
	hud_update_timer = 0

	local expired = {}
	for pname, info in pairs(immune_players) do
		if info.accumulated_time then
			local player = core.get_player_by_name(pname)
			if player then
				if info.accumulated_time >= info.immunity_duration then
					table.insert(expired, pname)
				else
					local remaining = math.ceil(info.immunity_duration - info.accumulated_time)
					mhud:change(player, "ctf_immune", {text = "Immune to enemy dmg: " .. remaining .. "s"})
				end
			else
				table.insert(expired, pname)
			end
		end
	end

	for _, pname in ipairs(expired) do
		ctf_modebase.remove_immunity(pname)
	end
end)

function ctf_modebase.is_immune(player)
	return immune_players[PlayerName(player)] ~= nil
end

local old_get_skin = ctf_cosmetics.get_skin
ctf_cosmetics.get_skin = function(player, color)
	if ctf_modebase.is_immune(player) then
		return old_get_skin(player, color) .. "^[colorize:#fff:80^[multiply:#85beff"
	else
		return old_get_skin(player, color)
	end
end

function ctf_modebase.give_immunity(player, respawn_timer, hud_duration)
	local pname = player:get_player_name()
	local old = immune_players[pname]

	if old then
		if old.timer then
			old.timer:cancel()
		end

		if old.particles then
			core.delete_particlespawner(old.particles)
		end

		remove_immune_hud(old, player)
	end

	if respawn_timer then
		immune_players[pname] = {
			timer = core.after(respawn_timer, ctf_modebase.remove_immunity, pname),
		}
	else
		immune_players[pname] = {
			timer = false,
		}
	end

	local hud_timer
	if hud_duration == false then
		hud_timer = nil
	else
		hud_timer = hud_duration or respawn_timer
	end
	if hud_timer then
		create_immune_hud(player, hud_timer)
	end

	immune_players[pname].particles = core.add_particlespawner({
		time = respawn_timer or 0,
		amount = 8 * (respawn_timer or 1),
		collisiondetection = false,
		texture = "ctf_modebase_immune.png",
		glow = 10,
		attached = player,

		pos = vector.new(0, 1.2, 0),
		attract = {
			kind = "point",
			strength = 2,
			origin = vector.new(0, 1.2, 0),
			origin_attached = player,
			die_on_contact = true,
		},
		radius = {min = 0.8, max = 1.3, bias = 1},

		minexptime = 0.3,
		maxexptime = 0.3,
		minsize = 1,
		maxsize = 2,
	})

	if old == nil then
		if player_api.players[pname] then
			player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))
		end
		player:set_properties({pointable = false})
		player:set_armor_groups({fleshy = 0})
	end
end

function ctf_modebase.remove_immunity(pname)
	if type(pname) == "userdata" and pname.get_player_name then
		core.log("error", "[ctf_modebase] remove_immunity called with player object, use player name instead")
		pname = pname:get_player_name()
	end
	local old = immune_players[pname]

	if old == nil then return end

	if old.timer then
		old.timer:cancel()
	end

	if old.particles then
		core.delete_particlespawner(old.particles)
	end

	local player = core.get_player_by_name(pname)
	if not player then
		immune_players[pname] = nil
		return
	end

	remove_immune_hud(old, player)

	immune_players[pname] = nil

	if player_api.players[pname] then
		player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))
	end

	player:set_properties({pointable = true})
	player:set_armor_groups({fleshy = 100})
end

-- Remove immunity and return true if it's respawn immunity, return false otherwise
function ctf_modebase.remove_respawn_immunity(pname)
	if type(pname) == "userdata" and pname.get_player_name then
		core.log("error", "[ctf_modebase] remove_respawn_immunity called with player object, use player name instead")
		pname = pname:get_player_name()
	end
	local old = immune_players[pname]

	if old == nil then return true end
	if old.timer == false then return false end

	old.timer:cancel()

	if old.particles then
		core.delete_particlespawner(old.particles)
	end

	local player = core.get_player_by_name(pname)
	if player then
		remove_immune_hud(old, player)

		if player_api.players[pname] then
			player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))
		end

		player:set_properties({pointable = true})
		player:set_armor_groups({fleshy = 100})
	end

	immune_players[pname] = nil

	return true
end

ctf_teams.register_on_allocplayer(function(player)
	ctf_modebase.give_immunity(player, RESPAWN_IMMUNITY_SECONDS)
end)

ctf_api.register_on_respawnplayer(function(player)
	ctf_modebase.give_immunity(player, RESPAWN_IMMUNITY_SECONDS)
end)

core.register_on_dieplayer(function(player)
	ctf_modebase.remove_immunity(player:get_player_name())
	player:set_properties({pointable = false})
end)

core.register_on_leaveplayer(function(player)
	ctf_modebase.remove_immunity(player:get_player_name())
end)
