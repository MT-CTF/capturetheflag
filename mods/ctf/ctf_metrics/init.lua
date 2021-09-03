if not minetest.create_metric then
	return
end


local function counter(...)
	return minetest.create_metric("counter", ...)
end
local function gauge(...)
	return minetest.create_metric("gauge", ...)
end


--
-- Kills
--
local kill_counter = counter("ctf_kills", "Total kills")
ctf.register_on_killedplayer(function(victim, killer)
	kill_counter:increment()
end)


--
-- Damage
--
local punch_counter = counter("ctf_punches", "Total punches")
local damage_counter = counter("ctf_damage_given", "Total damage given")
ctf.register_on_attack(function(_, _, _, _, _, damage)
	punch_counter:increment()
	damage_counter:increment(damage)
end)

--
-- Digs / places
--
local dig_counter = counter("ctf_digs", "Total digs")
local place_counter = counter("ctf_places", "Total digs")
minetest.register_on_dignode(function()
	dig_counter:increment()
end)
minetest.register_on_placenode(function()
	place_counter:increment()
end)


--
-- Gauges
--

local class_gauges = {}
for _, class in ipairs(ctf_classes.__classes_ordered) do
	class_gauges[class.name] = gauge("ctf_class_players", "Player count for class", {
		class = class.name
	})
end

local online_score = gauge("ctf_online_score", "Total score of online players")
local match_time = gauge("ctf_match_play_time", "Current time in match")

minetest.register_globalstep(function()
	local sum = 0
	local class_counts = {}
	for _, player in pairs(minetest.get_connected_players()) do
		local total, _ = ctf_stats.player(player:get_player_name())
		sum = sum + total.score

		local class = ctf_classes.get(player)
		class_counts[class.name] = (class_counts[class.name] or 0) + 1
	end

	online_score:set(sum)
	match_time:set(ctf_match.get_match_duration() or 0)

	for _, class in ipairs(ctf_classes.__classes_ordered) do
		class_gauges[class.name]:set(class_counts[class.name] or 0)
	end
end)
