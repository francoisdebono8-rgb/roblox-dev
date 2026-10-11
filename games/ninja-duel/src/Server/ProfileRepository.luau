-- Single-key development profile persistence. No player listeners/timers.
-- Exclusive leased writer, fenced revisions, serial per-handle saves and fixed
-- idempotent write packets. Failing reads NEVER create a writable default.
local S=require(script.Parent.ProfileSchema)
local Economy=require(script.Parent.CollectionEconomy)
local Repo={};Repo.__index=Repo
function Repo.new(store,cfg,options)
 require(script.Parent.ProgressionDefinitions).validate(cfg)
 options=options or {};assert(store and type(store.update)=="function" and type(store.read)=="function","Store adapter required")
 local owner=options.owner or game:GetService("HttpService"):GenerateGUID(false)
 assert(S.id(owner),"Owner token required")
 return setmetatable({store=store,cfg=cfg,owner=owner,clock=options.clock or os.time,sleep=options.sleep or task.wait,handles={},loading={}},Repo)
end
function Repo:_update(key,transform)
 local reason
 for attempt=1,self.cfg.MaxRetries do
  local ok,result=pcall(function() return self.store:update(key,transform) end)
  if ok then return true,result end;reason=tostring(result)
  if attempt<self.cfg.MaxRetries then self.sleep(math.min(2,.2*2^(attempt-1))) end
 end
 return false,reason
end
local function envelope(raw,cfg)
 if raw==nil then return nil end
 assert(S.serializable(raw) and raw.envelopeVersion==1 and S.integer(raw.revision,cfg.MaxAmount),"Corrupt/future envelope")
 if raw.lease then assert(type(raw.lease)=="table" and S.id(raw.lease.owner) and type(raw.lease.expires)=="number" and raw.lease.expires==raw.lease.expires and math.abs(raw.lease.expires)<1e12,"Invalid lease") end
 local p,reason=S.migrate(raw.profile,cfg);assert(p,reason)
 local result=S.copy(raw);result.profile=p;return result
end
function Repo:load(id)
 if not S.devId(id) or not id:match("^dev_[%w_%-]+$") then return nil,"Development ID required" end
 if self.loading[id] then return nil,"Load busy" end
 if self.handles[id] then return nil,"Already loaded" end
 self.loading[id]=true;local reason
 local ok,value=self:_update("p_"..id,function(raw)
  local current=envelope(raw,self.cfg);local now=self.clock()
  if current and current.profile.id~=id then reason="Identity mismatch";return nil end
  if current and current.lease and current.lease.owner~=self.owner and current.lease.expires>now then reason="Session locked";return nil end
  current=current or {envelopeVersion=1,revision=0,profile=S.new(id,self.cfg)}
  current.revision+=1;current.lease={owner=self.owner,expires=now+self.cfg.LeaseSeconds};return current
 end)
 self.loading[id]=nil
 if not ok or not value then return nil,reason or value or "Load failed" end
 local h={id=id,data=S.copy(value.profile),revision=value.revision,leaseUntil=value.lease.expires,state="Ready",busy=false,writeNumber=0,lastSave=self.clock()}
 self.handles[id]=h;return h
end
function Repo:ready(h)
 if self.handles[h.id]~=h or h.state~="Ready" or h.busy then return false,"Profile not ready / busy" end
 if self.clock()>=h.leaseUntil then h.state="Lost";return false,"Lease expired" end
 return true
end
function Repo:view(h) return S.copy(h.data),h.state end
function Repo:apply(h,sequence,kind,args,nextNumber)
 local ready,reason=self:ready(h);if not ready then return false,reason end
 local ok,data,result,replay=pcall(Economy.apply,h.data,self.cfg,sequence,kind,args,nextNumber)
 if not ok then return false,tostring(data) end
 h.data=data;return true,S.copy(result),replay
end
function Repo:resetTest(h)
 local ready,reason=self:ready(h);if not ready then return false,reason end
 local p=S.new(h.id,self.cfg);p.commandSequence=h.data.commandSequence+1;p.lastCommand={sequence=p.commandSequence,kind="reset",result={reset=true}}
 h.data=p;return true
end
function Repo:save(h,release)
 if self.handles[h.id]~=h or h.busy or h.state=="Closed" or h.state=="Lost" then return false,"Profile unavailable / busy" end
 if self.clock()>=h.leaseUntil then h.state="Lost";return false,"Lease expired" end
 h.busy=true
 if not h.pending then
  local valid,reason=S.validate(h.data,self.cfg);if not valid then h.busy=false;return false,reason end
  h.writeNumber+=1
  h.pending={token=self.owner..":"..h.writeNumber,revision=h.revision,data=S.copy(h.data),release=release==true}
 end
 local packet=h.pending;local reason
 local ok,value=self:_update("p_"..h.id,function(raw)
  local current=envelope(raw,self.cfg);local now=self.clock()
  -- An ambiguous successful write is retried with the SAME snapshot/token.
  if current and current.lastWrite==packet.token and current.revision==packet.revision+1 then return current end
  if not current or current.profile.id~=h.id or current.revision~=packet.revision or not current.lease or current.lease.owner~=self.owner or current.lease.expires<=now then reason="Writer fence / lease lost";return nil end
  current.profile=S.copy(packet.data);current.revision+=1;current.lastWrite=packet.token
  current.lease=if packet.release then nil else {owner=self.owner,expires=now+self.cfg.LeaseSeconds}
  return current
 end)
 h.busy=false
 if not ok then h.state="SaveUncertain";return false,value end
 if not value then h.state="Lost";return false,reason or "Save rejected" end
 h.pending=nil;h.revision=value.revision;h.lastSave=self.clock()
 if packet.release then h.state="Closed";self.handles[h.id]=nil
 else
  if not value.lease or value.lease.owner~=self.owner or value.lease.expires<=self.clock() then h.state="Lost";return false,"Lease lost after commit" end
  h.leaseUntil=value.lease.expires;h.state="Ready"
 end
 if release and not packet.release then return self:save(h,true) end
 return true
end
function Repo:verify(id)
 if not S.devId(id) then return nil,"Development ID required" end
 local ok,value=pcall(function() return self.store:read("p_"..id) end)
 if not ok then return nil,tostring(value) end
 if value==nil then return nil,"Missing saved profile" end
 local valid,record=pcall(envelope,value,self.cfg)
 if not valid then return nil,tostring(record) end
 if record.profile.id~=id then return nil,"Identity mismatch" end
 return record
end
-- Explicit host scheduling; never installed into the current runtime.
function Repo:pulse()
 local failures={}
 for id,h in self.handles do
  if not h.busy and (h.state=="SaveUncertain" or self.clock()-h.lastSave>=self.cfg.SaveInterval) then
   local ok,reason=self:save(h);if not ok then failures[id]=reason end
  end
 end
 return failures
end
function Repo:closeAll()
 local failures={};for id,h in self.handles do local ok,reason=self:save(h,true);if not ok then failures[id]=reason end end;return failures
end
return Repo
