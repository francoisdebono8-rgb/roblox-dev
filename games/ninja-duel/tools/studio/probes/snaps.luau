-- Client datamodel: per-frame snaps annotated with the combat state broadcast by the debug inspector.
local RS=game:GetService("RunService")
local Players=game:GetService("Players")
local cam=workspace.CurrentCamera
local DUR=13
local latest=nil
local remote=game:GetService("ReplicatedStorage"):FindFirstChild("NinjaDuelCombatDebug")
local rconn=remote and remote.OnClientEvent:Connect(function(snap) latest=snap end)
local function ctx()
 if not latest or not latest.actors then return "?" end
 local out={}
 for _,a in latest.actors do
  table.insert(out,string.format("%s:%s/%s/%s/%s",string.sub(a.fighterId or a.id or "?",1,5),a.state or "?",a.reaction or "-",a.move or "-",a.movement or "-"))
 end
 local styles={}
 for _,i in latest.impacts or {} do table.insert(styles,i.style) end
 return table.concat(out," ").." imp="..table.concat(styles,",",math.max(1,#styles-2))
end
local tracks={}
local function part(modelName,partName)
 return function()
  local me=Players.LocalPlayer.Character
  local folder=me and me.Parent
  local m=if modelName=="me" then me else folder and folder:FindFirstChild(modelName)
  local p=m and m:FindFirstChild(partName)
  return p and p.Position
 end
end
local order={"camera","meRoot","meLFoot","meLFootRel","botTorso","botLFoot","botLFootRel"}
local yaw={me={prev=nil,n=0,snaps=0,max=0},bot={prev=nil,n=0,snaps=0,max=0}}
local function torso(which) local me=Players.LocalPlayer.Character local f=me and me.Parent local m=if which=="me" then me else f and f:FindFirstChild("AIFighter") local t=m and m:FindFirstChild("HumanoidRootPart") return t and t.CFrame.LookVector end
local function rel(modelName)
 return function()
  local me=Players.LocalPlayer.Character
  local folder=me and me.Parent
  local m=if modelName=="me" then me else folder and folder:FindFirstChild(modelName)
  local r=m and m:FindFirstChild("HumanoidRootPart");local f=m and m:FindFirstChild("LeftFoot")
  return r and f and r.CFrame:PointToObjectSpace(f.Position)
 end
end
local getters={camera=function() return cam.CFrame.Position end,meRoot=part("me","HumanoidRootPart"),meLFoot=part("me","LeftFoot"),meLFootRel=rel("me"),
 botTorso=part("AIFighter","UpperTorso"),botLFoot=part("AIFighter","LeftFoot"),botLFootRel=rel("AIFighter")}
for _,n in order do tracks[n]={prev=nil,vel=Vector3.zero,frames=0,snaps=0,events={}} end
local t0=os.clock()
local conn=RS.RenderStepped:Connect(function(dt)
 if dt<=0 then return end
 local t=os.clock()-t0
 for which,y in yaw do
  local lv=torso(which)
  if lv and y.prev and t>0.6 then
   local a=math.deg(math.acos(math.clamp(Vector3.new(lv.X,0,lv.Z).Unit:Dot(Vector3.new(y.prev.X,0,y.prev.Z).Unit),-1,1)))
   y.n+=1;if a>y.max then y.max=a end;if a>25 then y.snaps+=1 end
  end
  y.prev=lv
 end
 for _,n in order do
  local tr=tracks[n];local p=getters[n]()
  if p then
   if tr.prev and t>0.6 then
    local err=(p-(tr.prev+tr.vel*dt)).Magnitude
    tr.frames+=1
    if err>(if string.find(n,"Rel") then .5 else .8) then
     tr.snaps+=1
     if #tr.events<(if n=="meRoot" then 10 else 0) then table.insert(tr.events,string.format("  %.2fs %.1f | %s",t,err,ctx())) end
    end
   end
   if tr.prev then tr.vel=tr.vel:Lerp((p-tr.prev)/dt,.5) end
   tr.prev=p
  end
 end
end)
task.wait(DUR)
conn:Disconnect();if rconn then rconn:Disconnect() end
local out={"debugRemote="..tostring(remote~=nil)}
for which,y in yaw do table.insert(out,string.format("yaw %s frames=%d turns>25deg/frame=%d (%.1f%%) max=%.0f",which,y.n,y.snaps,y.snaps/math.max(y.n,1)*100,y.max)) end
for _,n in order do
 local tr=tracks[n]
 table.insert(out,string.format("%s frames=%d snaps=%d (%.1f%%)",n,tr.frames,tr.snaps,tr.snaps/math.max(tr.frames,1)*100))
 for _,e in tr.events do table.insert(out,e) end
end
return table.concat(out,"\n")
