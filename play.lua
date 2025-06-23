return function(chart)
	buttons = {'d','f','j','k'}


	local PWD = os.getenv('PWD')
	if(chart:sub(0,#PWD) == PWD) then
		chart = chart:sub(#PWD)
	end
	local songMeta = {
		songNotes = {
			
		},
		scale = 10,
		speed = 1,
		voicesVol = 0.5,
		instVol = 0.4,
	}


	if not chart then 
		print('no bitches')
		return am.text('NO CHART')
	end
	local scene = am.group()
	local songNotes = songMeta.songNotes
	do -- SONG PARSING
		local str = am.parse_json(am.load_string(chart))
		songMeta.bpm = str.song.bpm
		local bpm = songMeta.bpm
		local crochet = ((60 / bpm) * 1000)
		local stepCrochet = crochet / 4
		for i,SECTION in ipairs(str.song.notes) do
			if(SECTION.changeBPM) then
				bpm = math.abs(SECTION.bpm)
				crochet = ((60 / bpm) * 1000)
				stepCrochet = crochet / 4
			end
			for nid,note in ipairs(SECTION.sectionNotes) do
				note[2]=(note[2]%4)+1
				-- ((SECTION.mustHitSection and note[2] or (note[2]+4))%8)+1

				if(note[2] < 5) then
					note[3]= note[3] * stepCrochet
					songNotes[#songNotes+1] = note
				end
			end
		end
	end

	inst = am.track(am.load_audio(chart:gsub('[^/]+$','').."Inst.ogg"),false,1,songMeta.instVol)
	pcall(function()
		voices = am.track(am.load_audio(chart:gsub('[^/]+$','').."Voices.ogg"),false,1,songMeta.voicesVol)
	end)


	noteSprites = { am.sprite([[
	.mm
	mm.
	.mm]]), am.sprite([[
	b.b
	bbb
	.b.]]), am.sprite([[
	.g.
	ggg
	g.g]]), am.sprite([[
	rr.
	.rr
	rr.]]),
	}
	arrowSprites = { am.sprite([[
	.MM
	MMM
	.MM]]), am.sprite([[
	BBB
	BBB
	.B.]]), am.sprite([[
	.G.
	GGG
	GGG]]), am.sprite([[
	RR.
	RRR
	RR.]]),
	}

	local lerp = function(a, b, t)
		return a + (b - a) * t
	end

	noteGroup = am.group()
	strumGroup = am.group()
	strumTransforms = {}
	notes = {}
	pressed = {false,false,false,false}
	misses = 0
	combo = 0
	ghosttaps = 0
	notesHit = 0
	notesEncountered=0
	heldColor,unheldColor=vec4(1,1,1,1),vec4(0.6,0.6,0.6,1)

	strumTransformAction = function(t) 
		t.y = lerp(t.y,1,0.2)
		t.x = lerp(t.x,1,0.2)
		t.z = lerp(t.z,1,0.2)
	end
	-- strumSpriteAction = function(t) 
	-- 	t = t.color
	-- 	t.y = lerp(t.y,1,0.2)--;t.y=t.x;
	-- end
	for i,N in pairs(noteSprites) do
		-- N:action(strumSpriteAction)
		local transform = am.translate(((10*i)*songMeta.scale),10) ^ am.scale(songMeta.scale) 
		strumGroup:append(am.scale(1):action(strumTransformAction) ^ transform ^ N)
		local transform = am.translate(((10*i)*songMeta.scale),10) ^ am.scale(songMeta.scale) 
		strumTransforms[i] = transform
	end
	for i,N in pairs(songMeta.songNotes) do
		if(N[2] < 5) then
			local SPR = strumTransforms[N[2]] ^ arrowSprites[N[2]]
			local transform = am.translate(0,0) ^ SPR
			local NOTE = {d=N,s=transform}
			noteGroup:append(transform)
			if(N[3] ~= 0) then
				NOTE.r = am.rect(0,0,SPR.width,N[3])
				SPR:append(NOTE.r)
			end
			notes[#notes+1] = NOTE
		end
	end

	noteExists = #notes

	txt = am.text('');
	scene = am.translate(-200,200) ^ am.group{
		strumGroup,
		noteGroup,
	}

	local tracker = am.translate(-10,-40) ^ txt

	tracker:action(am.play(inst))
	if(voices) then tracker:action(am.play(voices)) end
	missSound = am.sfxr_synth({})
	ghostSound = am.sfxr_synth({})
	local time = 0

	function noteMiss(id)
		notesEncountered=notesEncountered+1
		misses = misses + 1
		combo = 0
		scene:action("MISS",am.play(missSound,false,0.75 + ((id/4)*0.5)),0.5)
		-- strumGroup:child(id).y = 0.8
		strumGroup:child(id).y = 1.05
		if(voices) then voices.volume = 0 end
	end
	function ghost(id)
		ghosttaps = ghosttaps + 1
		scene:action("Ghost",am.play(ghostSound,false,0.75 + ((id/4)*0.2)),0.5)
		-- strumGroup:child(id).y = 0.8
		strumGroup:child(id).y = 1.1
	end
	function noteHit(id,diff)
		notesEncountered=notesEncountered+1
		combo = combo + 1
		local close = (1 - math.abs(diff));
		notesHit = notesHit + close
		-- strumGroup:child(id).y = 1 + (close*0.3)
		strumGroup:child(id).y = 1 - (close*0.1)
		if(voices) then voices.volume = songMeta.voicesVol end

	end

	function updateNoteVisuals()
		for i, note in pairs(notes) do
			local d = note.d[2]
			local transform = note.s;
			local diff = (time - note.d[1]);
			transform.y = (diff * songMeta.speed)
			transform.hidden = diff > 4000
			if(note.r) then
				note.r.y2 = (note.d[3] * songMeta.speed)
			end
		end
	end


	tracker:action(function(scene)
		if paused then 
			if(win:key_pressed("enter")) then -- TODO ADD COUNTDOWN
				paused = false
				if(voices) then voices:reset(time*0.001) end 
				inst:reset(time*0.001)
			end
			if(win:key_pressed("escape")) then -- TODO ADD COUNTDOWN
				win.scene = require('list')
				return
			end
			txt.text=("PAUSED\nTime: %i\nMisses/Ghost: %i/%i\nCombo: %i\nAccuracy: %i\nNotes Left: %i/%i"):format(time,misses,ghosttaps,combo,(notesHit/notesEncountered)*100,#notes,noteExists)
			return
		end
		time = time+(am.delta_time*1000)
		txt.text=("Time: %i\nMisses/Ghost: %i/%i\nCombo: %i\nAccuracy: %i\nNotes Left: %i/%i"):format(time,misses,ghosttaps,combo,(notesHit/notesEncountered)*100,#notes,noteExists)
		if(win:key_pressed("enter")) then
			paused = true
		end


		local down,just = {},{}
		for i,v in pairs(buttons) do
			just[i] = win:key_pressed(v)
			down[i] = win:key_down(v)
			noteSprites[i].color = down[i] and heldColor or unheldColor
		end
		local i = 0
		while i < #notes do
			i = i + 1
			local note = notes[i]
			if(note == nil) then break end
			local diff = (time - note.d[1]) / 140
			local data = note.d[2]
			if(math.abs(diff) < 1 and just[data]) then
				noteGroup:remove(note.s)
				just[data] = false
				table.remove(notes,i)
				i=i-1
				noteHit(data,diff)
			elseif(diff > 1) then
				noteGroup:remove(note.s)
				table.remove(notes,i)
				i=i-1
				noteMiss(data)
			end
		end

		for i,v in pairs(just) do
			if(v) then
				ghost(i)
			end
		end
		updateNoteVisuals()
	end)
	local startTracker = am.text('')
	time = -2500

	local introSounds = {
		am.load_audio("assets/sounds/introGo.ogg"),
		am.load_audio("assets/sounds/intro1.ogg"),
		am.load_audio("assets/sounds/intro2.ogg"),
		am.load_audio("assets/sounds/intro3.ogg"),

	}
	scene:child(1):append(startTracker:action(function()
		if paused then 
			if(win:key_pressed("enter")) then -- TODO ADD COUNTDOWN
				paused = false
			end
			if(win:key_pressed("escape")) then -- TODO ADD COUNTDOWN
				win.scene = require('list')
				return
			end
			startTracker.text= ("%i\nPAUSED"):format((-math.floor(time/500))-1)
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
		startTracker.text = ("%i"):format(secs-1)
		updateNoteVisuals()
		if(time > 0) then
			time = 0
			scene:child(1):remove(startTracker)
			scene:child(1):prepend(tracker)
		end
	end))
	return scene
end