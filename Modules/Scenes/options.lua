function execute(str)
	local f = io.popen(str,'r')
	local content =f:read('*a')
	f:close()
	return content
end
local settings = import'SETTINGS'
local function fromArray(self,a) return self.name .. " : " ..(self.values[a] or a) end
local function arrayNavigate(self,a,b) return (a+b) % (#self.values+1)  end
local options={
	{
		name = "Instrumental Volume",
		var = 'instVol',
		increment = 0.01,max=10,min=0,
		display = function(self,a) 
			return self.name .. " : " ..math.floor(a*100).."%"
		end
	},
	{
		name = "Vocals Volume",
		var = 'voicesVol',
		increment = 0.01,max=10,min=0,
		display = function(self,a) 
			return self.name .. " : " ..math.floor(a*100).."%" 
		end
	},
	{
		name = "Miss Sound Volume",
		var = 'missVol',
		increment = 0.01,max=10,min=0,
		display = function(self,a) 
			return self.name .. " : " ..math.floor(a*100).."%" 
		end
	},
	{
		name = "Ghosttap Sound Volume",
		var = 'ghostVol',
		increment = 0.01,max=10,min=0,
		display = function(self,a) 
			return self.name .. " : " ..math.floor(a*100).."%" 
		end
	},
	{
		name = "Chart type",
		var = 'side',
		values = {[0]="player",[1]="opponent",[2]="both"},
		change = arrayNavigate,
		display = fromArray
	},
	{
		name = "Scroll Direction/Speed",
		var = 'scrollDir',
		increment = 0.01,
		change = function(self,v,a,enter) 
			if enter then return -v end
			if(a<0) then a = -a end
			return v+(a*(0.01))
		end,
		display = function(s,a) return s.name .. " : " ..(a<0 and 'DOWNSCROLL/' .. -a or "UPSCROLL/" .. a) end
	},
}


local hover,normal = vec4(1,1,1,1),vec4(0.6,0.6,0.6,1)
local menuList = am.group{}
local group = am.group{
	am.translate(-100,300)^am.text('Press Escape or Backspace to go back\nShift to change by 10'),
	menuList
}
local function updateText(i)
	local option = options[i]
	menuList:child(i):child(1).text = option.display and option:display(settings[option.var]) or option.name .. " : " .. settings[option.var]
end

for index,option in pairs(options) do
	menuList:append(am.translate(0,index*15) ^ am.text(
		"" 
		,nil,"left",'top'))
	updateText(index)
end


local scroll = 1
local keyRepeat = 0
function changeOption(id,direction,enter)
	local setting = options[id]
	local settingName = setting.var
	local v = settings[settingName]
	if(setting.change) then
		settings[settingName] = setting:change(v,direction,enter)
	else
		local value = v+((setting.increment or 1)*direction)
		if(setting.min) then value = math.max(value,setting.min) end
		if(setting.max) then value = math.min(value,setting.max) end
		settings[settingName] = value
	end
	updateText(id)
end



group:action(function(g)
	for i,child in menuList:child_pairs() do
		child.y = (scroll - i) * 15
		child:child(1).color = i==scroll and hover or normal
	end
	local mw = win:mouse_wheel_delta().y
	if(mw ~= 0) then
		scroll = math.min(math.max(scroll-math.ceil(mw),1),#songs)
	end
	if(#win:keys_down() == 0) then
		keyRepeat = 0
		return
	end
	keyRepeat = keyRepeat - am.delta_time


	if(win:key_down('left') and keyRepeat <= 0) then
		changeOption(scroll,-1 * (win:key_down('lshift') and 10 or 1))
		keyRepeat = 0.2
	end
	if((win:key_down('right') ) and keyRepeat <= 0) then
		changeOption(scroll,1 * (win:key_down('lshift') and 10 or 1),win:key_down('enter'))
		keyRepeat = 0.2
	end
	if(win:key_pressed('enter')) then
		changeOption(scroll,1 * (win:key_down('lshift') and 10 or 1),true)
		keyRepeat = 0.2
	end


	if(win:key_down('up') and keyRepeat <= 0) then
		scroll = math.max(scroll-1,1)
		keyRepeat = 0.2
	end
	if(win:key_down('down') and keyRepeat <= 0) then
		scroll = math.min(scroll+1,#options)
		keyRepeat = 0.2
	end
	if(win:key_pressed('escape') or win:key_pressed('backspace')) then
		local f= io.open('SETTINGS.lua','w')
		f:write('return ' .. table.tostring(settings))
		f:close()
		-- SceneHandler:load_scene(group.scene or 'list',group.arguments)
		SceneHandler.back_a_scene()
		group.scene = nil
		group.args = nil
	end
end)

return am.translate(-310,0) ^ group,group
