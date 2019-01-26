--Inspired from Andrey's bandages mod

local healing_limit = 15

minetest.register_craftitem("ctf_bandages:bandage", {
    description = "Bandage, heals teammates for 3-4 HP until HP is equal to "..healing_limit,
    inventory_image = "ctf_bandages_bandage.png",
    range = 4,
    on_use = function(itemstack, player, pointed_thing)
    if pointed_thing.type ~= "object" then
        return
    end
    local name = player:get_player_name()
    local object = pointed_thing.ref
    local pname = object:get_player_name()
    local team = ctf.player(name).team
        if not object:is_player() then
            return
        end

        if ctf.player(pname).team == team then
            local hp = object:get_hp()
            if hp > 0 and hp < healing_limit then
                hp = hp + math.random(3,4)
                    if hp > healing_limit then
                        hp = healing_limit
                    end
                object:set_hp(hp)
                itemstack:take_item()
                return itemstack
            else
                minetest.chat_send_player(name, pname .. " has " .. hp .. " hitpoints. You can't heal them.")
            end
        else
            minetest.chat_send_player(name, pname.." isn't in your team!")
        end
    end,
})
