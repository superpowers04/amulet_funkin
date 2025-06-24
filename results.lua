return function(stuff,on_enter,on_back)
	local scene = am.group()
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