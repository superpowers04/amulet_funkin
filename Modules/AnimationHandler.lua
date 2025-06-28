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
function mod.sprite_anim(texture,frames,fps,loop)
	return mod.sprite_anims(texture,{def=frames},"def",fps,loop)
end
function mod.sprite_anims(texture,animations,anim,fps,loop)
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
	local node = am.sprite(spec)
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
		spec.s1 = frame.x/w -- left
		spec.t1 = frame.y/h --- bottom
		spec.t2 = (frame.x+frame.h)/h -- up
		spec.s2 = (frame.y+frame.w)/w -- right
		spec.x1 = 0
		spec.x2 = frame.h
		spec.y1 = 0
		spec.y2 = frame.w
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
	return node:action(node.on_update)
end
return mod