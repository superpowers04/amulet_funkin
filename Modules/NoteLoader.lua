local animHandler = require('Modules.AnimationHandler')
local mod = {}


function mod.getNote(anim)
	return animHandler.fromSparrowAtlas('assets/NOTE_assets.png','assets/NOTE_assets.xml',anim)
end

return mod