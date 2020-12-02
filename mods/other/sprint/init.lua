-- Sprint mod by rubenwardy. License: MIT.
-- Heavily modified from a mod by GunshipPenguin

-- Config, see README.md
local MOD_WALK    = tonumber(minetest.settings:get("sprint_speed")     or 1.8)
local MOD_JUMP    = tonumber(minetest.settings:get("sprint_jump")      or 1.1)
local STAMINA_MAX = tonumber(minetest.settings:get("sprint_stamina")   or 20)
local HEAL_RATE   = tonumber(minetest.settings:get("sprint_heal_rate") or 0.5)
local MIN_SPRINT  = tonumber(minetest.settings:get("sprint_min")       or 0.5)

if minetest.get_modpath("hudbars") ~= nil then
	hb.register_hudbar("sprint", 0xFFFFFF, "Stamina",
		{ bar = "sprint_stamina_bar.png", icon = "sprint_stamina_icon.png" },
		STAMINA_MAX, STAMINA_MAX,
		false, "%s: %.1f/%.1f")

	SPRINT_HUDBARS_USED = true
else
	SPRINT_HUDBARS_USED = false
end

local players = {}

local function setSprinting(player, info, sprinting)
	if info.sprinting ~= sprinting then
		if sprinting then
			physics.set(player:get_player_name(), "sprint:sprint", {
				speed = MOD_WALK,
				jump  = MOD_JUMP
			})
		else
			physics.remove(player:get_player_name(), "sprint:sprint")
		end
		info.sprinting = sprinting
	end
end

minetest.register_globalstep(function(dtime)
	for name, info in pairs(players) do
		local player = minetest.get_player_by_name(name)
		if not player then
			players[name] = nil
		else
			-- ##?## You can enable recharging when the E key is pressed by
			--       following these instructions.

			--Check if the player should be sprinting
			local controls = player:get_player_control()
			local sprintRequested = controls.aux1 and controls.up
			-- ##1## replace info.sprintRequested with info.sprinting
			if sprintRequested ~= info.sprintRequested then
				if sprintRequested and info.stamina > MIN_SPRINT
						and not medkits.is_healing(player:get_player_name()) then
					setSprinting(player, info, true)
				elseif not sprintRequested then
					setSprinting(player, info, false)
				end
			end
			info.sprintRequested = sprintRequested

			local staminaChanged = false
			if info.sprinting then
				info.stamina = info.stamina - dtime
				staminaChanged = true
				if info.stamina <= 0 then
					info.stamina = 0
					setSprinting(player, info, false)
				end

			-- ##2## remove `not info.sprintRequested and`
			elseif not info.sprintRequested and info.stamina < STAMINA_MAX then
				info.stamina = info.stamina + dtime * HEAL_RATE
				staminaChanged = true
				if info.stamina > STAMINA_MAX then
					info.stamina = STAMINA_MAX
				end
			end

			if staminaChanged then
				if SPRINT_HUDBARS_USED then
					hb.change_hudbar(player, "sprint", info.stamina)
				else
					local numBars = math.floor(20 * info.stamina / STAMINA_MAX)
					if info.lastHudSendValue ~= numBars then
						info.lastHudSendValue = numBars
						player:hud_change(info.hud, "number", numBars)
					end
				end
			end
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local info = {
		sprinting       = false,       -- Is the player actually sprinting?
		stamina         = STAMINA_MAX, -- integer, the stamina we have left
		sprintRequested = false,       -- is the sprint key down / etc?
	}

	if SPRINT_HUDBARS_USED then
		hb.init_hudbar(player, "sprint")
	else
		info.hud = player:hud_add({
			hud_elem_type = "statbar",
			position      = {x=0.5, y=1},
			size          = {x=24, y=24},
			text          = "sprint_stamina_icon.png",
			number        = 20,
			alignment     = {x=0, y=1},
			offset        = {x=-263, y=-110},
		})
	end

	players[player:get_player_name()] = info
end)

minetest.register_on_respawnplayer(function(player)
	players[player:get_player_name()].stamina = STAMINA_MAX
end)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)
