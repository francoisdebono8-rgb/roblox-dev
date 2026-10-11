-- Internal facade. Profiles ALWAYS dev_*; default store stays in memory.
-- No client remote or live PlayerAdded binding; bindable is Studio-only.
local S=require(script.Parent.ProfileSchema)
local Repo=require(script.Parent.ProfileRepository)
local Memory=require(script.Parent.DevelopmentProfileStore)
local RNG=require(script.Parent.ProgressionRandom)
local Tools={};Tools.__index=Tools
function Tools.new(cfg,store,options)
 local actual=store or Memory.new()
 return setmetatable({cfg=cfg,store=actual,repo=Repo.new(actual,cfg,options),rng=RNG.new(12345)},Tools)
end
function Tools:handle(id)
 if not S.devId(id) then return nil,"Development ID required" end
 return self.repo.handles[id] or self.repo:load(id)
end
function Tools:run(op,arg)
 arg=arg or {};if type(arg)~="table" or not S.serializable(arg) then return {ok=false,error="Invalid arguments"} end
 if op=="simulate" then
  local ok,value=pcall(function() return require(script.Parent.PackSimulation).run(self.cfg,arg,task and task.wait) end)
  return if ok then {ok=true,report=value} else {ok=false,error=tostring(value)}
 end
 local kinds={give="unlock",remove="revoke",xp="xp",rank="rank",currency="currency",pack="pack",mastery="mastery",select="select"}
 if not kinds[op] and not ({verify=true,dump=true,save=true,reset=true})[op] then return {ok=false,error="Unknown dev profile operation"} end
 local id=arg.profile or "dev_studio"
 if op=="verify" then local record,err=self.repo:verify(id);return {ok=record~=nil,record=record,error=err} end
 local h,reason=self:handle(id);if not h then return {ok=false,error=reason} end
 if op=="dump" then local p,state=self.repo:view(h);return {ok=true,profile=p,state=state,revision=h.revision,leaseUntil=h.leaseUntil} end
 if op=="save" then local ok,err=self.repo:save(h,arg.release==true);return {ok=ok,error=not ok and err or nil} end
 if op=="reset" then local ok,err=self.repo:resetTest(h);return {ok=ok,error=not ok and err or nil} end
 local kind=kinds[op]
 local ok,value,replayed=self.repo:apply(h,arg.sequence or h.data.commandSequence+1,kind,arg,function() return self.rng:next() end)
 return {ok=ok,result=ok and value or nil,error=not ok and value or nil,replayed=replayed==true}
end
return Tools
