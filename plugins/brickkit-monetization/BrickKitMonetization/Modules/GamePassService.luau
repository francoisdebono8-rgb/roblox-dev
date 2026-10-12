local GamePassService = {}
GamePassService.__index = GamePassService

function GamePassService.new(marketplaceService, resolveReward, log)
	return setmetatable({
		_marketplace = marketplaceService,
		_resolveReward = resolveReward,
		_log = log or function() end,
	}, GamePassService)
end

function GamePassService:apply(player, entry)
	local checked, ownsPass = pcall(function()
		return self._marketplace:UserOwnsGamePassAsync(player.UserId, entry.id)
	end)

	if not checked then
		self._log("warn", "Game Pass ownership check failed for pass " .. tostring(entry.id))
		return false, "marketplace_error"
	end

	if not ownsPass then
		return true, "not_owned"
	end

	local reward = self._resolveReward(entry.rewardHandler)
	if not reward then
		return false, "unknown_handler"
	end

	local called, applied, rewardError = pcall(reward, player, entry.params)
	if not called or applied ~= true then
		self._log("warn", "Game Pass reward failed for pass " .. tostring(entry.id) .. ": " .. tostring(rewardError))
		return false, "reward_failed"
	end

	return true, "applied"
end

function GamePassService:applyAll(player, entries)
	for _, entry in ipairs(entries) do
		self:apply(player, entry)
	end
end

return GamePassService
