local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(intervalSeconds, now)
	assert(type(intervalSeconds) == "number" and intervalSeconds > 0, "intervalSeconds must be positive")

	return setmetatable({
		_interval = intervalSeconds,
		_now = now or os.clock,
		_lastByUserId = {},
	}, RateLimiter)
end

function RateLimiter:allow(player)
	local userId = player and player.UserId
	if type(userId) ~= "number" or userId <= 0 then
		return false
	end

	local current = self._now()
	local previous = self._lastByUserId[userId]
	if previous and current - previous < self._interval then
		return false
	end

	self._lastByUserId[userId] = current
	return true
end

function RateLimiter:forget(player)
	if player and type(player.UserId) == "number" then
		self._lastByUserId[player.UserId] = nil
	end
end

return RateLimiter
