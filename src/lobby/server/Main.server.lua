-- Startpunkt der Lobby: baut die Welt, startet die Autos und die Kasse.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarQueue = require(script.Parent.CarQueue)
local LobbyBuilder = require(script.Parent.LobbyBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Purchases = require(script.Parent.Purchases)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local notify = Instance.new("RemoteEvent")
notify.Name = "Notify"
notify.Parent = remotes
remotes.Parent = ReplicatedStorage

Players.RespawnTime = 2

Players.PlayerAdded:Connect(PlayerData.load)
for _, player in Players:GetPlayers() do
	task.spawn(PlayerData.load, player)
end
Purchases.init(notify)

local lobby = LobbyBuilder.build()
CarQueue.init(lobby.carsFolder, lobby.gate, notify)
