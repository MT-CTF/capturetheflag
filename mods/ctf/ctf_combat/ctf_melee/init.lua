local sword_mats = {"stone", "steel", "mese", "diamond"}

for _, mat in pairs(sword_mats) do
	minetest.register_alias("ctf_melee:sword_"..mat, "default:sword_"..mat)
end
