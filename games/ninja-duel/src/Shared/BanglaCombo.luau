-- Adapted from BanglaBattlegrounds StarterPack/Punch/PunchMoves (Dewan Mukto, MIT).
-- Input and cooldown authority moved to the server; no Tool or independent input loop.
local Combo={maxComboCount=3,comboDelay=.5,resetDelay=1.1}
function Combo.next(actor,now)
 local comboTimer=now-actor.lastAttack
 local comboCount=actor.combo
 local maxComboCount=Combo.maxComboCount
 local comboDelay=Combo.resetDelay
 -- Donor combo progression, retained verbatim with per-actor state.
 if comboTimer <= comboDelay then
  comboCount = comboCount + 1
  if comboCount > maxComboCount then
   comboCount = 1
  end
 else
  comboCount = 1
 end
 actor.combo=comboCount;actor.lastAttack=now
 return 'Light'..comboCount
end
Combo.Actions={Light1='Punch',Light2='HardSmack',Light3='MegaPunch'}
-- Donor server damageValues and Animation objects, never supplied by clients.
Combo.Damage={Punch=5,HardSmack=10,MegaPunch=25}
Combo.AnimationIds={Punch=18342131933,HardSmack=18342045122,MegaPunch=18341956985,Parry=18341905406}
return Combo
