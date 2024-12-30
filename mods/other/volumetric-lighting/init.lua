local S = core.get_translator('volumetric_lighting')
local storage = core.get_mod_storage()
local default_strength = tonumber(core.settings:get("volumetric_lighting_default_strength") or 0.1)

-- Set a player's volumetric lighting strength in mod storage
local function set_player_strength(player, strength)
    storage:set_string("strength_" .. player:get_player_name(), tostring(strength))
end

core.register_on_joinplayer(function(player)
    local strength = tonumber(storage:get_string("strength_" .. player:get_player_name())) or default_strength
    player:set_lighting({ volumetric_light = { strength = strength } })
end)

core.register_chatcommand("light_strength", {
    params = "<strength>",
    description = S("Set volumetric lighting strength for yourself."),
    func = function(name, param)
        local player = core.get_player_by_name(name)
        local current_strength = player:get_lighting().volumetric_light.strength or default_strength

        if param == "" then
            core.chat_send_player(name, S("Your current volumetric lighting strength is: @1", math.floor(current_strength * 1000 + 0.5) / 1000))
            return true
        end

        local new_strength = tonumber(param) or default_strength
        if type(tonumber(param)) ~= "number" or new_strength < 0 or new_strength > 1 then
            core.chat_send_player(name, core.colorize("#ff0000", S("Invalid strength.")))
            return true
        end

        set_player_strength(player, new_strength)
        player:set_lighting({ volumetric_light = { strength = new_strength } })

        if new_strength == default_strength then
            core.chat_send_player(name, S("Set strength to default value (@1).", new_strength))
        else
            core.chat_send_player(name, S("Set strength to @1.", new_strength))
        end

        return true
    end
})
