local CustomRewards = {}

-- Add game-specific handlers here only when the built-in handlers are insufficient.
-- A persistent handler should update the player's data and record receiptInfo.PurchaseId
-- in the same atomic transaction provided by the game's data system.
local handlers = {}

function CustomRewards.resolve(name)
	return handlers[name]
end

function CustomRewards.exists(name)
	return handlers[name] ~= nil
end

return CustomRewards
