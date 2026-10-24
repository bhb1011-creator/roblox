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

		local arrival = ending == "drive" and Route.driveDuration() or Route.walkDuration()
		local steps = {}
		for _, step in Dialogue.ENDINGS[ending] do
			table.insert(steps, { time = branchStart + (step.at or arrival + step.arrive), step = step })
		end
		table.sort(steps, function(a, b)
			return a.time < b.time
		end)
		for _, entry in steps do
			waitUntil(entry.time)
			if entry.step.finish then
				cutscene:SetAttribute("Finished", true)
			else
				runLine(entry.step)
			end
		end
	end)
end

return DialogueRunner
