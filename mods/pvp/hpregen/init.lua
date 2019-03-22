local regen_interval = tonumber(minetest.settings:get("regen_interval"))
if regen_interval <= 0 then
	regen_interval = 6
end
local regen_amount = tonumber(minetest.settings:get("regen_amount"))
if regen_amount <= 0 then
	regen_amount = 1
end

local function regen_all()
	for _, player in pairs(minetest.get_connected_players()) do
		local oldhp = player:get_hp()
		if oldhp > 0 then
			local newhp = oldhp + regen_amount
			if newhp > player:get_properties().hp_max then
				newhp = player:get_properties().hp_max
			end
			if oldhp ~= newhp then
				player:set_hp(newhp)
			end
		end
	end
end


local update = 0
minetest.register_globalstep(function(delta)
	update = update + delta
	if update < regen_interval then
		return
	end
	update = update - regen_interval

	regen_all()
end)
