-- Baut die Welt der ersten Zwischensequenz: Dämmerung, Waldboden, eine lange
-- Waldstraße mit Leitpfosten, Leitplanken, Schildern und Strommasten, die Parkbucht
-- mit Waldweg und dichten Wald links und rechts.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Forest = require(ReplicatedStorage.Shared.Forest)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Route = require(ReplicatedStorage.Shared.LevelRoute)

local World = {}

local Y = Route.GROUND_Y
local WIDTH = Route.ROAD_WIDTH
local SEGMENT = 4
local COLORS = {
	asphalt = Color3.fromRGB(42, 42, 46),
	line = Color3.fromRGB(215, 210, 195),
	post = Color3.fromRGB(215, 215, 210),
	reflector = Color3.fromRGB(150, 65, 15),
	metal = Color3.fromRGB(150, 152, 158),
	darkMetal = Color3.fromRGB(45, 45, 48),
	wood = Color3.fromRGB(70, 52, 38),
	gravel = Color3.fromRGB(112, 106, 98),
	dirt = Color3.fromRGB(88, 70, 52),
	lamp = Color3.fromRGB(255, 190, 120),
}

-- Dämmerung: nicht heller, aber besser erkennbar – wenig Dunst, mehr Kontrast und
-- kühles Schattenlicht, damit Konturen von Bäumen und Straße sichtbar bleiben.
local function setupLighting()
	Lighting.ClockTime = 18.55
	Lighting.GeographicLatitude = 41
	Lighting.Brightness = 1.3
	Lighting.ExposureCompensation = -0.15
	Lighting.Ambient = Color3.fromRGB(38, 38, 50)
	Lighting.OutdoorAmbient = Color3.fromRGB(68, 66, 84)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.ShadowSoftness = 0.2
	Lighting.GlobalShadows = true
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("PostEffect") or child:IsA("Sky") then
			child:Destroy()
		end
	end
	local sky = Instance.new("Sky")
	sky.StarCount = 0
	sky.MoonTextureId = ""
	sky.SunAngularSize = 12
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.05
	atmosphere.Color = Color3.fromRGB(150, 100, 100)
	atmosphere.Decay = Color3.fromRGB(40, 32, 52)
	atmosphere.Glare = 0.8
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	local grading = Instance.new("ColorCorrectionEffect")
	grading.Saturation = 0
	grading.Contrast = 0.24
	grading.TintColor = Color3.fromRGB(240, 232, 235)
	grading.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
end

-- Abschnitte der Straße: CFrame (Mitte auf Höhe 0, Blick entlang der Straße) und Länge
local function roadSegments()
	local segments = {}
	local samples = Route.roadSamples(SEGMENT)
	for i = 1, #samples - 1 do
		local from, to = Route.centerAt(samples[i]), Route.centerAt(samples[i + 1])
		table.insert(segments, {
			s = samples[i],
			cframe = CFrame.lookAt((from + to) / 2, to),
			length = (to - from).Magnitude,
		})
	end
	return segments
end

local function buildTerrain(segments)
	local terrain = workspace.Terrain
	terrain:Clear()
	pcall(function()
		terrain.Decoration = false
	end)
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(58, 66, 40))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(78, 64, 48))
	terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(60, 50, 40))

	terrain:FillBlock(CFrame.new(10, -6, -900), Vector3.new(900, 12, 2400), Enum.Material.LeafyGrass)
	local rng = Random.new(5)
	for _ = 1, 260 do
		local s = rng:NextNumber(0, Route.TOTAL_LENGTH)
		local position = Route.sidePoint(s, rng:NextNumber(-180, 180), 0)
		terrain:FillBlock(
			CFrame.new(position.X, -2, position.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			Vector3.new(rng:NextNumber(10, 34), 4, rng:NextNumber(10, 34)),
			rng:NextNumber() < 0.7 and Enum.Material.Ground or Enum.Material.Mud
		)
	end
	-- Erdiger Seitenstreifen, dann unter Straße, Parkbucht und Waldweg das Gelände entfernen
	for _, segment in segments do
		terrain:FillBlock(segment.cframe * CFrame.new(0, -2, 0), Vector3.new(WIDTH + 12, 4, segment.length + 2), Enum.Material.Ground)
	end
	for _, segment in segments do
		terrain:FillBlock(segment.cframe, Vector3.new(WIDTH + 1, 8, segment.length + 2), Enum.Material.Air)
		if segment.s >= Route.LAYBY_START_S - 8 and segment.s <= Route.LAYBY_END_S then
			terrain:FillBlock(segment.cframe * CFrame.new(Route.LAYBY_OFFSET, 0, 0), Vector3.new(Route.LAYBY_WIDTH + 1, 8, segment.length + 2), Enum.Material.Air)
		end
	end
	local path = Route.forestPath()
	for i = 1, #path - 1 do
		local a, b = path[i], path[i + 1]
		terrain:FillBlock(CFrame.lookAt((a + b) / 2, b), Vector3.new(5.5, 8, (b - a).Magnitude + 2), Enum.Material.Air)
	end
end

local function buildRoad(parent, segments)
	local road = Instance.new("Folder")
	road.Name = "Road"
	road.Parent = parent

	local previousForward
	for index, segment in segments do
		-- Benachbarte Stücke liegen minimal versetzt, damit Überlappungen in Kurven nicht flimmern
		local lift = (index % 2) * 0.012
		local cf = segment.cframe * CFrame.new(0, lift, 0)
		local length = segment.length + 0.6
		Parts.new("Part", {
			Name = "RoadSurface",
			Size = Vector3.new(WIDTH, 4.2, length),
			CFrame = cf * CFrame.new(0, Y - 2.1, 0),
			Color = COLORS.asphalt,
			Material = Enum.Material.Asphalt,
			Parent = road,
		})
		for _, side in { -1, 1 } do
			Parts.new("Part", {
				Name = "EdgeLine",
				Size = Vector3.new(0.35, 0.02, length),
				CFrame = cf * CFrame.new(side * (WIDTH / 2 - 0.8), Y + 0.01, 0),
				Color = COLORS.line,
				CanCollide = false,
				Parent = road,
			})
		end
		if index % 4 == 0 then
			Parts.new("Part", {
				Name = "CenterLine",
				Size = Vector3.new(0.3, 0.02, 5),
				CFrame = cf * CFrame.new(0, Y + 0.01, 0),
				Color = COLORS.line,
				CanCollide = false,
				Parent = road,
			})
		end

		-- Leitpfosten alle 48 Studs auf beiden Seiten
		if index % 12 == 0 then
			for _, side in { -1, 1 } do
				local base = cf * CFrame.new(side * (WIDTH / 2 + 2.5), 0, 0)
				Parts.new("Part", { Name = "MarkerPost", Size = Vector3.new(0.5, 3.2, 0.5), CFrame = base * CFrame.new(0, 1.6, 0), Color = COLORS.post, Parent = road })
				Parts.new("Part", { Name = "MarkerBand", Size = Vector3.new(0.52, 0.5, 0.52), CFrame = base * CFrame.new(0, 2.7, 0), Color = Color3.fromRGB(25, 25, 25), Parent = road })
				Parts.new("Part", {
					Name = "Reflector",
					Size = Vector3.new(0.2, 0.3, 0.54),
					CFrame = base * CFrame.new(0, 2.7, 0),
					Color = COLORS.reflector,
					Material = Enum.Material.Neon,
					Parent = road,
				})
			end
		end

		-- Leitplanke in Kurven (auf der Außenseite)
		local forward = cf.LookVector
		if previousForward then
			local turn = previousForward:Cross(forward).Y
			if math.abs(turn) > 0.006 and not (segment.s > Route.LAYBY_START_S - 20 and segment.s < Route.LAYBY_END_S + 10) then
				local side = turn > 0 and 1 or -1
				local base = cf * CFrame.new(side * (WIDTH / 2 + 1.6), 0, 0)
				Parts.new("Part", {
					Name = "GuardRail",
					Size = Vector3.new(0.25, 0.8, length),
					CFrame = base * CFrame.new(0, 2.1, 0),
					Color = COLORS.metal,
					Material = Enum.Material.DiamondPlate,
					Parent = road,
				})
				Parts.new("Part", {
					Name = "GuardRailPost",
					Size = Vector3.new(0.3, 2.3, 0.3),
					CFrame = base * CFrame.new(side * 0.25, 1.15, 0),
					Color = COLORS.darkMetal,
					Material = Enum.Material.Metal,
					Parent = road,
				})
			end
		end
		previousForward = forward
	end
end

-- Strommasten aus Holz links der Straße, mit durchhängenden Leitungen
local function buildPowerLine(parent, segments)
	local folder = Instance.new("Folder")
	folder.Name = "PowerLine"
	folder.Parent = parent
	local tops = {}
	for index, segment in segments do
		if index % 16 == 1 then
			local base = segment.cframe * CFrame.new(-(WIDTH / 2 + 7), 0, 0)
			Parts.column({ Name = "Pole", Color = COLORS.wood, Material = Enum.Material.Wood, Parent = folder }, 22, 0.9, base)
			Parts.new("Part", {
				Name = "CrossArm",
				Size = Vector3.new(5, 0.4, 0.4),
				CFrame = base * CFrame.new(0, 21, 0),
				Color = COLORS.wood,
				Material = Enum.Material.Wood,
				Parent = folder,
			})
			local pair = {}
			for _, x in { -2.1, 2.1 } do
				local insulator = base * CFrame.new(x, 21.45, 0)
				Parts.new("Part", { Name = "Insulator", Size = Vector3.new(0.3, 0.5, 0.3), CFrame = insulator, Color = Color3.fromRGB(120, 140, 150), Parent = folder })
				table.insert(pair, (insulator * CFrame.new(0, 0.25, 0)).Position)
			end
			table.insert(tops, pair)
		end
	end
	for i = 1, #tops - 1 do
		for wire = 1, 2 do
			local a, b = tops[i][wire], tops[i + 1][wire]
			local previous = a
			for step = 1, 6 do
				local t = step / 6
				local point = a:Lerp(b, t) - Vector3.new(0, 2.2 * 4 * t * (1 - t), 0)
				Parts.beam({ Name = "Wire", Color = Color3.fromRGB(20, 20, 20), CanCollide = false, CastShadow = false, Parent = folder }, previous, point, 0.08)
				previous = point
			end
		end
	end
end

-- Verkehrsschild am rechten Straßenrand, Vorderseite zum herankommenden Auto
local function buildSign(parent, s, draw)
	local position = Route.sidePoint(s, WIDTH / 2 + 3.5, 0)
	local _, forward = Route.frameAt(s)
	local base = CFrame.lookAt(position, position - forward)
	Parts.column({ Name = "SignPost", Color = Color3.fromRGB(130, 130, 135), Material = Enum.Material.Metal, Parent = parent }, 7.5, 0.3, base)
	local board = Parts.new("Part", {
		Name = "SignBoard",
		Size = Vector3.new(3.2, 3.2, 0.12),
		CFrame = base * CFrame.new(0, 6.6, -0.25),
		Transparency = 1,
		Parent = parent,
	})
	local gui = Parts.surfaceGui(board, Enum.NormalId.Front)
	draw(gui)
end

local function roundSign(text, ring, background, textColor)
	return function(gui)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = background
		frame.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Color = ring
		stroke.Thickness = 14
		stroke.Parent = frame
		Parts.text(frame, { Text = text, TextColor3 = textColor, Size = UDim2.fromScale(0.7, 0.6), Position = UDim2.fromScale(0.15, 0.2) })
	end
end

local function boardSign(text, background, textColor, border)
	return function(gui)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 0.7)
		frame.Position = UDim2.fromScale(0, 0.15)
		frame.BackgroundColor3 = background
		frame.Parent = gui
		if border then
			local stroke = Instance.new("UIStroke")
			stroke.Color = border
			stroke.Thickness = 8
			stroke.Parent = frame
		end
		Parts.text(frame, { Text = text, TextColor3 = textColor, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	end
end

local function buildSigns(parent)
	local signs = Instance.new("Folder")
	signs.Name = "Signs"
	signs.Parent = parent
	local white, red, black = Color3.fromRGB(240, 240, 235), Color3.fromRGB(190, 30, 30), Color3.fromRGB(25, 25, 25)
	buildSign(signs, 130, roundSign("70", red, white, black))
	buildSign(signs, 300, boardSign("⚠ WILDWECHSEL", white, black, red))
	buildSign(signs, 560, boardSign("Waldheim 12 km", Color3.fromRGB(240, 200, 40), black))
	buildSign(signs, 820, boardSign("⚠ KURVEN", white, black, red))
	buildSign(signs, 1100, roundSign("50", red, white, black))
	buildSign(signs, Route.LAYBY_START_S - 120, boardSign("P  Parkplatz 200 m", Color3.fromRGB(30, 70, 150), white))
end

-- Parkbucht aus Schotter, Waldweg mit kaputter Schranke, alte Laterne, Mülleimer und Tafel
local function buildLayby(parent, segments)
	local layby = Instance.new("Folder")
	layby.Name = "Layby"
	layby.Parent = parent

	for _, segment in segments do
		if segment.s >= Route.LAYBY_START_S - 8 and segment.s <= Route.LAYBY_END_S then
			Parts.new("Part", {
				Name = "Gravel",
				Size = Vector3.new(Route.LAYBY_WIDTH, 4.2, segment.length + 1.2),
				CFrame = segment.cframe * CFrame.new(Route.LAYBY_OFFSET, Y - 2.1, 0),
				Color = COLORS.gravel,
				Material = Enum.Material.Pebble,
				Parent = layby,
			})
			-- niedrige Holzpfosten am äußeren Rand
			Parts.new("Part", {
				Name = "Bollard",
				Size = Vector3.new(0.5, 2, 0.5),
				CFrame = segment.cframe * CFrame.new(Route.LAYBY_OFFSET + Route.LAYBY_WIDTH / 2 + 0.4, Y + 0.2, 0),
				Color = COLORS.wood,
				Material = Enum.Material.Wood,
				Parent = layby,
			})
		end
	end

	-- Waldweg
	local path = Route.forestPath()
	for i = 1, #path - 1 do
		local a, b = path[i], path[i + 1]
		Parts.new("Part", {
			Name = "ForestPath",
			Size = Vector3.new(4.5, 4.2, (b - a).Magnitude + 1),
			CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, Y - 2.1, 0),
			Color = COLORS.dirt,
			Material = Enum.Material.Ground,
			Parent = layby,
		})
	end

	-- Kaputte Schranke am Anfang des Weges
	local entrance = CFrame.lookAt(path[1], path[2]) * CFrame.new(0, 0, -3)
	for _, x in { -2.8, 2.8 } do
		Parts.new("Part", { Name = "BarrierPost", Size = Vector3.new(0.6, 3, 0.6), CFrame = entrance * CFrame.new(x, Y + 1.5, 0), Color = COLORS.wood, Material = Enum.Material.Wood, Parent = layby })
	end
	Parts.new("Part", {
		Name = "BarrierLog",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(5.8, 0.5, 0.5),
		CFrame = entrance * CFrame.new(-0.6, Y + 1.2, 0) * CFrame.Angles(0, 0, math.rad(-22)),
		Color = Color3.fromRGB(95, 72, 50),
		Material = Enum.Material.Wood,
		Parent = layby,
	})

	-- Alte Laterne, die flackert
	local lampBase = CFrame.lookAt(Route.sidePoint(Route.STOP_S - 30, Route.LAYBY_OFFSET + 7.5, 0), Route.sidePoint(Route.STOP_S - 30, 0, 0))
	Parts.column({ Name = "LampPole", Color = COLORS.darkMetal, Material = Enum.Material.Metal, Parent = layby }, 14.2, 0.45, lampBase)
	Parts.new("Part", { Name = "LampArm", Size = Vector3.new(0.3, 0.3, 2.6), CFrame = lampBase * CFrame.new(0, Y + 13.8, -1.2), Color = COLORS.darkMetal, Material = Enum.Material.Metal, Parent = layby })
	local lens = Parts.new("Part", {
		Name = "LampLens",
		Size = Vector3.new(1.2, 0.3, 1.6),
		CFrame = lampBase * CFrame.new(0, Y + 13.5, -2.4),
		Color = COLORS.lamp,
		Material = Enum.Material.Neon,
		Parent = layby,
	})
	Parts.light("SpotLight", lens, { Face = Enum.NormalId.Bottom, Range = 30, Angle = 100, Brightness = 1.4, Color = COLORS.lamp, Shadows = true })
	CollectionService:AddTag(lens, "FlickerLamp")

	-- Mülleimer und eine verwitterte Infotafel
	local binBase = CFrame.new(Route.sidePoint(Route.STOP_S + 12, Route.LAYBY_OFFSET + 5, 0)) + Vector3.new(0, Y, 0)
	Parts.column({ Name = "TrashBin", Color = Color3.fromRGB(40, 60, 42), Material = Enum.Material.Metal, Parent = layby }, 3, 1.8, binBase)
	local boardPosition = Route.sidePoint(Route.STOP_S + 6, Route.LAYBY_OFFSET + Route.LAYBY_WIDTH / 2 + 1.5, 0)
	local boardBase = CFrame.lookAt(boardPosition, Route.sidePoint(Route.STOP_S + 6, 0, 0))
	for _, x in { -2.2, 2.2 } do
		Parts.new("Part", { Name = "BoardPost", Size = Vector3.new(0.4, 6, 0.4), CFrame = boardBase * CFrame.new(x, 3, 0.2), Color = COLORS.wood, Material = Enum.Material.Wood, Parent = layby })
	end
	local board = Parts.new("Part", {
		Name = "InfoBoard",
		Size = Vector3.new(5, 3, 0.25),
		CFrame = boardBase * CFrame.new(0, 4.2, 0),
		Color = Color3.fromRGB(80, 62, 44),
		Material = Enum.Material.WoodPlanks,
		Parent = layby,
	})
	Parts.text(Parts.surfaceGui(board, Enum.NormalId.Front), {
		Text = "WALDLEHRPFAD\nWege nach Einbruch der\nDunkelheit nicht betreten.",
		Font = Enum.Font.SpecialElite,
		TextColor3 = Color3.fromRGB(220, 205, 180),
		Size = UDim2.fromScale(0.9, 0.85),
		Position = UDim2.fromScale(0.05, 0.08),
	})
end

local function buildForest(parent)
	local forest = Instance.new("Folder")
	forest.Name = "Forest"
	forest.Parent = parent
	local builders = Forest.builders
	local rng = Random.new(2027)

	local function isClear(position, margin)
		return Route.distanceToRoad(position.X, position.Z) > WIDTH / 2 + 4 + margin
			and Route.distanceToLayby(position.X, position.Z) > Route.LAYBY_WIDTH / 2 + 3 + margin
			and Route.distanceToPath(position.X, position.Z) > 3.5 + margin
	end

	-- Streut Objekte in einem Band neben der Straße (Abstand von der Mitte in Studs)
	local function scatter(count, minDistance, maxDistance, margin, build)
		local placed, attempts = 0, 0
		while placed < count and attempts < count * 20 do
			attempts += 1
			local s = rng:NextNumber(0, Route.TOTAL_LENGTH)
			local side = rng:NextNumber() < 0.5 and -1 or 1
			local position = Route.sidePoint(s, side * rng:NextNumber(minDistance, maxDistance), 0)
			position = Vector3.new(position.X, 0, position.Z)
			if isClear(position, margin) then
				build(position)
				placed += 1
			end
		end
	end

	-- Große Tannen haben Äste bis ~11 Studs Radius: so weit weg, dass nichts in die Fahrbahn ragt
	scatter(240, WIDTH / 2 + 17, 55, 4, function(position)
		builders.pine(forest, position, rng:NextNumber(30, 52), rng)
	end)
	scatter(380, 55, 170, 4, function(position)
		builders.simplePine(forest, position, rng:NextNumber(32, 54), rng)
	end)
	scatter(30, 16, 70, 4, function(position)
		builders.deadTree(forest, position, rng)
	end)
	scatter(320, WIDTH / 2 + 4, 45, 1, function(position)
		builders.bush(forest, position, rng)
	end)
	scatter(90, 14, 80, 2, function(position)
		builders.rock(forest, position, rng)
	end)
	scatter(22, 18, 70, 10, function(position)
		builders.fallenLog(forest, position, rng)
	end)
	scatter(30, 14, 60, 2, function(position)
		builders.stump(forest, position, rng)
	end)
end

function World.build()
	for _, name in { "Baseplate", "SpawnLocation" } do
		local existing = workspace:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
	setupLighting()

	local segments = roadSegments()
	buildTerrain(segments)

	local world = Instance.new("Folder")
	world.Name = "Level1"
	world.Parent = workspace
	buildRoad(world, segments)
	buildPowerLine(world, segments)
	buildSigns(world)
	buildLayby(world, segments)
	buildForest(world)
end

return World
