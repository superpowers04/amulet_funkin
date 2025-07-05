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
	local translate = am.translate(0,0) ^ node
	local scale = am.scale(1) ^ translate
	local self = am.wrap(scale)
	self.texture = texture
	self.scale=scale
	self.translate=translate
	self.sprite=node
	 -- if true then return node end
	-- node.frames = animations[anim]
	self.animations = animations
	self.halign = halign
	self.valign = valign
	self.origSpec = spec
	self.time = 0
	self.frameTime = (1/(fps or 24))
	self.playing = true
	function self:playAnimIfStopped(name,...)
		return not self.playing and self:playAnim(name,...)
	end
	function self:playAnimIfDifferent(name,names,restart,...)
		local curAnim = self.animName
		if(names) then
			for i,v in pairs(names) do
				if(v == name) then return false end
			end
		end
		if(curAnim == name) then
			if(restart and not self.playing) then
				self.time = 0
				self.playing = true
				return true
			end
			return false
		end
		return self:playAnim(name,...)
	end
	function self:playAnim(name,time,loop,restart)
		local frames= self.animations[name]
		if frames == self.frames then
			self.playing = true
			self.looping = loop
			self.time = 0
			return
		end

		if not frames then 
			if(name) then
				local name = name:lower()
				for i,v in pairs(animations) do
					if(i:lower():match(name)) then
						self.animName = i
						frames = v
						break
					end
				end
			end
		else
			self.animName = name

		end
		if not frames then 
			self.playing = false
			if name == nil then error('NAME IS NIL') end
			print('Invalid animation:' .. tostring(name))
			return false
		end
		self.frames=frames
		self.time = time or 0
		if(#self.frames == 1) then
			self:showFrame(self.frames[1])
			self.looping = false
			self.playing = false
		end
		self.playing = true
		self.looping = loop
		return true
	end
	function self:showFrame(frame)
		local w,h = self.texture.width, self.texture.height
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
		if(self.valign) then
			if(self.valign == "center") then
				offY=-(frame.h*0.5)
			elseif(self.valign == "top") then
				offY=-frame.h
			else
				error(tostring(self.valign) .. ' is not a valid valign')
			end
		end
		if(self.halign and self.halign ~= "left") then
			if(self.halign == "center") then
				offX=-(frame.w*0.5)
			elseif(self.halign == "right") then
				offX=-frame.w
			else
				error(tostring(self.halign) .. ' is not a valid halign')
			end
		end
		self.translate.position2d = vec2(posOffX+offX,posOffY+offY)
		self.sprite.source = spec
	end
	if (not anim or not self:playAnim(anim,0,loop)) and animations then
		for i,v in pairs(animations) do
			self.frames = {v[1]}
			self:showFrame(v[1])
			break
		end
	end

	function self:on_update()
		if(not self.playing) then return end
		local lasttime = self.time
		self.time = self.time + am.delta_time
		local time = (self.time/self.frameTime)
		if not self.looping and (time > #self.frames) then
			self.playing = false; 
			self.time = #self.frames
			return
		end
		self:showFrame(self.frames[math.floor(time%#self.frames)+1])
	end
	self:action(self.on_update)
	return self
end
mod.cache = {}

function mod.fromSparrowAtlas(png,xml,defaultAnim,fps,loop,ignoreCache)
	local newF = mod.frame
	local frames
	if not ignoreCache and mod.cache[xml] then
		frames = table.shallow_copy(mod.cache[xml])
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
		if(not ignoreCache) then mod.cache[xml]=table.shallow_copy(frames) end
	end
	-- table.sort(frames, function(a,b) return a.name > b.name end)
	local spr = mod.sprite_anims(png,frames,defaultAnim,fps or 24,loop,nil,'center','center')
	return spr
end


return mod