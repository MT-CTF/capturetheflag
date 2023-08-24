local markdown_guide = [[
# Capture the Flag Guide

### Basics
* Click the opposite team's flag to take it.
Then, click your team's flag before the enemy takes it in order to capture.
* Each team has a team chest; put useful items in there and **never** take more than you need!

### Modes
* CTF cycles through three modes: Classes, Nade Fight, and Classic.
* At the end of each mode, you get to vote for how many matches of the next mode you would like to play.

* In Classes, right-click your team's flag to change classes.
It's helpful to read the description of the items your class is given.
* In Nade Fight, right-click your grenade to switch between three types of nade.
* In Classic, eat apples to heal and find ores to craft better swords.

### Tips & Tricks
* Sneak while jumping to jump up two blocks.
* Start your messages with /t to send a message only visible to teamates.
* Sprint by pressing the fast key (`E` by default).
* Use `/r` to check your rank.
* Use `/m` to add a team marker at pointed location.
* Use `/s` to check the current and previous match summary.
* Use `/top50` to see the leaderboard.
* Use `/team` to check all team members.
* Use `/donate <player> <score>` to donate scores to a player.
* Use `/lb` to see a list of bountied players.
* Use `/msg` <player> to send a PM to a player.

****
]]

local function ctf_guide(name, guide_content)
    local formspec_guide = md2f.md2f(0.3, 0, 8, 10, guide_content)
    local formspec = "size[8,9.5]" ..
                    formspec_guide ..
                    "button_exit[3,8.75;2,1;exit;Close]"
    minetest.show_formspec(name, "ctf_guide", formspec)
    return true
end

sfinv.register_page("ctf_guide:guide", {
    title = "Guide",
    get = function(self, player, context)
        local formspec_guide = md2f.md2f(0.3, 0, 8, 10, markdown_guide)
        return sfinv.make_formspec(player, context, formspec_guide, false)
    end
})

minetest.register_on_newplayer(function(player)
    local player_name = player:get_player_name()
    local background_hud = player:hud_add({
        hud_elem_type = "image",
        position = {x = 1, y = 0.15},
        offset = {x = -180, y = 20},
        text = "background.png",
        scale = {x = 1.5, y = 1.2},
        alignment = 0
    })
    local welcome_hud = player:hud_add({
        hud_elem_type = "text",
        position = {x = 1, y = 0.15},
        offset = {x = -180, y = 0},
        text = "Welcome to Capture the Flag!",
        alignment = 0,
        scale = {x = 100, y = 30},
        number = 0xFFA500,
    })
    local text_hud = player:hud_add({
        hud_elem_type = "text",
        position = {x = 1, y = 0.15},
        offset = {x = -180, y = 40},
        text = "Run /ctf_guide in chat for instructions\non how to play.",
        alignment = 0,
        scale = {x = 100, y = 30},
        number = 0xFFFFFF,
    })

    minetest.after(60, function()
        player:hud_remove(welcome_hud)
        player:hud_remove(text_hud)
        player:hud_remove(background_hud)
    end)

    minetest.register_chatcommand("ctf_guide", {
        func = function(name, param)
            if name == player_name then
                player:hud_remove(welcome_hud)
                player:hud_remove(text_hud)
                player:hud_remove(background_hud)
            end
            ctf_guide(name, markdown_guide)
        end
    })
end)

minetest.register_chatcommand("ctf_guide", {
    func = function(name, param)
        ctf_guide(name, markdown_guide)
    end
})