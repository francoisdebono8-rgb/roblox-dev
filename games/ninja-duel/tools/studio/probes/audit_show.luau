-- Server (Debug build): the audit showcase (DEC-030, Partie 0). FIGHTER plays
-- every kind of move against a frozen dummy; workspace attribute NdPhase names
-- the move being shown (the client recorder audit_rec.luau stores it per frame).
-- Runs in the background: returns at once, NdPhase="done" at the end.
local FIGHTER="Lion"
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local Fighters=require(game.ReplicatedStorage.NinjaDuel.Fighters)
local def=Fighters[FIGHTER]
local opp=if FIGHTER=="Leaf" then "Flashstep" else "Leaf"
local function phase(n) workspace:SetAttribute("NdPhase",n) end
phase("setup")
dev:Invoke("start",FIGHTER,opp)
local t0=os.clock()
repeat task.wait(.2) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",true)
local function fresh(g)
	dev:Invoke("refill");dev:Invoke("health","human",900);dev:Invoke("health","bot",900)
	dev:Invoke("move","human",Vector3.zero);dev:Invoke("sprint","human",false)
	dev:Invoke("place",Vector3.new(0,3,g/2),Vector3.new(0,3,-g/2))
end
local function act(a,who)
	local s=dev:Invoke("state")
	local other=if who=="bot" then s.human else s.bot
	return dev:Invoke("act",who or "human",a,other and other.position)
end
task.spawn(function()
	fresh(7);task.wait(.8)
	phase("idle");task.wait(1.0)
	phase("run");dev:Invoke("move","human",Vector3.new(1,0,0));task.wait(1.2)
	phase("sprint");dev:Invoke("sprint","human",true);dev:Invoke("move","human",Vector3.new(-1,0,0));task.wait(1.2)
	dev:Invoke("move","human",Vector3.zero);dev:Invoke("sprint","human",false);task.wait(.6)
	fresh(7);task.wait(.4)
	phase("jump");act("Jump");task.wait(.15);act("JumpOff");task.wait(1.1)
	fresh(5);task.wait(.4)
	phase("chain");act("Attack");task.wait(.34);act("Attack");task.wait(.34);act("Attack");task.wait(1.1)
	fresh(5);task.wait(.5)
	phase("heavy");act("Heavy");task.wait(1.4)
	fresh(5);task.wait(.5)
	phase("air");act("Jump");task.wait(.22);act("Attack");task.wait(.3);act("JumpOff");act("Attack");task.wait(1.0)
	fresh(10);task.wait(.5)
	phase("tool");act("Tool");task.wait(1.1)
	for i,t in def.Techniques or {} do
		fresh(8);task.wait(.6)
		phase("T"..i..":"..t.Id);act("Technique"..i);task.wait(1.8)
		act("GuardOff")
	end
	fresh(5);task.wait(.5)
	phase("guard");act("Guard");task.wait(.15);act("Attack","bot");task.wait(.35);act("Attack","bot");task.wait(.8);act("GuardOff");task.wait(.3)
	fresh(5);task.wait(.5)
	phase("dodge");act("Dodge");task.wait(.9)
	fresh(5);task.wait(.5)
	phase("hit");act("Attack","bot");task.wait(.34);act("Attack","bot");task.wait(.34);act("Attack","bot");task.wait(.6);act("Heavy","bot");task.wait(2.2)
	phase("done")
end)
return "showing "..FIGHTER.." vs "..opp
