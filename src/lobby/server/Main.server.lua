-- Startpunkt der Lobby: baut die Welt und startet die Autos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarQueue = require(script.Parent.CarQueue)
local LobbyBuilder = require(script.Parent.LobbyBuilder)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local notify = Instance.new("RemoteEvent")
notify.Name = "Notify"
notify.Parent = remotes
remotes.Parent = ReplicatedStorage

Players.RespawnTime = 2

local lobby = LobbyBuilder.build()
CarQueue.init(lobby.carsFolder, lobby.gate, notify)
