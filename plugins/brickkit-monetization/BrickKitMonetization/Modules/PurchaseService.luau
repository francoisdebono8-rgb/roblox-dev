local RateLimiter = require(script.Parent.RateLimiter)

local PurchaseService = {}
PurchaseService.__index = PurchaseService

local function keyFor(productType, id)
	return productType .. ":" .. tostring(id)
end

function PurchaseService.new(marketplaceService, activeEntries, now)
	local entriesByKey = {}
	for _, entry in ipairs(activeEntries) do
		entriesByKey[keyFor(entry.type, entry.id)] = entry
	end

	return setmetatable({
		_marketplace = marketplaceService,
		_entriesByKey = entriesByKey,
		_purchaseLimiter = RateLimiter.new(1, now),
		_catalogLimiter = RateLimiter.new(2, now),
	}, PurchaseService)
end

function PurchaseService:getCatalog(player)
	if not self._catalogLimiter:allow(player) then
		return nil, "rate_limited"
	end

	local catalog = {}
	for _, entry in pairs(self._entriesByKey) do
		table.insert(catalog, {
			type = entry.type,
			id = entry.id,
			fallbackLabel = entry.fallbackLabel,
		})
	end

	return catalog
end

function PurchaseService:requestPurchase(player, productType, id)
	if not self._purchaseLimiter:allow(player) then
		return false, "rate_limited"
	end

	if type(productType) ~= "string" or type(id) ~= "number" or id % 1 ~= 0 then
		return false, "invalid_arguments"
	end

	local entry = self._entriesByKey[keyFor(productType, id)]
	if not entry then
		return false, "not_allowed"
	end

	local ok
	if entry.type == "DeveloperProduct" then
		ok = pcall(function()
			self._marketplace:PromptProductPurchase(player, entry.id)
		end)
	elseif entry.type == "GamePass" then
		ok = pcall(function()
			self._marketplace:PromptGamePassPurchase(player, entry.id)
		end)
	else
		return false, "not_allowed"
	end

	if not ok then
		return false, "marketplace_error"
	end

	return true
end

function PurchaseService:forget(player)
	self._purchaseLimiter:forget(player)
	self._catalogLimiter:forget(player)
end

return PurchaseService
