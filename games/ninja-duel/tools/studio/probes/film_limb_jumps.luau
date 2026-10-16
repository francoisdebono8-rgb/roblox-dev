-- Client: per-frame limb jumps in the fighter's own root frame (pose snaps at transitions)
local WHO="me"
local LIMIT=.8
local film=shared.NdFilm
if not film then return "no film" end
local limbs={"RightHand#1","LeftHand#1","RightFoot#1","LeftFoot#1","Head#1"}
local out={};local worst=0;local count=0;local frames=0
local prev=nil
for _,f in film.frames do
 local pose=f.poses[WHO];local root=pose["HumanoidRootPart#1"]
 if root then
  local cur={}
  for _,k in limbs do local p=pose[k];if p then cur[k]=root.cf:PointToObjectSpace(p.cf.Position) end end
  if prev and f.t-prev.t<.05 then
   frames+=1
   local fmax,fk=0,""
   for _,k in limbs do if cur[k] and prev.cur[k] then local d=(cur[k]-prev.cur[k]).Magnitude if d>fmax then fmax=d;fk=k end end end
   if fmax>worst then worst=fmax end
   if fmax>LIMIT then count+=1;if #out<14 then table.insert(out,string.format("%.2f %s %.2f | %s",f.t,fk,fmax,f.label)) end end
  end
  prev={t=f.t,cur=cur}
 end
end
table.insert(out,1,string.format("%s: %d/%d frames with a limb jump > %.1f stud (worst %.2f)",WHO,count,frames,LIMIT,worst))
return table.concat(out,"\n")
