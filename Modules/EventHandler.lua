local EventHandler = {events={}}

function EventHandler:clear()
	self.events = {}
end

function EventHandler:newEvent(event)
	self.events[event] = {}
end

function EventHandler:register(event, name, func)
	local ev = self.events[event]
	if not ev then return end
	if not name then name = #ev+1 end
	ev[name] = func
end
function EventHandler:call(name,...)
	local ev = self.events[name]
	if not ev or #ev == 0 then return end
	for i,v in pairs(ev) do
		v(...)
	end
end
setmetatable(EventHandler,{__index=events,__newindex=function(self,k,v)
	if(type(v) == "table") then
		return self:call(k,unpack(v))
	elseif type(v) == "function" then
		return self:register(k,nil,v)
	end
end})

return EventHandler