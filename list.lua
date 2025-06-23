function execute(str)
	local f = io.popen(str,'r')
	local content =f:read('*a')
	f:close()
	return content
end


local songList = am.group{}
local group = am.group{am.sprite("p.\n.p\np."),songList}

local songs = {}
do
	local jsons = {}
	local insts = {}
	for line in execute('find mods/'):gmatch('[^\n]+') do
		if(line:find('%.json$')) then
			jsons[line] = true
		elseif line:find('Inst.ogg$') then
			insts[line] = true
		end
	end

	for file in pairs(jsons) do
		if(file:sub(-12) ~= "/events.json" and insts[file:gsub('[^/]+$','Inst.ogg')]) then
			table.insert(songs,file)
		end
	end
	table.sort(songs)

end
for index,song in pairs(songs) do
	songList:append(am.translate(0,index*15) ^ am.text(song:gsub('^mods/',''):gsub('/charts/',' > '),nil,"left",'top'))
end
local hover,normal = vec4(1,1,1,1),vec4(0.6,0.6,0.6,1)

local scroll = 1
local keyRepeat = 0
group:action(function(g)
	for i,v in pairs(songs) do
		local child = songList:child(i)
		child.y = (scroll - i) * 15
		child:child(1).color = i==scroll and hover or normal
	end
	if(#win:keys_down() == 0) then
		keyRepeat = 0
		return
	end
	keyRepeat = keyRepeat - am.delta_time
	if(win:key_down('up') and keyRepeat <= 0) then
		scroll = math.max(scroll-1,1)
		keyRepeat = 0.2
	end
	if(win:key_down('down') and keyRepeat <= 0) then
		scroll = math.min(scroll+1,#songs)
		keyRepeat = 0.2
	end
	if(win:key_pressed('enter')) then
		win.scene = require('play')(songs[scroll])
	end
end)

return am.translate(-310,0) ^ group
