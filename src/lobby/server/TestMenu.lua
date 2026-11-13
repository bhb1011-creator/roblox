-- Testmenü der Lobby (nur in Roblox Studio): Münzen geben, Käufe zurücksetzen.
-- Der Client (LobbyTestMenu.client.lua) schickt "coins" oder "reset" über LobbyTestAction.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerData = require(script.Parent.PlayerData)

local TestMenu = {}

function TestMenu.init()
	if not RunService:IsStudio() then
		return
	end
	local action = Instance.new("RemoteEvent")
	action.Name = "LobbyTestAction"
	action.OnServerEvent:Connect(function(player, what)
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
