local function regen_update()
	local get = ctf_classes.get
	local players = minetest.get_connected_players()
	local medic_by_team = { red = {}, blue = {} }
	local tnames = {}
	local found_medic = false

	-- First get medic positions and team names
	for i=1, #players do
		local player = players[i]
		local pname = player:get_player_name()
		local class = get(player)
		local tname = ctf.player(pname).team

		if medic_by_team[tname] == nil then return end

		tnames[pname] = tname
		if class.properties.nearby_hpregen then
			if tname then
				medic_by_team[tname][#medic_by_team[tname] + 1] = player:get_pos()
				found_medic = true
			end
		end
	end

	if not found_medic then
		return
	end

	-- Next, update hp

	local function sqdist(a, b)
		local x = a.x - b.x
		local y = a.y - b.y
		local z = a.z - b.z
		return x*x + y*y + z*z
	end

	for i=1, #players do
		local player = players[i]
		local pname = player:get_player_name()
		local tname = tnames[pname]
		local hp = player:get_hp()
		local max_hp = player:get_properties().hp_max
		if tname and hp ~= max_hp and hp > 0 then
			local pos = player:get_pos()
			local medics = medic_by_team[tname]
			for j=1, #medics do
				if sqdist(pos, medics[j]) < 100 then
					hp = hp + hpregen.amount
					player:set_hp(hp)
					break
				end
			end
		end
	end
end

local update = hpregen.interval / 2
minetest.register_globalstep(function(delta)
	update = update + delta
	if update < hpregen.interval then
		return
	end
	update = update - hpregen.interval

	regen_update()
end)

ctf_classes.dont_heal = {}
minetest.register_on_player_hpchange(function(player, hp_change, reason)
	local name = player:get_player_name()

	if reason.type == "drown" or reason.type == "node_damage" then
		ctf_classes.dont_heal[name] = true
	elseif ctf_classes.dont_heal[name] then
		ctf_classes.dont_heal[name] = nil
	end
end)

minetest.register_on_leaveplayer(function(player)
	ctf_classes.dont_heal[player:get_player_name()] = nil
end)

local bandage_on_use = minetest.registered_items["ctf_bandages:bandage"].on_use
minetest.override_item("ctf_bandages:bandage", {
	on_use = function(stack, user, pointed_thing)
		if pointed_thing.type ~= "object" then
			return
		end

		local object = pointed_thing.ref
		if not object:is_player() then
			return
		end

		local pname = object:get_player_name()
		local name = user:get_player_name()
		if ctf.player(pname).team == ctf.player(name).team then
			local nodename = minetest.get_node(object:get_pos()).name
			if ctf_classes.dont_heal[pname] or nodename:find("lava") or nodename:find("water") or nodename:find("trap") then
				hud_event.new(name, {
					name  = "ctf_classes:environment",
					color = "warning",
					value = "Can't heal " .. pname .. " in lava, water or spikes!",
				})
				return -- Can't heal players in lava/water/spikes
			end

			local hp = object:get_hp()
			local limit = ctf_bandages.heal_percent * object:get_properties().hp_max

			if hp > 0 and hp < limit and ctf_classes.get(user).name == "medic" then
				local main, match = ctf_stats.player(name)

				if main and match then
					local reward = 3

					if ctf_flag.has_flag(pname) then reward = 6 end

					main.score  = main.score  + reward
					match.score = match.score + reward

					hud_score.new(name, {
						name = "ctf_classes:medic_heal",
						color = "0x00FF00",
						value = reward
					})

					ctf_stats.request_save()
				end
			end
		end

		return bandage_on_use(stack, user, pointed_thing)
	end
})

local diggers = {}
local DIG_COOLDOWN = 30
local DIG_DIST_LIMIT = 10
local DIG_SPEED = 0.1

local function isdiggable(name)
	return name:find("default:") and (
		name:find("cobble") or name:find("wood" ) or
		name:find("leaves") or name:find("dirt" ) or
		name:find("gravel") or name:find("sand" ) or
		name:find("tree"  ) or name:find("brick") or
		name:find("glass" ) or name:find("ice"  ) or
		name:find("snow"  )
	)
end

local function paxel_stop(pname, reason)
	hud_event.new(pname, {
		name  = "ctf_classes:paxel_stop",
		color = "success",
		value = string.format("Pillar digging stopped. Reason: %s. You can use again in %ds", reason or "unknown", DIG_COOLDOWN),
	})

	diggers[pname] = minetest.after(DIG_COOLDOWN, function() diggers[pname] = nil end)
end

local function remove_pillar(pos, pname)
	local name = minetest.get_node(pos).name

	if name:find("default") and isdiggable(name) then
		local player = minetest.get_player_by_name(pname)

		minetest.dig_node(pos)

		if player and diggers[pname] and type(diggers[pname]) ~= "table" then
			local distance = vector.subtract(player:get_pos(), pos)
			-- Ignore vertical distance
			distance.y = 0
			if vector.length(distance) <= DIG_DIST_LIMIT then
				pos.y = pos.y + 1
				minetest.after(DIG_SPEED, remove_pillar, pos, pname)
			else
				paxel_stop(pname, "at too far away node")
			end
		end
	else
		paxel_stop(pname, "at undiggable node")
	end
end

minetest.register_tool("ctf_classes:paxel_bronze", {
	description = "Bronze Paxel\n" ..
		"Rightclick bottom of pillar to start destroying it, hold rightclick to stop\n"..
		"Can't use during build time",
	inventory_image = "default_tool_bronzepick.png^default_tool_bronzeshovel.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=0, maxlevel=2},
			crumbly = {times={[1]=1.50, [2]=0.90, [3]=0.40}, uses=0, maxlevel=2},
			choppy={times={[1]=2.50, [2]=1.40, [3]=1.00}, uses=0, maxlevel=2},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local pname = placer:get_player_name()

			if not isdiggable(minetest.get_node(pointed_thing.under).name) then
				hud_event.new(pname, {
					name  = "ctf_classes:paxel_undiggable",
					color = "warning",
					value = "Can't paxel node!",
				})
				return minetest.item_place(itemstack, placer, pointed_thing)
			end
			if ctf_match.is_in_build_time() then
				hud_event.new(pname, {
					name  = "ctf_classes:paxel_build_time",
					color = "warning",
					value = "Build time active!",
				})
				return minetest.item_place(itemstack, placer, pointed_thing)
			end

			if not diggers[pname] then
				hud_event.new(pname, {
					name  = "ctf_classes:paxel_start",
					color = "primary",
					value = "Pillar digging started",
				})
				diggers[pname] = true
				remove_pillar(pointed_thing.under, pname)
			elseif type(diggers[pname]) ~= "table" then
				paxel_stop(pname)
			else
				hud_event.new(pname, {
					name  = "ctf_classes:paxel_timer",
					color = "warning",
					value = "You can't activate yet!",
				})
			end
		end
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		local pname = user:get_player_name()

		if diggers[pname] and diggers[pname] == true and type(diggers[pname]) ~= "table" then
			diggers[pname] = 1
			minetest.after(1, function()
				if user and user:get_player_control().RMB then
					if diggers[pname] and type(diggers[pname]) ~= "table" then
						paxel_stop(pname, "Stop requested")
					end
				end
			end)
		end
	end,
})

minetest.register_on_dieplayer(function(player)
	local pname = player:get_player_name()

	if type(diggers[pname]) == "table" then
		diggers[pname]:cancel()
	end

	diggers[pname] = nil
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	if type(diggers[pname]) == "table" then
		diggers[pname]:cancel()
	end

	diggers[pname] = nil
end)

ctf_match.register_on_new_match(function()
	if diggers and #diggers > 0 then
		for _, v in pairs(diggers) do
			if type(v) == "table" then
				v:cancel()
			end
		end
	end

	diggers = {}
end)

ctf.register_on_new_game(function()
	if diggers and #diggers > 0 then
		for _, v in pairs(diggers) do
			if type(v) == "table" then
				v:cancel()
			end
		end
	end

	diggers = {}
end)
