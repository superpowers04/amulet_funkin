local SceneHandler 
SceneHandler = am.group()
local import = require('Modules.Import')

function SceneHandler:new_scene(s)
	if(s == SceneHandler) then s = s2 end
	local scene = import(s)
	self:replace(self:child(1),scene)
	return scene
end



function SceneHandler:load_scene(s,args)
	self:set_scene(am.text('LOADING'):action(function() 

		self:set_scene(s,args)
	end))
end
function SceneHandler:set_scene(s,args)
	if(s == SceneHandler) then s = args;args=nil end
	if(type(s) == "string") then
		s = import(s)
	end
	if(args) then
		s = s((table.unpack or unpack)(args))
	end
	local child = SceneHandler:child(1)
	if not child then
		SceneHandler:append(s)
		return
	end
	SceneHandler:replace(child,s)
end
function SceneHandler:get_scene(s)
	if(s == SceneHandler) then s = s2 end
	return SceneHandler:child(1)
end




return SceneHandler