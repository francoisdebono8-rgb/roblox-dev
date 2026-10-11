-- Read-only Studio adornments; never creates collision Parts or changes queries.
local Volumes={};Volumes.__index=Volumes
function Volumes.new(player) return setmetatable({player=player,enabled=false,boxes={},last=0},Volumes) end
function Volumes:clear()
 for _,box in self.boxes do box:Destroy() end;self.boxes={}
end
function Volumes:set(enabled) self.enabled=enabled;if not enabled then self:clear() end end
function Volumes:update()
 if not self.enabled or os.clock()-self.last<.1 then return end;self.last=os.clock()
 local model=self.player.Character;local folder=model and model.Parent;local effects=folder and folder:FindFirstChild("Effects")
 local wanted={}
 if effects then
  for _,part in effects:GetChildren() do
   if part:IsA("BasePart") and part.Name=="BanglaHitbox" then wanted[part]=Color3.fromRGB(255,100,85) end
  end
 end
 for _,fighter in {model,folder and folder:FindFirstChild("AIFighter")} do
  local root=fighter and fighter:FindFirstChild("HumanoidRootPart");if root then wanted[root]=Color3.fromRGB(70,170,255) end
 end
 for part,box in self.boxes do if not wanted[part] or not part.Parent then box:Destroy();self.boxes[part]=nil end end
 local count=0
 for part,color in wanted do
  count+=1;if count>40 then break end
  local box=self.boxes[part]
  if not box then
   box=Instance.new("BoxHandleAdornment");box.Name="DevObservedVolume";box.Adornee=part;box.AlwaysOnTop=true;box.ZIndex=4;box.Transparency=.7;box.Parent=self.player.PlayerGui;self.boxes[part]=box
  end
  box.Size=part.Size;box.Color3=color
 end
end
return Volumes
