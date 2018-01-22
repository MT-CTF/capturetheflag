
local function emergeblocks_callback(pos, action, num_calls_remaining, ctx)
	if ctx.total_blocks == 0 then
		ctx.total_blocks   = num_calls_remaining + 1
		ctx.current_blocks = 0
	end
	ctx.current_blocks = ctx.current_blocks + 1

	if ctx.current_blocks == ctx.total_blocks then
		if ctx.name then
			minetest.chat_send_player(ctx.name,
				string.format("Finished emerging %d blocks in %.2fms.",
				ctx.total_blocks, (os.clock() - ctx.start_time) * 1000))
		end

		ctx:callback()
	elseif ctx.progress then
		ctx:progress()
	end
end

function ctf_map.emerge_with_callbacks(name, pos1, pos2, callback, progress)
	local context = {
		current_blocks = 0,
		total_blocks   = 0,
		start_time     = os.clock(),
		name           = name,
		callback       = callback,
		progress       = progress
	}

	minetest.emerge_area(pos1, pos2, emergeblocks_callback, context)
end
