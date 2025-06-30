local SceneHandler 
SceneHandler = am.group()
local import = require('Modules.Import')

-- function SceneHandler:new_scene(s)
-- 	if(s == SceneHandler) then s = s2 end
-- 	local scene = import(s)
-- 	self:replace(self:child(1),scene)
-- 	return scene
-- end



function SceneHandler:load_scene(s,args)
	local ls = SceneHandler.current_scene
	local la = SceneHandler.current_args
	self:set_scene(am.text('LOADING'):action(function() 
		SceneHandler.current_scene = ls
		SceneHandler.current_args = la
		self:set_scene(s,args)
	end))
end
function SceneHandler:back_a_scene()
	SceneHandler:load_scene(SceneHandler.last_scene,SceneHandler.last_args)

end
function SceneHandler:reload_scene(s,args)
	SceneHandler:load_scene(SceneHandler.current_scene,SceneHandler.current_args)
end
function SceneHandler:set_scene(s,args)
	SceneHandler.last_scene = SceneHandler.current_scene
	SceneHandler.last_args = SceneHandler.current_args
	if(s == SceneHandler) then s = args;args=nil end
	SceneHandler.current_scene = s
	SceneHandler.current_args = args
	if(type(s) == "string") then
		s = import('Modules.Scenes.'..s)
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
	return s
end
function SceneHandler:get_scene(s)
	return SceneHandler.current_scene
end




return SceneHandler