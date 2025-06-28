local animHandler = require('Modules.AnimationHandler')
local mod = {}

function mod.getNote(anim)
	local xml = am.load_string('assets/NOTE_assets.xml')
	local frames = { }
	for tex,x,y,w,h in xml:lower():gmatch('subtexture name="([^"]-'..anim..'[^"]-)" x="(%d+)" y="(%d+)" width="(%d+)" height="(%d+)"') do
		local f = animHandler.frame(tonumber(x),tonumber(y),tonumber(w),tonumber(h))
		f.name = tex
		frames[#frames+1] = f
	end
	print(#frames,anim)
	table.sort(frames, function(a,b) return a.name > b.name end)
	return animHandler.sprite_anims('assets/NOTE_assets.png',{scroll=frames},"scroll",24,true,nil,"center","center")
end

return mod