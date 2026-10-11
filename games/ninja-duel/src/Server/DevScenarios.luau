-- Explicit QA setups only; they call the live engine, never a second simulator.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local Fighters=require(Shared.Fighters)
local Brawler=require(script.Parent.Brawler)
local World=require(script.Parent.World)
local Scenarios={}
Scenarios.names={"neutral","launcher","air","wall","substitution","grab","whiff","projectile","ko"}
function Scenarios.reset(matches,player,first,second,dummy)
 local old=matches.sessions[player]
 first=first or (old and old.playerId) or "Flashstep";second=second or (old and old.botId) or "Mirage"
 if not Fighters[first] or not Fighters[second] then return false,"Unknown fighter" end
 matches:start(player,first,second)
 local s=matches.sessions[player];s.introUntil=nil;s.botFrozen=dummy~=false
 local c=s.combat
 c:relocate(s.human,s.origin+Vector3.new(0,3,3));c:relocate(s.bot,s.origin+Vector3.new(0,3,-3))
 s.human.root.CFrame=CFrame.lookAt(s.human.root.Position,s.bot.root.Position)
 s.bot.root.CFrame=CFrame.lookAt(s.bot.root.Position,s.human.root.Position)
 matches:snapshot(player,s)
 return true,s
end
function Scenarios.refill(s,actor)
 for _,a in (if actor then {actor} else {s.human,s.bot}) do
  a.chakra=a.def.Chakra or Config.Chakra;a.cooldowns={};a.subCharges=Config.Substitution.Charges;a.subCooldown=0;a.subRegenAt=math.huge
 end
end
function Scenarios.setup(matches,player,name,first,second)
 local known=false;for _,value in Scenarios.names do if value==name then known=true end end
 if not known then return false,"Unknown scenario" end
 local ok,s=Scenarios.reset(matches,player,first,second,true);if not ok then return ok,s end
 local c,a,b=s.combat,s.human,s.bot
 if name=="launcher" then
  Brawler.react(c,b,"Launched",Vector3.new(0,48,0),1.2,a);a.pursuitUntil=c.now+Config.PursuitWindow
 elseif name=="air" then
  for _,x in {a,b} do c:relocate(x,x.root.Position+Vector3.new(0,13,0));x.airborne=true end
  a.airHold=c.now+2;Brawler.react(c,b,"Juggled",Vector3.zero,2,a)
 elseif name=="wall" then
  local hit=workspace:Raycast(s.origin+Vector3.new(World.WALL_RADIUS-12,12,0),Vector3.xAxis*24,c:rayParams(true))
  if not hit or not hit.Instance:GetAttribute("NinjaWall") then return false,"No wall surface on probe ray" end
  c:relocate(b,hit.Position+hit.Normal*2.1);c:relocate(a,b.root.Position+hit.Normal*5)
  a.root.CFrame=CFrame.lookAt(a.root.Position,Vector3.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
  Brawler.react(c,b,"WallSplat",Vector3.zero,.42,a);b.splatAt=c.now;b.splatNormal=hit.Normal
  a.pursuitUntil=c.now+.72
 elseif name=="substitution" then
  a.lastHurt=c.now;Brawler.react(c,a,"HitStun",Vector3.zero,.45,b)
  local accepted,reason=c:request(a,"Substitute");if not accepted then return false,reason end
 elseif name=="grab" then
  c:relocate(b,a.root.Position+a.root.CFrame.LookVector*3.4)
  local accepted,reason=c:request(a,"Grab");if not accepted then return false,reason end
 elseif name=="whiff" then
  c:relocate(b,s.origin+Vector3.new(0,3,-22));c:request(a,"Heavy")
 elseif name=="projectile" then
  c:relocate(b,s.origin+Vector3.new(0,3,-24));c:request(a,"Tool",b.root.Position)
 elseif name=="ko" then
  b.rotationUntil=0;b.shieldCharges=0;b.invulnerableUntil=0;b.readUntil=0
  c:damage(a,b,b.health+200,false,false)
 end
 matches:snapshot(player,s)
 return true,{scenario=name,epoch=s.epoch,first=s.playerId,second=s.botId}
end
return Scenarios
