-- Robux-Käufe: Kasse (Wiederbelebungen) und alle Shop-Produkte (Skins, Packs, Münzen,
-- Snacks, Starter Pack). Produkte mit ID 0 sind noch nicht im Creator Hub angelegt.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local ShopService = require(script.Parent.ShopService)

local Purchases = {}

function Purchases.init(notifyRemote)
	local productsById = {}
	for _, product in Config.PRODUCTS do
		if product.id ~= 0 then
			productsById[product.id] = product
		end
	end
	local shopHandlers = ShopService.productHandlers()

	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local product = productsById[receipt.ProductId]
		if product then
			local saved = PlayerData.grantPurchase(receipt.PlayerId, receipt.PurchaseId, product.field, product.amount)
			if not saved then
				-- Roblox fragt später erneut nach; der Spieler verliert nichts
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			if player then
				notifyRemote:FireClient(player, "Thanks for your purchase: " .. product.title .. "!")
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local handler = shopHandlers[receipt.ProductId]
		if handler then
			if not PlayerData.grantReceipt(receipt.PlayerId, receipt.PurchaseId, handler) then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			if player then
				notifyRemote:FireClient(player, "Thanks for your purchase!")
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return Purchases
