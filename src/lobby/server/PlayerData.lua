-- Gespeicherte Spielerdaten im DataStore: Wiederbelebungen, Rebirths, Münzen, gekaufte Sachen
-- (Skins, Kleidung, Sportwagen, Packs), Snacks im Rucksack und was man trägt.
-- Die wichtigsten Werte stehen zusätzlich als Attribute am Spieler, damit die Anzeige sie lesen kann:
--   Revives, Rebirths, Coins (Zahlen), ShopData (JSON: Owned, Items, Equipped)
-- In Studio braucht das: Spieleinstellungen → Sicherheit → "Studio-Zugriff auf API-Dienste".
-- Ohne DataStore (z. B. lokale Testdatei) gilt alles nur für diese Sitzung; in Studio gibt es dann
-- 5000 Test-Münzen, damit man den Shop ausprobieren kann.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local PlayerData = {}

local STORE_NAME = "PlayerData_v1"
local STUDIO_TEST_COINS = 5000

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("DataStore nicht verfügbar – Käufe können nicht gespeichert werden:", result)
	end
end

local sessions = {} -- [player] = Daten dieser Sitzung (Kopie des gespeicherten Stands)

local function keyFor(userId)
	return "player_" .. userId
end

-- fehlende Felder ergänzen (alte Spielstände haben nur Revives/Rebirths)
local function normalize(saved)
	saved = type(saved) == "table" and saved or {}
	saved.Revives = type(saved.Revives) == "number" and saved.Revives or 0
	saved.Rebirths = type(saved.Rebirths) == "number" and saved.Rebirths or 0
	saved.Coins = type(saved.Coins) == "number" and saved.Coins or 0
	saved.Owned = type(saved.Owned) == "table" and saved.Owned or {}
	saved.Items = type(saved.Items) == "table" and saved.Items or {}
	saved.Equipped = type(saved.Equipped) == "table" and saved.Equipped or {}
	saved.Receipts = type(saved.Receipts) == "table" and saved.Receipts or {}
	return saved
end

local function publish(player, data)
	player:SetAttribute("Revives", data.Revives)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("ShopData", HttpService:JSONEncode({ Owned = data.Owned, Items = data.Items, Equipped = data.Equipped }))
	player:SetAttribute("PlayerSkin", data.Equipped.Player)
end

function PlayerData.load(player)
	local data = normalize(nil)
	if store then
		local ok, saved = pcall(store.GetAsync, store, keyFor(player.UserId))
		if ok then
			data = normalize(saved)
		else
			warn("Spielerdaten konnten nicht geladen werden:", saved)
		end
	elseif RunService:IsStudio() then
		data.Coins = STUDIO_TEST_COINS
		player:SetAttribute("TestCoins", true)
	end
	sessions[player] = data
	publish(player, data)
end

function PlayerData.unload(player)
	sessions[player] = nil
end

function PlayerData.get(player)
	return sessions[player]
end

-- Ändert die Daten sicher (UpdateAsync): `change(data)` gibt true zurück, wenn gespeichert werden
-- soll, sonst false + Grund. Ergebnis: true oder false, Grund.
function PlayerData.update(player, change)
	if not sessions[player] then
		return false, "Your data is still loading."
	end
	if not store then
		local ok, reason = change(sessions[player])
		if ok then
			publish(player, sessions[player])
		end
		return ok, reason
	end
	local result, reason
	local ok, err = pcall(store.UpdateAsync, store, keyFor(player.UserId), function(saved)
		saved = normalize(saved)
		result, reason = change(saved)
		if not result then
			return nil -- nichts ändern
		end
		return saved
	end)
	if not ok then
		warn("Spielerdaten konnten nicht gespeichert werden:", err)
		return false, "Could not save. Please try again."
	end
	if result then
		-- neuen Stand übernehmen: einmal frisch laden ist am sichersten
		local loaded, saved = pcall(store.GetAsync, store, keyFor(player.UserId))
		if loaded then
			sessions[player] = normalize(saved)
		end
		publish(player, sessions[player])
	end
	return result, reason
end

-- Schreibt einen Robux-Kauf genau einmal gut (die Kauf-ID wird mitgespeichert).
-- `apply(data)` verändert die Daten. Gibt true zurück, wenn der Kauf gespeichert ist.
function PlayerData.grantReceipt(userId, purchaseId, apply)
	local function change(data)
		if data.Receipts[purchaseId] then
			return false, "already"
		end
		data.Receipts[purchaseId] = os.time()
		apply(data)
		return true
	end
	local player = game:GetService("Players"):GetPlayerByUserId(userId)
	if not store then
		if player and sessions[player] then
			local ok = change(sessions[player])
			if ok then
				publish(player, sessions[player])
			end
			return true
		end
		return false
	end
	local saved = false
	local ok, err = pcall(store.UpdateAsync, store, keyFor(userId), function(data)
		data = normalize(data)
		if change(data) then
			saved = true
			return data
		end
		saved = true -- war schon gutgeschrieben
		return nil
	end)
	if not ok then
		warn("Kauf konnte nicht gespeichert werden:", err)
		return false
	end
	if player and sessions[player] then
		local loaded, data = pcall(store.GetAsync, store, keyFor(userId))
		if loaded then
			sessions[player] = normalize(data)
			publish(player, sessions[player])
		end
	end
	return saved
end

-- Alte Schnittstelle (Kasse: Wiederbelebungen, Rebirths)
function PlayerData.grantPurchase(userId, purchaseId, field, amount)
	local ok = PlayerData.grantReceipt(userId, purchaseId, function(data)
		data[field] = (data[field] or 0) + amount
	end)
	local player = game:GetService("Players"):GetPlayerByUserId(userId)
	local data = player and sessions[player]
	return ok, data and data[field]
end

return PlayerData
