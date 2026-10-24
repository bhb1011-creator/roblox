-- Sprachausgabe auf Englisch (Text-to-Speech von Roblox) und Untertitel.
-- Klappt die Sprachausgabe nicht (z. B. weil Roblox sie im Spiel noch nicht erlaubt),
-- erscheint eine Warnung im Output und man sieht nur die Untertitel.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- Sarp klingt mit etwas Hall, als stünde er zu nah am offenen Fenster
local function effectChain(speaker, source)
	if speaker ~= "sarp" then
		return source
	end
	local ok, reverb = pcall(function()
		local effect = Instance.new("AudioReverb")
		effect.Parent = source
		return effect
	end)
	if not ok then
		return source
	end
	connect(source, reverb)
	return reverb
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
		for property, value in { Pitch = voice.pitch, Speed = voice.speed, Volume = voice.volume } do
			pcall(function()
				tts[property] = value
			end)
		end
		tts.Parent = SoundService
		connect(effectChain(speaker, tts), output)
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
	nameLabel.Size = UDim2.new(1, 0, 0, 26)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.SpecialElite
	nameLabel.TextSize = 20
	nameLabel.TextTransparency = 1
	nameLabel.TextStrokeTransparency = 1
	nameLabel.ZIndex = 6
	nameLabel.Parent = frame

	textLabel = Instance.new("TextLabel")
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
function Speech.say(speaker, name, text, duration)
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
	if Config.SPEECH_ENABLED ~= false then
		task.spawn(speak, speaker, text)
	end
end

function Speech.isSpeaking()
	return os.clock() < speakingUntil
end

return Speech
