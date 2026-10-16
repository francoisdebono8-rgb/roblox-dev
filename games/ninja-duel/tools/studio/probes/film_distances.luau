local film=shared.NdFilm
if not film then return "no film" end
local out={}
local nextT=0.8
for _,f in film.frames do
 if f.t>=nextT and f.t<=1.9 then
  nextT=f.t+.05
  local a,b=f.poses.me,f.poses.bot
  local function p(pose,k) local r=pose[k];return r and r.cf.Position end
  local ra,rb=p(a,"HumanoidRootPart#1"),p(b,"HumanoidRootPart#1")
  local ta,tb=p(a,"UpperTorso#1"),p(b,"UpperTorso#1")
  local ha,hb=p(a,"Head#1"),p(b,"Head#1")
  local function flat(x,y) return ((x-y)*Vector3.new(1,0,1)).Magnitude end
  -- closest approach between any two parts of the two bodies (centres)
  local best=math.huge
  for ka,va in a do if va.tr<1 then for kb,vb in b do if vb.tr<1 then local d=(va.cf.Position-vb.cf.Position).Magnitude if d<best then best=d end end end end end
  table.insert(out,string.format("%.2f root %.2f torso %.2f head %.2f nearestParts %.2f | %s",f.t,flat(ra,rb),flat(ta,tb),flat(ha,hb),best,f.label))
 end
end
return table.concat(out,"\n")
