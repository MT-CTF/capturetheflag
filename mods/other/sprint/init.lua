-- Sprint mod by rubenwardy. License: MIT.
-- Heavily modified from a mod by GunshipPenguin

-- Config, see README.md
local MOD_WALK    = tonumber(minetest.settings:get("sprint_speed")     or 1.8)
local MOD_JUMP    = tonumber(minetest.settings:get("sprint_jump")      or 1.1)
local STAMINA_MAX = tonumber(minetest.settings:get("sprint_stamina")   or 20)
local HEAL_RATE   = tonumber(minetest.settings:get("sprint_heal_rate") or 0.5)
local MIN_SPRINT  = tonumber(minetest.settings:get("sprint_min")       or 0.5)

local players = {}

local function setSprinting(player, sprinting)
	if sprinting then
		physics.set(player:get_player_name(), "sprint:sprint", {
			speed = MOD_WALK,
			jump  = MOD_JUMP
		})
	else
		physics.remove(player:get_player_name(), "sprint:sprint")
	end
end

local function updateHud(player, info)
	local numBars = math.floor(20 * info.stamina / STAMINA_MAX)
	if info.lastHudSendValue ~= numBars then
		info.lastHudSendValue = numBars
		player:hud_change(info.hud, "number", numBars)
	end
end

minetest.register_globalstep(function(dtime)
	for name, info in pairs(players) do
		local player = minetest.get_player_by_name(name)
		--Check if the player should be sprinting
		local controls = player:get_player_control()
		local sprintRequested = controls.aux1 and controls.up

		if sprintRequested and info.stamina > MIN_SPRINT then
			if not info.sprinting then
				info.sprinting = true
				setSprinting(player, true)
			end
		else
			if info.sprinting then
				info.sprinting = false
				setSprinting(player, false)
			end
		end

		if sprintRequested then
			if info.stamina > 0 then
				info.stamina = info.stamina - dtime
				if info.stamina < 0 then
					info.stamina = 0
				end
				updateHud(player, info)
			end
		else
			if info.stamina < STAMINA_MAX then
				info.stamina = info.stamina + dtime * HEAL_RATE
				updateHud(player, info)
			end
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local info = {
		sprinting       = false,       -- Is the player actually sprinting?
		stamina         = STAMINA_MAX, -- integer, the stamina we have left
	}

	info.hud = player:hud_add({
		hud_elem_type = "statbar",
		position      = {x=0.5, y=1},
		size          = {x=24, y=24},
		text          = "sprint_stamina_icon.png",
		text2         = "sprint_stamina_icon_gone.png",
		number        = 20,
		item          = 2 * STAMINA_MAX,
		alignment     = {x=0, y=1},
		offset        = {x=-263, y=-110},
	})

	players[player:get_player_name()] = info
end)

ctf_api.register_on_respawnplayer(function(player)
	local info = players[player:get_player_name()]
	if info.stamina < STAMINA_MAX then
		info.stamina = STAMINA_MAX
		updateHud(player, info)
	end
end)

minetest.register_on_respawnplayer(function(player)
	local info = players[player:get_player_name()]
	if info.stamina < STAMINA_MAX then
		info.stamina = STAMINA_MAX
		updateHud(player, info)
	end
end)

ctf_api.register_on_new_match(function()
	for name, info in pairs(players) do
		if info.stamina < STAMINA_MAX then
			info.stamina = STAMINA_MAX
			updateHud(minetest.get_player_by_name(name), info)
		end
	end
end)

ctf_api.register_on_flag_take(function(taker, flag_team)
	local tname = taker:get_player_name()

	players[tname].stamina = STAMINA_MAX
	updateHud(taker, players[tname])
end)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)
