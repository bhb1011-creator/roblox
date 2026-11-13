-- Startpunkt der Lobby: baut die Welt, startet die Autos und die Kasse.

-- Liegen im selben Studio-Ort auch die Skripte von Level 1, läuft nur das Level.
-- (Sonst würden Lobby und Level übereinander gebaut.)
if script.Parent.Parent:FindFirstChild("Level") then
	warn("Lobby-Skripte übersprungen: In diesem Ort liegt Level 1.")
	return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarQueue = require(script.Parent.CarQueue)
local LobbyBuilder = require(script.Parent.LobbyBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Purchases = require(script.Parent.Purchases)
local ShopService = require(script.Parent.ShopService)
local ShopHut = require(script.Parent.ShopHut)
local TestMenu = require(script.Parent.TestMenu)

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
ShopService.init()
Purchases.init(notify)
TestMenu.init() -- nur in Studio

local lobby = LobbyBuilder.build()
CarQueue.init(lobby.carsFolder, lobby.gate, notify)
-- Shop-Hütte zuletzt bauen: Figuren und Kleidung, die Lobby soll vorher stehen
task.spawn(ShopHut.build, lobby.folder)
