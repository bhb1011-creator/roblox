-- Alles, was nur der Spieler selbst sieht: Aussteigen-Knopf, Abblenden bei der
-- Abfahrt, Hinweise, Shop-Fenster und flackernde Lichter.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local function create(className, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local gui = create("ScreenGui", {
	Name = "LobbyHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 5,
	Parent = player:WaitForChild("PlayerGui"),
})

-- Schwarzer Bildschirm für die Abfahrt
local fade = create("Frame", {
	Name = "Fade",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	ZIndex = 10,
	Parent = gui,
})

local function fadeTo(transparency, duration)
	TweenService:Create(fade, TweenInfo.new(duration), { BackgroundTransparency = transparency }):Play()
end

-- Hinweise oben in der Mitte
local toast = create("TextLabel", {
	Name = "Toast",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 90),
	Size = UDim2.new(0.8, 0, 0, 40),
	BackgroundTransparency = 1,
	Font = Enum.Font.SpecialElite,
	TextSize = 28,
	TextColor3 = Color3.fromRGB(240, 225, 205),
	TextStrokeTransparency = 1,
	TextTransparency = 1,
	TextWrapped = true,
	ZIndex = 11,
	Parent = gui,
})

local toastToken = 0
local function showToast(text, duration)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 0, TextStrokeTransparency = 0.4 }):Play()
	task.delay(duration or 4, function()
		if token == toastToken then
			TweenService:Create(toast, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text)
	showToast(text, 5)
end)

-- Aussteigen-Knopf, solange man in einem Lobby-Auto sitzt
local exitButton = create("TextButton", {
	Name = "ExitCar",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -110),
	Size = UDim2.fromOffset(200, 50),
	BackgroundColor3 = Color3.fromRGB(25, 20, 20),
	BackgroundTransparency = 0.2,
	Font = Enum.Font.GothamBold,
	Text = "Aussteigen",
	TextSize = 22,
	TextColor3 = Color3.fromRGB(240, 225, 205),
	Visible = false,
	Parent = gui,
}, {
	corner(10),
	create("UIStroke", { Color = Color3.fromRGB(150, 60, 50), Thickness = 2 }),
})

-- Shop-Fenster (Platzhalter, bis es Items gibt)
local shopWindow = create("Frame", {
	Name = "ShopWindow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(420, 240),
	BackgroundColor3 = Color3.fromRGB(22, 18, 16),
	BackgroundTransparency = 0.05,
	Visible = false,
	ZIndex = 20,
	Parent = gui,
}, {
	corner(14),
	create("UIStroke", { Color = Color3.fromRGB(255, 210, 120), Thickness = 2, Transparency = 0.3 }),
	create("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "🛒 SHOP",
		TextSize = 32,
		TextColor3 = Color3.fromRGB(255, 210, 120),
		ZIndex = 21,
	}),
	create("TextLabel", {
		Name = "Body",
		Position = UDim2.new(0, 24, 0, 70),
		Size = UDim2.new(1, -48, 0, 90),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = "Hier kannst du bald Items und Spezial-Items kaufen.\nKomm später wieder!",
		TextSize = 20,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(230, 220, 205),
		ZIndex = 21,
	}),
})
local closeShop = create("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -18),
	Size = UDim2.fromOffset(160, 42),
	BackgroundColor3 = Color3.fromRGB(150, 45, 40),
	Font = Enum.Font.GothamBold,
	Text = "Schließen",
	TextSize = 20,
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 21,
	Parent = shopWindow,
}, { corner(10) })

closeShop.Activated:Connect(function()
	shopWindow.Visible = false
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer == player and CollectionService:HasTag(prompt, "ShopPrompt") then
		shopWindow.Visible = true
	end
end)

-- Sitzen im Auto verfolgen
local currentCar
local stateConnection
local fadeToken = 0

local function getHumanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function updateSeatUi()
	local state = currentCar and currentCar:GetAttribute("State")
	local departing = state == "Departing"
	exitButton.Visible = currentCar ~= nil and not departing

	local humanoid = getHumanoid()
	if humanoid then
		-- Während der Fahrt kann man nicht herausspringen
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not departing)
	end

	if departing then
		fadeToken += 1
		local token = fadeToken
		task.delay(Config.FADE_DELAY, function()
			if token == fadeToken and currentCar then
				fadeTo(0, 2)
			end
		end)
	end
end

local function onSeated(active, seatPart)
	if stateConnection then
		stateConnection:Disconnect()
		stateConnection = nil
	end
	if active and seatPart and seatPart:GetAttribute("LobbyCar") then
		currentCar = seatPart.Parent
		stateConnection = currentCar:GetAttributeChangedSignal("State"):Connect(updateSeatUi)
	else
		currentCar = nil
		fadeToken += 1
	end
	updateSeatUi()
end

exitButton.Activated:Connect(function()
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.Sit = false
	end
end)

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Seated:Connect(onSeated)
	onSeated(false, nil)
	fadeTo(1, 1.5)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end

-- Laternen flackern ab und zu
local lamps = {}
local function registerLamp(head)
	local light = head:FindFirstChildWhichIsA("Light")
	if light then
		lamps[head] = { light = light, brightness = light.Brightness, color = head.Color }
	end
end
for _, head in CollectionService:GetTagged("FlickerLamp") do
	registerLamp(head)
end
CollectionService:GetInstanceAddedSignal("FlickerLamp"):Connect(registerLamp)
CollectionService:GetInstanceRemovedSignal("FlickerLamp"):Connect(function(head)
	lamps[head] = nil
end)

local rng = Random.new()
task.spawn(function()
	while true do
		task.wait(rng:NextNumber(1.5, 5))
		local heads = {}
		for head in lamps do
			table.insert(heads, head)
		end
		if #heads > 0 then
			local head = heads[rng:NextInteger(1, #heads)]
			local info = lamps[head]
			for _ = 1, rng:NextInteger(2, 5) do
				info.light.Brightness = info.brightness * 0.1
				head.Color = info.color:Lerp(Color3.new(0, 0, 0), 0.7)
				task.wait(rng:NextNumber(0.04, 0.12))
				info.light.Brightness = info.brightness
				head.Color = info.color
				task.wait(rng:NextNumber(0.05, 0.25))
			end
		end
	end
end)

-- Das Lagerfeuer-Licht zuckt leicht
local fires = {}
local function registerFire(part)
	local light = part:FindFirstChildWhichIsA("Light")
	if light then
		fires[part] = { light = light, brightness = light.Brightness }
	end
end
for _, part in CollectionService:GetTagged("Campfire") do
	registerFire(part)
end
CollectionService:GetInstanceAddedSignal("Campfire"):Connect(registerFire)
CollectionService:GetInstanceRemovedSignal("Campfire"):Connect(function(part)
	fires[part] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, info in fires do
		info.light.Brightness = info.brightness * (0.85 + 0.15 * math.noise(t * 3, 0.5))
			+ rng:NextNumber(-0.08, 0.08)
	end
end)

task.delay(2, function()
	showToast("Willkommen. Steig in ein Auto, wenn du bereit bist…", 5)
end)
