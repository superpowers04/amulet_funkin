local mod = {}
local function execute(str)
	local f = io.popen(str,'r')
	local content =f:read('*a')
	f:close()
	return content
end

function mod.getDirectory(path,switches) -- TODO WINDOWS COMPATIBILITY
	local ret = {}
	for v in execute(('find %q %s'):format(path,switches or "")):gmatch('[^\n]+') do
		ret[#ret+1] = v
	end
	return ret
end



return mod