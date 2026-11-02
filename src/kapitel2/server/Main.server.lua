-- Startpunkt von Kapitel 2 (eigenes Rojo-Projekt: kapitel2.project.json).
-- Man steht vor der Haustür der Wagners. Der Ablauf steht in Kapitel2.lua.
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

-- Alte Skripte aus der Lobby oder aus Kapitel 1, die noch im selben Studio-Ort liegen,
-- stoppen und entfernen (inklusive allem, was sie schon gebaut haben)
for _, container in { script.Parent.Parent, StarterPlayer.StarterPlayerScripts } do
	for _, name in { "Lobby", "Level" } do
		local leftover = container:FindFirstChild(name)
		if leftover then
			warn("Alte Skripte (" .. name .. ") in Kapitel 2 gefunden und entfernt.")
			leftover:Destroy()
		end
	end
end
task.wait()
for _, name in { "Lobby", "Level1" } do
	local old = workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end
local oldCutscene = ReplicatedStorage:FindFirstChild("Cutscene")
if oldCutscene then
	oldCutscene:Destroy()
end

local ok, problem = xpcall(function()
	require(script.Parent.Kapitel2).start()
end, debug.traceback)
if not ok then
	-- Fehler auch auf dem Ladebildschirm zeigen (sonst wartet das Spiel nur)
	warn("Kapitel 2 konnte nicht starten – bitte diese Meldung an Claude schicken:\n" .. tostring(problem))
	local remotes = ReplicatedStorage:FindFirstChild("Kapitel2") or Instance.new("Folder")
	remotes.Name = "Kapitel2"
	-- Herausfinden, welches Modul kaputt ist: alle einzeln laden (von unten nach oben)
	local broken = "?"
	for _, path in {
		{ ReplicatedStorage.Shared, "Parts" },
		{ ReplicatedStorage.Shared, "LevelRoute" },
		{ ReplicatedStorage.Shared, "Forest" },
		{ ReplicatedStorage.Shared, "Config" },
		{ ReplicatedStorage.Shared, "Dialogue" },
		{ ReplicatedStorage.Shared, "Kapitel2Dialogue" },
		{ script.Parent, "House" },
		{ script.Parent, "HouseInterior" },
		{ script.Parent, "Furniture" },
		{ script.Parent, "Mansion" },
		{ script.Parent, "Wagners" },
		{ script.Parent, "World" },
		{ script.Parent, "ForestWalk" },
		{ script.Parent, "Kapitel2" },
	} do
		local module = path[1]:FindFirstChild(path[2])
		if not module then
			broken = path[2] .. " (fehlt ganz – ist Rojo verbunden?)"
			break
		end
		local loaded, err = pcall(require, module)
		if not loaded then
			broken = path[2] .. ": " .. tostring(err)
			break
		end
	end
	warn("Kapitel 2: kaputtes Modul → " .. broken)
	remotes:SetAttribute("Status", "Fehler beim Start in Modul\n" .. broken)
	remotes.Parent = ReplicatedStorage
end
