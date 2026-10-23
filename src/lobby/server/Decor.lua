-- Pflanzen und kleine Details innerhalb des Zauns: Blumenkästen, Topfpflanzen,
-- junge Laubbäume, Farne, Blumenbeete, Trittsteinwege, ein Grillplatz-Schild und
-- eine Campingecke am Wohnwagen.
local Layout = require(script.Parent.Layout)
local Parts = require(script.Parent.Parts)

local Decor = {}

local Y = Layout.GROUND_Y
local COLORS = {
	wood = Color3.fromRGB(110, 78, 50),
	darkWood = Color3.fromRGB(64, 46, 32),
	soil = Color3.fromRGB(58, 42, 30),
	terracotta = Color3.fromRGB(170, 90, 60),
	stem = Color3.fromRGB(60, 95, 45),
	leaves = { Color3.fromRGB(70, 110, 50), Color3.fromRGB(85, 120, 55), Color3.fromRGB(60, 95, 45) },
	flowers = {
		Color3.fromRGB(220, 50, 60),
		Color3.fromRGB(245, 200, 60),
		Color3.fromRGB(240, 240, 235),
		Color3.fromRGB(150, 90, 200),
		Color3.fromRGB(240, 130, 170),
		Color3.fromRGB(250, 140, 50),
	},
}

local function pick(list, rng)
	return list[rng:NextInteger(1, #list)]
end

local function point(x, z)
	return Vector3.new(x, Y, z)
end

-- Eine Blume: Stiel, zwei Blätter und eine Blüte
local function buildFlower(parent, position, rng, height)
	height = height or rng:NextNumber(0.6, 1.1)
	Parts.new("Part", {
		Name = "Stem",
		Size = Vector3.new(0.1, height, 0.1),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)),
		Color = COLORS.stem,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
	Parts.new("Part", {
		Name = "Leaf",
		Size = Vector3.new(0.5, 0.05, 0.22),
		CFrame = CFrame.new(position + Vector3.new(0, height * 0.4, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), math.rad(20)),
		Color = COLORS.stem,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
	Parts.new("Part", {
		Name = "Blossom",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.42, 0.42, 0.42),
		CFrame = CFrame.new(position + Vector3.new(0, height, 0)),
		Color = pick(COLORS.flowers, rng),
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
end

-- Holzkasten mit Erde, Blumen und etwas Grün. Länge entlang lokal X.
local function buildPlanter(parent, cframe, length, rng)
	local planter = Instance.new("Model")
	planter.Name = "Blumenkasten"
	local block = Parts.builder(planter, cframe)
	block("Box", Vector3.new(length, 1, 1.6), CFrame.new(0, 0.5, 0), COLORS.darkWood, Enum.Material.WoodPlanks)
	block("Rim", Vector3.new(length + 0.2, 0.15, 1.8), CFrame.new(0, 1.05, 0), COLORS.wood, Enum.Material.Wood)
	block("Soil", Vector3.new(length - 0.3, 0.1, 1.3), CFrame.new(0, 1.02, 0), COLORS.soil, Enum.Material.Ground, { CanCollide = false })
	local x = -length / 2 + 0.5
	while x < length / 2 - 0.4 do
		local position = (cframe * CFrame.new(x, 1.05, rng:NextNumber(-0.35, 0.35))).Position
		if rng:NextNumber() < 0.65 then
			buildFlower(planter, position, rng)
		else
			local size = rng:NextNumber(0.6, 0.9)
			Parts.new("Part", {
				Name = "Greenery",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(size, size, size),
				CFrame = CFrame.new(position + Vector3.new(0, size * 0.35, 0)),
				Color = pick(COLORS.leaves, rng),
				Material = Enum.Material.LeafyGrass,
				CanCollide = false,
				Parent = planter,
			})
		end
		x += rng:NextNumber(0.45, 0.7)
	end
	planter.Parent = parent
end

-- Terrakotta-Topf mit buschiger Pflanze
local function buildPottedPlant(parent, position, rng)
	local pot = Instance.new("Model")
	pot.Name = "Topfpflanze"
	local base = CFrame.new(position)
	Parts.column({ Name = "Pot", Color = COLORS.terracotta, Material = Enum.Material.Concrete, Parent = pot }, 1.4, 1.5, base)
	Parts.column({ Name = "PotRim", Color = COLORS.terracotta:Lerp(Color3.new(0, 0, 0), 0.15), Material = Enum.Material.Concrete, Parent = pot }, 0.25, 1.75, base * CFrame.new(0, 1.3, 0))
	Parts.column({ Name = "Soil", Color = COLORS.soil, Material = Enum.Material.Ground, CanCollide = false, Parent = pot }, 0.05, 1.4, base * CFrame.new(0, 1.5, 0))
	local color = pick(COLORS.leaves, rng)
	for i = 1, 4 do
		local size = rng:NextNumber(1, 1.6)
		Parts.new("Part", {
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			CFrame = base * CFrame.new(rng:NextNumber(-0.35, 0.35), 1.9 + i * 0.35, rng:NextNumber(-0.35, 0.35)),
			Color = color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.25)),
			Material = Enum.Material.LeafyGrass,
			CanCollide = false,
			Parent = pot,
		})
	end
	pot.Parent = parent
end

-- Junger Laubbaum (Birke oder Ahorn) mit Rindenmulch am Fuß
local function buildYoungTree(parent, position, rng)
	local tree = Instance.new("Model")
	tree.Name = "Laubbaum"
	local base = CFrame.new(position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local birch = rng:NextNumber() < 0.5
	local height = rng:NextNumber(9, 12)

	Parts.column({ Name = "Mulch", Color = Color3.fromRGB(70, 48, 32), Material = Enum.Material.Ground, CanCollide = false, Parent = tree }, 0.05, 4.5, base)
	Parts.column({
		Name = "Trunk",
		Color = birch and Color3.fromRGB(225, 222, 212) or Color3.fromRGB(90, 66, 46),
		Material = Enum.Material.Wood,
		Parent = tree,
	}, height, 0.8, base)
	if birch then
		-- Dunkle Flecken auf der Birkenrinde
		for i = 1, 5 do
			Parts.new("Part", {
				Name = "BarkMark",
				Size = Vector3.new(0.5, 0.15, 0.1),
				CFrame = base * CFrame.Angles(0, i * 1.7, 0) * CFrame.new(0, i * height / 7, -0.38),
				Color = Color3.fromRGB(40, 38, 36),
				CanCollide = false,
				Parent = tree,
			})
		end
	end
	for _ = 1, 2 do
		local start = (base * CFrame.new(0, height * rng:NextNumber(0.55, 0.75), 0)).Position
		local angle = rng:NextNumber(0, math.pi * 2)
		Parts.beam(
			{ Name = "Branch", Color = birch and Color3.fromRGB(200, 196, 186) or Color3.fromRGB(90, 66, 46), Material = Enum.Material.Wood, CanCollide = false, Parent = tree },
			start,
			start + Vector3.new(math.cos(angle) * 2.2, 1.6, math.sin(angle) * 2.2),
			0.35
		)
	end

	local leafColor = birch and Color3.fromRGB(110, 140, 60) or Color3.fromRGB(80, 115, 50)
	for _ = 1, 6 do
		local size = rng:NextNumber(3.5, 5.5)
		Parts.new("Part", {
			Name = "Crown",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			CFrame = base * CFrame.new(rng:NextNumber(-2, 2), height + rng:NextNumber(-1.5, 1.5), rng:NextNumber(-2, 2)),
			Color = leafColor:Lerp(Color3.fromRGB(40, 60, 30), rng:NextNumber(0, 0.35)),
			Material = Enum.Material.LeafyGrass,
			CanCollide = false,
			Parent = tree,
		})
	end
	tree.Parent = parent
end

-- Farn: Wedel, die schräg nach außen hängen
local function buildFern(parent, position, rng)
	local fern = Instance.new("Model")
	fern.Name = "Farn"
	local color = pick(COLORS.leaves, rng)
	local count = rng:NextInteger(6, 8)
	local turn = rng:NextNumber(0, math.pi * 2)
	for i = 1, count do
		local length = rng:NextNumber(1.8, 2.6)
		Parts.new("Part", {
			Name = "Frond",
			Size = Vector3.new(0.5, 0.06, length),
			CFrame = CFrame.new(position)
				* CFrame.Angles(0, turn + i / count * math.pi * 2, 0)
				* CFrame.Angles(math.rad(35), 0, 0)
				* CFrame.new(0, 0, -length / 2),
			Color = color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.2)),
			Material = Enum.Material.LeafyGrass,
			CanCollide = false,
			CastShadow = false,
			Parent = fern,
		})
	end
	fern.Parent = parent
end

local function buildFlowerPatch(parent, center, rng, count)
	for _ = 1, count do
		local angle, distance = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, 2.2)
		buildFlower(parent, center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance), rng, rng:NextNumber(0.4, 0.8))
	end
end

-- Trittsteine entlang einer Linie aus Punkten
local function buildSteppingStones(parent, points, rng)
	for i = 1, #points - 1 do
		local from, to = points[i], points[i + 1]
		local steps = math.floor((to - from).Magnitude / 2.4)
		for step = 0, steps - 1 do
			local position = from:Lerp(to, step / steps) + Vector3.new(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4))
			Parts.column({
				Name = "SteppingStone",
				Color = Color3.fromRGB(125, 122, 116):Lerp(Color3.fromRGB(90, 88, 84), rng:NextNumber(0, 1)),
				Material = Enum.Material.Slate,
				Parent = parent,
			}, 0.12, rng:NextNumber(1.7, 2.3), CFrame.new(position))
		end
	end
end

local function buildWoodSign(parent, cframe, text)
	local sign = Instance.new("Model")
	sign.Name = "Holzschild"
	local block = Parts.builder(sign, cframe)
	for _, x in { -1.8, 1.8 } do
		block("Post", Vector3.new(0.35, 4, 0.35), CFrame.new(x, 2, 0.1), COLORS.darkWood, Enum.Material.Wood)
	end
	local board = block("Board", Vector3.new(4.6, 1.3, 0.2), CFrame.new(0, 3.2, 0), COLORS.wood, Enum.Material.WoodPlanks)
	Parts.text(Parts.surfaceGui(board, Enum.NormalId.Front), {
		Text = text,
		Font = Enum.Font.SpecialElite,
		TextColor3 = Color3.fromRGB(40, 28, 18),
		Size = UDim2.fromScale(0.9, 0.8),
		Position = UDim2.fromScale(0.05, 0.1),
	})
	sign.Parent = parent
end

-- Campingstuhl (echter Sitz) und kleiner Tisch vor dem Wohnwagen
local function buildCampingCorner(parent, chairCFrame, tablePosition)
	local corner = Instance.new("Model")
	corner.Name = "Campingecke"
	local block = Parts.builder(corner, chairCFrame)
	local metal = Color3.fromRGB(50, 50, 55)
	for _, x in { -0.75, 0.75 } do
		for _, z in { -0.7, 0.7 } do
			block("ChairLeg", Vector3.new(0.12, 1.4, 0.12), CFrame.new(x, 0.7, z), metal, Enum.Material.Metal)
		end
	end
	Parts.new("Seat", {
		Name = "ChairSeat",
		Size = Vector3.new(1.7, 0.15, 1.6),
		CFrame = chairCFrame * CFrame.new(0, 1.45, 0),
		Color = Color3.fromRGB(40, 90, 60),
		Material = Enum.Material.Fabric,
		Parent = corner,
	})
	block("ChairBack", Vector3.new(1.7, 1.6, 0.1), CFrame.new(0, 2.3, 0.8) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(40, 90, 60), Enum.Material.Fabric)

	local tableBase = CFrame.new(tablePosition)
	Parts.column({ Name = "TableLeg", Color = metal, Material = Enum.Material.Metal, Parent = corner }, 2, 0.2, tableBase)
	Parts.column({ Name = "TableTop", Color = Color3.fromRGB(200, 195, 185), Parent = corner }, 0.12, 2, tableBase * CFrame.new(0, 2, 0))
	Parts.column({ Name = "Mug", Color = Color3.fromRGB(60, 90, 150), Parent = corner }, 0.45, 0.35, tableBase * CFrame.new(0.4, 2.12, 0.2))
	corner.Parent = parent
end

function Decor.build(parent)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = parent
	local rng = Random.new(31)

	-- Kiosk: Blumenkästen unter den Fenstern und Topfpflanzen neben der Tür
	buildPlanter(decor, CFrame.new(-58, Y, 44.4), 9, rng)
	buildPlanter(decor, CFrame.new(-37.5, Y, 44.4), 3.6, rng)
	buildPottedPlant(decor, point(-49.4, 44.6), rng)
	buildPottedPlant(decor, point(-40.6, 44.6), rng)

	-- Infotafel, Kassenhäuschen und Bestenliste
	buildPlanter(decor, CFrame.new(-14, Y, 62), 10, rng)
	buildPottedPlant(decor, point(33, 55.5), rng)
	buildPottedPlant(decor, point(47.5, 59.5), rng)
	buildPlanter(decor, CFrame.new(63, Y, 58.2), 14, rng)

	-- Campingecke und Pflanze am Wohnwagen
	buildCampingCorner(decor, CFrame.lookAt(point(6.5, 53.5), point(6.5, 40)), point(9, 53.2))
	buildPottedPlant(decor, point(16.5, 55.4), rng)

	-- Junge Laubbäume auf dem Waldboden
	for _, position in {
		point(-56, 14),
		point(-46, 34),
		point(-62, -4),
		point(56, 24),
		point(46, 4),
		point(63, 40),
		point(-27, 55),
	} do
		buildYoungTree(decor, position, rng)
		buildFern(decor, position + Vector3.new(rng:NextNumber(2.5, 3.5), 0, rng:NextNumber(-1, 1)), rng)
	end

	-- Farne und Blumen entlang des Zauns (Stellen mit Bänken, Tafeln und Masten bleiben frei)
	local blocked = { -20, 0, 4, 12, 20, 30, 32, 50 }
	for _, side in { -1, 1 } do
		for z = -12, 66, 7 do
			local free = true
			for _, blockedZ in blocked do
				if math.abs(z - blockedZ) < 4 then
					free = false
				end
			end
			if free then
				local position = point(side * rng:NextNumber(76, 78.5), z + rng:NextNumber(-2, 2))
				if rng:NextNumber() < 0.6 then
					buildFern(decor, position, rng)
				else
					buildFlowerPatch(decor, position, rng, 5)
				end
			end
		end
	end

	-- Ein paar Blumenbeete rund um den Grillplatz
	for _, position in { point(-40, 16), point(40, 12), point(-18, -10), point(18, -12), point(0, 38) } do
		buildFlowerPatch(decor, position, rng, 9)
	end

	-- Trittsteinwege vom Grillplatz zum Kiosk und zum Wohnwagen/zur Kasse
	buildSteppingStones(decor, { point(-12, 21), point(-16, 30), point(-30, 37), point(-45, 44.5) }, rng)
	buildSteppingStones(decor, { point(14, 20), point(25, 33), point(34, 46), point(39, 55) }, rng)

	buildWoodSign(decor, CFrame.lookAt(point(-9, -12), point(-9, -30)), "GRILLPLATZ")
end

return Decor
