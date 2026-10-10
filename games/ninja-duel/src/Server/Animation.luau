-- Optional authored R15 clip player. The full set is required so partial uploads
-- never fight procedural Motor6D posing. Server combat timing remains authoritative.
local Animation={}
Animation.Required={"Idle","Run","Strafe","Retreat","Jump","Fall","Land","Dash","AirDash","WallRun","WallJump",
	"Guard","Hit","Substitute","Attack1","Attack2","Attack3","Attack4","AirStrike","Pursuit",
	"TechniqueChannel","TechniqueRelease","TechniqueRecovery","Defeated","Heavy","Launcher","DashAttack","Air1","Air2","Slam","Grab","Throw","ThrowUp","Knockdown","Wakeup"}
function Animation.attach(a)
	local ids=a.def.AnimationIds
	if type(ids)~="table" then return false end
	for _,name in Animation.Required do
		if type(ids[name])~="number" or ids[name]<=0 then return false end
	end
	local animator=a.hum:FindFirstChildOfClass("Animator")
	if not animator then return false end
	local tracks,instances={},{}
	for _,name in Animation.Required do
		local asset=Instance.new("Animation"); asset.Name=name; asset.AnimationId="rbxassetid://"..ids[name]
		local ok,track=pcall(function() return animator:LoadAnimation(asset) end)
		if not ok then
			for _,created in instances do created:Destroy() end
			return false
		end
		track.Priority=if name=="Idle" or name=="Run" or name=="Strafe" or name=="Retreat" then Enum.AnimationPriority.Movement else Enum.AnimationPriority.Action
		tracks[name]=track;table.insert(instances,asset)
	end
	a.animation={tracks=tracks,instances=instances,current=nil}
	a.model:SetAttribute("AuthoredAnimations",true)
	return true
end
local function choose(a,now)
	if a.state=="Defeated" then return "Defeated" end
	if now<(a.subUntil or 0) then return "Substitute" end
	if now<(a.wallJumpUntil or 0) then return "WallJump" end
	if a.reaction=="Knockdown" then return "Knockdown" end
	if a.reaction=="Wakeup" then return "Wakeup" end
	if a.reaction or a.state=="Stunned" then return "Hit" end
	if a.state=="Dodging" then return if a.airborne then "AirDash" else "Dash" end
	if a.state=="Pursuit" then return "Pursuit" end
	if a.state=="Guarding" then return "Guard" end
	if a.state=="TechniqueChannel" then return "TechniqueChannel" end
	if a.state=="TechniqueActive" then return "TechniqueRelease" end
	if a.state=="TechniqueRecovery" then return "TechniqueRecovery" end
	if a.state=="Startup" or a.state=="Active" then
		if a.attackName then return a.attackName:gsub("^Light","Attack") end
		if a.pending and a.pending.air then return "AirStrike" end
		return "Attack"..math.clamp(a.combo,1,4)
	end
	if a.wall then return "WallRun" end
	if a.airborne then return if a.root.AssemblyLinearVelocity.Y>0 then "Jump" else "Fall" end
	if now<(a.landUntil or 0) then return "Land" end
	if a.locomotion.Magnitude<2 then return "Idle" end
	if a.locked then
		local direction=a.move:Dot(a.root.CFrame.LookVector)
		if direction< -0.35 then return "Retreat" end
		if math.abs(a.move:Dot(a.root.CFrame.RightVector))>0.5 then return "Strafe" end
	end
	return "Run"
end
function Animation.step(a,now)
	local player=a.animation
	if not player then return false end
	local name=choose(a,now)
	if player.current~=name then
		if player.current then player.tracks[player.current]:Stop(0.1) end
		player.current=name
		player.tracks[name]:Play(0.1)
	end
	if name=="Run" then player.tracks[name]:AdjustSpeed(math.clamp(a.locomotion.Magnitude/26,0.75,1.55)) end
	return true
end
function Animation.clear(a)
	local player=a.animation
	if not player then return end
	for _,track in player.tracks do track:Stop(0) end
	for _,asset in player.instances do asset:Destroy() end
	a.model:SetAttribute("AuthoredAnimations",nil)
	a.animation=nil
end
return Animation
