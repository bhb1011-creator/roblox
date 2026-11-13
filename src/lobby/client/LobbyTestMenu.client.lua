-- Testmenü der Lobby (nur in Roblox Studio): Taste O oder Knopf oben rechts.
-- Öffnet jeden Shop-/Kiosk-Reiter direkt, gibt Münzen, setzt Käufe zurück.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

if not RunService:IsStudio() then
	return
end
-- liegt im selben Ort das Level, gibt es dort ein eigenes Testmenü
if game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Level") then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local action = ReplicatedStorage:WaitForChild("LobbyTestAction", 15)

local ENTRIES = {
	{ "Shop: Bundles", "open", "Bundles" },
	{ "Shop: Suits & Skins (Figuren)", "open", "Skins" },
	{ "Shop: Clothing", "open", "Clothing" },
	{ "Shop: Passes", "open", "Passes" },
	{ "Shop: Coins", "open", "Coins" },
	{ "Kiosk: Snacks", "open", "Snacks" },
	{ "Kiosk: Extras", "open", "Extras" },
	{ "+5,000 Münzen", "coins" },
	{ "Käufe zurücksetzen (5,000 Münzen)", "reset" },
	{ "Zur Lobby (Menü schließen)", "close" },
}
-- Lobby und Spiel in einer Testdatei (alles.project.json): auch jedes Kapitel starten
local combined = ReplicatedStorage:GetAttribute("Combined") == true
if combined then
	local TestStarts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TestStarts"))
	-- Kapitel oben im Menü (Zahlentasten 1–9)
	for index, start in TestStarts do
		table.insert(ENTRIES, index, { "Spiel: " .. start.title, "start", start.id })
	end
end

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

local gui = create("ScreenGui", { Name = "LobbyTestMenu", ResetOnSpawn = false, DisplayOrder = 100, Parent = playerGui })
local openButton = create("TextButton", {
	Name = "Open",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12), -- oben in der Mitte: rechts liegt das X des Shops
	Size = UDim2.fromOffset(96, 36),
	BackgroundColor3 = Color3.fromRGB(30, 30, 34),
	BackgroundTransparency = 0.25,
	TextColor3 = Color3.fromRGB(230, 230, 230),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Text = "Test (O)",
	Parent = gui,
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = openButton })

local panel = create("ScrollingFrame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.9, 0.86),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6,
	BorderSizePixel = 0,
	BackgroundColor3 = Color3.fromRGB(16, 16, 20),
	BackgroundTransparency = 0.05,
	Visible = true, -- in Studio startet man direkt im Testmenü
	Parent = gui,
})
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = panel })
-- unsichtbarer Modal-Knopf: solange das Menü offen ist, ist der Mauszeiger frei (sonst Ich-Sicht-Sperre)
create("TextButton", { Name = "FreeMouse", Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Text = "", Modal = true, Parent = panel })
create("UIStroke", { Color = Color3.fromRGB(120, 30, 30), Thickness = 2, Parent = panel })
create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = panel })
create("UISizeConstraint", { MaxSize = Vector2.new(420, 640), Parent = panel })
create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
create("TextLabel", {
	LayoutOrder = 0,
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(240, 220, 220),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "TESTMENÜ – Lobby",
	Parent = panel,
})
create("TextLabel", {
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(180, 180, 186),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Anklicken oder Zahl drücken. „Zur Lobby“ schließt das Menü (wieder öffnen mit O)."
		.. (combined and " Ein Kapitel startet das Spiel; zurück in die Lobby: Stop, dann Play." or ""),
	Parent = panel,
})

local function run(entry)
	panel.Visible = false
	if entry[2] == "open" then
		local shop = playerGui:FindFirstChild("VipShop")
		if shop then
			shop:SetAttribute("TestOpen", nil)
			shop:SetAttribute("TestOpen", entry[3])
		end
	elseif entry[2] == "close" then
		return
	elseif entry[2] == "start" then
		if action then
			action:FireServer("start", entry[3])
		end
	elseif action then
		action:FireServer(entry[2])
	end
end

for index, entry in ENTRIES do
	local button = create("TextButton", {
		LayoutOrder = index + 1,
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Color3.fromRGB(40, 40, 46),
		TextColor3 = Color3.fromRGB(235, 235, 235),
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "  " .. index .. ".  " .. entry[1],
		Parent = panel,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = button })
	button.Activated:Connect(function()
		run(entry)
	end)
end

openButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.O then
		panel.Visible = not panel.Visible
	elseif panel.Visible then
		local number = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
		if number >= 1 and number <= #ENTRIES then
			run(ENTRIES[number])
		end
	end
end)

-- Kapitel gestartet: alles von der Lobby auf dem Bildschirm wegräumen und die Lobby-Skripte stoppen
local function leaveLobby()
	for _, name in { "VipShop", "LobbyHUD", "Crosshair" } do
		local item = playerGui:FindFirstChild(name)
		if item then
			item:Destroy()
		end
	end
	pcall(RunService.UnbindFromRenderStep, RunService, "FirstPersonPolish")
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 128
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	gui:Destroy()
	local scripts = player:FindFirstChild("PlayerScripts")
	local lobby = scripts and scripts:FindFirstChild("Lobby")
	if lobby then
		task.defer(lobby.Destroy, lobby)
	end
end
if combined then
	if ReplicatedStorage:GetAttribute("StartChoice") ~= nil then
		leaveLobby()
	else
		ReplicatedStorage:GetAttributeChangedSignal("StartChoice"):Connect(leaveLobby)
	end
end
