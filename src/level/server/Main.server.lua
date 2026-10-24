-- Startpunkt von Level 1: baut die Welt, legt Auto, Fremden und Spielerfiguren als
-- Vorlagen bereit, verteilt die Sitzplätze und startet die Zwischensequenz.
-- Während der Fahrt gibt es keine echten Spielfiguren; jeder Client zeigt die
-- Figur des Mitfahrers als Puppe im Auto.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Route = require(ReplicatedStorage.Shared.LevelRoute)
local CutsceneCar = require(script.Parent.CutsceneCar)
local DialogueRunner = require(script.Parent.DialogueRunner)
local Stranger = require(script.Parent.Stranger)
local World = require(script.Parent.World)

local WAIT_FOR_GROUP = 10 -- Sekunden, die auf den zweiten Spieler gewartet wird
local START_DELAY = 2

Players.CharacterAutoLoads = false

-- Alte Lobby-Skripte, die noch im selben Studio-Ort liegen, stoppen und entfernen
-- (inklusive der Lobby, die sie vielleicht schon gebaut haben). Sonst stehen
-- Lobby-Bäume und -Schranke mitten auf der Straße.
for _, container in { script.Parent.Parent, game:GetService("StarterPlayer").StarterPlayerScripts } do
	local leftover = container:FindFirstChild("Lobby")
	if leftover then
		warn("Alte Lobby-Skripte in Level 1 gefunden und entfernt.")
		leftover:Destroy()
	end
end
task.wait()
local oldLobby = workspace:FindFirstChild("Lobby")
if oldLobby then
	oldLobby:Destroy()
end

local cutscene = Instance.new("Folder")
cutscene.Name = "Cutscene"
local puppets = Instance.new("Folder")
puppets.Name = "Puppets"
puppets.Parent = cutscene
-- Gespräch: Server → Clients (Sätze, Auswahl) und Client → Server (gewählte Antwort)
for _, name in { "DialogueEvent", "DialogueChoice" } do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = cutscene
end
cutscene.Parent = ReplicatedStorage

World.build()
CutsceneCar.build(cutscene)
Stranger.build(cutscene)

-- Damit die Welt entlang der Strecke geladen wird, folgt für jeden Spieler ein
-- unsichtbarer Punkt dem Auto (Roblox lädt die Umgebung um diesen Punkt).
local focusParts = {}

local function expectedPlayers(player)
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData
	return type(teleportData) == "table" and teleportData.mode == "Duo" and 2 or 1
end

-- Figur des Spielers (sein Avatar) als Puppe für die anderen Clients
local function buildPuppet(player)
	local ok, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(math.max(player.UserId, 1))
	end)
	if not ok then
		description = Instance.new("HumanoidDescription")
	end
	local built, puppet = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not built then
		warn("Spielerfigur konnte nicht erstellt werden:", puppet)
		return
	end
	puppet.Name = tostring(player.UserId)
	local humanoid = puppet:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	puppet.Parent = puppets
end

local driverTaken = false
local firstJoin
local expected = 1

local function onPlayerAdded(player)
	player:SetAttribute("CutsceneSeat", driverTaken and "Passenger" or "Driver")
	driverTaken = true

	local focus = Instance.new("Part")
	focus.Name = "StreamFocus_" .. player.UserId
	focus.Anchored = true
	focus.CanCollide = false
	focus.CanQuery = false
	focus.Transparency = 1
	focus.Size = Vector3.new(1, 1, 1)
	focus.CFrame = Route.carCFrame(Route.START_S)
	focus.Parent = workspace
	focusParts[player] = focus
	player.ReplicationFocus = focus

	if not firstJoin then
		firstJoin = os.clock()
		expected = expectedPlayers(player)
		task.spawn(function()
			while #Players:GetPlayers() < expected and os.clock() - firstJoin < WAIT_FOR_GROUP do
				task.wait(0.25)
			end
			local startTime = workspace:GetServerTimeNow() + START_DELAY
			local duo = #Players:GetPlayers() >= 2
			cutscene:SetAttribute("Duo", duo)
			cutscene:SetAttribute("StartTime", startTime)
			DialogueRunner.start(cutscene, startTime, duo)
		end)
	end

	buildPuppet(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerRemoving:Connect(function(player)
	local focus = focusParts[player]
	if focus then
		focus:Destroy()
		focusParts[player] = nil
	end
	local puppet = puppets:FindFirstChild(tostring(player.UserId))
	if puppet then
		puppet:Destroy()
	end
end)

-- Ladepunkte mit dem Auto (oder den Spielern zu Fuß) mitbewegen
local driveLine, walkLine = Route.driveToHouseLine(), Route.walkLine()
RunService.Heartbeat:Connect(function()
	local startTime = cutscene:GetAttribute("StartTime")
	if not startTime then
		return
	end
	local now = workspace:GetServerTimeNow()
	local branch, branchStart = cutscene:GetAttribute("Branch"), cutscene:GetAttribute("BranchStart")
	local cframe
	if branch == "drive" and branchStart then
		local s = Route.profile(now - branchStart, driveLine.length, Route.DRIVE_TOP_SPEED, Route.DRIVE_ACCELERATION, Route.DRIVE_BRAKE)
		cframe = driveLine.cframeAt(s)
	elseif branch == "follow" and branchStart then
		cframe = walkLine.cframeAt(math.clamp((now - branchStart - Route.WALK_FADE) * Route.WALK_SPEED, 0, walkLine.length))
	else
		cframe = Route.carCFrame(Route.driveDistance(now - startTime))
	end
	for _, focus in focusParts do
		focus.CFrame = cframe
	end
end)
