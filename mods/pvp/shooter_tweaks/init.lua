local function wrap_callback(name, callback, func)
	assert(type(name) == "string")
	assert(type(callback) == "string")

	local old_callback = minetest.registered_items[name][callback]
	assert(old_callback)

	local overrides = {}
	overrides[callback] = function(...)
		return func(old_callback, ...)
	end

	minetest.override_item(name, overrides)
end

wrap_callback("shooter_hook:grapple_hook", "on_use", function(old, itemstack, ...)
	itemstack:add_wear(65536 / 16)
	return old(itemstack, ...)
end)

wrap_callback("shooter_hook:grapple_gun_loaded", "on_use", function(old, itemstack, ...)
	itemstack:add_wear(65536 / 8)
	return old(itemstack, ...)
end)

wrap_callback("shooter_hook:grapple_gun", "on_use", function(old, itemstack, user)
	local inv = user:get_inventory()
	if inv:contains_item("main", "shooter_hook:grapple_hook") then
		minetest.sound_play("shooter_reload", {object=user})
		local stack = inv:remove_item("main", "shooter_hook:grapple_hook")
		itemstack = "shooter_hook:grapple_gun_loaded 1 "..stack:get_wear()
	else
		minetest.sound_play("shooter_click", {object=user})
	end
	return itemstack
end)
