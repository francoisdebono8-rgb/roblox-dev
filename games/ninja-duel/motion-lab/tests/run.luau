local fs=require("@lune/fs");local serde=require("@lune/serde");local roblox=require("@lune/roblox")
local guid=0
local names={};local cache={};local load
load=function(name)
 if cache[name] then return cache[name] end
 local source=fs.readFile("motion-lab/ForgeMotionLab/Modules/"..name..".luau")
 local fn=assert(loadstring(source,name));setfenv(fn,setmetatable({script={Parent=names},require=load,CFrame=roblox.CFrame,Vector3=roblox.Vector3,game={GetService=function(_,service)assert(service=="HttpService");return {JSONDecode=function(_,v)return serde.decode("json",v)end,JSONEncode=function(_,v)return serde.encode("json",v)end,GenerateGUID=function()guid+=1;return "test-guid-"..guid end}end}},{__index=getfenv()}))
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
test("Ninja Duel export uses the existing anatomical 0..3 clip format",function()
 local p=M.copy(lib.presets.Flashstep);p.id="flat";p.bodyLayers.Torso.source="Mirage";p.bodyLayers.RightArm.source="Mirage"
 local bundle=A.bundle(p,lib);local json=A.serialize(bundle);assert(#json<2000000 and bundle.ninjaDuel.clips.Light1 and bundle.ninjaDuel.clips.DashAttack)
 assert(bundle.ninjaDuel.clips.Light1[1].at==0 and math.abs(bundle.ninjaDuel.clips.Light1[25].at-3)<.0001)
 local middle=bundle.ninjaDuel.clips.Light1[11].pose
 local expected=Sampler.anatomy(lib.presets.Mirage,lib.assets.jab,10/24,false)
 assert(middle.ra.raise==expected.ra.raise)
 local decoded=serde.decode("json",json);assert(decoded.ninjaDuel.id=="flat" and not decoded.automaticApply)
 local fn=assert(loadstring("return "..A.toLuau(bundle)));assert(fn().preset.id==p.id)
end)
test("mixed profiles survive JSON import and settings restart with source snapshots",function()
 local C=load("Controller");local settings={};local plugin={GetSetting=function(_,key)return settings[key]end,SetSetting=function(_,key,value)settings[key]=value end}
 local c=C.create(plugin);local source=M.copy(c.library.presets.Mirage);source.id="external_upper";source.name="External upper body";c.library.presets[source.id]=source
 c.preset.bodyLayers.Torso.source=source.id
 local bundle=A.bundle(c.preset,c.library);local json=A.serialize(bundle)
 local fake={FindFirstChild=function()return nil end,IsA=function(_,name)return name=="StringValue"end,Value=json}
 local original=c.library.presets.Mirage.name;c:import(fake);assert(c.library.presets.Mirage.name==original)
 c:save();local id=c.preset.id;local torso=c.preset.bodyLayers.Torso.source
 local reopened=C.create(plugin);assert(reopened.store.custom[id] and reopened.store.custom[torso]);assert(reopened.library.presets[torso].name==source.name)
 reopened:load(id);assert(not reopened.dirty)
end)
test("controller undo redo, sequence and A/B preserve references",function()
 local C=load("Controller");local c=C.create({GetSetting=function()return nil end,SetSetting=function()end})
 c:addClip("jab");c:addClip("cross");c:pinCompare();local original=c.compare.motionDNA.amplitude
 c:edit(function(p)p.motionDNA.amplitude=.5;table.remove(p.sequences[1].orderedClips)end)
 assert(c.compare.motionDNA.amplitude==original and #c.compare.sequences[1].orderedClips==2)
 c:undo();assert(#c:sequence().orderedClips==2 and c.preset.motionDNA.amplitude==original)
 c:redo();assert(#c:sequence().orderedClips==1 and c.preset.motionDNA.amplitude==.5)
 c.library.presets.Mirage.name="Changed source";assert(c.compareLibrary.presets.Mirage.name=="Itachi")
end)
test("locomotion slot overrides and weapon layer affect sampled motion",function()
 local p=M.copy(lib.presets.Flashstep);p.id="overridden";p.locomotionSet.run="idle"
 local a=Sampler.sample(p,lib.assets.run,.3,lib);local b=Sampler.sample(p,lib.assets.idle,.3,lib)
 assert((a.RightHip.Position-b.RightHip.Position).Magnitude<.00001 and (a.RightHip.UpVector-b.RightHip.UpVector).Magnitude<.00001)
 local original=a.Weapon;p.bodyLayers.Weapon.source="Mirage";local mixed=Sampler.sample(p,lib.assets.run,.3,lib)
 assert((original.UpVector-mixed.Weapon.UpVector).Magnitude>.01)
end)
test("invalid authored keys and expression overrides fail before preview",function()
 local p=M.copy(lib.presets.Flashstep);p.clips.Light1.keys[1].pose.ra="not a joint";assert(not M.validate(p))
 p=M.new("invalid","Invalid");p.characterRules.grammarOverrides={Launcher={rootTravel="bad"}};assert(not M.validate(p))
 p=M.new("invalid","Invalid");p.clips.Light1={duration=1,keys={{at=.8,pose={}},{at=.2,pose={}}}};assert(not M.validate(p))
end)
test("malformed saved settings are preserved and never prevent opening",function()
 for _,data in {{version=1,presets={broken=42}},{version=1,presets={broken={id="broken",motionDNA=12}}},{version=1,presets={Flashstep=M.copy(lib.presets.Flashstep)}}}do
  local raw=serde.encode("json",data);local plugin={GetSetting=function()return raw end,SetSetting=function()error("Must not overwrite corruption")end}
  local fresh=Library.new();A.import(load("NinjaSources"),fresh);local store=Store.new(plugin,fresh);assert(not store.writable and store.notice and #fresh.order==8)
 end
 local p=M.new("bad","Bad");p.sequences={12};assert(not M.validate(p))
end)
test("DNA shapes selected source layers without mutating source profiles",function()
 local p=M.copy(lib.presets.Flashstep);p.id="dna_mix";p.bodyLayers.RightArm.source="Mirage"
 local original=Sampler.sample(p,lib.assets.jab,.4,lib);local sourceDNA=lib.presets.Mirage.motionDNA.upperActivity
 p.motionDNA.upperActivity=.5;local tuned=Sampler.sample(p,lib.assets.jab,.4,lib)
 assert((original.Right.UpVector-tuned.Right.UpVector).Magnitude>.1 and lib.presets.Mirage.motionDNA.upperActivity==sourceDNA)
end)
test("template DNA is not applied twice when mixing the same template",function()
 local p=M.copy(lib.presets.gaara);p.id="gaara_mix";local original=Sampler.sample(p,lib.assets.jab,.4,lib)
 p.bodyLayers.RightArm.source="gaara";local same=Sampler.sample(p,lib.assets.jab,.4,lib)
 assert((original.Right.UpVector-same.Right.UpVector).Magnitude<.0001)
 p.motionDNA.amplitude=.7;local changed=Sampler.sample(p,lib.assets.jab,.4,lib);assert((original.Right.UpVector-changed.Right.UpVector).Magnitude>.01)
end)
require("./variants")(load,test,lib)
require("./bilateral")(load,test,lib)
require("./references")(load,test,lib)
require("./compatibility")(load,test,lib)
print("Forge Motion Lab: "..count.." PASS")
