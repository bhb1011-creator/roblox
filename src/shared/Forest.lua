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

-- Echte Tannen (MeshParts): liegen als Vorlagen in ReplicatedStorage.Natur.Tannen
-- (assets/natur/Tannen.model.json, erzeugt von tools/make_tree_models.py). Gibt es den
-- Ordner nicht (z. B. in einem Projekt, das ihn nicht einbindet) oder fehlen den Vorlagen
-- die Formen, werden wie bisher Tannen aus Klötzen gebaut.
local meshTemplates -- nil = noch nicht gesucht, false = keine da
local function findMeshTemplates()
	if meshTemplates ~= nil then
		return meshTemplates
	end
	meshTemplates = false
	local natur = game:GetService("ReplicatedStorage"):FindFirstChild("Natur")
	local folder = natur and natur:FindFirstChild("Tannen")
	if not folder then
		return false
	end
	local list = {}
	for _, model in folder:GetChildren() do
		local usable = model:IsA("Model")
		local top = 0
		if usable then
			for _, part in model:GetChildren() do
				if part:IsA("MeshPart") then
					if part.MeshId == "" then
						usable = false -- (Rojo konnte die Form nicht setzen: einmal Disconnect/Connect)
					end
					-- höchster Punkt über dem Fuß (die Vorlage steht mit dem Fuß auf y = 0)
					local half = part.Size / 2
					local up = part.CFrame.UpVector * half.Y
					local right = part.CFrame.RightVector * half.X
					local look = part.CFrame.LookVector * half.Z
					top = math.max(top, part.Position.Y + math.abs(up.Y) + math.abs(right.Y) + math.abs(look.Y))
				end
			end
		end
		if usable and top > 1 then
			model.WorldPivot = CFrame.new()
			table.insert(list, { model = model, height = top })
		end
	end
	if #list == 0 then
		warn("Forest: Tannen-Vorlagen gefunden, aber ohne Form – es werden Klotz-Tannen gebaut.")
		return false
	end
	table.sort(list, function(a, b)
		return a.model.Name < b.model.Name
	end)
	meshTemplates = list
	return list
end

-- Gibt es echte Tannen? Dann darf der Wald dichter werden: eine echte Tanne hat nur 2 Teile
-- (eine Klotz-Tanne 7 bis 33). Orte, die Bäume streuen, multiplizieren ihre Anzahl damit.
Forest.MESH_DENSITY = 1.8
function Forest.treeFactor()
	return findMeshTemplates() and Forest.MESH_DENSITY or 1
end

-- Stellt eine echte Tanne auf. collide = unsichtbarer Stamm zum Dagegenlaufen.
local function buildMeshPine(parent, position, height, rng, name, collide)
	local templates = findMeshTemplates()
	if not templates then
		return false
	end
	local template = templates[rng:NextInteger(1, #templates)]
	local tree = template.model:Clone()
	tree.Name = name
	tree:ScaleTo(height / template.height)
	local base = randomBase(position, rng) * CFrame.Angles(rng:NextNumber(-0.03, 0.03), 0, rng:NextNumber(-0.03, 0.03))
	tree:PivotTo(base * CFrame.new(0, -0.4, 0)) -- ein Stück in den Boden, damit kein Spalt bleibt
	if collide then
		Parts.column(
			{ Name = "TrunkCollider", Transparency = 1, CastShadow = false, CanQuery = false, Parent = tree },
			12,
			math.max(1.4, height * 0.035),
			CFrame.new(position)
		)
	end
	tree.Parent = parent
	return true
end

-- Detaillierte Tanne: zweiteiliger Stamm, dichte Etagen aus hängenden Ästen bis weit nach unten
local function buildPine(parent, position, height, rng)
	if buildMeshPine(parent, position, height, rng, "Pine", true) then
		return
	end
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
	local firstTier = height * rng:NextNumber(0.08, 0.16)
	local tiers, branches = 6, 5
	for tier = 0, tiers - 1 do
		local t = tier / (tiers - 1)
		local y = firstTier + t * (height - firstTier - 3)
		local radius = height * 0.22 * (1 - t * 0.78)
		local turn = rng:NextNumber(0, math.pi * 2)
		for branch = 1, branches do
			local angle = turn + branch / branches * math.pi * 2
			Parts.new("Part", {
				Name = "Branch",
				Size = Vector3.new(radius, 1.8 + (1 - t) * 1.2, radius * 1.05),
				CFrame = base
					* CFrame.new(0, y, 0)
					* CFrame.Angles(0, angle, 0)
					* CFrame.Angles(0, 0, math.rad(-18))
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
-- Einfache Klotz-Tanne (4 undurchsichtige Teile): für sehr weit entfernte Bäume, die man
-- nur im Nebel sieht. Durchsichtige Nadeln kosten auf der Grafikkarte viel, wenn hunderte
-- Bäume gleichzeitig im Bild sind (Kapitel 1: neben der Straße offener Blick).
local function buildBlockPine(parent, position, height, rng)
	local tree = Instance.new("Model")
	tree.Name = "FarPine"
	local base = randomBase(position, rng)
	Parts.column({ Name = "Trunk", Color = TRUNK, Material = Enum.Material.Wood, Parent = tree }, height * 0.9, height * 0.035, base)
	local leafColor = LEAVES[rng:NextInteger(1, #LEAVES)]
	for tier = 0, 2 do
		local diameter = height * (0.36 - tier * 0.1)
		Parts.column({
			Name = "Leaves",
			Color = leafColor,
			Material = Enum.Material.LeafyGrass,
			CanCollide = false,
			Parent = tree,
		}, height * 0.26, diameter, base * CFrame.new(0, height * (0.15 + tier * 0.26), 0))
	end
	tree.Parent = parent
end

local function buildSimplePine(parent, position, height, rng)
	if buildMeshPine(parent, position, height, rng, "FarPine", false) then
		return
	end
	buildBlockPine(parent, position, height, rng)
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

local function buildBush(parent, position, rng, scale)
	scale = scale or 1
	local bush = Instance.new("Model")
	bush.Name = "Bush"
	local color = LEAVES[rng:NextInteger(1, #LEAVES)]
	for _ = 1, rng:NextInteger(2, 4) do
		local size = rng:NextNumber(2.5, 5) * scale
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

-- Die einzelnen Bausteine, damit auch andere Orte (z. B. Level 1) damit Wald bauen können
Forest.builders = {
	pine = buildPine,
	simplePine = buildSimplePine,
	blockPine = buildBlockPine,
	deadTree = buildDeadTree,
	bush = buildBush,
	rock = buildRock,
	fallenLog = buildFallenLog,
	stump = buildStump,
}

-- isClear(x, z, margin) sagt, ob an einer Stelle Platz ist (nicht auf Parkplatz oder Straße).
-- roadDistance(x, z) liefert den Abstand zur Straße.
-- Lobby: der Wald rund um den Parkplatz noch dichter (nur echte Tannen in der Nähe;
-- die weit entfernten bleiben einfache Bäume, siehe unten)
local LOBBY_EXTRA = 1.5

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

	local nearLot = { -175, 175, -165, 160 }
	local roadArea = { -420, 80, -390, -60 }
	local everywhere = { -480, 480, -600, 360 }
	local function nearRoad(x, z)
		return roadDistance(x, z) < 55
	end
	local function farAway(x, z)
		local lotDistance = math.max(math.abs(x) - 80, math.abs(z) - 70, 0)
		return lotDistance > 70 and roadDistance(x, z) > 50
	end

	-- Tannen mit einem Busch am Fuß, damit der Wald auch unten dicht wirkt
	local function pineWithUndergrowth(position)
		buildPine(forest, position, rng:NextNumber(30, 52), rng)
		if rng:NextNumber() < 0.5 then
			buildBush(forest, position + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4)), rng)
		end
	end
	scatter(math.round(190 * Forest.treeFactor() * LOBBY_EXTRA), nearLot, 6, nil, pineWithUndergrowth)
	scatter(math.round(130 * Forest.treeFactor() * LOBBY_EXTRA), roadArea, 5, nearRoad, pineWithUndergrowth)
	-- Dichter Waldring direkt hinter dem Zaun: vom Parkplatz aus sieht man nicht mehr in die
	-- Ferne, nur noch Wald – und darüber die Berge (Environment.buildMountains).
	local function ring(x, z)
		local lotDistance = math.max(math.abs(x) - 80, math.abs(z) - 70, 0)
		return lotDistance > 2 and lotDistance < 45
	end
	scatter(math.round(260 * Forest.treeFactor()), { -130, 130, -120, 120 }, 3, ring, function(position)
		buildPine(forest, position, rng:NextNumber(28, 44), rng)
	end)
	scatter(260, { -130, 130, -120, 120 }, 1, ring, function(position)
		buildBush(forest, position, rng)
	end)
	-- Große, einfache Büsche weiter draußen: füllen die Lücken zwischen den Stämmen, damit man
	-- unter den Ästen nicht in die Ferne sieht (undurchsichtig, kosten kaum Leistung)
	local function outerBand(x, z)
		local lotDistance = math.max(math.abs(x) - 80, math.abs(z) - 70, 0)
		return lotDistance > 15 and lotDistance < 90
	end
	scatter(420, { -175, 175, -165, 165 }, 1, outerBand, function(position)
		buildBush(forest, position, rng, rng:NextNumber(1.4, 2.2))
	end)
	-- weit weg: einfache Bäume (durchsichtige Nadeln wären bei so vielen Bäumen im Blick zu teuer)
	scatter(math.round(320 * Forest.treeFactor()), everywhere, 8, farAway, function(position)
		buildBlockPine(forest, position, rng:NextNumber(30, 50), rng)
	end)
	scatter(26, nearLot, 6, nil, function(position)
		buildDeadTree(forest, position, rng)
	end)
	scatter(10, roadArea, 5, nearRoad, function(position)
		buildDeadTree(forest, position, rng)
	end)
	scatter(220, nearLot, 2, nil, function(position)
		buildBush(forest, position, rng)
	end)
	scatter(110, roadArea, 1, nearRoad, function(position)
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
