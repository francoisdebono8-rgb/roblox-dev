-- Server Authority trial (12/11, lab only: nothing here is loaded by the game
-- or by build.py). One fighter, Sasuke's walk and the game's dodge, written
-- the Server Authority way:
--   * the same code runs on the server and on the client, in
--     RunService:BindToSimulation (the client predicts, the server decides,
--     a disagreement rolls the client back and replays its inputs);
--   * every input is an InputAction (the server trusts nothing else);
--   * every piece of state that must roll back is an attribute on the
--     predicted body (plain Luau variables do not roll back);
--   * time is the simulation's time(), not os.clock().
-- Values: Shared/Fighters Lion (Speed 19, AccelerationScale 1.12) and
-- Shared/Config (GroundAcceleration 170, GroundDeceleration 290,
-- TurnAcceleration 360, DodgeSpeed 61, DodgeTime 0.32, DodgeCooldown 0.8).
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")

local SATrial={}
SATrial.Tune={Walk=19,Accel=170*1.12,Decel=290*1.12,Turn=360*1.12,
	DodgeSpeed=61,DodgeTime=.32,DodgeCooldown=.8,DodgeExit=19}
SATrial.ContextName="SATrialInput"

local function flat(v:Vector3) return Vector3.new(v.X,0,v.Z) end
local function toward(current:Vector3,target:Vector3,step:number)
	local d=target-current
	if d.Magnitude<=step then return target end
	return current+d.Unit*step
end

-- The input context each player gets (cloned under the Player by the server).
-- Move: WASD / left stick (Direction2D). Dodge: Q / B button (Bool).
function SATrial.makeContext()
	local ctx=Instance.new("InputContext");ctx.Name=SATrial.ContextName
	local move=Instance.new("InputAction");move.Name="Move";move.Type=Enum.InputActionType.Direction2D;move.Parent=ctx
	local keys=Instance.new("InputBinding");keys.Name="Keys"
	keys.Up=Enum.KeyCode.W;keys.Down=Enum.KeyCode.S;keys.Left=Enum.KeyCode.A;keys.Right=Enum.KeyCode.D;keys.Parent=move
	local stick=Instance.new("InputBinding");stick.Name="Stick";stick.KeyCode=Enum.KeyCode.Thumbstick1;stick.Parent=move
	local dodge=Instance.new("InputAction");dodge.Name="Dodge";dodge.Type=Enum.InputActionType.Bool;dodge.Parent=ctx
	local q=Instance.new("InputBinding");q.Name="Key";q.KeyCode=Enum.KeyCode.Q;q.Parent=dodge
	local b=Instance.new("InputBinding");b.Name="Pad";b.KeyCode=Enum.KeyCode.ButtonB;b.Parent=dodge
	return ctx
end

-- One simulation step for one player's body. State on the root (attributes):
--   VX, VZ      ground velocity the controller asks for (our acceleration model)
--   DodgeWas    the Dodge button last step (a press is its rising edge)
--   DodgeUntil  end of the dodge (simulation time), 0 when none
--   DodgeReady  when the next dodge is allowed
--   DodgeX/Z    the dodge's direction
--   Dodges      dodges started (the probe compares client and server)
function SATrial.step(player:Player,dt:number)
	local char=player.Character
	local root=char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	local ctx=player:FindFirstChild(SATrial.ContextName)
	if not (root and hum and ctx) or hum.Health<=0 then return end
	local T=SATrial.Tune
	local now=time()
	local stick=(ctx :: any).Move:GetState() :: Vector2
	-- The trial camera looks along -Z: W is -Z, D is +X.
	local input=Vector3.new(stick.X,0,-stick.Y)
	if input.Magnitude>1 then input=input.Unit end
	local v=Vector3.new(root:GetAttribute("VX") or 0,0,root:GetAttribute("VZ") or 0)
	local pressed=(ctx :: any).Dodge:GetState()==true
	local was=root:GetAttribute("DodgeWas")==true
	local untilT=root:GetAttribute("DodgeUntil") or 0
	if pressed and not was and now>=(root:GetAttribute("DodgeReady") or 0) and now>=untilT then
		local dir=if input.Magnitude>.2 then input.Unit else flat(root.CFrame.LookVector).Unit
		root:SetAttribute("DodgeX",dir.X);root:SetAttribute("DodgeZ",dir.Z)
		untilT=now+T.DodgeTime
		root:SetAttribute("DodgeUntil",untilT)
		root:SetAttribute("DodgeReady",now+T.DodgeTime+T.DodgeCooldown)
		root:SetAttribute("Dodges",(root:GetAttribute("Dodges") or 0)+1)
	end
	root:SetAttribute("DodgeWas",pressed)
	if now<untilT then
		-- The dodge: a fixed burst along its direction, the stick does not steer it.
		v=Vector3.new(root:GetAttribute("DodgeX") or 0,0,root:GetAttribute("DodgeZ") or 0)*T.DodgeSpeed
	else
		if untilT>0 then
			-- Out of the dodge: the body keeps a walk's worth of its speed.
			if v.Magnitude>T.DodgeExit then v=v.Unit*T.DodgeExit end
			root:SetAttribute("DodgeUntil",0)
		end
		local target=input*T.Walk
		local accel=if target.Magnitude<.05 then T.Decel elseif v.Magnitude>.05 and v.Unit:Dot(target.Unit)<.45 then T.Turn else T.Accel
		v=toward(v,target,accel*dt)
	end
	root:SetAttribute("VX",v.X);root:SetAttribute("VZ",v.Z)
	hum.WalkSpeed=v.Magnitude
	hum:Move(if v.Magnitude>.01 then v.Unit else Vector3.zero,false)
end

function SATrial.Initialize()
	RunService:BindToSimulation(function(dt)
		for _,player in Players:GetPlayers() do SATrial.step(player,dt) end
	end)
end

return SATrial
