local animHandler = require('Modules.AnimationHandler')
local mod = {}
local noteTypes = {
	['left']={
		hit='left confirm',
		press='left press',
		strum='arrowLEFT',
		scroll='purple',
		hold_piece='purple hold piece',
		hold_end='purple hold end',
	},
	['down']={
		hit='down confirm',
		press='down press',
		strum='arrowDOWN',
		scroll='blue',
		hold_piece='blue hold piece',
		hold_end='blue hold end',
	},
	['up']={
		hit='up confirm',
		press='up press',
		strum='arrowUP',
		scroll='green',
		hold_piece='green hold piece',
		hold_end='green hold end',
	},
	['right']={
		hit='right confirm',
		press='right press',
		strum='arrowRIGHT',
		scroll='red',
		hold_piece='red hold piece',
		hold_end='red hold end',
	}
}

function mod.getNote(type,anim)

	local noteType = noteTypes[type] or type
	local e = animHandler.fromSparrowAtlas('assets/NOTE_assets.png','assets/NOTE_assets.xml',noteType[anim])
	e.noteType = noteType
	for i,v in pairs(noteType) do
		e[i] = function(self,...)
			self:playAnim(v,...)
			return self
		end
		e[i.."_stopped"] = function(self,...)
			self:playAnimIfStopped(v,...)
			return self
		end
		e[i..'_diff'] = function(self,anims,...)
			self:playAnimIfDifferent(v,anims,true,...)
			return self
		end
	end
	return e
end
local noteIndexes={
	time=1,
	data=2,
	sustain=3,
	type=4
}
mod.note_mt={
	noteIndexes=noteIndexes,
	__index = function(s,k)
		return rawget(s,k) or rawget(a,noteIndexes[k])
	end,
	__newindex = function(s,k,v)
		rawset(s,noteIndexes[k] or k,v)
	end
}
function mod.newNote(t)
	return setmetatable(t,mod.note_mt)
end

return mod