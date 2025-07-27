import = require('Modules.Import')
PlatformUtils = import'Modules.PlatformUtils'
TextInsert = import'Modules.TextInsert'
function execute(str)
	local f = io.popen(str,'r')
	local content =f:read('*a')
	f:close()
	return content
end


local songList = am.group{}
local text_insert = TextInsert.new()
-- local animHandler = require('Modules.AnimationHandler')
local group = am.group{
	am.translate(-100,300)^am.text('Press O to open options. S to search'):action(function()
		if(text_insert.active) then return end
		if(win:key_down('o')) then
			SceneHandler:set_scene('options')
		elseif(win:key_down('s')) then
			text_insert:activate()
		end
	end),
	am.translate(-250,250) ^ text_insert,
	songList,
	-- animHandler.sprite_anims('assets/NOTE_assets.png',{scroll=animHandler.frame(1850,154,157,154)},"scroll",24,true)
}

local songs = {}
local search = ""
local scroll = 1
local function reloadSongs()

	songList:remove_all()
	songs = {}
	do
		local jsons = {}
		local insts = {}
		for _,line in pairs(PlatformUtils.getDirectory('mods/charts/')) do
			if(line:find('%.json$')) then
				jsons[line] = true
			elseif line:find('Inst.ogg$') then
				insts[line:sub(0,-9)] = true
			end
		end
		for _,line in pairs(PlatformUtils.getDirectory('fnfmods/')) do
			if(line:find('%.json$')) then
				jsons[line] = true
			elseif line:find('Inst.ogg$') then
				insts[line:sub(0,-9)] = true
			end
		end
		local function exists(paths)
			for i,v in pairs(paths) do
				if(insts[v]) then return v end
			end
			return nil
		end
		for file in pairs(jsons) do
			if(file:sub(-12) ~= "/events.json" and (search == "" or file:find(search))) then
				if(insts[file:gsub('[^/]+$','')]) then
					table.insert(songs,{file})
				else
					local f = file:gsub('[^/]+$','')
					local what = exists({
						f:gsub('/data/','/songs/'),
					})
					if what then
						table.insert(songs,{file,what})
					end
				end
			end
		end
		table.sort(songs,function(a,b) return a[1]<b[1] end)
	end
	for index,song in pairs(songs) do
		local song = song[1]
		songList:append(am.translate(0,index*15) ^ am.text(song:gsub('/data/',' > '):gsub('^fnfmods/','fnf > '):gsub('^mods/',' '):gsub('/charts/',' > '),nil,"left",'top'))
	end
	scroll = 1
end
reloadSongs()
-- if(#songs == 0) then return am.scale(2) ^ am.text('NO CHARTS!') end
local hover,normal = vec4(1,1,1,1),vec4(0.6,0.6,0.6,1)

local keyRepeat = 0
local resetNode = am.group()
resetNode:action("reload",function() import.clearCache(); group:remove(resetNode) end)
group:append(resetNode)
group:action(function(g)
	if(text_insert.active) then return end
	for i,v in pairs(songs) do
		local child = songList:child(i)
		child.y = (scroll - i) * 15
		child:child(1).color = i==scroll and hover or normal
		child.hidden = (child.y > 200 and child.y < 500)
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
	if(win:key_down('up') and keyRepeat <= 0) then
		scroll = math.max(scroll-1,1)
		keyRepeat = 0.2
	end
	if(win:key_down('down') and keyRepeat <= 0) then
		scroll = math.min(scroll+1,#songs)
		keyRepeat = 0.2
	end
	if(win:key_pressed('enter')) then
		SceneHandler:load_scene('play',songs[scroll])
		group:append(resetNode)
	end
end)
text_insert.onEnter = function(_,buffer)
	search = buffer
	reloadSongs()
	local node = am.group{}
	group:append(node)
	node:action(function()
		text_insert.deactivate()
		group:remove(node)
	end)
end
function text_insert.onDeactivate()
	text_insert.color = normal
end
function text_insert.onActivate()
	text_insert.color = hover
	pcall(function()
		songList:child(scroll):child(1).color = normal
	end)
end
return am.translate(-310,0) ^ group
