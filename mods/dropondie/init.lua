local blacklist_drop = {
	"default:pick_wood",
	"default:sword_wood",
	"default:ax_wood"
}

local function drop(pos, itemstack)
	local it = itemstack:take_item(itemstack:get_count())
	local sname = it:get_name()

	for _, item in pairs(blacklist_drop) do
		if sname == item then
			return
		end
	end
	if sname == "default:torch" then
		it:take_item(3)
		if it:get_count() <= 0 then
			return
		end
	end

	local obj = core.add_item(pos, it)

	if obj then
		obj:setvelocity({x=math.random(-1,1), y=5, z=math.random(-1,1)})

		local remi = minetest.setting_get("remove_items")
		if minetest.is_yes(remi) then
			obj:remove()
		end

	end
	return itemstack
end

local function drop_all(player)
	if minetest.setting_getbool("creative_mode") then
		return
	end

	local pos = player:getpos()
	pos.y = math.floor(pos.y + 0.5)

	local player_inv = player:get_inventory()

	for i=1,player_inv:get_size("main") do
		drop(pos, player_inv:get_stack("main", i))
		player_inv:set_stack("main", i, nil)
	end

	for i=1,player_inv:get_size("craft") do
		drop(pos, player_inv:get_stack("craft", i))
		player_inv:set_stack("craft", i, nil)
	end
end

minetest.register_on_dieplayer(drop_all)
minetest.register_on_leaveplayer(drop_all)
