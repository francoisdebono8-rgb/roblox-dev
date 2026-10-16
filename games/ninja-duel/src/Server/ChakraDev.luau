-- Server-internal tool facade. Studio bindable or offline CLI, no client Remote.
-- Chakra lab (Codex 7091585, ported verbatim): reached only through
-- dev:Invoke("interactions",op,args), loaded on the first call and only when
-- the chakra runtime modules exist (DevTools.ChakraRuntime). Debug/QA places
-- only (DEBUG_SOURCES).
local S=require(script.Parent.ProfileSchema)
local V=require(script.Parent.ChakraVectors)
local Lab=require(script.Parent.ChakraLab)
local Dev={};Dev.__index=Dev
function Dev.new(cfg,studio)
 if studio then assert(game:GetService("RunService"):IsStudio(),"Studio only") end
 return setmetatable({cfg=cfg,lab=Lab.new(cfg),studio=studio==true,view=nil,connection=nil,running=false,log=false,accumulator=0,lastPrinted=0},Dev)
end
function Dev:draw()
 if self.view then self.view:update({objects=self.lab.engine.objects,surfaces=self.lab.engine.surfaces}) end
 if self.log then
  for _,event in self.lab.engine.events do if event.sequence>self.lastPrinted then
   print("[NinjaDuelChakra] "..game:GetService("HttpService"):JSONEncode(event));self.lastPrinted=event.sequence
  end end
 end
end
function Dev:stop()
 if self.connection then self.connection:Disconnect();self.connection=nil end;self.running=false;self.accumulator=0
end
function Dev:destroy()
 self:stop();if self.view then self.view:destroy();self.view=nil end;self.lab:reset(true)
end
function Dev:_run(op,arg)
 local e=self.lab.engine
 if op=="qa" then assert(self.studio,"Native QA is Studio only");return require(script.Parent.ChakraStudioQA).run()
 elseif op=="spawn" then return e:spawn(arg.id,arg.tool or "Kunai",arg)
 elseif op=="surface" then return e:surface(arg.id,arg.kind or "Wall",arg.position or V.new(8,3,0),arg.normal)
 elseif op=="nature" then return e:infuse(arg.id,arg.nature or "None")
 elseif op=="property" then return e:property(arg.id,arg.property,arg.enabled)
 elseif op=="launch" then return e:launch(arg.id,arg.direction or V.new(1,0,0),arg.speed)
 elseif op=="collision" then return self.lab:forceClash(arg.source,arg.target,arg.direction,arg.normal)
 elseif op=="embed" then return self.lab:embed(arg.id,arg.surface)
 elseif op=="trigger" then return e:trigger(arg)
 elseif op=="toggle" then e:toggle(arg.rule,arg.enabled);return {rule=arg.rule,enabled=arg.enabled}
 elseif op=="inspect" then return e:inspect(arg.id)
 elseif op=="report" then return self.lab:report()
 elseif op=="compare" then return Lab.compare(self.cfg,arg.tool or "Kunai",arg.infusions or {"None","Reinforce","Wind"},arg.masteries or {"Basic","WeaponExpert"})
 elseif op=="demo" then self:stop();self.lastPrinted=0;if self.view then self.view:reset() end;return self.lab:demo(arg.name,arg.mastery)
 elseif op=="step" then return self.lab:run(arg.seconds or 1)
 elseif op=="reset" then self:stop();self.lab:reset(arg.clearRules==true);self.lastPrinted=0;if self.view then self.view:reset() end;return self.lab:report()
 elseif op=="stop" then self:stop();return {running=false}
 elseif op=="close" then self:destroy();return {closed=true}
 elseif op=="log" then assert(self.studio and type(arg.enabled)=="boolean","Studio boolean log switch");self.log=arg.enabled;return {enabled=self.log}
 elseif op=="show" then
  assert(self.studio,"Studio view only");if self.view then self.view:destroy();self.view=nil end
  if arg.enabled~=false then
   assert(not arg.origin or V.valid(arg.origin),"Invalid lab origin")
   self.view=require(script.Parent.ChakraStudioView).new(self.cfg,arg.origin and Vector3.new(arg.origin.x,arg.origin.y,arg.origin.z))
  end
  return {visible=self.view~=nil,folder="Workspace.NinjaDuelChakraLab",cameraChanged=false}
 elseif op=="play" then
  assert(self.studio,"Realtime lab is Studio only");self:stop();self.running=true
  self.connection=game:GetService("RunService").Heartbeat:Connect(function(dt)
   self.accumulator+=dt;local limit=8/60
   if self.accumulator>limit then self.lab.discardedSeconds+=self.accumulator-limit;self.accumulator=limit end
   local ok,err=pcall(function()
    while self.accumulator>=1/60 do self.lab:step(1/60);self.accumulator-=1/60 end;self:draw()
   end)
   if not ok then self:stop();warn("[NinjaDuelChakra] lab stopped: "..tostring(err)) end
  end)
  return {running=true}
 end
 error("Unknown interaction operation")
end
function Dev:run(op,arg)
 arg=arg or {};if type(arg)~="table" or not S.serializable(arg) then return {ok=false,error="Invalid dev arguments"} end
 local ok,value=pcall(self._run,self,op,arg)
 if ok then
  local drawn,err=pcall(self.draw,self);if not drawn then self:stop();return {ok=false,error="Lab view: "..tostring(err)} end
 end
 if ok and type(value)=="table" and value.ok==false then return value end
 return if ok then {ok=true,result=value} else {ok=false,error=tostring(value)}
end
return Dev
