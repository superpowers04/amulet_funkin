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
	self:set_scene(self:get_loading_scene(s,args))
end
function SceneHandler:get_loading_scene(s,args)
	local ls = self.current_scene
	local la = self.current_args
	local LOADING = am.text('LOADING')
	return LOADING:action(function() 
		if self.current_scene == LOADING then
			self.current_scene = ls
			self.current_args = la
			self:set_scene(s,args)
		end
	end)
end

function SceneHandler:back_a_scene()
	SceneHandler:load_scene(SceneHandler.last_scene,SceneHandler.last_args)

end
function SceneHandler:reload_scene()
	SceneHandler:load_scene(SceneHandler.current_scene,SceneHandler.current_args)
end
function SceneHandler:set_scene(s,args)
	self.last_scene = SceneHandler.current_scene
	self.last_args = SceneHandler.current_args
	if(s == SceneHandler) then s = args;args=nil end
	self.current_scene = s
	self.current_args = args
	local _s = s
	local succ,err = pcall(function()
		if(type(s) == "string") then
			s = import('Modules.Scenes.'..s)
		end
		if(args) then
			s = s((table.unpack or unpack)(args))
		end
	end)
	if not succ then
		error('Error while trying to switch scenes:\n'..tostring(err))
	end

	if(self.current_scene ~= _s) then 
		print('SCENE CHANGED WHILE TRYING TO CHANGE SCENE, ABORTING SCENE CHANGE!')
		return self.current_scene
	end -- Scene must've changed while trying to execute the above ABORT ABORT

	local child = self:child(1)
	if not child then
		self:append(s)
		return
	end
	self:replace(child,s)
	return s
end
function SceneHandler:get_scene(s)
	return self.current_scene
end




return SceneHandler