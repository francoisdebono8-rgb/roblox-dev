-- Client/UI behavior is intentionally deferred. This template only verifies that
-- the server-created endpoints exist for the future UI implementation.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("BrickKitMonetization")
remotes:WaitForChild("GetCatalog")
remotes:WaitForChild("RequestPurchase")
