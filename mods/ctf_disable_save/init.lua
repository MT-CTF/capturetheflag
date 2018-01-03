ctf.save = function()
	for i = 1, #ctf.registered_on_save do
		local res = ctf.registered_on_save[i]()
	end
end
