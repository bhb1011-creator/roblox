-- Sprachausgabe auf Englisch (Text-to-Speech von Roblox) und Untertitel.
-- Klappt die Sprachausgabe nicht (z. B. weil Roblox sie im Spiel noch nicht erlaubt),
-- erscheint eine Warnung im Output und man sieht nur die Untertitel.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Speech = {}

local NAME_COLORS = {
	sarp = Color3.fromRGB(205, 120, 105),
	player = Color3.fromRGB(150, 190, 225),
}

local output
local warned = false
local speakingUntil = 0
local current = 0
local frame, nameLabel, textLabel

local function connect(source, target)
	local wire = Instance.new("Wire")
	wire.SourceInstance = source
	wire.TargetInstance = target
	wire.Parent = source
end

-- Klangeffekte aus Config.VOICES hintereinander schalten (z. B. Sarp: Bass und Hall).
-- Kennt Roblox einen Effekt oder eine Einstellung nicht, wird sie einfach übersprungen.
local function effectChain(voice, source)
	local last = source
	for _, effect in voice.effects or {} do
		local className, settings = effect[1], effect[2]
		local ok, instance = pcall(Instance.new, className)
		if ok then
			for property, value in settings or {} do
				pcall(function()
					instance[property] = value
				end)
			end
			instance.Parent = source
			connect(last, instance)
			last = instance
		end
	end
	return last
end

local function speak(speaker, text)
	local voice = Config.VOICES and Config.VOICES[speaker] or {}
	local ok, problem = pcall(function()
		if not output then
			output = Instance.new("AudioDeviceOutput")
			output.Name = "SpeechOutput"
			output.Parent = SoundService
		end
		local tts = Instance.new("AudioTextToSpeech")
		tts.Text = text
		tts.VoiceId = voice.id or "1"
		-- Nicht jede Roblox-Version kennt alle Einstellungen, deshalb einzeln versuchen
		-- AutoLocalize aus: sonst übersetzt Roblox den Text in die Sprache des Spielers
		-- (z. B. Deutsch) und spricht ihn mit einer anderen Stimme. Hier bleibt alles Englisch.
		for property, value in { AutoLocalize = false, Pitch = voice.pitch, Speed = voice.speed, Volume = voice.volume } do
			pcall(function()
				tts[property] = value
			end)
		end
		tts.Parent = SoundService
		connect(effectChain(voice, tts), output)
		local status = tts:LoadAsync()
		if status ~= Enum.AssetFetchStatus.Success then
			error("Laden fehlgeschlagen: " .. tostring(status))
		end
		tts:Play()
		task.delay(40, function()
			tts:Destroy()
		end)
	end)
	if not ok and not warned then
		warned = true
		warn("Sprachausgabe (Text-to-Speech) geht hier nicht, es gibt nur Untertitel. Grund:", problem)
	end
end

function Speech.init(gui)
	frame = Instance.new("Frame")
	frame.Name = "Subtitles"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.fromScale(0.5, 0.885)
	frame.Size = UDim2.new(0.8, 0, 0, 90)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 6
	frame.Parent = gui

	nameLabel = Instance.new("TextLabel")
	nameLabel.AutoLocalize = false
	nameLabel.Size = UDim2.new(1, 0, 0, 26)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.SpecialElite
	nameLabel.TextSize = 20
	nameLabel.TextTransparency = 1
	nameLabel.TextStrokeTransparency = 1
	nameLabel.ZIndex = 6
	nameLabel.Parent = frame

	textLabel = Instance.new("TextLabel")
	textLabel.AutoLocalize = false -- Untertitel bleiben Englisch wie die Stimmen
	textLabel.Position = UDim2.fromOffset(0, 26)
	textLabel.Size = UDim2.new(1, 0, 1, -26)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.SpecialElite
	textLabel.TextSize = 24
	textLabel.TextWrapped = true
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.TextColor3 = Color3.fromRGB(240, 235, 225)
	textLabel.TextTransparency = 1
	textLabel.TextStrokeTransparency = 1
	textLabel.ZIndex = 6
	textLabel.Parent = frame
end

local function show(visible, duration)
	for _, label in { nameLabel, textLabel } do
		TweenService:Create(label, TweenInfo.new(duration), {
			TextTransparency = visible and 0 or 1,
			TextStrokeTransparency = visible and 0.5 or 1,
		}):Play()
	end
end

-- speaker: "narrator", "sarp" oder "player"; name: was über dem Text steht
-- Wo eine Stimme herkommt (z. B. Sarps Kopf); ohne Angabe klingt sie überall gleich laut
local emitters = {}
function Speech.setEmitter(speaker, part)
	emitters[speaker] = part
end

-- Alle eigenen Sprachaufnahmen gleich zu Beginn laden, damit sie rechtzeitig bereit
-- sind. Was nicht lädt (z. B. noch in Prüfung bei Roblox oder keine Berechtigung),
-- steht danach im Output; für diese Sätze spricht dann die Roblox-Stimme.
local recordings = {} -- Name -> Vorlage (Sound)
local recordingFolder = Instance.new("Folder")
recordingFolder.Name = "VoiceLines"
recordingFolder.Parent = SoundService

-- Zustand einer Aufnahme: "geladen", "lädt …" oder der Fehler von Roblox
local function statusOf(name)
	local sound = recordings[name]
	if not sound then
		return "keine ID"
	end
	if sound.IsLoaded then
		return "geladen"
	end
	local ok, fetch = pcall(ContentProvider.GetAssetFetchStatus, ContentProvider, sound.SoundId)
	if ok and fetch == Enum.AssetFetchStatus.Failure then
		return "FEHLER (keine Berechtigung, abgelehnt oder noch in Prüfung)"
	elseif ok and fetch == Enum.AssetFetchStatus.TimedOut then
		return "FEHLER (Zeitüberschreitung)"
	end
	return "lädt …"
end
Speech.statusOf = statusOf

function Speech.preload()
	local list = {}
	for name, recording in Config.VOICE_LINES or {} do
		if recording.id ~= "" then
			local sound = Instance.new("Sound")
			sound.Name = name
			sound.SoundId = recording.id
			sound.Parent = recordingFolder
			recordings[name] = sound
			table.insert(list, sound)
		end
	end
	if #list == 0 then
		return
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
		-- Dem Laden noch etwas Zeit geben, dann das Ergebnis in den Output schreiben
		local deadline = os.clock() + 10
		local missing
		repeat
			missing = {}
			for name in recordings do
				if statusOf(name) ~= "geladen" then
					table.insert(missing, name)
				end
			end
			task.wait(0.5)
		until #missing == 0 or os.clock() > deadline
		table.sort(missing)
		if #missing > 0 then
			local lines = {}
			for _, name in missing do
				table.insert(lines, string.format("%s (%s): %s", name, recordings[name].SoundId, statusOf(name)))
			end
			warn(string.format("Sprachaufnahmen: %d von %d laden nicht, dort spricht die Roblox-Stimme:\n  %s", #missing, #list, table.concat(lines, "\n  ")))
		else
			print(string.format("Sprachaufnahmen: alle %d geladen.", #list))
		end
	end)
end

-- Eigene Sprachaufnahme abspielen. Lädt sie noch, wird bis zu 2,5 Sekunden gewartet.
-- Gibt false zurück, wenn sie nicht spielbar ist (dann spricht die Roblox-Stimme).
local function playRecording(speaker, name)
	local template = recordings[name]
	if not template then
		return false
	end
	local deadline = os.clock() + 2.5
	while not template.IsLoaded and os.clock() < deadline and statusOf(name) == "lädt …" do
		task.wait(0.1)
	end
	if not template.IsLoaded then
		warn("Sprachaufnahme nicht spielbar:", name, template.SoundId, statusOf(name))
		return false
	end
	local emitter = emitters[speaker]
	local sound = template:Clone()
	sound.Name = "VoiceLine"
	sound.Volume = 1.3
	sound.RollOffMinDistance = 14
	sound.RollOffMaxDistance = 150
	-- etwas Hall, damit es nach draußen im Wald klingt
	local reverb = Instance.new("ReverbSoundEffect")
	reverb.DecayTime = 1.4
	reverb.Density = 0.8
	reverb.Diffusion = 0.8
	reverb.DryLevel = 0
	reverb.WetLevel = -16
	reverb.Parent = sound
	sound.Parent = (emitter and emitter.Parent) and emitter or SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	return true
end

function Speech.say(speaker, name, text, duration, voiceName)
	current += 1
	local mine = current
	speakingUntil = os.clock() + duration
	nameLabel.Text = name or ""
	nameLabel.TextColor3 = NAME_COLORS[speaker] or Color3.new(1, 1, 1)
	-- Der Erzähler steht in Klammern und etwas blasser da
	if speaker == "narrator" then
		textLabel.Text = text
		textLabel.TextColor3 = Color3.fromRGB(200, 195, 185)
	else
		textLabel.Text = "„" .. text .. "“"
		textLabel.TextColor3 = Color3.fromRGB(245, 240, 230)
	end
	show(true, 0.3)
	task.delay(duration, function()
		if current == mine then
			show(false, 0.6)
		end
	end)
	task.spawn(function()
		local played = voiceName and playRecording(speaker, voiceName)
		if not played and Config.SPEECH_ENABLED ~= false then
			speak(speaker, text)
		end
	end)
end

------------------------------------------------------------------ Audio-Prüfung (nur in Studio)
-- Taste J zeigt eine Liste aller Aufnahmen mit ihrem Zustand, Taste K spielt alle nacheinander ab.
function Speech.debugPanel(gui)
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	if not RunService:IsStudio() then
		return
	end
	local panel = Instance.new("ScrollingFrame")
	panel.Name = "AudioCheck"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -12, 0, 70)
	panel.Size = UDim2.new(0, 520, 0.8, 0)
	panel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.ScrollBarThickness = 6
	panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	panel.CanvasSize = UDim2.new()
	panel.Visible = false
	panel.ZIndex = 20
	panel.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.Name
	layout.Parent = panel
	local hint = Instance.new("TextLabel")
	hint.Name = "!Hint"
	hint.Size = UDim2.new(1, -10, 0, 40)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Code
	hint.TextSize = 14
	hint.TextWrapped = true
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextColor3 = Color3.fromRGB(255, 255, 255)
	hint.Text = "AUDIO-PRÜFUNG  (J = ein/aus, K = alle nacheinander anhören)"
	hint.ZIndex = 21
	hint.Parent = panel
	local rows = {}
	local names = {}
	for name in Config.VOICE_LINES or {} do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		local row = Instance.new("TextLabel")
		row.Name = name
		row.Size = UDim2.new(1, -10, 0, 18)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.Code
		row.TextSize = 13
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.ZIndex = 21
		row.Parent = panel
		rows[name] = row
	end
	task.spawn(function()
		while panel.Parent do
			if panel.Visible then
				for name, row in rows do
					local status = statusOf(name)
					row.Text = string.format("%-24s %s", name, status)
					row.TextColor3 = status == "geladen" and Color3.fromRGB(120, 230, 120)
						or status == "lädt …" and Color3.fromRGB(240, 210, 90)
						or Color3.fromRGB(255, 90, 80)
				end
			end
			task.wait(0.5)
		end
	end)
	local playingAll = false
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.J then
			panel.Visible = not panel.Visible
		elseif input.KeyCode == Enum.KeyCode.K and not playingAll then
			playingAll = true
			panel.Visible = true
			task.spawn(function()
				for _, name in names do
					local row = rows[name]
					row.Text = "> " .. name .. "   (spielt)"
					local sound = recordings[name]
					if sound and sound.IsLoaded then
						local copy = sound:Clone()
						copy.Parent = SoundService
						copy:Play()
						task.wait(math.min(copy.TimeLength, 8) + 0.3)
						copy:Destroy()
					else
						task.wait(0.3)
					end
				end
				playingAll = false
			end)
		end
	end)
end

function Speech.isSpeaking()
	return os.clock() < speakingUntil
end

return Speech
