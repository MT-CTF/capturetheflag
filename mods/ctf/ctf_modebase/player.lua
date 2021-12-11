ctf_modebase.player = {}

local function get_initial_stuff(player, f)
	local mode = ctf_modebase:get_current_mode()
	if mode and mode.stuff_provider then
		for _, item in ipairs(mode.stuff_provider(player)) do
			f(ItemStack(item))
		end
	end

	if ctf_map.current_map and ctf_map.current_map.initial_stuff then
		for _, item in ipairs(ctf_map.current_map.initial_stuff) do
			f(ItemStack(item))
		end
	end
end

function ctf_modebase.player.give_initial_stuff(player)
	minetest.log("action", "Giving initial stuff to player " .. player:get_player_name())

	local inv = player:get_inventory()
	get_initial_stuff(player, function(item)
		inv:remove_item("main", item)
		inv:add_item("main", item)
	end)
end

function ctf_modebase.player.empty_inv(player)
	player:get_inventory():set_list("main", {})
end

function ctf_modebase.player.remove_bound_items(player)
	local mode = ctf_modebase:get_current_mode()
	if mode and mode.is_bound_item then
		local inv = player:get_inventory()

		local list = inv:get_list("main")
		for i, item in ipairs(list) do
			if mode.is_bound_item(player, item:get_name()) then
				list[i] = ItemStack()
			end
		end
		inv:set_list("main", list)
	end
end

function ctf_modebase.player.remove_initial_stuff(player)
	local inv = player:get_inventory()
	get_initial_stuff(player, function(item)
		inv:remove_item("main", item)
	end)
end

function ctf_modebase.player.update(player)
	-- Set skyboxes and physics

	local mode = ctf_modebase:get_current_mode()
	if mode and ctf_map.current_map then
		local map = ctf_map.current_map
		skybox.set(player, table.indexof(ctf_map.skyboxes, map.skybox)-1)

		physics.set(player:get_player_name(), "ctf_modebase:map_physics", {
			speed = map.phys_speed,
			jump = map.phys_jump,
			gravity = map.phys_gravity,
		})

		if mode.physics then
			player:set_physics_override({
				sneak_glitch = mode.physics.sneak_glitch or false,
				new_move = mode.physics.new_move or true
			})
		end
	end
end

ctf_modebase.register_on_new_match(function()
	for _, player in pairs(minetest.get_connected_players()) do
		ctf_modebase.player.empty_inv(player)
		ctf_modebase.player.update(player)
	end
end)

ctf_teams.register_on_allocplayer(function(player)
	ctf_modebase.player.remove_bound_items(player)
	ctf_modebase.player.give_initial_stuff(player)
end)

minetest.register_on_joinplayer(function(player)
	player:set_hp(player:get_properties().hp_max)

	local inv = player:get_inventory()
	inv:set_list("main",  {})
	inv:set_list("craft", {})

	inv:set_size("craft", 1)
	inv:set_size("craftresult", 0)
	inv:set_size("hand", 0)

	ctf_modebase.player.update(player)
end)
