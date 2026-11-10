-- Feste Spielfiguren statt des eigenen Roblox-Avatars, damit alles zum realistischen Stil passt.
-- Die Figuren liegen in ReplicatedStorage.Spieler (aus assets/spieler):
--   Spieler1 = Fahrer (bzw. erster Spieler), Spieler2 = Beifahrer (bzw. zweiter Spieler).
-- Fehlt der Ordner, bekommt man wie bisher seinen eigenen Avatar.
--
--   PlayerFigure.load(player)      -- statt player:LoadCharacter()
--   PlayerFigure.template(player)  -- die Vorlage (Model) oder nil
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PlayerFigure = {}

local busy = false -- immer nur ein Spieler gleichzeitig (StarterCharacter wird kurz getauscht)

-- Welche Figur ein Spieler bekommt: Beifahrer = 2, sonst nach Reihenfolge
local function slotOf(player)
	local stored = player:GetAttribute("Figur")
	if stored then
		return stored
	end
	local slot
	if player:GetAttribute("CutsceneSeat") == "Passenger" then
		slot = 2
	elseif player:GetAttribute("CutsceneSeat") == "Driver" then
		slot = 1
	else
		local taken = {}
		for _, other in Players:GetPlayers() do
			local otherSlot = other ~= player and other:GetAttribute("Figur")
			if otherSlot then
				taken[otherSlot] = true
			end
		end
		slot = taken[1] and 2 or 1
	end
	player:SetAttribute("Figur", slot)
	return slot
end

function PlayerFigure.template(player)
	local folder = ReplicatedStorage:FindFirstChild("Spieler")
	if not folder then
		return nil
	end
	local slot = slotOf(player)
	local template = folder:FindFirstChild("Spieler" .. slot) or folder:FindFirstChild("Spieler1")
	if template and template:IsA("Model") and template:FindFirstChildOfClass("Humanoid") and template:FindFirstChild("HumanoidRootPart") then
		return template
	end
	return nil
end

-- Spielfigur laden: mit fester Figur (falls vorhanden), sonst der eigene Avatar
function PlayerFigure.load(player)
	local template = PlayerFigure.template(player)
	if not template then
		player:LoadCharacter()
		return
	end
	while busy do
		task.wait()
	end
	busy = true
	local old = StarterPlayer:FindFirstChild("StarterCharacter")
	if old then
		old.Parent = nil
	end
	local starter = template:Clone()
	starter.Name = "StarterCharacter"
	for _, item in starter:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = false
		end
	end
	starter.PrimaryPart = starter:FindFirstChild("HumanoidRootPart")
	starter.Parent = StarterPlayer
	local ok, problem = pcall(function()
		player:LoadCharacter()
	end)
	starter:Destroy()
	if old then
		old.Parent = StarterPlayer
	end
	busy = false
	if not ok then
		warn("Spielfigur konnte nicht geladen werden, nehme den eigenen Avatar:", problem)
		player:LoadCharacter()
		return
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

return PlayerFigure
