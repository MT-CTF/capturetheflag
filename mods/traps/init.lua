minetest.register_node("traps:dirt", {
    description = "Fake Dirt",
    tiles = {"traps_dirt.png"},
    is_ground_content = false,
    walkable    = false,
    groups = {crumbly=3, soil=1}
})

minetest.register_node("traps:stone", {
    description = "Fake Stone",
    tiles = {"traps_stone.png"},
    is_ground_content = false,
    walkable    = false,
    groups = {cracky=3, stone=1}
})

minetest.register_node("traps:cobblestone", {
    description = "Fake Cobblestone",
    tiles = {"traps_cobble.png"},
    is_ground_content = false,
    walkable    = false,
    groups = {cracky=3, stone=2}
})

minetest.register_node("traps:spike", {
	description = "Spike",
	drawtype = "plantlike",
	tiles = {"traps_spike.png"},
	inventory_image = "traps_spike.png",
	paramtype = "light",
	sunlight_propagates = true,
    walkable = false,
    damage_per_second = 5,
	groups = {cracky=1, level=2},
	selection_box = {
		type = "fixed",
		fixed = {-6 / 16, -0.5, -6 / 16, 6 / 16, -3 / 16, 6 / 16},
    },
})

--[[Crafting recipe to be added to ctf_crafting/init.lua
 crafting.register_recipe({
	type   = "inv",
	output = "traps:spike",
	items  = { "default:steel_ingot 5" },
	always_known = true,
    level  = 1,
    
Crafting recipe for ghost stones,
     crafting.register_recipe({
	type   = "inv",
	output = "traps:dirt",
	items  = { "default:dirt 5", "default:coal" },
	always_known = true,
    level  = 1,

crafting.register_recipe({
	type   = "inv",
	output = "traps:cobblestone",
	items  = { "default:cobblestone 5", "default:coal" },
	always_known = true,
    level  = 1,

crafting.register_recipe({
	type   = "inv",
	output = "traps:stone",
	items  = { "default:stone 5", "default:coal" },
	always_known = true,
    level  = 1,

crafting.register_recipe({
	type   = "inv",
	output = "traps:damage_cobble",
	items  = { "default:cobblestone", "default:coal 4", "default:steel_ingot 4" },
	always_known = true,
    level  = 1,
})
]]--

minetest.register_node("traps:damage_cobble", {
    description = "Cobblestone that does damage",
    tiles = {"traps_dmg_cobble.png"},
    is_ground_content = false,
    walkable    = true,
    groups = {cracky=3, stone=2},
    on_place = function(itemstack, placer, pointed_thing)
        local pos
        local node = minetest.get_node(pointed_thing.under)
        local pdef = minetest.registered_nodes[node.name]
        if pdef and pdef.on_rightclick and
                not placer:get_player_control().sneak then
            return pdef.on_rightclick(pointed_thing.under,
                node, placer, itemstack, pointed_thing)
            end
 
            if pdef and pdef.buildable_to then
                pos = pointed_thing.under
            else
                pos = pointed_thing.above
                node = minetest.get_node(pos)
                pdef = minetest.registered_nodes[node.name]
                if not pdef or not pdef.buildable_to then
                    return itemstack
                end
            end

            return minetest.item_place(itemstack, placer, pointed_thing)
    end,

    on_dig = function(pos, node, digger)
        local name = digger:get_player_name()
        if not digger then
            return
        end

        local digger_team = ctf.player(name).team
        local meta = minetest.get_meta(pos)
        local placer_team = meta:get_string("placer") or "missing"
        if digger_team ~= placer_team then
            local hp = digger:get_hp()
            digger:set_hp(hp - 7)
            minetest.remove_node(pos)
            return
        end

        meta:set_string("placer", "")
        return minetest.node_dig(pos, node, digger)

    end,
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local name = placer:get_player_name()
        meta:set_string("placer", ctf.player(name).team)
    end
})
