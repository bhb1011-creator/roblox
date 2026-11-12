-- Ausstellungsplatte für alle Shop-Sachen (nur zum Ansehen, eigenes Projekt showcase.project.json):
-- Spieler-Skins, Familie im goldenen Anzug, alle Sarp-Skins, Sportwagen, Kleidung/Accessoires.
-- Starten: rojo serve showcase.project.json, in Studio Connect und Play.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Parts = require(Shared.Parts)
local RealFigure = require(Shared.RealFigure)
local Skins = require(Shared.Skins)
local SportsCar = require(Shared.SportsCar)
local ShopCatalog = require(Shared.ShopCatalog)

local GOLD = Color3.fromRGB(212, 168, 70)
local FLOOR = Color3.fromRGB(34, 34, 38)
local STAND = Color3.fromRGB(22, 22, 25)
local TEXT = Color3.fromRGB(240, 236, 228)
local GREY = Color3.fromRGB(170, 166, 158)

local folder = Instance.new("Folder")
folder.Name = "Showcase"
folder.Parent = workspace

------------------------------------------------------------------ Licht: heller Ausstellungsraum
Lighting.ClockTime = 14.5
Lighting.Brightness = 2.2
Lighting.Ambient = Color3.fromRGB(95, 95, 100)
Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 125)
Lighting.ExposureCompensation = 0
Lighting.GlobalShadows = true
for _, child in Lighting:GetChildren() do
	if child:IsA("Atmosphere") or child:IsA("PostEffect") then
		child:Destroy()
	end
end
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.4
bloom.Threshold = 1.4
bloom.Size = 18
bloom.Parent = Lighting

------------------------------------------------------------------ Boden
for _, name in { "Baseplate", "SpawnLocation" } do
	local existing = workspace:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end
Parts.new("Part", { Name = "Floor", Size = Vector3.new(250, 2, 190), CFrame = CFrame.new(0, -1, -10), Color = FLOOR, Material = Enum.Material.Marble, Parent = folder })
for _, info in { { 0, -105, 250, 0.6 }, { 0, 85, 250, 0.6 }, { -125, -10, 0.6, 190 }, { 125, -10, 0.6, 190 } } do
	Parts.new("Part", { Name = "FloorTrim", Size = Vector3.new(info[3], 0.12, info[4]), CFrame = CFrame.new(info[1], 0.05, info[2]), Color = GOLD, Material = Enum.Material.Metal, Parent = folder })
end
local spawn = Instance.new("SpawnLocation")
spawn.Name = "SpawnLocation"
spawn.Anchored = true
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.new(0, 0.5, 75)
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Neutral = true
spawn.Parent = folder

------------------------------------------------------------------ Helfer
local function sign(cframe, width, height, title, lines, accent)
	local board = Parts.new("Part", { Name = "Sign", Size = Vector3.new(width, height, 0.25), CFrame = cframe, Color = STAND, Material = Enum.Material.SmoothPlastic, Parent = folder })
	Parts.new("Part", { Name = "SignTrim", Size = Vector3.new(width + 0.2, 0.12, 0.3), CFrame = cframe * CFrame.new(0, height / 2, 0), Color = accent or GOLD, Material = Enum.Material.Metal, Parent = folder })
	local gui = Parts.surfaceGui(board, Enum.NormalId.Back, true)
	gui.PixelsPerStud = 60
	Parts.text(gui, { Text = title, Font = Enum.Font.GothamBlack, TextColor3 = accent or GOLD, Size = UDim2.fromScale(0.92, 0.42), Position = UDim2.fromScale(0.04, 0.06) })
	Parts.text(gui, { Text = lines or "", Font = Enum.Font.GothamMedium, TextColor3 = TEXT, Size = UDim2.fromScale(0.92, 0.42), Position = UDim2.fromScale(0.04, 0.52) })
	return board
end

local function sectionTitle(z, text, subtitle)
	sign(CFrame.new(0, 9, z - 7), 60, 6, text, subtitle)
end

local function pedestal(position, diameter, height, accent)
	Parts.column({ Name = "Pedestal", Color = STAND, Material = Enum.Material.SmoothPlastic, Parent = folder }, height, diameter, CFrame.new(position))
	Parts.column({ Name = "PedestalRim", Color = accent or GOLD, Material = Enum.Material.Metal, Parent = folder }, 0.12, diameter + 0.25, CFrame.new(position + Vector3.new(0, height - 0.06, 0)))
	local lamp = Parts.new("Part", { Name = "StandLight", Size = Vector3.new(0.5, 0.2, 0.5), CFrame = CFrame.new(position + Vector3.new(0, height + 12, 4)), Transparency = 1, CanCollide = false, Parent = folder })
	Parts.light("SpotLight", lamp, { Face = Enum.NormalId.Bottom, Angle = 50, Range = 22, Brightness = 1.4, Color = Color3.fromRGB(255, 244, 225), Shadows = true })
	return position + Vector3.new(0, height, 0)
end

-- Größen wie im Spiel (Wagners.lua, SarpStage2.lua, Spielerfiguren)
local HEIGHTS = { MrsWagner = 5.3, MrWagner = 5.9, Lucy = 4.3, Tommy = 3.6, Sarp2 = 6.9 }

-- Figur aufstellen (schaut zur Spawn-Seite, +Z), optional mit Skin
local function figure(templateFolder, templateName, position, skinId, skinOptions)
	local container = ReplicatedStorage:FindFirstChild(templateFolder)
	local template = container and container:FindFirstChild(templateName)
	if not template then
		warn("Showcase: Figur fehlt: " .. templateFolder .. "." .. templateName)
		return nil
	end
	local model = RealFigure.prepare(template, { anchor = true, height = HEIGHTS[templateName] })
	model.Name = templateName .. (skinId and ("_" .. skinId) or "")
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.pi, 0))
	-- erst in den workspace, dann den Skin: Anzug & Co. messen die echte Körperform mit Strahlen
	model.Parent = folder
	if skinId then
		Skins.apply(model, skinId, skinOptions)
	end
	-- genau auf das Podest stellen: tiefsten sichtbaren Punkt messen und anheben
	local lowest = math.huge
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 and not part.Name:find("^Skin_") then
			local size = part.Size
			local cf = part.CFrame
			local extent = math.abs(cf.RightVector.Y) * size.X / 2 + math.abs(cf.UpVector.Y) * size.Y / 2 + math.abs(cf.LookVector.Y) * size.Z / 2
			lowest = math.min(lowest, part.Position.Y - extent)
		end
	end
	if lowest < math.huge then
		model:PivotTo(model:GetPivot() + Vector3.new(0, position.Y - lowest, 0))
	end
	return model
end

local function money(n)
	local text = tostring(n)
	return text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function skinPrice(id)
	for _, skin in ShopCatalog.SKINS do
		if skin.id == id then
			if skin.pack then
				for _, pack in ShopCatalog.PACKS do
					if pack.id == skin.pack then
						return pack.title .. " (" .. pack.robux .. " R$)"
					end
				end
			end
			return money(skin.coins) .. " coins or " .. skin.robux .. " R$"
		end
	end
	return ""
end

-- eine Reihe Figuren: entries = { { folder, name, skinId, title, options } }
local function figureRow(z, entries, spacing)
	local count = #entries
	for index, entry in entries do
		local x = (index - (count + 1) / 2) * spacing
		local top = pedestal(Vector3.new(x, 0, z), 7, 1, entry[3] and GOLD or GREY)
		figure(entry[1], entry[2], top, entry[3], entry[5])
		local price = entry[3] and skinPrice(entry[3]) or "Default"
		sign(CFrame.new(x, 1.6, z + 5) * CFrame.Angles(math.rad(-20), 0, 0), 9, 2.6, entry[4], price, entry[3] and GOLD or GREY)
	end
end

------------------------------------------------------------------ Reihe 1: Spieler
sectionTitle(48, "PLAYER SKINS", "Driver and passenger share one skin model   ·   Silver Suit: 2,500 coins or 249 R$   ·   Golden Suit: Golden Pack")
figureRow(48, {
	{ "Spieler", "Spieler1", nil, "DRIVER" },
	{ "Spieler", "Spieler2", nil, "PASSENGER" },
	{ "Spieler", "Spieler1", "SilverSuit", "SILVER SUIT" },
	{ "Spieler", "Spieler1", "GoldSuit", "GOLDEN SUIT", { tuxedo = true } },
}, 16)

------------------------------------------------------------------ Reihe 2: Familie Wagner (nur der goldene Anzug)
sectionTitle(14, "THE WAGNER FAMILY", "Only skin: the Golden Suit (Golden Pack, 999 R$)")
figureRow(14, {
	{ "Wagners", "MrWagner", nil, "MR. WAGNER" },
	{ "Wagners", "MrWagner", "GoldSuit", "GOLDEN SUIT", { tuxedo = true } },
	{ "Wagners", "MrsWagner", nil, "MRS. WAGNER" },
	{ "Wagners", "MrsWagner", "GoldSuit", "GOLDEN SUIT", { jewelry = true } },
	{ "Wagners", "Lucy", nil, "LUCY" },
	{ "Wagners", "Lucy", "GoldSuit", "GOLDEN SUIT", { barefoot = true, jewelry = true } },
	{ "Wagners", "Tommy", nil, "TOMMY" },
	{ "Wagners", "Tommy", "GoldSuit", "GOLDEN SUIT", { tuxedo = true } },
}, 14)

------------------------------------------------------------------ Reihe 3: Sarp
sectionTitle(-22, "SARP", "Sarp VIP Pack (499 R$): Gilded Horror   ·   Shadow Sarp: 3,500 coins or 399 R$")
figureRow(-22, {
	{ "Sarp", "Sarp2", nil, "SARP" },
	{ "Sarp", "Sarp2", "GildedHorror", "GILDED HORROR" },
	{ "Sarp", "Sarp2", "ShadowSarp", "SHADOW SARP" },
	{ "Sarp", "Sarp2", "GoldSuit", "GOLDEN SUIT" },
}, 17)

------------------------------------------------------------------ Reihe 4: Sportwagen und Kleidung
sectionTitle(-62, "SPORTS CAR & CLOTHING", "Clothing only for coins   ·   Free vending machine on your first visit")
-- Sportwagen auf einer Drehscheibe (dreht sich langsam)
local turntableTop = pedestal(Vector3.new(-62, 0, -72), 24, 0.6)
local car = SportsCar.build(folder, CFrame.new(turntableTop) * CFrame.Angles(0, math.rad(-35), 0))
sign(CFrame.new(-62, 1.8, -57) * CFrame.Angles(math.rad(-20), 0, 0), 16, 3, "SPORTS CAR", money(ShopCatalog.SPORTS_CAR.coins) .. " coins or " .. ShopCatalog.SPORTS_CAR.robux .. " R$  ·  free in Golden Pack & Sarp VIP Pack")

-- Kleidung auf kleinen Säulen, dreht sich
local clothingFolder = ReplicatedStorage:FindFirstChild("Shop") and ReplicatedStorage.Shop:FindFirstChild("Kleidung")
local spinning = {}
for index, item in ShopCatalog.CLOTHING do
	local column = (index - 1) % 6
	local row = math.floor((index - 1) / 6)
	local x = -12 + column * 14
	local z = -66 - row * 16
	local rarity = ShopCatalog.RARITIES[item.rarity]
	local top = pedestal(Vector3.new(x, 0, z), 4, 3.2, rarity.color)
	local template = clothingFolder and clothingFolder:FindFirstChild(item.id)
	if template then
		local shown = template:Clone()
		shown.Name = item.id
		shown.Anchored = true
		local height = shown.Size.Y
		local center = top + Vector3.new(0, height / 2 + 0.4, 0)
		shown.CFrame = CFrame.new(center)
		shown.Parent = folder
		table.insert(spinning, { part = shown, center = center, offset = index })
	else
		warn("Showcase: Kleidung fehlt: " .. item.id)
	end
	sign(CFrame.new(x, 1.4, z + 3.6) * CFrame.Angles(math.rad(-20), 0, 0), 8, 2.4, item.title:upper(), money(item.coins) .. " coins  ·  " .. rarity.title, rarity.color)
end

RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for _, info in spinning do
		info.part.CFrame = CFrame.new(info.center + Vector3.new(0, math.sin(t * 1.5 + info.offset) * 0.15, 0)) * CFrame.Angles(0, t * 0.8 + info.offset, 0)
	end
end)

local count = 0
for _, item in folder:GetDescendants() do
	if item:IsA("BasePart") then
		count += 1
	end
end
folder:SetAttribute("Ready", true)
print(string.format("Showcase: fertig (%d Teile, Auto: %s)", count, car and car.Name or "fehlt"))
