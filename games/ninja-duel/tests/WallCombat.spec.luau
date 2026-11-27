-- On the walls and through them (27/11, François: « course latérale sur les
-- murs, une vraie adaptation au mur, qu'on puisse combattre sur les murs à la
-- perpendiculaire ; je veux des dégâts de combat, les maisons se cassent lors
-- des combats en ville »). Headless: the duel's stand on a wall (Server/Motor),
-- the strings fought there, the leap off; a house's wall broken through
-- (Server/WorldReaction.breach, Client/HouseBreakFX); the walker's run along a
-- wall and his stand on it (Client/HubMove). The look of it is a Studio check.
local H=require("./Harness")
local roblox=require("@lune/roblox")
local CFrame,Vector3=roblox.CFrame,roblox.Vector3
local Instance,Enum=roblox.Instance,roblox.Enum
local V=H.V
local Motor=H.load("Server/Motor")
local Config=H.load("Shared/Config")
local passed=0
local function test(name,fn)
	H.clearWalls()
	local ok,err=pcall(fn)
	H.clearWalls()
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function near(a,b,eps) return (a-b).Magnitude<=(eps or 1e-3) end

test("the stick on a wall: into it up, away from it down, sideways along it",function()
	local n=V.new(-1,0,0)
	assert(near(Motor.wallStick(V.new(1,0,0),n),V.new(0,1,0)),"into the wall is not up")
	assert(near(Motor.wallStick(V.new(-1,0,0),n),V.new(0,-1,0)),"away from the wall is not down")
	local side=Motor.wallStick(V.new(0,0,1),n)
	assert(math.abs(side.Y)<1e-3 and math.abs(math.abs(side.Z)-1)<1e-3,"sideways is not along the wall")
	assert(Motor.wallStick(V.zero,n).Magnitude==0,"no stick, a walk")
	-- the look on the wall: toward the opponent laid on it, else up it
	assert(near(Motor.wallLook(n,V.new(0,10,0),V.new(-5,10,6)),V.new(0,0,1)),"the look is not laid on the wall")
	assert(near(Motor.wallLook(n,V.new(0,10,0),nil),V.new(0,1,0)),"no opponent: up the wall")
end)

local function onWall(fighter)
	H.addWall(10)
	local c,a,b=H.duel(fighter or "Leaf","Mirage")
	c:relocate(a,V.new(8,3,0));c:relocate(b,V.new(-60,3,60))
	a.playerInput=true
	a.move=V.zero;H.step(c,.01)
	a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+V.new(1,0,0))
	a.locomotion=V.new(30,0,0);a.move=V.new(1,0,0)
	H.step(c,.01)
	assert(a.wall,"no run up the wall")
	for _=1,300 do H.step(c,.01);if a.wall and a.wall.mode=="stand" then break end end
	return c,a,b
end

test("a run up a wall that runs out with the stick still into it stands on it, at a right angle",function()
	local c,a=onWall()
	assert(a.wall and a.wall.mode=="stand","it did not stand on the wall: "..tostring(a.wall and a.wall.mode))
	H.step(c,.05)
	assert(a.root.CFrame.UpVector.X<-.9,"the body's up is not the wall's normal: "..tostring(a.root.CFrame.UpVector))
	assert(a.root.Position.X<10 and a.root.Position.X>10-Motor.standHeight(a)-.5,"the feet are not on the wall")
	assert(a.airborne==false,"standing on the wall is not standing")
	-- the stick still into it: it walks up it
	local y=a.root.Position.Y
	H.step(c,.3)
	assert(a.root.Position.Y>y+2,"the stick into the wall does not walk up it")
	-- the stick let go: it holds there
	a.move=V.zero;H.step(c,.1);y=a.root.Position.Y
	H.step(c,.5)
	assert(a.wall and math.abs(a.root.Position.Y-y)<.3,"standing still, it slides on the wall")
end)

test("on the wall the string is fought there, then the jump leaps off it upright",function()
	local c,a=onWall()
	a.move=V.zero
	assert(c:request(a,"Attack"),"no strike on the wall")
	H.step(c,.05)
	assert(a.wall and a.wall.mode=="stand","the strike threw it off the wall")
	assert(a.attackName=="Light1","the strike on the wall is not the string's: "..tostring(a.attackName))
	H.step(c,.5)
	assert(a.wall and a.root.CFrame.UpVector.X<-.9,"after the strike the body is no longer on the wall")
	c:request(a,"Jump")
	assert(not a.wall,"the jump did not leave the wall")
	assert(a.root.CFrame.UpVector.Y>.9,"off the wall the body is not upright")
	assert(a.hum.PlatformStand~=true,"off the wall its own physics are not back")
end)

test("a house's wall breaks through under a heavy blow, the hole grows, a light blow only knocks",function()
	local WorldReaction=H.load("Server/WorldReaction")
	local stage=Instance.new("Folder")
	local feed={}
	local c={match={folder=stage},now=0,pushImpact=function(_,at,style,heavy,extra) table.insert(feed,{at=at,style=style,extra=extra}) end}
	local wall=Instance.new("Part");wall.Name="Solid1";wall.Size=Vector3.new(2,14,20);wall.CFrame=CFrame.new(0,7,0)
	wall.Material=Enum.Material.Plaster;wall.Transparency=1;wall:SetAttribute("WorldMaterial","house");wall.Parent=stage
	local light=WorldReaction.impact(c,{part=wall,position=Vector3.new(1,5,0),normal=Vector3.new(1,0,0),energy=20,contact="blunt"})
	assert(not (light and light.breach),"a light blow broke a house")
	local r=WorldReaction.impact(c,{part=wall,position=Vector3.new(1,5,0),normal=Vector3.new(1,0,0),energy=70,contact="blunt",direction=Vector3.new(-1,0,0)})
	assert(r and r.breach,"a heavy blow did not break through")
	local hole=r.breach
	assert(hole.part and hole.part.Name=="Breach" and hole.part.Parent~=nil,"the hole is not drawn")
	assert(feed[#feed].style=="housebreak" and feed[#feed].extra.size==hole.size,"the client is not told")
	local first=hole.size
	local again=WorldReaction.impact(c,{part=wall,position=Vector3.new(1,5.5,.5),normal=Vector3.new(1,0,0),energy=60,contact="blunt"})
	assert(again.breach==hole and hole.size>first,"a second blow next to it did not make it bigger")
	assert(wall.Parent==stage and wall.Size==Vector3.new(2,14,20),"the wall's own part changed")
	-- never more than Count holes, the oldest goes (and never the wall with it)
	for k=1,Config.World.Breach.Count+3 do
		WorldReaction.impact(c,{part=wall,position=Vector3.new(1,5,-9+k*1.4+20),normal=Vector3.new(1,0,0),energy=40,contact="blunt"})
	end
	assert(#WorldReaction.state(c).breaches<=Config.World.Breach.Count,"too many holes")
	assert(wall.Parent==stage,"an old hole took the wall with it")
end)

test("what flies out of the hole: plaster, boards, tiles from high up, more for a bigger hole",function()
	local House=H.load("Client/HouseBreakFX")
	local function rng() local x=.37 return {NextNumber=function() x=(x*9301+.49297)%1 return x end} end
	local small=House.pieces(3.2,V.new(1,0,0),V.new(-1,0,0),rng(),false)
	local big=House.pieces(7,V.new(1,0,0),V.new(-1,0,0),rng(),true)
	assert(#big>#small and #small>=10,"the burst does not grow with the hole")
	local kinds={}
	for _,p in big do kinds[p.kind]=true;assert(p.velocity.X>0,"a piece flies into the wall") end
	assert(kinds.plaster and kinds.board and kinds.tile,"missing pieces: "..table.concat((function() local t={} for k in kinds do table.insert(t,k) end return t end)(),","))
end)

test("the walker: along a wall he runs on it, the jump kicks off it; a stand on it, the kick off",function()
	local Move=H.load("Client/HubMove")
	local m=Move.new()
	local wall={normal=V.new(-1,0,0),part={}}
	-- straight into it: that is the run up it, not along
	assert(Move.sideStart(m,0,{wall=wall,dir=V.new(1,0,0),speed=30,air=true})==nil,"straight in ran along")
	local v=Move.sideStart(m,0,{wall=wall,dir=V.new(.3,0,1).Unit,speed=30,air=true})
	assert(v and v.Z>30 and v.Y>0,"no run along the wall")
	assert(m.side.side==1 or m.side.side==-1)
	local v2,what=Move.sideStep(m,.3,{wall=wall})
	assert(what=="run" and v2.Z>0,"the run along stopped")
	local _,spent=Move.sideStep(m,5,{wall=wall})
	assert(spent=="spent" and m.side==nil and m.leapUsed==false,"the run along never ends")
	assert(Move.sideStart(m,5.1,{wall=wall,dir=V.new(.3,0,1).Unit,speed=30,air=true})==nil,"twice on one jump")
	Move.landed(m)
	assert(Move.sideStart(m,6,{wall=wall,dir=V.new(.3,0,1).Unit,speed=30,air=true}),"the ground did not give it back")
	local kick=Move.sideKick(m,6.2)
	assert(kick and kick.X<0 and kick.Y>0,"the kick off a run along")
	-- standing on it
	Move.standStart(m,7,wall,1)
	assert(m.stand and near(m.stand.look,V.new(0,1,0)),"no stand on the wall")
	assert(near(Move.wallStick(V.new(1,0,0),wall.normal),V.new(0,1,0)),"the walker's stick into the wall is not up")
	local off=Move.standKick(m,7.5)
	assert(off and off.X<0 and m.stand==nil,"no kick off the wall he stood on")
end)

print(("WallCombat: %d passed"):format(passed))
