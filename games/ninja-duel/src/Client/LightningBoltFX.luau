--[[
	Procedural lightning, adapted from "Lightning Beams" by Quasiduck (Samy),
	https://github.com/SamyBlue/Lightning-Beams (MIT, copyright (c) 2020 Samy;
	the licence text is at the bottom of this file).

	What is kept: the bolt itself, the original's maths - control points along
	a cubic Bezier between two attachments, moved by layered Perlin noise
	(radius picked on a disk, so the zigzag is even all round the line), the
	thickness noise, the pulse that runs the bolt from Attachment0 to
	Attachment1 (a bolt can be drawn as it travels) and the dissipating end.

	What changes for Ninja Duel (VFX bible 06/11: anime, few layers, a little
	colour, never plain Neon parts):
	  * drawn with Beams, not Neon cylinders: one invisible anchor per bolt,
	    one attachment per point, two beams per segment - a thin white-hot core
	    and a coloured glow round it (the anime line: a pure stroke with its
	    colour bleeding out), both LightEmission 1, no part to light up flat;
	  * no 1000-part cache built at require: nothing exists before the first
	    bolt, and the frame loop disconnects itself when the last bolt is gone;
	  * a budget (MAX_BOLTS): past it the oldest bolt is dissipated, so a
	    Chidori held for seconds cannot pile up instances;
	  * each bolt is updated under pcall: a broken bolt is dropped, the frame
	    goes on (Effects must never stop drawing for an effect).
	The API stays the original's: LightningBolt.new(a0, a1, count), the same
	properties (CurveSize0/1, MinRadius/MaxRadius, Frequency, AnimationSpeed,
	Thickness, Min/MaxThicknessMultiplier, Min/MaxTransparency, PulseSpeed,
	PulseLength, FadeLength, Color = Color3 or ColorSequence), :Destroy(),
	:DestroyDissipate(time, strength). Attachments may be "fake" tables with
	WorldPosition and WorldAxis, as in the original. Added: GlowColor,
	GlowWidth (x Thickness), and LightningBolt.folder (where bolts are put).
]]
local LightningBolt={}
LightningBolt.__index=LightningBolt
LightningBolt.MAX_BOLTS=24
LightningBolt.folder=nil -- set by the user (Effects' FX folder); Terrain otherwise
LightningBolt.clock=os.clock -- (headless tests drive time)
local RunService=game:GetService("RunService")

local function CubicBezier(p,p0,p1,p2,p3)
	return p0*(1-p)^3+p1*3*p*(1-p)^2+p2*3*(1-p)*p^2+p3*p^3
end
-- See https://www.desmos.com/calculator/hg5h4fpfim (the original's pulse).
local function DiscretePulse(p,t,s,k,f,min,max)
	return math.clamp(k/(2*f)-math.abs((p-t*s+.5*k)/f),min,max)
end
local function ExtrudeCenter(p)
	return math.exp(-5000*(p-.5)^10)
end
local function NoiseBetween(x,y,z,min,max)
	return min+(max-min)*(math.noise(x,y,z)+.5)
end
LightningBolt.CubicBezier,LightningBolt.DiscretePulse,LightningBolt.ExtrudeCenter=CubicBezier,DiscretePulse,ExtrudeCenter
local offsetAngle=math.cos(math.rad(90))
local active={} -- the bolts alive, oldest first
local conn

local function seq(v) return NumberSequence.new(v) end
local function build(self,count)
	local anchor=Instance.new("Part")
	anchor.Name="LightningBolt";anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false
	anchor.CastShadow=false;anchor.Transparency=1;anchor.Size=Vector3.new(.05,.05,.05);anchor.CFrame=CFrame.new()
	self._Atts={}
	self._Core={}
	self._Glow={}
	for i=0,count do
		local a=Instance.new("Attachment");a.Parent=anchor
		self._Atts[i]=a
	end
	for i=1,count do
		local core=Instance.new("Beam")
		core.Attachment0,core.Attachment1=self._Atts[i-1],self._Atts[i]
		core.FaceCamera=true;core.Segments=1;core.LightEmission=1;core.LightInfluence=0;core.Transparency=seq(1)
		core.Parent=anchor
		local glow=core:Clone();glow.Attachment0,glow.Attachment1=self._Atts[i-1],self._Atts[i];glow.Parent=anchor
		self._Core[i],self._Glow[i]=core,glow
	end
	anchor.Parent=LightningBolt.folder or workspace.Terrain
	self._Anchor=anchor
end

local step -- forward
function LightningBolt.new(Attachment0,Attachment1,PartCount)
	local self=setmetatable({},LightningBolt)
	PartCount=PartCount or 30
	self.Enabled=true
	self.Attachment0,self.Attachment1=Attachment0,Attachment1
	self.CurveSize0,self.CurveSize1=0,0
	self.MinRadius,self.MaxRadius=0,2.4
	self.Frequency=1
	self.AnimationSpeed=7
	self.Thickness=1
	self.MinThicknessMultiplier,self.MaxThicknessMultiplier=.2,1
	self.MinTransparency,self.MaxTransparency=0,1
	self.PulseSpeed=2
	self.PulseLength=1000000
	self.FadeLength=.2
	self.Color=Color3.new(1,1,1)
	self.ColorOffsetSpeed=3
	self.GlowColor=Color3.fromRGB(120,180,255)
	self.GlowWidth=3.2
	self.SpaceCurveFunction=CubicBezier
	self.OpacityProfileFunction=DiscretePulse
	self.RadialProfileFunction=ExtrudeCenter
	self._N=PartCount
	self._StartT=LightningBolt.clock()
	self._RanNum=math.random()*100
	build(self,PartCount)
	table.insert(active,self)
	while #active>LightningBolt.MAX_BOLTS do
		local old=table.remove(active,1)
		old:_Free()
	end
	if not conn then conn=RunService.RenderStepped:Connect(function() step() end) end
	return self
end

function LightningBolt:_Free()
	self._Dead=true
	if self._Anchor then self._Anchor:Destroy();self._Anchor=nil end
end
function LightningBolt:Destroy()
	for i,b in active do if b==self then table.remove(active,i) break end end
	self:_Free()
end
-- Destroy after TimeLength seconds, the bolt thinning and spreading out.
function LightningBolt:DestroyDissipate(TimeLength,Strength)
	TimeLength=TimeLength or .2
	Strength=Strength or .5
	self._Dissipate={t0=LightningBolt.clock(),len=TimeLength,strength=Strength,
		start=self.MinTransparency,radius=self.MaxRadius,minRadius=self.MinRadius,minThick=self.MinThicknessMultiplier}
end

local function colorAt(self,p,t)
	if typeof(self.Color)=="Color3" then return self.Color end
	local t1=(self._RanNum+p-t*self.ColorOffsetSpeed)%1
	local kp=self.Color.Keypoints
	for i=1,#kp-1 do
		if kp[i].Time<=t1 and t1<=kp[i+1].Time then
			return kp[i].Value:Lerp(kp[i+1].Value,(t1-kp[i].Time)/math.max(1e-6,kp[i+1].Time-kp[i].Time))
		end
	end
	return kp[1].Value
end

local function update(self,now)
	local d=self._Dissipate
	if d then
		local k=(now-d.t0)/d.len
		if k>=1 then return false end
		self.MinThicknessMultiplier=d.minThick+(-2-d.minThick)*k
		self.MinTransparency=d.start+(1-d.start)*k
		self.MaxRadius=d.radius*(1+d.strength*k)
		self.MinRadius=d.minRadius+(self.MaxRadius-d.minRadius)*k
	end
	local t=now-self._StartT
	if t>=(self.PulseLength+1)/self.PulseSpeed then return false end
	local N=self._N
	if not self.Enabled then
		for i=1,N do self._Core[i].Transparency=seq(1);self._Glow[i].Transparency=seq(1) end
		return true
	end
	local a0,a1=self.Attachment0,self.Attachment1
	local p0,p3=a0.WorldPosition,a1.WorldPosition
	local p1,p2=p0+a0.WorldAxis*self.CurveSize0,p3-a1.WorldAxis*self.CurveSize1
	local spd,freq,ran=self.AnimationSpeed,self.Frequency,self._RanNum
	local minO,maxO=1-self.MaxTransparency,1-self.MinTransparency
	local prev=self.SpaceCurveFunction(0,p0,p1,p2,p3)
	local bez0=prev
	self._Atts[0].WorldPosition=prev
	for i=1,N do
		local p=i/N
		local input=(spd*-t)+freq*10*p-.2+ran*4
		local input2=5*((spd*.01*-t)/10+freq*p)+ran*4
		local noise0=NoiseBetween(5*input,1.5,5*.2*input2,0,.1*2*math.pi)+NoiseBetween(.5*input,1.5,.5*.2*input2,0,.9*2*math.pi)
		local noise1=NoiseBetween(3.4,input2,input,self.MinRadius,self.MaxRadius)*self.RadialProfileFunction(p)
		local thick=NoiseBetween(2.3,input2,input,self.MinThicknessMultiplier,self.MaxThicknessMultiplier)
		local bez1=self.SpaceCurveFunction(p,p0,p1,p2,p3)
		local nxt=bez1
		if i~=N and (bez1-bez0).Magnitude>1e-4 then
			nxt=(CFrame.lookAt(bez0,bez1)*CFrame.Angles(0,0,noise0)
				*CFrame.Angles(math.acos(math.clamp(NoiseBetween(input2,input,2.7,offsetAngle,1),-1,1)),0,0)*CFrame.new(0,0,-noise1)).Position
		end
		self._Atts[i].WorldPosition=nxt
		local opacity=self.OpacityProfileFunction(p,t,self.PulseSpeed,self.PulseLength,self.FadeLength,minO,maxO)
		local w=math.max(0,self.Thickness*thick*opacity)
		local core,glow=self._Core[i],self._Glow[i]
		if w<=0 or opacity<=0 then
			core.Transparency=seq(1);glow.Transparency=seq(1)
		else
			core.Width0,core.Width1=w,w
			core.Color=ColorSequence.new(colorAt(self,p,t))
			core.Transparency=seq(1-opacity)
			glow.Width0,glow.Width1=w*self.GlowWidth,w*self.GlowWidth
			glow.Color=ColorSequence.new(self.GlowColor)
			glow.Transparency=seq(math.min(1,.55+.45*(1-opacity)))
		end
		prev,bez0=nxt,bez1
	end
	return true
end

step=function()
	local now=LightningBolt.clock()
	for i=#active,1,-1 do
		local b=active[i]
		local ok,alive=pcall(update,b,now)
		if not ok or not alive or b._Dead then
			table.remove(active,i)
			b:_Free()
		end
	end
	if #active==0 and conn then conn:Disconnect();conn=nil end
end
LightningBolt.step=step
function LightningBolt.count() return #active end

-- A fake attachment (the original's tip): a point and an axis.
function LightningBolt.point(position,axis)
	return {WorldPosition=position,WorldAxis=axis or Vector3.yAxis}
end

return LightningBolt
--[[
MIT License

Copyright (c) 2020 Samy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
