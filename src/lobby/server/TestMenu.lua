-- Testmenü der Lobby (nur in Roblox Studio): Münzen geben, Käufe zurücksetzen und –
-- in der gemeinsamen Testdatei (alles.project.json) – ein Kapitel starten.
-- Der Client (LobbyTestMenu.client.lua) schickt "coins", "reset" oder "start", id.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(script.Parent.PlayerData)

local TestMenu = {}

-- Lobby wegräumen, damit das Kapitel seine eigene Welt bauen kann, dann die Wahl melden
local function startChapter(id)
	if not ReplicatedStorage:GetAttribute("Combined") or ReplicatedStorage:GetAttribute("StartChoice") ~= nil then
		return
	end
	Players.CharacterAutoLoads = false
	for _, player in Players:GetPlayers() do
		if player.Character then
			player.Character:Destroy()
			player.Character = nil
		end
	end
	for _, name in { "Lobby", "LobbyCars", "ShopHut" } do
		local leftover = workspace:FindFirstChild(name)
		if leftover then
			leftover:Destroy()
		end
	end
	workspace.Terrain:Clear()
	-- Lighting zurück auf Standard: Effekte der Lobby entfernen (das Kapitel setzt seine eigenen)
	for _, child in game:GetService("Lighting"):GetChildren() do
		if not child:IsA("Sky") then
			child:Destroy()
		end
	end
	ReplicatedStorage:SetAttribute("LobbyPick", id)
	-- zuletzt die Lobby-Skripte selbst stoppen (auch dieses hier)
	local lobbyScripts = ServerScriptService:FindFirstChild("Lobby")
	if lobbyScripts then
		task.defer(lobbyScripts.Destroy, lobbyScripts)
	end
end

function TestMenu.init()
	if not RunService:IsStudio() then
		return
	end
	local action = Instance.new("RemoteEvent")
	action.Name = "LobbyTestAction"
	action.OnServerEvent:Connect(function(player, what, id)
		if what == "start" then
			if type(id) == "string" then
				startChapter(id)
			end
			return
		end
		PlayerData.update(player, function(saved)
			if what == "coins" then
				saved.Coins += 5000
			elseif what == "reset" then
				saved.Coins = 5000
				table.clear(saved.Owned)
				table.clear(saved.Items)
				table.clear(saved.Equipped)
			else
				return false
			end
			return true
		end)
	end)
	action.Parent = ReplicatedStorage
end

return TestMenu
