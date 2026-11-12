-- Server Authority trial: run once in Studio, in Edit (Studio MCP
-- execute_luau, datamodel Edit), on the opened ND-SA-essai.rbxlx. Turns the
-- place into a Server Authority place in the documented order (AuthorityMode
-- last, it refuses until the others are on) and reports every property.
-- Nothing here touches a shared place (PLACES/): LAB/repro only.
local out={}
local function set(name,...)
	local candidates={...}
	local last="no candidate"
	for _,value in candidates do
		local ok,err=pcall(function() workspace[name]=value end)
		if ok then table.insert(out,name.."="..tostring(workspace[name]));return true end
		last=tostring(err)
	end
	table.insert(out,name.." FAILED: "..last)
	return false
end
local function enum(enumName,item)
	local ok,value=pcall(function() return (Enum :: any)[enumName][item] end)
	return if ok then value else nil
end
local sp=game:GetService("StarterPlayer")
pcall(function() sp.DevComputerMovementMode=Enum.DevComputerMovementMode.Scriptable end)
pcall(function() sp.DevTouchMovementMode=Enum.DevTouchMovementMode.Scriptable end)
table.insert(out,"StarterPlayer movement="..tostring(sp.DevComputerMovementMode))
-- The prerequisites (booleans in some builds, rollout enums in others).
set("StreamingEnabled",true)
set("SignalBehavior",Enum.SignalBehavior.Deferred)
for _,name in {"NextGenerationReplication","UseFixedSimulation","PlayerScriptsUseInputActionSystem"} do
	local candidates={true}
	for _,e in {enum("RolloutState","Enabled"),enum(name,"Enabled")} do if e then table.insert(candidates,e) end end
	set(name,table.unpack(candidates))
end
-- Last: the authority itself.
set("AuthorityMode",enum("AuthorityMode","Server"))
return table.concat(out," | ")
