-- Add minimum build range
local old_is_protected = minetest.is_protected
local r = ctf.setting("flag.nobuild_radius")
local rs = r * r
function minetest.is_protected(pos, name)
	if string.sub(minetest.get_node(pos).name, 1, 8) == "ctf_map:" then
		return true
	end

	if r <= 0 or rs == 0 then
		return old_is_protected(pos, name)
	end

	local flag, distSQ = ctf_flag.get_nearest(pos)
	if flag and pos.y >= flag.y - 1 and distSQ < rs then
		minetest.chat_send_player(name,
			"Too close to the flag to build! Leave at least " .. r .. " blocks around the flag.")
		return true
	else
		return old_is_protected(pos, name)
	end
end
