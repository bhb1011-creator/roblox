-- Gespeicherte Spielerdaten (Wiederbelebungen, Rebirths) im DataStore.
-- Die Werte stehen zusätzlich als Attribute am Spieler, damit die Anzeige sie lesen kann.
-- In Studio braucht das: Spieleinstellungen → Sicherheit → "Studio-Zugriff auf API-Dienste".
local DataStoreService = game:GetService("DataStoreService")

local PlayerData = {}

local STORE_NAME = "PlayerData_v1"
local DEFAULTS = { Revives = 0, Rebirths = 0 }

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

local function keyFor(userId)
	return "player_" .. userId
end

local function applyAttributes(player, saved)
	for field, default in DEFAULTS do
		local value = type(saved) == "table" and saved[field]
		player:SetAttribute(field, type(value) == "number" and value or default)
	end
end

function PlayerData.load(player)
	applyAttributes(player, nil)
	if not store then
		return
	end
	local ok, saved = pcall(store.GetAsync, store, keyFor(player.UserId))
	if ok then
		applyAttributes(player, saved)
	else
		warn("Spielerdaten konnten nicht geladen werden:", saved)
	end
end

-- Schreibt einen Kauf genau einmal gut (die Kauf-ID wird mitgespeichert).
-- Gibt true zurück, wenn der Kauf gespeichert ist (auch wenn er schon früher gespeichert wurde).
function PlayerData.grantPurchase(userId, purchaseId, field, amount)
	if not store then
		return false
	end
	local newValue
	local ok, err = pcall(store.UpdateAsync, store, keyFor(userId), function(saved)
		saved = type(saved) == "table" and saved or {}
		saved.Receipts = saved.Receipts or {}
		if saved.Receipts[purchaseId] then
			newValue = saved[field]
			return nil -- schon gutgeschrieben, nichts ändern
		end
		saved.Receipts[purchaseId] = os.time()
		saved[field] = (saved[field] or 0) + amount
		newValue = saved[field]
		return saved
	end)
	if not ok then
		warn("Kauf konnte nicht gespeichert werden:", err)
		return false
	end
	return true, newValue
end

return PlayerData
