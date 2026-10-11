-- Two-player adapter around the SAME Combat instance, without any AI.
-- The future host supplies server-created actors, finish handling and cleanup.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Rules=require(Shared.Rules)
local Config=require(Shared.Config)
local Validation=require(script.Parent.OnlineValidation)
local Match={};Match.__index=Match
function Match.new(epoch,combat,players,actors)
 assert(#players==2 and players[1]~=players[2] and #actors==2 and actors[1]~=actors[2],"Two distinct players/actors required")
 assert(combat.actors[1]==actors[1] and combat.actors[2]==actors[2],"Actors must belong to combat")
 local self=setmetatable({epoch=epoch,combat=combat,players=players,actors=actors,phase="Duel",byPlayer={},sequence={},buckets={}},Match)
 for i,p in players do self.byPlayer[p]=actors[i];self.buckets[p]={tokens=Config.RequestBurst,time=os.clock()};actors[i].target=actors[3-i] end
 return self
end
function Match:request(player,payload,serverNow,clock)
 local bucket=self.buckets[player]
 if not bucket or not Rules.consumeToken(bucket,clock,Config.RequestRate,Config.RequestBurst) then return false,"Rate limit / participant" end
 local clean,reason=Validation.intent(self,player,payload,serverNow);if not clean then return false,reason end
 self.sequence[player]=clean.sequence
 local actor=self.byPlayer[player]
 if clean.direction then actor.move=clean.direction;actor.lastMove=clock end
 if clean.sprint~=nil then actor.sprinting=clean.sprint end
 if clean.locked~=nil then actor.locked=clean.locked end
 if clean.action=="Move" then return true end
 -- The engine still validates state, resources, hitboxes and target.
 return self.combat:request(actor,clean.action,clean.aim,clean.clientTime)
end
function Match:finish(winner,reason)
 if self.phase~="Duel" then return end
 self.phase="Result";self.winner=winner;self.reason=reason
end
function Match:disconnect(player)
 if not self.byPlayer[player] then return false end
 self:finish(if self.players[1]==player then self.players[2] else self.players[1],"disconnect");return true
end
function Match:update(dt,now)
 if self.phase~="Duel" then return end
 for _,a in self.actors do if os.clock()-(a.lastMove or 0)>.4 then a.move=Vector3.zero end end
 self.combat:update(math.min(dt,.1),now)
end
return Match
