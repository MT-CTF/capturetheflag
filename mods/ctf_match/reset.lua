ctf.register_on_init(function()
	ctf._set("match.map_reset_limit",    0)
end)

function ctf_match.next()
	for i = 1, #ctf_match.registered_on_new_match do
		ctf_match.registered_on_new_match[i]()
	end

	local r = ctf.setting("match.map_reset_limit")
	if r > 0 then
		minetest.chat_send_all("Resetting the map, this may take a few moments...")
		minetest.after(0.5, function()
			minetest.delete_area(vector.new(-r, -r, -r), vector.new(r, r, r))

			minetest.after(1, function()
				ctf.reset()
				if vote then
					vote.active = {}
					vote.queue = {}
					vote.update_all_hud()
				end
			end)
		end)
	else
		ctf.reset()
		if vote then
			vote.active = {}
			vote.queue = {}
			vote.update_all_hud()
		end
	end
end
