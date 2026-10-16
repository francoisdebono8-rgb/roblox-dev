-- Bounded, opt-in measurements for the Studio dev tools (Codex 33028b2, ported).
-- No instances, remotes or gameplay policy. Debug/QA places only: build.py
-- lists this module in DEBUG_SOURCES, so the normal build never contains it.
local MAX_LABELS=128
local Metrics={};Metrics.__index=Metrics
function Metrics.new(clock)
	return setmetatable({clock=clock or os.clock,enabled=false,stats={},counters={},events={},restores={},started=0,labels=0},Metrics)
end
function Metrics:start()
	self.stats={};self.counters={};self.events={};self.labels=0;self.started=self.clock();self.ended=nil;self.enabled=true
end
function Metrics:sample(name,value)
	if not self.enabled or type(value)~="number" or value~=value or math.abs(value)==math.huge then return end
	local s=self.stats[name]
	if not s then
		if self.labels>=MAX_LABELS then return end
		self.labels+=1
		s={n=0,sum=0,max=0,values={},next=1};self.stats[name]=s
	end
	s.n+=1;s.sum+=value;s.max=math.max(s.max,value)
	s.values[s.next]=value;s.next=s.next%240+1
end
function Metrics:count(name,n)
	if not self.enabled then return end
	if self.counters[name]==nil then if self.labels>=MAX_LABELS then name="overflow" else self.labels+=1 end end
	self.counters[name]=(self.counters[name] or 0)+(n or 1)
end
function Metrics:event(kind,context)
	if not self.enabled then return end
	table.insert(self.events,{at=self.clock()-self.started,kind=kind,context=context})
	if #self.events>80 then table.remove(self.events,1) end
end
-- Wraps object[key] at instance level. The original keeps its arguments,
-- results (nil included) and errors; stop() puts back exactly what was there.
function Metrics:wrap(object,key,label,after,before)
	local original=object[key];local own=rawget(object,key)
	assert(type(original)=="function","No method "..key)
	local wrapper=function(...)
		if not self.enabled then return original(...) end
		if before then before(...) end
		local at=self.clock()
		if debug.profilebegin then debug.profilebegin("NinjaDuel/"..label) end
		local result=table.pack(pcall(original,...))
		if debug.profileend then debug.profileend() end
		self:sample(label..".ms",(self.clock()-at)*1000);self:count(label..".calls")
		if not result[1] then self:event("script-error",{scope=label,error=tostring(result[2])});error(result[2],0) end
		if after then after(...) end
		return table.unpack(result,2,result.n)
	end
	object[key]=wrapper
	self:addRestore(object,function() if rawget(object,key)==wrapper then object[key]=own end end)
end
function Metrics:addRestore(object,fn) table.insert(self.restores,{object=object,fn=fn}) end
function Metrics:restoreObject(object)
	for i=#self.restores,1,-1 do
		local entry=self.restores[i]
		if entry.object==object then entry.fn();table.remove(self.restores,i) end
	end
end
function Metrics:stop()
	if self.enabled then self.ended=self.clock() end
	self.enabled=false
	for i=#self.restores,1,-1 do self.restores[i].fn() end
	self.restores={}
end
-- Mean/max cover the whole capture; p50/p95 the last 240 samples of a label.
function Metrics:report()
	local out={seconds=math.max(0,(self.ended or self.clock())-self.started),enabled=self.enabled,stats={},counters=table.clone(self.counters),events=table.clone(self.events)}
	for name,s in self.stats do
		local sorted=table.clone(s.values);table.sort(sorted)
		out.stats[name]={count=s.n,mean=s.sum/s.n,max=s.max,p50=sorted[math.max(1,math.ceil(#sorted*.5))],p95=sorted[math.max(1,math.ceil(#sorted*.95))],window=#sorted}
	end
	return out
end
-- An estimate of application payload size, NOT wire bytes or Roblox bandwidth.
function Metrics.estimate(value,depth,budget)
	depth=depth or 0;budget=budget or {left=2048}
	if depth>8 or budget.left<=0 then return 0 end
	budget.left-=1
	local kind=typeof(value)
	if kind=="number" then return 8 elseif kind=="boolean" then return 1 elseif kind=="Vector3" then return 12
	elseif kind=="CFrame" then return 48 elseif kind=="string" then return #value+2 elseif kind=="table" then
		local size=2
		for k,v in value do
			size+=Metrics.estimate(k,depth+1,budget)+Metrics.estimate(v,depth+1,budget)
			if budget.left<=0 then break end
		end
		return size
	end
	return 0
end
-- Telemetry stays small even for malformed clients in multi-client Studio
-- tests: finite numbers, booleans, strings up to 512 characters, string or
-- number keys, depth 8 and `budget` visited values (default 2048).
function Metrics.validPayload(value,budget)
	budget=budget or 2048
	local function visit(v,depth)
		budget-=1;if budget<0 or depth>8 then return false end
		local t=type(v)
		if t=="number" then return v==v and math.abs(v)<math.huge
		elseif t=="boolean" then return true
		elseif t=="string" then return #v<=512
		elseif t=="table" then
			for k,item in v do
				if (type(k)~="string" and type(k)~="number") or not visit(k,depth+1) or not visit(item,depth+1) then return false end
			end
			return true
		end
		return false
	end
	return visit(value,0)
end
return Metrics
