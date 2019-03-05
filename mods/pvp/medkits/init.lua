-- Table of tables indexed by player names, each having three fields:
-- * HP at time of left-click + regen_max,
-- * Max HP of player (generally 20)
-- * ID of "healing effect" HUD element
local players = {}

local regen_max = 20        -- Max HP provided by one medkit
local regen_interval = 0.3 -- Time in seconds between each iteration
local regen_timer = 0      -- Timer to keep track of regen_interval
local regen_step = 1       -- Number of HP added every iteration

-- Boolean function for use by other mods to check if a player is healing
function is_healing(name)
	return players[name] and true or false
end

-- Called when player uses a medkit
-- Aborts if player is already healing
local function start_healing(stack, player)
	if not player then
		return stack
	end
	local name = player:get_player_name()

	if players[name] or player:get_hp() >= 20 then
		return stack
	end

	players[name] = {
		pos    = player:get_pos(),
		target = player:get_hp() + regen_max,
		hud    = player:hud_add({
			hud_elem_type = "image",
			position = {x = 0.5, y = 0.5},
			scale = {x = -100, y = -100},
			text = "medkit_hud.png"
		})
	}

	stack:take_item()
	return stack
end

-- Called after regen is complete. Remove additional effects
-- If interrupted == true, revert to original HP and give back one medkit.
local function stop_healing(player, interrupted)
	local name = player:get_player_name()
	local info = players[name]

	players[name] = nil
	if interrupted then
		minetest.chat_send_player(name, minetest.colorize("#FF4444",
										"Your healing was interrupted!"))
		player:set_hp(info.target - regen_max)
		player:get_inventory():add_item("main", ItemStack("medkits:medkit 1"))
	end

	player:hud_remove(info.hud)
end

-- Called after left-click every n seconds (determined by regen_interval)
-- heals player for a total of regen_max, limited by player's max hp
minetest.register_globalstep(function(dtime)
	regen_timer = regen_timer + dtime
	if regen_timer < regen_interval then
		return
	end

	for name, info in pairs(players) do
		local player = minetest.get_player_by_name(name)
		if not player then
			players[name] = nil
		else
			-- Abort if player moves more than 1m in any direction to
			-- allow players to manually interrupt healing if necessary
			local pos = player:get_pos()
			if vector.distance(pos, info.pos) >= 1 then
				stop_healing(player, true)
			end

			-- Stop healing if target reached
			local hp = player:get_hp()
			if hp < info.target and hp < 20 then
				player:set_hp(hp + regen_step)
			else
				stop_healing(player)
			end
		end
	end
	regen_timer = 0
end)

-- If player takes damage while healing,
-- stop regen and revert back to original state
minetest.register_on_player_hpchange(function(player, hp, reason)
	if hp < 0 then
		if players[player:get_player_name()] then
			stop_healing(player, true)
		end
		if reason and reason.type == "punch" then
			local hitter = reason.object
			if hitter and players[hitter:get_player_name()] then
				stop_healing(hitter, true)
			end
		end
	end
	return hp
end, true)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)

minetest.register_craftitem("medkits:medkit", {
	description = "Medkit",
	inventory_image = "medkit_medkit.png",
	wield_image = "medkit_medkit.png",
	stack_max = 10,

	on_use = start_healing
})
