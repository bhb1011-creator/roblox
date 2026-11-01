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

require(script.Parent.Kapitel2).start()
