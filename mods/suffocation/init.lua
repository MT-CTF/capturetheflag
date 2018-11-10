--[[
	suffocation when head is inside solid node

	all other features of playerplus was removed

	PlayerPlus by TenPlus1, modified by AKryukov92
	Original code can be downloaded here https://notabug.org/TenPlus1/playerplus
]]

-- get node but use fallback for nil or unknown
local function node_ndef(pos)

	local node = minetest.get_node_or_nil(pos)

	local node_name = "air"
	if node and minetest.registered_nodes[node.name] then
		node_name = node.name
	end

	return minetest.registered_nodes[node_name]
end

local function is_normal_node(ndef)
    return ndef.walkable == true
       and ndef.drowning == 0
       and ndef.damage_per_second <= 0
       and ndef.groups.disable_suffocation ~= 1
       and ndef.drawtype == "normal"
end

local time = 0

minetest.register_globalstep(function(dtime)

	time = time + dtime

	-- every 1 second
	if time < 1 then
		return
	end

	-- reset time for next check
	time = 0

	local name, pos

	-- loop through players
	for _,player in ipairs(minetest.get_connected_players()) do

		name = player:get_player_name()

		pos = player:get_pos()
		pos.y = pos.y + 1.4 -- head level

		-- Is player suffocating inside a normal node without no_clip privs?
		local ndef = node_ndef(pos)

		if is_normal_node(ndef) and not minetest.check_player_privs(name, {noclip = true}) then
			if player:get_hp() > 0 then
				player:set_hp(player:get_hp() - 3)
			end
		end

	end

end)