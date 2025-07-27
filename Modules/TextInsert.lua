local mod = {}


function mod.new()
	local TEXT = am.text('',nil,"LEFT","TOP")
	local CARETTEXT = am.text('|',nil,"LEFT","TOP")
	local scale = 1

	ret =am.group{CARETTEXT,TEXT}

	local buffer = ""
	local caret = 1
	local caretCharacter = "_"
	local output = ""
	function ret.onEnter(buffer)
		-- do thing
	end
	function print(...)
		output = output .. "\n"
		local tbl = {...}
		for i,v in pairs(tbl) do tbl[i]=tostring(v) end
		output = output..table.concat(tbl,'\t')
	end
	local function moveCaret(c,isCtrl)
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
	local function insertCharacter(c,position,incrementCaret)
		if not position then position = caret end
		buffer = buffer:sub(0,position).. c ..buffer:sub(position+1)
		position = position + #c
		if incrementCaret then moveCaret(position) end
	end
	local function removeCharacter(c,incrementCaret)
		buffer = buffer:sub(0,c-1)..buffer:sub(c+1)
		if(incrementCaret and caret >= c) then moveCaret(caret - 1) end
	end
	ret.keyAtlas = { -- uppercase = shift pressed
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
	ret.keybindFunctions = {
		l=function() buffer = "" output = "" caret = 0 end,
		v=function() -- TODO PASTING IMPLEMENTATION
			-- local clip = executeCmd('wl-paste')
			-- insertCharacter(clip:sub(1,1) == '"' or clip:sub(1,1) == "'" and clip or ('%q'):format(clip),caret,true)
		end,
		delete=function() buffer = "" end
	}
	local lastKey = ""
	function ret.handleKey(v,isShift,isCtrl)
		if(v == "space") then
			insertCharacter(" ",caret,true)
		elseif(v == "backspace") then
			removeCharacter(caret,true)
		elseif(v == "escape") then
			ret.deactivate()
		elseif(v == "enter") then
			ret.onEnter(buffer)
		elseif(v == "left") then
			moveCaret(caret-1,isCtrl)
		elseif(v == "right") then
			moveCaret(caret+1,isCtrl)
		else
			local v = v
			if isShift then 
				if(tonumber(v) ~= nil and tonumber(v) == tonumber(v)) then
					v = 'SHIFT'..v
				else
					v = v:upper()
				end
			end
			v = ret.keyAtlas[v] or v
			if(isCtrl) then
				local func = ret.keybindFunctions[v]
				if(func) then
					return func()
				end
			elseif(#v == 1) then
				insertCharacter(v,caret,true)
				return
			end
		end
	end
	local timerFromLastPress = 0
	local allowRepeat = false
	win.scene:action(function(e)
		if not ret.active then return end
		local keys_pressed = win:keys_pressed()
		local keys_down = win:keys_down()
		if(#keys_down == 0) then return end
		local isShift = win:key_down("lshift") or win:key_down("rshift")
		local isCtrl = win:key_down("lctrl") or win:key_down("rctrl")
		timerFromLastPress = timerFromLastPress + am.delta_time
		for i,v in ipairs(keys_pressed) do
			allowRepeat = false
			ret.handleKey(v,isShift,isCtrl)
		end
		if(not allowRepeat) then 
			if(timerFromLastPress > 1) then
				allowRepeat = true
				timerFromLastPress = 0
			end
		elseif(timerFromLastPress > 0.1) then
			for i,v in ipairs(keys_down) do
				ret.handleKey(v)
			end
			timerFromLastPress = 0
		end
		local caret = caret
		local buffer = buffer
		if(#buffer > 30 and caret > 30) then

			buffer = buffer:sub(caret-30,caret+30)
			CARETTEXT.text = (' '):rep(30)..caretCharacter
		else
			CARETTEXT.text = (' '):rep(caret)..caretCharacter

		end

		TEXT.text = buffer
	end)
	function ret.deactivate()
		TEXT.text = buffer
		ret.active = false
	end
	return ret

end

return mod