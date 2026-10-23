-- Die Mitte des Parkplatzes: großer Grillplatz mit Feuerstelle und Schwenkgrill,
-- Bänke im Kreis (man kann sich setzen), Biertischgarnituren, gemauerter Grill,
-- Zelte, Lichterketten, Pinnwand mit Vermisst-Zetteln und Infotafel.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(script.Parent.Layout)
local Parts = require(script.Parent.Parts)

local Camp = {}

local Y = Layout.GROUND_Y
local FIRE = Layout.CAMPFIRE
local COLORS = {
	wood = Color3.fromRGB(110, 78, 50),
	darkWood = Color3.fromRGB(64, 46, 32),
	board = Color3.fromRGB(28, 26, 24),
	stone = Color3.fromRGB(95, 92, 88),
	metal = Color3.fromRGB(45, 45, 48),
	warmLight = Color3.fromRGB(255, 190, 120),
}

local function facing(x, z, target)
	local position = Vector3.new(x, Y, z)
	return CFrame.lookAt(position, Vector3.new(target.X, Y, target.Z))
end

-- Feuer mit Flammen, Glut, Funkenflug und Rauch
local function addFire(parent, cframe, size)
	local flame = Parts.new("Part", {
		Name = "Flame",
		Size = Vector3.new(1, 1, 1),
		CFrame = cframe,
		Transparency = 1,
		CanCollide = false,
		Parent = parent,
	})
	local fire = Instance.new("Fire")
	fire.Size = size
	fire.Heat = size * 1.6
	fire.Color = Color3.fromRGB(255, 120, 40)
	fire.SecondaryColor = Color3.fromRGB(255, 200, 80)
	fire.Parent = flame

	local embers = Instance.new("ParticleEmitter")
	embers.Name = "Embers"
	embers.Rate = size * 2.5
	embers.Lifetime = NumberRange.new(1.5, 3)
	embers.Speed = NumberRange.new(3, 7)
	embers.SpreadAngle = Vector2.new(25, 25)
	embers.Acceleration = Vector3.new(0, 2, 0)
	embers.Drag = 1
	embers.Size = NumberSequence.new(0.18, 0)
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 80, 20))
	embers.LightEmission = 1
	embers.Parent = flame

	local smoke = Instance.new("Smoke")
	smoke.Opacity = 0.05
	smoke.RiseVelocity = 6
	smoke.Size = size * 0.8
	smoke.Color = Color3.fromRGB(90, 90, 90)
	smoke.Parent = flame
	return flame
end

local function buildFirePit(parent)
	local pit = Instance.new("Model")
	pit.Name = "Feuerstelle"
	local base = CFrame.new(FIRE)
	local radius = 4.4

	-- Zweilagige Steinmauer
	for layer = 0, 1 do
		local count = 18
		for i = 0, count - 1 do
			local angle = (i + layer * 0.5) / count * math.pi * 2
			Parts.new("Part", {
				Name = "Stone",
				Size = Vector3.new(1.7, 0.75, 1.3),
				CFrame = base * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.38 + layer * 0.72, -radius) * CFrame.Angles(0, 0, (i % 3 - 1) * 0.05),
				Color = COLORS.stone:Lerp(Color3.fromRGB(60, 58, 56), (i * 7 + layer * 3) % 5 / 8),
				Material = Enum.Material.Slate,
				Parent = pit,
			})
		end
	end
	Parts.column({ Name = "Ashes", Color = Color3.fromRGB(32, 30, 28), Material = Enum.Material.Sand, Parent = pit }, 0.2, radius * 2 - 1, base)

	-- Glühende Kohlen
	local rng = Random.new(8)
	for _ = 1, 14 do
		local angle, distance = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, 2.2)
		Parts.new("Part", {
			Name = "Ember",
			Size = Vector3.new(rng:NextNumber(0.4, 0.8), 0.3, rng:NextNumber(0.4, 0.8)),
			CFrame = base * CFrame.new(math.cos(angle) * distance, 0.3, math.sin(angle) * distance) * CFrame.Angles(0, angle, 0),
			Color = rng:NextNumber() < 0.5 and Color3.fromRGB(255, 90, 20) or Color3.fromRGB(200, 40, 10),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = pit,
		})
	end

	-- Holzscheite wie ein Zelt aufgestellt
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2
		Parts.new("Part", {
			Name = "Log",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(4, 0.75, 0.75),
			CFrame = base * CFrame.Angles(0, angle, 0) * CFrame.new(0, 1.3, -0.9) * CFrame.Angles(math.rad(-55), 0, 0) * CFrame.Angles(0, math.pi / 2, 0),
			Color = Color3.fromRGB(45, 32, 24),
			Material = Enum.Material.Wood,
			CanCollide = false,
			Parent = pit,
		})
	end

	local flame = addFire(pit, base * CFrame.new(0, 1.5, 0), 8)
	Parts.light("PointLight", flame, { Range = 40, Brightness = 2.6, Color = Color3.fromRGB(255, 140, 60), Shadows = true })
	CollectionService:AddTag(flame, "Campfire")

	-- Schwenkgrill: Dreibein mit Kette und Grillrost über dem Feuer
	local apex = base * CFrame.new(0, 10, 0)
	for i = 0, 2 do
		local angle = i / 3 * math.pi * 2 + 0.3
		local foot = (base * CFrame.new(math.cos(angle) * 5.6, 0, math.sin(angle) * 5.6)).Position
		Parts.beam({ Name = "TripodLeg", Color = COLORS.metal, Material = Enum.Material.Metal, Parent = pit }, foot, apex.Position, 0.35)
	end
	Parts.new("Part", {
		Name = "Chain",
		Size = Vector3.new(0.15, 6.3, 0.15),
		CFrame = base * CFrame.new(0, 6.85, 0),
		Color = COLORS.metal,
		Material = Enum.Material.Metal,
		CanCollide = false,
		Parent = pit,
	})
	Parts.column({ Name = "Grate", Color = COLORS.metal, Material = Enum.Material.DiamondPlate, CanCollide = false, Parent = pit }, 0.15, 4.4, base * CFrame.new(0, 3.6, 0))
	for i = -1, 1 do
		Parts.new("Part", {
			Name = "Sausage",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.6, 0.35, 0.35),
			CFrame = base * CFrame.new(i * 0.9, 3.85, i * 0.4),
			Color = Color3.fromRGB(150, 70, 40),
			CanCollide = false,
			Parent = pit,
		})
	end

	pit.Parent = parent
end

-- Holzbank mit Lehne; die Sitzflächen sind echte Sitze. Blickrichtung = LookVector.
local function buildBench(parent, cframe, length)
	local bench = Instance.new("Model")
	bench.Name = "GrillBank"
	local block = Parts.builder(bench, cframe)
	local seats = math.max(1, math.floor(length / 2.3))
	local seatWidth = length / seats
	for i = 1, seats do
		Parts.new("Seat", {
			Name = "Seat",
			Size = Vector3.new(seatWidth - 0.05, 0.3, 1.8),
			CFrame = cframe * CFrame.new(-length / 2 + seatWidth * (i - 0.5), 1.85, 0),
			Color = COLORS.wood,
			Material = Enum.Material.WoodPlanks,
			Parent = bench,
		})
	end
	block("Backrest", Vector3.new(length, 1.2, 0.25), CFrame.new(0, 3, 0.85) * CFrame.Angles(math.rad(-12), 0, 0), COLORS.wood, Enum.Material.WoodPlanks)
	for _, x in { -length / 2 + 0.4, length / 2 - 0.4 } do
		block("Leg", Vector3.new(0.35, 1.7, 1.5), CFrame.new(x, 0.85, 0), COLORS.darkWood, Enum.Material.Wood)
		block("BackPost", Vector3.new(0.3, 1.6, 0.3), CFrame.new(x, 2.5, 0.8), COLORS.darkWood, Enum.Material.Wood)
	end
	bench.Parent = parent
end

-- Biertischgarnitur: Tisch mit zwei Bänken (echte Sitze) und Laterne
local function buildBeerTable(parent, cframe)
	local set = Instance.new("Model")
	set.Name = "Biertisch"
	local block = Parts.builder(set, cframe)
	local length = 9
	block("TableTop", Vector3.new(length, 0.3, 2.6), CFrame.new(0, 2.75, 0), COLORS.wood, Enum.Material.WoodPlanks)
	for _, x in { -3.6, 3.6 } do
		block("TableLeg", Vector3.new(0.25, 2.6, 2.2), CFrame.new(x, 1.3, 0), COLORS.metal, Enum.Material.Metal)
	end
	for _, side in { -1, 1 } do
		local benchCFrame = cframe * CFrame.new(0, 0, side * 2.4) * CFrame.Angles(0, side == -1 and math.pi or 0, 0)
		for i = -1, 1 do
			Parts.new("Seat", {
				Name = "Seat",
				Size = Vector3.new(2.95, 0.25, 1.1),
				CFrame = benchCFrame * CFrame.new(i * 3, 1.7, 0),
				Color = COLORS.wood,
				Material = Enum.Material.WoodPlanks,
				Parent = set,
			})
		end
		for _, x in { -3.6, 3.6 } do
			block("BenchLeg", Vector3.new(0.25, 1.6, 0.9), CFrame.new(x, 0.8, side * 2.4), COLORS.metal, Enum.Material.Metal)
		end
	end

	block("LanternBase", Vector3.new(0.8, 0.3, 0.8), CFrame.new(2, 3.05, 0), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	local glass = block("LanternGlass", Vector3.new(0.6, 0.9, 0.6), CFrame.new(2, 3.65, 0), COLORS.warmLight, Enum.Material.Neon)
	Parts.light("PointLight", glass, { Range = 14, Brightness = 1.2, Color = COLORS.warmLight, Shadows = true })
	CollectionService:AddTag(glass, "Campfire")
	block("Plate", Vector3.new(1.2, 0.05, 1.2), CFrame.new(-1.5, 2.93, 0.5), Color3.fromRGB(235, 235, 230))
	block("Mug", Vector3.new(0.4, 0.5, 0.4), CFrame.new(-3, 3.15, -0.5), Color3.fromRGB(150, 40, 40))
	block("Ketchup", Vector3.new(0.3, 0.7, 0.3), CFrame.new(0.4, 3.25, -0.3), Color3.fromRGB(190, 30, 30))
	set.Parent = parent
end

-- Gemauerter Grill mit Kamin und glühendem Rost
local function buildBrickGrill(parent, cframe)
	local grill = Instance.new("Model")
	grill.Name = "GemauerterGrill"
	local block = Parts.builder(grill, cframe)
	local brick = Color3.fromRGB(140, 70, 50)
	block("Base", Vector3.new(6, 3, 3.2), CFrame.new(0, 1.5, 0), brick, Enum.Material.Brick)
	block("Back", Vector3.new(6, 2.4, 0.8), CFrame.new(0, 4.2, 1.2), brick, Enum.Material.Brick)
	block("Chimney", Vector3.new(1.6, 6, 1.6), CFrame.new(0, 6, 1.2), brick, Enum.Material.Brick)
	block("ChimneyCap", Vector3.new(2.2, 0.3, 2.2), CFrame.new(0, 9.15, 1.2), COLORS.stone, Enum.Material.Concrete)
	for _, x in { -2.6, 2.6 } do
		block("Side", Vector3.new(0.8, 1.6, 2.4), CFrame.new(x, 3.8, -0.2), brick, Enum.Material.Brick)
	end
	local coals = block("Coals", Vector3.new(4.2, 0.3, 2), CFrame.new(0, 3.15, -0.3), Color3.fromRGB(230, 70, 15), Enum.Material.Neon)
	Parts.light("PointLight", coals, { Range = 12, Brightness = 1.2, Color = Color3.fromRGB(255, 120, 50) })
	CollectionService:AddTag(coals, "Campfire")
	block("Grate", Vector3.new(4.4, 0.1, 2.2), CFrame.new(0, 3.7, -0.3), COLORS.metal, Enum.Material.DiamondPlate, { CanCollide = false })
	for i = -1, 1 do
		block("Steak", Vector3.new(1, 0.2, 0.7), CFrame.new(i * 1.3, 3.85, -0.3) * CFrame.Angles(0, i * 0.3, 0), Color3.fromRGB(120, 55, 35))
	end
	grill.Parent = parent
end

-- Zelt aus zwei Keilen; der Eingang zeigt in Blickrichtung von `cframe`
local function buildTent(parent, cframe, color)
	local tent = Instance.new("Model")
	tent.Name = "Tent"
	local length, width, height = 9, 8, 5.5

	Parts.new("Part", {
		Name = "Groundsheet",
		Size = Vector3.new(width + 1, 0.1, length + 1),
		CFrame = cframe * CFrame.new(0, 0.05, 0),
		Color = Color3.fromRGB(40, 45, 50),
		Material = Enum.Material.Fabric,
		Parent = tent,
	})
	for _, side in { -1, 1 } do
		Parts.new("WedgePart", {
			Name = "Canvas",
			Size = Vector3.new(length, height, width / 2),
			CFrame = cframe * CFrame.new(side * width / 4, height / 2, 0) * CFrame.Angles(0, -side * math.pi / 2, 0),
			Color = color,
			Material = Enum.Material.Fabric,
			Parent = tent,
		})
		Parts.new("WedgePart", {
			Name = "Entrance",
			Size = Vector3.new(0.1, height * 0.75, width * 0.3),
			CFrame = cframe
				* CFrame.new(side * width * 0.15, height * 0.375, -length / 2 - 0.06)
				* CFrame.Angles(0, -side * math.pi / 2, 0),
			Color = Color3.fromRGB(20, 18, 16),
			Material = Enum.Material.Fabric,
			CanCollide = false,
			Parent = tent,
		})
	end
	tent.Parent = parent
end

local function buildFirewood(parent, cframe)
	for row = 0, 3 do
		local logs = 5 - row
		for i = 1, logs do
			Parts.new("Part", {
				Name = "Firewood",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(3.5, 0.8, 0.8),
				CFrame = cframe * CFrame.new(0, 0.4 + row * 0.7, (i - (logs + 1) / 2) * 0.8),
				Color = COLORS.wood:Lerp(Color3.fromRGB(130, 95, 62), (i % 2) * 0.3),
				Material = Enum.Material.Wood,
				Parent = parent,
			})
		end
	end
end

local function buildCooler(parent, cframe)
	local block = Parts.builder(parent, cframe)
	block("Cooler", Vector3.new(2.4, 1.5, 1.6), CFrame.new(0, 0.75, 0), Color3.fromRGB(40, 90, 150))
	block("CoolerLid", Vector3.new(2.5, 0.25, 1.7), CFrame.new(0, 1.6, 0), Color3.fromRGB(230, 230, 225))
end

-- Pinnwand mit Zetteln. Die Geschichten sind ausgedacht.
local function buildNoticeBoard(parent, cframe)
	local board = Instance.new("Model")
	board.Name = "NoticeBoard"
	local block = Parts.builder(board, cframe)
	for _, x in { -4.6, 4.6 } do
		block("Post", Vector3.new(0.5, 8.5, 0.5), CFrame.new(x, 4.25, 0.3), COLORS.darkWood, Enum.Material.Wood)
	end
	block("Roof", Vector3.new(10.6, 0.3, 1.8), CFrame.new(0, 8.6, 0.1) * CFrame.Angles(math.rad(-15), 0, 0), COLORS.darkWood, Enum.Material.WoodPlanks)
	local cork = block("Cork", Vector3.new(9.6, 5.4, 0.3), CFrame.new(0, 5.2, 0), Color3.fromRGB(150, 110, 70), Enum.Material.Cardboard)
	local lamp = block("BoardLamp", Vector3.new(1.4, 0.3, 0.5), CFrame.new(0, 8.2, -0.5), COLORS.warmLight, Enum.Material.Neon)
	Parts.light("SpotLight", lamp, { Face = Enum.NormalId.Bottom, Range = 10, Angle = 90, Brightness = 1, Color = COLORS.warmLight })

	local gui = Parts.surfaceGui(cork, Enum.NormalId.Front)
	local notes = {
		{ "VERMISST", "Zuletzt hier am Parkplatz gesehen.", 0.02, 0.04, -4 },
		{ "VERMISST", "Seit 3 Tagen.\nSein Auto steht noch hier.", 0.27, 0.08, 3 },
		{ "WER HAT IHN GESEHEN?", "Ging abends allein in den Wald.", 0.52, 0.03, -2 },
		{ "VERMISST", "Belohnung für Hinweise!", 0.77, 0.07, 5 },
	}
	for _, note in notes do
		local paper = Instance.new("Frame")
		paper.Size = UDim2.fromScale(0.21, 0.6)
		paper.Position = UDim2.fromScale(note[3], note[4])
		paper.Rotation = note[5]
		paper.BackgroundColor3 = Color3.fromRGB(228, 222, 200)
		paper.BorderSizePixel = 0
		paper.Parent = gui
		Parts.text(paper, {
			Text = note[1],
			Font = Enum.Font.SpecialElite,
			TextColor3 = Color3.fromRGB(150, 25, 25),
			Size = UDim2.new(0.9, 0, 0.22, 0),
			Position = UDim2.fromScale(0.05, 0.06),
		})
		Parts.text(paper, {
			Text = note[2],
			Font = Enum.Font.SpecialElite,
			TextColor3 = Color3.fromRGB(40, 35, 30),
			Size = UDim2.new(0.9, 0, 0.6, 0),
			Position = UDim2.fromScale(0.05, 0.34),
		})
	end
	local warning = Instance.new("Frame")
	warning.Size = UDim2.fromScale(0.5, 0.26)
	warning.Position = UDim2.fromScale(0.25, 0.7)
	warning.Rotation = -2
	warning.BackgroundColor3 = Color3.fromRGB(235, 225, 150)
	warning.BorderSizePixel = 0
	warning.Parent = gui
	Parts.text(warning, {
		Text = "ACHTUNG: Nach Einbruch der Dunkelheit\nnicht in den Wald gehen!",
		Font = Enum.Font.SpecialElite,
		TextColor3 = Color3.fromRGB(40, 35, 30),
		Size = UDim2.fromScale(0.9, 0.8),
		Position = UDim2.fromScale(0.05, 0.1),
	})
	board.Parent = parent
end

local function buildInfoBoard(parent)
	local board = Instance.new("Model")
	board.Name = "InfoBoard"
	local block = Parts.builder(board, CFrame.new(Layout.INFO_BOARD))
	local width, height = 13, 7
	for _, x in { -width / 2 + 0.5, width / 2 - 0.5 } do
		block("Post", Vector3.new(0.6, height + 2, 0.6), CFrame.new(x, (height + 2) / 2, 0.3), COLORS.darkWood, Enum.Material.Wood)
	end
	block("Roof", Vector3.new(width + 1, 0.4, 2), CFrame.new(0, height + 2.4, 0.1) * CFrame.Angles(math.rad(-12), 0, 0), COLORS.darkWood, Enum.Material.WoodPlanks)
	local panel = block("Board", Vector3.new(width, height, 0.4), CFrame.new(0, 2 + height / 2, 0), COLORS.board, Enum.Material.Wood)

	local gui = Parts.surfaceGui(panel, Enum.NormalId.Front)
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
	board.Parent = parent
end

-- Lichterkette: durchhängendes Kabel mit Fassungen und Glühbirnen
local function buildStringLights(parent, from, to, sag)
	local count = math.floor((to - from).Magnitude / 2.5)
	local previous
	for i = 0, count do
		local t = i / count
		local point = from:Lerp(to, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
		if previous then
			Parts.beam({ Name = "Wire", Color = Color3.fromRGB(20, 20, 20), CanCollide = false, CastShadow = false, Parent = parent }, previous, point, 0.07)
		end
		if i > 0 and i < count then
			Parts.new("Part", {
				Name = "Socket",
				Size = Vector3.new(0.22, 0.3, 0.22),
				CFrame = CFrame.new(point - Vector3.new(0, 0.18, 0)),
				Color = Color3.fromRGB(25, 25, 25),
				CanCollide = false,
				CastShadow = false,
				Parent = parent,
			})
			local bulb = Parts.new("Part", {
				Name = "Bulb",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.5, 0.5, 0.5),
				CFrame = CFrame.new(point - Vector3.new(0, 0.55, 0)),
				Color = i % 3 == 0 and Color3.fromRGB(255, 215, 150) or Color3.fromRGB(255, 180, 105),
				Material = Enum.Material.Neon,
				CanCollide = false,
				CastShadow = false,
				Parent = parent,
			})
			if i % 6 == 0 then
				Parts.light("PointLight", bulb, { Range = 15, Brightness = 0.8, Color = COLORS.warmLight })
			end
		end
		previous = point
	end
end

function Camp.build(parent)
	local camp = Instance.new("Folder")
	camp.Name = "Camp"
	camp.Parent = parent

	buildFirePit(camp)

	-- Sechs Bänke im Kreis um das Feuer; die Lücke im Norden ist der Zugang
	for i = 0, 5 do
		local angle = math.rad(90 + i * 60)
		if i ~= 3 then
			buildBench(camp, facing(FIRE.X + math.cos(angle) * 11, FIRE.Z + math.sin(angle) * 11, FIRE), 7)
		end
	end

	buildBeerTable(camp, CFrame.new(-22, Y, 24) * CFrame.Angles(0, math.rad(10), 0))
	buildBeerTable(camp, CFrame.new(22, Y, 24) * CFrame.Angles(0, math.rad(-10), 0))
	buildBrickGrill(camp, facing(0, 30, FIRE))
	buildTent(camp, facing(-30, 0, FIRE), Color3.fromRGB(70, 90, 60))
	buildTent(camp, facing(30, -4, FIRE), Color3.fromRGB(150, 85, 40))
	buildFirewood(camp, CFrame.new(-10, Y, 27) * CFrame.Angles(0, math.rad(80), 0))
	buildCooler(camp, CFrame.new(-23, Y, 9) * CFrame.Angles(0, math.rad(30), 0))
	buildNoticeBoard(camp, Layout.NOTICE_BOARD)
	buildInfoBoard(camp)

	-- Lichterketten nur außen rund um den Grillplatz
	local height = 12
	local corners = {
		Vector3.new(-34, Y, -14),
		Vector3.new(34, Y, -14),
		Vector3.new(34, Y, 36),
		Vector3.new(-34, Y, 36),
	}
	for i, corner in corners do
		Parts.column({ Name = "LightPole", Color = COLORS.darkWood, Material = Enum.Material.Wood, Parent = camp }, height, 0.6, CFrame.new(corner))
		local nextCorner = corners[i % #corners + 1]
		buildStringLights(camp, corner + Vector3.new(0, height - 0.2, 0), nextCorner + Vector3.new(0, height - 0.2, 0), 2.5)
	end
end

return Camp
