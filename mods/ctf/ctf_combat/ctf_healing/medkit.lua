local hud = mhud.init()

-- healing_players[pname] = {hp = hp_at_healing_start, after = core.after id}
local healing_players = {}

local REGEN_PER_SEC = 3 -- Amount of HP healed per second

local MAX_WEAR = 65535
local MEDKIT_CAPACITY = 50 -- Amount of HP a medkit can heal
local WEAR_PER_SEC = math.floor(MAX_WEAR / (MEDKIT_CAPACITY / REGEN_PER_SEC))

local S = core.get_translator(core.get_current_modname())

local function stop_medkit_heal(playername, interrupt_reason)
	local player = core.get_player_by_name(playername)

	if player then
		if interrupt_reason then
			local php = player:get_hp()

			player:set_hp((php + healing_players[playername].hp)/2) -- set hp halfway from the original to the current

			hud_events.new(playername, {
				text = S("Your healing was interrupted") .. ": " .. interrupt_reason,
				color = "danger",
				quick = true,
			})
		end

		hud:remove(player, "healing_overlay")
		physics.remove(playername, "ctf_healing:medkit_slow")
	end

	if healing_players[playername].after then
		healing_players[playername].after:cancel()
	end

	healing_players[playername] = nil
end

local prevent_heals_list = {
	"normal",
	"glasslike", "glasslike_framed", "glasslike_framed_optional",
	"allfaces", "allfaces_optional",
}
local function prevent_heals(nodedef)
	if nodedef.walkable then
		for _, v in pairs(prevent_heals_list) do
			if nodedef.drawtype == v then
				return true
			end
		end
	end

	return false
end

local function medkit_heal(playername)
	healing_players[playername].after = core.after(1, function()
		local player = core.get_player_by_name(playername)

		if not player then
			return stop_medkit_heal(playername)
		end

		local wielded_item = player:get_wielded_item()
		if not wielded_item or wielded_item:get_name() ~= "ctf_healing:medkit" then
			return stop_medkit_heal(playername, S("You stopped holding the medkit"))
		end

		-- In case teammates manage to place blocks inside the player while they're healing
		local pos = player:get_pos():offset(0, 0.1, 0)
		local node_0 = core.registered_nodes[core.get_node(pos).name]
		local node_1 = core.registered_nodes[core.get_node(pos:offset(0, 1, 0)).name]

		if prevent_heals(node_0) or prevent_heals(node_1) then
			return stop_medkit_heal(playername, S("You can't heal while inside blocks"))
		end

		local max_hp = player:get_properties().hp_max
		local new_hp = math.min(player:get_hp() + REGEN_PER_SEC, max_hp)

		player:set_hp(new_hp)

		local new_wear = wielded_item:get_wear() + WEAR_PER_SEC
		wielded_item:set_wear(new_wear)
		player:set_wielded_item(wielded_item)

		if new_hp ~= max_hp and new_wear <= MAX_WEAR then
			medkit_heal(playername)
		else -- player was fully healed, or medkit ran out
			stop_medkit_heal(playername)
		end
	end)
end

local function start_medkit_heal(playername)
	if healing_players[playername] then return end

	local player = core.get_player_by_name(playername)

	if not player then return end

	local hp_max = player:get_properties().hp_max
	local php = player:get_hp()

	if php >= hp_max then
		hud_events.new(playername, {
			text = S("You're already at full health"),
			color = "warning",
			quick = true,
		})
		return
	end

	-- Prevent players from using medkits while inside nodes
	local pos = player:get_pos():offset(0, 0.1, 0)
	local node_0 = core.registered_nodes[core.get_node(pos).name]
	local node_1 = core.registered_nodes[core.get_node(pos:offset(0, 1, 0)).name]

	if prevent_heals(node_0) or prevent_heals(node_1) then
		return hud_events.new(playername, {
			text = S("You can't heal inside blocks"),
			color = "danger",
			quick = true,
		})
	end

	healing_players[playername] = {hp = php}

	hud:add(player, "healing_overlay", {
		hud_elem_type = "image",
		position = {x = 0.5, y = 0.5},
		image_scale = -100,
		texture = "[combine:1x1^[invert:rgba^[opacity:1^[colorize:#099bd1:101"
	})

	physics.set(playername, "ctf_healing:medkit_slow", { speed = 0.3 })

	medkit_heal(playername)
end

core.register_on_punchplayer(function(player, hitter, _, _, _, damage)
	if player and hitter and player:get_hp() > 0 and damage > 0 then
		local pname = player:get_player_name()
		local hname = hitter:is_player() and hitter:get_player_name()

		if hname and ctf_teams.get(pname) and ctf_teams.get(pname) == ctf_teams.get(hname) then return end

		if healing_players[pname] then
			stop_medkit_heal(pname, S("Someone is attacking you"))
		end

		if hname and healing_players[hname] then
			stop_medkit_heal(hname, S("You can't attack while healing"))
		end
	end
end)

core.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	if not healing_players[pname] then return end

	if healing_players[pname].after then
		healing_players[pname].after:cancel()
	end

	healing_players[pname] = nil
end)

core.register_tool("ctf_healing:medkit", {
	description = S("Medkit"),
	inventory_image = "ctf_healing_medkit.png",
	on_use = function(itemstack, user, pointed_thing)
		local uname = user:get_player_name()

		if not healing_players[uname] then
			start_medkit_heal(uname)
		else
			stop_medkit_heal(uname, S("You stopped the healing"))
		end
	end,
})
