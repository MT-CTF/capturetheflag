local latest_updates = minetest.formspec_escape([[
- Prevented knights from using the SMG
- Gave medic class building tools and prevented them from using SMG/Shotgun
- Changed fall damage to use the combat system
- Increased damage dealt by knights (+1 hp) when wielding swords
- Merged the sniper class with the shooter class
- Changed bandages to give two points per heal
- Made rifle automatic and doubled damage
- Added combat mode
- Added Sticky grenades
- Added automatic skip votes
]])

if minetest.global_exists("sfinv") then
	sfinv.register_page("latest_updates:latest_updates", {
		title = "Updates",
		get = function(self, player, context)
			return sfinv.make_formspec(player, context,
				"real_coordinates[true]" ..
				"box[0.1,0.5;10.4,10.25;#222222]" ..
				"textarea[0.1,0.5;10.4,10.25;;The latest updates to CTF are listed here;" .. latest_updates .. "]", false)
		end
	})
end
