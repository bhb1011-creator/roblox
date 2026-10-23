-- Der Wald: hohe Tannen mit Astetagen, tote Bäume, Büsche, Felsen,
-- umgestürzte Stämme und Baumstümpfe.
local Parts = require(script.Parent.Parts)

local Forest = {}

local TRUNK = Color3.fromRGB(62, 46, 34)
local DEAD_WOOD = Color3.fromRGB(78, 70, 62)
local LEAVES = {
	Color3.fromRGB(30, 52, 34),
	Color3.fromRGB(36, 58, 36),
	Color3.fromRGB(26, 44, 32),
	Color3.fromRGB(40, 54, 30),
}

local function randomBase(position, rng)
	return CFrame.new(position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
end

-- Detaillierte Tanne: zweiteiliger Stamm, unten kahl, darüber 5 Etagen aus hängenden Ästen
local function buildPine(parent, position, height, rng)
	local tree = Instance.new("Model")
	tree.Name = "Pine"
	local base = randomBase(position, rng)
		* CFrame.Angles(rng:NextNumber(-0.03, 0.03), 0, rng:NextNumber(-0.03, 0.03))
	local trunkDiameter = height * 0.04

	Parts.column({ Name = "Trunk", Color = TRUNK, Material = Enum.Material.Wood, Parent = tree }, height * 0.55, trunkDiameter, base)
	Parts.column(
		{ Name = "Trunk", Color = TRUNK, Material = Enum.Material.Wood, Parent = tree },
		height * 0.5,
		trunkDiameter * 0.65,
		base * CFrame.new(0, height * 0.5, 0)
	)

	local leafColor = LEAVES[rng:NextInteger(1, #LEAVES)]
	local firstTier = height * rng:NextNumber(0.25, 0.4)
	local tiers, branches = 5, 5
	for tier = 0, tiers - 1 do
		local t = tier / (tiers - 1)
		local y = firstTier + t * (height - firstTier - 3)
		local radius = height * 0.2 * (1 - t * 0.75)
		local turn = rng:NextNumber(0, math.pi * 2)
		for branch = 1, branches do
			local angle = turn + branch / branches * math.pi * 2
			Parts.new("Part", {
				Name = "Branch",
				Size = Vector3.new(radius, 1.4 + (1 - t) * 0.8, radius * 0.85),
				CFrame = base
					* CFrame.new(0, y, 0)
					* CFrame.Angles(0, angle, 0)
					* CFrame.Angles(0, 0, math.rad(-22))
					* CFrame.new(radius / 2, 0, 0),
				Color = leafColor:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.25)),
				Material = Enum.Material.LeafyGrass,
				CanCollide = false,
				Parent = tree,
			})
		end
	end
	Parts.column(
		{ Name = "Top", Color = leafColor, Material = Enum.Material.LeafyGrass, CanCollide = false, Parent = tree },
		4,
		1.8,
		base * CFrame.new(0, height - 3, 0)
	)

	tree.Parent = parent
end

-- Einfache Tanne für weit entfernte Stellen (spart Bauteile, im Nebel kaum zu unterscheiden)
local function buildSimplePine(parent, position, height, rng)
	local tree = Instance.new("Model")
	tree.Name = "FarPine"
	local base = randomBase(position, rng)
	Parts.column({ Name = "Trunk", Color = TRUNK, Material = Enum.Material.Wood, Parent = tree }, height * 0.9, height * 0.035, base)
	local leafColor = LEAVES[rng:NextInteger(1, #LEAVES)]
	for tier = 0, 2 do
		local diameter = height * (0.32 - tier * 0.09)
		Parts.column({
			Name = "Leaves",
			Color = leafColor,
			Material = Enum.Material.LeafyGrass,
			CanCollide = false,
			Parent = tree,
		}, height * 0.22, diameter, base * CFrame.new(0, height * (0.35 + tier * 0.2), 0))
	end
	tree.Parent = parent
end

-- Toter Baum: kahler Stamm mit ein paar krummen Ästen
local function buildDeadTree(parent, position, rng)
	local tree = Instance.new("Model")
	tree.Name = "DeadTree"
	local height = rng:NextNumber(18, 30)
	local base = randomBase(position, rng) * CFrame.Angles(rng:NextNumber(-0.06, 0.06), 0, rng:NextNumber(-0.06, 0.06))
	Parts.column({ Name = "Trunk", Color = DEAD_WOOD, Material = Enum.Material.Wood, Parent = tree }, height, 1.3, base)
	for _ = 1, rng:NextInteger(3, 5) do
		local start = (base * CFrame.new(0, rng:NextNumber(height * 0.45, height * 0.95), 0)).Position
		local angle = rng:NextNumber(0, math.pi * 2)
		local length = rng:NextNumber(4, 8)
		local direction = Vector3.new(math.cos(angle), rng:NextNumber(0.4, 1.1), math.sin(angle)).Unit
		Parts.beam(
			{ Name = "Branch", Color = DEAD_WOOD, Material = Enum.Material.Wood, CanCollide = false, Parent = tree },
			start,
			start + direction * length,
			0.45
		)
	end
	tree.Parent = parent
end

local function buildBush(parent, position, rng)
	local bush = Instance.new("Model")
	bush.Name = "Bush"
	local color = LEAVES[rng:NextInteger(1, #LEAVES)]
	for _ = 1, rng:NextInteger(2, 4) do
		local size = rng:NextNumber(2.5, 5)
		Parts.new("Part", {
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			CFrame = CFrame.new(position + Vector3.new(rng:NextNumber(-1.8, 1.8), size * 0.3, rng:NextNumber(-1.8, 1.8))),
			Color = color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.3)),
			Material = Enum.Material.LeafyGrass,
			CanCollide = false,
			Parent = bush,
		})
	end
	bush.Parent = parent
end

local function buildRock(parent, position, rng)
	local size = Vector3.new(rng:NextNumber(2, 7), rng:NextNumber(1.5, 4), rng:NextNumber(2, 6))
	Parts.new("Part", {
		Name = "Rock",
		Size = size,
		CFrame = CFrame.new(position + Vector3.new(0, size.Y * 0.25, 0))
			* CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.3, 0.3)),
		Color = Color3.fromRGB(80, 80, 82):Lerp(Color3.fromRGB(60, 66, 52), rng:NextNumber(0, 0.6)),
		Material = Enum.Material.Slate,
		Parent = parent,
	})
end

local function buildFallenLog(parent, position, rng)
	local length = rng:NextNumber(12, 22)
	local diameter = rng:NextNumber(1.4, 2.2)
	Parts.new("Part", {
		Name = "FallenLog",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(length, diameter, diameter),
		CFrame = CFrame.new(position + Vector3.new(0, diameter * 0.4, 0))
			* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.05, 0.05)),
		Color = TRUNK:Lerp(Color3.fromRGB(60, 70, 40), rng:NextNumber(0, 0.4)),
		Material = Enum.Material.Wood,
		Parent = parent,
	})
end

local function buildStump(parent, position, rng)
	local diameter = rng:NextNumber(1.6, 2.8)
	Parts.column(
		{ Name = "Stump", Color = TRUNK, Material = Enum.Material.Wood, Parent = parent },
		rng:NextNumber(1, 2.2),
		diameter,
		CFrame.new(position)
	)
end

-- isClear(x, z, margin) sagt, ob an einer Stelle Platz ist (nicht auf Parkplatz oder Straße).
-- roadDistance(x, z) liefert den Abstand zur Straße.
function Forest.build(parent, isClear, roadDistance)
	local forest = Instance.new("Folder")
	forest.Name = "Forest"
	forest.Parent = parent

	local rng = Random.new(1337)

	local function scatter(count, area, margin, want, build)
		local placed, attempts = 0, 0
		while placed < count and attempts < count * 40 do
			attempts += 1
			local x = rng:NextNumber(area[1], area[2])
			local z = rng:NextNumber(area[3], area[4])
			if isClear(x, z, margin) and (not want or want(x, z)) then
				build(Vector3.new(x, 0, z))
				placed += 1
			end
		end
	end

	local nearLot = { -135, 135, -130, 125 }
	local roadArea = { -380, 70, -340, -40 }
	local everywhere = { -420, 420, -540, 300 }
	local function nearRoad(x, z)
		return roadDistance(x, z) < 55
	end
	local function farAway(x, z)
		local lotDistance = math.max(math.abs(x) - 60, math.abs(z) - 50, 0)
		return lotDistance > 70 and roadDistance(x, z) > 50
	end

	scatter(150, nearLot, 6, nil, function(position)
		buildPine(forest, position, rng:NextNumber(28, 48), rng)
	end)
	scatter(110, roadArea, 5, nearRoad, function(position)
		buildPine(forest, position, rng:NextNumber(28, 48), rng)
	end)
	scatter(280, everywhere, 8, farAway, function(position)
		buildSimplePine(forest, position, rng:NextNumber(30, 50), rng)
	end)
	scatter(26, nearLot, 6, nil, function(position)
		buildDeadTree(forest, position, rng)
	end)
	scatter(10, roadArea, 5, nearRoad, function(position)
		buildDeadTree(forest, position, rng)
	end)
	scatter(170, nearLot, 2, nil, function(position)
		buildBush(forest, position, rng)
	end)
	scatter(80, roadArea, 1, nearRoad, function(position)
		buildBush(forest, position, rng)
	end)
	scatter(70, nearLot, 3, nil, function(position)
		buildRock(forest, position, rng)
	end)
	scatter(30, roadArea, 3, nearRoad, function(position)
		buildRock(forest, position, rng)
	end)
	scatter(16, nearLot, 12, nil, function(position)
		buildFallenLog(forest, position, rng)
	end)
	scatter(26, nearLot, 4, nil, function(position)
		buildStump(forest, position, rng)
	end)
end

return Forest
