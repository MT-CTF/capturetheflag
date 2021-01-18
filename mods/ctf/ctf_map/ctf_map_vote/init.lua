-- code by oneplustwo

ctf_map_vote = {}

local voted = {}
local vote_cooldown = {}
local storage = minetest.get_mod_storage()

local score_requirement = 500
local vote_delay = 172800 -- two days

local function load_voter_data()
    voted = minetest.deserialize(storage:get_string("voted"))
    vote_cooldown = minetest.deserialize(storage:get_string("vote_cooldown"))
end

local function save_voter_data()
    storage:set_string("voted", minetest.serialize(voted))
    storage:set_string("vote_cooldown", minetest.serialize(vote_cooldown))
end

local function check_voter_eligibility(name)
    local stats, _ = ctf_stats.player(name)
    if stats.score < score_requirement then
        return 2
    elseif vote_cooldown[name][ctf_map.map] then
        return 1
    else
        return 0
    end
end

local function vote(name, vote_type)
    voted[ctf_map.map][name] = vote_type
    vote_cooldown[name][ctf_map.map] = true -- add cooldown
    minetest.after(vote_delay, function(name, map)
        vote_cooldown[name][map] = nil
    end, name, ctf_map.map) -- get rid of cooldown after vote_delay
end

function ctf_map_vote.get_map_rating(map_name)
    local total = 0
    for _, type in pairs(voted[map_name]) do
        total = total + type
    end
    return type
end

minetest.register_chatcommand("upvote", {
    func = function(name, param)
        code = check_voter_eligibility(name)
        if code == 0 then
            vote(name, 1)
        elseif code == 1 then
            minetest.chat_send_player(name, minetest.colorize("Your voting cooldown is still active!"))
        else
            minetest.chat_send_player(name, minetest.colorize("You must have at least 500 score"))
        end
    end,
})

minetest.register_chatcommand("downvote", {
    func = function(name, param)
        code = check_voter_eligibility(name)
        if code == 0 then
            vote(name, -1)
        elseif code == 1 then
            minetest.chat_send_player(name, minetest.colorize("Your voting cooldown is still active!"))
        else
            minetest.chat_send_player(name, minetest.colorize("You must have at least 500 score"))
        end
    end,
})

minetest.register_chatcommand("unvote", {
    func = function(name, param)
        code = check_voter_eligibility(name)
        if code == 0 then
            vote(name, nil)
        elseif code == 1 then
            minetest.chat_send_player(name, minetest.colorize("Your voting cooldown is still active!"))
        else
            minetest.chat_send_player(name, minetest.colorize("You must have at least 500 score"))
        end
    end,
})

minetest.register_on_shutdown(save_voter_data())

load_voter_data()