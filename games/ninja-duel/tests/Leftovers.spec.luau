-- Small points of the QA test of b822ee5 (12/11): effect pieces and lights
-- still there 3 s after a round (23 pieces and a light after Kakashi-Itachi,
-- a light after Lee-Minato), and the intro's « BEGIN » shown over the
-- opponent alone, the player behind the lens. Headless: the client's own
-- bookkeeping and the lens's geometry; the look is a Studio check.
local H=require("./Harness")
local V=H.V
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end

test("the result screen takes the round's seal marks and burning patches with it",function()
	local instance,restore=H.stubScene()
	local ok,err=pcall(function()
		local FX=H.load("Client/Effects")
		local fx=FX.new()
		local folder=instance("Folder")
		-- Minato's seal riding on the bot's back (a light on him), a burning patch.
		local glyph=instance("Model");glyph.Name="Body seal";glyph.Parent=fx.folder
		local anchor=instance("Part");anchor.Parent=glyph
		local light=instance("PointLight");light.Parent=anchor
		fx.seals["PlayerFighter:7"]={glyph=glyph,anchor=anchor,light=light,body=true,born=0}
		local holder=instance("Part");holder.Parent=fx.folder
		local emitter=instance("ParticleEmitter");emitter.Enabled=true;emitter.Parent=holder
		local fire=instance("PointLight");fire.Brightness=2;fire.Parent=holder
		fx.hazards["fire:1.0:0.0:1.0"]={holder=holder,emitter=emitter,light=fire}
		-- The round is over: the server cleared it (no seals, no hazards, no zones).
		local result={phase="Result",epoch=3,human={id="PlayerFighter",seals={}},bot={id="AIFighter",seals={}},hazards={},zones={},projectiles={},bodies={}}
		fx:update(result,1/60,folder)
		assert(fx.seals["PlayerFighter:7"]==nil,"the seal mark (and its light) stayed on the result screen")
		assert(fx.hazards["fire:1.0:0.0:1.0"]==nil and emitter.Enabled==false,"the burning patch stayed on the result screen")
	end)
	restore()
	assert(ok,err)
end)

-- The intro, frame by frame at 60 fps (the server's 2.6 s): over the BEGIN
-- window (Config.IntroBegin) the player must be in front of the lens and
-- inside its view.
local clock=100
H.envBase.os=setmetatable({clock=function() return clock end},{__index=os})
local Camera=H.load("Client/Camera")
local Config=H.load("Shared/Config")
test("at BEGIN the lens has the player in the frame, not only the opponent",function()
	local camera=H.roblox.Instance.new("Camera")
	camera.CameraType=H.roblox.Enum.CameraType.Scriptable
	camera.FieldOfView=70;camera.ViewportSize=H.roblox.Vector2.new(1280,720);camera.CFrame=H.roblox.CFrame.new(0,10,30)
	H.workspace.CurrentCamera=camera
	local c,a,b=H.duel("Flashstep","Mirage")
	H.localPlayer.Character=a.model
	c:relocate(a,c.match.origin+V.new(0,3,Config.StartDistance));c:relocate(b,c.match.origin+V.new(0,3,-Config.StartDistance))
	a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position);b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
	local cam=Camera.new()
	local function actor(x)
		return {fighterId=x.fighterId,fighter=x.def.Name,health=x.health,state=x.state,airborne=false,speed=0,velocity=V.zero,impactSerial=0,position=x.root.Position,id=x.id}
	end
	local function inView(p)
		local cf=camera.CFrame
		local to=p-cf.Position
		if to.Magnitude<1 then return false end
		local angle=math.deg(math.acos(math.clamp(cf.LookVector:Dot(to.Unit),-1,1)))
		return angle<camera.FieldOfView*.5
	end
	local intro=2.6
	local begin,seen=0,0
	while intro>0 do
		clock+=1/60
		cam:update({phase="Duel",epoch=1,intro=intro,human=actor(a),bot=actor(b)},1/60)
		if intro<(Config.IntroBegin or .75) then
			begin+=1
			if inView(a.root.Position+V.new(0,1,0)) then seen+=1 end
		end
		intro-=1/60
	end
	assert(begin>0,"no BEGIN window")
	assert(seen/begin>=.9,string.format("the player is in the frame %d%% of the BEGIN window",math.floor(seen/begin*100)))
end)

print(string.format("NinjaDuel leftovers and intro (QA 12/11): %d PASS",passed))
