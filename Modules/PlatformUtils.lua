local mod = {}
local function execute(str)
	local f = io.popen(str,'r')
	local content =f:read('*a')
	f:close()
	return content
end

function mod.getDirectory(path)
	local ret = {}
	for v in execute(('find %q'):format(path)):gmatch('[^\n]+') do
		ret[#ret+1] = v
	end
	return ret
end



return mod