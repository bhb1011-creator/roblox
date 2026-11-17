-- Zurück in die Lobby (Startort, Config.LOBBY_PLACE_ID): nach dem Ende von Kapitel 3 und mit
-- "Back to lobby" beim Game Over. Teleport geht nur im echten Roblox – in Studio passiert nichts.
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local BackToLobby = {}

-- true = Teleport wurde gestartet
function BackToLobby.send(players)
	local lobby = Config.LOBBY_PLACE_ID or 0
	if #players == 0 then
		return false
	end
	if RunService:IsStudio() or lobby == 0 or game.PlaceId == lobby then
		print("Zurück zur Lobby: geht nur im echten Roblox (in Studio kein Teleport).")
		return false
	end
	local ok, problem = pcall(TeleportService.TeleportAsync, TeleportService, lobby, players)
	if not ok then
		warn("Zurück zur Lobby fehlgeschlagen: " .. tostring(problem))
	end
	return ok
end

return BackToLobby
