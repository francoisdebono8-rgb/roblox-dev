-- The duel lens as a pad player feels it (05/11, user: "pour la partie caméra
-- elle est vraiment pas bonne, on sent qu'elle bascule entre 2"): one rig whose
-- changes slide instead of cutting. On a pad the free lens keeps the opponent
-- in view by itself; the right stick borrows it and gives it back; the R3 lock
-- and the framing modes (launcher, chase, wall) ease from one to the other.
-- Real Camera module on harness rigs, a scripted clock; the screen is checked
-- in Studio.
local H=require("./Harness")
local V=H.V
local clock=100
H.envBase.os=setmetatable({clock=function() return clock end},{__index=os})
local passed=0
-- CALIBRATE=true prints the measures and runs every test (to compare builds).
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name)
	else print("FAIL "..name..": "..tostring(err));if not CALIBRATE then error(name..": "..tostring(err),0) end end
end
local function data(a,b,extra)
	local function actor(x)
		return {fighterId=x.fighterId,fighter=x.def.Name,health=x.health,state=x.state,airborne=x.airborne,reaction=x.reaction,
			attackName=x.attackName,wall=x.wall~=nil,speed=0,velocity=V.zero,impactSerial=0,position=x.root.Position,id=x.id}
	end
	local d={phase="Duel",epoch=1,human=actor(a),bot=actor(b)}
	for k,v in extra or {} do d[k]=v end
	return d
end
local function makeCamera()
	local camera=H.roblox.Instance.new("Camera")
	camera.CameraType=H.roblox.Enum.CameraType.Scriptable
	camera.FieldOfView=70
	camera.ViewportSize=H.roblox.Vector2.new(1280,720)
	camera.CFrame=H.roblox.CFrame.new(0,10,30)
	H.workspace.CurrentCamera=camera
	return camera
end
local function place(c,a,b,gap)
	c:relocate(a,c.match.origin+V.new(0,3,gap/2))
	c:relocate(b,c.match.origin-V.new(0,3,gap/2))
	a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
	b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
end
-- The angle between where the lens looks (flat) and the opponent.
local function offYaw(cam,a,b)
	local look=camera.CFrame.LookVector*V.new(1,0,1)
	local to=(b.root.Position-camera.CFrame.Position)*V.new(1,0,1)
	return math.deg(math.acos(math.clamp(look.Unit:Dot(to.Unit),-1,1)))
end
-- What Client/Presentation gives the lens: the drawn bodies (the roots here)
-- and the stick's direction.
local function presentation(dir)
	return {inputDir=dir,visualRoot=function() return nil end,visualVelocity=function() return nil end}
end
-- How far the lens's heading is from straight behind the player toward the
-- opponent (degrees): what decides whether he is in view.
local function offYaw(cam,a,b)
	local behind=(a.root.Position-b.root.Position)*V.new(1,0,1)
	local line=math.atan2(behind.Unit.X,behind.Unit.Z)
	local d=((cam.boomAngle-line)+math.pi)%(2*math.pi)-math.pi
	return math.abs(math.deg(d))
end
local Camera=H.load("Client/Camera")
local camera=makeCamera()
local function setup(gap)
	local c,a,b=H.duel("Flashstep","Mirage")
	H.localPlayer.Character=a.model
	place(c,a,b,gap or 9)
	return c,a,b,Camera.new()
end
-- Frames at 60 fps; returns the largest jolt of the lens (the change of its
-- per-frame velocity, studs per frame) and of its field of view.
local function run(cam,a,b,frames,extra,each)
	local worstJolt,worstFov,lastPos,lastVel,lastFov=0,0,nil,nil,nil
	for f=1,frames do
		if each then each(f) end
		clock+=1/60
		cam:update(data(a,b,extra),1/60)
		local p=camera.CFrame.Position
		if lastPos then
			local vel=p-lastPos
			if lastVel then worstJolt=math.max(worstJolt,(vel-lastVel).Magnitude) end
			lastVel=vel
			worstFov=math.max(worstFov,math.abs(camera.FieldOfView-lastFov))
		end
		lastPos=p;lastFov=camera.FieldOfView
	end
	return worstJolt,worstFov
end

test("pad, free: an opponent off to the side comes back into view by itself, running or not",function()
	local _,a,b,cam=setup(10)
	run(cam,a,b,30,{gamepad=true})
	cam.yaw+=math.rad(100);cam.lastLookInput=clock-5
	cam.presentation=presentation(V.new(1,0,0))
	run(cam,a,b,30,{gamepad=true})
	assert(offYaw(cam,a,b)<60,("still %.0f degrees off after half a second"):format(offYaw(cam,a,b)))
	run(cam,a,b,60,{gamepad=true})
	assert(offYaw(cam,a,b)<30,("still %.0f degrees off after 1.5 s"):format(offYaw(cam,a,b)))
	-- inside the dead zone the lens holds still (no constant swaying)
	run(cam,a,b,60,{gamepad=true})
	b.root.CFrame=b.root.CFrame+V.new(-1.2,0,0)
	run(cam,a,b,10,{gamepad=true})
	local yaw=cam.yaw
	run(cam,a,b,30,{gamepad=true})
	assert(math.abs(cam.yaw-yaw)<math.rad(2),"the lens swayed inside its dead zone")
	cam.presentation=nil
end)

test("pad: the right stick borrows the lens, and let go it comes back gently",function()
	local _,a,b,cam=setup(10)
	run(cam,a,b,30,{gamepad=true})
	cam.look=H.roblox.Vector2.new(1,0)
	run(cam,a,b,45,{gamepad=true})
	cam.look=H.roblox.Vector2.new(0,0)
	local off=offYaw(cam,a,b)
	assert(off>50,("the stick did not turn the lens away (%.0f)"):format(off))
	-- held off for a beat: the stick's choice is respected
	run(cam,a,b,24,{gamepad=true})
	assert(offYaw(cam,a,b)>off-12,"the follow snatched the lens back at once")
	local jolt=run(cam,a,b,120,{gamepad=true})
	if CALIBRATE then print(("  stick return jolt %.3f"):format(jolt)) end
	assert(offYaw(cam,a,b)<30,("the follow did not come back (%.0f)"):format(offYaw(cam,a,b)))
	assert(jolt<.12,("the follow came back with a jolt of %.2f"):format(jolt))
end)

test("mouse, free: no help while the player moves; eased in when he stands",function()
	local _,a,b,cam=setup(10)
	run(cam,a,b,30,{})
	cam.yaw+=math.rad(90);cam.lastLookInput=clock-5
	cam.presentation=presentation(V.new(1,0,0))
	run(cam,a,b,60,{})
	assert(offYaw(cam,a,b)>70,"the mouse lens turned while the player was moving")
	cam.presentation=presentation(V.zero)
	local jolt=run(cam,a,b,150,{})
	if CALIBRATE then print(("  mouse help jolt %.3f"):format(jolt)) end
	assert(offYaw(cam,a,b)<40,("the standing help did not bring him back (%.0f)"):format(offYaw(cam,a,b)))
	assert(jolt<.12,("the standing help started with a jolt of %.2f"):format(jolt))
	cam.presentation=nil
end)

test("the lock toggle and back slide, they do not cut between two cameras",function()
	local _,a,b,cam=setup(9)
	run(cam,a,b,40,{gamepad=true})
	cam:setLocked(true)
	local j1,f1=run(cam,a,b,60,{gamepad=true})
	cam:setLocked(false)
	local j2,f2=run(cam,a,b,60,{gamepad=true})
	if CALIBRATE then print(("  toggle jolt %.3f %.3f fov %.2f %.2f"):format(j1,j2,f1,f2)) end
	assert(math.max(j1,j2)<.08,("the toggle jolted the lens %.2f"):format(math.max(j1,j2)))
	assert(math.max(f1,f2)<.5,("the toggle jumped the field of view %.2f in a frame"):format(math.max(f1,f2)))
end)

test("locked: a launcher, the chase and the landing ease the framing instead of switching it",function()
	local c,a,b,cam=setup(6)
	cam:setLocked(true)
	run(cam,a,b,40,{})
	local worstJolt,worstFov=0,0
	local function sequence(state)
		b.reaction=state.reaction;b.airborne=state.airborne;a.state=state.astate or "Neutral";a.airborne=state.aair
		local j,f=run(cam,a,b,state.frames,{})
		worstJolt=math.max(worstJolt,j);worstFov=math.max(worstFov,f)
	end
	sequence({reaction="Launched",airborne=true,frames=18})
	sequence({reaction="Hitstun",airborne=true,astate="Pursuit",aair=true,frames=24})
	sequence({reaction=nil,airborne=false,frames=40})
	sequence({reaction="Launched",airborne=true,frames=18})
	sequence({reaction=nil,airborne=false,frames=60})
	if CALIBRATE then print(("  framing jolt %.3f fov %.2f"):format(worstJolt,worstFov)) end
	assert(worstJolt<.08,("the framing jolted the lens %.2f"):format(worstJolt))
	assert(worstFov<.5,("the framing jumped the field of view %.2f in a frame"):format(worstFov))
	local _=c
end)

print(("CameraFeel: %d passed"):format(passed))
