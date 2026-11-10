-- Startpunkt von Kapitel 2 (eigenes Rojo-Projekt: kapitel2.project.json).
-- Man steht vor der Haustür der Wagners. Der Ablauf steht in Kapitel2.lua.
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

-- Ganzes Spiel (spiel.project.json): Kapitel 1 läuft zuerst. Kapitel 2 startet, wenn es
-- zu Ende ist (Bild schwarz, "Ende von Kapitel 1"), und räumt dann Kapitel 1 weg.
-- Im Testmenü (Taste O) kann man auch gleich irgendwo in Kapitel 2 oder 3 anfangen.
local function startChoice()
	while ReplicatedStorage:GetAttribute("StartChoice") == nil do
		ReplicatedStorage:GetAttributeChangedSignal("StartChoice"):Wait()
	end
	return ReplicatedStorage:GetAttribute("StartChoice")
end
if ReplicatedStorage:GetAttribute("FullGame") and (startChoice() == "figuren" or startChoice() == "charaktere") then
	return -- (Testmenü: nur die Figuren ansehen, siehe src/spiel/server/Figuren.lua)
end
if ReplicatedStorage:GetAttribute("FullGame") and startChoice() == "kapitel1" then
	local cutscene = ReplicatedStorage:WaitForChild("Cutscene", math.huge)
	while not cutscene:GetAttribute("Finished") do
		cutscene:GetAttributeChangedSignal("Finished"):Wait()
	end
	task.wait(9) -- Abblenden und Karte "Ende von Kapitel 1" zeigen lassen
	for _, player in Players:GetPlayers() do
		if player.Character then
			player.Character:Destroy()
			player.Character = nil
		end
		player.ReplicationFocus = nil
	end
	for _, leftover in workspace:GetChildren() do
		if leftover.Name == "BeastAnchor" or leftover.Name:sub(1, 12) == "StreamFocus_" then
			leftover:Destroy()
		end
	end
end

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
	remotes:SetAttribute("Status", "Startup error in module\n" .. broken)
	remotes.Parent = ReplicatedStorage
end
