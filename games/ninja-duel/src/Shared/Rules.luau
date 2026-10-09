-- Pure policy shared by server combat and headless tests. Authority lives on server.
local Rules = {}
local free = { Neutral = true, Guarding = true }
function Rules.finite(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end
function Rules.canAct(a, now)
	return a.health > 0 and free[a.state] == true and now >= (a.lockUntil or 0)
end
function Rules.technique(a, spec, now, prerequisites)
	if not Rules.canAct(a, now) then return false, "Committed" end
	if (a.cooldowns[spec.Id] or 0) > now then return false, "Cooldown" end
	if a.chakra < spec.Cost then return false, "Need chakra" end
	if not prerequisites then return false, "Condition missing" end
	return true
end
function Rules.reserve(a, spec, now)
	a.chakra -= spec.Cost
	a.cooldowns[spec.Id] = now + spec.Cooldown
	a.state = "TechniqueChannel"
	a.untilTime = now + spec.Channel
end
function Rules.consumeToken(bucket, now, rate, burst)
	bucket.tokens = math.min(burst, bucket.tokens + math.max(0, now - bucket.time) * rate)
	bucket.time = now
	if bucket.tokens < 1 then return false end
	bucket.tokens -= 1
	return true
end
function Rules.interruptible(a)
	return a.state == "TechniqueChannel" and a.pending ~= nil and a.pending.spec.Interruptible == true
end
function Rules.isGuard(a, frontal)
	return a.state == "Guarding" and frontal and a.chakra > 0
end
return Rules
