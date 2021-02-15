function map_maker.show_gui(name)
	local context = map_maker.get_context()
	local mapauthor = context.mapauthor or name

	local formspec = {
		"size[9,9.5]",
		"bgcolor[#080808BB;true]",
		default.gui_bg,
		default.gui_bg_img,

		"label[0,0;1. Select Area]",
		"field[0.4,1;1,1;posx;X;", context.center.x, "]",
		"field[1.4,1;1,1;posy;Y;", context.center.y, "]",
		"field[2.4,1;1,1;posz;Z;", context.center.z, "]",
		"field[0.4,2;1.5,1;posr;R;", context.center.r, "]",
		"field[1.9,2;1.5,1;posh;H;", context.center.h, "]",
		"button[4.3,0.7;1.75,1;set_center;Player Pos]",
		"button[6.05,0.7;1.5,1;towe;To WE]",
		"button[7.55,0.7;1.5,1;fromwe;From WE]",
		"button[4.3,1.7;4.75,1;emerge;Emerge Area]",

		"box[0,2.65;8.85,0.05;#111111BB]",

		"label[0,2.8;2. Place Barriers]",
		"label[0.1,3.3;This may take a few minutes.]",
		"field[0.4,4.3;1,1;barrier_r;R;", context.barrier_r, "]",
		"dropdown[1.15,4.05;1,1;barrier_rot;X=0,Z=0;",
		context.barrier_rot == "x" and 1 or 2, "]",
		"button[2.3,4;2,1;place_barriers;Place Barriers]",

		"box[4.4,2.8;0.05,2.2;#111111BB]",

		"label[4.8,2.8;3. Place Flags]",
		"label[4.8,3.3;", minetest.formspec_escape(map_maker.get_flag_status()), "]",
		"button[4.8,4;3.5,1;giveme;Giveme Flags]",

		"box[0,5.06;8.85,0.05;#111111BB]",

		"label[0,5.15;4. Meta Data]",
		"field[0.4,6.2;8.5,1;title;Title;",
		minetest.formspec_escape(context.maptitle), "]",
		"field[0.4,7.3;8.5,1;initial;Stuff to give on (re)spawn, comma-separated itemstrings;",
		minetest.formspec_escape(context.mapinitial), "]",
		"field[0.4,8.4;4.25,1;name;File Name;",
		minetest.formspec_escape(context.mapname), "]",
		"field[4.625,8.4;4.25,1;author;Author;",
		minetest.formspec_escape(mapauthor), "]",

		"button_exit[1.3,9;3,1;close;Close]",
		"button_exit[4.3,9;3,1;export;Export]",
	}

	formspec = table.concat(formspec, "")
	minetest.show_formspec(name, "ctf_map:tool", formspec)
end

function map_maker.show_progress_formspec(name, text)
	minetest.show_formspec(name, "ctf_map:progress",
		"size[6,1]bgcolor[#080808BB;true]" ..
		default.gui_bg ..
		default.gui_bg_img .. "label[0,0;" ..
		minetest.formspec_escape(text) .. "]")
end

function map_maker.emerge_progress(ctx)
	map_maker.show_progress_formspec(ctx.name,
		string.format("Emerging Area - %d/%d blocks emerged (%.1f%%)",
		ctx.current_blocks, ctx.total_blocks,
		(ctx.current_blocks / ctx.total_blocks) * 100))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "ctf_map:tool" then
		return
	end

	local name = player:get_player_name()

	if fields.posx or fields.posy or fields.posz or fields.posh or fields.posr then
		map_maker.set_center(name, {
			x = tonumber(fields.posx),
			y = tonumber(fields.posy),
			z = tonumber(fields.posz),
			h = tonumber(fields.posh),
			r = tonumber(fields.posr)
		})
	end

	if fields.barrier_r then
		map_maker.set_meta("barrier_r", tonumber(fields.barrier_r))
	end

	if fields.title then
		map_maker.set_meta("maptitle", fields.title)
	end

	if fields.author then
		map_maker.set_meta("mapauthor", fields.author)
	end

	if fields.name then
		map_maker.set_meta("mapname", fields.name)
	end

	if fields.initial then
		map_maker.set_meta("mapinitial", fields.initial)
	end

	if fields.barrier_rot then
		map_maker.set_meta("barrier_rot", fields.barrier_rot == "X=0" and "x" or "z")
	end

	if fields.set_center then
		map_maker.set_center(name)
	end

	if fields.giveme then
		player:get_inventory():add_item("main", "ctf_map:flag 2")
	end

	if fields.emerge then
		map_maker.emerge(name)
	end

	if fields.place_barriers then
		map_maker.place_barriers(name)
	end

	if fields.towe then
		map_maker.we_select(name)
	end

	if fields.fromwe then
		map_maker.we_import(name)
	end

	if fields.export then
		map_maker.export(name)
	end

	if not fields.quit then
		map_maker.show_gui(name)
	end
end)

minetest.register_chatcommand("gui", {
	func = function(name)
		map_maker.show_gui(name)
		return true
	end
})
