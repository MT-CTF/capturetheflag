--Overiding axe values

minetest.override_item("default:axe_stone", {
	tool_capabilities = {
		full_punch_interval = 1.4,
		damage_groups = {fleshy=5},
	},
})

minetest.override_item("default:axe_bronze", {
	tool_capabilities = {
		full_punch_interval = 1.0,
		damage_groups = {fleshy=7},
	},
})

minetest.override_item("default:axe_steel", {
	tool_capabilities = {
		full_punch_interval = 1.0,
		damage_groups = {fleshy=7},
	},
})


minetest.override_item("default:axe_mese", {
	tool_capabilities = {
		full_punch_interval = 0.9,
		damage_groups = {fleshy=8},
	},
})


minetest.override_item("default:axe_diamond", {
	tool_capabilities = {
		full_punch_interval = 0.9,
		damage_groups = {fleshy=9},
	},
})
