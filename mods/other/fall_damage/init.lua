local node_fall_damage_factors = {
    {"default:snowblock", -14}, -- From a height of 13 blocks you take 5 damage
    {"default:snow", -10}, -- From a height of 13 blocks you take 6 damage
}

minetest.register_on_mods_loaded(function()
    for _, entry in ipairs(node_fall_damage_factors) do
        local groups_temp = minetest.registered_items[entry[1]].groups
        groups_temp.fall_damage_add_percent = entry[2]
        minetest.override_item(entry[1], {
            groups = groups_temp,
        })
    end
end)
