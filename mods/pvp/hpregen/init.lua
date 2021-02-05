hpregen = {}

hpregen.interval = tonumber(minetest.settings:get("hpregen.interval"))
if hpregen.interval <= 0 then
	hpregen.interval = 6
end
hpregen.amount = tonumber(minetest.settings:get("hpregen.amount"))
if hpregen.amount <= 0 then
	hpregen.amount = 1
end

local function regen_all()
	for _, player in pairs(minetest.get_connected_players()) do
		local oldhp = player:get_hp()
		if oldhp > 0 then
			local newhp = oldhp + hpregen.amount
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
	if update < hpregen.interval then
		return
	end
	update = update - hpregen.interval

	regen_all()
end)
