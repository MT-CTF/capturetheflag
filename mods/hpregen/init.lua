local regen_interval = tonumber(minetest.setting_get("regen_interval"))
if regen_interval <= 0 then
	regen_interval = 10
end
local regen_amount = tonumber(minetest.setting_get("regen_amount"))
if regen_amount <= 0 then
	regen_amount = 1
end

local function regen_all()
	for _, player in pairs(minetest.get_connected_players()) do
		local oldhp = player:get_hp()
		if oldhp > 0 then
			local newhp = oldhp + regen_amount
			if newhp > 20 then
				newhp = 20
			end
			player:set_hp(newhp)
		end
	end
	minetest.after(regen_interval, regen_all)
end
minetest.after(regen_interval, regen_all)
