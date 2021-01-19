-- code by oneplustwo

ctf_map_rating = {}

local rated = {}
local rate_cooldown = {}
local storage = minetest.get_mod_storage()

local score_requirement = 500
local rate_delay = 172800 -- two days

local error_color = "#FFCC00"

local function load_rating_data()
    local rated_s = storage:get("rated")
    local rate_cooldown_s = storage:get("rate_cooldown")
    if rated_s then
        rated = minetest.deserialize(rated_s)
    end
    if rate_cooldown_s then
        rate_cooldown = minetest.deserialize(rate_cooldown_s)
    end
end

local function save_rating_data()
    if rated ~= {} then
        storage:set_string("rated", minetest.serialize(rated))
    end
    if rate_cooldown ~= {} then
        storage:set_string("rate_cooldown", minetest.serialize(rate_cooldown))
    end
end

local function can_rate(name)
    local stats, _ = ctf_stats.player(name)
    if stats.score < score_requirement then
        return 2
    elseif rate_cooldown[name] and rate_cooldown[name][ctf_map.map.name] then
        return 1
    else
        return 0
    end
end

local function rate(name, rating)
    if not rated[ctf_map.map.name] then
        rated[ctf_map.map.name] = {}
    end

    rated[ctf_map.map.name][name] = rating

    if not rating and rated[ctf_map.map.name] = {} then -- delete nested tables when they are empty
        rated[ctf_map.map.name] = nil
    end

    if not rate_cooldown[name] then
        rate_cooldown[name] = {}
    end
    
    rate_cooldown[name][ctf_map.map.name] = true -- add cooldown
    minetest.after(rate_delay, function(mname, map)
        rate_cooldown[mname][map] = nil
        if rate_cooldown[mname] = {} then -- delete nested tables when they are empty
            rate_cooldown[mname] = nil
        end
    end, name, ctf_map.map.name) -- get rid of cooldown after rate_delay
end

function ctf_map_rating.get_map_rating(map_name)
    local total = 0
    for _, rating in pairs(rated[map_name]) do
        total = total + rating
    end
    return total / #rated[map_name]
end

minetest.register_chatcommand("rate", {
    params = "[rating]",
    description = "Rate the current map. Ratings are 1 to 5. Run /rate with no parameter to cancel your rating.",
    func = function(name, param)
        if not minetest.get_player_by_name(name) then
            return
        end
        local code = can_rate(name)

        if code == 0 then
            if param == "" then
                rate(name, nil)
            end

            local rating = tonumber(param)

            if rating and rating % 1 == 0 then -- check if rating is an integer
                if rating >= 1 and rating <= 5 then
                    rate(name, rating)
                else
                    minetest.chat_send_player(name, minetest.colorize(error_color, "Rating must be between 1 and 5"))
                end
            else
                minetest.chat_send_player(name, minetest.colorize(error_color, "Rating must be an integer"))
            end
        elseif code == 1 then
            minetest.chat_send_player(name, minetest.colorize(error_color, "Your rating cooldown is still active"))
        else
            minetest.chat_send_player(name, minetest.colorize(error_color, "You must have at least 500 score to rate a map"))
        end
    end,
})

minetest.register_on_shutdown(save_rating_data)

load_rating_data()
