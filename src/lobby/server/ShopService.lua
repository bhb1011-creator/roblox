-- Server-Seite des Shops: Kaufen mit Münzen, Anziehen (Skins), Gamepässe und Robux-Produkte.
-- Der Server prüft alles selbst (Preis, Besitz, Münzen) – der Client schickt nur die ID.
--   ReplicatedStorage.ShopRemotes.BuyWithCoins:InvokeServer(id)    -> ok, Nachricht
--   ReplicatedStorage.ShopRemotes.Equip:InvokeServer(slot, id|nil) -> ok, Nachricht
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local PlayerData = require(script.Parent.PlayerData)

local ShopService = {}

local lastRequest = {}

local function busy(player)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < 0.4 then
		return true
	end
	lastRequest[player] = now
	return false
end

local function money(n)
	local text = tostring(n)
	return (text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

-- Was ein Kauf gutschreibt (für Münzen und Robux gleich)
function ShopService.grant(data, entry, kind)
	if kind == "Item" then
		data.Items[entry.id] = (data.Items[entry.id] or 0) + 1
	elseif kind == "CoinPack" then
		data.Coins += entry.coins
	elseif kind == "Pack" then
		data.Owned[entry.id] = true
		for _, id in entry.grants or {} do
			data.Owned[id] = true
		end
	elseif kind == "Outfit" then
		data.Owned[entry.id] = true
		for _, id in entry.items or {} do
			data.Owned[id] = true
		end
	else
		data.Owned[entry.id] = true
	end
end

function ShopService.grantStarterPack(data)
	data.Owned.StarterPack = true
	data.Items.EnergyBar = (data.Items.EnergyBar or 0) + 3
	data.Items.Coffee = (data.Items.Coffee or 0) + 2
	data.Items.MintGum = (data.Items.MintGum or 0) + 1
	data.Coins += 500
	data.Owned.Beanie = true
end

local function buyWithCoins(player, id)
	if type(id) ~= "string" or busy(player) then
		return false, "Please wait a moment."
	end
	local entry, kind = ShopCatalog.find(id)
	if not entry or type(entry.coins) ~= "number" then
		return false, "This can't be bought with coins."
	end
	local consumable = kind == "Item"
	local ok, reason = PlayerData.update(player, function(data)
		if not consumable and data.Owned[id] then
			return false, "You already own " .. entry.title .. "."
		end
		if kind == "Outfit" then
			local missing = false
			for _, itemId in entry.items do
				if not data.Owned[itemId] then
					missing = true
				end
			end
			if not missing then
				return false, "You already own everything in " .. entry.title .. "."
			end
		end
		if data.Coins < entry.coins then
			return false, "Not enough coins: you need " .. money(entry.coins - data.Coins) .. " more."
		end
		data.Coins -= entry.coins
		ShopService.grant(data, entry, kind)
		return true
	end)
	if ok then
		return true, consumable and (entry.title .. " added to your backpack!") or ("You got " .. entry.title .. "!")
	end
	return false, reason
end

local function equip(player, slot, id)
	if (slot ~= "Player" and slot ~= "Sarp") or busy(player) then
		return false, "Please wait a moment."
	end
	if id ~= nil then
		local entry, kind = ShopCatalog.find(id)
		if kind ~= "Skin" or entry.slot ~= slot then
			return false, "This skin doesn't fit here."
		end
	end
	return PlayerData.update(player, function(data)
		if id ~= nil and not data.Owned[id] then
			return false, "You don't own this skin yet."
		end
		data.Equipped[slot] = id
		return true
	end)
end

-- Gamepässe: Besitz bei Roblox abfragen (nur für Pässe mit echter ID)
local function checkPasses(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local newPasses = {}
	for _, pass in ShopCatalog.GAMEPASSES do
		if pass.passId ~= 0 and not data.Owned[pass.id] then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.passId)
			if ok and owns then
				table.insert(newPasses, pass.id)
			end
		end
	end
	if #newPasses > 0 then
		-- gespeichert nur für die Anzeige; Roblox bleibt die Quelle (UserOwnsGamePassAsync)
		PlayerData.update(player, function(saved)
			for _, id in newPasses do
				saved.Owned[id] = true
			end
			return true
		end)
	end
end

function ShopService.init()
	local remotes = Instance.new("Folder")
	remotes.Name = "ShopRemotes"
	local buy = Instance.new("RemoteFunction")
	buy.Name = "BuyWithCoins"
	buy.Parent = remotes
	local equipRemote = Instance.new("RemoteFunction")
	equipRemote.Name = "Equip"
	equipRemote.Parent = remotes
	remotes.Parent = ReplicatedStorage

	buy.OnServerInvoke = buyWithCoins
	equipRemote.OnServerInvoke = equip

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased then
			checkPasses(player)
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.delay(3, checkPasses, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		PlayerData.unload(player)
	end)
end

-- Robux-Produkte des Shops: productId -> function(data)
function ShopService.productHandlers()
	local handlers = {}
	local function add(productId, apply)
		if productId and productId ~= 0 then
			handlers[productId] = apply
		end
	end
	for _, list in { { ShopCatalog.SKINS, "Skin" }, { ShopCatalog.ITEMS, "Item" }, { ShopCatalog.PACKS, "Pack" }, { ShopCatalog.COIN_PACKS, "CoinPack" }, { ShopCatalog.CLOTHING, "Clothing" }, { ShopCatalog.OUTFITS, "Outfit" } } do
		for _, entry in list[1] do
			add(entry.productId, function(data)
				ShopService.grant(data, entry, list[2])
			end)
		end
	end
	add(ShopCatalog.SPORTS_CAR.productId, function(data)
		ShopService.grant(data, ShopCatalog.SPORTS_CAR, "Car")
	end)
	add(ShopCatalog.STARTER_PACK.productId, ShopService.grantStarterPack)
	add(ShopCatalog.STARTER_PACK.firstTimeProductId, ShopService.grantStarterPack)
	return handlers
end

return ShopService
