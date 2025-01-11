local orenames = {"Coal", "Iron", "Mese", "Diamond"}
local orenamestech = {"coal", "iron", "mese", "diamond"}
local stonenamestech = {"sandstone", "desert_stone"}
local stonenames = {"Sandstone ", "Desert "}
local dropnames = {"coal_lump", "iron_lump", "mese_crystal", "diamond"}
local crackylevels = {3, 2, 1, 1}

for k, orenametech in pairs(orenamestech) do
    for k2, stonenametech in pairs(stonenamestech) do
        minetest.register_node("more_ore:" .. stonenametech .. "_with_" .. orenametech, {
            description = stonenames[k2] .. orenames[k] .. " Ore",
            tiles = {"default_" .. stonenametech .. ".png^default_mineral_" .. orenametech .. ".png"},
            groups = {cracky = crackylevels[k]},
            drop = "default:" .. dropnames[k],
			sounds = default.node_sound_stone_defaults(),
        })
    end
end
