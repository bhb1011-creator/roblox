-- Ganzes Spiel: Wo soll es losgehen? Nur in Roblox Studio wartet der Server auf die Wahl im
-- Testmenü (Taste O, erscheint beim Start von selbst). Im echten Spiel immer Kapitel 1.
-- Ergebnis: Attribut "StartChoice" an ReplicatedStorage. Kapitel 1 und Kapitel 2
-- (Main.server.lua) warten darauf.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local TestStarts = require(ReplicatedStorage.Shared:WaitForChild("TestStarts"))

local CHOOSE_TIME = 40 -- Sekunden; danach geht es normal ab Kapitel 1 los

local valid = {}
for _, entry in TestStarts do
	valid[entry.id] = true
end

local pick = Instance.new("RemoteEvent")
pick.Name = "TestMenuPick"
pick.Parent = ReplicatedStorage

local function choose(id)
	if ReplicatedStorage:GetAttribute("StartChoice") ~= nil then
		return
	end
	if id == "figuren" then
		task.spawn(require(script.Parent:WaitForChild("Figuren")).run)
	elseif id ~= "kapitel1" then
		Config.TEST_START_KAPITEL2 = id
	end
	print("Ganzes Spiel: Start bei „" .. (id == "" and "Kapitel 2 – Haustür" or id) .. "“")
	ReplicatedStorage:SetAttribute("StartChoice", id)
end

if not RunService:IsStudio() then
	choose("kapitel1")
	return
end

ReplicatedStorage:SetAttribute("TestMenu", true) -- Clients zeigen das Menü
if valid[Config.TEST_AUTOSTART or ""] and Config.TEST_AUTOSTART ~= "" then
	choose(Config.TEST_AUTOSTART)
	return
end
pick.OnServerEvent:Connect(function(_, id)
	if type(id) == "string" and valid[id] then
		choose(id)
	end
end)
-- Uhr läuft erst, wenn jemand da ist
task.spawn(function()
	while #Players:GetPlayers() == 0 do
		Players.PlayerAdded:Wait()
	end
	task.wait(CHOOSE_TIME)
	choose("kapitel1")
end)
