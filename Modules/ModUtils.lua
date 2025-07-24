local mod = {}

function mod.initScripts(state, env) -- TODO ADD SANDBOXING
	local scripts = {}

	for i,v in ipairs(PlatformUtils.getDirectory('mods/scripts')) do
		if(v:find('/'..state..'.lua') or v:find('mods/scripts/[^/]*%.lua$')) then
			scripts[#scripts+1] = v
		end
	end

	table.sort(scripts)
	for i,v in ipairs(scripts) do
		local chunk,err = loadfile(v)
		if not chunk then
			
			return false,('Error while parsing %s:\n %s'):format(v,err or "")
		end
		local chunk = setfenv(chunk,setmetatable({state=state,script=v,path=v:match('.+/')},{__index=env}))
		local succ,err = pcall(chunk)
		if not succ then
			return false,('Error while executing %s:\n %s'):format(v,err or "")
		end
		
	end
	print(('Loaded %i scripts'):format(#scripts))
	return true
end

return mod