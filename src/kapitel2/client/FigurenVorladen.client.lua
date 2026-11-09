-- Lädt die echten Figuren der Familie (ReplicatedStorage.Wagners, aus assets/figuren)
-- gleich beim Spielstart im Hintergrund: Körper-Modelle und Texturen. So sind sie
-- fertig, wenn sie in Kapitel 2 auftauchen, statt erst weiß/grau zu erscheinen.
-- Läuft im ganzen Spiel schon während Kapitel 1.
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:WaitForChild("Wagners", 30)
if not folder then
	return
end

-- kurz warten, damit der Spielstart selbst nicht ausgebremst wird
task.wait(2)

local items = {}
for _, item in folder:GetDescendants() do
	if item:IsA("MeshPart") or item:IsA("SurfaceAppearance") then
		table.insert(items, item)
	end
end

local failed = 0
local started = os.clock()
local ok, err = pcall(function()
	ContentProvider:PreloadAsync(items, function(_, status)
		if status ~= Enum.AssetFetchStatus.Success then
			failed += 1
		end
	end)
end)
if not ok then
	warn("Figuren vorladen fehlgeschlagen:", err)
elseif failed > 0 then
	-- frisch hochgeladene Dateien braucht Roblox manchmal noch eine Weile ("is being generated")
	warn(string.format("Figuren vorgeladen in %.1f s, %d Dateien noch nicht bereit.", os.clock() - started, failed))
else
	print(string.format("Figuren vorgeladen in %.1f s.", os.clock() - started))
end
