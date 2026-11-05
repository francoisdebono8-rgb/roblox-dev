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
CALIBRATE=CALIBRATE or (require("@lune/process").env.CALIBRATE~=nil)
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

-- (FEEL 05/11, AVANT report) The two lens defects measured in Studio.
-- Where a point is on the screen: inside the frame (with the given margin, in
-- degrees) or not.
local function onScreen(p,margin)
	local v=camera.CFrame:PointToObjectSpace(p)
	if -v.Z<.5 then return false end
	local halfV=math.rad(camera.FieldOfView*.5-(margin or 0))
	local aspect=camera.ViewportSize.X/camera.ViewportSize.Y
	local halfH=math.atan(math.tan(math.rad(camera.FieldOfView*.5))*aspect)-math.rad(margin or 0)
	return math.abs(math.atan2(v.Y,-v.Z))<=halfV and math.abs(math.atan2(v.X,-v.Z))<=halfH
end

test("keepInFrame: nothing to do for a body in frame; a body far above tilts and widens",function()
	local cf=H.C.lookAt(V.new(0,8,20),V.new(0,4,0))
	local tilt,widen=Camera.keepInFrame(cf,68,V.new(0,6,0),V.new(0,0,0))
	assert(tilt==0 and widen==0,"a body in frame moved the lens")
	tilt,widen=Camera.keepInFrame(cf,68,V.new(0,60,0),V.new(0,0,0))
	assert(tilt>0,"no tilt for a body 60 studs up")
	assert(tilt<=.6 and widen<=16,"the keeper went past its caps")
end)

test("locked: Neji's chakra launcher (66 studs up) keeps the opponent in frame",function()
	local _,a,b,cam=setup(6)
	cam:setLocked(true)
	run(cam,a,b,40,{})
	-- The flight (Studio take 1: 2.44 s, peak ~66 studs over the floor).
	b.reaction="Launched";b.airborne=true
	local off=0
	for f=1,150 do
		local t=f/60
		local y=math.max(0,58*t*1.6-0.5*48*t*t*1.6)
		b.root.CFrame=H.C.new(b.root.Position.X,3+y,b.root.Position.Z)
		run(cam,a,b,1,{})
		if not onScreen(b.root.Position+V.new(0,2.6,0),1) then off+=1 end
	end
	if CALIBRATE then print(("  launcher: opponent off screen %d of 150 frames"):format(off)) end
	assert(off<=15,("the opponent left the frame for %d of 150 frames"):format(off))
	assert(onScreen(a.root.Position,0),"the player left the frame")
end)

test("locked, back to the arena wall: the lens swings along it and keeps the player in view",function()
	local _,a,b,cam=setup(10)
	-- The wall on +X just behind the player, the opponent toward -X.
	local wall=H.addWall(12)
	a.root.CFrame=H.C.lookAt(V.new(10,3,0),V.new(-10,3,0))
	b.root.CFrame=H.C.lookAt(V.new(-10,3,0),V.new(10,3,0))
	cam:setLocked(true)
	run(cam,a,b,120,{})
	local seen=onScreen(a.root.Position+V.new(0,1,0),2)
	local side=camera.CFrame.Position.X
	H.clearWalls()
	local _=wall
	if CALIBRATE then print(("  wall: player on screen %s, lens x %.1f, swing %.2f"):format(tostring(seen),side,cam.wallYaw or 0)) end
	assert(side<12,"the lens went through the wall")
	assert(seen,"the player is still off screen with his back to the wall")
	assert(onScreen(b.root.Position,2),"the swing lost the opponent")
end)

test("pad, free, backed into the arena wall: the lens swings along it too",function()
	local _,a,b,cam=setup(10)
	H.addWall(12)
	a.root.CFrame=H.C.lookAt(V.new(10,3,0),V.new(-10,3,0))
	b.root.CFrame=H.C.lookAt(V.new(-10,3,0),V.new(10,3,0))
	run(cam,a,b,150,{gamepad=true})
	local seen=onScreen(a.root.Position+V.new(0,1,0),2)
	local side=camera.CFrame.Position.X
	H.clearWalls()
	if CALIBRATE then print(("  free pad wall: player on screen %s, lens x %.1f, swing %.2f"):format(tostring(seen),side,cam.wallYaw or 0)) end
	assert(side<12,"the lens went through the wall")
	assert(seen,"free on a pad, the player is still off screen with his back to the wall")
	assert(onScreen(b.root.Position,2),"free on a pad, the swing lost the opponent")
end)

print(("CameraFeel: %d passed"):format(passed))
