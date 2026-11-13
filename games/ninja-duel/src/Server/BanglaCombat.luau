-- Adapted from BanglaBattlegrounds ServerScriptService/StarterCombat.
-- Copyright (c) 2024 Dewan Mukto, MIT (vendor/bangla/LICENSE).
-- Retained: forward hitbox, per-swing Hits, damage table, parry seam, hit counter,
-- BasicPunch emission and swing/contact sounds. Changes: one validated actor API,
-- deterministic broadphase for anchored hitboxes, active-window lifetime/cleanup,
-- collision occlusion, and Ninja Duel's guard/chakra/damage authority.
local Debris=game:GetService('Debris')
local assets=game:GetService('ReplicatedStorage').NinjaDuel:WaitForChild('BanglaAssets')
local Combo=require(game:GetService('ReplicatedStorage').NinjaDuel.BanglaCombo)
local Config=require(game:GetService('ReplicatedStorage').NinjaDuel.Config)
local Bangla={}
local function sound(parent,id)
 local s=Instance.new('Sound');s.SoundId=id;s.Volume=.5;s.Parent=parent
 s:Play();Debris:AddItem(s,1.5)
end
function Bangla.begin(c,a,p)
 local hitbox=Instance.new('Part')
 hitbox.Name='BanglaHitbox';hitbox.Anchored=true;hitbox.CanCollide=false
 hitbox.CanQuery=false;hitbox.CanTouch=false;hitbox.Transparency=1
 hitbox.Size=Vector3.new(5,5,2)
 hitbox.CFrame=a.root.CFrame*CFrame.new(0,0,-2)
 hitbox.Parent=c.match.effects
 p.donor={hitbox=hitbox,Hits={},action=Combo.Actions[p.name] or 'MegaPunch'}
 -- The donor used Debris for lifetime; c.effects also cleans interrupted swings.
 -- (13/11, #72: the Chidori dive off the wall missed a body 40 studs away)
 -- A sized window (the wall dive's flight, the slam's descent: p.slamWindow,
 -- Combat's Active) keeps the hitbox for the whole of it, not the authored
 -- active alone: the dive arrived after the box was gone.
 local window=math.max(p.spec.active,p.slamWindow or 0)
 table.insert(c.effects,{part=hitbox,expires=c.now+p.spec.startup+window+.05})
 sound(a.root,'rbxassetid://5835032207')
 a.model:SetAttribute('CombatBase','BanglaBattlegrounds')
end
function Bangla.close(p)
 if p and p.donor then p.donor.hitbox:Destroy() end
end
function Bangla.tryHit(c,a,p)
 local donor=p.donor;local target=a.target
 if not donor or not donor.hitbox.Parent or not target or target.health<=0 then return false end
 -- Same donor forward volume; missing air/grab mechanics supply their bounded shape.
 local hitbox=donor.hitbox
 hitbox.Size=Vector3.new(p.spec.width or 5,p.spec.height or 5,p.spec.depth or 2)
 -- A strike carried out by another body (Ninja Duel Bodies: Naruto's clone)
 -- is thrown, validated and judged from that body's frame (p.from).
 local frame=p.from or a.root.CFrame
 hitbox.CFrame=frame*CFrame.new(0,0,-(p.spec.offset or 2))
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={target.model}
 -- Touched on a teleported anchored part was unreliable; query the same volume.
 for _,hit in workspace:GetPartBoundsInBox(hitbox.CFrame,hitbox.Size,params) do
  if hit:IsDescendantOf(target.model) and not donor.Hits[target.id] then
   -- (07/11, game feel) only what is in front of the blow (Config.Contact).
   if not c:targetValid(a,target,p.spec.range,p.spec.facing or Config.Contact.Facing,p.from) then continue end
   -- (13/11, #72: the Chidori dive at a body getting up) The rising body's
   -- short protection lets a strike pass, it does not spend it: a strike
   -- still out when he is up lands (a dodge or a substitution still eats it).
   if target.reaction=="Wakeup" and (target.invulnerableUntil or 0)>c.now then continue end
   donor.Hits[target.id]=true
   local delta=frame.Position-target.root.Position
   local frontal=delta.Magnitude<.001 or target.root.CFrame.LookVector:Dot(delta.Unit)>.15
   local guarded=target.state=='Guarding' and target.chakra>0 and frontal
   local protected=target.state=='TechniqueChannel' and target.pending and not target.pending.spec.Interruptible
   local damage=if Combo.Actions[p.name] then Combo.Damage[donor.action] else p.spec.damage
   c.damageTag=if p.rasengan then "Rasengan" else p.name
   -- A Flow strike (chained on the beat) lands a little harder.
   local flow=if p.flow then require(game:GetService("ReplicatedStorage").NinjaDuel.Config).Flow.Damage else 1
   if p.from then c.hitOrigin=frame.Position end
   local success=c:damage(a,target,damage*(a.def.CombatDamage or 1)*flow*(p.spec.damageScale or 1),false,true)
   if p.from then c.hitOrigin=nil end
   c.damageTag=nil
   -- The defence resolution (guard, Byakugan sight, guard break) is the truth.
   if success then guarded=target.impactStyle=='block' end
   -- A Gentle Fist palm is not a punch: no donor fist burst on the body (the
   -- client strikes the chakra point itself, IdentityFX).
   if success and not a.def.GentleFist then
    -- Contact audio comes from the client's impact feed (VelmoraHitFeedback);
    -- a replicated server Sound here doubled every hit, out of sync.
    local vfx=if donor.action=='MegaPunch' then 'ComboPunch' else 'BasicPunch'
    local basicPunch=assets.VFX[vfx].Attachment:Clone()
    basicPunch.Parent=target.root
    for _,v in basicPunch:GetChildren() do
     if v:IsA('ParticleEmitter') then v:Emit(v:GetAttribute('EmitCount') or 1) end
    end
    Debris:AddItem(basicPunch,.25)
   end
   if success then
    if c.now-(a.donorLastHit or -10)>2 then a.donorHitCount=0 end
    a.donorHitCount=(a.donorHitCount or 0)+1;a.donorLastHit=c.now
   end
   return success,guarded,protected
  end
 end
 return false
end
return Bangla
