local robbery_cooldown = ctf_core.init_cooldowns()
local ROBBERY_INTERVAL = 5

local function rob_player(player, robber)
    local inv = player:get_inventory()
    local stack = inv:get_stack("main", math.random(1, inv:get_size("main")))
    local mode = ctf_modebase:get_current_mode()
	if mode and mode.stuff_provider then
        for _, item in ipairs(ctf_classes.classes.get(player).items) do
            if stack:get_name() == item or stack:get_name() == "" then
                return "You didn't find anything to rob."
            end
	    end
        if robber:get_inventory():room_for_item("main", stack) then
            inv:remove_item("main", stack)
            robber:get_inventory():add_item("main", stack)
        else
            local pos = player:get_pos()
            inv:remove_item("main", stack)
            minetest.add_item(pos, stack)
        end
        return string.format("You stole %s %s", stack:get_count(), stack:get_description())
	end
end

minetest.register_on_punchplayer(function(punched, puncher)
    if puncher and puncher:is_player() and punched and punched:is_player() then
        if puncher:get_wielded_item():get_name() == "" then
            if robbery_cooldown:get(puncher:get_player_name()) then
                hud_events.new(puncher, {
                    text = "You can only rob every "..ROBBERY_INTERVAL.." seconds",
                    color = "warning",
                    quick = true,
                })
                return
            end
            local msg = rob_player(punched, puncher)
            if msg then
                hud_events.new(puncher, {
                    text = msg,
                    color = "warning",
                    quick = true,
                })
            end
            robbery_cooldown:set(puncher, ROBBERY_INTERVAL)
        end
    end
end)
