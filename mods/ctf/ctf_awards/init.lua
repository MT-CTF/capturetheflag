-- Copyright (c) 2013-18 rubenwardy, Cato and Wuzzy. MIT.
awards.register_award("builder",{
  title = "Builder",
  description = "Place 20 cobbles",
  icon = "default_cobble.png",
  trigger = {
    type = "place",
    node = "default:cobble",
    target = 20
  }
})

awards.register_award("digger",{
  title = "Digger",
  description = "Dig 20 block",
  icon = "default_tool_steelpick.png",
  background = "awards_bg_mining.png",
  difficulty = 1,
  trigger = {
    type = "dig",
    target = 20
  }
})


awards.register_award("ctf",{
  title = "Capture The Flag!",
  description = "Capture The Flag",
  icon = "awards_ctf_icon.png",
  difficulty = 1,
})

ctf_flag.register_on_capture(function(attname,flag)
  awards.unlock(attname, "ctf")
end)

-- gravitation

awards.register_award("gravitation",{
  title = "Wow! Gravitation!",
  description = "You forgot Newton's law of universal gravitation.",
  icon = "default_sand.png",
  difficulty = 1,
})

minetest.register_on_dieplayer(function(ObjectRef, reason)
  if reason.type == "fall" then
    awards.unlock(ObjectRef:get_player_name(), "gravitation")
  end
end)

awards.register_award("award_lumberjack", {
  title = "Lumberjack",
  description = "Dig 36 tree blocks.",
  icon = "awards_lumberjack.png",
  difficulty = 0.03,
  trigger = {
    type = "dig",
    node = "default:tree",
    target = 36
  }
})

awards.register_award("award_junglebaby", {
  title = "Junglebaby",
  description = "Dig 36 jungle tree blocks.",
  icon = "awards_junglebaby.png",
  difficulty = 0.05,
  trigger = {
    type = "dig",
    node = "default:jungletree",
    target = 36
  }
})

awards.register_award("award_mine2", {
  title = "Mini Miner",
  description = "Dig 100 stone blocks.",
  icon = "awards_mini_miner.png^awards_level1.png",
  background = "awards_bg_mining.png",
  difficulty = 0.02,
  trigger = {
    type = "dig",
    node = "default:stone",
    target = 100
  }
})
