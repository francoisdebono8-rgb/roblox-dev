-- Progression profile persistence (PROG-001). One key per profile; an
-- exclusive leased writer (session lock) with fenced revisions; every write is
-- a fixed snapshot with an idempotency token, so an ambiguous UpdateAsync is
-- retried without applying twice; a failed or corrupt read never becomes a
-- writable default. Lease/fence/retry logic from Codex's foundation (29a9ec1),
-- rebased on the skill profile (ProfileSchema), without economy.
--
-- Store adapter contract: update(key, transform) (UpdateAsync semantics: the
-- transform may run more than once and returns nil to abort) and read(key).
-- Repo.memoryStore() is the deterministic test double; Repo.dataStore() is the
-- real Roblox adapter, never created implicitly. No game script loads profiles
-- yet (player lifecycle, BindToClose and budgets are the next step).
local S=require(script.Parent.ProfileSchema)
local Repo={};Repo.__index=Repo
Repo.Config={LeaseSeconds=120,SaveInterval=30,MaxRetries=3,
	StoreName="NinjaDuel_Progression",DevStoreName="NinjaDuel_Progression_DEV",Scope="skills_v1"}
function Repo.new(store,options)
	options=options or {}
	assert(store and type(store.update)=="function" and type(store.read)=="function","Store adapter required")
	local owner=options.owner or game:GetService("HttpService"):GenerateGUID(false)
	assert(S.id(owner),"Owner token required")
	return setmetatable({store=store,config=options.config or Repo.Config,owner=owner,clock=options.clock or os.time,
		sleep=options.sleep or task.wait,handles={},loading={}},Repo)
end
local function keyOf(id) return "p_"..id end
function Repo:_update(key,transform)
	local reason
	for attempt=1,self.config.MaxRetries do
		local ok,result=pcall(function() return self.store:update(key,transform) end)
		if ok then return true,result end
		reason=tostring(result)
		if attempt<self.config.MaxRetries then self.sleep(math.min(2,.2*2^(attempt-1))) end
	end
	return false,reason
end
-- A stored record: {envelopeVersion, revision, lease={owner,expires}, profile, lastWrite}.
local function envelope(raw)
	if raw==nil then return nil end
	assert(S.serializable(raw) and type(raw)=="table" and raw.envelopeVersion==1 and S.integer(raw.revision),"Corrupt/future envelope")
	if raw.lease then
		assert(type(raw.lease)=="table" and S.id(raw.lease.owner) and type(raw.lease.expires)=="number" and raw.lease.expires==raw.lease.expires and math.abs(raw.lease.expires)<1e12,"Invalid lease")
	end
	local p,reason=S.migrate(raw.profile)
	assert(p,reason)
	local result=S.copy(raw)
	result.profile=p
	return result
end
-- Acquire the lease and the profile (a missing profile starts fresh; a corrupt,
-- foreign or locked one is refused and left untouched).
function Repo:load(id)
	if not S.profileId(id) then return nil,"Profile id required" end
	if self.loading[id] then return nil,"Load busy" end
	if self.handles[id] then return nil,"Already loaded" end
	self.loading[id]=true
	local reason
	local ok,value=self:_update(keyOf(id),function(raw)
		local okRead,current=pcall(envelope,raw)
		if not okRead then reason=tostring(current);return nil end
		local now=self.clock()
		if current and current.profile.id~=id then reason="Identity mismatch";return nil end
		if current and current.lease and current.lease.owner~=self.owner and current.lease.expires>now then reason="Session locked";return nil end
		current=current or {envelopeVersion=1,revision=0,profile=S.new(id)}
		current.revision+=1
		current.lease={owner=self.owner,expires=now+self.config.LeaseSeconds}
		return current
	end)
	self.loading[id]=nil
	if not ok or not value then return nil,reason or value or "Load failed" end
	local h={id=id,data=S.copy(value.profile),revision=value.revision,leaseUntil=value.lease.expires,state="Ready",busy=false,writeNumber=0,lastSave=self.clock()}
	self.handles[id]=h
	return h
end
function Repo:ready(h)
	if self.handles[h.id]~=h or h.state~="Ready" or h.busy then return false,"Profile not ready / busy" end
	if self.clock()>=h.leaseUntil then h.state="Lost";return false,"Lease expired" end
	return true
end
function Repo:view(h) return S.copy(h.data),h.state end
-- Run a ProfileSchema command on the loaded profile (in memory until saved).
function Repo:apply(h,sequence,kind,args)
	local ready,reason=self:ready(h)
	if not ready then return false,reason end
	local ok,data,result,replayed=pcall(S.apply,h.data,sequence,kind,args)
	if not ok then return false,tostring(data) end
	h.data=data
	return true,S.copy(result),replayed
end
function Repo:save(h,release)
	if self.handles[h.id]~=h or h.busy or h.state=="Closed" or h.state=="Lost" then return false,"Profile unavailable / busy" end
	if self.clock()>=h.leaseUntil then h.state="Lost";return false,"Lease expired" end
	h.busy=true
	if not h.pending then
		local valid,reason=S.validate(h.data)
		if not valid then h.busy=false;return false,reason end
		h.writeNumber+=1
		h.pending={token=self.owner..":"..h.writeNumber,revision=h.revision,data=S.copy(h.data),release=release==true}
	end
	local packet=h.pending
	local reason
	local ok,value=self:_update(keyOf(h.id),function(raw)
		local okRead,current=pcall(envelope,raw)
		if not okRead then reason=tostring(current);return nil end
		local now=self.clock()
		-- An ambiguous write that did commit is recognised by its token.
		if current and current.lastWrite==packet.token and current.revision==packet.revision+1 then return current end
		if not current or current.profile.id~=h.id or current.revision~=packet.revision or not current.lease
			or current.lease.owner~=self.owner or current.lease.expires<=now then reason="Writer fence / lease lost";return nil end
		current.profile=S.copy(packet.data);current.revision+=1;current.lastWrite=packet.token
		current.lease=if packet.release then nil else {owner=self.owner,expires=now+self.config.LeaseSeconds}
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
-- Read-only check of a stored profile; never creates one.
function Repo:verify(id)
	if not S.profileId(id) then return nil,"Profile id required" end
	local ok,value=pcall(function() return self.store:read(keyOf(id)) end)
	if not ok then return nil,tostring(value) end
	if value==nil then return nil,"Missing saved profile" end
	local valid,record=pcall(envelope,value)
	if not valid then return nil,tostring(record) end
	if record.profile.id~=id then return nil,"Identity mismatch" end
	return record
end
-- Explicit host scheduling (periodic save + lease renewal); never installed by itself.
function Repo:pulse()
	local failures={}
	for id,h in self.handles do
		if not h.busy and (h.state=="SaveUncertain" or self.clock()-h.lastSave>=self.config.SaveInterval) then
			local ok,reason=self:save(h)
			if not ok then failures[id]=reason end
		end
	end
	return failures
end
function Repo:closeAll()
	local failures={}
	for id,h in self.handles do
		local ok,reason=self:save(h,true)
		if not ok then failures[id]=reason end
	end
	return failures
end

-- In-memory store: deterministic UpdateAsync stand-in with fault injection
-- (failBefore: unavailable; failAfter: commits then errors; repeatTransform:
-- runs the transform twice). Copies emulate the serialization boundary.
local Memory={};Memory.__index=Memory
function Repo.memoryStore(data)
	return setmetatable({data=S.copy(data or {}),failBefore=0,failAfter=0,repeatTransform=false,calls=0},Memory)
end
function Memory:update(key,transform)
	self.calls+=1
	if self.failBefore>0 then self.failBefore-=1;error("Simulated store unavailable") end
	local value=transform(S.copy(self.data[key]))
	if self.repeatTransform then value=transform(S.copy(self.data[key])) end
	if value==nil then return nil end
	assert(S.serializable(value),"Invalid serialized record")
	self.data[key]=S.copy(value)
	if self.failAfter>0 then self.failAfter-=1;error("Simulated ambiguous commit") end
	return S.copy(value)
end
function Memory:read(key)
	if self.failBefore>0 then self.failBefore-=1;error("Simulated read unavailable") end
	return S.copy(self.data[key])
end

-- Real Roblox DataStore adapter, guarded: never created unless enabled=true.
-- In Studio it only opens the DEV store (Studio sessions can never touch live
-- data); on a live server it also requires live=true. Keys are validated.
local DataStore={};DataStore.__index=DataStore
function Repo.validKey(key)
	return type(key)=="string" and #key<=50 and (string.match(key,"^p_u_%d+$")~=nil or string.match(key,"^p_dev_[%w_%-]+$")~=nil)
end
function Repo.dataStore(options)
	options=options or {}
	if options.enabled~=true then return nil,"Persistence disabled" end
	local name
	if game:GetService("RunService"):IsStudio() then name=Repo.Config.DevStoreName
	elseif options.live==true then name=Repo.Config.StoreName
	else return nil,"Live persistence requires live=true" end
	local store=game:GetService("DataStoreService"):GetDataStore(name,Repo.Config.Scope)
	return setmetatable({store=store,name=name},DataStore)
end
function DataStore:update(key,transform)
	assert(Repo.validKey(key),"Invalid profile key")
	return self.store:UpdateAsync(key,transform)
end
function DataStore:read(key)
	assert(Repo.validKey(key),"Invalid profile key")
	local options=Instance.new("DataStoreGetOptions");options.UseCache=false
	return self.store:GetAsync(key,options)
end
return Repo
