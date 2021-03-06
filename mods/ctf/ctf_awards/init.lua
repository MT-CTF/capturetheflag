awards.register_award("ctf", {
  title = "Capture The Flag!",
  description = "Capture The Flag",
  icon = "awards_ctf_icon.png",
  difficulty = 1,
})

awards.register_award("ctf_ten", {
  title = "The Master of Capturing!",
  description = "Capture The Flag ten times",
  icon = "awards_ctf_icon.png",
  difficulty = 5,
})

awards.register_award("ctf_king", {
  title = "The King of Capturing!",
  description = "Capture The Flag 100 times!",
  icon = "awards_ctf_icon.png",
  difficulty = 5,
})

ctf_flag.register_on_capture(function(attname,flag)
  minetest.after(0, function()
  local CAPS = ctf_stats.player(attname).captures
  if CAPS >= 100 then
    awards.unlock(attname, "ctf_king")
  elseif CAPS >= 10 then
    awards.unlock(attname, "ctf_ten")
  end
  awards.unlock(attname, "ctf")
  end)
end)


awards.register_award("gravitation", {
  title = "Wow! Gravitation!",
  description = "You forgot Newton's law of universal gravitation.",
  icon = "default_sand.png",
  difficulty = 1,
})

awards.register_award("canary", {
  title = "Canary",
  description = "be the first to die in a match",
  icon = "heart.png",
  difficulty = 1,
})

local canary = ""
minetest.register_on_dieplayer(function(ObjectRef, reason)
  local name = ObjectRef:get_player_name()
  if canary == "" then
    canary = name
    awards.unlock(name, "canary")
  end
  if reason.type == "fall" then
    awards.unlock(name, "gravitation")
  end
end)

awards.register_award("bounty", {
  title = "Bounty Hunter",
  description = "Kill 50 bounties",
  icon = "default_tool_mesesword.png",
  difficulty = 1,
})

awards.register_award("kd10", {
  title = "???",
  description = "Get a K/D above 10",
  icon = "grenades_boom.png",
  difficulty = 1,
})

local _mt_loaded = false

ctf.register_on_new_game(function()
  canary = ""
  if _mt_loaded then
    for _, x in pairs(minetest.get_connected_players()) do
      local name = x:get_player_name()
      local STAT = ctf_stats.player(name)
      local BKS = STAT.bounty_kills
      if BKS > 50 then
        awards.unlock(name, "bounty")
      end
      local KD = STAT.kills
      if STAT.deaths > 1 then
        KD = KD / STAT.deaths
      end
      if KD > 10 then
        awards.unlock(name, "kd10")
      end
    end
  end
end)

minetest.register_on_mods_loaded(function()
  _mt_loaded = true
end)
