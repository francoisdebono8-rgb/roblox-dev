-- Build-time extraction of TRUSTED repository code. Never shipped/executed in plugin.
local fs=require("@lune/fs");local serde=require("@lune/serde")
local H=require("../../tests/Harness")
local source=fs.readFile("src/Client/VelmoraMotionEngine.luau")
assert(source:match("return Motion%s*$"),"Motion source contract changed")
source=source:gsub("return Motion%s*$","return {stances=STANCE,clips=CLIPS,gaits=GAIT,timingFor=timing}")
local fn=assert(loadstring(source,"MotionLabBuildExtraction"))
setfenv(fn,setmetatable({require=H.load,script={Parent={}}},{__index=function(_,k)return H.envBase[k] or getfenv()[k]end}))
local data=fn();data.fighters={};data.attacks={};data.timings={};data.clipInheritance={}
for id,clips in data.clips do
 local parent=getmetatable(clips) and getmetatable(clips).__index
 for parentId,parentClips in data.clips do if parent==parentClips then data.clipInheritance[id]=parentId end end
end
local function namesFor(id,seen)
 seen=seen or {};assert(not seen[id],"Cyclic trusted clip inheritance");seen[id]=true
 local names={};local parent=data.clipInheritance[id]
 if parent then names=namesFor(parent,seen) end
 for name in data.clips[id] do names[name]=true end
 return names
end
for id,clips in data.clips do
 data.timings[id]={};for name in namesFor(id) do local startup,active,recovery=data.timingFor(name,id);data.timings[id][name]={startup=startup,active=active,recovery=recovery} end
end
data.timingFor=nil
for id,f in H.load("Shared/Fighters") do data.fighters[id]={name=f.Name,attackProfile=f.AttackProfile} end
for id,a in H.load("Shared/Attacks") do data.attacks[id]={startup=a.startup,active=a.active,recovery=a.recovery} end
fs.writeFile("motion-lab/ForgeMotionLab/Modules/NinjaSources.luau",'-- Generated from current Ninja Duel definitions; data only.\nreturn game:GetService("HttpService"):JSONDecode([==[\n'..serde.encode("json",data)..'\n]==])\n')
print("Extracted authored stances, clips, gaits and timing definitions")
