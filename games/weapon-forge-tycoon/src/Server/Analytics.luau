local Service=game:GetService('AnalyticsService')
local Run=game:GetService('RunService')
local Analytics={}
function Analytics.event(player,name,value)
 if Run:IsStudio() then return end
 task.spawn(function() local ok,err=pcall(function() Service:LogCustomEvent(player,name,value or 1) end); if not ok then warn('WFT analytics: '..tostring(err)) end end)
end
function Analytics.step(player,step,name)
 if Run:IsStudio() then return end
 task.spawn(function() pcall(function() Service:LogOnboardingFunnelStepEvent(player,step,name) end) end)
end
return Analytics
