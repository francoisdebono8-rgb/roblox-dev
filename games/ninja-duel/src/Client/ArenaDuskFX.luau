-- The Ōtsutsuki's arena at dusk (26/11, passe 3, DEV: « son arène de finale au
-- crépuscule »; François's reference: a crimson-violet sky, the pale moon with
-- three tomoe, braziers). The arena is the ANIMATEUR's model `final_arena`
-- (tools/blender/konoha_landmarks.py), on a unit the server tags Dress=
-- "final_arena" (Server/Hub, the DEV's place for it). While this screen's
-- camera is near it, the world's light (Shared/Look, Client/WorldLook) is
-- borrowed and turned to dusk, and the moon rises behind the torii; away from
-- it, the afternoon comes back. Presentation only, on this client.
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")

local Dusk={}
Dusk.MODEL="final_arena"
Dusk.NEAR=95     -- studs from the arena's centre where the dusk is full
Dusk.FAR=130     -- and where it lets go
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
-- the dusk's light (never black: DEC-044, the fighters stay readable)
Dusk.LIGHT={ClockTime=18.15,GeographicLatitude=32,Brightness=2.2,ExposureCompensation=.05,
	Ambient=rgb(104,78,98),OutdoorAmbient=rgb(130,96,120),ColorShift_Top=rgb(255,130,96),ColorShift_Bottom=rgb(90,70,130)}
Dusk.ATMOSPHERE={Density=.34,Offset=.2,Color=rgb(206,120,128),Decay=rgb(110,60,120),Glare=.4,Haze=1.4}
Dusk.GRADE={TintColor=rgb(255,226,226),Saturation=.3,Contrast=.16}
Dusk.MOON={color=rgb(232,226,240),tomoe=rgb(40,30,46),size=60,distance=420,height=150}

-- (pure) How much of the dusk at `distance` from the arena (0..1).
function Dusk.weight(distance)
	if type(distance)~="number" then return 0 end
	if distance<=Dusk.NEAR then return 1 end
	if distance>=Dusk.FAR then return 0 end
	return 1-(distance-Dusk.NEAR)/(Dusk.FAR-Dusk.NEAR)
end

-- The arena's centre: its unit's DressAt (Server/Hub tags it), nil while there is none.
function Dusk.find()
	for _,d in workspace:GetDescendants() do
		if d:IsA("Model") and (d:GetAttribute("Dress")==Dusk.MODEL or d:GetAttribute("LayoutModel")==Dusk.MODEL) then
			local at=d:GetAttribute("DressAt")
			if typeof(at)=="CFrame" then return at end
			local cf=d:GetPivot()
			return cf
		end
	end
	return nil
end

-- The moon: a pale disc with three tomoe, far behind the torii (the arena's -Z), facing it.
function Dusk.moon(at)
	local M=Dusk.MOON
	local f=Instance.new("Folder");f.Name="ArenaMoon"
	local pos=at.Position+at:VectorToWorldSpace(Vector3.new(0,0,-M.distance))+Vector3.new(0,M.height,0)
	local disc=Instance.new("Part")
	disc.Name="Moon";disc.Shape=Enum.PartType.Cylinder;disc.Anchored=true;disc.CanCollide=false;disc.CanQuery=false;disc.CanTouch=false
	disc.CastShadow=false;disc.Material=Enum.Material.Neon;disc.Color=M.color;disc.Size=Vector3.new(.5,M.size,M.size)
	disc.CFrame=CFrame.lookAt(pos,at.Position)*CFrame.Angles(0,math.pi/2,0)
	disc.Parent=f
	local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Right;gui.LightInfluence=0;gui.CanvasSize=Vector2.new(400,400)
	gui.Parent=disc
	for k=0,2 do
		local a=math.rad(90+k*120)
		local cx,cy=.5+math.cos(a)*.24,.5-math.sin(a)*.24
		local dot=Instance.new("Frame");dot.AnchorPoint=Vector2.new(.5,.5);dot.Position=UDim2.fromScale(cx,cy)
		dot.Size=UDim2.fromScale(.15,.15);dot.BackgroundColor3=M.tomoe;dot.BorderSizePixel=0;dot.Parent=gui
		local c=Instance.new("UICorner");c.CornerRadius=UDim.new(.5,0);c.Parent=dot
	end
	local ring=Instance.new("Frame");ring.AnchorPoint=Vector2.new(.5,.5);ring.Position=UDim2.fromScale(.5,.5);ring.Size=UDim2.fromScale(.5,.5)
	ring.BackgroundTransparency=1;ring.Parent=gui
	local rc=Instance.new("UICorner");rc.CornerRadius=UDim.new(.5,0);rc.Parent=ring
	local st=Instance.new("UIStroke");st.Thickness=6;st.Color=M.tomoe;st.Transparency=.35;st.Parent=ring
	f.Parent=workspace
	return f,disc
end

function Dusk.start()
	if Dusk.started then return end
	Dusk.started=true
	task.spawn(function()
		local okW,WorldLook=pcall(require,script.Parent.WorldLook)
		local okL,Look=pcall(require,game:GetService("ReplicatedStorage").NinjaDuel.Look)
		if not (okW and okL) then return end
		local at
		for _=1,60 do at=Dusk.find();if at then break end;task.wait(2) end
		if not at then return end
		local moonFolder,moon=Dusk.moon(at)
		local base=table.clone(Look.LIGHT)
		local baseAir=table.clone(Look.ATMOSPHERE)
		local held=false
		local acc=0
		RunService.Heartbeat:Connect(function(dt)
			acc+=dt
			if acc<.2 then return end
			acc=0
			local cam=workspace.CurrentCamera
			if not cam then return end
			local w=Dusk.weight((cam.CFrame.Position-at.Position).Magnitude)
			moon.Transparency=1-w
			for _,g in moon:GetChildren() do if g:IsA("SurfaceGui") then g.Enabled=w>.05 end end
			if w>0 then
				if not held then held=true;WorldLook.borrowed=true end
				for k,v in Dusk.LIGHT do
					local b=base[k]
					if typeof(v)=="Color3" and typeof(b)=="Color3" then Lighting[k]=b:Lerp(v,w)
					elseif type(v)=="number" and type(b)=="number" then Lighting[k]=b+(v-b)*w end
				end
				local atmo=Lighting:FindFirstChildOfClass("Atmosphere")
				if atmo then
					for k,v in Dusk.ATMOSPHERE do
						local b=baseAir[k]
						if typeof(v)=="Color3" and typeof(b)=="Color3" then atmo[k]=b:Lerp(v,w)
						elseif type(v)=="number" and type(b)=="number" then atmo[k]=b+(v-b)*w end
					end
				end
			elseif held then
				held=false
				WorldLook.borrowed=false
				pcall(WorldLook.apply)
			end
		end)
	end)
end

return Dusk
