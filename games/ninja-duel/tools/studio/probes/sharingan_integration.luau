--!nocheck
-- Studio (Server, ND-DEV): the interactions of the Sharingan integration
-- (07/11, issue #45) played with the dev hooks, one scene per call:
--   local probe=require(this) ; probe.run("crowd")
-- Scenes: crowd, byakugan, copy, hounds, water, wire, clash, chase. Each
-- returns what the server saw (events, bodies, reactions); the look is read
-- on the screen captures taken between the calls.
local SS=game:GetService("ServerStorage")
local dev=SS:WaitForChild("NinjaDuelDev",10)
local P={}
local function call(...) return dev:Invoke(...) end
local function state() return call("state") end
local function ev(who,name)
	local st=state();local side=if who=="bot" then st.botEvents else st.events
	return (side and side[name]) or 0
end
local function duel(human,bot,gap)
	call("start",human,bot,true)
	task.wait(1.2)
	call("freezeBot",true)
	call("refill")
	call("place",Vector3.new(0,3,(gap or 12)/2),Vector3.new(0,3,-(gap or 12)/2))
	task.wait(.3)
end
local function act(who,name,aim,opts) return call("act",who,name,aim,opts) end
function P.run(scene)
	local out={scene=scene}
	if scene=="crowd" then
		duel("Legion","Flashstep",12)
		out.cast=act("human","Technique3")
		task.wait(1.4)
		out.clonesBefore=ev("human","BodySpawned")
		out.switch=act("human","Technique3")
		task.wait(.4)
		out.switched=ev("human","BodySwitch")+ev("human","Switch")
	elseif scene=="byakugan" then
		duel("GentleFist","Mirage",12)
		out.sight=act("human","Technique4")
		task.wait(.3)
		out.mirage=act("bot","Technique3")
		task.wait(.8)
	elseif scene=="copy" then
		duel("Copycat","Mirage",14)
		out.fireball=act("bot","Technique2")
		task.wait(1.6)
		out.copied=ev("human","Copied")
		out.cast=act("human","Technique1")
		task.wait(.6)
		out.copyCast=ev("human","CopyCast")
	elseif scene=="hounds" then
		duel("Copycat","Lion",12)
		out.fang=act("human","Technique3")
		task.wait(.9)
	elseif scene=="water" then
		duel("Copycat","Flashstep",12)
		out.dragon=act("human","Technique1")
		task.wait(1.4)
		out.blade=act("human","Technique2")
		task.wait(.8)
	elseif scene=="wire" then
		duel("Lion","Mirage",12)
		out.wire=act("human","Technique3")
		task.wait(.9)
		out.flame=act("human","Technique1")
		task.wait(.8)
	elseif scene=="clash" then
		duel("Legion","Lion",9)
		call("freezeBot",false)
		out.rasengan=act("human","Technique2")
		out.chidori=act("bot","Technique2")
		task.wait(1.5)
	elseif scene=="chase" then
		duel("Flashstep","Mirage",5.5)
		for _=1,2 do act("human","Attack");task.wait(.3) end
		out.launch=act("human","Heavy");task.wait(.35)
		out.pursuit=act("human","Pursuit")
		out.attack1=act("human","Attack");task.wait(.3)
		out.attack2=act("human","Attack");task.wait(.3)
		out.slam=act("human","Heavy");task.wait(.6)
		out.airHits=ev("human","AirHit");out.slamHit=ev("human","SlamHit")
	end
	local st=state()
	out.human={hp=st.human and st.human.health,state=st.human and st.human.state}
	out.bot={hp=st.bot and st.bot.health,state=st.bot and st.bot.state,reaction=st.bot and st.bot.reaction}
	return out
end
return P
