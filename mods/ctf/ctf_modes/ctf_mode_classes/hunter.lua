local S = minetest.get_translator(minetest.get_current_modname())


local hunting = {
	--[[
	hunter = {
		hunting = playername,
		start_time = os.clock(),
	}
	--]]
}

local MIN_DIST_FROM_FLAG = 10
local DAMAGE_BUFF = 0.4
local DAMAGE_NERF = 0.51
local HEAL_AMOUNT = 0.5
local HUNT_TIME = 60
local HUNT_DISTANCE = 100
local MARKER_UPDATE_TIME = 4

local hunt_huds = mhud.init()

local function dist_from_flag(player)
	local tname = ctf_teams.get(player)
	if not tname then return 0 end

	return vector.distance(ctf_map.current_map.teams[tname].flag_pos, player:get_pos())
end

local function stop_hunt(huntername, skip_item)
	hunt_huds:remove(huntername)
	hunt_huds:remove(hunting[huntername].hunting)

	hunting[huntername] = nil

	if not skip_item then
		local hunter = core.get_player_by_name(huntername)

		local inv = hunter:get_inventory()
		local main = inv:get_list("main")

		for idx, item in pairs(main) do
			if item and item:get_name() == "ctf_mode_classes:hunter_token_hunting" then
				inv:set_stack("main", idx, "ctf_mode_classes:hunter_token")
			end
		end
	end
end

local function update_huds(hunter, hunted)
	if not hunt_huds:exists(hunter, "hunted_mark_"..hunted) then
		hunt_huds:add(hunter, "hunted_mark_"..hunted, {
			type = "image_waypoint",
			image_scale = 1,
			texture = "ctf_ranged_rifle_crosshair.png",
			world_pos = core.get_player_by_name(hunted):get_pos():add(vector.new(0, 1, 0)),
		})
	else
		hunt_huds:change(hunter, "hunted_mark_"..hunted, {
			world_pos = core.get_player_by_name(hunted):get_pos():add(vector.new(0, 1, 0)),
		})
	end

	if not hunt_huds:exists(hunted, "hunter_mark_"..hunter) then
		hunt_huds:add(hunted, "hunter_mark_"..hunter, {
			type = "image_waypoint",
			image_scale = 2,
			texture = "ctf_modebase_skull.png^[multiply:#FF1111",
			world_pos = core.get_player_by_name(hunter):get_pos():add(vector.new(0, 1, 0)),
		})
	else
		hunt_huds:change(hunted, "hunter_mark_"..hunter, {
			world_pos = core.get_player_by_name(hunter):get_pos():add(vector.new(0, 1, 0)),
		})
	end
end

local on_cooldown = {}
core.register_craftitem("ctf_mode_classes:hunter_token", {
	description = "Hunt Token\n"..
		"Use to start hunting a random player within "..HUNT_DISTANCE.." nodes from you\n"..
		"The hunt ends after "..HUNT_TIME.."s, or if the target goes near their flag\n"..
		"You deal "..(DAMAGE_BUFF*100).."% more damage to hunted players, and "..
			(DAMAGE_NERF*100).."% less to everyone else (grenades ignore buffs/nerfs)\n"..
		"Killing your mark heals "..(HEAL_AMOUNT*100).."% of your hp\n",
	inventory_image = "binoculars_binoculars.png^ctf_modebase_special_item.png",
	on_use = function(itemstack, user, pointed_thing)
		local username = user:get_player_name()

		if on_cooldown[username] then return end
		on_cooldown[username] = true
		minetest.after(1, function() on_cooldown[username] = nil end)

		if not ctf_modebase.match_started then
			hud_events.new(user, {
				quick = true,
				text = S("Can't use during build time"),
				color = "warning",
			})
			return
		end

		local uteam = ctf_teams.get(user)
		local targets = {}

		local reason = "No enemies in range!"
		for _, p in pairs(ctf_teams.get_connected_players()) do
			if ctf_teams.get(p) ~= uteam and vector.distance(p:get_pos(), user:get_pos()) <= HUNT_DISTANCE then
				if dist_from_flag(p) > MIN_DIST_FROM_FLAG then
					table.insert(targets, {
						hunting = p:get_player_name(),
						start_time = os.clock()
					})
				else
					reason = "The only enemies nearby are at their flag"
				end
			end
		end

		if #targets > 0 then
			hunting[username] = targets[math.random(1, #targets)]
			local pname = hunting[username].hunting
			update_huds(username, pname)

			local existing = hunt_huds:get(pname, "hunting_name")
			local winfo = core.get_player_window_information(pname)
			if not existing then
				hunt_huds:add(pname, "hunting_name", {
					type = "text",
					text = "Hunted by: "..username,
					color = 0xFF1111,
					position = {x = 0.5, y = 1},
					alignment = {x = "right", y = "up"},
					offset = {x = 6, y = (-32 -32 -32 -16) * (winfo and winfo.real_hud_scaling or 1)},
				})
			else
				hunt_huds:change(pname, "hunting_name", {
					text = existing.def.text .. ", " .. username,
				})
			end

			hunt_huds:add(username, "hunting", {
				type = "text",
				text = "Hunting: "..pname,
				color = 0x9df8e5,
				position = {x = 0.5, y = 1},
				alignment = {x = "left", y = "up"},
				offset = {x = -6, y = (-32 -32 -32 -16) * (winfo and winfo.real_hud_scaling or 1)},
			})

			return "ctf_mode_classes:hunter_token_hunting"
		else
			hud_events.new(username, {
				quick = true,
				text = reason,
				color = "warning",
			})
		end
	end
})

core.register_craftitem("ctf_mode_classes:hunter_token_hunting", {
	description = core.registered_items["ctf_mode_classes:hunter_token"].description,
	inventory_image = "default_steel_block.png^ctf_ranged_rifle_crosshair.png^ctf_modebase_special_item.png",
})

local time = 0
core.register_globalstep(function(dtime)
	time = time + dtime

	if time < MARKER_UPDATE_TIME then
		return
	end

	time = 0

	for hunter, hunt in pairs(hunting) do
		local huntedplayer = core.get_player_by_name(hunt.hunting)

		if dist_from_flag(huntedplayer) <= MIN_DIST_FROM_FLAG then
			stop_hunt(hunter)
			hud_events.new(hunter, {
				quick = true,
				text = "Your target got too close to their flag",
				color = "warning",
			})
		elseif os.clock() - hunt.start_time > HUNT_TIME then
			stop_hunt(hunter)
			hud_events.new(hunter, {
				quick = true,
				text = "Your hunt has run out of time",
				color = "warning",
			})
		else
			if os.clock() - hunt.start_time == HUNT_TIME-10 then
				hud_events.new(hunter, {
					text = "Your hunt ends in 10 seconds",
					channel = 2,
					color = "warning",
				})
			end

			update_huds(hunter, hunt.hunting)
		end
	end
end)

core.register_on_dieplayer(function(player, reason)
	local pname = player:get_player_name()

	if reason and reason.type == "punch" and reason.object and reason.object:is_player() then
		local hunter = reason.object
		local hname = hunter:get_player_name()

		if hunting[hname] and hunting[hname].hunting == pname then
			local hp_max = hunter:get_properties().hp_max
			local hp = hunter:get_hp()
			local amount_healed = math.min(hp + math.floor(hp_max * HEAL_AMOUNT), hp_max)

			stop_hunt(hname)

			hud_events.new(hunter, {
				channel = 2,
				text = string.format("Target killed, +%dhp", (amount_healed - hp)/10),
				color = 0x88FF88
			})

			hunter:set_hp(amount_healed)
		end
	end

	if hunting[pname] then
		stop_hunt(pname, true)
	end

	for hunter, hunt in pairs(hunting) do
		if hunt.hunting == pname then
			hud_events.new(hunter, {
				quick = true,
				text = "Target died",
				color = 0xFFFFFF,
			})
			stop_hunt(hunter)
		end
	end
end)

core.register_on_leaveplayer(function(player)
	local playername = player:get_player_name()

	if hunting[playername] then
		stop_hunt(playername, true)
	end

	for hunter, hunt in pairs(hunting) do
		if hunt.hunting == playername then
			hud_events.new(hunter, {
				quick = true,
				text = "Target left the game",
			})
			stop_hunt(hunter)
		end
	end
end)

return {
	on_class_change = function(player, class, oldclass)
		local pname = PlayerName(player)

		if oldclass == "hunter" and hunting[pname] then
			stop_hunt(pname, true)
		end
	end,
	damage_mod = function(player, hitter, tool_capabilities, damage)
		if damage then
			local hname = hitter:get_player_name()
			local pname = player:get_player_name()

			if hunting[hname] then
				if hunting[hname].hunting == pname then
					if tool_capabilities.damage_groups.fleshy and not tool_capabilities.damage_groups.grenade then
						return damage * (1 + DAMAGE_BUFF)
					end
				else
					if tool_capabilities.damage_groups.fleshy and not tool_capabilities.damage_groups.grenade then
						return damage * (1 - DAMAGE_NERF)
					end
				end
			end
		end

		return damage
	end
}