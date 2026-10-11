-- Offline CLI loads actual isolated modules. Never opens Studio/DataStoreService.
local H=require("../tests/Harness")
local serde=require("@lune/serde");local fs=require("@lune/fs");local process=require("@lune/process")
local args=process.args;local op=args[1];local options=serde.decode("json",args[2] or "{}")
local S=H.load("Server/ProfileSchema");local cfg=S.copy(H.load("Server/ProgressionConfig"))
local synthetic=options.roster;options.roster=nil
if synthetic then
 assert(S.integer(synthetic,128) and synthetic>=5,"Synthetic roster must be 5..128")
 local n=0;for _ in cfg.Characters do n+=1 end
 for i=n+1,synthetic do
  local id=string.format("Fixture%03d",i);local speed=10+i%5
  cfg.Characters[id]={name="SYNTHETIC "..i,rarity=if i%5==0 then "Epic" else "Rare",unlockFragments=50,stats={Speed={base=speed,growth=.02,cap=speed+1}},rewards={}}
  table.insert(cfg.Packs.Training.entries,{character=id,rarity=cfg.Characters[id].rarity,weight=10,fragments=10})
 end
end
local result
if op=="simulate" then
 result={ok=true,report=H.load("Server/PackSimulation").run(cfg,options)}
elseif op=="bench" then
 local count=options.profiles or 1000;assert(S.integer(count,10000) and count>0,"Profiles budget 1..10000")
 local store=H.load("Server/DevelopmentProfileStore").new()
 local tools=H.load("Server/DevelopmentProfiles").new(cfg,store,{owner="benchmark",sleep=function() end})
 local started=os.clock();local errors={};local records=0
 for i=1,count do
  local id="dev_bench_"..i
  for _,command in {{"give",{character="Mirage"}},{"xp",{character="Mirage",amount=500}},{"currency",{currency="Coins",amount=500}}} do
   command[2].profile=id;local value=tools:run(command[1],command[2]);assert(value.ok,value.error)
  end
  local saved=tools:run("save",{profile=id,release=true});assert(saved.ok,saved.error)
  local record=tools.repo:verify(id);assert(record and record.profile.currencies.Coins==500 and record.profile.characters.Mirage.xp==500);records+=1
 end
 result={ok=true,report={backend="Memory UpdateAsync simulator, not Roblox throughput",profiles=count,verified=records,elapsedSeconds=os.clock()-started,storeCalls=store.calls,rosterSize=synthetic or 5}}
else
 local data={}
 if args[3] and fs.isFile(args[3]) then
  local raw=fs.readFile(args[3]);assert(#raw<=20000000,"Development sandbox too large")
  local saved=serde.decode("json",raw);assert(saved.environment=="development" and saved.formatVersion==1 and type(saved.records)=="table","Not a development sandbox")
  data=saved.records
 end
 local store=H.load("Server/DevelopmentProfileStore").new(data)
 local tools=H.load("Server/DevelopmentProfiles").new(cfg,store,{owner="offline_cli",sleep=function() end})
 result=tools:run(op,options)
 if result.ok then
  local failures=tools.repo:closeAll();assert(next(failures)==nil,"Sandbox save failed")
  if args[4] then fs.writeFile(args[4],serde.encode("json",{environment="development",formatVersion=1,records=store.data})) end
  result.persistence="development sandbox saved and released"
 end
end
print(serde.encode("json",result))
if not result.ok then process.exit(1) end
