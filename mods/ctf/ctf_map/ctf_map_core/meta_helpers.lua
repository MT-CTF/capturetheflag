if not minetest.get_modpath("physics") then
	error("Cannot find mod 'physics'!")
end

----------
-- TIME --
----------

local BASE_TIME_SPEED = 72

local function update_time()
	local time = ctf_map.map.start_time
	local mult = ctf_map.map.time_speed or 1
	if time then
		minetest.set_timeofday(time)
	else
		minetest.set_timeofday(0.4)
	end

	minetest.settings:set("time_speed", BASE_TIME_SPEED * mult)
end

------------
-- SKYBOX --
------------

function ctf_map.skybox_exists(subdir)
	return ctf_map.file_exists(subdir, {
		"skybox_1.png",
		"skybox_2.png",
		"skybox_3.png",
		"skybox_4.png",
		"skybox_5.png",
		"skybox_6.png"
	})
end

local function set_skybox(player)
	if ctf_map.map.skybox then
		local prefix = ctf_map.map.dirname .. "_skybox_"
		local skybox_textures = {
			prefix .. "1.png",  -- up
			prefix .. "2.png",  -- down
			prefix .. "3.png",  -- east
			prefix .. "4.png",  -- west
			prefix .. "5.png",  -- south
			prefix .. "6.png"   -- north
		}
		player:set_sky(0xFFFFFFFF, "skybox", skybox_textures, false)
	else
		player:set_sky(0xFFFFFFFF, "regular", {}, true)
	end
end

-------------
-- PHYSICS --
-------------

local function update_physics(player)
	physics.set(player:get_player_name(), "ctf_map:map_physics", {
		speed   = ctf_map.map.phys_speed   or 1,
		jump    = ctf_map.map.phys_jump    or 1,
		gravity = ctf_map.map.phys_gravity or 1
	})
end

---------------
-- CALLBACKS --
---------------

minetest.register_on_joinplayer(function(player)
	if ctf_map.map then
		set_skybox(player)
		update_physics(player)
	end
end)

function ctf_map.update_env()
	if not ctf_map.map then
		return
	end

	update_time()
	for _, player in pairs(minetest.get_connected_players()) do
		set_skybox(player)
		update_physics(player)
	end
end
