-- Das Haus der Gastfamilie Wagner: großes, altes Holzhaus mit zwei Stockwerken,
-- Veranda, angebauter Garage, Schornstein, Hof, Zaun und Briefkasten an der Straße.
-- Kein einziges Licht brennt. Alles wird relativ zu `Route.houseCFrame()` gebaut:
-- x nach rechts, y nach oben, -z zeigt zur Straße.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.Parts)
local Route = require(ReplicatedStorage.Shared.LevelRoute)

local House = {}

local Y = Route.GROUND_Y
local W, D = Route.HOUSE_SIZE.X, Route.HOUSE_SIZE.Z -- Wohnhaus 40 × 30
local BASE = 1.6 -- Höhe des Steinsockels (Fußboden Erdgeschoss)
local STORY = 10 -- Höhe eines Stockwerks
local TOP = BASE + 2 * STORY -- Oberkante der Wände
local RISE = 9 -- Dachhöhe über den Wänden
local GX, GW, GD, GH = Route.GARAGE_X, Route.GARAGE_SIZE.X, Route.GARAGE_SIZE.Z, 11

local COLORS = {
	siding = Color3.fromRGB(92, 84, 72), -- verwittertes, graubraunes Holz
	sidingLine = Color3.fromRGB(64, 57, 49),
	trim = Color3.fromRGB(150, 144, 130), -- früher weiß, jetzt schmutzig
	darkWood = Color3.fromRGB(52, 40, 30),
	deck = Color3.fromRGB(78, 64, 50),
	shutter = Color3.fromRGB(38, 52, 44),
	roof = Color3.fromRGB(46, 44, 44),
	glass = Color3.fromRGB(12, 14, 16),
	curtain = Color3.fromRGB(120, 112, 100),
	stone = Color3.fromRGB(78, 76, 72),
	brick = Color3.fromRGB(84, 50, 40),
	yard = Color3.fromRGB(52, 54, 38),
	gravel = Color3.fromRGB(100, 96, 88),
	metal = Color3.fromRGB(70, 72, 76),
}

function House.build(parent)
	local origin = Route.houseCFrame()
	local model = Instance.new("Model")
	model.Name = "WagnerHouse"
	local block = Parts.builder(model, origin)

	local function wedge(name, size, offset, color, material)
		return Parts.new("WedgePart", {
			Name = name,
			Size = size,
			CFrame = origin * offset,
			Color = color,
			Material = material or Enum.Material.WoodPlanks,
			Parent = model,
		})
	end

	------------------------------------------------------------------ Boden: Hof und Gelände
	-- Gelände unter dem Grundstück entfernen, damit nichts durch den Hof ragt
	local yardCFrame = origin * CFrame.new(4, 0, -4)
	workspace.Terrain:FillBlock(yardCFrame, Vector3.new(86, 8, 62), Enum.Material.Air)
	Parts.new("Part", {
		Name = "Yard",
		Size = Vector3.new(86, 4.2, 62),
		CFrame = yardCFrame * CFrame.new(0, -0.08 - 2.1, 0),
		Color = COLORS.yard,
		Material = Enum.Material.Ground,
		Parent = model,
	})

	------------------------------------------------------------------ Wohnhaus: Sockel und Wände
	block("Foundation", Vector3.new(W + 1, BASE, D + 1), CFrame.new(0, BASE / 2, 0), COLORS.stone, Enum.Material.Cobblestone)
	block("Walls", Vector3.new(W, 2 * STORY, D), CFrame.new(0, BASE + STORY, 0), COLORS.siding, Enum.Material.WoodPlanks)

	-- Seiten des Hauses: CFrame auf der Wand, LookVector zeigt nach außen
	local faces = {
		front = { cframe = CFrame.new(0, 0, -D / 2), width = W },
		back = { cframe = CFrame.new(0, 0, D / 2) * CFrame.Angles(0, math.pi, 0), width = W },
		left = { cframe = CFrame.new(-W / 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), width = D },
		right = { cframe = CFrame.new(W / 2, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), width = D },
	}
	local garageSide = CFrame.new(GX + GW / 2, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0)

	-- Waagerechte Bretter (Stülpschalung) auf allen vier Seiten
	for _, face in faces do
		for y = BASE + 0.9, TOP - 0.2, 1.1 do
			block("Siding", Vector3.new(face.width + 0.1, 0.12, 0.12), face.cframe * CFrame.new(0, y, -0.06), COLORS.sidingLine, Enum.Material.Wood)
		end
		-- Zierbrett zwischen den Stockwerken
		block("FloorTrim", Vector3.new(face.width + 0.3, 0.6, 0.3), face.cframe * CFrame.new(0, BASE + STORY, -0.15), COLORS.trim, Enum.Material.Wood)
		block("TopTrim", Vector3.new(face.width + 0.3, 0.7, 0.3), face.cframe * CFrame.new(0, TOP - 0.35, -0.15), COLORS.trim, Enum.Material.Wood)
	end
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			block("CornerBoard", Vector3.new(0.7, 2 * STORY, 0.7), CFrame.new(x * W / 2, BASE + STORY, z * D / 2), COLORS.trim, Enum.Material.Wood)
		end
	end

	------------------------------------------------------------------ Fenster (alle dunkel)
	local rng = Random.new(14)
	local function window(face, u, y, options)
		options = options or {}
		local w, h = options.width or 3.4, options.height or 5
		local base = faces[face].cframe * CFrame.new(u, y, 0)
		block("WindowGlass", Vector3.new(w, h, 0.2), base * CFrame.new(0, 0, -0.08), COLORS.glass, Enum.Material.Glass, { Reflectance = 0.12 })
		-- Rahmen, Sprossen und Fensterbank
		block("WindowFrame", Vector3.new(w + 0.8, 0.4, 0.35), base * CFrame.new(0, h / 2 + 0.2, -0.15), COLORS.trim, Enum.Material.Wood)
		block("WindowSill", Vector3.new(w + 1.1, 0.3, 0.7), base * CFrame.new(0, -h / 2 - 0.15, -0.3), COLORS.trim, Enum.Material.Wood)
		for _, side in { -1, 1 } do
			block("WindowFrame", Vector3.new(0.4, h, 0.35), base * CFrame.new(side * (w / 2 + 0.2), 0, -0.15), COLORS.trim, Enum.Material.Wood)
		end
		block("WindowBar", Vector3.new(0.15, h, 0.2), base * CFrame.new(0, 0, -0.2), COLORS.trim, Enum.Material.Wood)
		block("WindowBar", Vector3.new(w, 0.15, 0.2), base * CFrame.new(0, h * 0.1, -0.2), COLORS.trim, Enum.Material.Wood)
		-- Vorhang hinter dem Glas, manchmal halb zugezogen
		if options.curtain then
			block("Curtain", Vector3.new(w * 0.45, h - 0.3, 0.1), base * CFrame.new(-w * 0.27, 0, 0.05), COLORS.curtain, Enum.Material.Fabric)
		end
		-- Fensterläden; ab und zu hängt einer schief
		if not options.noShutters then
			for _, side in { -1, 1 } do
				local tilt = rng:NextNumber() < 0.15 and math.rad(rng:NextNumber(8, 18)) * side or 0
				block("Shutter", Vector3.new(1.4, h + 0.4, 0.2), base * CFrame.new(side * (w / 2 + 1.2), 0, -0.25) * CFrame.Angles(0, 0, tilt), COLORS.shutter, Enum.Material.WoodPlanks)
			end
		end
		-- Mit Brettern vernagelt
		if options.boarded then
			for i, angle in { 12, -9, 4 } do
				block("Board", Vector3.new(w + 1, 0.6, 0.15), base * CFrame.new(0, (i - 2) * 1.4, -0.45) * CFrame.Angles(0, 0, math.rad(angle)), COLORS.darkWood, Enum.Material.WoodPlanks)
			end
		end
	end

	local groundY, upperY = BASE + 4.6, BASE + STORY + 4.8
	-- Vorderseite: unten links und rechts der Tür, oben fünf Fenster
	for _, u in { -14, -8.5, 6, 13.5 } do
		window("front", u, groundY, { curtain = u == 6 })
	end
	for i, u in { -14, -7, 0, 7, 14 } do
		window("front", u, upperY, { curtain = i == 2 or i == 5, boarded = i == 4 })
	end
	for _, u in { -8, 8 } do
		window("left", u, groundY)
		window("left", u, upperY, { curtain = u > 0 })
		window("right", u, upperY)
	end
	for _, u in { -12, -4, 4, 12 } do
		window("back", u, groundY, { noShutters = true })
		window("back", u, upperY, { noShutters = true, boarded = u == 4 })
	end

	------------------------------------------------------------------ Haustür
	local doorX = -2
	local door = faces.front.cframe * CFrame.new(doorX, BASE, 0)
	block("DoorFrame", Vector3.new(5.2, 8.6, 0.4), door * CFrame.new(0, 4.3, -0.15), COLORS.trim, Enum.Material.Wood)
	block("Door", Vector3.new(4, 7.8, 0.3), door * CFrame.new(0, 3.9, -0.3), COLORS.darkWood, Enum.Material.WoodPlanks)
	for _, y in { 2, 5.6 } do
		block("DoorPanel", Vector3.new(2.8, 2.6, 0.12), door * CFrame.new(0, y, -0.5), Color3.fromRGB(44, 34, 26), Enum.Material.Wood)
	end
	block("DoorKnob", Vector3.new(0.3, 0.3, 0.3), door * CFrame.new(1.4, 3.8, -0.55), COLORS.metal, Enum.Material.Metal, { Shape = Enum.PartType.Ball })
	block("DoorWindow", Vector3.new(4, 1, 0.2), door * CFrame.new(0, 8.2, -0.1), COLORS.glass, Enum.Material.Glass)
	block("HouseNumber", Vector3.new(1.2, 0.8, 0.1), door * CFrame.new(3.6, 6.4, -0.1), COLORS.metal, Enum.Material.Metal)
	block("DoorMat", Vector3.new(3.6, 0.06, 2), CFrame.new(doorX, BASE + 0.03, -D / 2 - 1.4), Color3.fromRGB(70, 56, 40), Enum.Material.Fabric)

	------------------------------------------------------------------ Veranda
	local porchW, porchD = 22, 7
	local porchZ = -D / 2 - porchD / 2
	block("PorchDeck", Vector3.new(porchW, BASE, porchD), CFrame.new(doorX, BASE / 2, porchZ), COLORS.deck, Enum.Material.WoodPlanks)
	for i = 0, porchW - 1, 1.2 do
		block("DeckBoard", Vector3.new(0.08, 0.04, porchD), CFrame.new(doorX - porchW / 2 + i, BASE + 0.02, porchZ), COLORS.darkWood, Enum.Material.Wood)
	end
	-- Treppe zur Straße hin
	for step = 1, 3 do
		local height = BASE - step * BASE / 3
		block("PorchStep", Vector3.new(6, height + 0.01, 1.1), CFrame.new(doorX, height / 2, -D / 2 - porchD - step * 1.1 + 0.55), COLORS.deck, Enum.Material.WoodPlanks)
	end
	-- Pfosten, Geländer und Dach der Veranda
	local roofY = BASE + 8.6
	for _, x in { -porchW / 2 + 0.5, -4, 4, porchW / 2 - 0.5 } do
		local px = doorX + x
		block("PorchPost", Vector3.new(0.7, roofY - BASE, 0.7), CFrame.new(px, BASE + (roofY - BASE) / 2, -D / 2 - porchD + 0.4), COLORS.trim, Enum.Material.Wood)
	end
	for _, side in { -1, 1 } do
		local from, to = doorX + side * 4, doorX + side * (porchW / 2 - 0.5)
		local length = math.abs(to - from)
		local middle = (from + to) / 2
		local z = -D / 2 - porchD + 0.4
		block("Railing", Vector3.new(length, 0.3, 0.35), CFrame.new(middle, BASE + 3, z), COLORS.trim, Enum.Material.Wood)
		block("Railing", Vector3.new(length, 0.25, 0.3), CFrame.new(middle, BASE + 0.6, z), COLORS.trim, Enum.Material.Wood)
		local index = 0
		for x = math.min(from, to) + 0.6, math.max(from, to) - 0.4, 0.8 do
			index += 1
			-- ein paar Stäbe fehlen
			if index % 7 ~= 3 then
				block("Baluster", Vector3.new(0.18, 2.3, 0.18), CFrame.new(x, BASE + 1.8, z), COLORS.trim, Enum.Material.Wood)
			end
		end
	end
	local porchRoofAngle = math.rad(12)
	block("PorchRoof", Vector3.new(porchW + 1.5, 0.5, porchD + 1.6), CFrame.new(doorX, roofY + 0.9, porchZ - 0.4) * CFrame.Angles(-porchRoofAngle, 0, 0), COLORS.roof, Enum.Material.Slate)
	block("PorchBeam", Vector3.new(porchW, 0.7, 0.5), CFrame.new(doorX, roofY + 0.1, -D / 2 - porchD + 0.4), COLORS.trim, Enum.Material.Wood)
	-- Ausgeschaltete Lampe neben der Tür
	block("PorchLampBase", Vector3.new(0.5, 0.9, 0.3), door * CFrame.new(-3.4, 6, -0.2), COLORS.metal, Enum.Material.Metal)
	block("PorchLampGlass", Vector3.new(0.7, 1.1, 0.7), door * CFrame.new(-3.4, 5.6, -0.65), Color3.fromRGB(40, 40, 36), Enum.Material.Glass, { Transparency = 0.2 })
	-- Schaukelstuhl, der zur Straße schaut, und vertrocknete Blumentöpfe
	local chair = CFrame.new(doorX - 7, BASE, porchZ + 0.5) * CFrame.Angles(0, math.rad(200), 0)
	block("ChairSeat", Vector3.new(2, 0.25, 2), chair * CFrame.new(0, 1.8, 0), COLORS.darkWood, Enum.Material.Wood)
	block("ChairBack", Vector3.new(2, 2.8, 0.25), chair * CFrame.new(0, 3.2, 1) * CFrame.Angles(math.rad(-12), 0, 0), COLORS.darkWood, Enum.Material.Wood)
	for _, x in { -0.9, 0.9 } do
		block("ChairRocker", Vector3.new(0.2, 0.25, 2.8), chair * CFrame.new(x, 0.2, 0), COLORS.darkWood, Enum.Material.Wood)
		block("ChairLeg", Vector3.new(0.2, 1.6, 0.2), chair * CFrame.new(x, 1, 0), COLORS.darkWood, Enum.Material.Wood)
	end
	for _, x in { doorX + 6, doorX + 9 } do
		Parts.column({ Name = "FlowerPot", Color = Color3.fromRGB(110, 62, 44), Material = Enum.Material.Concrete, Parent = model }, 1.2, 1.4, origin * CFrame.new(x, BASE, porchZ + 2))
		block("DeadPlant", Vector3.new(0.9, 1, 0.9), CFrame.new(x, BASE + 1.6, porchZ + 2) * CFrame.Angles(0, 0, math.rad(15)), Color3.fromRGB(70, 58, 40), Enum.Material.Grass)
	end

	------------------------------------------------------------------ Dach mit Schornstein
	local slope = math.atan(RISE / (D / 2))
	local overhang = 1.6
	local slabLength = (D / 2 + overhang) / math.cos(slope)
	for _, side in { -1, 1 } do
		local z = side * (D / 2 + overhang) / 2
		local y = TOP + RISE - (D / 2 + overhang) / 2 * math.tan(slope) + 0.45
		local tilt = CFrame.new(0, y, z) * CFrame.Angles(side * slope, 0, 0)
		block("Roof", Vector3.new(W + 2 * overhang, 0.8, slabLength), tilt, COLORS.roof, Enum.Material.Slate)
		-- Schindelreihen
		for row = -slabLength / 2 + 1, slabLength / 2 - 0.5, 1.4 do
			block("Shingles", Vector3.new(W + 2 * overhang, 0.15, 0.25), tilt * CFrame.new(0, 0.45, row), Color3.fromRGB(34, 33, 33), Enum.Material.Slate)
		end
		-- Giebeldreiecke an den Seiten (zwei Keile pro Seite)
		local gableX = side * W / 2
		wedge("Gable", Vector3.new(0.9, RISE, D / 2), CFrame.new(gableX, TOP + RISE / 2, -D / 4), COLORS.siding)
		wedge("Gable", Vector3.new(0.9, RISE, D / 2), CFrame.new(gableX, TOP + RISE / 2, D / 4) * CFrame.Angles(0, math.pi, 0), COLORS.siding)
		-- Rundes Dachbodenfenster im Giebel
		block("AtticWindow", Vector3.new(0.3, 2.4, 2.4), CFrame.new(gableX + side * 0.5, TOP + 3, 0), COLORS.glass, Enum.Material.Glass, { Shape = Enum.PartType.Cylinder })
		block("AtticFrame", Vector3.new(0.25, 3, 3), CFrame.new(gableX + side * 0.45, TOP + 3, 0), COLORS.trim, Enum.Material.Wood, { Shape = Enum.PartType.Cylinder })
	end
	block("RoofRidge", Vector3.new(W + 2 * overhang, 0.6, 1), CFrame.new(0, TOP + RISE + 0.75, 0), Color3.fromRGB(30, 30, 30), Enum.Material.Slate)
	block("Chimney", Vector3.new(3.2, 13, 3.2), CFrame.new(-12, TOP + 5.5, 5), COLORS.brick, Enum.Material.Brick)
	block("ChimneyCap", Vector3.new(3.8, 0.5, 3.8), CFrame.new(-12, TOP + 12.2, 5), COLORS.stone, Enum.Material.Concrete)
	-- Regenrinne vorne, ein Stück hängt herunter
	block("Gutter", Vector3.new(W - 6, 0.4, 0.5), CFrame.new(3, TOP - 0.4, -D / 2 - overhang + 0.2), COLORS.metal, Enum.Material.Metal)
	block("Gutter", Vector3.new(6.5, 0.4, 0.5), CFrame.new(-W / 2 + 1.5, TOP - 1.6, -D / 2 - overhang + 0.2) * CFrame.Angles(0, 0, math.rad(-22)), COLORS.metal, Enum.Material.Metal)
	block("Downpipe", Vector3.new(0.4, TOP - 0.5, 0.4), CFrame.new(W / 2 - 0.6, (TOP - 0.5) / 2, -D / 2 - 0.6), COLORS.metal, Enum.Material.Metal)

	------------------------------------------------------------------ Garage (angebaut)
	local garageCenter = CFrame.new(GX, 0, 0)
	local gHalf = GD / 2
	block("GarageFoundation", Vector3.new(GW + 0.6, 0.6, GD + 0.6), garageCenter * CFrame.new(0, 0.3, 0), COLORS.stone, Enum.Material.Concrete)
	block("GarageWalls", Vector3.new(GW, GH, GD), garageCenter * CFrame.new(0, GH / 2 + 0.6, 0), COLORS.siding, Enum.Material.WoodPlanks)
	for y = 1.4, GH, 1.1 do
		block("Siding", Vector3.new(GW + 0.1, 0.12, 0.12), garageCenter * CFrame.new(0, y, -gHalf - 0.06), COLORS.sidingLine, Enum.Material.Wood)
		block("Siding", Vector3.new(0.12, 0.12, GD + 0.1), garageCenter * CFrame.new(GW / 2 + 0.06, y, 0), COLORS.sidingLine, Enum.Material.Wood)
		block("Siding", Vector3.new(GW + 0.1, 0.12, 0.12), garageCenter * CFrame.new(0, y, gHalf + 0.06), COLORS.sidingLine, Enum.Material.Wood)
	end
	-- Flaches Satteldach (First von vorne nach hinten)
	local garageSlope = math.rad(18)
	local garageRoofWidth = (GW / 2 + 1.2) / math.cos(garageSlope)
	for _, side in { -1, 1 } do
		local x = side * (GW / 2 + 1.2) / 2
		local y = GH + 0.6 + (GW / 2 + 1.2) / 2 * math.tan(garageSlope) + 0.4
		block("GarageRoof", Vector3.new(garageRoofWidth, 0.7, GD + 2), garageCenter * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, -side * garageSlope), COLORS.roof, Enum.Material.Slate)
		local rise = GW / 2 * math.tan(garageSlope)
		-- Giebel vorne und hinten
		for _, front in { -1, 1 } do
			wedge("GarageGable", Vector3.new(0.6, rise, GW / 2), garageCenter * CFrame.new(side * GW / 4, GH + 0.6 + rise / 2, front * gHalf) * CFrame.Angles(0, -side * math.pi / 2, 0), COLORS.siding)
		end
	end
	-- Garagentor mit Paneelen, unten verbeult, und kleinen dunklen Fenstern
	local gate = garageCenter * CFrame.new(0, 0.6, -gHalf)
	block("GarageDoorFrame", Vector3.new(15, 9.8, 0.4), gate * CFrame.new(0, 4.9, -0.15), COLORS.trim, Enum.Material.Wood)
	block("GarageDoor", Vector3.new(14, 9.2, 0.3), gate * CFrame.new(0, 4.6, -0.3), Color3.fromRGB(110, 106, 96), Enum.Material.WoodPlanks)
	for row = 1, 4 do
		block("GarageDoorLine", Vector3.new(14, 0.12, 0.1), gate * CFrame.new(0, row * 2.2, -0.48), Color3.fromRGB(70, 66, 58), Enum.Material.Wood)
	end
	for i = -3, 3 do
		if i ~= 0 then
			block("GarageWindow", Vector3.new(1.4, 0.9, 0.1), gate * CFrame.new(i * 1.9, 7.7, -0.48), COLORS.glass, Enum.Material.Glass)
		end
	end
	block("GarageDent", Vector3.new(3, 1.2, 0.1), gate * CFrame.new(-3.5, 0.9, -0.5) * CFrame.Angles(0, 0, math.rad(6)), Color3.fromRGB(84, 80, 72), Enum.Material.WoodPlanks)
	block("GarageHandle", Vector3.new(1, 0.25, 0.25), gate * CFrame.new(0, 1.3, -0.55), COLORS.metal, Enum.Material.Metal)
	-- Seitenfenster und Brennholzstapel
	faces.garage = { cframe = garageSide, width = GD }
	window("garage", -6, 6.5, { width = 2.6, height = 2.4, noShutters = true })
	local woodPile = CFrame.new(GX + GW / 2 + 1.6, 0, 4)
	for row = 0, 3 do
		for i = 0, 6 - row do
			block("Firewood", Vector3.new(0.9, 0.9, 3), woodPile * CFrame.new(0, 0.45 + row * 0.85, -3 + i * 1 + row * 0.5) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(96, 72, 50), Enum.Material.Wood, { Shape = Enum.PartType.Cylinder })
		end
	end
	-- Zwei alte Mülltonnen neben dem Tor
	for i, z in { -gHalf + 2, -gHalf + 4.6 } do
		local can = origin * CFrame.new(GX + GW / 2 + 1.8, 0, z)
		Parts.column({ Name = "TrashCan", Color = Color3.fromRGB(56, 60, 58), Material = Enum.Material.Metal, Parent = model }, 3.2, 2, can)
		block("TrashLid", Vector3.new(2.3, 0.25, 2.3), CFrame.new(GX + GW / 2 + 1.8, 3.35, z) * CFrame.Angles(0, 0, i == 2 and math.rad(30) or 0), Color3.fromRGB(46, 50, 48), Enum.Material.Metal)
	end

	------------------------------------------------------------------ Hof: Zaun, Briefkasten, Spuren
	-- Alter Lattenzaun vorne am Grundstück, mit Lücken
	local fenceZ = -D / 2 - 16
	local fenceFrom, fenceTo = -36, GX - GW / 2 - 4
	for x = fenceFrom, fenceTo, 1.3 do
		local index = math.floor((x - fenceFrom) / 1.3)
		if index % 9 ~= 4 then
			local lean = (index % 5 == 0) and math.rad(10) or 0
			block("Picket", Vector3.new(0.6, 3.6, 0.15), CFrame.new(x, 1.8, fenceZ) * CFrame.Angles(lean, 0, 0), COLORS.trim, Enum.Material.Wood)
		end
	end
	for _, y in { 1, 2.8 } do
		block("FenceRail", Vector3.new(fenceTo - fenceFrom, 0.3, 0.2), CFrame.new((fenceFrom + fenceTo) / 2, y, fenceZ + 0.15), COLORS.trim, Enum.Material.Wood)
	end
	-- Ein umgekipptes Kinderdreirad im Gras
	local trike = CFrame.new(-24, 0, -D / 2 - 14) * CFrame.Angles(0, math.rad(35), math.rad(80))
	block("TrikeFrame", Vector3.new(0.25, 0.25, 2.2), trike * CFrame.new(0, 0.9, 0), Color3.fromRGB(120, 30, 28), Enum.Material.Metal)
	for _, z in { -1, 1 } do
		block("TrikeWheel", Vector3.new(0.2, 1.2, 1.2), trike * CFrame.new(0, 0.6, z), Color3.fromRGB(20, 20, 20), Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
	end
	-- Schaukel aus einem Reifen an einem Gestell neben dem Haus
	local swing = CFrame.new(-W / 2 - 6, 0, 6)
	for _, z in { -2.5, 2.5 } do
		block("SwingPost", Vector3.new(0.5, 10, 0.5), swing * CFrame.new(0, 5, z), COLORS.darkWood, Enum.Material.Wood)
	end
	block("SwingBeam", Vector3.new(0.5, 0.5, 5.5), swing * CFrame.new(0, 10, 0), COLORS.darkWood, Enum.Material.Wood)
	block("SwingRope", Vector3.new(0.1, 6, 0.1), swing * CFrame.new(0, 7, 0), Color3.fromRGB(110, 100, 80), Enum.Material.Fabric)
	block("SwingTire", Vector3.new(0.8, 2.4, 2.4), swing * CFrame.new(0, 3.6, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(22, 22, 22), Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })

	-- Einfahrt aus Schotter (fängt erst neben der Straße an)
	local driveway = Route.drivewaySamples()
	for i = 1, #driveway - 1 do
		local a, b = driveway[i], driveway[i + 1]
		local middle = (a + b) / 2
		if Route.distanceToRoad(middle.X, middle.Z) > Route.ROAD_WIDTH / 2 + 0.5 then
			workspace.Terrain:FillBlock(CFrame.lookAt(middle, b), Vector3.new(11, 8, (b - a).Magnitude + 2), Enum.Material.Air)
			Parts.new("Part", {
				Name = "Driveway",
				Size = Vector3.new(10, 4.2, (b - a).Magnitude + 1),
				CFrame = CFrame.lookAt(middle, b) * CFrame.new(0, -0.03 - 2.1, 0),
				Color = COLORS.gravel,
				Material = Enum.Material.Pebble,
				Parent = model,
			})
		end
	end

	-- Schotterfläche vor dem Garagentor
	block("Driveway", Vector3.new(15, 4.2, 16), CFrame.new(GX, -0.03 - 2.1, -GD / 2 - 8), COLORS.gravel, Enum.Material.Pebble)

	-- Briefkasten an der Einfahrt
	local mailPosition = Route.sidePoint(Route.HOUSE_S - 14, Route.ROAD_WIDTH / 2 + 2.5, 0)
	local mail = CFrame.lookAt(mailPosition, Route.sidePoint(Route.HOUSE_S - 14, 0, 0))
	Parts.new("Part", { Name = "MailboxPost", Size = Vector3.new(0.4, 3.6, 0.4), CFrame = mail * CFrame.new(0, Y + 1.8, 0), Color = COLORS.darkWood, Material = Enum.Material.Wood, Parent = model })
	local box = Parts.new("Part", {
		Name = "Mailbox",
		Size = Vector3.new(1.3, 1.3, 2.2),
		CFrame = mail * CFrame.new(0, Y + 4.1, -0.3),
		Color = Color3.fromRGB(60, 62, 64),
		Material = Enum.Material.Metal,
		Parent = model,
	})
	Parts.new("Part", { Name = "MailboxFlag", Size = Vector3.new(0.1, 0.9, 0.3), CFrame = box.CFrame * CFrame.new(0.7, 0.4, 0.4), Color = Color3.fromRGB(150, 30, 26), Material = Enum.Material.Metal, Parent = model })
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		Parts.text(Parts.surfaceGui(box, face), {
			Text = "WAGNER",
			Font = Enum.Font.SpecialElite,
			TextColor3 = Color3.fromRGB(215, 205, 185),
			Size = UDim2.fromScale(0.9, 0.5),
			Position = UDim2.fromScale(0.05, 0.25),
		})
	end

	model.Parent = parent
	return model
end

return House
