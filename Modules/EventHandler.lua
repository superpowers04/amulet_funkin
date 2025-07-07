local EventHandler = {events={}}

function EventHandler:clear()
	self.events = {}
end

function EventHandler:newEvent(event)
	self.events[event] = {}
end

function EventHandler:register(event, func, name)
	local ev = self.events[event]
	if not ev then error('Invalid event: ' .. tostring(event)) end
	if not name then name = #ev+1 end
	ev[name] = func
end
function EventHandler:call(event,...)
	local ev = self.events[event]
	if not ev then return end
	for i,v in pairs(ev) do
		local succ,err = pcall(v,...)
		if not succ then
			return SceneHandler:set_scene('results',{('Error with %s:%s\n%s'):format(event,i,err)})
		end
	end
end
setmetatable(EventHandler,{__index=events,__newindex=function(self,k,v)
	if(type(v) == "table") then
		return self:call(k,unpack(v))
	elseif type(v) == "function" then
		return self:register(k,v)
	end
end})

return EventHandler