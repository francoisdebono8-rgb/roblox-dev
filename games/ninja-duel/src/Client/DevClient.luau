-- Studio-only overlay and bounded observation of the live client. F6 opens it.
local Dev={}
function Dev.install(ctx)
 local rs=game:GetService("RunService");if not rs:IsStudio() then return nil end
 local Metrics=require(game:GetService("ReplicatedStorage").NinjaDuel.DevMetrics)
 local volumes=require(script.Parent.DevVolumes).new(ctx.player)
 local m=Metrics.new();local self={panelOpen=false,metrics=m};local track={};local lastPacket=nil;local epoch=nil
 local log,control;local busy=false;local profile=false
 local gui=Instance.new("ScreenGui");gui.Name="NinjaDuelDevPanel";gui.ResetOnSpawn=false;gui.DisplayOrder=100;gui.Enabled=false;gui.Parent=ctx.player:WaitForChild("PlayerGui")
 local frame=Instance.new("Frame");frame.Size=UDim2.fromOffset(360,530);frame.Position=UDim2.new(0,16,0,16);frame.BackgroundColor3=Color3.fromRGB(20,24,30);frame.Parent=gui
 local title=Instance.new("TextLabel");title.Size=UDim2.new(1,-16,0,40);title.Position=UDim2.fromOffset(8,4);title.BackgroundTransparency=1;title.TextColor3=Color3.new(1,1,1);title.TextSize=16;title.Text="DEV / F6 — Studio uniquement";title.Parent=frame
 local status=title:Clone();status.Position=UDim2.fromOffset(8,478);status.Size=UDim2.new(1,-16,0,46);status.TextSize=13;status.TextWrapped=true;status.Text="Mesures OFF · aucun scénario actif";status.Parent=frame
 local firstButton;local selectedBefore
 local function run(op,arg)
  if busy or not control then return end;busy=true
  task.spawn(function()
   local ok,result=pcall(function() return control:InvokeServer(op,arg or {}) end)
   status.Text=if ok and result.ok then op.." : OK" else tostring(ok and result.error or result)
   busy=false
  end)
 end
 local index=0
 local function button(text,callback)
  local b=Instance.new("TextButton");local row=math.floor(index/2);local col=index%2;index+=1
  b.Position=UDim2.fromOffset(8+col*174,48+row*32);b.Size=UDim2.fromOffset(168,28);b.BackgroundColor3=Color3.fromRGB(43,51,65);b.TextColor3=Color3.new(1,1,1);b.TextSize=13;b.Text=text;b.Parent=frame;b.Activated:Connect(callback);firstButton=firstButton or b
 end
 local ids={"Flashstep","Mirage","GentleFist","Lion"};local names={"Minato","Itachi","Neji","Sasuke"}
 -- IDs come from the active data, with no registration of new movesets.
 local Fighters=require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters)
 local active={};for id,def in Fighters do if def.Name=="Neji" then ids[3]=id elseif def.Name=="Sasuke" then ids[4]=id end;active[id]=true end
 for i,id in ids do
  if active[id] then button("Joueur : "..names[i],function() run("character",{first=id}) end);button("Adversaire : "..names[i],function() run("character",{second=id}) end) end
 end
 button("Reset immédiat",function() run("reset") end);button("Chakra / sub pleins",function() run("refill") end)
 button("Éveil joueur",function() run("awaken") end);button("KO adversaire",function() run("ko",{actor="bot"}) end)
 button("Dummy",function() run("dummy",{enabled=true}) end);button("IA",function() run("dummy",{enabled=false}) end)
 for _,name in {"neutral","launcher","air","wall","substitution","grab","whiff","projectile"} do button("Situation : "..name,function() run("scenario",{name=name}) end) end
 button("Répéter situation",function() run("repeat") end)
 button("Mesures ON / OFF",function() profile=not profile;run("profile",{enabled=profile}) end)
 button("Rapport → Output",function() run("report") end)
 button("Volumes ON / OFF",function() volumes:set(not volumes.enabled);status.Text="Volumes : racines bleues / hitboxes rouges" end)
 function self:toggle()
  self.panelOpen=not self.panelOpen;gui.Enabled=self.panelOpen
  local gs=game:GetService("GuiService")
  if self.panelOpen then selectedBefore=gs.SelectedObject;ctx.input:reset();ctx.send("GuardOff");ctx.send("Move",Vector3.zero);gs.SelectedObject=firstButton
  else gs.SelectedObject=if selectedBefore and selectedBefore.Parent then selectedBefore else nil end
 end
 game:GetService("UserInputService").InputBegan:Connect(function(key,processed)
  if not processed and key.KeyCode==Enum.KeyCode.F6 then self:toggle() end
 end)
 local function setProfile(enabled)
  m:stop();track={};lastPacket=nil
  if not enabled then return end
  m:start()
  for _,key in {"smoothStep","update","impacts"} do m:wrap(ctx.presentation,key,"client.presentation."..key) end
  m:wrap(ctx.camera,"update","client.camera");m:wrap(ctx.ui,"render","client.hud")
  m:wrap(ctx.presentation.fx,"update","client.fx")
 end
 rs:BindToRenderStep("NinjaDuelDevMeasure",Enum.RenderPriority.Camera.Value+1,function(dt)
  volumes:update()
  if not m.enabled then return end
  local data=ctx.state();if data.phase~="Duel" or dt<=0 then return end
  m:sample("client.frame.ms",dt*1000)
  if dt>.05 then m:event("frame-spike",{ms=dt*1000,state=data.human.state}) end
  if epoch~=data.epoch then track={};epoch=data.epoch;m:event("epoch",{epoch=epoch}) end
  if data~=lastPacket then
   local at=os.clock();if lastPacket then m:sample("client.snapshot.gap.ms",(at-self.packetAt)*1000) end
   self.packetAt=at;lastPacket=data
   if data.serverNow then m:sample("client.snapshot.age.ms",math.max(0,workspace:GetServerTimeNow()-data.serverNow)*1000) end
  end
  for _,key in {"human","bot"} do
   local actor=data[key];local st=ctx.presentation.smooth[key];local draw=ctx.presentation:visualRoot(key)
   if actor and st and st.replicatedCF and draw then
    m:sample("client."..key..".presentationGap.studs",(draw-st.replicatedCF.Position).Magnitude)
    local old=track[key];local delta=old and (draw-old.p).Magnitude or 0
    m:sample("client."..key..".frameTravel.studs",delta)
    if old and delta>math.max(6,dt*160) then m:event("visual-position-jump",{actor=key,state=actor.state,reaction=actor.reaction,attack=actor.attackName,studs=delta,warp=actor.warpSerial,previousWarp=old.warp,ms=dt*1000}) end
    track[key]={p=draw,warp=actor.warpSerial}
   end
  end
 end)
 task.spawn(function()
  -- The server creates this channel at ReplicatedStorage root, never in Shared.
  log=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuelDevLog",10)
  control=game:GetService("ReplicatedStorage").NinjaDuel:WaitForChild("DevControl",10)
  if not log then return end
  local warnings={time=0,count=0}
  game:GetService("LogService").MessageOut:Connect(function(message,kind)
   if kind~=Enum.MessageType.MessageError and kind~=Enum.MessageType.MessageWarning then return end
   local now=os.clock();if now-warnings.time>1 then warnings.time=now;warnings.count=0 end
   if warnings.count>=4 then return end;warnings.count+=1;log:FireServer("log",message:sub(1,400))
  end)
  log.OnClientEvent:Connect(function(kind,enabled)
   if kind=="profile" then profile=enabled==true;setProfile(profile);status.Text="Mesures "..(profile and "ON" or "OFF")
   elseif kind=="report" then local report=m:report();report.build=game:GetService("ReplicatedStorage").NinjaDuel.BuildFingerprint.Value;log:FireServer("report",report)
   elseif kind=="probe" then log:FireServer("info",{probe=m:report()})
   elseif kind=="info" then
    local cam=workspace.CurrentCamera;local uiObjects={};local hud=ctx.player.PlayerGui:FindFirstChild("NinjaDuelHUD")
    if hud then for _,g in hud:GetDescendants() do if g:IsA("GuiObject") and #uiObjects<40 then table.insert(uiObjects,{name=g.Name,visible=g.Visible,position=tostring(g.AbsolutePosition),size=tostring(g.AbsoluteSize)}) end end end
    log:FireServer("info",{camera=tostring(cam.CFrame),fov=cam.FieldOfView,mode=ctx.camera.mode,gui=uiObjects})
   end
  end)
 end)
 return self
end
return Dev
