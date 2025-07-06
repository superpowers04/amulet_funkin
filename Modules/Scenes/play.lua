local this
this = function(...)
	local import = require('Modules.Import')
	local Events = import'Modules.EventHandler'
	local PlatformUtils = import'Modules.PlatformUtils'
	local NoteLoader = import("Modules.NoteLoader")
	local AnimationHandler = import'Modules.AnimationHandler'
	-- local ISDEBUG = true
	local SCRIPTENV = setmetatable({
		Events=Events,
		PlatformUtils=PlatformUtils,
		NoteLoader=NoteLoader,
		AnimationHandler=AnimationHandler,
		-- Game=getfenv()
	},{__index=getfenv()})
	Events:clear()




	local arguments = {...}
	local chart,instDir = ...
	-- TODO - Unhardcode chart loading


	options=import('SETTINGS')
	local buttons = options.buttons

	local PWD = os.getenv('PWD')
	if(chart:sub(0,#PWD) == PWD) then
		chart = chart:sub(#PWD)
	end

	local songMeta = {
		songNotes = {},
		speed = options.scrollDir,
	}


	if not chart then 
		print('no bitches')
		return import('results',{'No chart!\nPress Enter, Space, Escape or Backspace to return to list',function()win.scene = require('list') end,function()win.scene = require('list') end})
	end
	Events:newEvent('update')
	Events:newEvent('noteHit') -- id, diff
	Events:newEvent('noteMiss') -- id
	Events:newEvent('noteGhost') -- id
	Events:newEvent('noteHold') -- 
	Events:newEvent('noteGen') -- noteobj
	Events:newEvent('noteParse') -- Noteobj
	Events:newEvent('songParse')

	for i,v in pairs(PlatformUtils.getDirectory('mods/scripts')) do
		if(v:find('/play.lua') or v:find('mods/scripts/[^/]*%.lua$')) then
			local chunk,err = loadfile(v)
			if not chunk then
				return SceneHandler:set_scene('results',{('Error while parsing %s: %s'):format(v,err or "")})
			end
			local chunk = setfenv(chunk,setmetatable({},{__index=SCRIPTENV}))
			local succ,err = pcall(chunk)
			if not succ then
				return SceneHandler:set_scene('results',{('Error while executing %s: %s'):format(v,err or "")})
			end
		end
	end
	local scene = am.group()
	scene.arguments = arguments
	scene.ENV = _ENV or getfenv()
	local songNotes = songMeta.songNotes
	local both_sides = options.side == 2
	local side = options.side == 1
	do -- SONG PARSING
		local str = am.parse_json(am.load_string(chart))
		Events:call('songParse',str)
		songMeta.bpm = math.abs(str.song.bpm)
		local bpm = math.abs(songMeta.bpm)
		local crochet = ((60 / bpm) * 1000)
		local stepCrochet = crochet / 4
		for i,SECTION in ipairs(str.song.notes) do
			if(SECTION.changeBPM) then
				bpm = math.abs(SECTION.bpm)
				crochet = ((60 / bpm) * 1000)
				stepCrochet = crochet / 4
			end
			for nid,note in ipairs(SECTION.sectionNotes) do
				if(both_sides or side == SECTION.mustHitSection == (note[2]>4)) then
					note[2]=(note[2]%4)+1
					if(note[2] < 5) then
						songNotes[#songNotes+1] = note
					end
					Events:call('noteParse',note)
				else
					Events:call('noteSkipParse',note)

				end
			end
		end
		table.sort(songNotes,function(a,b) return a[1] < b[1] end)
	end
	local inst_buffer = am.load_audio((instDir or chart:gsub('[^/]+$','')).."/Inst.ogg")
	local songLength = inst_buffer.length*1000
	print(songLength)
	local inst = am.track(inst_buffer,false,1,options.instVol)
	local voices
	pcall(function()
		voices = am.track(am.load_audio((instDir or chart:gsub('[^/]+$','')).."/Voices.ogg"),false,1,options.voicesVol)
	end)
	local noteSprites = { 
		NoteLoader.getNote('left'):strum(),
		NoteLoader.getNote('down'):strum(),
		NoteLoader.getNote('up'):strum(),
		NoteLoader.getNote('right'):strum(),
	}


	local arrowSprites = {
		NoteLoader.getNote('left'):scroll(),
		NoteLoader.getNote('down'):scroll(),
		NoteLoader.getNote('up'):scroll(),
		NoteLoader.getNote('right'):scroll(),
	}
	do
		local scale = 0.05
		for i,v in pairs(arrowSprites) do 
			v.scale.x = scale
			v.scale.y = scale
			-- v.scale.z = scale
		end
		for i,v in pairs(noteSprites) do 
			v.scale.x = scale
			v.scale.y = scale
			-- v.scale.z = scale
		end
	end
	-- local arrowSprites = { am.sprite([[
	-- .MM
	-- MMM
	-- .MM]]), am.sprite([[
	-- BBB
	-- BBB
	-- .B.]]), am.sprite([[
	-- .G.
	-- GGG
	-- GGG]]), am.sprite([[
	-- RR.
	-- RRR
	-- RR.]]),
	-- }

	local lerp = function(a, b, t)
		return a + (b - a) * t
	end

	local noteGroup = am.group()
	local strumGroup = am.group()
	local strumTransforms = {}
	local notes = {}
	local pressed = {false,false,false,false}
	local misses = 0
	local combo = 0
	local ghosttaps = 0
	local notesHitAccuracy = 0
	local notesHit = 0
	local notesEncountered=0
	local heldColor,unheldColor=vec4(1,1,1,1),vec4(0.6,0.6,0.6,1)
	local paused = false
	local queuedNotes = {}

	strumTransformAction = function(t) 
		t.y = lerp(t.y,1,am.delta_time)
		t.x = lerp(t.x,1,am.delta_time)
	end
	-- strumSpriteAction = function(t) 
	-- 	t = t.color
	-- 	t.y = lerp(t.y,1,0.2)--;t.y=t.x;
	-- end
	function getStrumPosition(i)
		return am.translate(((10*i)*options.scale),10) ^ am.scale(options.scale)
	end
	for i,N in pairs(noteSprites) do
		strumGroup:append(am.scale(1):action(strumTransformAction) ^ getStrumPosition(i) ^ N)
	end
	for i,N in pairs(songMeta.songNotes) do
		if(N[2] < 5) then
			queuedNotes[#queuedNotes+1] = N
		end
	end

	noteExists = #queuedNotes

	txt = am.text('',nil,"LEFT","TOP");
	scene = am.translate(-200,0) ^ am.translate(0,200*(options.scrollDir > 0 and 1 or -1)) ^ am.group{
		noteGroup,
		strumGroup,
	}

	local tracker = am.translate(-180,-120*(options.scrollDir > 0 and 1 or -1)) ^ txt
	local startTracker = am.translate(-180,-20) ^ txt

	tracker:action(am.play(inst))
	if(voices) then tracker:action(am.play(voices)) end
	missSound = am.load_audio('assets/sounds/missnote1.ogg')
	ghostSound = am.load_audio('assets/sounds/missnote1.ogg')
	local time = 0

	local function noteMiss(id)
		notesEncountered=notesEncountered+1
		misses = misses + 1
		combo = 0
		scene:action("MISS",am.play(missSound,false,0.75 + ((id/4)*0.5)),options.missVol)
		-- strumGroup:child(id).y = 0.8
		-- noteSprites[id]:press()
		if(voices) then voices.volume = 0 end
		Events:call('noteMiss',id)
	end
	local function ghost(id)
		ghosttaps = ghosttaps + 1
		scene:action("Ghost",am.play(ghostSound,false,0.75 + ((id/4)*0.2)),options.ghostVol)
		-- strumGroup:child(id).y = 0.8
		noteSprites[id]:press()
		Events:call('noteGhost',id,diff)
	end
	local function noteHit(id,diff)
		notesEncountered=notesEncountered+1
		combo = combo + 1
		local close = (1 - math.abs(diff));
		notesHitAccuracy = notesHitAccuracy+close
		notesHit = notesHit + 1
		-- strumGroup:child(id).y = 1 + (close*0.3)
		noteSprites[id]:hit()
		Events:call('noteHit',id,diff)

		if(voices) then voices.volume = options.voicesVol end
	end
	local function updateNoteVisuals()
		local speed = songMeta.speed
		while(queuedNotes[1] and queuedNotes[1][1]-time < 4000) do
			local N = table.remove(queuedNotes,1)
			local SPR = getStrumPosition(N[2]) ^ arrowSprites[N[2]]
			local transform = am.translate(0,0) ^ SPR
			local NOTE = {t=N[1],d=N,s=transform}
			noteGroup:append(transform)
			notes[#notes+1] = NOTE
			if(N[3] ~= 0) then
				NOTE.endTime = N[3]+NOTE.t
				NOTE.r = am.rect(-5,0,5,-N[3]*speed,vec4(1,1,1,1))
				-- print(NOTE.r.y2,speed)
				SPR:append(NOTE.r)
				-- notes[#notes+1] = NOTE
			end

		end
		for i, note in pairs(notes) do
			local d
			if(note.r and note.p) then
				d = time
				note.r.y2 = -(note.endTime-time)*speed
			else
				d= note.t
			end
			local transform = note.s;
			local diff = (time - d);
			transform.y = (diff * speed)
		end
	end
	local function on_finish()
		
		SceneHandler:set_scene('results',{("%s\nTime: %2i:%i\nMisses/Ghost: %i/%i\nCombo: %i\nAccuracy: %i(%i/%i)\nNotes Left: %i/%i"):format(
			chart:match('[^/]+$'),
			math.floor(time/60000),math.floor(time/1000%60),
			misses,ghosttaps,
			combo,
			(notesHit/notesEncountered)*100,notesHit,notesEncountered,
			#notes+#queuedNotes,noteExists
		)..'\n\nPress Enter, or Space to restart\nEscape or Backspace to return to list',
			function() SceneHandler:load_scene('play',arguments) end,
			function() SceneHandler:load_scene('list') end})
	end
	local function getScoreText()
		return ("Time: %i:%s\nMisses/Ghost/Hit: %i/%i/%i\nCombo: %i\nAccuracy: %i(%i/%i)\nNotes Left: %i/%i"):format(
			math.floor(time/60000),('%2i'):format(math.floor(time/1000%60)):gsub(' ','0'),
			misses,ghosttaps,notesHit,
			combo,
			notesHitAccuracy == 0 and notesEncountered == 0 and 100 or (notesHitAccuracy/notesEncountered)*100,notesHit,notesEncountered,
			#notes+#queuedNotes,noteExists
		)
	end
	local function debugHandle()
		if(not ISDEBUG) then return end
		local isShift =win:key_down('lshift')
		local DOWN = win:key_down("s")
		local UP = win:key_down("w")
		if(songMeta.speed < 0) then
			local _DOWN = DOWN
			DOWN=UP
			UP=_DOWN
		end
		if(DOWN) then
			time = time + (isShift and 500 or 50)
			if(voices) then voices:reset(time*0.001) end 
			inst:reset(time*0.001)
			updateNoteVisuals()
		end
		if(UP) then
			time = time - (isShift and 500 or 50)
			if(voices) then voices:reset(time*0.001) end 
			inst:reset(time*0.001)
			updateNoteVisuals()
		end
	end
	tracker:action(function(scene)
		debugHandle()
		Events:call('update',am.delta_time)
		if paused then 
			if(voices) then voices:reset(time*0.001) end 
			inst:reset(time*0.001)
			if(win:key_pressed("enter")) then -- TODO ADD COUNTDOWN
				paused = false
				inst.volume = options.instVol
				if(voices) then voices.volume = options.voicesVol end
			end
			if(win:key_pressed("escape")) then -- TODO ADD COUNTDOWN
				SceneHandler:load_scene('list')
				return
			end
			if(win:key_pressed("r")) then -- TODO ADD COUNTDOWN
				import.clearCache()
				SceneHandler:reload_scene()
				-- win.scene = am.load_script('play.lua')()(unpack(arguments))
				return
			end
			if(win:key_pressed("o")) then -- TODO ADD COUNTDOWN
				import.clearCache()
				SceneHandler:set_scene("options")
				-- SceneHandler:load_scene('play',arguments)
				-- win.scene = am.load_script('play.lua')()(unpack(arguments))
				return
			end
			txt.text=("PAUSED\n%s\n\nPress enter to unpause\nPress O to open options\nPress R to restart\nPress ESC to go back to list"):format(getScoreText())
			return
		end
		time = time+(am.delta_time*1000)
		if(time > songLength) then
			on_finish()
			return
		end

		local down,just = {},{}
		for i,v in pairs(buttons) do
			local pressed = win:key_pressed(v)
			local isDown = win:key_down(v) or pressed
			just[i] = pressed
			down[i] = isDown
			if(not isDown) then

				noteSprites[i]:strum_stopped()
			end
		end
		local i = 0
		local pressed = {}
		while i < #notes do
			i = i + 1
			local note = notes[i]
			if(note == nil) then break end
			local noteTime = (note.vt or note.t)
			local diff = (time - noteTime)
			local data = note.d[2]
			local diffFloat = diff/140
			local _notep = note.p
			note.p = false
			if(math.abs(diffFloat) < 1 and note.r and (just[data] or _notep and down[data])) then
				note.vt = time
				down[data] = false
				note.p = true
				if(note.endTime - time <= 0) then
					noteGroup:remove(note.s)
					table.remove(notes,i)
					i=i-1
					-- just[data] = nil
					pressed[data] = time
					noteHit(data,diffFloat)
				else
					pressed[data] = time
					noteSprites[data]:hit()
					if(voices) then voices.volume = options.voicesVol end
				end
			elseif(pressed[data] and (math.abs(noteTime-pressed[data]) < 7)) then
				noteGroup:remove(note.s)
				table.remove(notes,i)
				-- notesEncountered = notesEncountered - 1
				-- print(note.d[1],pressed[data])
				i=i-1
			elseif(math.abs(diffFloat) < 1 and not note.r and just[data] ~= false) then
				noteGroup:remove(note.s)
				just[data] = false
				down[data] = false
				pressed[data] = noteTime
				table.remove(notes,i)
				i=i-1
				noteHit(data,diffFloat)
				
			elseif(diffFloat > 1) then
				noteGroup:remove(note.s)
				table.remove(notes,i)
				i=i-1
				noteMiss(data)
			end
		end

		for i,v in pairs(just) do
			if(v and not pressed[i]) then
				ghost(i)
			end
		end
		updateNoteVisuals()
		txt.text=getScoreText()
		if(win:key_pressed("enter")) then
			paused = true
			inst.volume = 0
			if(voices) then voices.volume = 0 end
		end
	end)
	time = -2500

	local introSounds = {
		am.load_audio("assets/sounds/introGo.ogg"),
		am.load_audio("assets/sounds/intro1.ogg"),
		am.load_audio("assets/sounds/intro2.ogg"),
		am.load_audio("assets/sounds/intro3.ogg"),

	}
	scene:child(1):append(startTracker:action(function()
-- debugHandle()
		if paused then 
			if(win:key_pressed("enter")) then -- TODO ADD COUNTDOWN
				paused = false
			end
			if(win:key_pressed("escape")) then -- TODO ADD COUNTDOWN
				SceneHandler:load_scene('list')
				return
			end
			txt.text= ("%i\nPAUSED"):format((-math.floor(time/500))-1)
			return
		end
		if(win:key_pressed("enter")) then
			paused = true
		end

		local lastSecs = -math.floor(time/500)
		time = time+(am.delta_time*1000)
		local secs = -math.floor(time/500)
		for i,v in pairs(buttons) do
			noteSprites[i].color = win:key_down(v) and heldColor or unheldColor
		end
		if(lastSecs ~= secs and introSounds[secs]) then
			startTracker:action('INTRO',am.play(introSounds[secs],false,1,0.5))
		end
		txt.text = ("%i"):format(secs-1)
		updateNoteVisuals()
		if(time > 0) then
			time = 0
			scene:child(1):remove(startTracker)
			scene:child(1):prepend(tracker)
		end
	end))
	return scene
end
return this