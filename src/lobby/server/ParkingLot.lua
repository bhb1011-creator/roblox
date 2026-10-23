-- Der Parkplatz: dicke Asphaltplatte mit Flecken, Rissen und Pfützen, Parkbuchten,
-- Bordsteine, Holzzaun, weiße Flutlichtmasten, Laternen, Schilder, Mülleimer, Bänke
-- und unsichtbare Grenzen.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(script.Parent.Layout)
local Parts = require(script.Parent.Parts)

local ParkingLot = {}

local LOT = Layout.LOT
local Y = Layout.GROUND_Y
local COLORS = {
	asphalt = Color3.fromRGB(44, 44, 48),
	line = Color3.fromRGB(215, 210, 195),
	curb = Color3.fromRGB(105, 105, 108),
	wood = Color3.fromRGB(92, 66, 44),
	darkWood = Color3.fromRGB(60, 44, 32),
	metal = Color3.fromRGB(70, 72, 76),
	darkMetal = Color3.fromRGB(38, 38, 42),
	lamp = Color3.fromRGB(255, 200, 135),
	flood = Color3.fromRGB(255, 252, 242),
}

local function buildSurface(lot, rng)
	local depth = LOT.maxZ - LOT.minZ
	local midZ = (LOT.maxZ + LOT.minZ) / 2
	-- Dicke Platte bis 4 Studs unter den Boden: kein Gelände kann hindurchragen
	Parts.new("Part", {
		Name = "Asphalt",
		Size = Vector3.new(LOT.halfWidth * 2, 4.2, depth),
		CFrame = CFrame.new(0, Y - 2.1, midZ),
		Color = COLORS.asphalt,
		Material = Enum.Material.Asphalt,
		Parent = lot,
	})

	local function randomSpot(margin)
		return rng:NextNumber(-LOT.halfWidth + margin, LOT.halfWidth - margin), rng:NextNumber(LOT.minZ + margin, LOT.maxZ - margin)
	end

	for _ = 1, 24 do
		local x, z = randomSpot(8)
		Parts.new("Part", {
			Name = "Patch",
			Size = Vector3.new(rng:NextNumber(6, 18), 0.02, rng:NextNumber(4, 14)),
			CFrame = CFrame.new(x, Y + 0.005, z) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0),
			Color = COLORS.asphalt:Lerp(Color3.fromRGB(72, 70, 68), rng:NextNumber(0.1, 0.4)),
			Material = Enum.Material.Asphalt,
			CanCollide = false,
			Parent = lot,
		})
	end

	for _ = 1, 70 do
		local x, z = randomSpot(3)
		Parts.new("Part", {
			Name = "Crack",
			Size = Vector3.new(0.15, 0.02, rng:NextNumber(2, 7)),
			CFrame = CFrame.new(x, Y + 0.012, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			Color = Color3.fromRGB(22, 22, 24),
			CanCollide = false,
			Parent = lot,
		})
	end

	-- Pfützen spiegeln das Licht
	for _ = 1, 14 do
		local x, z = randomSpot(6)
		Parts.column({
			Name = "Puddle",
			Color = Color3.fromRGB(34, 38, 46),
			Reflectance = 0.35,
			CanCollide = false,
			Parent = lot,
		}, 0.02, rng:NextNumber(3, 9), CFrame.new(x, Y + 0.008, z))
	end
end

local function buildCurbs(lot)
	local depth = LOT.maxZ - LOT.minZ
	local midZ = (LOT.maxZ + LOT.minZ) / 2
	local side = LOT.halfWidth - LOT.exitHalfWidth
	local curbs = {
		{ Vector3.new(LOT.halfWidth * 2 + 1, 0.6, 1), Vector3.new(0, Y + 0.3, LOT.maxZ) },
		{ Vector3.new(1, 0.6, depth), Vector3.new(-LOT.halfWidth, Y + 0.3, midZ) },
		{ Vector3.new(1, 0.6, depth), Vector3.new(LOT.halfWidth, Y + 0.3, midZ) },
		{ Vector3.new(side, 0.6, 1), Vector3.new(-(LOT.exitHalfWidth + side / 2), Y + 0.3, LOT.minZ) },
		{ Vector3.new(side, 0.6, 1), Vector3.new(LOT.exitHalfWidth + side / 2, Y + 0.3, LOT.minZ) },
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
end

-- Alter Holzzaun mit Pfosten und zwei Latten; ein paar Latten fehlen
local function buildFence(lot, rng)
	local fence = Instance.new("Folder")
	fence.Name = "Fence"
	fence.Parent = lot

	local function line(from, to)
		local count = math.max(1, math.floor((to - from).Magnitude / 6 + 0.5))
		local previous
		for i = 0, count do
			local point = from:Lerp(to, i / count)
			Parts.new("Part", {
				Name = "FencePost",
				Size = Vector3.new(0.6, 4.4, 0.6),
				CFrame = CFrame.new(point + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, 0, rng:NextNumber(-0.04, 0.04)),
				Color = COLORS.darkWood,
				Material = Enum.Material.Wood,
				Parent = fence,
			})
			if previous then
				for _, height in { 2, 3.6 } do
					if rng:NextNumber() > 0.1 then
						Parts.beam({
							Name = "FenceRail",
							Color = COLORS.wood,
							Material = Enum.Material.WoodPlanks,
							Parent = fence,
						}, previous + Vector3.new(0, height, 0), point + Vector3.new(0, height, 0), 0.35)
					end
				end
			end
			previous = point
		end
	end

	local x, minZ, maxZ = LOT.halfWidth + 0.5, LOT.minZ - 0.5, LOT.maxZ + 0.5
	line(Vector3.new(-x, Y, maxZ), Vector3.new(x, Y, maxZ))
	line(Vector3.new(-x, Y, minZ), Vector3.new(-x, Y, maxZ))
	line(Vector3.new(x, Y, minZ), Vector3.new(x, Y, maxZ))
	line(Vector3.new(-x, Y, minZ), Vector3.new(-LOT.exitHalfWidth - 1, Y, minZ))
	line(Vector3.new(LOT.exitHalfWidth + 1, Y, minZ), Vector3.new(x, Y, minZ))
end

local function buildBays(lot)
	for _, car in Config.CARS do
		local x, z = car.position.X, car.position.Z
		for _, lineX in { x - 11, x + 11 } do
			Parts.new("Part", {
				Name = "ParkingLine",
				Size = Vector3.new(0.35, 0.02, 18),
				CFrame = CFrame.new(lineX, Y + 0.01, z),
				Color = COLORS.line,
				CanCollide = false,
				Parent = lot,
			})
		end

		Parts.new("Part", {
			Name = "WheelStop",
			Size = Vector3.new(5.5, 0.5, 0.8),
			CFrame = CFrame.new(x, Y + 0.25, z - 9.5),
			Color = Color3.fromRGB(150, 148, 140),
			Material = Enum.Material.Concrete,
			Parent = lot,
		})

		Parts.column({
			Name = "OilStain",
			Color = Color3.fromRGB(22, 22, 24),
			Transparency = 0.2,
			CanCollide = false,
			Parent = lot,
		}, 0.02, 3, CFrame.new(x + 0.6, Y + 0.009, z - 1))

		local marking = Parts.new("Part", {
			Name = "BayMarking",
			Size = Vector3.new(14, 0.02, 3.5),
			CFrame = CFrame.new(x, Y + 0.01, z + 12.5) * CFrame.Angles(0, math.pi, 0),
			Transparency = 1,
			CanCollide = false,
			Parent = lot,
		})
		Parts.text(Parts.surfaceGui(marking, Enum.NormalId.Top), {
			Text = Config.MODES[car.mode].title,
			TextColor3 = COLORS.line,
			TextTransparency = 0.1,
		})
	end
end

-- Hoher Mast mit zwei weißen Flutlicht-Strahlern, die auf `target` zeigen
local function buildFloodlight(parent, position, target)
	local mast = Instance.new("Model")
	mast.Name = "FloodlightMast"
	local base = CFrame.new(position)
	local height = 22

	Parts.new("Part", {
		Name = "Foot",
		Size = Vector3.new(2.2, 1.2, 2.2),
		CFrame = base * CFrame.new(0, 0.6, 0),
		Color = Color3.fromRGB(125, 122, 116),
		Material = Enum.Material.Concrete,
		Parent = mast,
	})
	Parts.column({ Name = "Pole", Color = COLORS.metal, Material = Enum.Material.Metal, Parent = mast }, height, 0.8, base)
	Parts.new("Part", {
		Name = "JunctionBox",
		Size = Vector3.new(1, 1.4, 0.6),
		CFrame = base * CFrame.new(0, 3.5, 0.6),
		Color = Color3.fromRGB(150, 150, 150),
		Material = Enum.Material.Metal,
		Parent = mast,
	})

	local facing = CFrame.lookAt(position, Vector3.new(target.X, position.Y, target.Z))
	Parts.new("Part", {
		Name = "Crossbar",
		Size = Vector3.new(6.4, 0.4, 0.4),
		CFrame = facing * CFrame.new(0, height - 0.4, -0.6),
		Color = COLORS.metal,
		Material = Enum.Material.Metal,
		Parent = mast,
	})
	for _, x in { -2.4, 2.4 } do
		local headPosition = (facing * CFrame.new(x, height - 1.2, -1.3)).Position
		local head = CFrame.lookAt(headPosition, target + (facing.RightVector * x * 3))
		Parts.new("Part", {
			Name = "Housing",
			Size = Vector3.new(2.4, 1.6, 1),
			CFrame = head,
			Color = COLORS.darkMetal,
			Material = Enum.Material.Metal,
			Parent = mast,
		})
		local lens = Parts.new("Part", {
			Name = "Lens",
			Size = Vector3.new(2.1, 1.3, 0.1),
			CFrame = head * CFrame.new(0, 0, -0.55),
			Color = COLORS.flood,
			Material = Enum.Material.Neon,
			Parent = mast,
		})
		Parts.light("SpotLight", lens, {
			Face = Enum.NormalId.Front,
			Range = 75,
			Angle = 75,
			Brightness = 2.2,
			Color = COLORS.flood,
			Shadows = true,
		})
	end

	mast.Parent = parent
end

-- Klassische Laterne mit warmem Licht; der Kopf zeigt zur Mitte des Parkplatzes
local function buildLamp(parent, position)
	local lamp = Instance.new("Model")
	lamp.Name = "StreetLamp"
	local base = CFrame.lookAt(position, Vector3.new(0, position.Y, 5))
	local height = 18

	Parts.new("Part", {
		Name = "Foot",
		Size = Vector3.new(1.6, 1.2, 1.6),
		CFrame = base * CFrame.new(0, 0.6, 0),
		Color = Color3.fromRGB(120, 118, 112),
		Material = Enum.Material.Concrete,
		Parent = lamp,
	})
	Parts.column({ Name = "Pole", Color = COLORS.darkMetal, Material = Enum.Material.Metal, Parent = lamp }, height, 0.6, base)
	Parts.new("Part", {
		Name = "Arm",
		Size = Vector3.new(0.4, 0.4, 4),
		CFrame = base * CFrame.new(0, height - 0.2, -1.8),
		Color = COLORS.darkMetal,
		Material = Enum.Material.Metal,
		Parent = lamp,
	})
	Parts.new("Part", {
		Name = "Housing",
		Size = Vector3.new(1.8, 0.6, 3),
		CFrame = base * CFrame.new(0, height - 0.3, -3.8),
		Color = COLORS.darkMetal,
		Material = Enum.Material.Metal,
		Parent = lamp,
	})
	local lens = Parts.new("Part", {
		Name = "Lens",
		Size = Vector3.new(1.5, 0.12, 2.5),
		CFrame = base * CFrame.new(0, height - 0.65, -3.8),
		Color = COLORS.lamp,
		Material = Enum.Material.Neon,
		Parent = lamp,
	})
	Parts.light("SpotLight", lens, {
		Face = Enum.NormalId.Bottom,
		Range = 45,
		Angle = 110,
		Brightness = 1.8,
		Color = COLORS.lamp,
		Shadows = true,
	})
	CollectionService:AddTag(lens, "FlickerLamp")

	lamp.Parent = parent
end

local function buildParkingSign(parent)
	local base = CFrame.new(LOT.exitHalfWidth + 2.5, Y, LOT.minZ + 1.2)
	Parts.column(
		{ Name = "SignPost", Color = Color3.fromRGB(120, 120, 125), Material = Enum.Material.Metal, Parent = parent },
		9,
		0.3,
		base
	)
	local board = Parts.new("Part", {
		Name = "ParkingSign",
		Size = Vector3.new(3.2, 3.2, 0.15),
		CFrame = base * CFrame.new(0, 8, 0.25) * CFrame.Angles(0, math.pi, 0),
		Color = Color3.fromRGB(30, 70, 150),
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	Parts.text(Parts.surfaceGui(board, Enum.NormalId.Front), { Text = "P", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1) })
	local plate = Parts.new("Part", {
		Name = "ParkingPlate",
		Size = Vector3.new(3.2, 1, 0.15),
		CFrame = base * CFrame.new(0, 5.8, 0.25) * CFrame.Angles(0, math.pi, 0),
		Color = Color3.fromRGB(230, 230, 225),
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	Parts.text(Parts.surfaceGui(plate, Enum.NormalId.Front), {
		Text = "Waldparkplatz",
		TextColor3 = Color3.fromRGB(30, 30, 30),
		Size = UDim2.fromScale(0.9, 0.8),
		Position = UDim2.fromScale(0.05, 0.1),
	})
end

local function buildTrashBin(parent, position)
	local base = CFrame.new(position)
	Parts.column({ Name = "TrashBin", Color = Color3.fromRGB(40, 70, 45), Material = Enum.Material.Metal, Parent = parent }, 3.2, 2, base)
	Parts.column({ Name = "TrashLid", Color = Color3.fromRGB(30, 50, 34), Material = Enum.Material.Metal, Parent = parent }, 0.3, 2.3, base * CFrame.new(0, 3.2, 0))
end

-- Parkbank mit Sitzflächen, auf die man sich setzen kann. Blickrichtung = LookVector.
local function buildBench(parent, cframe)
	local bench = Instance.new("Model")
	bench.Name = "Bench"
	local block = Parts.builder(bench, cframe)
	for i = -1, 1 do
		Parts.new("Seat", {
			Name = "Seat",
			Size = Vector3.new(2, 0.3, 1.6),
			CFrame = cframe * CFrame.new(i * 2, 1.85, 0),
			Color = COLORS.wood,
			Material = Enum.Material.WoodPlanks,
			Parent = bench,
		})
	end
	block("BenchBack", Vector3.new(6, 1.4, 0.25), CFrame.new(0, 2.9, 0.75) * CFrame.Angles(math.rad(-10), 0, 0), COLORS.wood, Enum.Material.WoodPlanks)
	for _, x in { -2.6, 2.6 } do
		block("BenchLeg", Vector3.new(0.3, 1.7, 1.4), CFrame.new(x, 0.85, 0), COLORS.darkMetal, Enum.Material.Metal)
	end
	bench.Parent = parent
end

-- Unsichtbare Wände: Spieler können den Parkplatz nicht verlassen.
-- Die Autos fahren trotzdem durch, weil sie per Code bewegt werden.
local function buildBounds(parent)
	local width = LOT.halfWidth * 2 + 6
	local northZ, southZ = Layout.GATE_Z - 3, LOT.maxZ + 2
	local depth = southZ - northZ
	local midZ = (southZ + northZ) / 2
	local walls = {
		{ Vector3.new(width, 40, 1), Vector3.new(0, 20, northZ) },
		{ Vector3.new(width, 40, 1), Vector3.new(0, 20, southZ) },
		{ Vector3.new(1, 40, depth), Vector3.new(-LOT.halfWidth - 2, 20, midZ) },
		{ Vector3.new(1, 40, depth), Vector3.new(LOT.halfWidth + 2, 20, midZ) },
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

function ParkingLot.build(parent)
	local lot = Instance.new("Folder")
	lot.Name = "ParkingLot"
	lot.Parent = parent

	local rng = Random.new(2024)
	buildSurface(lot, rng)
	buildCurbs(lot)
	buildFence(lot, rng)
	buildBays(lot)
	buildBounds(lot)
	buildParkingSign(lot)

	local lights = Instance.new("Folder")
	lights.Name = "Lights"
	lights.Parent = lot
	for _, floodlight in Layout.FLOODLIGHTS do
		buildFloodlight(lights, floodlight[1], floodlight[2])
	end
	for _, position in Layout.LAMPS do
		buildLamp(lights, position)
	end

	local furniture = Instance.new("Folder")
	furniture.Name = "Furniture"
	furniture.Parent = lot
	for _, position in {
		Vector3.new(-22, Y, 46),
		Vector3.new(22, Y, 46),
		Vector3.new(-77, Y, 30),
		Vector3.new(77, Y, 12),
	} do
		buildTrashBin(furniture, position)
	end
	buildBench(furniture, CFrame.lookAt(Vector3.new(-77, Y, 20), Vector3.new(0, Y, 20)))
	buildBench(furniture, CFrame.lookAt(Vector3.new(77, Y, 0), Vector3.new(0, Y, 0)))
	buildBench(furniture, CFrame.lookAt(Vector3.new(77, Y, 50), Vector3.new(0, Y, 50)))
end

return ParkingLot
