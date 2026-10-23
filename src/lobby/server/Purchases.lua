-- Robux-Käufe an der Kasse (Wiederbelebungen und Rebirths).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local Purchases = {}

function Purchases.init(notifyRemote)
	local productsById = {}
	for _, product in Config.PRODUCTS do
		if product.id ~= 0 then
			productsById[product.id] = product
		end
	end

	MarketplaceService.ProcessReceipt = function(receipt)
		local product = productsById[receipt.ProductId]
		if not product then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local saved, newValue = PlayerData.grantPurchase(receipt.PlayerId, receipt.PurchaseId, product.field, product.amount)
		if not saved then
			-- Roblox fragt später erneut nach; der Spieler verliert nichts
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if player then
			player:SetAttribute(product.field, newValue)
			notifyRemote:FireClient(player, "Danke für deinen Kauf: " .. product.title .. "!")
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Purchases
