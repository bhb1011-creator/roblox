-- Kapitel 2: die Eingangshalle der Wagners. Dunkel, kalt, nur ein paar Kerzen.
-- Holzboden mit altem Teppich, Treppe nach oben zu einer Galerie mit zwei Türen (die
-- erste ist mit Brettern vernagelt), eine stehen gebliebene Standuhr, Garderobe mit
-- Kinderstiefeln, ein Tischchen mit Familienfotos (Gesichter zerkratzt), ein verhängter
-- Spiegel und zwei Durchgänge ins Dunkle (Wohnzimmer und Küche).
-- Alles relativ zum Haus: x nach rechts, z nach hinten, y = 0 auf Hofhöhe.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.Parts)
local Route = require(ReplicatedStorage.Shared.LevelRoute)
local House = require(script.Parent.House)

local HouseInterior = {}

local COLORS = {
	wallpaper = Color3.fromRGB(58, 66, 56), -- ausgeblichenes Grün
	wallpaperStripe = Color3.fromRGB(50, 57, 48),
	wainscot = Color3.fromRGB(46, 36, 28),
	floor = Color3.fromRGB(58, 44, 32),
	stair = Color3.fromRGB(52, 40, 30),
	tread = Color3.fromRGB(40, 30, 22),
	trim = Color3.fromRGB(70, 56, 42),
	rug = Color3.fromRGB(82, 32, 30),
	rugBorder = Color3.fromRGB(52, 26, 22),
	brass = Color3.fromRGB(120, 96, 52),
	candle = Color3.fromRGB(225, 215, 190),
	flame = Color3.fromRGB(255, 170, 70),
	cloth = Color3.fromRGB(176, 168, 154),
	photo = Color3.fromRGB(122, 112, 96),
	scratch = Color3.fromRGB(30, 22, 18),
	darkness = Color3.fromRGB(0, 0, 0),
	ceiling = Color3.fromRGB(44, 40, 34),
}

local BASE, STORY = House.BASE, House.STORY
local X0, X1, Z1 = House.HALL_X0, House.HALL_X1, House.HALL_Z1
local Z0 = -Route.HOUSE_SIZE.Z / 2 + House.WALL -- Innenseite der Vorderwand
local FLOOR = BASE + 0.1 -- Oberkante des Fußbodens
local TOP = BASE + 2 * STORY
local CEILING = TOP - 0.5
local GALLERY = BASE + STORY -- Fußboden oben
local GALLERY_Z = -3 -- Vorderkante der Galerie (tief genug, dass man oben bequem ankommt)
local STAIRS_X0, STAIRS_X1 = X0, -5
local STAIRS_Z0 = -13.4 -- erste Stufe
local STEPS = 13

HouseInterior.FLOOR = FLOOR
HouseInterior.STAIRS_TOP = Vector3.new((STAIRS_X0 + STAIRS_X1) / 2, GALLERY, GALLERY_Z - 0.5)

-- Kerze mit Licht; `cframe` = Unterseite des Halters
function HouseInterior.candle(parent, cframe, height, range, brightness)
	height = height or 1
	Parts.column({ Name = "CandleHolder", Color = COLORS.brass, Material = Enum.Material.Metal, Parent = parent }, 0.12, 0.7, cframe)
	Parts.column({ Name = "Candle", Color = COLORS.candle, Material = Enum.Material.SmoothPlastic, Parent = parent }, height, 0.25, cframe * CFrame.new(0, 0.12, 0))
	local flame = Parts.new("Part", {
		Name = "CandleFlame",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.16, 0.16, 0.16),
		CFrame = cframe * CFrame.new(0, 0.12 + height + 0.12, 0),
		Color = COLORS.flame,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		Parent = parent,
	})
	Parts.light("PointLight", flame, {
		Name = "CandleLight",
		Range = range or 10,
		Brightness = brightness or 1.1,
		Color = Color3.fromRGB(255, 160, 85),
		Shadows = true,
	})
	return flame
end

-- `mansion` = true: im großen Haus (Mansion.lua) kommen Wände, Boden, Decke und die echten
-- Türen vom Haus selbst; hier nur Treppe, Galerie und Einrichtung der Halle.
function HouseInterior.build(model, origin, mansion)
	local folder = Instance.new("Model")
	folder.Name = "Interior"
	folder.Parent = model
	local block = Parts.builder(folder, origin)

	------------------------------------------------------------------ Boden und Decke
	local hallW, hallD = X1 - X0, Z1 - Z0
	local midX, midZ = (X0 + X1) / 2, (Z0 + Z1) / 2
	if not mansion then
		block("Floor", Vector3.new(hallW, 0.1, hallD), CFrame.new(midX, BASE + 0.05, midZ), COLORS.floor, Enum.Material.WoodPlanks)
		block("Ceiling", Vector3.new(hallW, 0.5, hallD), CFrame.new(midX, TOP - 0.25, midZ), COLORS.ceiling, Enum.Material.Wood)
	end
	-- Alter Teppich mit dunklem Rand
	block("RugBorder", Vector3.new(5.4, 0.03, 8.4), CFrame.new(-2, FLOOR + 0.015, -8.2), COLORS.rugBorder, Enum.Material.Fabric)
	block("Rug", Vector3.new(4.8, 0.03, 7.8), CFrame.new(-2, FLOOR + 0.045, -8.2), COLORS.rug, Enum.Material.Fabric)

	------------------------------------------------------------------ Wände: Tapete und Holzverkleidung
	-- Platten liegen 0.1 vor der Wand (keine gleichen Flächen, kein Flimmern)
	local wainscotTop = FLOOR + 3
	local function walls(fromY, toY, color, material, depth, name)
		local h, y = toY - fromY, (fromY + toY) / 2
		-- links und rechts
		block(name, Vector3.new(depth, h, hallD), CFrame.new(X0 + depth / 2, y, midZ), color, material)
		block(name, Vector3.new(depth, h, hallD), CFrame.new(X1 - depth / 2, y, midZ), color, material)
		-- hinten
		block(name, Vector3.new(hallW - 2 * depth - 0.02, h, depth), CFrame.new(midX, y, Z1 - depth / 2), color, material)
		-- vorne, links und rechts der Tür (über der Tür extra)
		-- an der Türöffnung endet jede Schicht minimal anders (kein Flimmern der Kanten)
		local edge = 0.01 + depth * 0.1
		local leftW, rightW = -4 - X0 - depth - edge, X1 - 0 - depth - edge
		block(name, Vector3.new(leftW, h, depth), CFrame.new(X0 + depth + leftW / 2, y, Z0 + depth / 2), color, material)
		block(name, Vector3.new(rightW, h, depth), CFrame.new(X1 - depth - rightW / 2, y, Z0 + depth / 2), color, material)
		if toY > BASE + 7.9 then
			local from = math.max(fromY, BASE + 7.9)
			block(name, Vector3.new(4, toY - from, depth), CFrame.new(-2, (from + toY) / 2, Z0 + depth / 2), color, material)
		end
	end
	if not mansion then
	walls(wainscotTop, CEILING, COLORS.wallpaper, Enum.Material.Fabric, 0.1, "Wallpaper")
	walls(FLOOR, wainscotTop, COLORS.wainscot, Enum.Material.WoodPlanks, 0.16, "Wainscot")
	-- Abschlussleiste über der Holzverkleidung
	walls(wainscotTop - 0.1, wainscotTop + 0.15, COLORS.trim, Enum.Material.Wood, 0.22, "ChairRail")
	end
	-- dunkle Streifen in der Tapete (nur links und rechts, sie laufen nach oben)
	for z = Z0 + 1.2, (mansion and Z0 or Z1 - 0.6), 1.6 do
		for _, x in { X0 + 0.11, X1 - 0.11 } do
			block("WallpaperStripe", Vector3.new(0.02, CEILING - wainscotTop - 0.4, 0.35), CFrame.new(x, (wainscotTop + CEILING) / 2 + 0.1, z), COLORS.wallpaperStripe, Enum.Material.Fabric)
		end
	end

	------------------------------------------------------------------ Treppe zur Galerie
	local run = (GALLERY_Z - STAIRS_Z0) / STEPS
	local rise = (GALLERY - BASE) / STEPS
	local stairsW = STAIRS_X1 - STAIRS_X0
	local stairsX = (STAIRS_X0 + STAIRS_X1) / 2
	for i = 1, STEPS do
		local height = i * rise - 0.1
		local z = STAIRS_Z0 + (i - 0.5) * run
		block("Stair", Vector3.new(stairsW - 0.02, height, run), CFrame.new(stairsX + 0.01, FLOOR + height / 2, z), COLORS.stair, Enum.Material.WoodPlanks)
		block("StairTread", Vector3.new(stairsW + 0.06, 0.08, run + 0.06), CFrame.new(stairsX + 0.03, FLOOR + height + 0.04, z - 0.03), COLORS.tread, Enum.Material.Wood)
	end
	-- Handlauf mit Stäben auf der offenen Seite
	local railX = STAIRS_X1 + 0.15
	local railFrom = Vector3.new(railX, FLOOR + 3.2, STAIRS_Z0 + 0.3)
	local railTo = Vector3.new(railX, GALLERY + 3.1, GALLERY_Z)
	Parts.beam({ Name = "Handrail", Color = COLORS.trim, Material = Enum.Material.Wood, Parent = folder }, (origin * CFrame.new(railFrom)).Position, (origin * CFrame.new(railTo)).Position, 0.25)
	block("NewelPost", Vector3.new(0.5, 4, 0.5), CFrame.new(railX, FLOOR + 2, STAIRS_Z0 + 0.3), COLORS.trim, Enum.Material.Wood)
	block("NewelCap", Vector3.new(0.65, 0.3, 0.65), CFrame.new(railX, FLOOR + 4.15, STAIRS_Z0 + 0.3), COLORS.tread, Enum.Material.Wood)
	for i = 2, STEPS - 1, 2 do
		local z = STAIRS_Z0 + (i - 0.5) * run
		local stepTop = FLOOR + i * rise
		local t = (z - railFrom.Z) / (railTo.Z - railFrom.Z)
		local railY = railFrom.Y + (railTo.Y - railFrom.Y) * t
		block("Baluster", Vector3.new(0.14, railY - stepTop, 0.14), CFrame.new(railX, (stepTop + railY) / 2, z), COLORS.trim, Enum.Material.Wood)
	end

	------------------------------------------------------------------ Galerie oben mit zwei Türen
	local galleryD = Z1 - 0.1 - GALLERY_Z
	block("GalleryFloor", Vector3.new(hallW - 0.2, 0.5, galleryD), CFrame.new(midX, GALLERY - 0.25, GALLERY_Z + galleryD / 2), COLORS.floor, Enum.Material.WoodPlanks)
	block("GalleryFascia", Vector3.new(hallW - 0.2, 0.7, 0.2), CFrame.new(midX, GALLERY - 0.45, GALLERY_Z - 0.1), COLORS.trim, Enum.Material.Wood)
	local galleryRailZ = GALLERY_Z + 0.15
	block("GalleryRail", Vector3.new(X1 - 0.12 - STAIRS_X1, 0.25, 0.3), CFrame.new((X1 - 0.12 + STAIRS_X1) / 2, GALLERY + 3.1, galleryRailZ), COLORS.trim, Enum.Material.Wood)
	for x = STAIRS_X1 + 0.6, X1 - 0.5, 0.9 do
		block("Baluster", Vector3.new(0.14, 3, 0.14), CFrame.new(x, GALLERY + 1.5, galleryRailZ), COLORS.trim, Enum.Material.Wood)
	end
	-- Türen an der Rückwand: die erste vernagelt und zerkratzt, die zweite ist "euer" Zimmer
	local doorZ = Z1 - 0.1 - 0.1
	for index, x in mansion and {} or { -3.2, 1.4 } do
		block("UpstairsDoorFrame", Vector3.new(3.8, 7.6, 0.16), CFrame.new(x, GALLERY + 3.8, doorZ - 0.02), COLORS.trim, Enum.Material.Wood)
		block("UpstairsDoor", Vector3.new(3.2, 7.1, 0.2), CFrame.new(x, GALLERY + 3.55, doorZ - 0.12), COLORS.stair, Enum.Material.WoodPlanks)
		block("UpstairsDoorKnob", Vector3.new(0.25, 0.25, 0.25), CFrame.new(x + 1.1, GALLERY + 3.4, doorZ - 0.3), COLORS.brass, Enum.Material.Metal, { Shape = Enum.PartType.Ball })
		if index == 1 then
			for i, angle in { 14, -10, 6 } do
				block("Board", Vector3.new(4.2, 0.55, 0.14), CFrame.new(x, GALLERY + 1.8 + i * 1.5, doorZ - 0.32) * CFrame.Angles(0, 0, math.rad(angle)), COLORS.tread, Enum.Material.WoodPlanks)
			end
			for i = 1, 5 do
				block("Scratch", Vector3.new(0.05, 1.4, 0.02), CFrame.new(x - 1 + i * 0.32, GALLERY + 1.4, doorZ - 0.23) * CFrame.Angles(0, 0, math.rad(8 - i * 3)), COLORS.scratch, Enum.Material.SmoothPlastic)
			end
		end
	end
	HouseInterior.candle(folder, origin * CFrame.new(X1 - 0.6, GALLERY, Z1 - 0.8), 0.6, 8, 0.7)

	------------------------------------------------------------------ Rechte Wand: Uhr, Garderobe, Durchgang, Tischchen
	local wallX = X1 - 0.1
	-- Standuhr, stehen geblieben um 3:17
	local clock = CFrame.new(wallX - 0.75, FLOOR, -11.6)
	block("ClockBody", Vector3.new(1.3, 6.4, 1.7), clock * CFrame.new(0, 3.2, 0), COLORS.stair, Enum.Material.Wood)
	block("ClockTop", Vector3.new(1.5, 0.5, 1.9), clock * CFrame.new(0, 6.65, 0), COLORS.tread, Enum.Material.Wood)
	block("ClockFace", Vector3.new(0.06, 1.3, 1.3), clock * CFrame.new(-0.68, 5.4, 0), COLORS.candle, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	block("ClockHand", Vector3.new(0.04, 0.38, 0.06), clock * CFrame.new(-0.73, 5.4, 0) * CFrame.Angles(math.rad(-97), 0, 0) * CFrame.new(0, 0.17, 0), COLORS.scratch)
	block("ClockHand", Vector3.new(0.04, 0.55, 0.05), clock * CFrame.new(-0.74, 5.4, 0) * CFrame.Angles(math.rad(-102), 0, 0) * CFrame.new(0, 0.25, 0), COLORS.scratch)
	block("Pendulum", Vector3.new(0.03, 1.6, 0.1), clock * CFrame.new(-0.68, 2.9, 0), COLORS.brass, Enum.Material.Metal)
	block("PendulumWeight", Vector3.new(0.03, 0.4, 0.4), clock * CFrame.new(-0.68, 2.1, 0), COLORS.brass, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	block("ClockGlass", Vector3.new(0.04, 2.6, 0.9), clock * CFrame.new(-0.72, 2.6, 0), Color3.fromRGB(20, 18, 16), Enum.Material.Glass, { Transparency = 0.3 })
	-- Garderobe mit einem langen Mantel und kleinen Gummistiefeln (die Kinder)
	local rack = CFrame.new(wallX - 0.9, FLOOR, -13.4)
	Parts.column({ Name = "CoatRack", Color = COLORS.tread, Material = Enum.Material.Wood, Parent = folder }, 6, 0.25, origin * rack)
	block("Coat", Vector3.new(0.8, 3.8, 1.2), rack * CFrame.new(-0.1, 4, 0.1), Color3.fromRGB(36, 34, 32), Enum.Material.Fabric)
	block("Scarf", Vector3.new(0.2, 1.6, 0.3), rack * CFrame.new(-0.42, 4.6, -0.5), Color3.fromRGB(110, 34, 30), Enum.Material.Fabric)
	for i, z in { -0.4, 0.1 } do
		block("Boot", Vector3.new(0.45, 0.9, 0.8), rack * CFrame.new(-0.8 + i * 0.05, 0.45, z - 0.6) * CFrame.Angles(0, math.rad(10 * i), 0), Color3.fromRGB(150, 140, 40), Enum.Material.Rubber)
	end
	-- Durchgang zum Wohnzimmer: nur Schwärze
	local function doorway(name, cframe, width, height)
		block(name, Vector3.new(width, height, 0.06), cframe * CFrame.new(0, height / 2, 0), COLORS.darkness, Enum.Material.Neon)
		block(name .. "Casing", Vector3.new(0.35, height + 0.2, 0.18), cframe * CFrame.new(-width / 2 - 0.17, height / 2 + 0.1, -0.06), COLORS.trim, Enum.Material.Wood)
		block(name .. "Casing", Vector3.new(0.35, height + 0.2, 0.18), cframe * CFrame.new(width / 2 + 0.17, height / 2 + 0.1, -0.06), COLORS.trim, Enum.Material.Wood)
		block(name .. "Casing", Vector3.new(width + 0.7, 0.35, 0.18), cframe * CFrame.new(0, height + 0.37, -0.06), COLORS.trim, Enum.Material.Wood)
	end
	if not mansion then
		doorway("LivingRoomDoorway", CFrame.new(wallX - 0.26, FLOOR, -5) * CFrame.Angles(0, math.rad(90), 0), 3.4, 7.4)
	end
	-- Tischchen mit Kerze und Familienfotos (alle Gesichter zerkratzt)
	local tableCF = CFrame.new(wallX - 0.9, FLOOR, -0.9)
	block("SideTable", Vector3.new(1.4, 0.15, 2.6), tableCF * CFrame.new(0, 2.9, 0), COLORS.stair, Enum.Material.Wood)
	for _, x in { -0.55, 0.55 } do
		for _, z in { -1.1, 1.1 } do
			block("TableLeg", Vector3.new(0.14, 2.82, 0.14), tableCF * CFrame.new(x, 1.41, z), COLORS.tread, Enum.Material.Wood)
		end
	end
	HouseInterior.candle(folder, origin * tableCF * CFrame.new(0, 2.975, -0.8), 0.8, 9, 0.9)
	for i, z in { -0.1, 0.45, 0.95 } do
		local frame = tableCF * CFrame.new(0.2, 2.975, z) * CFrame.Angles(0, math.rad(-90 + (i - 2) * 12), 0) * CFrame.Angles(math.rad(-12), 0, 0)
		block("PhotoFrame", Vector3.new(0.6, 0.75, 0.06), frame * CFrame.new(0, 0.38, 0), COLORS.brass, Enum.Material.Metal)
		block("Photo", Vector3.new(0.46, 0.6, 0.02), frame * CFrame.new(0, 0.38, -0.04), COLORS.photo, Enum.Material.SmoothPlastic)
		for k = 1, 3 do
			block("Scratch", Vector3.new(0.03, 0.22, 0.01), frame * CFrame.new(-0.06 + k * 0.04, 0.52, -0.055) * CFrame.Angles(0, 0, math.rad(20 - k * 12)), COLORS.scratch, Enum.Material.SmoothPlastic)
		end
	end

	------------------------------------------------------------------ Rückwand: Spiegel unter einem Tuch, Durchgang zur Küche
	local backZ = Z1 - 0.1
	block("MirrorFrame", Vector3.new(2.8, 4, 0.15), CFrame.new(-3.6, FLOOR + 5.2, backZ - 0.08), COLORS.brass, Enum.Material.Metal)
	block("MirrorCloth", Vector3.new(2.6, 3.5, 0.06), CFrame.new(-3.6, FLOOR + 4.9, backZ - 0.2), COLORS.cloth, Enum.Material.Fabric)
	block("MirrorCloth", Vector3.new(2.2, 0.8, 0.12), CFrame.new(-3.5, FLOOR + 3.05, backZ - 0.25) * CFrame.Angles(math.rad(-8), 0, math.rad(4)), COLORS.cloth, Enum.Material.Fabric)
	if not mansion then
		doorway("KitchenDoorway", CFrame.new(1.4, FLOOR, backZ - 0.26), 3, 7.4)
		-- Aus der Küche fällt schwaches Kerzenlicht
		local glow = block("KitchenGlow", Vector3.new(0.2, 0.2, 0.2), CFrame.new(1.4, FLOOR + 0.8, backZ - 0.9), COLORS.flame, Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false })
		Parts.light("PointLight", glow, { Name = "CandleLight", Range = 7, Brightness = 0.5, Color = Color3.fromRGB(255, 150, 80) })
	end

	------------------------------------------------------------------ Kronleuchter ohne Licht
	local chandelier = CFrame.new(-2, CEILING, -7.5)
	block("ChandelierChain", Vector3.new(0.12, 2.6, 0.12), chandelier * CFrame.new(0, -1.3, 0), COLORS.brass, Enum.Material.Metal)
	Parts.column({ Name = "ChandelierRing", Color = COLORS.brass, Material = Enum.Material.Metal, Parent = folder }, 0.2, 2.6, origin * chandelier * CFrame.new(0, -2.8, 0))
	for i = 0, 4 do
		local angle = i / 5 * math.pi * 2
		Parts.column({ Name = "DeadCandle", Color = Color3.fromRGB(150, 140, 120), Material = Enum.Material.SmoothPlastic, Parent = folder }, 0.5, 0.18, origin * chandelier * CFrame.new(math.cos(angle) * 1.1, -2.6, math.sin(angle) * 1.1))
	end

	return folder
end

return HouseInterior
