-- Baut die komplette Lobby per Code: Parkplatz, Straße, Wald, Laternen,
-- Lagerfeuer, Infotafel, Shop-Kiosk, Bestenliste, Schranke und Autos.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Parts = require(script.Parent.Parts)

local LobbyBuilder = {}

local LOT = { halfWidth = 60, minZ = -50, maxZ = 46, entranceHalfWidth = 8 }
local GATE_Z = 47
local ROAD_END_Z = 460
LobbyBuilder.LOT = LOT

local COLORS = {
	asphalt = Color3.fromRGB(40, 40, 44),
	line = Color3.fromRGB(205, 200, 185),
	curb = Color3.fromRGB(95, 95, 98),
	ground = Color3.fromRGB(34, 42, 28),
	trunk = Color3.fromRGB(58, 42, 30),
	leaves = { Color3.fromRGB(26, 48, 32), Color3.fromRGB(32, 54, 34), Color3.fromRGB(22, 40, 30) },
	wood = Color3.fromRGB(92, 66, 44),
	darkWood = Color3.fromRGB(60, 44, 32),
	metal = Color3.fromRGB(70, 72, 76),
	lamp = Color3.fromRGB(255, 205, 140),
	board = Color3.fromRGB(28, 26, 24),
}

local function setupLighting()
	-- Fester Sonnenuntergang: die Uhrzeit wird nie verändert.
	Lighting.ClockTime = Config.LOBBY_CLOCK_TIME
	Lighting.GeographicLatitude = 41
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(45, 35, 40)
	Lighting.OutdoorAmbient = Color3.fromRGB(95, 70, 70)
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.GlobalShadows = true

	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("ColorCorrectionEffect") then
			child:Destroy()
		end
	end

	-- Dichter, warmer Dunst: die Straße verschwindet nach ein paar Metern im Nebel.
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.48
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(200, 130, 100)
	atmosphere.Decay = Color3.fromRGB(70, 40, 60)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 2.4
	atmosphere.Parent = Lighting

	local grading = Instance.new("ColorCorrectionEffect")
	grading.Name = "LobbyGrading"
	grading.Saturation = -0.15
	grading.Contrast = 0.1
	grading.TintColor = Color3.fromRGB(255, 235, 220)
	grading.Parent = Lighting
end

local function removeTemplateParts()
	-- Die Studio-Vorlage "Baseplate" bringt eigene Teile mit, die wir nicht brauchen.
	for _, name in { "Baseplate", "SpawnLocation" } do
		local existing = workspace:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
end

local function buildGround(parent)
	Parts.new("Part", {
		Name = "Ground",
		Size = Vector3.new(700, 2, 800),
		CFrame = CFrame.new(0, -1, 150),
		Color = COLORS.ground,
		Material = Enum.Material.Grass,
		Parent = parent,
	})
end

local function buildParkingLot(parent)
	local lot = Instance.new("Folder")
	lot.Name = "ParkingLot"
	lot.Parent = parent

	local depth = LOT.maxZ - LOT.minZ
	local midZ = (LOT.maxZ + LOT.minZ) / 2
	Parts.new("Part", {
		Name = "Asphalt",
		Size = Vector3.new(LOT.halfWidth * 2, 0.2, depth),
		CFrame = CFrame.new(0, 0.1, midZ),
		Color = COLORS.asphalt,
		Material = Enum.Material.Asphalt,
		Parent = lot,
	})

	-- Bordsteine rundherum, mit Lücke für die Einfahrt
	local sideLength = LOT.halfWidth - LOT.entranceHalfWidth
	local curbs = {
		{ Vector3.new(LOT.halfWidth * 2 + 1, 0.6, 1), Vector3.new(0, 0.3, LOT.minZ) },
		{ Vector3.new(1, 0.6, depth), Vector3.new(-LOT.halfWidth, 0.3, midZ) },
		{ Vector3.new(1, 0.6, depth), Vector3.new(LOT.halfWidth, 0.3, midZ) },
		{ Vector3.new(sideLength, 0.6, 1), Vector3.new(-(LOT.entranceHalfWidth + sideLength / 2), 0.3, LOT.maxZ) },
		{ Vector3.new(sideLength, 0.6, 1), Vector3.new(LOT.entranceHalfWidth + sideLength / 2, 0.3, LOT.maxZ) },
	}
	for _, curb in curbs do
		Parts.new("Part", {
			Name = "Curb",
			Size = curb[1],
			CFrame = CFrame.new(curb[2]),
			Color = COLORS.curb,
			Material = Enum.Material.Concrete,
			Parent = lot,
		})
	end

	-- Parklinien und Beschriftung auf dem Boden für jede Parkbucht
	for _, car in Config.CARS do
		local x = car.position.X
		for _, lineX in { x - 8, x + 8 } do
			Parts.new("Part", {
				Name = "ParkingLine",
				Size = Vector3.new(0.3, 0.02, 16),
				CFrame = CFrame.new(lineX, 0.21, -38),
				Color = COLORS.line,
				CanCollide = false,
				Parent = lot,
			})
		end

		local marking = Parts.new("Part", {
			Name = "BayMarking",
			Size = Vector3.new(12, 0.02, 3),
			CFrame = CFrame.new(x, 0.21, -27) * CFrame.Angles(0, math.pi, 0),
			Transparency = 1,
			CanCollide = false,
			Parent = lot,
		})
		local gui = Parts.surfaceGui(marking, Enum.NormalId.Top)
		Parts.text(gui, {
			Text = Config.MODES[car.mode].title,
			TextColor3 = COLORS.line,
			TextTransparency = 0.15,
		})
	end
end

local function buildRoad(parent)
	local road = Instance.new("Folder")
	road.Name = "Road"
	road.Parent = parent

	local length = ROAD_END_Z - LOT.maxZ
	Parts.new("Part", {
		Name = "RoadSurface",
		Size = Vector3.new(14, 0.2, length),
		CFrame = CFrame.new(0, 0.1, LOT.maxZ + length / 2),
		Color = COLORS.asphalt,
		Material = Enum.Material.Asphalt,
		Parent = road,
	})

	for z = LOT.maxZ + 8, ROAD_END_Z - 4, 10 do
		Parts.new("Part", {
			Name = "CenterLine",
			Size = Vector3.new(0.3, 0.02, 4),
			CFrame = CFrame.new(0, 0.21, z),
			Color = COLORS.line,
			CanCollide = false,
			Parent = road,
		})
	end
end

local function buildTree(parent, position, scale, rng)
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	local base = CFrame.new(position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local trunkHeight = 9 * scale

	Parts.column({
		Name = "Trunk",
		Color = COLORS.trunk,
		Material = Enum.Material.Wood,
		Parent = tree,
	}, trunkHeight, 1.6 * scale, base)

	local leafColor = COLORS.leaves[rng:NextInteger(1, #COLORS.leaves)]
	for tier = 1, 3 do
		local height = 3.2 * scale
		local diameter = (12.5 - tier * 2.8) * scale
		local y = trunkHeight * 0.45 + (tier - 1) * 3 * scale
		Parts.column({
			Name = "Leaves",
			Color = leafColor,
			Material = Enum.Material.Grass,
			Parent = tree,
		}, height, diameter, base * CFrame.new(0, y, 0))
	end

	tree.Parent = parent
end

local function isClearForTree(x, z)
	local insideLot = math.abs(x) < LOT.halfWidth + 8 and z > LOT.minZ - 8 and z < LOT.maxZ + 4
	local onRoad = math.abs(x) < 13 and z > LOT.maxZ - 2
	return not insideLot and not onRoad
end

local function buildForest(parent)
	local forest = Instance.new("Folder")
	forest.Name = "Forest"
	forest.Parent = parent

	local rng = Random.new(1337)
	-- {Anzahl, minX, maxX, minZ, maxZ}: dicht am Parkplatz, an der Straße und weiter weg
	local areas = {
		{ 170, -110, 110, -100, 90 },
		{ 190, -50, 50, 50, ROAD_END_Z },
		{ 160, -240, 240, -220, ROAD_END_Z + 20 },
	}
	for _, area in areas do
		local placed, attempts = 0, 0
		while placed < area[1] and attempts < area[1] * 20 do
			attempts += 1
			local x = rng:NextNumber(area[2], area[3])
			local z = rng:NextNumber(area[4], area[5])
			if isClearForTree(x, z) then
				buildTree(forest, Vector3.new(x, 0, z), rng:NextNumber(0.9, 1.7), rng)
				placed += 1
			end
		end
	end
end

local function buildLamp(parent, position)
	local lamp = Instance.new("Model")
	lamp.Name = "StreetLamp"
	local base = CFrame.new(position)

	Parts.column({ Name = "Pole", Color = COLORS.metal, Material = Enum.Material.Metal, Parent = lamp }, 14, 0.6, base)
	local head = Parts.new("Part", {
		Name = "LampHead",
		Size = Vector3.new(2.2, 0.6, 2.2),
		CFrame = base * CFrame.new(0, 14.2, 0),
		Color = COLORS.lamp,
		Material = Enum.Material.Neon,
		Parent = lamp,
	})
	local light = Instance.new("PointLight")
	light.Range = 38
	light.Brightness = 1.4
	light.Color = COLORS.lamp
	light.Shadows = true
	light.Parent = head
	CollectionService:AddTag(head, "FlickerLamp")

	lamp.Parent = parent
end

local function buildCampfire(parent, center)
	local campfire = Instance.new("Model")
	campfire.Name = "Campfire"
	local base = CFrame.new(center)

	for i = 0, 7 do
		local angle = i / 8 * math.pi * 2
		Parts.new("Part", {
			Name = "Stone",
			Size = Vector3.new(1.4, 0.9, 1.1),
			CFrame = base * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.6, -2.6),
			Color = Color3.fromRGB(85, 85, 88),
			Material = Enum.Material.Slate,
			Parent = campfire,
		})
	end
	for _, angle in { 0, math.rad(70), math.rad(140) } do
		Parts.new("Part", {
			Name = "Log",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3.6, 0.7, 0.7),
			CFrame = base * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, angle, math.rad(12)),
			Color = COLORS.darkWood,
			Material = Enum.Material.Wood,
			CanCollide = false,
			Parent = campfire,
		})
	end

	local flame = Parts.new("Part", {
		Name = "Flame",
		Size = Vector3.new(1, 1, 1),
		CFrame = base * CFrame.new(0, 1.2, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = campfire,
	})
	local fire = Instance.new("Fire")
	fire.Size = 5
	fire.Heat = 9
	fire.Parent = flame
	local light = Instance.new("PointLight")
	light.Range = 26
	light.Brightness = 2
	light.Color = Color3.fromRGB(255, 140, 60)
	light.Shadows = true
	light.Parent = flame
	CollectionService:AddTag(flame, "Campfire")

	-- Baumstamm-Bänke um das Feuer
	for _, bench in { { -7, 0, 0 }, { 7, 0, 0 }, { 0, 7, 90 } } do
		Parts.new("Part", {
			Name = "Bench",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(6, 1.4, 1.4),
			CFrame = base * CFrame.new(bench[1], 0.7, bench[2]) * CFrame.Angles(0, math.rad(bench[3] + 90), 0),
			Color = COLORS.wood,
			Material = Enum.Material.Wood,
			Parent = campfire,
		})
	end

	campfire.Parent = parent
end

-- Tafel mit zwei Pfosten; gibt die Tafel zurück (Vorderseite zeigt Richtung Parkplatz)
local function buildBoard(parent, name, position, width, height)
	local model = Instance.new("Model")
	model.Name = name
	local base = CFrame.new(position)
	for _, x in { -width / 2 + 0.5, width / 2 - 0.5 } do
		Parts.new("Part", {
			Name = "Post",
			Size = Vector3.new(0.6, height + 2, 0.6),
			CFrame = base * CFrame.new(x, (height + 2) / 2, 0.3),
			Color = COLORS.darkWood,
			Material = Enum.Material.Wood,
			Parent = model,
		})
	end
	local board = Parts.new("Part", {
		Name = "Board",
		Size = Vector3.new(width, height, 0.4),
		CFrame = base * CFrame.new(0, 2 + height / 2, 0),
		Color = COLORS.board,
		Material = Enum.Material.Wood,
		Parent = model,
	})
	model.Parent = parent
	return board
end

local function buildInfoBoard(parent)
	local board = buildBoard(parent, "InfoBoard", Vector3.new(-45, 0, 36), 13, 7)
	local gui = Parts.surfaceGui(board, Enum.NormalId.Front)

	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui

	Parts.text(gui, {
		Text = string.upper(Config.GAME_TITLE),
		Font = Enum.Font.Creepster,
		TextColor3 = Color3.fromRGB(220, 60, 50),
		Size = UDim2.fromScale(0.9, 0.32),
		LayoutOrder = 1,
	})
	Parts.text(gui, {
		Text = Config.GAME_SUBTITLE .. "…",
		Font = Enum.Font.SpecialElite,
		TextColor3 = Color3.fromRGB(230, 220, 200),
		Size = UDim2.fromScale(0.85, 0.13),
		LayoutOrder = 2,
	})
	Parts.text(gui, {
		Text = "Steig in ein Auto – allein oder zu zweit.\nÜberlebe die Nacht.",
		Font = Enum.Font.SpecialElite,
		TextColor3 = Color3.fromRGB(180, 170, 155),
		Size = UDim2.fromScale(0.85, 0.24),
		LayoutOrder = 3,
	})
end

local function buildShop(parent)
	local shop = Instance.new("Model")
	shop.Name = "ShopKiosk"
	local base = CFrame.new(-26, 0, 36)

	local counter = Parts.new("Part", {
		Name = "Counter",
		Size = Vector3.new(10, 3.5, 6),
		CFrame = base * CFrame.new(0, 1.75, 0),
		Color = COLORS.wood,
		Material = Enum.Material.WoodPlanks,
		Parent = shop,
	})
	for _, corner in { { -4.7, -2.7 }, { 4.7, -2.7 }, { -4.7, 2.7 }, { 4.7, 2.7 } } do
		Parts.new("Part", {
			Name = "Post",
			Size = Vector3.new(0.5, 3.5, 0.5),
			CFrame = base * CFrame.new(corner[1], 5.25, corner[2]),
			Color = COLORS.darkWood,
			Material = Enum.Material.Wood,
			Parent = shop,
		})
	end
	Parts.new("Part", {
		Name = "BackWall",
		Size = Vector3.new(10, 3.5, 0.4),
		CFrame = base * CFrame.new(0, 5.25, 2.8),
		Color = COLORS.darkWood,
		Material = Enum.Material.WoodPlanks,
		Parent = shop,
	})
	Parts.new("Part", {
		Name = "Roof",
		Size = Vector3.new(11, 0.5, 7),
		CFrame = base * CFrame.new(0, 7.25, 0),
		Color = COLORS.darkWood,
		Material = Enum.Material.Wood,
		Parent = shop,
	})

	-- Gestreiftes Vordach
	for i = 0, 4 do
		Parts.new("Part", {
			Name = "Awning",
			Size = Vector3.new(2.2, 0.25, 3),
			CFrame = base * CFrame.new(-4.4 + i * 2.2, 6.7, -4.3) * CFrame.Angles(math.rad(-25), 0, 0),
			Color = i % 2 == 0 and Color3.fromRGB(150, 35, 35) or Color3.fromRGB(220, 215, 200),
			Material = Enum.Material.Fabric,
			CanCollide = false,
			Parent = shop,
		})
	end

	local sign = Parts.new("Part", {
		Name = "Sign",
		Size = Vector3.new(8, 1.8, 0.3),
		CFrame = base * CFrame.new(0, 8.6, -2.8),
		Color = COLORS.board,
		Parent = shop,
	})
	Parts.text(Parts.surfaceGui(sign, Enum.NormalId.Front), {
		Text = "🛒 SHOP",
		TextColor3 = Color3.fromRGB(255, 210, 120),
	})

	local light = Instance.new("PointLight")
	light.Range = 14
	light.Brightness = 1
	light.Color = COLORS.lamp
	light.Parent = sign

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Shop öffnen"
	prompt.ObjectText = "Kiosk"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	CollectionService:AddTag(prompt, "ShopPrompt")

	shop.Parent = parent
end

local function buildLeaderboard(parent)
	local booth = Instance.new("Model")
	booth.Name = "LeaderboardBooth"
	local base = CFrame.new(36, 0, 38)

	Parts.new("Part", {
		Name = "Walls",
		Size = Vector3.new(8, 8, 7),
		CFrame = base * CFrame.new(0, 4, 0),
		Color = Color3.fromRGB(150, 145, 135),
		Material = Enum.Material.Concrete,
		Parent = booth,
	})
	Parts.new("Part", {
		Name = "Roof",
		Size = Vector3.new(9, 0.5, 8),
		CFrame = base * CFrame.new(0, 8.25, 0),
		Color = COLORS.metal,
		Material = Enum.Material.Metal,
		Parent = booth,
	})

	local board = Parts.new("Part", {
		Name = "Board",
		Size = Vector3.new(7, 5.5, 0.3),
		CFrame = base * CFrame.new(0, 4.4, -3.65),
		Color = COLORS.board,
		Parent = booth,
	})
	CollectionService:AddTag(board, "LeaderboardBoard")

	local gui = Parts.surfaceGui(board, Enum.NormalId.Front)
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui
	Parts.text(gui, {
		Name = "Title",
		Text = "🏆 ÜBERLEBT",
		TextColor3 = Color3.fromRGB(255, 210, 120),
		Size = UDim2.fromScale(1, 0.22),
		LayoutOrder = 0,
	})
	for rank = 1, 5 do
		Parts.text(gui, {
			Name = "Row" .. rank,
			Text = rank .. ".  ---",
			Font = Enum.Font.SpecialElite,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(0.85, 0.13),
			LayoutOrder = rank,
		})
	end

	local light = Instance.new("PointLight")
	light.Range = 12
	light.Brightness = 0.8
	light.Color = COLORS.lamp
	light.Parent = board

	booth.Parent = parent
end

-- Schranke an der Einfahrt. Mehrere Autos können sie gleichzeitig offen halten.
local function buildGate(parent)
	local gateModel = Instance.new("Model")
	gateModel.Name = "Gate"

	Parts.new("Part", {
		Name = "Post",
		Size = Vector3.new(1, 4, 1),
		CFrame = CFrame.new(-10, 2, GATE_Z),
		Color = Color3.fromRGB(200, 190, 60),
		Parent = gateModel,
	})
	Parts.new("Part", {
		Name = "Rest",
		Size = Vector3.new(0.6, 3.2, 0.6),
		CFrame = CFrame.new(9.5, 1.6, GATE_Z),
		Color = COLORS.metal,
		Parent = gateModel,
	})

	local pivot = CFrame.new(-9.5, 3.6, GATE_Z)
	local closed = pivot * CFrame.new(9, 0, 0)
	local open = pivot * CFrame.Angles(0, 0, math.rad(80)) * CFrame.new(9, 0, 0)
	local arm = Parts.new("Part", {
		Name = "Arm",
		Size = Vector3.new(18, 0.5, 0.5),
		CFrame = closed,
		Color = Color3.fromRGB(190, 40, 40),
		Parent = gateModel,
	})
	gateModel.Parent = parent

	local users = 0
	local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local gate = {}
	function gate.open()
		users += 1
		TweenService:Create(arm, tweenInfo, { CFrame = open }):Play()
	end
	function gate.close()
		users = math.max(users - 1, 0)
		if users == 0 then
			TweenService:Create(arm, tweenInfo, { CFrame = closed }):Play()
		end
	end
	return gate
end

-- Unsichtbare Wände: Spieler können den Parkplatz nicht verlassen.
-- Die Autos fahren durch, weil sie per Code bewegt werden.
local function buildBounds(parent)
	local width = LOT.halfWidth * 2 + 4
	local depth = GATE_Z + 2 - LOT.minZ + 2
	local midZ = (GATE_Z + 2 + LOT.minZ - 1) / 2
	local walls = {
		{ Vector3.new(width, 40, 1), Vector3.new(0, 20, LOT.minZ - 1) },
		{ Vector3.new(width, 40, 1), Vector3.new(0, 20, GATE_Z + 2) },
		{ Vector3.new(1, 40, depth), Vector3.new(-LOT.halfWidth - 1, 20, midZ) },
		{ Vector3.new(1, 40, depth), Vector3.new(LOT.halfWidth + 1, 20, midZ) },
	}
	for _, wall in walls do
		Parts.new("Part", {
			Name = "InvisibleWall",
			Size = wall[1],
			CFrame = CFrame.new(wall[2]),
			Transparency = 1,
			CanQuery = false,
			Parent = parent,
		})
	end
end

-- Ein einfaches Auto aus Blöcken. Vorne ist -Z (Blickrichtung von homeCFrame).
function LobbyBuilder.buildCar(parent, homeCFrame, color, seatCount, name, title)
	local model = Instance.new("Model")
	model.Name = name

	local function piece(className, offset, props)
		props.CFrame = homeCFrame * offset
		props.Parent = model
		return Parts.new(className, props)
	end

	local body = piece("Part", CFrame.new(0, 2, 0), {
		Name = "Body",
		Size = Vector3.new(6.4, 2, 13),
		Color = color,
		Material = Enum.Material.Metal,
	})
	piece("Part", CFrame.new(0, 7.7, 1.2), {
		Name = "Roof",
		Size = Vector3.new(6.2, 0.4, 6.4),
		Color = color,
		Material = Enum.Material.Metal,
	})
	for _, x in { -2.95, 2.95 } do
		for _, z in { -1.8, 4.2 } do
			piece("Part", CFrame.new(x, 5.25, z), {
				Name = "Pillar",
				Size = Vector3.new(0.3, 4.5, 0.3),
				Color = color,
				Material = Enum.Material.Metal,
			})
		end
	end

	local glassProps = {
		Color = Color3.fromRGB(120, 140, 160),
		Material = Enum.Material.Glass,
		Transparency = 0.55,
	}
	local glassPanes = {
		{ CFrame.new(0, 5.25, -1.8), Vector3.new(5.6, 4.5, 0.15) },
		{ CFrame.new(0, 5.25, 4.2), Vector3.new(5.6, 4.5, 0.15) },
		{ CFrame.new(-2.95, 5.25, 1.2), Vector3.new(0.15, 4.5, 5.7) },
		{ CFrame.new(2.95, 5.25, 1.2), Vector3.new(0.15, 4.5, 5.7) },
	}
	for _, pane in glassPanes do
		piece("Part", pane[1], {
			Name = "Window",
			Size = pane[2],
			Color = glassProps.Color,
			Material = glassProps.Material,
			Transparency = glassProps.Transparency,
		})
	end

	for _, x in { -3.3, 3.3 } do
		for _, z in { -4.2, 4.2 } do
			piece("Part", CFrame.new(x, 1.2, z), {
				Name = "Wheel",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1.2, 2.4, 2.4),
				Color = Color3.fromRGB(25, 25, 25),
			})
		end
	end

	for _, x in { -2.2, 2.2 } do
		local headlight = piece("Part", CFrame.new(x, 2.5, -6.55), {
			Name = "Headlight",
			Size = Vector3.new(1.2, 0.6, 0.2),
			Color = Color3.fromRGB(255, 245, 220),
			Material = Enum.Material.Neon,
		})
		local beam = Instance.new("SpotLight")
		beam.Face = Enum.NormalId.Front
		beam.Range = 45
		beam.Angle = 60
		beam.Brightness = 2
		beam.Color = Color3.fromRGB(255, 240, 210)
		beam.Parent = headlight

		piece("Part", CFrame.new(x, 2.5, 6.55), {
			Name = "Taillight",
			Size = Vector3.new(1.2, 0.6, 0.2),
			Color = Color3.fromRGB(200, 20, 20),
			Material = Enum.Material.Neon,
		})
	end

	local seats = {}
	local seatSides = seatCount == 1 and { -1 } or { -1, 1 }
	for _, side in seatSides do
		local seat = piece("Seat", CFrame.new(side * 1.4, 3.3, 0.8), {
			Name = "Seat",
			Size = Vector3.new(2, 0.6, 2),
			Color = Color3.fromRGB(40, 40, 45),
			Material = Enum.Material.Fabric,
		})
		seat:SetAttribute("LobbyCar", true)
		table.insert(seats, { seat = seat, exitOffset = CFrame.new(side * 6.5, 3, 0.8) })
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Einsteigen"
	prompt.ObjectText = title
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	-- Schild über dem Auto
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StatusSign"
	billboard.Size = UDim2.fromOffset(220, 96)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 11, 0)
	billboard.MaxDistance = 110
	billboard.LightInfluence = 0
	billboard.Adornee = body
	billboard.Parent = body

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(15, 12, 12)
	panel.BackgroundTransparency = 0.3
	panel.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local labels = {
		mode = Parts.text(panel, {
			Name = "Mode",
			Text = title,
			TextColor3 = Color3.fromRGB(255, 210, 120),
			Size = UDim2.new(1, -16, 0.4, 0),
			Position = UDim2.new(0, 8, 0.04, 0),
		}),
		count = Parts.text(panel, {
			Name = "Count",
			Text = "",
			Size = UDim2.new(1, -16, 0.26, 0),
			Position = UDim2.new(0, 8, 0.44, 0),
		}),
		status = Parts.text(panel, {
			Name = "Status",
			Text = "",
			Font = Enum.Font.Gotham,
			TextColor3 = Color3.fromRGB(210, 200, 190),
			Size = UDim2.new(1, -16, 0.22, 0),
			Position = UDim2.new(0, 8, 0.72, 0),
		}),
	}

	model.PrimaryPart = body
	model.WorldPivot = homeCFrame
	model:SetAttribute("State", "Idle")
	model.Parent = parent

	return {
		model = model,
		seats = seats,
		prompt = prompt,
		labels = labels,
	}
end

function LobbyBuilder.build()
	removeTemplateParts()
	setupLighting()

	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = workspace

	buildGround(lobby)
	buildParkingLot(lobby)
	buildRoad(lobby)
	buildForest(lobby)
	buildBounds(lobby)

	local lamps = Instance.new("Folder")
	lamps.Name = "Lamps"
	lamps.Parent = lobby
	for _, position in {
		Vector3.new(0, 0, -48),
		Vector3.new(-30, 0, -4),
		Vector3.new(30, 0, -4),
		Vector3.new(-30, 0, 26),
		Vector3.new(30, 0, 26),
	} do
		buildLamp(lamps, position)
	end

	buildCampfire(lobby, Vector3.new(0, 0, 10))
	buildInfoBoard(lobby)
	buildShop(lobby)
	buildLeaderboard(lobby)

	Parts.new("SpawnLocation", {
		Name = "LobbySpawn",
		Size = Vector3.new(14, 0.2, 8),
		CFrame = CFrame.new(0, 0.3, -6),
		Transparency = 1,
		CanCollide = false,
		Neutral = true,
		Duration = 0,
		Parent = lobby,
	})

	local cars = Instance.new("Folder")
	cars.Name = "Cars"
	cars.Parent = lobby

	return {
		folder = lobby,
		carsFolder = cars,
		gate = buildGate(lobby),
	}
end

return LobbyBuilder
