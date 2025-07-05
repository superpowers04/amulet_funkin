local mod = {}




--[[local frame = {
	x=0,y=0,w=32,h=32
}]]
--[[
	All positions are pixels,
	literally just outputs a table bound to 
	{x=x,y=y,w=width,height=height,ox=ox or 0,oy=oy or 0}
]]
function mod.frame(x,y,width,height,ox,oy,ow,oh)
	return {x=x,y=y,w=width,h=height,ox=ox or 0,oy=oy or 0}
end
function mod.playAnim(spr,frames)
	spr.frames = frames
	spr.time = 0
end
function mod.sprite_anim(texture,frames,fps,loop,color, halign, valign)
	return mod.sprite_anims(texture,{def=frames},"def",fps,loop)
end
function mod.sprite_anims(texture,animations,anim,fps,loop,color, halign, valign)
	if(type(texture) == "string") then
		if texture:sub(-4) ~= ".png" then texture=texture..".png" end
		texture = am.texture2d(texture)
	end
	local spec = {
		texture=texture,
		s1 = 0,
		s2 = 1,
		t1 = 0,
		t2 = 1,
		x1 = 0,
		y1 = 0,
		x2 = texture.width,
		y2 = texture.height,
		width=texture.width,
		height=texture.height,
	}
	local node = am.sprite(spec,color, 'left','bottom')
	local ret = am.translate(0,0) ^ node
	 -- if true then return node end
	node.animations = animations
	-- node.frames = animations[anim]
	ret.halign = halign
	ret.valign = valign
	node.origSpec = spec
	node.time = 0
	node.frameTime = (fps/60)*1000
	node.playing = true
	function node:playAnim(name,time)
		local frames= animations[name]

		if not frames and name then 
			local name = name:lower()
			for i,v in pairs(animations) do
				if(i:lower():match(name)) then
					frames = v
					break
				end
			end
		end
		if not frames then 
			self.playing = false
			print('Invalid animation:' .. tostring(name))
			return false
		end
		self.frames=frames
		self.time = time or 0
		if(#self.frames == 1) then
			self:showFrame(self.frames[1])
			self.playing = false
		end
		return true
	end
	function node:showFrame(frame)
		local w,h = texture.width, texture.height
		local spec = self.origSpec
		local top,left = frame.y, frame.x
		local bottom, right = top+frame.h, left+frame.w


		spec.s1 = left/w
		spec.t1 = (h-bottom)/h
		spec.s2 = right/w
		spec.t2 = (h-top)/h
		spec.x1 = left
		spec.y1 = top
		spec.x2 = right
		spec.y2 = bottom
		width=w
		height=h

		local offX,offY = 0,0
		local posOffX,posOffY = -left,-top
		if(ret.valign) then
			if(ret.valign == "center") then
				offY=-(frame.h*0.5)
			elseif(ret.valign == "top") then
				offY=-frame.h
			else
				error(tostring(ret.valign) .. ' is not a valid valign')
			end
		end
		if(ret.halign and ret.halign ~= "left") then
			if(ret.halign == "center") then
				offX=-(frame.w*0.5)
			elseif(ret.halign == "right") then
				offX=-frame.w
			else
				error(tostring(ret.halign) .. ' is not a valid halign')
			end
		end
		ret.position2d = vec2(posOffX+offX,posOffY+offY)

		self.source = spec
	end
	if not node:playAnim(anim) and animations then
		for i,v in pairs(animations) do
			node:showFrame(v[1])
		end
	end

	function node:on_update()
		if(not self.playing) then return end
		local lasttime = self.time
		self.time = self.time + am.delta_time
		local time = (self.time/self.frameTime)
		if not looping and (time > #self.frames) then
			self.playing = false; 
			self.time = #node.frames
			return
		end
		self:showFrame(self.frames[math.floor(time%#self.frames)+1])
	end
	function ret:playAnim(...) return node:playAnim(...) end
	function ret:showFrame(...) return node:playAnim(...) end
	node:action(node.on_update)
	return ret
end
mod.cache = {}

function mod.fromSparrowAtlas(png,xml,defaultAnim,fps,ignoreCache)
	local newF = mod.frame
	local frames
	if not ignoreCache and mod.cache[xml] then
		frames = mod.cache[xml]
	else
		local xml = am.load_string(xml)
		frames = { }
		for tex,frame,x,y,w,h in xml:lower():gmatch('subtexture name="([^"]-)(%d+)" x="(%d+)" y="(%d+)" width="(%d+)" height="(%d+)"') do
			local f = newF(tonumber(x),tonumber(y),tonumber(w),tonumber(h))
			f.name = tex
			if(not frames[tex]) then frames[tex] = {} end
			frames[tex][tonumber(frame)+1] = f
		end
		-- for i,v in pairs(frames) do print(i,#v) end
		if(not ignoreCache) then mod.cache[xml]=frames end
	end
	-- table.sort(frames, function(a,b) return a.name > b.name end)
	local spr = mod.sprite_anims(png,frames,defaultAnim,fps or 24,true,nil,'center','center')
	return spr
end


return mod