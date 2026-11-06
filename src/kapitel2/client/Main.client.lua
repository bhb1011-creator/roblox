-- Startpunkt von Kapitel 2 auf dem Client. Der Ablauf steht in Scene.lua,
-- Kapitel 3 (Ritualraum, Flucht durch den Wald) in Kapitel3.lua.
task.spawn(function()
	require(script.Parent:WaitForChild("Kapitel3")).run()
end)
require(script.Parent:WaitForChild("Scene")).run()
