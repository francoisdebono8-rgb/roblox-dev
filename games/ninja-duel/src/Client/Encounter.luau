-- (26/11, the CM's series « MY AVATAR VS THE 8 »: « la caméra du défi montre
-- l'avatar de dos pendant qu'il marche vers le prodige ») The encounter: while
-- the player attribute NinjaEncounter holds where an inspiration blocks the
-- street (Server/DevChallengeFilm, during his dare), the avatar walks up to
-- him and the lens frames him three-quarter front, the inspiration in the
-- frame, never from behind. Cleared (the duel begins): Roblox's own lens again.
local Players=game:GetService("Players")
local Encounter={}
Encounter.__index=Encounter
-- he stops this far before the inspiration (studs)
Encounter.STOP=7

function Encounter.new(hub)
	return setmetatable({hub=hub,target=nil,cam=nil},Encounter)
end
function Encounter.target()
	local ok,at=pcall(function() return Players.LocalPlayer:GetAttribute("NinjaEncounter") end)
	return if ok and typeof(at)=="Vector3" then at else nil
end
-- The shot: a little ahead of him and well to his side (three-quarter front,
-- never his back), looking along his way: his face, and who he walks to.
function Encounter.shot(at,target)
	local flat=Vector3.new(target.X-at.X,0,target.Z-at.Z)
	local dist=flat.Magnitude
	local dir=if dist>.1 then flat.Unit else Vector3.new(0,0,-1)
	local side=dir:Cross(Vector3.yAxis)
	local head=at+Vector3.new(0,1.6,0)
	local eye=head+dir*4+side*8+Vector3.new(0,1,0)
	return CFrame.lookAt(eye,head+dir*math.min(6,dist*.4)+Vector3.new(0,.2,0)),dir
end
-- Every frame of the walk: true while the encounter holds the lens.
function Encounter:step(dt,hum,root)
	local target=Encounter.target()
	local camera=workspace.CurrentCamera
	if not target or not root or not hum then
		if self.target then
			self.target=nil;self.cam=nil
			camera.CameraType=Enum.CameraType.Custom
			if hum then camera.CameraSubject=hum end
		end
		return false
	end
	local cf,dir=Encounter.shot(root.Position,target)
	if self.target~=target then
		self.target=target;self.cam=nil
		hum:MoveTo(Vector3.new(target.X,root.Position.Y,target.Z)-dir*Encounter.STOP)
	end
	camera.CameraType=Enum.CameraType.Scriptable
	self.cam=if self.cam then self.cam:Lerp(cf,math.min(1,dt*6)) else cf
	camera.CFrame=self.cam
	return true
end

return Encounter
