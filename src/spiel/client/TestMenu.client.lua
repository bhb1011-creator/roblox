-- Testmenü (nur in Roblox Studio, ganzes Spiel): Taste O oder der Knopf oben links.
-- Beim Start erscheint es von selbst: dort aussuchen, wo das Spiel losgehen soll.
-- Mitten im Spiel zeigt es nur, wo man gestartet ist – zum Springen: Stop, dann Play.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local TestStarts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TestStarts"))
local player = Players.LocalPlayer

-- Kurz warten, ob der Server das Menü überhaupt anbietet (im echten Spiel nicht)
local waited = 0
while not ReplicatedStorage:GetAttribute("TestMenu") and ReplicatedStorage:GetAttribute("StartChoice") == nil and waited < 10 do
	waited += task.wait(0.2)
end
if not ReplicatedStorage:GetAttribute("TestMenu") then
	return
end
local pick = ReplicatedStorage:WaitForChild("TestMenuPick")

local function create(className, props)
	local item = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			item[key] = value
		end
	end
	item.Parent = props.Parent
	return item
end

local gui = create("ScreenGui", {
	Name = "TestMenu",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 100, -- über allem (auch über dem schwarzen Abblenden)
	Parent = player:WaitForChild("PlayerGui"),
})

-- kleiner Knopf oben links (auch fürs Handy)
local openButton = create("TextButton", {
	Name = "Open",
	Size = UDim2.fromOffset(84, 30),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -12), -- unten links (oben liegen die Roblox-Knöpfe)
	BackgroundColor3 = Color3.fromRGB(30, 30, 34),
	BackgroundTransparency = 0.25,
	TextColor3 = Color3.fromRGB(230, 230, 230),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Text = "Test (O)",
	AutoButtonColor = true,
	Parent = gui,
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = openButton })

-- Tag-Schalter (Taste T): macht alles hell wie am Mittag, um die Umgebung auf Fehler zu prüfen.
-- Nur auf diesem Bildschirm; die Kapitel setzen ihr Licht ständig neu, deshalb wird der Tag jedes Bild erzwungen.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local dayButton = create("TextButton", {
	Name = "Day",
	Size = UDim2.fromOffset(84, 30),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 104, 1, -12),
	BackgroundColor3 = Color3.fromRGB(30, 30, 34),
	BackgroundTransparency = 0.25,
	TextColor3 = Color3.fromRGB(230, 230, 230),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Text = "Tag (T)",
	AutoButtonColor = true,
	Parent = gui,
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = dayButton })
local DAY = {
	ClockTime = 13,
	Brightness = 3,
	Ambient = Color3.fromRGB(150, 150, 150),
	OutdoorAmbient = Color3.fromRGB(170, 170, 170),
	ExposureCompensation = 0,
	FogEnd = 100000,
	FogStart = 0,
	GlobalShadows = true,
}
local dayOn = false
local savedLight, hidden = {}, {}
local dayConnection
local function setDay(on)
	if on == dayOn then
		return
	end
	dayOn = on
	dayButton.Text = on and "Nacht (T)" or "Tag (T)"
	if on then
		for key in DAY do
			savedLight[key] = Lighting[key]
		end
		dayConnection = RunService.RenderStepped:Connect(function()
			for key, value in DAY do
				Lighting[key] = value
			end
			-- Nebel, Farbfilter und Unschärfe der Kapitel ausschalten (merken, um sie zurückzugeben)
			for _, child in Lighting:GetChildren() do
				if child:IsA("Atmosphere") and child.Density > 0.05 then
					hidden[child] = hidden[child] or { "Density", child.Density }
					child.Density = 0.05
				elseif (child:IsA("ColorCorrectionEffect") or child:IsA("BlurEffect") or child:IsA("DepthOfFieldEffect")) and child.Enabled then
					hidden[child] = hidden[child] or { "Enabled", true }
					child.Enabled = false
				end
			end
		end)
	else
		if dayConnection then
			dayConnection:Disconnect()
		end
		for key, value in savedLight do
			Lighting[key] = value
		end
		for child, info in hidden do
			if child.Parent then
				child[info[1]] = info[2]
			end
		end
		table.clear(hidden)
	end
end
dayButton.Activated:Connect(function()
	setDay(not dayOn)
end)

-- (scrollt, wenn das Fenster klein ist)
local panel = create("ScrollingFrame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.92, 0.88),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6,
	BorderSizePixel = 0,
	BackgroundColor3 = Color3.fromRGB(16, 16, 20),
	BackgroundTransparency = 0.05,
	Visible = false,
	Parent = gui,
})
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = panel })
create("UIStroke", { Color = Color3.fromRGB(120, 30, 30), Thickness = 2, Parent = panel })
create("UIPadding", {
	PaddingTop = UDim.new(0, 14),
	PaddingBottom = UDim.new(0, 14),
	PaddingLeft = UDim.new(0, 14),
	PaddingRight = UDim.new(0, 14),
	Parent = panel,
})
create("UISizeConstraint", { MaxSize = Vector2.new(460, 640), Parent = panel })
create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

local title = create("TextLabel", {
	LayoutOrder = 0,
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(240, 220, 220),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "TESTMENÜ – Wo willst du starten?",
	Parent = panel,
})
local note = create("TextLabel", {
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(180, 180, 186),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
	Parent = panel,
})

local buttons = {}
for index, entry in TestStarts do
	local button = create("TextButton", {
		LayoutOrder = 10 + index,
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Color3.fromRGB(36, 36, 44),
		AutoButtonColor = true,
		Text = "",
		Parent = panel,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = button })
	create("TextLabel", {
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.fromOffset(10, 4),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(235, 235, 235),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = index .. ".  " .. entry.title,
		Parent = button,
	})
	create("TextLabel", {
		Size = UDim2.new(1, -20, 0, 16),
		Position = UDim2.fromOffset(10, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(160, 160, 168),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = entry.info,
		Parent = button,
	})
	button.Activated:Connect(function()
		if ReplicatedStorage:GetAttribute("StartChoice") == nil then
			pick:FireServer(entry.id)
		end
	end)
	buttons[entry.id] = button
end

local function chosenTitle()
	local chosen = ReplicatedStorage:GetAttribute("StartChoice")
	for _, entry in TestStarts do
		if entry.id == chosen then
			return entry.title
		end
	end
	return "?"
end

local function refresh()
	local chosen = ReplicatedStorage:GetAttribute("StartChoice")
	if chosen == nil then
		title.Text = "TESTMENÜ – Wo willst du starten?"
		note.Text = "Anklicken oder Zahl drücken (1–" .. #TestStarts .. "). Ohne Wahl geht es nach 40 Sekunden normal mit Kapitel 1 los."
	else
		title.Text = "TESTMENÜ"
		note.Text = "Gestartet bei: " .. chosenTitle() .. "\nZum Springen: in Studio Stop drücken, dann Play – das Menü kommt beim Start von selbst."
	end
	for id, button in buttons do
		button.BackgroundColor3 = id == chosen and Color3.fromRGB(110, 34, 34) or Color3.fromRGB(36, 36, 44)
		button.AutoButtonColor = chosen == nil
	end
end

local savedMouse
local function setOpen(open)
	panel.Visible = open
	if open then
		savedMouse = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	elseif savedMouse then
		UserInputService.MouseBehavior = savedMouse
	end
end

-- Solange noch nicht gewählt ist, die Maus freihalten (die Kapitel sperren sie sonst)
task.spawn(function()
	while ReplicatedStorage:GetAttribute("StartChoice") == nil do
		if panel.Visible then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
		task.wait()
	end
end)

ReplicatedStorage:GetAttributeChangedSignal("StartChoice"):Connect(function()
	refresh()
	task.delay(0.6, function()
		setOpen(false)
	end)
end)
openButton.Activated:Connect(function()
	setOpen(not panel.Visible)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.T then
		setDay(not dayOn)
		return
	end
	if input.KeyCode == Enum.KeyCode.O then
		setOpen(not panel.Visible)
	elseif panel.Visible and ReplicatedStorage:GetAttribute("StartChoice") == nil then
		local number = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
		local entry = TestStarts[number]
		if entry and number >= 1 then
			pick:FireServer(entry.id)
		end
	end
end)

refresh()
setOpen(ReplicatedStorage:GetAttribute("StartChoice") == nil)

-- "Figuren ansehen": Kamera fährt der Reihe nach zu jeder Figur (Gesicht nah, dann ganz).
-- Taste N = nächste Figur, Taste B = Kamera wieder frei.
local function figureCamera()
	local RunService = game:GetService("RunService")
	local folder = workspace:WaitForChild("Figuren", 30)
	if not folder then
		return
	end
	-- Charakterliste: Reihenfolge kommt vom Server (Attribut "Order")
	if ReplicatedStorage:GetAttribute("StartChoice") == "charaktere" then
		local waitUntil = os.clock() + 30
		while folder:GetAttribute("Order") == nil and os.clock() < waitUntil do
			task.wait(0.2)
		end
	end
	local listed = folder:GetAttribute("Order")
	local order = listed and string.split(listed, ",") or { "MrsWagner", "Lucy", "MrWagner", "Tommy" }
	local index, close, free = 1, true, false
	local switchAt = os.clock() + 5
	local camera = workspace.CurrentCamera
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.N then
			free = false
			close = not close
			if close then
				index = index % #order + 1
			end
			switchAt = os.clock() + 5
		elseif input.KeyCode == Enum.KeyCode.B then
			free = true
			camera.CameraType = Enum.CameraType.Custom
		end
	end)
	RunService.RenderStepped:Connect(function()
		if free then
			return
		end
		if os.clock() > switchAt then
			close = not close
			if close then
				index = index % #order + 1
			end
			switchAt = os.clock() + 5
		end
		local model = folder:FindFirstChild(order[index])
		local head = model and model:FindFirstChild("Head")
		local root = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
		if not (head and root) then
			return
		end
		camera.CameraType = Enum.CameraType.Scriptable
		local front = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		front = front.Magnitude > 0.01 and front.Unit or Vector3.new(0, 0, -1)
		-- große Figuren (das Biest) aus mehr Abstand
		local _, size = model:GetBoundingBox()
		local scale = math.max(1, size.Y / 6)
		if close then
			camera.CFrame = CFrame.lookAt(head.Position + front * 3 * scale + Vector3.new(0.6, 0.15, 0), head.Position)
		else
			local middle = model:GetPivot().Position + Vector3.new(0, size.Y * 0.45, 0)
			camera.CFrame = CFrame.lookAt(middle + front * 7 * scale + Vector3.new(2, 0.8, 0), middle)
		end
	end)
end
local function maybeFigures()
	local choice = ReplicatedStorage:GetAttribute("StartChoice")
	if choice == "figuren" or choice == "charaktere" then
		task.spawn(figureCamera)
	end
end
ReplicatedStorage:GetAttributeChangedSignal("StartChoice"):Connect(maybeFigures)
maybeFigures()
