local ReceiptLedger = {}
ReceiptLedger.__index = ReceiptLedger

local KEY_PREFIX = "receipt:"

function ReceiptLedger.new(dataStoreService, storeName)
	local ok, store = pcall(function()
		return dataStoreService:GetDataStore(storeName or "BrickKitMonetizationReceiptsV1")
	end)

	return setmetatable({
		_store = ok and store or nil,
	}, ReceiptLedger)
end

function ReceiptLedger:check(purchaseId)
	if not self._store then
		return false, false, "Receipt DataStore is unavailable"
	end

	local ok, value = pcall(function()
		return self._store:GetAsync(KEY_PREFIX .. purchaseId)
	end)

	if not ok then
		return false, false, "Receipt lookup failed"
	end

	return true, value == true
end

function ReceiptLedger:markProcessed(purchaseId)
	if not self._store then
		return false, "Receipt DataStore is unavailable"
	end

	local ok = pcall(function()
		self._store:UpdateAsync(KEY_PREFIX .. purchaseId, function()
			return true
		end)
	end)

	if not ok then
		return false, "Receipt write failed"
	end

	return true
end

return ReceiptLedger
