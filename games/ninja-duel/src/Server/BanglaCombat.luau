-- Adapted from BanglaBattlegrounds ServerScriptService/StarterCombat.
-- Copyright (c) 2024 Dewan Mukto, MIT (vendor/bangla/LICENSE).
-- Retained: forward hitbox, per-swing Hits, damage table, parry seam, hit counter,
-- BasicPunch emission and swing/contact sounds. Changes: one validated actor API,
-- deterministic broadphase for anchored hitboxes, active-window lifetime/cleanup,
-- collision occlusion, and Ninja Duel's guard/chakra/damage authority.
local Debris=game:GetService('Debris')
local assets=game:GetService('ReplicatedStorage').NinjaDuel:WaitForChild('BanglaAssets')
local Combo=require(game:GetService('ReplicatedStorage').NinjaDuel.BanglaCombo)
local Bangla={}
local weaponSounds={['Light Melee']='rbxassetid://8595980577',['Heavy Melee']='rbxassetid://9117969717'}
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
 table.insert(c.effects,{part=hitbox,expires=c.now+p.spec.startup+p.spec.active+.05})
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
 hitbox.CFrame=a.root.CFrame*CFrame.new(0,0,-(p.spec.offset or 2))
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={target.model}
 -- Touched on a teleported anchored part was unreliable; query the same volume.
 for _,hit in workspace:GetPartBoundsInBox(hitbox.CFrame,hitbox.Size,params) do
  if hit:IsDescendantOf(target.model) and not donor.Hits[target.id] then
   if not c:targetValid(a,target,p.spec.range,p.spec.facing or .05) then continue end
   donor.Hits[target.id]=true
   local delta=a.root.Position-target.root.Position
   local frontal=delta.Magnitude<.001 or target.root.CFrame.LookVector:Dot(delta.Unit)>.15
   local guarded=target.state=='Guarding' and target.chakra>0 and frontal
   local protected=target.state=='TechniqueChannel' and target.pending and not target.pending.spec.Interruptible
   local damage=if Combo.Actions[p.name] then Combo.Damage[donor.action] else p.spec.damage
   local success=c:damage(a,target,damage*(a.def.CombatDamage or 1),false,true)
   if success then
    local weaponType=if donor.action=='MegaPunch' then 'Heavy Melee' else 'Light Melee'
    sound(target.root,weaponSounds[weaponType])
    local vfx=if donor.action=='MegaPunch' then 'ComboPunch' else 'BasicPunch'
    local basicPunch=assets.VFX[vfx].Attachment:Clone()
    basicPunch.Parent=target.root
    for _,v in basicPunch:GetChildren() do
     if v:IsA('ParticleEmitter') then v:Emit(v:GetAttribute('EmitCount') or 1) end
    end
    Debris:AddItem(basicPunch,.25)
    if c.now-(a.donorLastHit or -10)>2 then a.donorHitCount=0 end
    a.donorHitCount=(a.donorHitCount or 0)+1;a.donorLastHit=c.now
   end
   return success,guarded,protected
  end
 end
 return false
end
return Bangla
