-- Studio tooling boundary (Codex 33028b2, ported): the F6 panel's remote and
-- the `tool` bindable op reach DevTools only through this allowlist of
-- operations, argument keys and types. Debug/QA places only (DEBUG_SOURCES).
local Commands={}
Commands.ops={reset=true,character=true,scenario=true,["repeat"]=true,profile=true,report=true,
	dummy=true,refill=true,awaken=true,ko=true,list=true,panel=true,selftest=true}
function Commands.validate(op,arg)
	if type(op)~="string" or not Commands.ops[op] then return false end
	if arg==nil then return true,{} end
	if type(arg)~="table" then return false end
	local out={};local n=0
	for k,v in arg do
		n+=1;if n>5 then return false end
		if k=="first" or k=="second" or k=="name" then
			if type(v)~="string" or #v>32 then return false end
		elseif k=="actor" then
			if v~="human" and v~="bot" then return false end
		elseif k=="enabled" then
			if type(v)~="boolean" then return false end
		else return false end
		out[k]=v
	end
	return true,out
end
return Commands
