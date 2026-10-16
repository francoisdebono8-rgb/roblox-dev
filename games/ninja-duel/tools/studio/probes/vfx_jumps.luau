-- Client: VFX parts that jump position between two frames (ground lights / trails / dust popping).
local DUR=12
local LIMIT=3
local RS=game:GetService("RunService")
local folder=workspace:FindFirstChild("NinjaDuelFX")
if not folder then return "no duels" end
local last={}
local born={}
local jumps={}
local frames=0
local tracked=0
local t0=os.clock()
local conn=RS.RenderStepped:Connect(function()
 frames+=1
 local now=os.clock()-t0
 local seen={}
 for _,d in folder:GetDescendants() do
  if d:IsA("BasePart") and d.Transparency<1 then
   seen[d]=true
   local p=d.Position
   local prev=last[d]
   if prev then
    local jump=(p-prev).Magnitude
    if jump>LIMIT and now-(born[d] or 0)>.05 then
     local key=d.Name
     local j=jumps[key] or {count=0,worst=0}
     j.count+=1;if jump>j.worst then j.worst=jump end
     jumps[key]=j
    end
   else born[d]=now;tracked+=1 end
   last[d]=p
  end
 end
 for d in last do if not seen[d] then last[d]=nil end end
end)
task.wait(DUR)
conn:Disconnect()
local out={string.format("%d frames, %d effect parts seen, jump > %d studs/frame:",frames,tracked,LIMIT)}
local list={}
for name,j in jumps do table.insert(list,{name,j.count,j.worst}) end
table.sort(list,function(a,b) return a[2]>b[2] end)
for i,e in list do if i>15 then break end table.insert(out,string.format("  %s x%d (worst %.1f)",e[1],e[2],e[3])) end
return table.concat(out,"\n")
