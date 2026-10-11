local fs=require("@lune/fs");local serde=require("@lune/serde");local roblox=require("@lune/roblox")
local names={};local cache={};local load
load=function(name)
 if cache[name] then return cache[name] end
 local source=fs.readFile("motion-lab/ForgeMotionLab/Modules/"..name..".luau")
 local fn=assert(loadstring(source,name));setfenv(fn,setmetatable({script={Parent=names},require=load,CFrame=roblox.CFrame,Vector3=roblox.Vector3,game={GetService=function(_,service)assert(service=="HttpService");return {JSONDecode=function(_,v)return serde.decode("json",v)end,JSONEncode=function(_,v)return serde.encode("json",v)end,GenerateGUID=function()return "test-guid"end}end}},{__index=getfenv()}))
 cache[name]=fn();return cache[name]
end
for _,p in fs.readDir("motion-lab/ForgeMotionLab/Modules") do names[p:gsub("%.luau$","")]=p:gsub("%.luau$","") end
local M=load("Model");local Library=load("Library");local A=load("NinjaDuelAdapter");local Sampler=load("Sampler");local Store=load("Store")
local lib=Library.new();A.import(load("NinjaSources"),lib)
local count=0
local function test(name,fn)local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name)end
test("actual four authored profiles plus four starting profiles",function()assert(#lib.order==8);for _,id in {"Flashstep","Mirage","GentleFist","Lion"}do assert(lib.presets[id].clips.Light1 and lib.presets[id].stance and lib.presets[id].metadata.sourceType=="ninja-duel")end end)
test("Minato legs Itachi upper Neji head mix is different and persistable",function()
 local p=M.copy(lib.presets.Flashstep);p.id="mixed";p.bodyLayers.Torso.source="Mirage";p.bodyLayers.LeftArm.source="Mirage";p.bodyLayers.RightArm.source="Mirage";p.bodyLayers.Head.source="GentleFist"
 local a=Sampler.sample(p,lib.assets.jab,.4,lib);local minato=Sampler.sample(lib.presets.Flashstep,lib.assets.jab,.4,lib);local itachi=Sampler.sample(lib.presets.Mirage,lib.assets.jab,.4,lib)
 local function same(x,y)return (x.RightVector-y.RightVector).Magnitude<.0001 and (x.UpVector-y.UpVector).Magnitude<.0001 and (x.Position-y.Position).Magnitude<.0001 end
 assert(same(a.Right,itachi.Right) and same(a.RightHip,minato.RightHip) and same(a.Waist,itachi.Waist));assert(not same(a.Right,minato.Right))
 local bundle=A.bundle(p,lib);assert(bundle.sources.Mirage and bundle.sources.GentleFist and not bundle.automaticApply)
end)
test("preset storage reload and failure preserve previous settings",function()
 local settings={};local plugin={GetSetting=function(_,k)return settings[k]end,SetSetting=function(_,k,v)settings[k]=v end}
 local store=Store.new(plugin,lib);local p=M.copy(lib.presets.Flashstep);p.id="saved";p.name="Saved mixed motion";store:save(p)
 local other=Library.new();A.import(load("NinjaSources"),other);local reloaded=Store.new(plugin,other);assert(reloaded.custom.saved.name==p.name)
 plugin.SetSetting=function()error("write failure")end;local before=store.custom.saved.name;p.name="lost";assert(not pcall(store.save,store,p));assert(store.custom.saved.name==before)
end)
test("generation uses editable continuous DNA rather than locked archetypes",function()
 for _,id in {"lee","gaara","bee","shisui"}do local p=Library.propose(lib.presets[id]);assert(#p.sequences[1].orderedClips==3 and p.motionDNA.cadence>0);assert(M.validate(p,lib.presets))end
 local p=M.new("blank","Blank");p.motionDNA.precision=.99;local g=Library.propose(p);assert(g.sequences[1].orderedClips[1].asset=="palm")
end)
test("all blocks sample finite R15 transforms for all eight profiles",function()
 for _,id in lib.order do for _,assetId in lib.assetOrder do for _,t in {0,.25,.5,.75,1}do
  local pose=Sampler.sample(lib.presets[id],lib.assets[assetId],t,lib)
  for _,key in {"Root","Waist","Neck","Right","Left","RightHip","LeftHip"}do assert(typeof(pose[key])=="CFrame" and M.finite(pose[key].Position.X))end
 end end end
end)
test("mirror involution and timing/sequence reorder",function()
 local anatomy=Sampler.anatomy(lib.presets.Flashstep,lib.assets.jab,.4,false);local mirrored=Sampler.mirror(Sampler.mirror(anatomy));assert(mirrored.ra.raise==anatomy.ra.raise and mirrored.root.yaw==anatomy.root.yaw)
 local p=Library.propose(lib.presets.lee);local sequence=p.sequences[1];local first=sequence.orderedClips[1].asset;M.reorder(sequence,1,3);assert(sequence.orderedClips[3].asset==first)
 local pose,index=Sampler.sequence(p,sequence,.2,lib);assert(index==1 and pose.Root)
end)
test("cycles, unknown body source and invalid DNA are rejected",function()
 local p=M.new("bad","Bad");p.bodyLayers.Root.source="unknown";assert(not M.validate(p,lib.presets));p.bodyLayers.Root.source="base";p.motionDNA.cadence=0/0;assert(not M.validate(p))
 local a=M.new("a","A");local b=M.new("b","B");a.bodyLayers.Root.source="b";b.bodyLayers.Root.source="a";assert(not M.validateGraph({a=a,b=b}))
end)
print("Forge Motion Lab: "..count.." PASS")
