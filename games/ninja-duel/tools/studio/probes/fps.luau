local RS=game:GetService("RunService")
local n,t,maxdt=0,0,0
local c=RS.RenderStepped:Connect(function(dt) n+=1;t+=dt;if dt>maxdt then maxdt=dt end end)
task.wait(2)
c:Disconnect()
return string.format("frames=%d fps=%.1f maxdt=%.3f",n,n/math.max(t,1e-3),maxdt)
