-- VIP-Showroom auf der Ostseite der Lobby: offener Pavillon (Marmorboden, Goldsäulen, Dach mit
-- Licht), an der Rückwand alle Skins auf Podesten, in der Mitte der Sportwagen auf einer
-- Drehscheibe, an den Seiten die Kleidung in Vitrinen, vorne zwei Shop-Terminals.
-- Jedes Podest hat einen Knopf „View in shop“ (Tag ShowroomItemPrompt, Attribut ShopItem).
-- Die Drehscheibe und die Kleidung drehen sich nur beim Client (Tag ShowroomSpin), damit der
-- Server nichts jedes Bild neu senden muss.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(script.Parent.Layout)
local Parts = require(ReplicatedStorage.Shared.Parts)
local RealFigure = require(ReplicatedStorage.Shared.RealFigure)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local Skins = require(ReplicatedStorage.Shared.Skins)
local SportsCar = require(ReplicatedStorage.Shared.SportsCar)

local Showroom = {}

local Y = Layout.GROUND_Y
local FLOOR_Y = Y + 0.5
-- Pavillon: x 45..73, z -10..48, offen nach Westen (zum Lagerfeuer)
local MIN_X, MAX_X, MIN_Z, MAX_Z = 45, 73, -10, 48
local CENTER_Z = (MIN_Z + MAX_Z) / 2
local ROOF_Y = 13

local GOLD = Color3.fromRGB(212, 168, 70)
local DARK = Color3.fromRGB(24, 22, 26)
local MARBLE = Color3.fromRGB(36, 34, 38)
local TEXT = Color3.fromRGB(240, 236, 228)
local WEST = Vector3.new(-1, 0, 0) -- Blickrichtung der Ausstellungsstücke

local function money(n)
	local text = tostring(n)
	return (text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function priceText(entry)
	if entry.pack then
		for _, pack in ShopCatalog.PACKS do
			if pack.id == entry.pack then
				return pack.title .. " · " .. pack.robux .. " R$"
			end
		end
	end
	local parts = {}
	if entry.coins then
		table.insert(parts, money(entry.coins) .. " coins")
	end
	if entry.robux then
		table.insert(parts, entry.robux .. " R$")
	end
	return table.concat(parts, " or ")
end

local function prompt(parent, itemId, title)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = "View in shop"
	p.ObjectText = title
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.HoldDuration = 0
	p.MaxActivationDistance = 9
	p.RequiresLineOfSight = false
	p:SetAttribute("ShopItem", itemId)
	CollectionService:AddTag(p, "ShowroomItemPrompt")
	p.Parent = parent
	return p
end

-- kleines schräges Schild, Schrift zeigt nach Westen
local function plaque(parent, position, width, title, subtitle, accent)
	local cf = CFrame.lookAt(position, position + WEST) * CFrame.Angles(math.rad(-25), 0, 0)
	local board = Parts.new("Part", { Name = "Plaque", Size = Vector3.new(width, 1.3, 0.15), CFrame = cf, Color = DARK, Parent = parent })
	Parts.new("Part", { Name = "PlaqueTrim", Size = Vector3.new(width + 0.1, 0.08, 0.2), CFrame = cf * CFrame.new(0, 0.65, 0), Color = accent or GOLD, Material = Enum.Material.Metal, Parent = parent })
	local gui = Parts.surfaceGui(board, Enum.NormalId.Front, true)
	gui.PixelsPerStud = 70
	Parts.text(gui, { Text = title, Font = Enum.Font.GothamBlack, TextColor3 = accent or GOLD, Size = UDim2.fromScale(0.94, 0.5), Position = UDim2.fromScale(0.03, 0.04) })
	Parts.text(gui, { Text = subtitle or "", Font = Enum.Font.GothamMedium, TextColor3 = TEXT, Size = UDim2.fromScale(0.94, 0.38), Position = UDim2.fromScale(0.03, 0.56) })
	return board
end

local function downlight(parent, position, target, range, brightness, shadows)
	-- flache Deckenleuchte; das Licht fällt schräg auf das Ziel
	local lamp = Parts.new("Part", { Name = "Downlight", Size = Vector3.new(0.9, 0.08, 0.9), CFrame = CFrame.new(position), Color = Color3.fromRGB(255, 244, 225), Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	local aim = Parts.new("Part", { Name = "DownlightAim", Size = Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.lookAt(position - Vector3.new(0, 0.2, 0), target), Transparency = 1, CanCollide = false, Parent = parent })
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Angle = 70
	light.Range = range
	light.Brightness = brightness
	light.Color = Color3.fromRGB(255, 236, 205)
	light.Shadows = shadows or false
	light.Parent = aim
	return lamp
end

------------------------------------------------------------------ Gebäude
local function buildPavilion(folder)
	local width, length = MAX_X - MIN_X, MAX_Z - MIN_Z
	local cx = (MIN_X + MAX_X) / 2
	-- Boden mit Goldkante und Stufe vorne
	Parts.new("Part", { Name = "Floor", Size = Vector3.new(width, 0.5, length), CFrame = CFrame.new(cx, Y + 0.25, CENTER_Z), Color = MARBLE, Material = Enum.Material.Marble, Parent = folder })
	Parts.new("Part", { Name = "Step", Size = Vector3.new(1.2, 0.25, length), CFrame = CFrame.new(MIN_X - 0.6, Y + 0.125, CENTER_Z), Color = MARBLE, Material = Enum.Material.Marble, Parent = folder })
	for _, info in { { MIN_X, CENTER_Z, 0.14, length }, { cx, MIN_Z, width, 0.14 }, { cx, MAX_Z, width, 0.14 } } do
		Parts.new("Part", { Name = "FloorTrim", Size = Vector3.new(info[3] > 1 and info[3] or 0.14, 0.06, info[4] > 1 and info[4] or 0.14), CFrame = CFrame.new(info[1], FLOOR_Y + 0.03, info[2]), Color = GOLD, Material = Enum.Material.Metal, Parent = folder })
	end
	-- schwarzer Teppich mit Goldrand vom Eingang zur Drehscheibe
	Parts.new("Part", { Name = "Carpet", Size = Vector3.new(4, 0.04, 8), CFrame = CFrame.new(MIN_X + 2, FLOOR_Y + 0.02, CENTER_Z), Color = Color3.fromRGB(110, 14, 24), Material = Enum.Material.Fabric, Parent = folder })

	-- Rückwand: dunkle Paneele, Goldleisten, warmes Licht oben
	local wallX = MAX_X - 0.5
	Parts.new("Part", { Name = "BackWall", Size = Vector3.new(1, ROOF_Y - FLOOR_Y, length), CFrame = CFrame.new(wallX, FLOOR_Y + (ROOF_Y - FLOOR_Y) / 2, CENTER_Z), Color = DARK, Material = Enum.Material.WoodPlanks, Parent = folder })
	for z = MIN_Z + 3, MAX_Z - 3, 6 do
		Parts.new("Part", { Name = "WallStrip", Size = Vector3.new(0.12, ROOF_Y - FLOOR_Y - 1, 0.12), CFrame = CFrame.new(wallX - 0.56, FLOOR_Y + (ROOF_Y - FLOOR_Y) / 2, z), Color = GOLD, Material = Enum.Material.Metal, Parent = folder })
	end
	Parts.new("Part", { Name = "CoveLight", Size = Vector3.new(0.2, 0.2, length - 1), CFrame = CFrame.new(wallX - 0.6, ROOF_Y - 0.5, CENTER_Z), Color = Color3.fromRGB(255, 205, 130), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })

	-- Seitenwände (hinten geschlossen, vorne Glas)
	for _, z in { MIN_Z + 0.25, MAX_Z - 0.25 } do
		Parts.new("Part", { Name = "SideWall", Size = Vector3.new(12, ROOF_Y - FLOOR_Y, 0.5), CFrame = CFrame.new(MAX_X - 6, FLOOR_Y + (ROOF_Y - FLOOR_Y) / 2, z), Color = DARK, Material = Enum.Material.WoodPlanks, Parent = folder })
		Parts.new("Part", { Name = "SideGlass", Size = Vector3.new(width - 12.5, 3.2, 0.2), CFrame = CFrame.new(MIN_X + (width - 12) / 2, FLOOR_Y + 1.6, z), Color = Color3.fromRGB(170, 200, 210), Material = Enum.Material.Glass, Transparency = 0.6, Parent = folder })
		Parts.new("Part", { Name = "GlassRail", Size = Vector3.new(width - 12.5, 0.15, 0.3), CFrame = CFrame.new(MIN_X + (width - 12) / 2, FLOOR_Y + 3.25, z), Color = GOLD, Material = Enum.Material.Metal, Parent = folder })
	end

	-- Dach auf goldenen Säulen
	Parts.new("Part", { Name = "Roof", Size = Vector3.new(width + 2, 0.6, length + 2), CFrame = CFrame.new(cx - 1, ROOF_Y + 0.3, CENTER_Z), Color = DARK, Parent = folder })
	Parts.new("Part", { Name = "Ceiling", Size = Vector3.new(width, 0.1, length), CFrame = CFrame.new(cx, ROOF_Y - 0.05, CENTER_Z), Color = Color3.fromRGB(46, 42, 48), CanCollide = false, Parent = folder })
	for _, z in { MIN_Z + 0.6, 6, 32, MAX_Z - 0.6 } do
		Parts.column({ Name = "Column", Color = GOLD, Material = Enum.Material.Metal, Reflectance = 0.2, Parent = folder }, ROOF_Y - FLOOR_Y, 0.9, CFrame.new(MIN_X + 0.6, FLOOR_Y, z))
		Parts.column({ Name = "ColumnBase", Color = DARK, Parent = folder }, 0.5, 1.4, CFrame.new(MIN_X + 0.6, FLOOR_Y, z))
	end
	-- Schild vorne am Dach
	local fascia = Parts.new("Part", { Name = "Fascia", Size = Vector3.new(0.5, 2.4, length + 2), CFrame = CFrame.new(MIN_X - 2.35, ROOF_Y + 0.3, CENTER_Z), Color = DARK, Parent = folder })
	Parts.new("Part", { Name = "FasciaTrim", Size = Vector3.new(0.55, 0.15, length + 2), CFrame = CFrame.new(MIN_X - 2.35, ROOF_Y - 0.85, CENTER_Z), Color = GOLD, Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	local gui = Parts.surfaceGui(fascia, Enum.NormalId.Left, true)
	gui.PixelsPerStud = 30
	Parts.text(gui, { Text = "★  VIP SHOWROOM  ★", Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Size = UDim2.fromScale(0.9, 0.86), Position = UDim2.fromScale(0.05, 0.07) })

	-- Licht: Spots auf die Figuren und auf das Auto
	for z = MIN_Z + 4, MAX_Z - 4, 7 do
		downlight(folder, Vector3.new(63, ROOF_Y - 0.1, z), Vector3.new(68.5, FLOOR_Y + 3, z), 22, 2.4, false)
	end
	downlight(folder, Vector3.new(55, ROOF_Y - 0.2, CENTER_Z - 5), Vector3.new(55, FLOOR_Y, CENTER_Z - 3), 22, 1.4, true)
	downlight(folder, Vector3.new(55, ROOF_Y - 0.2, CENTER_Z + 5), Vector3.new(55, FLOOR_Y, CENTER_Z + 3), 22, 1.4, false)
	local fill = Parts.new("Part", { Name = "Fill", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(52, ROOF_Y - 2, CENTER_Z), Transparency = 1, CanCollide = false, Parent = folder })
	local pointLight = Instance.new("PointLight")
	pointLight.Range = 40
	pointLight.Brightness = 1.2
	pointLight.Color = Color3.fromRGB(255, 225, 185)
	pointLight.Parent = fill
end

-- Gruppen-Titel an der Rückwand
local function wallSign(folder, z, width, title, subtitle)
	local board = Parts.new("Part", { Name = "WallSign", Size = Vector3.new(0.2, 2, width), CFrame = CFrame.new(MAX_X - 1.1, ROOF_Y - 2.4, z), Color = DARK, Parent = folder })
	Parts.new("Part", { Name = "WallSignTrim", Size = Vector3.new(0.25, 0.08, width), CFrame = CFrame.new(MAX_X - 1.1, ROOF_Y - 1.4, z), Color = GOLD, Material = Enum.Material.Metal, Parent = folder })
	local gui = Parts.surfaceGui(board, Enum.NormalId.Left, true)
	gui.PixelsPerStud = 50
	Parts.text(gui, { Text = title, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Size = UDim2.fromScale(0.96, 0.55), Position = UDim2.fromScale(0.02, 0.04) })
	Parts.text(gui, { Text = subtitle, Font = Enum.Font.GothamMedium, TextColor3 = TEXT, Size = UDim2.fromScale(0.96, 0.34), Position = UDim2.fromScale(0.02, 0.6) })
end

------------------------------------------------------------------ Figuren
local function pedestal(folder, position, diameter, accent)
	Parts.column({ Name = "Pedestal", Color = DARK, Parent = folder }, 1, diameter, CFrame.new(position))
	Parts.column({ Name = "PedestalRim", Color = accent or GOLD, Material = Enum.Material.Metal, Parent = folder }, 0.1, diameter + 0.2, CFrame.new(position + Vector3.new(0, 0.95, 0)))
	return position + Vector3.new(0, 1, 0)
end

-- Figur aufstellen (schaut nach Westen) mit Skin; steht genau auf `top`
local function figure(folder, spec, skinId, options, top)
	local container = ReplicatedStorage:FindFirstChild(spec.folder)
	local template = container and container:FindFirstChild(spec.name)
	if not template then
		warn("Showroom: Figur fehlt: " .. spec.folder .. "." .. spec.name)
		return nil
	end
	local model = RealFigure.prepare(template, { anchor = true, height = spec.height })
	model.Name = spec.name .. "_" .. skinId
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	model:PivotTo(CFrame.lookAt(top, top + WEST))
	model.Parent = folder -- erst in den workspace: der Skin misst die Körperform
	Skins.apply(model, skinId, options)
	local lowest = math.huge
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 and not part.Name:find("^Skin_") then
			local size, cf = part.Size, part.CFrame
			local extent = math.abs(cf.RightVector.Y) * size.X / 2 + math.abs(cf.UpVector.Y) * size.Y / 2 + math.abs(cf.LookVector.Y) * size.Z / 2
			lowest = math.min(lowest, part.Position.Y - extent)
		end
	end
	if lowest < math.huge then
		model:PivotTo(model:GetPivot() + Vector3.new(0, top.Y - lowest, 0))
	end
	return model
end

local function exhibit(folder, z, spec, skinId, options, itemId, title, subtitle)
	local base = Vector3.new(68.5, FLOOR_Y, z)
	local top = pedestal(folder, base, 3.6)
	local model = figure(folder, spec, skinId, options, top)
	local sign = plaque(folder, Vector3.new(66.2, FLOOR_Y + 0.9, z), 3.6, title, subtitle)
	prompt(sign, itemId, title)
	return model
end

------------------------------------------------------------------ Sportwagen und Kleidung
local function buildCar(folder)
	local center = Vector3.new(55, FLOOR_Y, CENTER_Z)
	local spin = Instance.new("Model")
	spin.Name = "Turntable"
	Parts.column({ Name = "Disc", Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Metal, Parent = spin }, 0.3, 17, CFrame.new(center))
	Parts.column({ Name = "DiscRing", Color = GOLD, Material = Enum.Material.Neon, CanCollide = false, Parent = spin }, 0.12, 17.3, CFrame.new(center + Vector3.new(0, 0.08, 0)))
	SportsCar.build(spin, CFrame.new(center + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, math.rad(-35), 0))
	spin:SetAttribute("SpinCenter", center)
	spin:SetAttribute("SpinSpeed", 0.25)
	CollectionService:AddTag(spin, "ShowroomSpin")
	spin.Parent = folder
	local sign = plaque(folder, Vector3.new(MIN_X + 2.8, FLOOR_Y + 0.9, CENTER_Z + 6.5), 4.2, "SPORTS CAR", priceText(ShopCatalog.SPORTS_CAR))
	prompt(sign, ShopCatalog.SPORTS_CAR.id, "Sports Car")
end

local function buildClothing(folder)
	local templates = ReplicatedStorage:FindFirstChild("Shop") and ReplicatedStorage.Shop:FindFirstChild("Kleidung")
	for index, item in ShopCatalog.CLOTHING do
		local row = index <= 6 and 0 or 1
		local column = (index - 1) % 6
		local x = MIN_X + 3 + column * 2.6
		local z = row == 0 and MIN_Z + 2.2 or MAX_Z - 2.2
		local rarity = ShopCatalog.RARITIES[item.rarity]
		local base = Vector3.new(x, FLOOR_Y, z)
		Parts.column({ Name = "Stand", Color = DARK, Parent = folder }, 2.6, 1.6, CFrame.new(base))
		Parts.column({ Name = "StandRim", Color = rarity.color, Material = Enum.Material.Neon, CanCollide = false, Parent = folder }, 0.06, 1.7, CFrame.new(base + Vector3.new(0, 2.6, 0)))
		local template = templates and templates:FindFirstChild(item.id)
		if template then
			local shown = template:Clone()
			shown.Anchored = true
			shown.CanCollide = false
			-- große Teile (Jacken) kleiner, damit sie auf die Säule passen
			local largest = math.max(shown.Size.X, shown.Size.Y, shown.Size.Z)
			if largest > 1.8 then
				shown.Size = shown.Size * (1.8 / largest)
			end
			local center = base + Vector3.new(0, 2.7 + shown.Size.Y / 2, 0)
			shown.CFrame = CFrame.new(center)
			shown:SetAttribute("SpinCenter", center)
			shown:SetAttribute("SpinSpeed", 0.8)
			CollectionService:AddTag(shown, "ShowroomSpin")
			shown.Parent = folder
		end
		local facing = row == 0 and Vector3.new(0, 0, 1) or Vector3.new(0, 0, -1)
		local signPos = base + facing * 1.2 + Vector3.new(0, 0.7, 0)
		local cf = CFrame.lookAt(signPos, signPos + facing) * CFrame.Angles(math.rad(-25), 0, 0)
		local board = Parts.new("Part", { Name = "Plaque", Size = Vector3.new(2.3, 0.9, 0.12), CFrame = cf, Color = DARK, Parent = folder })
		local gui = Parts.surfaceGui(board, Enum.NormalId.Front, true)
		gui.PixelsPerStud = 90
		Parts.text(gui, { Text = item.title:upper(), Font = Enum.Font.GothamBlack, TextColor3 = rarity.color, Size = UDim2.fromScale(0.94, 0.5), Position = UDim2.fromScale(0.03, 0.04) })
		Parts.text(gui, { Text = money(item.coins) .. " coins · " .. rarity.title, Font = Enum.Font.GothamMedium, TextColor3 = TEXT, Size = UDim2.fromScale(0.94, 0.38), Position = UDim2.fromScale(0.03, 0.56) })
		prompt(board, item.id, item.title)
	end
	-- Schilder über den Vitrinen
	for _, z in { MIN_Z + 0.55, MAX_Z - 0.55 } do
		local sign = Parts.new("Part", { Name = "ClothingSign", Size = Vector3.new(14, 1.4, 0.15), CFrame = CFrame.new(MIN_X + 9.5, FLOOR_Y + 5, z) * (z < CENTER_Z and CFrame.Angles(0, math.pi, 0) or CFrame.new()), Color = DARK, Parent = folder })
		local gui = Parts.surfaceGui(sign, Enum.NormalId.Front, true)
		gui.PixelsPerStud = 40
		Parts.text(gui, { Text = "CLOTHING & ACCESSORIES  ·  ONLY FOR COINS", Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Size = UDim2.fromScale(0.96, 0.8), Position = UDim2.fromScale(0.02, 0.1) })
	end
end

-- Shop-Terminal: goldener Ständer mit leuchtendem Bildschirm
local function terminal(folder, position)
	local cf = CFrame.lookAt(position, position + WEST)
	local stand = Parts.new("Part", { Name = "TerminalStand", Size = Vector3.new(0.6, 3.4, 0.6), CFrame = cf * CFrame.new(0, 1.7, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = folder })
	Parts.new("Part", { Name = "TerminalBase", Size = Vector3.new(1.8, 0.2, 1.8), CFrame = cf * CFrame.new(0, 0.1, 0), Color = DARK, Parent = folder })
	local screen = Parts.new("Part", { Name = "TerminalScreen", Size = Vector3.new(2.6, 1.8, 0.2), CFrame = cf * CFrame.new(0, 3.9, 0) * CFrame.Angles(math.rad(-15), 0, 0), Color = DARK, Parent = folder })
	local gui = Parts.surfaceGui(screen, Enum.NormalId.Front, true)
	gui.PixelsPerStud = 80
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(20, 18, 22)
	back.Parent = gui
	Parts.text(gui, { Text = "VIP SHOP", Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Size = UDim2.fromScale(0.9, 0.4), Position = UDim2.fromScale(0.05, 0.12), ZIndex = 2 })
	Parts.text(gui, { Text = "Skins · Packs · Coins · Snacks", Font = Enum.Font.GothamMedium, TextColor3 = TEXT, Size = UDim2.fromScale(0.9, 0.22), Position = UDim2.fromScale(0.05, 0.6), ZIndex = 2 })
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Front
	light.Range = 6
	light.Brightness = 0.8
	light.Color = Color3.fromRGB(255, 210, 140)
	light.Parent = screen
	local p = Instance.new("ProximityPrompt")
	p.ActionText = "Open VIP Shop"
	p.ObjectText = "Shop"
	p.HoldDuration = 0
	p.MaxActivationDistance = 9
	p.RequiresLineOfSight = false
	CollectionService:AddTag(p, "VipShopPrompt")
	p.Parent = stand
end

function Showroom.build(parent)
	local started = os.clock()
	local folder = Instance.new("Folder")
	folder.Name = "Showroom"
	folder.Parent = parent

	buildPavilion(folder)
	terminal(folder, Vector3.new(MIN_X + 2.2, FLOOR_Y, CENTER_Z - 9))
	terminal(folder, Vector3.new(MIN_X + 2.2, FLOOR_Y, CENTER_Z + 9))
	buildCar(folder)
	buildClothing(folder)

	-- Golden Pack: die Familie
	wallSign(folder, 0.5, 18, "GOLDEN PACK", "Golden suits for everyone · 999 R$")
	local familyZ = { -6, -1.5, 3, 7 }
	for index, spec in ShopCatalog.FAMILY_GOLD do
		exhibit(folder, familyZ[index], spec, "GoldSuit", spec.options, "GoldenPack", spec.title:upper(), "Golden Pack")
		task.wait()
	end
	-- Anzüge der Spieler
	wallSign(folder, 15.75, 10, "YOUR SUITS", "Driver & passenger")
	local suits = { { 13, "SilverSuit" }, { 18.5, "GoldSuit" } }
	for _, info in suits do
		local skin = ShopCatalog.find(info[2])
		exhibit(folder, info[1], skin.preview, skin.id, skin.options, skin.pack or skin.id, skin.title:upper(), priceText(skin))
		task.wait()
	end
	-- Sarp
	wallSign(folder, 34, 24, "SARP VIP PACK", "3 luxury skins · 499 R$   ·   Shadow Sarp: 3,500 coins or 399 R$")
	local sarpZ = { 25, 31, 37, 43 }
	local index = 0
	for _, skin in ShopCatalog.SKINS do
		if skin.slot == "Sarp" then
			index += 1
			exhibit(folder, sarpZ[index], skin.preview, skin.id, skin.options, skin.pack or skin.id, skin.title:upper(), priceText(skin))
			task.wait()
		end
	end

	Parts.optimize(folder)
	folder:SetAttribute("Ready", true)
	local count = 0
	for _, item in folder:GetDescendants() do
		if item:IsA("BasePart") then
			count += 1
		end
	end
	print(string.format("Showroom: fertig in %.1f s (%d Teile)", os.clock() - started, count))
end

return Showroom
