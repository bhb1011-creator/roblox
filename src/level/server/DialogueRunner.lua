-- Führt das Gespräch mit Sarp und danach eines der beiden Enden.
-- Der Server bestimmt den Ablauf und schickt jede Zeile an alle Clients; die Clients
-- sprechen den Text (Text-to-Speech) und zeigen Untertitel. Antworten wählt der Fahrer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Dialogue = require(ReplicatedStorage.Shared.Dialogue)
local Route = require(ReplicatedStorage.Shared.LevelRoute)

local DialogueRunner = {}

local CHOICE_TIMEOUT = 25 -- danach wird automatisch die erste Antwort genommen
local GAP = 0.4 -- Pause zwischen zwei Sätzen

local function waitUntil(serverTime)
	local remaining = serverTime - workspace:GetServerTimeNow()
	if remaining > 0 then
		task.wait(remaining)
	end
end

-- Wer antworten darf: der Fahrer, sonst irgendein Spieler
local function findChooser()
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("CutsceneSeat") == "Driver" then
			return player
		end
	end
	return Players:GetPlayers()[1]
end

function DialogueRunner.start(cutscene, startTime, duo)
	local event = cutscene:WaitForChild("DialogueEvent")
	local choiceEvent = cutscene:WaitForChild("DialogueChoice")
	local nameKnown = false

	local function say(speaker, entry, name)
		local text = Dialogue.text(entry, duo)
		local voice = Config.VOICES and Config.VOICES[speaker] or {}
		local duration = Dialogue.duration(text, voice.speed)
		if speaker == "sarp" then
			name = nameKnown and "Sarp" or "???"
		end
		event:FireAllClients({ type = "line", speaker = speaker, name = name, text = text, duration = duration })
		task.wait(duration + GAP)
	end

	local function runLine(line)
		if line.action then
			event:FireAllClients({ type = "action", action = line.action })
		end
		if line.text then
			say(line.speaker, line.text)
		end
		if line.reveal then
			nameKnown = true
		end
		if line.wait then
			task.wait(line.wait)
		end
	end

	local function ask(options)
		local chooser = findChooser()
		local texts = {}
		for i, option in options do
			texts[i] = Dialogue.text(option.text, duo)
		end
		local picked
		local connection = choiceEvent.OnServerEvent:Connect(function(player, index)
			if player == chooser and not picked and type(index) == "number" and options[index] then
				picked = index
			end
		end)
		event:FireAllClients({ type = "choice", options = texts, chooser = chooser and chooser.UserId, timeout = CHOICE_TIMEOUT })
		local deadline = os.clock() + CHOICE_TIMEOUT
		while not picked and os.clock() < deadline and chooser and chooser.Parent do
			task.wait(0.1)
		end
		connection:Disconnect()
		picked = picked or 1
		event:FireAllClients({ type = "chosen", index = picked })
		return picked, chooser
	end

	-- Schritte eines Endes zu festen Zeiten abspielen (`at` ab start, `arrive` ab arrival)
	local function runTimed(steps, start, arrival)
		local timed = {}
		for _, step in steps do
			if step.at or step.arrive then
				table.insert(timed, { time = step.at and start + step.at or arrival + step.arrive, step = step })
			end
		end
		table.sort(timed, function(a, b)
			return a.time < b.time
		end)
		for _, entry in timed do
			waitUntil(entry.time)
			if entry.step.finish then
				cutscene:SetAttribute("Finished", true)
				for _, player in Players:GetPlayers() do
					local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.WalkSpeed = 0
					end
				end
			else
				runLine(entry.step)
			end
		end
	end

	-- Ende "follow": Die Spieler steigen aus und laufen selbst. Sarp geht ein Stück voraus
	-- und wartet, wenn man zurückbleibt. Wer an der Veranda ankommt, beendet den Weg.
	local function runFollow(steps, start)
		waitUntil(start + 1.2) -- jetzt ist der Bildschirm schwarz
		for index, player in Players:GetPlayers() do
			task.spawn(function()
				player.CameraMode = Enum.CameraMode.LockFirstPerson
				player:LoadCharacter()
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = Route.WALK_SPEED
					humanoid.UseJumpPower = false
					humanoid.JumpHeight = 2
					character:PivotTo(Route.walkerSpawn(index) + Vector3.new(0, humanoid.HipHeight + 1.5, 0))
				end
				player.ReplicationFocus = nil
			end)
		end

		local length = Route.walkLine().length
		local sarpS = 6
		cutscene:SetAttribute("SarpS", sarpS)
		local queue, nextProgress = {}, 1
		local progressSteps = {}
		for _, step in steps do
			if step.progress then
				table.insert(progressSteps, step)
			end
		end
		table.sort(progressSteps, function(a, b)
			return a.progress < b.progress
		end)
		-- Erzählung nacheinander abspielen, während weiter gelaufen wird
		local speaking = false
		local function speakQueued()
			if speaking then
				return
			end
			speaking = true
			task.spawn(function()
				while #queue > 0 do
					runLine(table.remove(queue, 1))
				end
				speaking = false
			end)
		end

		while true do
			task.wait(0.2)
			local furthest = 0
			for _, player in Players:GetPlayers() do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local s, distance = Route.walkProgress(root.Position)
					if distance < 40 then
						furthest = math.max(furthest, s)
					end
				end
			end
			-- Sarp bleibt ein paar Schritte vor dem vordersten Spieler
			local target = math.clamp(furthest + 10, 6, length)
			if target > sarpS + 0.5 then
				sarpS = target
				cutscene:SetAttribute("SarpS", sarpS)
			end
			while progressSteps[nextProgress] and furthest >= progressSteps[nextProgress].progress * length do
				table.insert(queue, progressSteps[nextProgress])
				nextProgress += 1
				speakQueued()
			end
			if furthest >= length - Route.ARRIVE_DISTANCE then
				break
			end
		end
		cutscene:SetAttribute("SarpS", length)
		while speaking do
			task.wait(0.1)
		end
		local now = workspace:GetServerTimeNow()
		cutscene:SetAttribute("ArrivedAt", now)
		runTimed(steps, now, now)
	end

	task.spawn(function()
		waitUntil(startTime + Route.strangerArrival() + Route.DIALOGUE_DELAY)

		-- Das Gespräch am Fenster
		local ending = "drive"
		for _, step in Dialogue.SCRIPT do
			if step.choice then
				local index, chooser = ask(step.choice)
				local option = step.choice[index]
				say("player", option.text, chooser and chooser.DisplayName or "You")
				for _, line in option.reply do
					runLine(line)
				end
				ending = option.ending or ending
			else
				runLine(step)
			end
		end

		-- Das Ende beginnt: alle Clients lesen Branch und BranchStart und spielen es ab
		local branchStart = workspace:GetServerTimeNow() + 0.6
		cutscene:SetAttribute("BranchStart", branchStart)
		cutscene:SetAttribute("Branch", ending)

		if ending == "drive" then
			runTimed(Dialogue.ENDINGS.drive, branchStart, branchStart + Route.driveDuration())
		else
			runFollow(Dialogue.ENDINGS.follow, branchStart)
		end
	end)
end

return DialogueRunner
