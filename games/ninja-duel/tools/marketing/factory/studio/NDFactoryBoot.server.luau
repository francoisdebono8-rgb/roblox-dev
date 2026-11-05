--!nocheck
-- Ninja Duel content factory: the server's command channel (clip place only,
-- Studio only). Studio's Assistant runs execute_luau in a sandbox that may not
-- call the game's dev hooks; this Script, part of the clip place, does it for
-- the factory. Write a JSON command into workspace attribute NDRun, read the
-- answer in NDRunResult (a JSON string, or "error: ..."):
--   {"verb":"takes","n":4,"spec":{...}}    _G.NDShot.takes(spec, n)
--   {"verb":"scene","take":1,"spec":{...}} one take
--   {"verb":"logs"}  {"verb":"result"}     the take logs
--   {"verb":"dev","args":["place",[0,3,8],[0,3,-2]]}   any NinjaDuelDev op
-- In the spec and args, an array of exactly three numbers is a Vector3.
if not game:GetService("RunService"):IsStudio() then return end
local Http = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")
local F = SS:WaitForChild("NDFactory")
local dev = SS:WaitForChild("NinjaDuelDev", 30)
require(F:WaitForChild("ShotRunner"))
local function vec(t)
	if type(t) ~= "table" then return t end
	if #t == 3 and type(t[1]) == "number" and type(t[2]) == "number" and type(t[3]) == "number" then return Vector3.new(t[1], t[2], t[3]) end
	local out = {}
	for k, v in pairs(t) do out[k] = vec(v) end
	return out
end
local function plain(v, depth)
	depth = depth or 0
	if typeof(v) == "Vector3" then return {math.floor(v.X * 100) / 100, math.floor(v.Y * 100) / 100, math.floor(v.Z * 100) / 100} end
	if typeof(v) == "CFrame" then return plain(v.Position, depth) end
	if type(v) ~= "table" then
		if type(v) == "number" or type(v) == "string" or type(v) == "boolean" or v == nil then return v end
		return tostring(v)
	end
	if depth > 6 then return "..." end
	local out = {}
	for k, x in pairs(v) do out[tostring(k)] = plain(x, depth + 1) end
	return out
end
local function run(cmd)
	local verb = cmd.verb
	if verb == "takes" then return _G.NDShot.takes(vec(cmd.spec), cmd.n or 1)
	elseif verb == "scene" then return _G.NDShot.scene(vec(cmd.spec), cmd.take or 1)
	elseif verb == "logs" then return _G.NDShot.allLogs()
	elseif verb == "result" then return _G.NDShot.result()
	elseif verb == "flash" then return _G.NDShot.flash()
	elseif verb == "dev" then
		local args = vec(cmd.args or {})
		return Http:JSONEncode(plain(dev:Invoke(table.unpack(args, 1, #(cmd.args or {})))))
	end
	return "error: unknown verb " .. tostring(verb)
end
workspace:SetAttribute("NDRunResult", "ready")
workspace:GetAttributeChangedSignal("NDRun"):Connect(function()
	local raw = workspace:GetAttribute("NDRun")
	if type(raw) ~= "string" or raw == "" then return end
	workspace:SetAttribute("NDRun", "")
	local ok, res = pcall(function() return run(Http:JSONDecode(raw)) end)
	workspace:SetAttribute("NDRunResult", if ok then tostring(res) else "error: " .. tostring(res))
end)
