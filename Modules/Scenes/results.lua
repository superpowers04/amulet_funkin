return function(stuff,on_enter,on_back)
	local scene = am.group()
	stuff = stuff or "N/A"
	print(stuff)
	if not on_enter then
		on_enter = function() SceneHandler:reload_scene() end
		stuff = stuff .. "\n\nPress Enter, or Space to restart\nPress Escape or Backspace to return to list"
	end
	if not on_back then
		on_back = function() SceneHandler:set_scene('list') end
	end
	local TEXT = am.text(stuff,nil,"center","center")
	scene:append(TEXT)
	scene:action(function()
		if(win:key_pressed("backspace") or win:key_pressed("escape")) then
			on_back()
		end
		if(win:key_pressed("enter") or win:key_pressed("space")) then
			on_enter()
		end
	end)

	return scene
end