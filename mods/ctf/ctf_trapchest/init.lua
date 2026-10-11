local pending_kills = {}
local trapchest = {}

local TRAP_DAMAGE = 150
local TRAP_KILL_IMAGE = "ctf_kill_list_trapchest.png"

local function is_support_paxel(stack)
	return stack:get_name() == "ctf_mode_classes:support_paxel"
end

-- Keep ctf_mode_classes optional at mod-load time.
-- If its Paxel helpers are unavailable, don't allow Paxel disarming.
local function paxel_is_ready(itemstack)
	return ctf_mode_classes
		and ctf_mode_classes.paxel_is_ready
		and ctf_mode_classes.paxel_is_ready(itemstack)
end

local function start_paxel_cooldown(player, itemstack)
	if ctf_mode_classes and ctf_mode_classes.start_paxel_cooldown then
		return ctf_mode_classes.start_paxel_cooldown(player, itemstack)
	end

	return false
end

local function get_trapchest(pos)
	return trapchest[minetest.hash_node_position(pos)]
end

local function register_trapchest(pos, placer)
	local team = ctf_teams.get(placer)

	trapchest[minetest.hash_node_position(pos)] = {
		player = placer:get_player_name(),
		team = team,
	}
end

local function remove_trapchest(pos)
	trapchest[minetest.hash_node_position(pos)] = nil
	minetest.remove_node(pos)
end

local function disarm_trapchest(pos, player)
    remove_trapchest(pos)

    hud_events.new(player, {
        quick = true,
        text = "Trap chest disarmed.",
        color = "success",
    })
end

local function damage_trap_opener(player, trap)
	local pname = player:get_player_name()

	pending_kills[pname] = {
		trap_player = trap and trap.player or nil,
	}

	local hp_before = player:get_hp()

	player:set_hp(hp_before - TRAP_DAMAGE, {
		type = "set_hp",
		reason = "ctf_trapchest",
	})

	-- If the player survived, this trap did not kill them.
	if player:get_hp() > 0 then
		pending_kills[pname] = nil
	end
end

minetest.register_on_dieplayer(function(player)
	local pname = player:get_player_name()
	local kill = pending_kills[pname]

	if not kill then
		return
	end

	pending_kills[pname] = nil

	-- Player-placed traps credit the placer.
	-- Map-generated traps have no placer, so the killer is blank.
	if ctf_kill_list and ctf_kill_list.add then
		ctf_kill_list.add(
			kill.trap_player or "",
			player,
			TRAP_KILL_IMAGE
		)
	end
end)

minetest.register_on_leaveplayer(function(player)
	pending_kills[player:get_player_name()] = nil
end)

local trap_def = {
	description = "Trap Chest",

	-- Closed-chest texture layout.
	tiles = {
	"default_chest_top.png",
	"default_chest_top.png",
	"default_chest_side.png",
	"default_chest_side.png",
	"default_chest_side.png",
	"default_chest_front.png",
},

	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	is_ground_content = false,

	groups = {
		immortal = 1,
	},

	sounds = default.node_sound_wood_defaults(),

	-- Remember the placer and their team for player-placed trap chests.
	after_place_node = function(pos, placer)
		register_trapchest(pos, placer)
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		if not clicker or not clicker:is_player() then
			return itemstack
		end

		local trap = get_trapchest(pos)

		-- Player-placed trap chest.
		if trap and trap.team then
			local opener_team = ctf_teams.get(clicker)

			-- Teammates cannot trigger the trap.
			if opener_team == trap.team then
				if is_support_paxel(itemstack) then
					-- A recharging Paxel cannot retrieve the chest.
					if not paxel_is_ready(itemstack) then
						return itemstack
					end

					-- Retrieve the chest as an item.
					remove_trapchest(pos)
					minetest.add_item(pos, "ctf_trapchest:trapchest")

					start_paxel_cooldown(clicker, itemstack)
					return itemstack
				end

				hud_events.new(clicker, {
    				quick = true,
    				text = "This is a trap chest!",
    				color = "warning",
				})

				return itemstack
			end

			-- Enemies can disarm the trap with a ready Support Paxel.
			if is_support_paxel(itemstack) and paxel_is_ready(itemstack) then
				disarm_trapchest(pos, clicker)
				start_paxel_cooldown(clicker, itemstack)
				return itemstack
			end
		else
			-- Map-generated traps have no owner or team.
			-- Any player with a ready Support Paxel can disarm them.
			if is_support_paxel(itemstack) and paxel_is_ready(itemstack) then
				disarm_trapchest(pos, clicker)
				start_paxel_cooldown(clicker, itemstack)
				return itemstack
			end
		end
		-- Anyone opening an armed trap without a usable Paxel triggers it.
		remove_trapchest(pos)
		damage_trap_opener(clicker, trap)

		return itemstack
	end,
}


minetest.register_node("ctf_trapchest:trapchest", trap_def)

if ctf_api and ctf_api.register_on_match_end then
	ctf_api.register_on_match_end(function()
		pending_kills = {}
		trapchest = {}
	end)
end
