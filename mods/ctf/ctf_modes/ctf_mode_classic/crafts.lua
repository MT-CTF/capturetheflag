crafting.register_recipe({
	type   = "inv",
	output = "ctf_ranged:ammo",
	items  = { "default:steel_ingot 2", "default:coal_lump" },
	always_known = false,
	level  = 1,
})

return {
	"ctf_ranged:ammo",
	"ctf_melee:sword_steel",
	"ctf_melee:sword_mese",
	"ctf_melee:sword_diamond",
}
