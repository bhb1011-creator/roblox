-- Kapitel 3 auf dem Client: Kapitelkarte, die Sequenz im Ritualraum mit den drei
-- Quick-Time-Events, die Flucht durch den Wald und Sarps Verwandlung (Stufe 3).
-- Der Server gibt den Takt vor (Nachrichten mit type = "k3"), alles Sichtbare passiert hier:
-- Kamera, Animationen (eigene Kopien bzw. lokale Gelenke), Geräusche, Anzeigen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Kapitel3 = {}

local player = Players.LocalPlayer

------------------------------------------------------------------ Geräusche
-- Solange ein Sound noch keine ID hat (Config.SOUNDS leer): ein vorhandener als Ersatz
local FALLBACK = {
	chapterHit = { "sting", 0.45 },
}

local function makeSound(key, parent, props)
	local id = Config.SOUNDS[key] or ""
	local speed = 1
	if id == "" and FALLBACK[key] then
		id = Config.SOUNDS[FALLBACK[key][1]] or ""
		speed = FALLBACK[key][2]
	end
	if id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = id
	for property, value in props or {} do
		sound[property] = value
	end
	sound.PlaybackSpeed *= speed
	sound.Parent = parent or SoundService
	return sound
end

local function play(key, props, parent)
	local sound = makeSound(key, parent, props)
	if sound then
		sound:Play()
		task.delay(math.max(sound.TimeLength, 6) + 1, function()
			sound:Destroy()
		end)
	end
	return sound
end

------------------------------------------------------------------ Anzeige
local gui, black, cardTop, cardTitle
local function create(className, props)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	instance.Parent = props.Parent
	return instance
end

local function buildGui()
	gui = create("ScreenGui", {
		Name = "Kapitel3UI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 15,
		Parent = player:WaitForChild("PlayerGui"),
	})
	black = create("Frame", {
		Name = "Black",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 50,
		Parent = gui,
	})
	local function cardLabel(y, size, height)
		return create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, y),
			Size = UDim2.new(0.9, 0, 0, height),
			BackgroundTransparency = 1,
			Font = Enum.Font.SpecialElite,
			Text = "",
			TextSize = size,
			TextColor3 = Color3.fromRGB(235, 222, 205),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			AutoLocalize = false,
			ZIndex = 52,
			Parent = gui,
		})
	end
	cardTop = cardLabel(0.42, 30, 40)
	cardTitle = cardLabel(0.5, 52, 64)
end

local function setBlack(transparency, duration)
	if duration and duration > 0 then
		TweenService:Create(black, TweenInfo.new(duration), { BackgroundTransparency = transparency }):Play()
	else
		black.BackgroundTransparency = transparency
	end
end

local function showCard(top, title, visible, duration)
	cardTop.Text = top or cardTop.Text
	cardTitle.Text = title or cardTitle.Text
	for _, label in { cardTop, cardTitle } do
		TweenService:Create(label, TweenInfo.new(duration or 1.5), { TextTransparency = visible and 0 or 1 }):Play()
	end
end

------------------------------------------------------------------ Nachrichten vom Server
local handlers = {}

-- Die Tür ist auf: schwarz, KAPITEL 3
function handlers.card(message)
	setBlack(0, 0.35)
	task.delay(1.2, function()
		play("chapterHit", { Volume = 1.6 })
		showCard("KAPITEL 3", message.title or "", true, 1.8)
	end)
	task.delay(6.2, function()
		showCard(nil, nil, false, 1.4)
	end)
end

function Kapitel3.run()
	buildGui()
	local remotes = ReplicatedStorage:WaitForChild("Kapitel2")
	local event = remotes:WaitForChild("SceneEvent")
	event.OnClientEvent:Connect(function(message)
		if message.type == "k3" then
			local handler = handlers[message.step]
			if handler then
				task.spawn(handler, message)
			end
		elseif message.type == "gameOver" then
			-- Game Over (Scene.lua) liegt darunter: das eigene Schwarz weg
			setBlack(1, 0)
			showCard(nil, nil, false, 0.1)
		end
	end)
end

return Kapitel3
