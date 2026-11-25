-- Startpunkt von Kapitel 2 auf dem Client. Der Ablauf steht in Scene.lua,
-- Kapitel 3 (Ritualraum, Flucht durch den Wald) in Kapitel3.lua.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Ganzes Spiel (spiel.project.json): erst Kapitel 1 spielen lassen, bis der Server Kapitel 2 startet
if ReplicatedStorage:GetAttribute("FullGame") then
	ReplicatedStorage:WaitForChild("Kapitel2", math.huge)
end
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Mood")).start()
require(ReplicatedStorage.Shared:WaitForChild("Inventory")).start()
-- Leistung: ferne Tannen im Wald von Kapitel 3 nicht zeichnen
task.spawn(function()
	local forest = workspace:WaitForChild("Kapitel3Forest", math.huge)
	require(ReplicatedStorage.Shared:WaitForChild("TreeCulling")).start(forest)
end)
task.spawn(function()
	require(script.Parent:WaitForChild("Kapitel3")).run()
end)
require(script.Parent:WaitForChild("Scene")).run()
