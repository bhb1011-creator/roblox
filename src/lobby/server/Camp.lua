-- Die Mitte des Parkplatzes: Lagerfeuer mit Bänken, Zelte, Lichterketten,
-- Picknicktisch, Brennholz, Kühlbox, Pinnwand mit Vermisst-Zetteln und Infotafel.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(script.Parent.Layout)
local Parts = require(script.Parent.Parts)

local Camp = {}

local Y = Layout.GROUND_Y
local FIRE = Layout.CAMPFIRE
local COLORS = {
	wood = Color3.fromRGB(92, 66, 44),
	darkWood = Color3.fromRGB(60, 44, 32),
	board = Color3.fromRGB(28, 26, 24),
	warmLight = Color3.fromRGB(255, 190, 120),
}

local function buildCampfire(parent)
	local campfire = Instance.new("Model")
	campfire.Name = "Campfire"
	local base = CFrame.new(FIRE)

	for i = 0, 9 do
		Parts.new("Part", {
			Name = "Stone",
			Size = Vector3.new(1.4, 0.9, 1.1),
			CFrame = base * CFrame.Angles(0, i / 10 * math.pi * 2, 0) * CFrame.new(0, 0.4, -2.7) * CFrame.Angles(0.15, 0, 0),
			Color = Color3.fromRGB(85, 85, 88),
			Material = Enum.Material.Slate,
			Parent = campfire,
		})
	end
	Parts.column({ Name = "Ashes", Color = Color3.fromRGB(30, 28, 26), Material = Enum.Material.Sand, Parent = campfire }, 0.1, 4.6, base)
	for _, angle in { 0, 60, 120 } do
		Parts.new("Part", {
			Name = "Log",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3.6, 0.7, 0.7),
			CFrame = base * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, math.rad(angle), math.rad(14)),
			Color = Color3.fromRGB(40, 30, 24),
			Material = Enum.Material.Wood,
			CanCollide = false,
			Parent = campfire,
		})
	end

	local flame = Parts.new("Part", {
		Name = "Flame",
		Size = Vector3.new(1, 1, 1),
		CFrame = base * CFrame.new(0, 1.3, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = campfire,
	})
	local fire = Instance.new("Fire")
	fire.Size = 5
	fire.Heat = 10
	fire.Parent = flame
	local smoke = Instance.new("Smoke")
	smoke.Opacity = 0.06
	smoke.RiseVelocity = 5
	smoke.Size = 4
	smoke.Color = Color3.fromRGB(90, 90, 90)
	smoke.Parent = flame
	Parts.light("PointLight", flame, { Range = 28, Brightness = 2.2, Color = Color3.fromRGB(255, 140, 60), Shadows = true })
	CollectionService:AddTag(flame, "Campfire")

	-- Baumstamm-Bänke (Norden bleibt frei, dort kommen die Spieler her)
	for _, bench in { { -7, 0, 0 }, { 7, 0, 0 }, { 0, 7, 90 } } do
		Parts.new("Part", {
			Name = "LogBench",
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

-- Zelt aus zwei Keilen; der Eingang zeigt in Blickrichtung von `cframe`
local function buildTent(parent, cframe, color)
	local tent = Instance.new("Model")
	tent.Name = "Tent"
	local length, width, height = 8, 7, 5

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
		-- Dunkler Eingang vorne
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

local function buildPicnicTable(parent, cframe)
	local block = Parts.builder(parent, cframe)
	block("TableTop", Vector3.new(8, 0.3, 3), CFrame.new(0, 2.7, 0), COLORS.wood, Enum.Material.WoodPlanks)
	for _, z in { -2.3, 2.3 } do
		block("TableBench", Vector3.new(8, 0.3, 1.1), CFrame.new(0, 1.6, z), COLORS.wood, Enum.Material.WoodPlanks)
	end
	for _, x in { -3.2, 3.2 } do
		for _, z in { -0.9, 0.9 } do
			block("TableLeg", Vector3.new(0.3, 2.6, 0.3), CFrame.new(x, 1.3, z), COLORS.darkWood, Enum.Material.Wood)
		end
		for _, z in { -2.3, 2.3 } do
			block("BenchLeg", Vector3.new(0.3, 1.5, 0.3), CFrame.new(x, 0.75, z), COLORS.darkWood, Enum.Material.Wood)
		end
	end

	-- Laterne auf dem Tisch
	block("LanternBase", Vector3.new(0.8, 0.3, 0.8), CFrame.new(1.5, 3, 0), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	local glass = block("LanternGlass", Vector3.new(0.6, 0.9, 0.6), CFrame.new(1.5, 3.6, 0), COLORS.warmLight, Enum.Material.Neon)
	Parts.light("PointLight", glass, { Range = 14, Brightness = 1.3, Color = COLORS.warmLight, Shadows = true })
	CollectionService:AddTag(glass, "Campfire")

	-- Ein paar vergessene Sachen
	block("Mug", Vector3.new(0.4, 0.5, 0.4), CFrame.new(-2, 3.1, 0.6), Color3.fromRGB(150, 40, 40))
	block("Map", Vector3.new(1.6, 0.03, 1.2), CFrame.new(-0.5, 2.87, -0.4) * CFrame.Angles(0, 0.3, 0), Color3.fromRGB(200, 190, 160))
end

local function buildFirewood(parent, cframe)
	for row = 0, 2 do
		local logs = 4 - row
		for i = 1, logs do
			Parts.new("Part", {
				Name = "Firewood",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(3.5, 0.8, 0.8),
				CFrame = cframe * CFrame.new(0, 0.4 + row * 0.7, (i - (logs + 1) / 2) * 0.8),
				Color = COLORS.wood:Lerp(Color3.fromRGB(120, 90, 60), (i % 2) * 0.3),
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
	for _, x in { -2.8, 2.8 } do
		block("Post", Vector3.new(0.5, 7, 0.5), CFrame.new(x, 3.5, 0.3), COLORS.darkWood, Enum.Material.Wood)
	end
	block("Roof", Vector3.new(7, 0.3, 1.6), CFrame.new(0, 7.1, 0.1) * CFrame.Angles(math.rad(-15), 0, 0), COLORS.darkWood, Enum.Material.WoodPlanks)
	local cork = block("Cork", Vector3.new(6, 4, 0.3), CFrame.new(0, 4.6, 0), Color3.fromRGB(150, 110, 70), Enum.Material.Cardboard)

	local gui = Parts.surfaceGui(cork, Enum.NormalId.Front)
	local notes = {
		{ "VERMISST", "Wer hat diese Person gesehen?\nZuletzt hier am Parkplatz.", 0.04, 0.06, -4 },
		{ "HUND ENTLAUFEN", "Hört auf „Bruno“.\nBitte melden!", 0.36, 0.1, 3 },
		{ "ACHTUNG", "Nach Einbruch der Dunkelheit\nnicht in den Wald gehen.", 0.68, 0.05, -2 },
		{ "VERMISST", "Seit 3 Tagen.\nAuto noch auf dem Parkplatz.", 0.2, 0.55, 2 },
		{ "", "Sie sind noch da draußen.", 0.58, 0.58, -6 },
	}
	for _, note in notes do
		local paper = Instance.new("Frame")
		paper.Size = UDim2.fromScale(0.29, 0.4)
		paper.Position = UDim2.fromScale(note[3], note[4])
		paper.Rotation = note[5]
		paper.BackgroundColor3 = Color3.fromRGB(225, 218, 195)
		paper.Parent = gui
		Parts.text(paper, {
			Text = note[1],
			Font = Enum.Font.SpecialElite,
			TextColor3 = Color3.fromRGB(150, 25, 25),
			Size = UDim2.new(0.9, 0, 0.28, 0),
			Position = UDim2.fromScale(0.05, 0.04),
		})
		Parts.text(paper, {
			Text = note[2],
			Font = Enum.Font.SpecialElite,
			TextColor3 = Color3.fromRGB(40, 35, 30),
			Size = UDim2.new(0.9, 0, 0.6, 0),
			Position = UDim2.fromScale(0.05, 0.34),
		})
	end
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

-- Lichterkette zwischen zwei Punkten, leicht durchhängend
local function buildStringLights(parent, from, to, sag)
	local count = math.floor((to - from).Magnitude / 3)
	local previous
	for i = 0, count do
		local t = i / count
		local point = from:Lerp(to, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
		if previous then
			Parts.beam({ Name = "Wire", Color = Color3.fromRGB(25, 25, 25), CanCollide = false, Parent = parent }, previous, point, 0.08)
		end
		if i > 0 and i < count then
			local bulb = Parts.new("Part", {
				Name = "Bulb",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.45, 0.45, 0.45),
				CFrame = CFrame.new(point - Vector3.new(0, 0.3, 0)),
				Color = i % 2 == 0 and Color3.fromRGB(255, 205, 130) or Color3.fromRGB(255, 160, 95),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = parent,
			})
			if i % 4 == 0 then
				Parts.light("PointLight", bulb, { Range = 10, Brightness = 0.7, Color = COLORS.warmLight })
			end
		end
		previous = point
	end
end

function Camp.build(parent)
	local camp = Instance.new("Folder")
	camp.Name = "Camp"
	camp.Parent = parent

	buildCampfire(camp)

	local function facingFire(x, z)
		local position = Vector3.new(x, Y, z)
		return CFrame.lookAt(position, Vector3.new(FIRE.X, Y, FIRE.Z))
	end
	buildTent(camp, facingFire(-18, 3), Color3.fromRGB(70, 90, 60))
	buildTent(camp, facingFire(18, 0), Color3.fromRGB(150, 85, 40))
	buildPicnicTable(camp, CFrame.new(15, Y, 17) * CFrame.Angles(0, math.rad(15), 0))
	buildFirewood(camp, CFrame.new(-9, Y, 17) * CFrame.Angles(0, math.rad(80), 0))
	buildCooler(camp, CFrame.new(-12.5, Y, 8) * CFrame.Angles(0, math.rad(30), 0))
	buildNoticeBoard(camp, facingFire(-20, 17))
	buildInfoBoard(camp)

	-- Lichterketten rund um das Lager
	local corners = {
		Vector3.new(-24, Y, -13),
		Vector3.new(24, Y, -13),
		Vector3.new(24, Y, 25),
		Vector3.new(-24, Y, 25),
	}
	for i, corner in corners do
		Parts.column({ Name = "LightPole", Color = COLORS.darkWood, Material = Enum.Material.Wood, Parent = camp }, 10, 0.5, CFrame.new(corner))
		local nextCorner = corners[i % #corners + 1]
		buildStringLights(camp, corner + Vector3.new(0, 9.8, 0), nextCorner + Vector3.new(0, 9.8, 0), 2.2)
	end
end

return Camp
