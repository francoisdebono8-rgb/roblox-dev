-- Server: the ground audit (06/11, user: « vérifie le dégât au sol de toutes
-- les attaques »). Every fighter's strikes (string, heavy, launcher, low
-- heavy, air), jutsu, hand-seal jutsu, awakening and ultimate, cast on a
-- frozen dummy; after each, what the arena kept (Server/WorldReaction: new
-- scars, merged scars, by kind). Background run; result as JSON in workspace
-- attribute NDGround, progress in NDGroundAt. Uses DevHooks' attribute channel.
local FIGHTERS={"Mirage","Copycat","Lion","Leaf","Legion","Sand","GentleFist","Flashstep"}
local Http=game:GetService("HttpService")
local function dev(...)
	local args={...}
	for i,a in args do if typeof(a)=="Vector3" then args[i]={a.X,a.Y,a.Z} end end
	local t0=os.clock()
	while workspace:GetAttribute("NDDevResult")=="pending" and os.clock()-t0<5 do task.wait(.03) end
	workspace:SetAttribute("NDDevResult","pending")
	workspace:SetAttribute("NDDev",Http:JSONEncode({args=args}))
	t0=os.clock()
	repeat task.wait(.03) until workspace:GetAttribute("NDDevResult")~="pending" or os.clock()-t0>8
	local r=workspace:GetAttribute("NDDevResult")
	local ok,dec=pcall(function() return Http:JSONDecode(r) end)
	return if ok then dec else r
end
-- {label, gap, presses (each {action, wait}), opts}
local STRIKES={
	{"String x4",4,{{"Attack",.3},{"Attack",.3},{"Attack",.3},{"Attack",.6}}},
	{"Heavy",4,{{"Heavy",.9}}},
	{"Launcher (2+H)",4,{{"Attack",.3},{"Attack",.3},{"Heavy",.9}}},
	{"Low heavy (3+H)",4,{{"Attack",.3},{"Attack",.3},{"Attack",.3},{"Heavy",.9}}},
	{"Air spike",4,{{"Attack",.3},{"Attack",.3},{"Heavy",.35},{"Pursuit",.35},{"Attack",.25},{"Heavy",1.2}}},
}
local JUTSU={"Technique1","Technique2","Technique3","Technique4","Seal1","Seal2","Seal3","Seal4","Seal5","Awaken","Ultimate"}
local GAP={Technique1=12,Technique2=10,Technique3=10,Technique4=8,Seal1=8,Seal2=10,Seal3=8,Seal4=8,Seal5=6,Awaken=6,Ultimate=6}
local results={}
local function world()
	local w=dev("world")
	if type(w)~="table" then return {scars=0,merged=0} end
	local st=w.stats or {}
	return {scars=st.scars or 0,merged=st.merged or 0,live=w.scars or 0,breaks=st.breaks or 0}
end
local function kinds()
	local out={}
	for _,d in workspace:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("WorldScar") then out[d:GetAttribute("WorldScar")]=(out[d:GetAttribute("WorldScar")] or 0)+1 end
	end
	return out
end
local function diff(a,b)
	local out={}
	for k,v in b do local d=v-(a[k] or 0);if d~=0 then out[k]=d end end
	return out
end
local function prep(gap)
	dev("refill");dev("health","human",400);dev("health","bot",400)
	dev("move","human",Vector3.zero);dev("place",Vector3.new(0,3,gap/2),Vector3.new(0,3,-gap/2))
	task.wait(.45)
end
local function run(A,label,gap,presses,special)
	prep(gap)
	if special=="Awaken" then dev("health","human",30) end
	if special=="Ultimate" then dev("ultimate","human",100) end
	local before,kb=world(),kinds()
	local reasons={}
	for _,p in presses do
		local s=dev("state")
		local r=dev("act","human",p[1],s.bot and s.bot.position)
		table.insert(reasons,p[1]..":"..tostring(type(r)=="table" and (r.ok and "ok" or r.reason) or r))
		task.wait(p[2])
	end
	task.wait(if special=="Ultimate" then 5 else 1.2)
	local after,ka=world(),kinds()
	table.insert(results,{fighter=A,move=label,new=after.scars-before.scars,merged=after.merged-before.merged,kinds=diff(kb,ka),presses=table.concat(reasons," ")})
	workspace:SetAttribute("NDGroundAt",A.." "..label)
	workspace:SetAttribute("NDGround",Http:JSONEncode(results))
end
shared.NdGroundStop=false
task.spawn(function()
	for _,A in FIGHTERS do
		if shared.NdGroundStop then break end
		dev("start",A,if A=="Mirage" then "Copycat" else "Mirage")
		local t0=os.clock()
		repeat task.wait(.25);local r=dev("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>14
		dev("autopilot",false);dev("freezeBot",true);dev("scripted",true)
		for _,s in STRIKES do if shared.NdGroundStop then break end;run(A,s[1],s[2],s[3]) end
		for _,j in JUTSU do if shared.NdGroundStop then break end;run(A,j,GAP[j],{{j,.1}},j) end
	end
	workspace:SetAttribute("NDGroundAt","done")
end)
return "ground audit started"
