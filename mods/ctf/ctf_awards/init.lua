local AMS = minetest.get_mod_storage()
awards.register_award("ctf",{
  title = "Capture The Flag!",
  description = "Capture The Flag",
  icon = "awards_ctf_icon.png",
  difficulty = 1,
})

awards.register_award("ctf_ten",{
  title = "The Master of Capturing!",
  description = "Capture The Flag ten times",
  icon = "awards_ctf_icon.png",
  difficulty = 5,
})

awards.register_award("ctf_king",{
  title = "The King of Capturing!",
  description = "Capture The Flag 100 times!",
  icon = "awards_ctf_icon.png",
  difficulty = 5,
})

ctf_flag.register_on_capture(function(attname,flag)
  minetest.after(0,function()
  CAPS = ctf_stats.player(attname).captures
  if CAPS >= 100 then
    awards.unlock(attname, "ctf_king")
  elseif CAPS >= 10 then
    awards.unlock(attname, "ctf_ten")
  end
  awards.unlock(attname, "ctf")
  end)
end)


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
