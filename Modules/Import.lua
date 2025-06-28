local import 
local pack = table.pack or function(...)
	return {...}
end
local unpack = table.unpack or unpack
import = {
	cache = {},
	fromFile= function(str)
		local f = io.open(str,'r')
		if not f then return nil end
		local contents = f:read('*a')
		f:close()
		return contents
	end,
	import = function(str,a)
		if(str == import) then str = a end
		if(import.cache[str]) then return unpack(import.cache[str]) end
		if type(str) ~= "string" then error('got '..type(str)..' for argument 1(expected string)') end
		local orig = str
		str=str:gsub('%.','/')
		if str:sub(-4) ~= ".lua" then str = str .. ".lua" end
		local contents = (am and am.load_string or import.fromFile)(str)
		if not contents then contents = am.load_string('Modules.'..str) end
		if not contents then error('No such module' .. str) end
		import.cache[str] = pack(load(contents,orig)())
		return unpack(import.cache[str])
	end,
	clearCache = function()
		for i,v in pairs(import.cache) do
			import.cache = {}
			return
		end
	end
}
setmetatable(import,{__index=function(s,k,...) return rawget(s,k) or s.import(k) end,__call=import.import})

return import