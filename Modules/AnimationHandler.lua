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
	local node = am.sprite(spec,color, halign, valign)
	local ret = am.translate(0,0) ^ node
	 -- if true then return node end
	node.animations = animations
	node.frames = animations[anim]
	node.origSpec = spec
	node.time = 0
	node.frameTime = (fps/60)*1000
	node.playing = true
	function node:playAnim(name,time)
		if true then return end
		self.frames = animations[name]
		self.time = time or 0
		if(#self.frames == 1) then
			self:showFrame(self.frames[1])
			print(table.tostring(self.frames))
			print(self.width,self.height)
			self.playing = false
		end

	end
	function node:showFrame(frame)
		local w,h = texture.width, texture.height
		local spec = self.origSpec
		local top = (frame.y)
		local bottom = (frame.y+frame.h)
		local left = (frame.x)
		local right = (frame.x+frame.w)


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
		-- ret.position2d = vec2(-left,-top)
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
		-- spec.x1 = frame.w*-0.5
		-- spec.x2 = frame.w*0.5
		-- spec.y1 = frame.y*-0.5
		-- spec.y2 = frame.y*0.5

		-- spec.x2 = frame.w
		-- spec.y1 = frame.y
		-- spec.y2 = frame.h
		-- print(table.tostring(spec))

		self.source = spec
	end
	node:playAnim(anim)
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
return mod