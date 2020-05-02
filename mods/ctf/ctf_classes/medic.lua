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
			local hp = object:get_hp()
			local percentage = 0.75 --percentage of total HP to be healed
			local limit = percentage * object:get_properties().hp_max
			if hp > 0 and hp < limit then 
				local main, match = ctf_stats.player(name)
				if main and match then
					local reward = 5
					main.score  = main.score  + reward
					match.score = match.score + reward

					hud_score.new(name, {
						name = "ctf_stats:heal_score",
						color = "0x00FF00",
						value = reward
					})
				end
			end
		end
		return bandage_on_use(stack, user, pointed_thing)
	end
})
