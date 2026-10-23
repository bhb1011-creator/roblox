-- Die Waldstraße: verlässt den Parkplatz nach Norden, macht eine Kurve und
-- verschwindet zwischen den Bäumen im Dunkeln. Die Autos fahren genau diesen Weg.
local TweenService = game:GetService("TweenService")

local Layout = require(script.Parent.Layout)
local Parts = require(script.Parent.Parts)

local Road = {}

local WIDTH = 18
local SAMPLE_SPACING = 8
local CONTROL_POINTS = {
	Vector3.new(0, 0, Layout.LOT.minZ),
	Vector3.new(0, 0, -140),
	Vector3.new(-22, 0, -210),
	Vector3.new(-80, 0, -265),
	Vector3.new(-165, 0, -298),
	Vector3.new(-270, 0, -314),
	Vector3.new(-370, 0, -318),
}
Road.WIDTH = WIDTH

local COLORS = {
	asphalt = Color3.fromRGB(36, 36, 40),
	line = Color3.fromRGB(205, 200, 185),
	post = Color3.fromRGB(215, 215, 210),
	reflector = Color3.fromRGB(140, 60, 15),
}

local function catmullRom(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5
		* ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

-- Weiche Kurve durch die Kontrollpunkte, ein Punkt etwa alle 8 Studs
local function samplePath()
	local points = {}
	local count = #CONTROL_POINTS
	for i = 1, count - 1 do
		local p0 = CONTROL_POINTS[math.max(i - 1, 1)]
		local p1 = CONTROL_POINTS[i]
		local p2 = CONTROL_POINTS[i + 1]
		local p3 = CONTROL_POINTS[math.min(i + 2, count)]
		local steps = math.max(1, math.ceil((p2 - p1).Magnitude / SAMPLE_SPACING))
		for step = 0, steps - 1 do
			table.insert(points, catmullRom(p0, p1, p2, p3, step / steps))
		end
	end
	table.insert(points, CONTROL_POINTS[count])
	return points
end

Road.PATH = samplePath()

-- Ein Abschnitt pro Punktepaar: Mitte auf Höhe 0, Blickrichtung entlang der Straße
Road.SEGMENTS = {}
for i = 1, #Road.PATH - 1 do
	local from, to = Road.PATH[i], Road.PATH[i + 1]
	table.insert(Road.SEGMENTS, {
		cframe = CFrame.lookAt((from + to) / 2, to),
		length = (to - from).Magnitude,
		from = from,
		to = to,
	})
end

-- Kürzester Abstand (waagerecht) von einem Punkt zur Straßenmitte
function Road.distanceTo(x, z)
	local best = math.huge
	for _, segment in Road.SEGMENTS do
		local ax, az = segment.from.X, segment.from.Z
		local dx, dz = segment.to.X - ax, segment.to.Z - az
		local lengthSquared = dx * dx + dz * dz
		local t = math.clamp(((x - ax) * dx + (z - az) * dz) / lengthSquared, 0, 1)
		local px, pz = ax + dx * t - x, az + dz * t - z
		best = math.min(best, math.sqrt(px * px + pz * pz))
	end
	return best
end

local function buildSign(parent, cframe, lines, background, textColor)
	local sign = Instance.new("Model")
	sign.Name = "RoadSign"
	Parts.column(
		{ Name = "Post", Color = Color3.fromRGB(120, 120, 125), Material = Enum.Material.Metal, Parent = sign },
		7,
		0.3,
		cframe
	)
	local board = Parts.new("Part", {
		Name = "Board",
		Size = Vector3.new(4.2, 3, 0.15),
		CFrame = cframe * CFrame.new(0, 6.5, -0.25),
		Color = background,
		Material = Enum.Material.Metal,
		Parent = sign,
	})
	local gui = Parts.surfaceGui(board, Enum.NormalId.Front)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = background
	frame.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(170, 30, 30)
	stroke.Thickness = 8
	stroke.Parent = frame
	Parts.text(frame, {
		Text = lines,
		TextColor3 = textColor,
		Size = UDim2.fromScale(0.86, 0.8),
		Position = UDim2.fromScale(0.07, 0.1),
	})
	sign.Parent = parent
end

function Road.build(parent)
	local road = Instance.new("Folder")
	road.Name = "Road"
	road.Parent = parent

	for index, segment in Road.SEGMENTS do
		local cf = segment.cframe
		local length = segment.length + 1.2 -- leichte Überlappung, damit in Kurven keine Lücken entstehen
		-- Dicke Platte (Oberkante 0.2), damit kein Gelände durchschaut
		Parts.new("Part", {
			Name = "RoadSurface",
			Size = Vector3.new(WIDTH, 4.2, length),
			CFrame = cf * CFrame.new(0, -1.9, 0),
			Color = COLORS.asphalt,
			Material = Enum.Material.Asphalt,
			Parent = road,
		})
		for _, side in { -1, 1 } do
			Parts.new("Part", {
				Name = "EdgeLine",
				Size = Vector3.new(0.35, 0.02, length),
				CFrame = cf * CFrame.new(side * (WIDTH / 2 - 0.8), 0.21, 0),
				Color = COLORS.line,
				CanCollide = false,
				Parent = road,
			})
		end
		if index % 2 == 0 then
			Parts.new("Part", {
				Name = "CenterLine",
				Size = Vector3.new(0.3, 0.02, 5),
				CFrame = cf * CFrame.new(0, 0.21, 0),
				Color = COLORS.line,
				CanCollide = false,
				Parent = road,
			})
		end

		-- Leitpfosten am Straßenrand mit schwach leuchtendem Reflektor
		if index % 3 == 0 then
			for _, side in { -1, 1 } do
				local base = cf * CFrame.new(side * (WIDTH / 2 + 2), 0, 0)
				Parts.new("Part", {
					Name = "MarkerPost",
					Size = Vector3.new(0.5, 3.2, 0.5),
					CFrame = base * CFrame.new(0, 1.6, 0),
					Color = COLORS.post,
					Parent = road,
				})
				Parts.new("Part", {
					Name = "Reflector",
					Size = Vector3.new(0.52, 0.5, 0.52),
					CFrame = base * CFrame.new(0, 2.6, 0),
					Color = COLORS.reflector,
					Material = Enum.Material.Neon,
					Parent = road,
				})
			end
		end
	end

	-- Schilder an der Ausfahrt, Vorderseite zum Parkplatz
	local function roadsideCFrame(pathIndex, side)
		local point = Road.PATH[pathIndex]
		local direction = (Road.PATH[pathIndex + 1] - point).Unit
		local right = direction:Cross(Vector3.yAxis)
		local position = point + right * side * (WIDTH / 2 + 3.5)
		return CFrame.lookAt(position, position - direction)
	end
	buildSign(road, roadsideCFrame(3, 1), "⚠\nWILDWECHSEL", Color3.fromRGB(235, 235, 230), Color3.fromRGB(30, 30, 30))
	buildSign(
		road,
		roadsideCFrame(7, -1),
		"DURCHFAHRT AUF\nEIGENE GEFAHR",
		Color3.fromRGB(235, 235, 230),
		Color3.fromRGB(30, 30, 30)
	)
end

-- Schranke an der Ausfahrt. Mehrere Autos können sie gleichzeitig offen halten.
function Road.buildGate(parent)
	local gateModel = Instance.new("Model")
	gateModel.Name = "Gate"
	local z = Layout.GATE_Z

	Parts.new("Part", {
		Name = "Housing",
		Size = Vector3.new(1.4, 4, 1.4),
		CFrame = CFrame.new(-11, 2.2, z),
		Color = Color3.fromRGB(200, 170, 40),
		Material = Enum.Material.Metal,
		Parent = gateModel,
	})
	Parts.new("Part", {
		Name = "Rest",
		Size = Vector3.new(0.6, 3.2, 0.6),
		CFrame = CFrame.new(10.5, 1.8, z),
		Color = Color3.fromRGB(70, 72, 76),
		Material = Enum.Material.Metal,
		Parent = gateModel,
	})

	local pivot = CFrame.new(-10.5, 3.8, z)
	local closed = pivot * CFrame.new(10, 0, 0)
	local open = pivot * CFrame.Angles(0, 0, math.rad(80)) * CFrame.new(10, 0, 0)
	local arm = Parts.new("Part", {
		Name = "Arm",
		Size = Vector3.new(20, 0.5, 0.5),
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

return Road
