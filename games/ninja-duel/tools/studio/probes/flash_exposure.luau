-- Client datamodel: flash exposure during an AI-vs-AI fight (run after nd_fight_on on the server).
-- Tracks every PointLight and Neon part created after start; per rendered frame sums light
-- "power" (Brightness*Range) and the screen-relevant neon area (size^2 * opacity) of big neon bits.
local RS=game:GetService("RunService")
local lights,neon={}, {}
local conn=workspace.DescendantAdded:Connect(function(d)
 if d:IsA("PointLight") or d:IsA("SpotLight") then lights[d]=true
 elseif d:IsA("BasePart") and d.Material==Enum.Material.Neon then neon[d]=true end
end)
local bySource={}
local frames,litFrames,bigFlashFrames=0,0,0
local peakLight,sumLight,peakNeon,sumNeon=0,0,0,0
local start=os.clock()
local rc=RS.RenderStepped:Connect(function()
 frames+=1
 local power=0
 for l in lights do
  if l.Parent and l.Enabled then power+=l.Brightness*l.Range else if not l.Parent then lights[l]=nil end end
 end
 local area=0
 for p in neon do
  if p.Parent then
   local op=1-p.Transparency
   if op>0.05 then local s=p.Size; local m=math.max(s.X,s.Y,s.Z); area+=m*m*op end
  else neon[p]=nil end
 end
 if power>20 then litFrames+=1 end
 for l in lights do if l.Parent and l.Enabled and l.Brightness*l.Range>8 then local k=(l.Parent.Name or "?").."|r"..math.floor(l.Range).."|b"..math.floor(l.Brightness*10)/10; bySource[k]=(bySource[k] or 0)+1 end end
 if area>40 then bigFlashFrames+=1 end
 peakLight=math.max(peakLight,power);sumLight+=power
 peakNeon=math.max(peakNeon,area);sumNeon+=area
end)
task.wait(12)
rc:Disconnect();conn:Disconnect()
local parts={} for k,v in bySource do table.insert(parts,k.."="..v) end table.sort(parts)
return table.concat(parts,"; ").." || "..string.format("frames=%d fps=%.0f | light: peak=%.0f mean=%.1f framesAbove20=%.1f%% | neon: peak=%.0f mean=%.1f framesAbove40=%.1f%%",
 frames,frames/12,peakLight,sumLight/math.max(frames,1),litFrames/math.max(frames,1)*100,peakNeon,sumNeon/math.max(frames,1),bigFlashFrames/math.max(frames,1)*100)
