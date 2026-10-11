-- Data-only, additive edits in the existing anatomical representation. No game hooks.
local Solver=require(script.Parent.PoseSolver)
local E={}
local function copy(v) if type(v)~="table" then return v end;local o={};for k,x in v do o[k]=copy(x)end;return o end
E.Parts={"Root","Hips","Torso","Head","LeftArm","RightArm","LeftLeg","RightLeg","LeftFoot","RightFoot","Weapon"}
E.Map={Root="root",Hips="root",Torso="torso",Head="head",LeftArm="la",RightArm="ra",LeftLeg="ll",RightLeg="rl",LeftFoot="lf",RightFoot="rf",Weapon="weapon"}
local rot={{"pitch","Pitch",-180,180},{"yaw","Yaw",-180,180},{"roll","Roll",-180,180}}
local pos={{"x","X",-5,5},{"y","Y",-5,5},{"z","Z",-5,5}}
E.Controls={Root={pos[1],pos[2],pos[3],rot[1],rot[2],rot[3]},Hips=rot,Torso=rot,Head=rot,Weapon={pos[1],pos[2],pos[3],rot[1],rot[2],rot[3]}}
for _,p in {"LeftArm","RightArm"}do E.Controls[p]={{"raise","Shoulder raise",-150,150},{"out","Shoulder out",-150,150},{"twist","Shoulder rotation",-180,180},{"elbow","Elbow bend",-150,150},{"elbowTwist","Elbow rotation",-180,180},{"wrist","Wrist bend",-120,120},{"wroll","Wrist roll",-120,120}}end
for _,p in {"LeftLeg","RightLeg"}do E.Controls[p]={{"lift","Hip raise",-150,150},{"out","Hip out",-120,120},{"twist","Hip rotation",-180,180},{"knee","Knee bend",-150,150},{"ankle","Ankle bend",-100,100}}end
for _,p in {"LeftFoot","RightFoot"}do E.Controls[p]={pos[1],pos[2],pos[3],{"yaw","Foot yaw",-180,180},{"toe","Toe pitch",-100,100}}end
E.Modifiers={{"amplitude","Amplitude"},{"hipRotation","Hip rotation"},{"torsoFollow","Torso follow"},{"limbExtension","Limb extension"},{"rootTravel","Root travel"},{"impactLean","Impact lean"},{"anticipation","Anticipation"},{"followThrough","Follow-through"},{"recoveryTightness","Recovery tightness"}}
E.Semantics={"Start","Anticipation","Contact","FollowThrough","Recovery"}
E.Easing={"linear","smooth","in","out"}
function E.create(id,name,asset,duration,contact,recovery)
 contact=math.clamp(contact or .42,.12,.85);recovery=math.clamp(recovery or .7,contact+.04,.95)
 local times={0,contact*.5,contact,recovery,1};local keys={};for i,s in E.Semantics do table.insert(keys,{id=s,time=times[i],semantic=s,sourceTime=times[i],parts={}})end
 local modifiers={};for _,row in E.Modifiers do modifiers[row[1]]=1 end
 return {id=id,name=name,sourceAsset=asset.id,sourceGrammar=asset.grammar,sourceDuration=duration,poseOverrides=keys,motionModifiers=modifiers,timing={duration=duration,playbackSpeed=1,easing="linear",hold=0},rootPath={forward=0,lateral=0,lift=0,turn=0,startX=0,startY=0,startZ=0,endX=0,endY=0,endZ=0},channels={},enabled=true}
end
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<1e8 end
local function id(s)return type(s)=="string" and #s>0 and #s<=100 and s:match("^[%w_.:%-]+$")~=nil end
function E.validate(v)
 if type(v)~="table" or not id(v.id) or not id(v.sourceAsset) or not id(v.sourceGrammar) or type(v.name)~="string" or #v.name<1 or #v.name>80 or type(v.enabled)~="boolean" or not finite(v.sourceDuration) or v.sourceDuration<=0 or v.sourceDuration>30 then return false,"Invalid variant header"end
 local t=v.timing;if type(t)~="table" or not finite(t.duration) or t.duration<.12 or t.duration>30 or not finite(t.playbackSpeed) or t.playbackSpeed<.25 or t.playbackSpeed>3 or not table.find(E.Easing,t.easing) or not finite(t.hold) or t.hold<0 or t.hold>.3 then return false,"Invalid variant timing"end
 if type(v.motionModifiers)~="table" or type(v.rootPath)~="table" or type(v.channels)~="table" then return false,"Missing variant controls"end
 for _,row in E.Modifiers do local n=v.motionModifiers[row[1]];if not finite(n) or n<0 or n>3 then return false,"Invalid motion modifier"end end
 for _,key in {"forward","lateral","lift","turn","startX","startY","startZ","endX","endY","endZ"}do local n=v.rootPath[key];if not finite(n) or math.abs(n)>(if key=="turn" then 360 else 10) then return false,"Invalid root path"end end
 for part,channel in v.channels do if not table.find(E.Parts,part) or type(channel)~="table" or type(channel.muted)~="boolean" or type(channel.locked)~="boolean" then return false,"Invalid channel"end end
 if type(v.poseOverrides)~="table" or #v.poseOverrides<5 or #v.poseOverrides>64 then return false,"Pose key budget"end
 local last=-1;local semantics={};local ids={};local lastSource=-1
 for _,key in v.poseOverrides do
  if type(key)~="table" or not id(key.id) or ids[key.id] or not finite(key.time) or key.time<0 or key.time>1 or key.time-last<.001 or type(key.parts)~="table" then return false,"Invalid pose key"end
  ids[key.id]=true;last=key.time
  if key.semantic then local index=table.find(E.Semantics,key.semantic);if not index or semantics[key.semantic] or index~=1+#semantics then return false,"Semantic order"end;table.insert(semantics,key.semantic);semantics[key.semantic]=true;if not finite(key.sourceTime) or key.sourceTime<0 or key.sourceTime>1 or key.sourceTime<=lastSource then return false,"Invalid source marker"end;lastSource=key.sourceTime end
  for part,fields in key.parts do
   if not E.Controls[part] or type(fields)~="table" then return false,"Invalid pose part"end
   for field,n in fields do local control=nil;for _,row in E.Controls[part]do if row[1]==field then control=row end end;if not control or not finite(n) or n<control[3] or n>control[4] then return false,"Invalid pose channel"end end
  end
 end
 if #semantics~=5 or v.poseOverrides[1].semantic~="Start" or v.poseOverrides[1].time~=0 or v.poseOverrides[#v.poseOverrides].semantic~="Recovery" or v.poseOverrides[#v.poseOverrides].time~=1 then return false,"Missing semantic boundaries"end
 return true
end
function E.asset(p,id,lib)
 local v=p.motionVariants and p.motionVariants[id]
 if not v then return lib.assets[id]end
 local base=assert(lib.assets[v.sourceAsset],"Missing variant source")
 local asset=copy(base);asset.id=v.id;asset.name=v.name;asset.duration=v.timing.duration;asset.variant=true;asset.sourceType="variant";return asset
end
function E.variant(p,asset)return p.motionVariants and p.motionVariants[asset.id]end
function E.key(v,id)for i,k in v.poseOverrides do if k.id==id then return k,i end end end
function E.markers(v)local keys={};for _,k in v.poseOverrides do if k.semantic then table.insert(keys,k)end end;return keys end
local function ease(t,kind)return if kind=="linear" then t elseif kind=="in" then t^3 elseif kind=="out" then 1-(1-t)^3 else t*t*(3-2*t)end
function E.warp(v,t)
 local markers=E.markers(v);local contact=markers[3].time;local hold=math.min(v.timing.hold,markers[4].time-contact-.002)
 if t>=contact and t<=contact+hold then return markers[3].sourceTime end
 for i=1,4 do local a,b=markers[i],markers[i+1];local start=a.time+(if i==3 then hold else 0)
  if t<=b.time then local u=ease(math.clamp((t-start)/math.max(.001,b.time-start),0,1),v.timing.easing);return a.sourceTime+(b.sourceTime-a.sourceTime)*u end
 end;return 1
end
function E.moveKeys(v,ids,delta)
 local low=-1;local high=1
 for i,key in v.poseOverrides do if ids[key.id] then
  if key.semantic=="Start" or key.semantic=="Recovery" then return 0 end
  local j=i-1;while j>=1 and ids[v.poseOverrides[j].id]do j-=1 end;low=math.max(low,(v.poseOverrides[j] and v.poseOverrides[j].time or 0)+.002-key.time)
  j=i+1;while j<=#v.poseOverrides and ids[v.poseOverrides[j].id]do j+=1 end;high=math.min(high,(v.poseOverrides[j] and v.poseOverrides[j].time or 1)-.002-key.time)
 end end
 delta=math.clamp(delta,low,high);for _,key in v.poseOverrides do if ids[key.id]then key.time+=delta end end;return delta
end
function E.addKey(v,id,t)
 assert(#v.poseOverrides<64,"Maximum 64 keys");for _,k in v.poseOverrides do assert(math.abs(k.time-t)>=.002,"A key already exists here")end
 assert(t>.002 and t<.998,"Keep Start/Recovery boundaries");local a,b=v.poseOverrides[1],v.poseOverrides[#v.poseOverrides]
 for i=1,#v.poseOverrides-1 do if t<=v.poseOverrides[i+1].time then a,b=v.poseOverrides[i],v.poseOverrides[i+1];break end end
 local u=ease((t-a.time)/(b.time-a.time),v.timing.easing);local parts={}
 for _,part in E.Parts do for _,row in E.Controls[part]do local field=row[1];local x=(a.parts[part] or {})[field] or 0;local y=(b.parts[part] or {})[field] or 0;local n=x+(y-x)*u;if math.abs(n)>.000001 then parts[part]=parts[part] or {};parts[part][field]=n end end end
 table.insert(v.poseOverrides,{id=id,time=t,parts=parts});table.sort(v.poseOverrides,function(a,b)return a.time<b.time end)
end
local function deltas(v,part,t)
 -- Empty semantic keys deliberately mean zero delta, so corrections return to base.
 local keys=v.poseOverrides;local a,b=keys[1],keys[#keys]
 for i=1,#keys-1 do if t<=keys[i+1].time then a,b=keys[i],keys[i+1];break end end
 local u=ease(math.clamp((t-a.time)/math.max(.001,b.time-a.time),0,1),v.timing.easing);local out={}
 for _,row in E.Controls[part]do local field=row[1];local x=(a.parts[part] or {})[field] or 0;local y=(b.parts[part] or {})[field] or 0;out[field]=x+(y-x)*u end
 return out
end
function E.apply(v,base,t)
 if not v.enabled then return base end
 local p=copy(base);local m=v.motionModifiers;local pulse=math.sin(math.pi*t)^2;local markers=E.markers(v);local contact=markers[3].time
 local phaseScale=if t<contact then m.anticipation elseif t<markers[4].time then m.followThrough else m.recoveryTightness
 -- Exaggerate around existing stance-neutral axes, then apply sparse key deltas.
 for part,a in p do if type(a)=="table" then for field,n in a do if type(n)=="number" and not table.find({"x","y","z"},field)then a[field]=n*m.amplitude*(1+(phaseScale-1)*pulse)end end end end
 p.root=p.root or {};p.torso=p.torso or {}
 p.root.yaw=(p.root.yaw or 0)*m.hipRotation;p.torso.yaw=(p.torso.yaw or 0)*m.torsoFollow;p.torso.pitch=(p.torso.pitch or 0)*m.torsoFollow
 p.root.x=(p.root.x or 0)*m.rootTravel;p.root.z=(p.root.z or 0)*m.rootTravel;p.root.pitch=(p.root.pitch or 0)+(m.impactLean-1)*20*pulse
 for _,arm in {"ra","la"}do if p[arm]then p[arm].elbow=math.clamp((p[arm].elbow or 0)-(m.limbExtension-1)*60*pulse,0,160)end end
 for _,leg in {"rl","ll"}do if p[leg]then p[leg].knee=math.clamp((p[leg].knee or 0)-(m.limbExtension-1)*60*pulse,0,160)end end
 for _,part in E.Parts do if not (v.channels[part] and v.channels[part].muted) then
  local d=deltas(v,part,t);local target=E.Map[part];local nonzero=false;for _,n in d do if math.abs(n)>.00001 then nonzero=true end end
  if nonzero then
   if part=="RightLeg"then p.rl=p.rl or Solver.freeLeg(p,1);p.rf=nil elseif part=="LeftLeg"then p.ll=p.ll or Solver.freeLeg(p,-1);p.lf=nil elseif part=="RightFoot"then p.rf=p.rf or Solver.footTarget(p,1);p.rl=nil elseif part=="LeftFoot"then p.lf=p.lf or Solver.footTarget(p,-1);p.ll=nil end
   p[target]=p[target] or {};for field,n in d do p[target][field]=(p[target][field] or 0)+n end
  end
 end end
 local r=v.rootPath;local root=p.root;root.x=(root.x or 0)+r.lateral*pulse+r.startX*(1-t)+r.endX*t;root.z=(root.z or 0)-r.forward*pulse+r.startZ*(1-t)+r.endZ*t;root.y=(root.y or 0)+r.lift*pulse+r.startY*(1-t)+r.endY*t;root.yaw=(root.yaw or 0)+r.turn*pulse
 for _,part in {"ra","la"}do if p[part] then p[part].elbow=math.clamp(p[part].elbow or 0,0,160)end end
 for _,part in {"rl","ll"}do if p[part] then p[part].knee=math.clamp(p[part].knee or 0,0,160)end end
 return p
end
return E
