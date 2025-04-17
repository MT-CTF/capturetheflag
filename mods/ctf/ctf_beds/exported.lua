-- AUTOMATICALLY GENERATED by <https://gitlab.com/szest/defripper>

local reg = ...

local L = {}

L.beds_bed_top_sounds = {dig = {gain = 0.4, name = "default_dig_choppy"},
	dug = {gain = 1, name = "default_wood_footstep"},
	footstep = {gain = 0.15, name = "default_wood_footstep"},
	place = {gain = 1, name = "default_place_node_hard"}}

L.beds_bed_top_node_box = {fixed = {-0.5, -0.5, -0.5, 0.5, 0.0625, 0.5},
	type = "fixed"}

L.beds_fancy_bed_top_node_box = {fixed = {{-0.5, -0.5, 0.4375, -0.375, 0.1875, 0.5},
		{0.375, -0.5, 0.4375, 0.5, 0.1875, 0.5},
		{-0.5, 0, 0.4375, 0.5, 0.125, 0.5},
		{-0.5, -0.375, 0.4375, 0.5, -0.125, 0.5},
		{-0.5, -0.375, -0.5, -0.4375, -0.125, 0.5},
		{0.4375, -0.375, -0.5, 0.5, -0.125, 0.5},
		{-0.4375, -0.3125, -0.5, 0.4375, -0.0625, 0.4375}},
	type = "fixed"}

reg({_raw_name = "beds:bed_bottom",
	description = "Simple Bed",
	drawtype = "nodebox",
	inventory_image = "beds_bed.png",
	node_box = L.beds_bed_top_node_box,
	paramtype = "light",
	paramtype2 = "facedir",
	selection_box = {fixed = {-0.5, -0.5, -0.5, 0.5, 0.0625, 1.5},
		type = "fixed"},
	sounds = L.beds_bed_top_sounds,
	tiles = {"beds_bed_top_bottom.png^[transformR90",
		"beds_bed_under.png",
		"beds_bed_side_bottom_r.png",
		"beds_bed_side_bottom_r.png^[transformFX",
		"blank.png",
		"beds_bed_side_bottom.png"},
	type = "node",
	use_texture_alpha = "clip",
	wield_image = "beds_bed.png"})

reg({_raw_name = "beds:bed_top",
	drawtype = "nodebox",
	node_box = L.beds_bed_top_node_box,
	paramtype = "light",
	paramtype2 = "facedir",
	selection_box = L.beds_bed_top_node_box,
	sounds = L.beds_bed_top_sounds,
	tiles = {"beds_bed_top_top.png^[transformR90",
		"beds_bed_under.png",
		"beds_bed_side_top_r.png",
		"beds_bed_side_top_r.png^[transformFX",
		"beds_bed_side_top.png",
		"blank.png"},
	type = "node",
	use_texture_alpha = "clip"})

reg({_raw_name = "beds:fancy_bed_bottom",
	description = "Fancy Bed",
	drawtype = "nodebox",
	inventory_image = "beds_bed_fancy.png",
	node_box = {fixed = {{-0.5, -0.5, -0.5, -0.375, -0.065, -0.4375},
			{0.375, -0.5, -0.5, 0.5, -0.065, -0.4375},
			{-0.5, -0.375, -0.5, 0.5, -0.125, -0.4375},
			{-0.5, -0.375, -0.5, -0.4375, -0.125, 0.5},
			{0.4375, -0.375, -0.5, 0.5, -0.125, 0.5},
			{-0.4375, -0.3125, -0.4375, 0.4375, -0.0625, 0.5}},
		type = "fixed"},
	paramtype = "light",
	paramtype2 = "facedir",
	selection_box = {fixed = {-0.5, -0.5, -0.5, 0.5, 0.06, 1.5}, type = "fixed"},
	sounds = L.beds_bed_top_sounds,
	tiles = {"beds_bed_top1.png",
		"beds_bed_under.png",
		"beds_bed_side1.png",
		"beds_bed_side1.png^[transformFX",
		"beds_bed_foot.png",
		"beds_bed_foot.png"},
	type = "node",
	use_texture_alpha = "clip",
	wield_image = "beds_bed_fancy.png"})

reg({_raw_name = "beds:fancy_bed_top",
	drawtype = "nodebox",
	node_box = L.beds_fancy_bed_top_node_box,
	paramtype = "light",
	paramtype2 = "facedir",
	selection_box = L.beds_fancy_bed_top_node_box,
	sounds = L.beds_bed_top_sounds,
	tiles = {"beds_bed_top2.png",
		"beds_bed_under.png",
		"beds_bed_side2.png",
		"beds_bed_side2.png^[transformFX",
		"beds_bed_head.png",
		"beds_bed_head.png"},
	type = "node",
	use_texture_alpha = "clip"})

reg({_alias_to = "beds:bed_bottom", _raw_name = "beds:bed"})

reg({_alias_to = "beds:bed_bottom",
	_raw_name = "beds:bed_bottom_red"})

reg({_alias_to = "beds:bed_top", _raw_name = "beds:bed_top_red"})

reg({_alias_to = "beds:fancy_bed_bottom",
	_raw_name = "beds:fancy_bed"})

