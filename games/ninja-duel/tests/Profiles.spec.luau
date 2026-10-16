-- Progression profiles (PROG-001): schema, server-side commands (grant,
-- unlock, saved builds), idempotent command replay and the persistence
-- repository (lease, fence, ambiguous commits) against the in-memory store.
-- The real DataStore adapter stays inert here (no cloud request is made).
local H=require("./Harness")
local S=H.load("Server/ProfileSchema")
local Repo=H.load("Server/ProfileRepository")
local SkillBuilds=H.load("Server/SkillBuilds")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
-- Run a command on a profile at the next sequence; returns profile, result.
local function run(p,kind,args)
 local nextProfile,result=S.apply(p,p.sequence+1,kind,args)
 return nextProfile,result
end
local function refused(p,kind,args,pattern)
 local ok,err=pcall(S.apply,p,p.sequence+1,kind,args)
 assert(not ok,kind.." was accepted")
 assert(string.find(tostring(err),pattern,1,true),tostring(err))
end

test("a new profile is valid and JSON-safe; ids are u_<UserId> or dev_<name>",function()
 local p=S.new("u_123456")
 assert(S.validate(p) and S.serializable(p))
 assert(S.validate(S.new("dev_studio")))
 for _,bad in {"123","player","u_12a","dev_","dev_ bad",string.rep("u_1",30)} do
  assert(not pcall(S.new,bad),"accepted id "..bad)
 end
end)

test("points are granted by the server; unlocking follows prerequisites and spends them",function()
 local p=S.new("dev_unlock")
 p=run(p,"grant",{fighter="Flashstep",amount=20})
 assert(p.fighters.Flashstep.earned==20)
 refused(p,"unlock",{fighter="Flashstep",node="KunaiRecall"},"requires SealInk")
 local result
 p,result=run(p,"unlock",{fighter="Flashstep",node="SealInk"})
 assert(result.free==16,"free points "..tostring(result.free))
 p=run(p,"unlock",{fighter="Flashstep",node="KunaiRecall"})
 assert(S.spent("Flashstep",p.fighters.Flashstep)==14)
 refused(p,"unlock",{fighter="Flashstep",node="KunaiRecall"},"Already unlocked")
 refused(p,"unlock",{fighter="Flashstep",node="StringFlash"},"requires FlashEconomy")
 p=run(p,"unlock",{fighter="Flashstep",node="FlashEconomy"})
 refused(p,"unlock",{fighter="Flashstep",node="StringFlash"},"Not enough skill points")
 refused(p,"unlock",{fighter="Flashstep",node="Nope"},"Unknown node")
 refused(p,"unlock",{fighter="Sand",node="Nope"},"No skill tree")
 refused(p,"grant",{fighter="Flashstep",amount=-5},"Invalid amount")
 refused(p,"grant",{fighter="Flashstep",amount=S.MaxPoints},"Point cap")
 -- Both options of an exclusive choice can be owned; a build picks one.
 p=run(p,"grant",{fighter="Flashstep",amount=40})
 p=run(p,"unlock",{fighter="Flashstep",node="AirSwitchSeal"})
 p=run(p,"unlock",{fighter="Flashstep",node="SpikeAnchor"})
 assert(p.fighters.Flashstep.unlocked.AirSwitchSeal and p.fighters.Flashstep.unlocked.SpikeAnchor)
end)

test("saved builds: only unlocked, consistent builds; select, delete, limit",function()
 local p=S.new("dev_builds")
 p=run(p,"grant",{fighter="Lion",amount=60})
 for _,node in {"DancingLeaf","SharperEyes","SharinganCounter","ShurikenFan","WirePin","WiredFlames"} do p=run(p,"unlock",{fighter="Lion",node=node}) end
 local result
 p,result=run(p,"saveBuild",{fighter="Lion",name="Wall wire",nodes={"WirePin","ShurikenFan","DancingLeaf"}})
 assert(result.cost==24)
 assert(table.concat(p.fighters.Lion.builds["Wall wire"].nodes,",")=="DancingLeaf,ShurikenFan,WirePin","the build was not stored in tree order")
 refused(p,"saveBuild",{fighter="Lion",name="Both",nodes={"ShurikenFan","WirePin","WiredFlames"}},"Exclusive choice")
 refused(p,"saveBuild",{fighter="Lion",name="Locked",nodes={"ChidoriFocus"}},"Node locked")
 refused(p,"saveBuild",{fighter="Lion",name="Orphan",nodes={"SharinganCounter"}},"requires SharperEyes")
 refused(p,"saveBuild",{fighter="Lion",name="",nodes={}},"Invalid build name")
 refused(p,"selectBuild",{fighter="Lion",name="Ghost"},"Unknown build")
 p=run(p,"selectBuild",{fighter="Lion",name="Wall wire"})
 local nodes,unlocked=S.selection(p,"Lion")
 assert(#nodes==3 and unlocked.WiredFlames,"the selection does not give the build and the unlocked set")
 -- The selection is exactly what ranked admission needs.
 assert(SkillBuilds.admit("Fundamentals","Lion",nodes,unlocked),"the selected build was not admitted")
 p=run(p,"deleteBuild",{fighter="Lion",name="Wall wire"})
 assert(p.fighters.Lion.selected==nil and S.selection(p,"Lion")==nil,"deleting the selected build kept it selected")
 for k=1,S.MaxBuilds do p=run(p,"saveBuild",{fighter="Lion",name="B"..k,nodes={"DancingLeaf"}}) end
 refused(p,"saveBuild",{fighter="Lion",name="One more",nodes={}},"Too many builds")
 p=run(p,"saveBuild",{fighter="Lion",name="B1",nodes={}})
 assert(#p.fighters.Lion.builds.B1.nodes==0,"replacing a saved build failed")
end)

test("validation refuses tampered or future profiles instead of repairing them",function()
 local p=S.new("dev_tamper")
 p=run(p,"grant",{fighter="GentleFist",amount=10})
 p=run(p,"unlock",{fighter="GentleFist",node="PrecisePalms"})
 local function broken(mutate,pattern)
  local q=S.copy(p);mutate(q)
  local ok,reason=S.validate(q)
  assert(not ok,"accepted a broken profile ("..pattern..")")
  assert(string.find(reason,pattern,1,true),reason)
 end
 broken(function(q) q.fighters.GentleFist.unlocked.Ghost=true end,"unknown unlocked node")
 broken(function(q) q.fighters.GentleFist.earned=1 end,"more points spent than earned")
 broken(function(q) q.fighters.GentleFist.unlocked.KaitenCancel=true;q.fighters.GentleFist.earned=50;q.fighters.GentleFist.unlocked.PrecisePalms=nil end,"requires PrecisePalms")
 broken(function(q) q.fighters.GentleFist.builds.X={nodes={"PointStep"}} end,"build X")
 broken(function(q) q.fighters.GentleFist.selected="Missing" end,"selected build missing")
 broken(function(q) q.fighters.Sand=S.fighter() end,"No skill tree")
 broken(function(q) q.schemaVersion=2 end,"header")
 broken(function(q) q.fighters.GentleFist.earned=0/0 end,"Unsafe")
 assert(S.migrate({schemaVersion=99})==nil,"a future schema was accepted")
 assert(S.migrate(p),"a valid profile was refused")
end)

test("commands are idempotent: a replayed sequence never applies twice; stale or gapped ones are refused",function()
 local p=S.new("dev_replay")
 local first,result=S.apply(p,1,"grant",{fighter="Mirage",amount=30})
 local again,replayed,flag=S.apply(first,1,"grant",{fighter="Mirage",amount=30})
 assert(flag and again.fighters.Mirage.earned==30 and replayed.earned==30,"the replay granted twice")
 assert(not pcall(S.apply,first,3,"grant",{fighter="Mirage",amount=1}),"a gapped command was accepted")
 assert(not pcall(S.apply,first,1,"unlock",{fighter="Mirage",node="Precision"}),"a stale sequence with another command was accepted")
 assert(not pcall(S.apply,first,2,"teleport",{}),"an unknown command was accepted")
 -- A failing command leaves the original untouched.
 assert(not pcall(S.apply,first,2,"unlock",{fighter="Mirage",node="WallPalm"}))
 assert(first.sequence==1 and first.fighters.Mirage.unlocked.WallPalm==nil,"a failed command leaked")
 assert(result.earned==30)
end)

-- Repository -----------------------------------------------------------------
local now=1000
local function repo(store,owner) return Repo.new(store,{owner=owner,clock=function() return now end,sleep=function() end}) end
local function grant(r,h,n)
 local ok,err=r:apply(h,h.data.sequence+1,"grant",{fighter="Flashstep",amount=n})
 assert(ok,err)
end
test("repository: exclusive writer; release and reload keep points, unlocks and builds",function()
 now=1000
 local store=Repo.memoryStore();local a=repo(store,"A");local b=repo(store,"B")
 local h=a:load("dev_lock");assert(h)
 assert(not b:load("dev_lock"),"two writers held the same profile")
 grant(a,h,20)
 assert(a:apply(h,2,"unlock",{fighter="Flashstep",node="FlashEconomy"}))
 assert(a:apply(h,3,"saveBuild",{fighter="Flashstep",name="Main",nodes={"FlashEconomy"}}))
 assert(a:save(h,true))
 local other=b:load("dev_lock");assert(other,"the released profile could not be taken over")
 local r=other.data.fighters.Flashstep
 assert(r.earned==20 and r.unlocked.FlashEconomy and r.builds.Main and other.data.sequence==3,"fields lost across the save")
 local copy=b:view(other);copy.fighters.Flashstep.earned=999
 assert(other.data.fighters.Flashstep.earned==20,"a view leaked into the handle")
end)
test("repository: a failed or corrupt read never becomes a writable default",function()
 now=1000
 local store=Repo.memoryStore();store.failBefore=9
 local r=repo(store,"A")
 assert(not r:load("dev_failed") and next(r.handles)==nil and next(store.data)==nil,"a failed load created a profile")
 local future=S.new("dev_future");future.schemaVersion=99
 local corrupt=Repo.memoryStore({p_dev_future={envelopeVersion=1,revision=4,profile=future}})
 local r2=repo(corrupt,"A")
 assert(not r2:load("dev_future"),"a future profile was loaded")
 assert(corrupt.data.p_dev_future.profile.schemaVersion==99 and corrupt.data.p_dev_future.revision==4,"the future record was overwritten")
 assert(not r2:load("player_1") and not r2:verify("123"),"a non-profile id was accepted")
end)
test("repository: an ambiguous committed save is retried with the same snapshot (no double grant)",function()
 now=1000
 local store=Repo.memoryStore();local r=repo(store,"A");local h=r:load("dev_ambiguous")
 grant(r,h,25)
 store.repeatTransform=true;store.failAfter=1
 assert(r:save(h),"the retried save failed")
 local record=r:verify(h.id)
 assert(record.profile.fighters.Flashstep.earned==25 and record.profile.sequence==1 and record.revision==2,"the ambiguous save applied twice")
end)
test("repository: save uncertainty blocks mutations; stale writers and revision conflicts are fenced",function()
 now=1000
 local store=Repo.memoryStore();local r=repo(store,"A");local h=r:load("dev_retry")
 grant(r,h,10)
 store.failBefore=3
 assert(not r:save(h) and h.state=="SaveUncertain")
 assert(not r:apply(h,2,"grant",{fighter="Flashstep",amount=5}),"a mutation passed during save uncertainty")
 assert(r:save(h,true) and h.state=="Closed")
 assert(r:verify(h.id).profile.fighters.Flashstep.earned==10)
 -- Lease expiry: a newer owner takes over, the old writer is fenced.
 local a=repo(store,"A");local b=repo(store,"B")
 local old=a:load("dev_fence");grant(a,old,99)
 now+=Repo.Config.LeaseSeconds+1
 local current=b:load("dev_fence");assert(current)
 assert(not a:save(old),"a stale writer saved after losing its lease")
 grant(b,current,7);assert(b:save(current))
 assert(b:verify("dev_fence").profile.fighters.Flashstep.earned==7)
 -- Revision conflict despite the same owner.
 local c=repo(store,"C");local hc=c:load("dev_revision");grant(c,hc,3)
 store.data.p_dev_revision.revision+=1
 assert(not c:save(hc) and hc.state=="Lost","a revision conflict was saved over")
end)
test("repository: pulse renews the lease; closed handles are no longer writable; verify never creates",function()
 now=1000
 local store=Repo.memoryStore();local r=repo(store,"A")
 assert(not r:verify("dev_missing") and next(store.data)==nil,"verify created a profile")
 local h=r:load("dev_pulse")
 now+=Repo.Config.SaveInterval
 assert(next(r:pulse())==nil and h.leaseUntil==now+Repo.Config.LeaseSeconds,"pulse did not renew the lease")
 assert(next(r:closeAll())==nil and h.state=="Closed")
 assert(not r:apply(h,1,"grant",{fighter="Flashstep",amount=1}),"a closed handle was writable")
end)
test("DataStore adapter: disabled by default, never opened outside an explicit flag; keys validated",function()
 local adapter,reason=Repo.dataStore()
 assert(not adapter and reason=="Persistence disabled")
 adapter,reason=Repo.dataStore({enabled=true})
 assert(not adapter and reason=="Live persistence requires live=true","a live server opened the store without live=true")
 assert(Repo.validKey("p_u_123") and Repo.validKey("p_dev_qa") and not Repo.validKey("p_123") and not Repo.validKey("u_123"))
end)

print("NinjaDuel progression profiles: "..passed.." PASS (in-memory store; real DataStore adapter not exercised)")
