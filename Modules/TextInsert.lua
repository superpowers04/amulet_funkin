local mod = {}


function mod.new(placeholder_text)
	local buffer = ""
	local caret = 0
	local caretCharacter = "|"
	local output = ""

	local TEXT = am.text('',nil,"LEFT","TOP")
	local CARETTEXT = am.text(placeholder_text or caretCharacter,nil,"LEFT","TOP")
	local scale = 1

	local self = am.group{CARETTEXT,TEXT}

	-- Callbacks
	function self:onEnter(buffer)
		-- do thing
	end
	function self:onActivate(buffer)
		-- do thing
	end
	function self:onDeactivate(buffer)
		-- do thing
	end

	function self:moveCaret(c,isCtrl)
		if isCtrl then
			if(c > caret) then
				c = buffer:find('%s.-$',0,caret) or #buffer
				print(caret,'+')
			else
				c = buffer:find('%s',caret) or #buffer
				print(caret,'-')
			end
		end
		caret = math.max(math.min(c,#buffer),0)
	end
	function self:insertCharacter(c,position,incrementCaret)
		if not position then position = caret end
		buffer = buffer:sub(0,position).. c ..buffer:sub(position+1)
		position = position + #c
		if incrementCaret then self:moveCaret(position) end
	end
	function self:removeCharacter(c,incrementCaret)
		buffer = buffer:sub(0,c-1)..buffer:sub(c+1)
		if(incrementCaret and caret >= c) then self:moveCaret(caret - 1) end
	end
	self.keyAtlas = { -- uppercase = shift pressed
		equals="=",
		minus="-",
		EQUALS="+",
		MINUS="_",
		leftbracket='[',
		rightbracket=']',
		LEFTBRACKET='{',
		RIGHTBRACKET='}',
		semicolon=';',
		SEMICOLON=':',
		quote='\'',
		QUOTE='"',
		comma=',',
		period='.',
		COMMA='<',
		PERIOD='>',
		slash='/',
		backslash='\\',
		SLASH='?',
		BACKSLASH='|',
		SHIFT1="!",
		SHIFT2="@",
		SHIFT3="#",
		SHIFT4="$",
		SHIFT5="%",
		SHIFT6="^",
		SHIFT7="&",
		SHIFT8="*",
		SHIFT9="(",
		SHIFT0=")",
	}
	self.keybindFunctions = {
		l=function() buffer = "" output = "" caret = 0 end,
		v=function() -- TODO PASTING IMPLEMENTATION
			-- local clip = executeCmd('wl-paste')
			-- insertCharacter(clip:sub(1,1) == '"' or clip:sub(1,1) == "'" and clip or ('%q'):format(clip),caret,true)
		end,
		delete=function() buffer = "" end
	}
	local lastKey = ""
	function self:handleKey(v,isShift,isCtrl)
		if(v == "space") then
			self:insertCharacter(" ",caret,true)
		elseif(v == "backspace") then
			self:removeCharacter(caret,true)
		elseif(v == "escape") then
			self:deactivate(buffer)
		elseif(v == "enter") then
			self:onEnter(buffer)
			self:deactivate(buffer)
		elseif(v == "left") then
			self:moveCaret(caret-1,isCtrl)
		elseif(v == "right") then
			self:moveCaret(caret+1,isCtrl)
		else
			local v = v
			if isShift then 
				if(tonumber(v) ~= nil and tonumber(v) == tonumber(v)) then
					v = 'SHIFT'..v
				else
					v = v:upper()
				end
			end
			v = self.keyAtlas[v] or v
			if(isCtrl) then
				local func = self.keybindFunctions[v]
				if(func) then
					return func(self,buffer)
				end
			elseif(#v == 1) then
				self:insertCharacter(v,caret,true)
				return
			end
		end
	end
	local timerFromLastPress = 0
	local allowRepeat = false
	self:action(function(e)
		if not self.active then return end
		local keys_pressed = win:keys_pressed()
		local keys_down = win:keys_down()
		if(#keys_down == 0) then return end
		local isShift = win:key_down("lshift") or win:key_down("rshift")
		local isCtrl = win:key_down("lctrl") or win:key_down("rctrl")
		timerFromLastPress = timerFromLastPress + am.delta_time
		for i,v in ipairs(keys_pressed) do
			allowRepeat = false
			self:handleKey(v,isShift,isCtrl)
		end
		if(not allowRepeat) then 
			if(timerFromLastPress > 1) then
				allowRepeat = true
				timerFromLastPress = 0
			end
		elseif(timerFromLastPress > 0.1) then
			for i,v in ipairs(keys_down) do
				self:handleKey(v)
			end
			timerFromLastPress = 0
		end
		self:showText()
	end)
	function self:showText()
		self.buffer = buffer
		local caret = caret
		local buffer = buffer
		if(#buffer > 30 and caret > 30) then

			buffer = buffer:sub(caret-30,caret+30)
			CARETTEXT.text = (' '):rep(30)..caretCharacter
		else
			CARETTEXT.text = (' '):rep(caret)..caretCharacter

		end

		TEXT.text = buffer

	end
	function self:deactivate()
		CARETTEXT.text = buffer
		TEXT.text = ""
		self:onDeactivate(buffer)
		self.active = false
	end
	function self:activate()
		self.active = true
		self:showText()
		self:onActivate(buffer)
	end
	self:showText()
	return self

end

return mod