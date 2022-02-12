--
--- Medic Paxel
--

local DIG_SPEED = 0.1
local PAXEL_POWER = 50 -- currently just blocks count
local PAXEL_RETRY = 3
local PAXEL_COOLDOWN_TIME = 20

local dig_timers = {}

local function is_diggable(node)
	local name = node.name
	return name:find("default:") and (
		name:find("cobble") or name:find("wood" ) or
		name:find("leaves") or name:find("dirt" ) or
		name:find("gravel") or name:find("sand" ) or
		name:find("tree"  ) or name:find("brick") or
		name:find("glass" ) or name:find("ice"  ) or
		name:find("snow"  )
	)
	or name:find("stairs:")
end

local function dig(pname, ppos, power, retry)
	if power <= 1 then
		hud_events.new(pname, {
			quick = true,
			text = "Pillar digging went too far",
			color = "warning",
		})
		dig_timers[pname] = nil
		return
	end

	for y = 1, 20 do
		local pos = vector.offset(ppos, 0, y, 0)
		local node = minetest.get_node(pos)
		if node.name ~= "air" then
			if is_diggable(node) then
				minetest.dig_node(pos)
				dig_timers[pname] = minetest.after(DIG_SPEED, dig, pname, pos, power - 1, PAXEL_RETRY)
			else
				hud_events.new(pname, {
					quick = true,
					text = "Pillar digging stopped at undiggable node",
					color = "warning",
				})
				dig_timers[pname] = nil
			end

			return
		end
	end

	if retry > 0 then
		dig_timers[pname] = minetest.after(1, dig, pname, ppos, power, retry - 1)
	else
		hud_events.new(pname, {
			quick = true,
			text = "Pillar digging has nothing more to dig",
			color = "warning",
		})
		dig_timers[pname] = nil
	end
end

minetest.register_tool("ctf_mode_classes:support_paxel", {
	description = "Paxel",
	inventory_image = "default_tool_bronzepick.png^default_tool_bronzeshovel.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level = 1,
		groupcaps = {
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=0, maxlevel=2},
			crumbly = {times={[1]=1.50, [2]=0.90, [3]=0.40}, uses=0, maxlevel=2},
			choppy = {times={[1]=2.50, [2]=1.40, [3]=1.00}, uses=0, maxlevel=2},
		},
		damage_groups = {fleshy=4},
		punch_attack_uses = 0,
	},
	groups = {pickaxe = 1, tier = 10},
	sound = {breaks = "default_tool_breaks"},

	on_place = function(itemstack, user, pointed_thing)
		if pointed_thing and itemstack:get_wear() == 0 then
			local pos = pointed_thing.under
			if is_diggable(minetest.get_node(pos)) then
				local pname = user:get_player_name()

				minetest.dig_node(pos)

				if dig_timers[pname] then
					dig_timers[pname]:cancel()
				end

				dig_timers[pname] = minetest.after(DIG_SPEED, dig, pname, pos, PAXEL_POWER, PAXEL_RETRY)

				local dstep = math.floor(65534 / PAXEL_COOLDOWN_TIME)
				ctf_modebase.update_wear.start_update(pname, "ctf_mode_classes:support_paxel", dstep, true)

				itemstack:set_wear(65534)
				return itemstack
			else
				hud_events.new(user, {
					quick = true,
					text = "Can't start pillar digging at undiggable node",
					color = "warning",
				})
			end
		end
	end,
})

ctf_api.register_on_match_end(function()
	for _, timer in pairs(dig_timers) do
		timer:cancel()
	end

	dig_timers = {}
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	if dig_timers[pname] then
		dig_timers[pname]:cancel()
	end
end)
