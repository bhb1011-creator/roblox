-- Ladebildschirm der Ausstellung: wartet, bis der Server alles gebaut hat, und lädt dann alle
-- Formen und Texturen (Figuren, Kleidung) vor. Fehlgeschlagene Dateien werden bis zu 3x neu
-- versucht. Bei sehr langsamem Internet kann man nach 15 s trotzdem weiter.
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Laden"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false

local back = Instance.new("Frame")
back.Size = UDim2.fromScale(1, 1)
back.BackgroundColor3 = Color3.fromRGB(14, 13, 16)
back.BorderSizePixel = 0
back.Parent = gui

local function label(text, size, y, color, font)
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.AnchorPoint = Vector2.new(0.5, 0.5)
	item.Position = UDim2.fromScale(0.5, y)
	item.Size = UDim2.new(0.8, 0, 0, size)
	item.Font = font or Enum.Font.GothamMedium
	item.TextSize = size
	item.TextColor3 = color
	item.Text = text
	item.Parent = back
	return item
end

label("SHOP SHOWCASE", 34, 0.42, Color3.fromRGB(212, 168, 70), Enum.Font.GothamBlack)
local status = label("Building the showcase...", 18, 0.5, Color3.fromRGB(230, 226, 218))

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 0.5)
bar.Position = UDim2.fromScale(0.5, 0.56)
bar.Size = UDim2.new(0, 360, 0, 8)
bar.BackgroundColor3 = Color3.fromRGB(45, 43, 48)
bar.BorderSizePixel = 0
bar.Parent = back
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = bar
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(212, 168, 70)
fill.BorderSizePixel = 0
fill.Parent = bar
corner:Clone().Parent = fill

local skip = Instance.new("TextButton")
skip.AnchorPoint = Vector2.new(0.5, 0.5)
skip.Position = UDim2.fromScale(0.5, 0.64)
skip.Size = UDim2.new(0, 200, 0, 40)
skip.BackgroundColor3 = Color3.fromRGB(45, 43, 48)
skip.TextColor3 = Color3.fromRGB(230, 226, 218)
skip.Font = Enum.Font.GothamBold
skip.TextSize = 16
skip.Text = "Continue anyway"
skip.Visible = false
skip.Parent = back
corner:Clone().Parent = skip

gui.Parent = player:WaitForChild("PlayerGui")

local done = false
skip.Activated:Connect(function()
	done = true
end)
task.delay(15, function()
	if not done then
		skip.Visible = true
	end
end)

-- 1) warten, bis der Server fertig gebaut hat
local folder = workspace:WaitForChild("Showcase", 60)
while folder and not folder:GetAttribute("Ready") and not done do
	task.wait(0.2)
end

-- 2) alles sammeln, was Dateien aus dem Internet braucht
local items = {}
local function collect(root)
	if not root then
		return
	end
	for _, item in root:GetDescendants() do
		if item:IsA("MeshPart") or item:IsA("SurfaceAppearance") or item:IsA("Decal") or item:IsA("Texture") then
			table.insert(items, item)
		end
	end
end
collect(folder)
collect(ReplicatedStorage:FindFirstChild("Shop"))

-- 3) vorladen, Fehlschläge bis zu 3x wiederholen
local total = #items
local loaded = 0
local started = os.clock()
local attempt = 0
while #items > 0 and attempt < 4 and not done do
	attempt += 1
	local failed = {}
	for _, item in items do
		if done then
			break
		end
		local ok = true
		pcall(function()
			ContentProvider:PreloadAsync({ item }, function(_, fetchStatus)
				if fetchStatus ~= Enum.AssetFetchStatus.Success then
					ok = false
				end
			end)
		end)
		if ok then
			loaded += 1
		else
			table.insert(failed, item)
		end
		fill.Size = UDim2.fromScale(loaded / math.max(total, 1), 1)
		status.Text = string.format("Loading models and textures  %d / %d%s", loaded, total, attempt > 1 and ("  (retry " .. (attempt - 1) .. ")") or "")
	end
	items = failed
	if #items > 0 and not done then
		status.Text = string.format("%d files are slow, trying again...", #items)
		task.wait(2)
	end
end

if #items > 0 then
	warn(string.format("Ausstellung: %d von %d Dateien nicht geladen (langsames Internet?)", #items, total))
else
	print(string.format("Ausstellung: alles geladen in %.1f s (%d Dateien)", os.clock() - started, total))
end

-- 4) ausblenden
status.Text = "Ready"
local info = TweenInfo.new(0.6)
for _, item in back:GetDescendants() do
	if item:IsA("TextLabel") or item:IsA("TextButton") then
		TweenService:Create(item, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
	elseif item:IsA("Frame") then
		TweenService:Create(item, info, { BackgroundTransparency = 1 }):Play()
	end
end
TweenService:Create(back, info, { BackgroundTransparency = 1 }):Play()
task.wait(0.7)
gui:Destroy()
