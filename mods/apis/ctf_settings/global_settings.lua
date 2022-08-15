ctf_settings.register("ctf_kill_list:tp_size", {
	type = "list",
	description = "Your texturepack's texture size. Used to scale things like kill feed images",
	list = {"8px", "16px", "32px", "64px", "128px", "256px"},
	image_scale_map = {2, 1, 0.5, 0.25, 0.125, 0.0625},
	default = "2",
})
