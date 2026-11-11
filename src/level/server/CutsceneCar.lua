-- Detailliertes Auto für die Zwischensequenz. Wird als Vorlage in ReplicatedStorage
-- gelegt; jeder Spieler bewegt eine eigene Kopie, damit die Fahrt flüssig aussieht.
-- Alle Teile hängen per Schweißnaht an "Root"; Lenkrad und Räder haben eigene
-- Gelenke ("SteeringWeld", "WheelWeld"), die der Client dreht.
-- Vorne ist -Z, der Fahrer sitzt links (-X). Boden unter der Fahrzeugmitte = Ursprung.
-- Der Innenraum ist sehr genau gebaut, weil man die ganze Fahrt darin sitzt.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.Parts)

local CutsceneCar = {}

local PAINT = Color3.fromRGB(38, 52, 72)
local DARK = Color3.fromRGB(20, 20, 23)
local TRIM = Color3.fromRGB(38, 38, 42)
local CHROME = Color3.fromRGB(180, 182, 188)
local GLASS = Color3.fromRGB(70, 85, 100)
local DASH = Color3.fromRGB(32, 31, 33)
local LINER = Color3.fromRGB(175, 170, 162)

-- Innenraum
local LEATHER = Color3.fromRGB(34, 31, 30)
local LEATHER_SOFT = Color3.fromRGB(48, 44, 41)
local CLOTH = Color3.fromRGB(66, 61, 56)
local RIB = Color3.fromRGB(42, 39, 36)
local STITCH = Color3.fromRGB(132, 116, 96)
local WOOD = Color3.fromRGB(74, 46, 28)
local ALU = Color3.fromRGB(150, 152, 157)
local BLACK = Color3.fromRGB(10, 10, 11)
local GLOSS = Color3.fromRGB(16, 16, 18)
local CARPET = Color3.fromRGB(31, 30, 30)
local AMBIENT = Color3.fromRGB(255, 150, 70)
local WARM = Color3.fromRGB(255, 215, 160)

local M = Enum.Material
-- Roblox-Zylinder liegen entlang X: so zeigen sie nach oben bzw. nach vorn/hinten
local ALONG_Y = CFrame.Angles(0, 0, math.rad(90))
local ALONG_Z = CFrame.Angles(0, math.rad(90), 0)

local LENGTH, WIDTH = 15, 6.8
local SILL, GLASS_BOTTOM, GLASS_TOP = 2.9, 3.3, 5.8
local ROOF_FRONT, ROOF_BACK = -0.8, 6.8
local WHEEL_Z = 4.9
local DASH_Z = ROOF_FRONT - 0.9 -- Fläche des Armaturenbretts, die zum Fahrer zeigt

function CutsceneCar.build(parent)
	local model = Instance.new("Model")
	model.Name = "Car"

	local root = Parts.new("Part", {
		Name = "Root",
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(),
		Transparency = 1,
		CanCollide = false,
		Parent = model,
	})
	model.PrimaryPart = root

	-- Erstellt ein Teil und schweißt es an `attachTo` (Standard: Root)
	local function part(name, size, cframe, color, material, extra, attachTo)
		local props = {
			Name = name,
			Size = size,
			CFrame = cframe,
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
			CanCollide = false,
			CanTouch = false,
			Parent = model,
		}
		for key, value in extra or {} do
			props[key] = value
		end
		local className = props.ClassName or "Part"
		props.ClassName = nil
		local created = Parts.new(className, props)
		created.Anchored = false
		-- kleine Teile werfen keinen Schatten (sieht man kaum, kostet aber Leistung)
		if math.max(size.X, size.Y, size.Z) < 1 then
			created.CastShadow = false
		end
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = attachTo or root
		weld.Part1 = created
		weld.Parent = created
		return created
	end
	local function wedge(name, size, cframe, color, material, extra)
		local props = { ClassName = "WedgePart" }
		for key, value in extra or {} do
			props[key] = value
		end
		return part(name, size, cframe, color, material, props)
	end
	local function cyl(name, length, diameter, cframe, color, material, extra, attachTo)
		local props = { Shape = Enum.PartType.Cylinder }
		for key, value in extra or {} do
			props[key] = value
		end
		return part(name, Vector3.new(length, diameter, diameter), cframe, color, material, props, attachTo)
	end
	local function beam(name, from, to, thickness, color, material)
		return part(name, Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material)
	end
	-- Gelenk, das der Client drehen kann
	local function joint(name, cframe, weldName)
		local pivot = part(name, Vector3.new(0.2, 0.2, 0.2), cframe, DARK, nil, { Transparency = 1 })
		pivot:FindFirstChildOfClass("WeldConstraint"):Destroy()
		local weld = Instance.new("Weld")
		weld.Name = weldName
		weld.Part0 = root
		weld.Part1 = pivot
		weld.C0 = cframe
		weld.Parent = pivot
		return pivot, weld
	end

	local paint = { Reflectance = 0.12 }
	local glass = { Transparency = 0.55, Reflectance = 0.08 }
	local front, back = -LENGTH / 2, LENGTH / 2

	------------------------------------------------------------------ Karosserie
	part("Floor", Vector3.new(WIDTH - 0.04, 0.38, LENGTH - 0.04), CFrame.new(0, 0.91, 0), TRIM)
	part("EngineBay", Vector3.new(WIDTH, SILL - 0.7, 4.3), CFrame.new(0, (SILL + 0.7) / 2, front + 2.15), PAINT, nil, paint)
	wedge("Hood", Vector3.new(WIDTH - 0.2, GLASS_BOTTOM - SILL, 4.3), CFrame.new(0, (SILL + GLASS_BOTTOM) / 2, front + 2.15), PAINT, nil, paint)
	part("Trunk", Vector3.new(WIDTH, GLASS_BOTTOM - 0.7, back - 5.9), CFrame.new(0, (GLASS_BOTTOM + 0.7) / 2, (5.9 + back) / 2), PAINT, nil, paint)
	part("Firewall", Vector3.new(WIDTH - 0.88, 2.4, 0.3), CFrame.new(0, 2.1, front + 4.4), DASH)
	for _, side in { -1, 1 } do
		local x = side * (WIDTH / 2 - 0.2)
		part("Door", Vector3.new(0.4, GLASS_BOTTOM - 0.7, back - 1.6 - (front + 4.3)), CFrame.new(x, (GLASS_BOTTOM + 0.7) / 2, (front + 4.3 + back - 1.6) / 2), PAINT, nil, paint)

		-- Scheiben, Säulen und Zierleisten
		part("SideWindow", Vector3.new(0.12, GLASS_TOP - GLASS_BOTTOM, ROOF_BACK - ROOF_FRONT), CFrame.new(x, (GLASS_BOTTOM + GLASS_TOP) / 2, (ROOF_FRONT + ROOF_BACK) / 2), GLASS, Enum.Material.Glass, glass)
		beam("APillar", Vector3.new(x, GLASS_BOTTOM, ROOF_FRONT - 2.4), Vector3.new(x, GLASS_TOP, ROOF_FRONT), 0.32, PAINT)
		beam("APillarTrim", Vector3.new(side * (WIDTH / 2 - 0.45), GLASS_BOTTOM, ROOF_FRONT - 2.3), Vector3.new(side * (WIDTH / 2 - 0.45), GLASS_TOP - 0.05, ROOF_FRONT + 0.05), 0.3, LINER)
		part("BPillar", Vector3.new(0.4, GLASS_TOP - GLASS_BOTTOM - 0.03, 0.5), CFrame.new(side * (WIDTH / 2 - 0.3), (GLASS_BOTTOM + GLASS_TOP) / 2, 2.6), DARK)
		part("DPillar", Vector3.new(0.3, GLASS_TOP - GLASS_BOTTOM + 0.04, 0.6), CFrame.new(x, (GLASS_BOTTOM + GLASS_TOP) / 2, ROOF_BACK - 0.3), PAINT, nil, paint)
		part("WindowTrim", Vector3.new(0.15, 0.12, ROOF_BACK - ROOF_FRONT - 0.04), CFrame.new(side * (WIDTH / 2 - 0.1), GLASS_BOTTOM + 0.05, (ROOF_FRONT + ROOF_BACK) / 2), CHROME, Enum.Material.Metal)
		part("SideSkirt", Vector3.new(0.12, 0.45, WHEEL_Z * 2 - 3.2), CFrame.new(side * (WIDTH / 2 + 0.03), 0.95, 0), TRIM)
		part("Mirror", Vector3.new(0.6, 0.45, 0.9), CFrame.new(side * (WIDTH / 2 + 0.35), GLASS_BOTTOM + 0.3, ROOF_FRONT - 1.9), PAINT, nil, paint)
		part("MirrorGlass", Vector3.new(0.5, 0.35, 0.05), CFrame.new(side * (WIDTH / 2 + 0.35), GLASS_BOTTOM + 0.3, ROOF_FRONT - 1.43), Color3.fromRGB(90, 100, 110), Enum.Material.Glass, { Reflectance = 0.5 })
		for _, z in { -0.6, 2.4 } do
			part("DoorLine", Vector3.new(0.04, SILL - 1.1, 0.06), CFrame.new(side * (WIDTH / 2 + 0.01), (SILL + 1.1) / 2, z), DARK)
		end
		for _, z in { 0.2, 3.2 } do
			part("DoorHandle", Vector3.new(0.1, 0.15, 0.6), CFrame.new(side * (WIDTH / 2 + 0.04), SILL - 0.4, z), CHROME, Enum.Material.Metal)
		end

		-- Lichter
		local headlight = part("Headlight", Vector3.new(1.4, 0.4, 0.1), CFrame.new(side * 2.3, 2.45, front - 0.02), Color3.fromRGB(255, 248, 230), Enum.Material.Neon)
		Parts.light("SpotLight", headlight, { Face = Enum.NormalId.Front, Range = 60, Angle = 55, Brightness = 3.2, Color = Color3.fromRGB(255, 244, 220), Shadows = true })
		part("Indicator", Vector3.new(0.4, 0.25, 0.1), CFrame.new(side * 3.22, 2.45, front - 0.02), Color3.fromRGB(255, 150, 40), Enum.Material.Neon)
		local taillight = part("Taillight", Vector3.new(1.3, 0.45, 0.1), CFrame.new(side * 2.5, 2.5, back + 0.02), Color3.fromRGB(210, 20, 20), Enum.Material.Neon)
		Parts.light("PointLight", taillight, { Range = 7, Brightness = 0.8, Color = Color3.fromRGB(255, 40, 30) })
	end

	part("Roof", Vector3.new(WIDTH - 0.4, 0.3, ROOF_BACK - ROOF_FRONT), CFrame.new(0, GLASS_TOP + 0.15, (ROOF_FRONT + ROOF_BACK) / 2), PAINT, nil, paint)
	part("RoofLiner", Vector3.new(WIDTH - 0.8, 0.06, ROOF_BACK - ROOF_FRONT - 0.2), CFrame.new(0, GLASS_TOP - 0.03, (ROOF_FRONT + ROOF_BACK) / 2), LINER, Enum.Material.Fabric)
	for _, x in { -2.5, 2.5 } do
		part("RoofRail", Vector3.new(0.15, 0.2, 6), CFrame.new(x, GLASS_TOP + 0.4, 3), TRIM, Enum.Material.Metal)
	end
	-- Frontscheibe als dünne, schräge Scheibe (man sieht von innen keine Glaskante)
	local shieldFrom = Vector3.new(0, GLASS_BOTTOM, ROOF_FRONT - 2.4)
	local shieldTo = Vector3.new(0, GLASS_TOP, ROOF_FRONT)
	local shieldLength = (shieldTo - shieldFrom).Magnitude
	local shield = CFrame.lookAt((shieldFrom + shieldTo) / 2, shieldTo)
	part("Windshield", Vector3.new(WIDTH - 0.6, 0.08, shieldLength), shield, GLASS, Enum.Material.Glass, { Transparency = 0.75, Reflectance = 0.05 })
	-- schwarzer Rand oben an der Scheibe und Scheibenwischer unten
	part("WindshieldFrit", Vector3.new(WIDTH - 0.7, 0.02, 0.32), shield * CFrame.new(0, -0.05, -shieldLength / 2 + 0.16), BLACK)
	for _, info in { { -1.25, 0.12 }, { 1.35, 0.1 } } do
		part("Wiper", Vector3.new(2.5, 0.06, 0.08), shield * CFrame.new(info[1], 0.07, shieldLength / 2 - 0.3) * CFrame.Angles(0, info[2], 0), BLACK)
		part("WiperBlade", Vector3.new(2.3, 0.1, 0.04), shield * CFrame.new(info[1], 0.1, shieldLength / 2 - 0.36) * CFrame.Angles(0, info[2], 0), Color3.fromRGB(25, 25, 25), M.Rubber)
	end
	part("RearWindow", Vector3.new(WIDTH - 0.6, GLASS_TOP - GLASS_BOTTOM, 0.12), CFrame.new(0, (GLASS_BOTTOM + GLASS_TOP) / 2, ROOF_BACK), GLASS, Enum.Material.Glass, glass)
	part("FrontBumper", Vector3.new(WIDTH + 0.2, 0.7, 0.5), CFrame.new(0, 1.1, front - 0.2), TRIM)
	part("RearBumper", Vector3.new(WIDTH + 0.2, 0.7, 0.5), CFrame.new(0, 1.1, back + 0.2), TRIM)
	part("Grille", Vector3.new(3.2, 0.7, 0.08), CFrame.new(0, 2.1, front - 0.03), DARK, Enum.Material.Metal)
	part("GrilleBar", Vector3.new(3.16, 0.1, 0.1), CFrame.new(0, 2.1, front - 0.07), CHROME, Enum.Material.Metal)
	for _, info in { { "FrontPlate", CFrame.new(0, 1.1, front - 0.47) }, { "RearPlate", CFrame.new(0, 1.9, back + 0.03) * CFrame.Angles(0, math.pi, 0) } } do
		local plate = part(info[1], Vector3.new(2, 0.5, 0.04), info[2], Color3.fromRGB(235, 235, 230))
		Parts.text(Parts.surfaceGui(plate, Enum.NormalId.Front), { Text = "WH-K 731", Font = Enum.Font.Code, TextColor3 = Color3.fromRGB(20, 20, 20) })
	end

	------------------------------------------------------------------ Räder (drehen sich)
	for _, side in { -1, 1 } do
		for _, z in { -WHEEL_Z, WHEEL_Z } do
			local center = CFrame.new(side * (WIDTH / 2 - 0.35), 1.25, z)
			local axle, weld = joint("WheelAxle", center, "WheelWeld")
			weld:SetAttribute("Front", z < 0)
			part("Tire", Vector3.new(1.1, 2.5, 2.5), center, DARK, nil, { Shape = Enum.PartType.Cylinder }, axle)
			part("Rim", Vector3.new(1.14, 1.5, 1.5), center, CHROME, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder }, axle)
			for spoke = 0, 4 do
				part("RimSpoke", Vector3.new(1.16 + spoke * 0.03, 0.18, 1.3), center * CFrame.Angles(spoke / 5 * math.pi, 0, 0), Color3.fromRGB(120, 122, 128), Enum.Material.Metal, nil, axle)
			end
			part("WheelArch", Vector3.new(0.2, 0.45, 3.1), CFrame.new(side * (WIDTH / 2 + 0.05), 2.55, z), TRIM)
		end
	end

	------------------------------------------------------------------ Boden innen
	part("Carpet", Vector3.new(WIDTH - 0.9, 0.05, 8.2), CFrame.new(0, 1.125, 1.05), CARPET, M.Carpet)
	for _, side in { -1, 1 } do
		local x = side * 1.4
		part("MatEdge", Vector3.new(1.95, 0.04, 2.3), CFrame.new(x, 1.165, -1.6), Color3.fromRGB(58, 56, 52), M.Fabric)
		part("FloorMat", Vector3.new(1.85, 0.05, 2.2), CFrame.new(x, 1.18, -1.6), BLACK, M.Rubber)
		part("RearMat", Vector3.new(1.85, 0.05, 0.75), CFrame.new(x, 1.17, 3.1), BLACK, M.Rubber)
	end

	------------------------------------------------------------------ Armaturenbrett
	-- Hinten (zum Fahrer) gerade, vorne zur Scheibe hin schräg abfallend
	part("Dashboard", Vector3.new(WIDTH - 0.84, 1.0, 0.65), CFrame.new(0, 3.6, DASH_Z - 0.325), DASH)
	wedge("DashFront", Vector3.new(WIDTH - 0.84, 0.82, 0.85), CFrame.new(0, 3.69, DASH_Z - 1.075), DASH)
	part("DashPad", Vector3.new(WIDTH - 0.84, 0.08, 0.6), CFrame.new(0, 4.14, DASH_Z - 0.32), LEATHER_SOFT, M.Leather)
	part("DashStitch", Vector3.new(WIDTH - 0.9, 0.02, 0.02), CFrame.new(0, 4.185, DASH_Z - 0.08), STITCH)
	-- weiche, runde Kante (nicht hinter dem Tacho)
	cyl("DashRoll", 3.4, 0.28, CFrame.new(1.28, 4.02, DASH_Z + 0.02), LEATHER_SOFT, M.Leather)
	cyl("DashRoll", 0.6, 0.28, CFrame.new(-2.68, 4.02, DASH_Z + 0.02), LEATHER_SOFT, M.Leather)
	-- Lüftungsschlitze für die Frontscheibe
	for i = -5, 5 do
		part("DefrostSlot", Vector3.new(0.3, 0.02, 0.05), CFrame.new(i * 0.42, 3.775, -2.7) * CFrame.Angles(math.rad(-44), 0, 0), BLACK)
	end
	-- Lautsprecher vorne in den Ecken
	for _, side in { -1, 1 } do
		cyl("DashTweeter", 0.03, 0.34, CFrame.new(side * 2.6, 4.19, DASH_Z - 0.35) * ALONG_Y, Color3.fromRGB(24, 24, 26), M.Fabric)
	end

	-- Lüftungsdüse mit Chromrahmen und Lamellen (zeigt nach +Z zum Fahrer)
	local function vent(name, cframe, width, height)
		part(name, Vector3.new(width, height, 0.04), cframe, BLACK)
		for _, dy in { -1, 1 } do
			part(name .. "Frame", Vector3.new(width + 0.06, 0.03, 0.06), cframe * CFrame.new(0, dy * height / 2, 0.01), ALU, M.Metal)
		end
		for _, dx in { -1, 1 } do
			part(name .. "Frame", Vector3.new(0.03, height, 0.06), cframe * CFrame.new(dx * width / 2, 0, 0.01), ALU, M.Metal)
		end
		for i = 1, 3 do
			part(name .. "Slat", Vector3.new(width - 0.04, 0.02, 0.07), cframe * CFrame.new(0, -height / 2 + i * height / 4, 0.01) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(52, 52, 56))
		end
		part(name .. "Tab", Vector3.new(0.05, 0.08, 0.09), cframe * CFrame.new(0, 0, 0.04), ALU, M.Metal)
	end
	vent("SideVent", CFrame.new(-2.62, 3.72, DASH_Z + 0.02), 0.5, 0.32)
	vent("SideVent", CFrame.new(2.62, 3.72, DASH_Z + 0.02), 0.5, 0.32)

	-- Beifahrerseite: Holzleiste, Ambientelicht, Handschuhfach
	part("DashWood", Vector3.new(2.1, 0.2, 0.05), CFrame.new(1.25, 3.55, DASH_Z + 0.02), WOOD, M.Wood)
	for _, y in { 3.44, 3.665 } do
		part("DashWoodEdge", Vector3.new(2.1, 0.025, 0.06), CFrame.new(1.25, y, DASH_Z + 0.02), ALU, M.Metal)
	end
	local dashAmbient = part("DashAmbient", Vector3.new(2.1, 0.025, 0.03), CFrame.new(1.25, 3.405, DASH_Z + 0.04), AMBIENT, M.Neon, { Transparency = 0.2 })
	Parts.light("PointLight", dashAmbient, { Range = 3, Brightness = 0.3, Color = AMBIENT })
	part("GloveBoxPanel", Vector3.new(2.3, 0.75, 0.4), CFrame.new(1.55, 2.75, DASH_Z - 0.2), DASH)
	part("GloveBox", Vector3.new(2.05, 0.55, 0.04), CFrame.new(1.55, 2.8, DASH_Z + 0.01), Color3.fromRGB(37, 36, 38))
	part("GloveBoxHandle", Vector3.new(0.45, 0.07, 0.06), CFrame.new(1.55, 3.0, DASH_Z + 0.05), ALU, M.Metal)
	-- Parkschein vom Nachmittag auf dem Armaturenbrett
	local ticket = part("ParkingTicket", Vector3.new(0.42, 0.01, 0.28), CFrame.new(2.0, 4.19, -2.0) * CFrame.Angles(0, math.rad(18), 0), Color3.fromRGB(238, 236, 228))
	local ticketGui = Parts.surfaceGui(ticket, Enum.NormalId.Top)
	ticketGui.PixelsPerStud = 300
	Parts.text(ticketGui, { Text = "PARKING\n14:12  2,50", Font = Enum.Font.Code, TextColor3 = Color3.fromRGB(40, 40, 40), Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })

	-- Fahrerseite: Knieblende, Lichtschalter
	part("KneePanel", Vector3.new(2.1, 0.7, 0.4), CFrame.new(-1.6, 2.75, DASH_Z - 0.2), DASH)
	cyl("LightSwitchRing", 0.05, 0.3, CFrame.new(-2.62, 3.25, DASH_Z + 0.02) * ALONG_Z, ALU, M.Metal)
	cyl("LightSwitch", 0.08, 0.24, CFrame.new(-2.62, 3.25, DASH_Z + 0.05) * ALONG_Z, BLACK)
	part("LightSwitchMark", Vector3.new(0.03, 0.1, 0.02), CFrame.new(-2.62, 3.3, DASH_Z + 0.1), Color3.fromRGB(230, 230, 230))
	for _, side in { -1, 1 } do
		local footLight = part("FootwellLight", Vector3.new(0.3, 0.03, 0.1), CFrame.new(side * 1.5, 2.38, DASH_Z - 0.25), AMBIENT, M.Neon, { Transparency = 0.4 })
		Parts.light("PointLight", footLight, { Range = 3.5, Brightness = 0.25, Color = AMBIENT })
	end

	-- Tacho und Drehzahlmesser in einer Röhre unter einer Lederhaube. Sie sitzen so hoch,
	-- dass man sie vom Fahrersitz über dem Lenkrad-Polster sieht.
	local CLUSTER_Y = 4.12
	part("ClusterHousing", Vector3.new(1.8, 0.5, 0.3), CFrame.new(-1.4, CLUSTER_Y, DASH_Z - 0.15), DASH)
	part("ClusterHood", Vector3.new(1.8, 0.2, 0.45), CFrame.new(-1.4, CLUSTER_Y + 0.33, DASH_Z - 0.05), LEATHER, M.Leather)
	cyl("ClusterHoodLip", 1.8, 0.2, CFrame.new(-1.4, CLUSTER_Y + 0.31, DASH_Z + 0.16), LEATHER, M.Leather)
	part("ClusterHoodStitch", Vector3.new(1.78, 0.02, 0.02), CFrame.new(-1.4, CLUSTER_Y + 0.435, DASH_Z + 0.05), STITCH)
	for _, dx in { -0.85, 0.85 } do
		part("ClusterBezel", Vector3.new(0.08, 0.6, 0.22), CFrame.new(-1.4 + dx, CLUSTER_Y, DASH_Z + 0.1), GLOSS)
	end
	part("ClusterBezel", Vector3.new(1.78, 0.06, 0.22), CFrame.new(-1.4, CLUSTER_Y - 0.28, DASH_Z + 0.1), GLOSS)
	part("ClusterGlass", Vector3.new(1.62, 0.52, 0.02), CFrame.new(-1.4, CLUSTER_Y, DASH_Z + 0.16), Color3.fromRGB(30, 34, 40), nil, { Transparency = 0.93, Reflectance = 0.3 })

	-- Die Nadeln (SpeedNeedle/RpmNeedle) dreht der Client von -120° bis +120°
	local cluster = part("Cluster", Vector3.new(1.6, 0.5, 0.05), CFrame.new(-1.4, CLUSTER_Y, DASH_Z + 0.03), BLACK)
	local clusterGui = Parts.surfaceGui(cluster, Enum.NormalId.Back, true)
	clusterGui.PixelsPerStud = 220
	local GAUGE_WHITE = Color3.fromRGB(235, 230, 220)
	local GAUGE_GREY = Color3.fromRGB(160, 155, 145)
	local GAUGE_RED = Color3.fromRGB(230, 60, 40)
	local function frame(parentGui, props)
		local created = Instance.new("Frame")
		created.BorderSizePixel = 0
		for key, value in props do
			created[key] = value
		end
		created.Parent = parentGui
		return created
	end
	local function round(target, scale)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(scale, 0)
		corner.Parent = target
	end
	for _, info in { { "Speed", 0.22, "km/h", 11, 200 }, { "Rpm", 0.78, "x1000 rpm", 9, 8 } } do
		local name, posX, unit, majors, maxValue = info[1], info[2], info[3], info[4], info[5]
		local dial = frame(clusterGui, {
			Name = name .. "Dial",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(posX, 0.5),
			Size = UDim2.fromScale(0.4, 0.94),
			BackgroundColor3 = Color3.fromRGB(14, 14, 17),
		})
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = dial
		round(dial, 0.5)
		local ring = Instance.new("UIStroke")
		ring.Color = Color3.fromRGB(150, 150, 156)
		ring.Thickness = 2
		ring.Parent = dial
		-- Skala: große Striche mit Zahlen, kleine Striche dazwischen
		local steps = (majors - 1) * 2
		for t = 0, steps do
			local angle = -120 + t * 240 / steps
			local major = t % 2 == 0
			local holder = frame(dial, { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Rotation = angle })
			frame(holder, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.04),
				Size = major and UDim2.fromScale(0.022, 0.09) or UDim2.fromScale(0.012, 0.05),
				BackgroundColor3 = (name == "Rpm" and t >= steps - 3) and GAUGE_RED or GAUGE_WHITE,
			})
			if major then
				local r = math.rad(angle)
				Parts.text(dial, {
					Text = tostring(math.round(t / steps * maxValue)),
					TextColor3 = (name == "Rpm" and t >= steps - 2) and GAUGE_RED or GAUGE_WHITE,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5 + 0.3 * math.sin(r), 0.5 - 0.3 * math.cos(r)),
					Size = UDim2.fromScale(0.17, 0.09),
				})
			end
		end
		-- Nadel dreht sich um die Mitte der Uhr
		local needleHolder = frame(dial, { Name = name .. "Needle", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Rotation = -120, ZIndex = 2 })
		frame(needleHolder, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.025, 0.4),
			BackgroundColor3 = Color3.fromRGB(255, 80, 40),
			ZIndex = 2,
		})
		local cap = frame(dial, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.13, 0.13), BackgroundColor3 = Color3.fromRGB(36, 36, 40), ZIndex = 3 })
		round(cap, 0.5)
		Parts.text(dial, {
			Name = name .. "Text",
			Text = name == "Speed" and "0" or "",
			TextColor3 = GAUGE_WHITE,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.72),
			Size = UDim2.fromScale(0.36, 0.13),
			ZIndex = 2,
		})
		Parts.text(dial, {
			Text = unit,
			Font = Enum.Font.Gotham,
			TextColor3 = GAUGE_GREY,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.86),
			Size = UDim2.fromScale(0.42, 0.07),
		})
	end
	-- kleines Display zwischen den Uhren: Außentemperatur, Kilometer, Tank
	local infoScreen = frame(clusterGui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromScale(0.15, 0.6),
		BackgroundColor3 = Color3.fromRGB(6, 8, 10),
	})
	round(infoScreen, 0.12)
	Parts.text(infoScreen, { Text = "4°C", TextColor3 = Color3.fromRGB(150, 200, 255), Size = UDim2.fromScale(0.8, 0.2), Position = UDim2.fromScale(0.1, 0.06) })
	Parts.text(infoScreen, { Text = "128452 km", Font = Enum.Font.Code, TextColor3 = GAUGE_WHITE, Size = UDim2.fromScale(0.9, 0.15), Position = UDim2.fromScale(0.05, 0.34) })
	Parts.text(infoScreen, { Text = "FUEL", Font = Enum.Font.Gotham, TextColor3 = GAUGE_GREY, Size = UDim2.fromScale(0.6, 0.11), Position = UDim2.fromScale(0.2, 0.58) })
	local fuelBar = frame(infoScreen, { Position = UDim2.fromScale(0.12, 0.75), Size = UDim2.fromScale(0.76, 0.08), BackgroundColor3 = Color3.fromRGB(40, 40, 44) })
	frame(fuelBar, { Size = UDim2.fromScale(0.62, 1), BackgroundColor3 = Color3.fromRGB(255, 170, 70) })
	-- Blinker-Pfeil zwischen den Uhren (der Client lässt ihn blinken)
	Parts.text(clusterGui, {
		Name = "BlinkerArrow",
		Text = "▶",
		TextColor3 = Color3.fromRGB(80, 255, 110),
		TextTransparency = 1,
		Size = UDim2.fromScale(0.08, 0.26),
		Position = UDim2.fromScale(0.46, 0.04),
	})
	Parts.light("PointLight", cluster, { Range = 4, Brightness = 0.9, Color = Color3.fromRGB(255, 170, 90) })

	------------------------------------------------------------------ Mittelkonsole oben
	local STACK_Z = DASH_Z + 0.19 -- Vorderfläche der Mittelkonsole
	part("CenterStack", Vector3.new(1.3, 1.75, 0.44), CFrame.new(0, 3.2, STACK_Z - 0.22), DASH)
	for _, side in { -1, 1 } do
		part("StackEdge", Vector3.new(0.05, 1.75, 0.08), CFrame.new(side * 0.65, 3.2, STACK_Z - 0.02), ALU, M.Metal)
	end
	vent("Vent", CFrame.new(-0.32, 3.84, STACK_Z + 0.01), 0.46, 0.3)
	vent("Vent", CFrame.new(0.32, 3.84, STACK_Z + 0.01), 0.46, 0.3)
	part("HazardButton", Vector3.new(0.14, 0.14, 0.05), CFrame.new(0, 3.84, STACK_Z + 0.03), Color3.fromRGB(190, 30, 30), Enum.Material.Neon)

	-- Bildschirm mit Radio
	part("ScreenBezel", Vector3.new(1.2, 0.56, 0.03), CFrame.new(0, 3.37, STACK_Z + 0.01), GLOSS, nil, { Reflectance = 0.15 })
	local radio = part("RadioDisplay", Vector3.new(1.1, 0.46, 0.03), CFrame.new(0, 3.37, STACK_Z + 0.03), Color3.fromRGB(6, 8, 10))
	local radioGui = Parts.surfaceGui(radio, Enum.NormalId.Back, true)
	radioGui.PixelsPerStud = 220
	Parts.text(radioGui, {
		Name = "RadioText",
		Text = "FM 98.4  PINE RADIO   18:47",
		Font = Enum.Font.Code,
		TextColor3 = Color3.fromRGB(120, 220, 255),
		Size = UDim2.fromScale(0.94, 0.26),
		Position = UDim2.fromScale(0.03, 0.1),
	})
	local progress = frame(radioGui, { Position = UDim2.fromScale(0.06, 0.5), Size = UDim2.fromScale(0.88, 0.035), BackgroundColor3 = Color3.fromRGB(35, 45, 55) })
	frame(progress, { Size = UDim2.fromScale(0.36, 1), BackgroundColor3 = Color3.fromRGB(120, 220, 255) })
	Parts.text(radioGui, {
		Text = "RADIO     MEDIA     NAV     SETTINGS",
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.fromRGB(110, 125, 140),
		Size = UDim2.fromScale(0.9, 0.14),
		Position = UDim2.fromScale(0.05, 0.74),
	})
	Parts.light("PointLight", radio, { Range = 2.5, Brightness = 0.4, Color = Color3.fromRGB(120, 200, 255) })
	for i = -3, 3 do
		part("RadioButton", Vector3.new(0.13, 0.06, 0.04), CFrame.new(i * 0.16, 3.04, STACK_Z + 0.02), Color3.fromRGB(34, 34, 37))
	end

	-- Klimabedienung mit zwei Drehreglern und kleinem Display
	part("ClimatePanel", Vector3.new(1.2, 0.42, 0.04), CFrame.new(0, 2.72, STACK_Z + 0.01), GLOSS, nil, { Reflectance = 0.1 })
	local climate = part("ClimateDisplay", Vector3.new(0.5, 0.15, 0.02), CFrame.new(0, 2.77, STACK_Z + 0.035), Color3.fromRGB(6, 6, 8))
	local climateGui = Parts.surfaceGui(climate, Enum.NormalId.Back, true)
	climateGui.PixelsPerStud = 300
	Parts.text(climateGui, { Text = "21.5°  AUTO  21.5°", Font = Enum.Font.Code, TextColor3 = Color3.fromRGB(255, 170, 80), Size = UDim2.fromScale(0.94, 0.7), Position = UDim2.fromScale(0.03, 0.15) })
	for _, x in { -0.42, 0.42 } do
		cyl("ClimateKnobRing", 0.06, 0.32, CFrame.new(x, 2.72, STACK_Z + 0.03) * ALONG_Z, ALU, M.Metal)
		cyl("ClimateKnob", 0.12, 0.26, CFrame.new(x, 2.72, STACK_Z + 0.07) * ALONG_Z, Color3.fromRGB(22, 22, 24))
		part("ClimateKnobMark", Vector3.new(0.025, 0.08, 0.02), CFrame.new(x, 2.79, STACK_Z + 0.13), Color3.fromRGB(230, 230, 230))
	end
	for i = -2, 2 do
		part("ClimateButton", Vector3.new(0.08, 0.05, 0.03), CFrame.new(i * 0.1, 2.6, STACK_Z + 0.03), Color3.fromRGB(40, 40, 44))
	end

	-- unterer Teil mit Ablage, USB und Steckdose
	part("StackLower", Vector3.new(1.2, 1.2, 0.6), CFrame.new(0, 1.7, STACK_Z - 0.25), DASH)
	part("Cubby", Vector3.new(0.9, 0.25, 0.03), CFrame.new(0, 2.08, STACK_Z + 0.06), BLACK)
	for _, x in { -0.25, -0.1 } do
		part("UsbPort", Vector3.new(0.09, 0.035, 0.02), CFrame.new(x, 1.84, STACK_Z + 0.06), Color3.fromRGB(4, 4, 4))
	end
	cyl("PowerSocket", 0.03, 0.13, CFrame.new(0.2, 1.84, STACK_Z + 0.06) * ALONG_Z, ALU, M.Metal)

	------------------------------------------------------------------ Konsole zwischen den Sitzen
	part("Console", Vector3.new(1.0, 0.9, 3.65), CFrame.new(0, 1.55, 0.375), DASH)
	for _, side in { -1, 1 } do
		part("ConsoleSide", Vector3.new(0.04, 0.55, 3.5), CFrame.new(side * 0.52, 1.6, 0.4), LEATHER_SOFT, M.Leather)
		part("ConsoleStitch", Vector3.new(0.045, 0.02, 3.5), CFrame.new(side * 0.52, 1.86, 0.4), STITCH)
	end
	part("ConsoleWood", Vector3.new(0.9, 0.04, 1.7), CFrame.new(0, 2.02, -0.55), WOOD, M.Wood)
	-- Schaltknüppel mit Lederbalg
	cyl("ShifterRing", 0.04, 0.5, CFrame.new(0, 2.05, -0.3) * ALONG_Y, ALU, M.Metal)
	part("ShifterBoot", Vector3.new(0.4, 0.16, 0.4), CFrame.new(0, 2.13, -0.3), LEATHER, M.Leather)
	part("ShifterBootTop", Vector3.new(0.27, 0.2, 0.27), CFrame.new(0, 2.3, -0.3) * CFrame.Angles(0, math.rad(45), 0), LEATHER, M.Leather)
	part("ShifterStick", Vector3.new(0.09, 0.4, 0.09), CFrame.new(0, 2.55, -0.3), ALU, M.Metal)
	part("ShifterKnob", Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, 2.82, -0.3), LEATHER, M.Leather, { Shape = Enum.PartType.Ball })
	cyl("ShifterCap", 0.03, 0.2, CFrame.new(0, 2.965, -0.3) * ALONG_Y, ALU, M.Metal)
	-- Becherhalter, in einem steht noch der Kaffee von der Tankstelle
	for _, x in { -0.22, 0.22 } do
		cyl("CupHolderRing", 0.025, 0.38, CFrame.new(x, 2.035, -1.05) * ALONG_Y, ALU, M.Metal)
		cyl("CupHolder", 0.03, 0.33, CFrame.new(x, 2.045, -1.05) * ALONG_Y, BLACK)
	end
	cyl("CoffeeCup", 0.5, 0.28, CFrame.new(0.22, 2.29, -1.05) * ALONG_Y, Color3.fromRGB(228, 222, 210))
	cyl("CupSleeve", 0.18, 0.295, CFrame.new(0.22, 2.3, -1.05) * ALONG_Y, Color3.fromRGB(130, 95, 62), M.Cardboard)
	cyl("CupLid", 0.06, 0.31, CFrame.new(0.22, 2.56, -1.05) * ALONG_Y, Color3.fromRGB(240, 240, 238))
	-- Handbremse
	local brake = CFrame.new(0, 2.12, 0.45) * CFrame.Angles(math.rad(-12), 0, 0)
	part("BrakeBoot", Vector3.new(0.3, 0.05, 0.8), CFrame.new(0, 2.04, 0.45), LEATHER, M.Leather)
	part("Handbrake", Vector3.new(0.13, 0.11, 0.95), brake, Color3.fromRGB(40, 40, 42))
	part("HandbrakeGrip", Vector3.new(0.18, 0.16, 0.5), brake * CFrame.new(0, 0, 0.22), LEATHER, M.Leather)
	cyl("HandbrakeButton", 0.06, 0.09, brake * CFrame.new(0, 0, 0.5) * ALONG_Z, ALU, M.Metal)
	-- Armlehne
	part("ConsoleArmrest", Vector3.new(0.98, 0.24, 1.3), CFrame.new(0, 2.12, 1.82), LEATHER_SOFT, M.Leather)
	cyl("ArmrestRoll", 0.98, 0.24, CFrame.new(0, 2.12, 1.17), LEATHER_SOFT, M.Leather)
	for _, x in { -0.4, 0.4 } do
		part("ArmrestStitch", Vector3.new(0.02, 0.02, 1.3), CFrame.new(x, 2.245, 1.82), STITCH)
	end
	for _, x in { -0.2, 0.2 } do
		vent("RearVent", CFrame.new(x, 1.7, 2.21), 0.3, 0.16)
	end

	------------------------------------------------------------------ Pedale
	for i, x in { -1.95, -1.45, -0.95 } do
		local gas = i == 3
		local pad = CFrame.new(x, gas and 1.6 or 1.65, ROOF_FRONT - 1.9) * CFrame.Angles(math.rad(-20), 0, 0)
		part("PedalPad", gas and Vector3.new(0.26, 0.6, 0.06) or Vector3.new(0.36, 0.34, 0.06), pad, Color3.fromRGB(28, 28, 28), M.Rubber)
		for g = -1, 1 do
			part("PedalGrip", Vector3.new(gas and 0.2 or 0.3, 0.03, 0.02), pad * CFrame.new(0, g * 0.09, 0.04), ALU, M.Metal)
		end
		if not gas then
			beam("PedalArm", (pad * CFrame.new(0, 0.15, -0.03)).Position, Vector3.new(x, 3.0, -2.95), 0.07, Color3.fromRGB(45, 45, 48), M.Metal)
		end
	end
	part("DeadPedal", Vector3.new(0.34, 0.7, 0.06), CFrame.new(-2.5, 1.5, ROOF_FRONT - 1.75) * CFrame.Angles(math.rad(-35), 0, 0), Color3.fromRGB(28, 28, 28), M.Rubber)

	------------------------------------------------------------------ Lenksäule mit Hebeln und Schlüssel
	local steeringBase = CFrame.new(-1.35, 3.92, ROOF_FRONT - 0.15) * CFrame.Angles(math.rad(-25), 0, 0)
	part("SteeringColumn", Vector3.new(0.3, 0.3, 1.1), steeringBase * CFrame.new(0, 0, -0.6), Color3.fromRGB(22, 22, 24))
	part("ColumnShroud", Vector3.new(0.46, 0.4, 0.7), steeringBase * CFrame.new(0, -0.04, -0.5), DASH)
	for _, side in { -1, 1 } do
		-- links Blinker, rechts Scheibenwischer
		cyl("Stalk", 0.62, 0.07, steeringBase * CFrame.new(side * 0.52, 0.03, -0.32) * CFrame.Angles(0, 0, math.rad(-side * 8)), Color3.fromRGB(26, 26, 28))
		cyl("StalkTip", 0.18, 0.11, steeringBase * CFrame.new(side * 0.85, 0.08, -0.32) * CFrame.Angles(0, 0, math.rad(-side * 8)), Color3.fromRGB(32, 32, 35))
	end
	local ignition = steeringBase * CFrame.new(0.24, -0.1, -0.55)
	cyl("IgnitionRing", 0.04, 0.17, ignition, ALU, M.Metal)
	part("Key", Vector3.new(0.12, 0.2, 0.05), ignition * CFrame.new(0.08, 0, 0), BLACK)
	cyl("KeyRing", 0.02, 0.2, ignition * CFrame.new(0.12, -0.18, 0) * ALONG_Z, ALU, M.Metal)
	part("KeyTag", Vector3.new(0.03, 0.26, 0.16), ignition * CFrame.new(0.13, -0.38, 0) * CFrame.Angles(0, 0, math.rad(6)), Color3.fromRGB(120, 86, 52), M.Wood)

	------------------------------------------------------------------ Lenkrad (dreht sich)
	local hub, steeringWeld = joint("SteeringHub", steeringBase, "SteeringWeld")
	local radius, segments = 0.72, 32
	for i = 0, segments - 1 do
		local angle = i / segments * math.pi * 2
		-- links und rechts (Daumenauflage) etwas dicker; abwechselnd dicker, damit sich die Enden nicht überlagern
		local grip = math.abs(math.cos(angle)) > 0.85
		local thick = (grip and 0.19 or 0.155) + (i % 2) * 0.015
		local top = i == segments / 4
		part("WheelRim", Vector3.new(thick, 2 * math.pi * radius / segments + 0.03, thick), steeringBase * CFrame.Angles(0, 0, angle) * CFrame.new(radius, 0, 0), top and STITCH or LEATHER, M.Leather, nil, hub)
	end
	for _, angle in { 0, math.pi } do
		part("WheelSpoke", Vector3.new(radius - 0.1, 0.2, 0.1), steeringBase * CFrame.Angles(0, 0, angle) * CFrame.new(radius / 2 + 0.05, 0, 0.02), Color3.fromRGB(30, 30, 33), nil, nil, hub)
		part("SpokeTrim", Vector3.new(radius - 0.3, 0.035, 0.11), steeringBase * CFrame.Angles(0, 0, angle) * CFrame.new(radius / 2 + 0.1, -0.06, 0.03), ALU, M.Metal, nil, hub)
	end
	for _, dx in { -0.07, 0.07 } do
		part("WheelSpoke", Vector3.new(0.08, radius - 0.1, 0.08), steeringBase * CFrame.new(dx, -(radius / 2 + 0.05), 0.02), Color3.fromRGB(30, 30, 33), nil, nil, hub)
	end
	-- Tasten auf den Speichen
	for _, side in { -1, 1 } do
		for row = 0, 1 do
			for col = 0, 1 do
				part("WheelButton", Vector3.new(0.08, 0.06, 0.03), steeringBase * CFrame.new(side * (0.36 + col * 0.11), 0.06 - row * 0.09 + 0.02, 0.08), Color3.fromRGB(22, 22, 24), nil, nil, hub)
			end
		end
	end
	-- Prallkissen mit Logo
	part("Airbag", Vector3.new(0.5, 0.34, 0.15), steeringBase * CFrame.new(0, -0.04, 0.08), LEATHER_SOFT, M.Leather, nil, hub)
	cyl("AirbagRound", 0.15, 0.36, steeringBase * CFrame.new(0, 0.1, 0.08) * ALONG_Z, LEATHER_SOFT, M.Leather, nil, hub)
	cyl("WheelLogo", 0.03, 0.15, steeringBase * CFrame.new(0, 0.0, 0.16) * ALONG_Z, CHROME, M.Metal, nil, hub)
	cyl("WheelLogoInner", 0.035, 0.1, steeringBase * CFrame.new(0, 0.0, 0.162) * ALONG_Z, Color3.fromRGB(30, 50, 90), nil, nil, hub)
	steeringWeld:SetAttribute("IsSteering", true)

	------------------------------------------------------------------ Vordersitze
	for _, side in { -1, 1 } do
		local x = side * 1.4
		local outer = x + side * 0.92
		for _, rx in { -0.5, 0.5 } do
			part("SeatRail", Vector3.new(0.1, 0.08, 2.2), CFrame.new(x + rx, 1.19, 1.2), Color3.fromRGB(70, 70, 74), M.Metal)
		end
		part("SeatBase", Vector3.new(1.5, 0.35, 1.7), CFrame.new(x, 1.4, 1.2), DARK)
		-- Sitzfläche: Stoff in der Mitte, Leder an den Wangen, runde Vorderkante
		part("SeatCushion", Vector3.new(1.15, 0.36, 1.85), CFrame.new(x, 1.66, 1.25), CLOTH, M.Fabric)
		for _, bx in { -1, 1 } do
			part("SeatBolster", Vector3.new(0.33, 0.46, 1.95), CFrame.new(x + bx * 0.735, 1.7, 1.22), LEATHER, M.Leather)
		end
		cyl("SeatFront", 1.8, 0.42, CFrame.new(x, 1.64, 0.3), LEATHER, M.Leather)
		for i = 1, 3 do
			part("SeatRib", Vector3.new(1.15, 0.02, 0.05), CFrame.new(x, 1.845, 0.6 + i * 0.45), RIB, M.Fabric)
		end
		part("SeatTrim", Vector3.new(0.05, 0.3, 1.6), CFrame.new(outer, 1.45, 1.25), DARK)
		part("SeatLever", Vector3.new(0.06, 0.07, 0.5), CFrame.new(outer + side * 0.04, 1.42, 0.7), DARK)
		cyl("ReclineKnob", 0.1, 0.22, CFrame.new(outer + side * 0.05, 1.6, 2.0), DARK)

		-- Lehne leicht nach hinten geneigt
		local seatBack = CFrame.new(x, 1.8, 2.2) * CFrame.Angles(math.rad(12), 0, 0)
		part("SeatBack", Vector3.new(1.15, 2.55, 0.32), seatBack * CFrame.new(0, 1.35, 0.02), CLOTH, M.Fabric)
		for _, bx in { -1, 1 } do
			part("SeatBackBolster", Vector3.new(0.33, 2.45, 0.5), seatBack * CFrame.new(bx * 0.735, 1.3, -0.04) * CFrame.Angles(0, bx * 0.18, 0), LEATHER, M.Leather)
		end
		cyl("SeatShoulder", 1.8, 0.48, seatBack * CFrame.new(0, 2.62, 0.03), LEATHER, M.Leather)
		for i = 1, 4 do
			part("SeatBackRib", Vector3.new(1.15, 0.05, 0.03), seatBack * CFrame.new(0, 0.3 + i * 0.48, -0.15), RIB, M.Fabric)
		end
		part("SeatShell", Vector3.new(1.85, 2.5, 0.08), seatBack * CFrame.new(0, 1.3, 0.27), DARK)
		part("SeatPocket", Vector3.new(1.3, 0.8, 0.06), seatBack * CFrame.new(0, 0.75, 0.33), Color3.fromRGB(28, 28, 30), M.Fabric)
		-- Kopfstütze mit runden Kanten auf zwei Stangen
		for _, px in { -0.3, 0.3 } do
			cyl("HeadrestPost", 0.5, 0.07, seatBack * CFrame.new(px, 3.0, 0.03) * ALONG_Y, ALU, M.Metal)
		end
		part("Headrest", Vector3.new(1.0, 0.42, 0.36), seatBack * CFrame.new(0, 3.4, 0.05), LEATHER, M.Leather)
		cyl("HeadrestTop", 1.0, 0.36, seatBack * CFrame.new(0, 3.61, 0.05), LEATHER, M.Leather)
		cyl("HeadrestBottom", 1.0, 0.3, seatBack * CFrame.new(0, 3.2, 0.05), LEATHER, M.Leather)

		-- Gurt (angelegt), Gurtschloss, Umlenkung an der B-Säule
		local buckle = Vector3.new(side * 0.47, 2.02, 1.95)
		beam("SeatBelt", Vector3.new(side * 2.8, 5.05, 2.6), buckle, 0.1, Color3.fromRGB(28, 28, 30), M.Fabric)
		beam("LapBelt", buckle, Vector3.new(side * 2.4, 1.85, 1.95), 0.1, Color3.fromRGB(28, 28, 30), M.Fabric)
		part("BeltGuide", Vector3.new(0.12, 0.3, 0.22), CFrame.new(side * 2.8, 5.05, 2.6), DASH)
		part("BeltBuckle", Vector3.new(0.12, 0.35, 0.18), CFrame.new(side * 0.45, 1.95, 1.95), BLACK)
		part("BuckleButton", Vector3.new(0.13, 0.06, 0.08), CFrame.new(side * 0.45, 2.13, 1.95), Color3.fromRGB(180, 30, 30))
		part("BeltLatch", Vector3.new(0.05, 0.22, 0.14), CFrame.new(side * 0.47, 2.22, 1.95), ALU, M.Metal)
	end

	------------------------------------------------------------------ Rückbank
	local benchWidth = WIDTH - 1.1
	part("RearBenchBase", Vector3.new(benchWidth, 0.45, 1.6), CFrame.new(0, 1.35, 4.45), DARK)
	part("RearBench", Vector3.new(benchWidth, 0.4, 1.8), CFrame.new(0, 1.72, 4.4), LEATHER, M.Leather)
	cyl("RearBenchFront", benchWidth, 0.4, CFrame.new(0, 1.7, 3.5), LEATHER, M.Leather)
	local rearBack = CFrame.new(0, 1.9, 5.3) * CFrame.Angles(math.rad(12), 0, 0)
	part("RearBenchBack", Vector3.new(benchWidth, 2.5, 0.4), rearBack * CFrame.new(0, 1.25, 0.1), LEATHER, M.Leather)
	for _, info in { { -1.85, 1.15 }, { 0, 0.9 }, { 1.85, 1.15 } } do
		local sx, sw = info[1], info[2]
		part("RearInsert", Vector3.new(sw, 0.05, 1.6), CFrame.new(sx, 1.935, 4.45), CLOTH, M.Fabric)
		part("RearBackInsert", Vector3.new(sw, 2.1, 0.05), rearBack * CFrame.new(sx, 1.2, -0.12), CLOTH, M.Fabric)
		for i = 1, 3 do
			part("RearRib", Vector3.new(sw, 0.02, 0.05), CFrame.new(sx, 1.965, 3.75 + i * 0.4), RIB, M.Fabric)
			part("RearBackRib", Vector3.new(sw, 0.04, 0.03), rearBack * CFrame.new(sx, 0.3 + i * 0.5, -0.155), RIB, M.Fabric)
		end
		-- Kopfstützen
		for _, px in { -0.25, 0.25 } do
			cyl("RearHeadrestPost", 0.45, 0.06, rearBack * CFrame.new(sx + px, 2.7, 0.1) * ALONG_Y, ALU, M.Metal)
		end
		part("RearHeadrest", Vector3.new(0.9, 0.36, 0.32), rearBack * CFrame.new(sx, 3.0, 0.1), LEATHER, M.Leather)
		cyl("RearHeadrestTop", 0.9, 0.32, rearBack * CFrame.new(sx, 3.18, 0.1), LEATHER, M.Leather)
	end
	part("RearSplit", Vector3.new(0.03, 2.4, 0.05), rearBack * CFrame.new(0.62, 1.25, -0.12), DARK)
	for _, side in { -1, 1 } do
		beam("RearBelt", Vector3.new(side * 2.75, 5.2, 6.2), Vector3.new(side * 2.6, 2.0, 5.1), 0.1, Color3.fromRGB(28, 28, 30), M.Fabric)
		for _, bx in { 0.75, 1.05 } do
			part("RearBuckle", Vector3.new(0.12, 0.3, 0.16), CFrame.new(side * bx, 1.98, 5.2), BLACK)
		end
	end
	-- Hutablage mit Lautsprechern
	part("ParcelShelf", Vector3.new(WIDTH - 0.8, 0.08, 0.75), CFrame.new(0, 4.42, 6.4), DASH)
	for _, side in { -1, 1 } do
		cyl("ShelfSpeakerRing", 0.04, 0.68, CFrame.new(side * 2.0, 4.47, 6.4) * ALONG_Y, ALU, M.Metal)
		cyl("ShelfSpeaker", 0.05, 0.6, CFrame.new(side * 2.0, 4.48, 6.4) * ALONG_Y, Color3.fromRGB(24, 24, 26), M.Fabric)
	end

	------------------------------------------------------------------ Türverkleidungen
	local function doorTrim(side, zFrom, zTo, isFront)
		local x = side * 2.94
		local inward = -side
		local length = zTo - zFrom
		local mid = (zFrom + zTo) / 2
		part("DoorCarpet", Vector3.new(0.08, 0.95, length), CFrame.new(x, 1.6, mid), CARPET, M.Carpet)
		part("DoorPanel", Vector3.new(0.1, 0.75, length), CFrame.new(x + inward * 0.01, 2.45, mid), LEATHER_SOFT, M.Leather)
		part("DoorStitch", Vector3.new(0.02, 0.02, length - 0.2), CFrame.new(x + inward * 0.065, 2.12, mid), STITCH)
		part("DoorWood", Vector3.new(0.05, 0.16, length - 0.5), CFrame.new(x + inward * 0.07, 2.92, mid), WOOD, M.Wood)
		part("DoorWoodEdge", Vector3.new(0.06, 0.025, length - 0.5), CFrame.new(x + inward * 0.07, 2.83, mid), ALU, M.Metal)
		part("DoorAmbient", Vector3.new(0.03, 0.025, length - 0.6), CFrame.new(x + inward * 0.09, 2.8, mid), AMBIENT, M.Neon, { Transparency = 0.25 })
		part("DoorSill", Vector3.new(0.34, 0.16, length), CFrame.new(x + inward * 0.1, 3.2, mid), DASH)
		part("WindowSeal", Vector3.new(0.06, 0.06, length), CFrame.new(side * 3.0, 3.31, mid), BLACK, M.Rubber)
		cyl("LockPin", 0.16, 0.07, CFrame.new(x + inward * 0.12, 3.33, zTo - 0.5) * ALONG_Y, ALU, M.Metal)
		-- Armlehne mit Griff und Fensterschaltern
		local armZ = isFront and mid + 0.6 or mid + 0.4
		local armLength = isFront and 2.0 or 1.6
		part("DoorArmrest", Vector3.new(0.45, 0.2, armLength), CFrame.new(x + inward * 0.25, 2.55, armZ), LEATHER, M.Leather)
		part("PullHandle", Vector3.new(0.12, 0.32, 0.12), CFrame.new(x + inward * 0.33, 2.76, armZ - armLength / 2 + 0.15), LEATHER, M.Leather)
		part("SwitchPanel", Vector3.new(0.28, 0.03, 0.55), CFrame.new(x + inward * 0.28, 2.66, armZ + 0.35), GLOSS, nil, { Reflectance = 0.1 })
		local switches = (isFront and side == -1) and 4 or 1
		for i = 0, switches - 1 do
			part("WindowSwitch", Vector3.new(0.08, 0.05, 0.12), CFrame.new(x + inward * (0.22 + (i % 2) * 0.12), 2.69, armZ + 0.2 + math.floor(i / 2) * 0.2), Color3.fromRGB(30, 30, 33))
		end
		-- Türöffner vorne an der Tür
		local handleZ = zFrom + (isFront and 0.8 or 0.6)
		part("HandleRecess", Vector3.new(0.03, 0.22, 0.55), CFrame.new(x + inward * 0.06, 2.62, handleZ), BLACK)
		part("InnerHandle", Vector3.new(0.05, 0.07, 0.42), CFrame.new(x + inward * 0.09, 2.62, handleZ), CHROME, M.Metal)
		-- Lautsprecher und Ablagefach
		local speakerSize = isFront and 0.85 or 0.65
		local speakerZ = zFrom + (isFront and 0.75 or 0.35)
		cyl("SpeakerRing", 0.05, speakerSize, CFrame.new(x + inward * 0.06, 1.6, speakerZ), ALU, M.Metal)
		cyl("Speaker", 0.05, speakerSize - 0.08, CFrame.new(x + inward * 0.075, 1.6, speakerZ), Color3.fromRGB(25, 25, 27), M.Fabric)
		cyl("SpeakerCap", 0.06, 0.16, CFrame.new(x + inward * 0.09, 1.6, speakerZ), Color3.fromRGB(45, 45, 48))
		part("DoorPocket", Vector3.new(0.3, 0.42, length * 0.45), CFrame.new(x + inward * 0.2, 1.45, armZ + 0.1), DASH)
		return x + inward * 0.2, armZ
	end
	for _, side in { -1, 1 } do
		local pocketX, pocketZ = doorTrim(side, ROOF_FRONT - 2.2, 2.3, true)
		doorTrim(side, 2.9, 5.7, false)
		if side == 1 then
			-- Wasserflasche im Fach der Beifahrertür
			cyl("WaterBottle", 0.9, 0.26, CFrame.new(pocketX, 1.88, pocketZ + 0.9) * ALONG_Y, Color3.fromRGB(170, 200, 220), M.Glass, { Transparency = 0.45 })
			cyl("BottleCap", 0.1, 0.16, CFrame.new(pocketX, 2.38, pocketZ + 0.9) * ALONG_Y, Color3.fromRGB(40, 90, 170))
		else
			-- gefaltete Straßenkarte im Fach der Fahrertür
			part("RoadMap", Vector3.new(0.05, 0.5, 0.85), CFrame.new(pocketX, 1.85, pocketZ + 0.3) * CFrame.Angles(0, 0, math.rad(side * 8)), Color3.fromRGB(225, 215, 170), M.Fabric)
		end
		-- Hochtöner im Spiegeldreieck vorne an der Tür
		part("DoorTweeter", Vector3.new(0.08, 0.32, 0.32), CFrame.new(side * 2.9, 3.05, ROOF_FRONT - 2.05), Color3.fromRGB(24, 24, 26), M.Fabric)
		-- Verkleidung der B-Säule mit Gurthöhenverstellung
		part("BPillarTrim", Vector3.new(0.08, 2.45, 0.6), CFrame.new(side * 2.86, 4.55, 2.6), LINER)
		part("BeltAdjuster", Vector3.new(0.04, 0.5, 0.08), CFrame.new(side * 2.81, 4.6, 2.6), Color3.fromRGB(60, 58, 55))
	end

	------------------------------------------------------------------ Dachhimmel
	-- Sonnenblenden mit Make-up-Spiegel-Klappe
	for _, side in { -1, 1 } do
		local visor = CFrame.new(side * 1.45, GLASS_TOP - 0.13, ROOF_FRONT + 0.45) * CFrame.Angles(math.rad(6), 0, 0)
		part("SunVisor", Vector3.new(1.6, 0.09, 0.85), visor, LINER, M.Fabric)
		part("VanityCover", Vector3.new(0.7, 0.02, 0.36), visor * CFrame.new(0, -0.05, 0.05), Color3.fromRGB(150, 145, 138))
		cyl("VisorRod", 1.6, 0.08, visor * CFrame.new(0, 0.02, -0.4), LINER)
		part("VisorClip", Vector3.new(0.12, 0.08, 0.18), CFrame.new(side * 0.68, GLASS_TOP - 0.06, ROOF_FRONT + 0.1), LINER)
	end
	-- Haltegriffe über den Türen
	local function grabHandle(side, z)
		part("GrabHandle", Vector3.new(0.08, 0.1, 0.8), CFrame.new(side * 2.78, GLASS_TOP - 0.38, z), DASH)
		for _, dz in { -0.38, 0.38 } do
			part("GrabMount", Vector3.new(0.12, 0.32, 0.08), CFrame.new(side * 2.82, GLASS_TOP - 0.22, z + dz), DASH)
		end
	end
	grabHandle(1, 0.6)
	grabHandle(-1, 4.3)
	grabHandle(1, 4.3)
	-- Dachkonsole mit Leselicht und Schaltern
	part("OverheadConsole", Vector3.new(1.1, 0.16, 0.9), CFrame.new(0, GLASS_TOP - 0.13, ROOF_FRONT + 0.75), DASH)
	part("GlassesHolder", Vector3.new(0.6, 0.02, 0.28), CFrame.new(0, GLASS_TOP - 0.215, ROOF_FRONT + 1.05), Color3.fromRGB(26, 26, 28))
	for i = -1, 2 do
		part("RoofButton", Vector3.new(0.1, 0.03, 0.08), CFrame.new(-0.15 + i * 0.13 - 0.06, GLASS_TOP - 0.22, ROOF_FRONT + 0.45), Color3.fromRGB(40, 40, 44))
	end
	local mapLight = part("MapLight", Vector3.new(0.5, 0.04, 0.2), CFrame.new(0, GLASS_TOP - 0.22, ROOF_FRONT + 0.72), WARM, M.Neon)
	Parts.light("SpotLight", mapLight, { Face = Enum.NormalId.Bottom, Range = 7, Angle = 90, Brightness = 0.8, Color = WARM })
	-- Deckenleuchte in der Mitte und Leselampen hinten (aus)
	part("DomeFrame", Vector3.new(1.05, 0.05, 0.65), CFrame.new(0, GLASS_TOP - 0.06, 2.4), Color3.fromRGB(150, 146, 140))
	local dome = part("DomeLight", Vector3.new(0.9, 0.08, 0.5), CFrame.new(0, GLASS_TOP - 0.08, 2.4), WARM, M.Neon)
	Parts.light("PointLight", dome, { Range = 9, Brightness = 1.1, Color = Color3.fromRGB(255, 215, 160) })
	for _, side in { -1, 1 } do
		part("RearReadingLight", Vector3.new(0.3, 0.04, 0.2), CFrame.new(side * 1.6, GLASS_TOP - 0.07, 4.6), Color3.fromRGB(200, 196, 186))
	end

	------------------------------------------------------------------ Rückspiegel und Duftbaum
	local sensor = shield * CFrame.new(0, -0.1, -shieldLength / 2 + 0.35)
	part("RainSensor", Vector3.new(0.5, 0.12, 0.3), sensor, BLACK)
	local mirrorAt = CFrame.new(0, GLASS_TOP - 0.55, ROOF_FRONT + 0.15) * CFrame.Angles(0, math.rad(-10), 0)
	beam("MirrorStem", sensor.Position, mirrorAt.Position + Vector3.new(0, 0.1, 0), 0.09, DARK)
	part("RearViewMirror", Vector3.new(1.15, 0.36, 0.14), mirrorAt, DARK)
	for _, dx in { -0.575, 0.575 } do
		cyl("MirrorEnd", 0.14, 0.36, mirrorAt * CFrame.new(dx, 0, 0) * ALONG_Z, DARK)
	end
	part("RearViewGlass", Vector3.new(1.08, 0.29, 0.03), mirrorAt * CFrame.new(0, 0, 0.07), Color3.fromRGB(80, 90, 100), Enum.Material.Glass, { Reflectance = 0.6 })
	-- Duftbaum (Tannenform) an einem Faden
	local freshener = CFrame.new(0.25, GLASS_TOP - 1.25, ROOF_FRONT + 0.15) * CFrame.Angles(0, math.rad(25), 0)
	part("FreshenerString", Vector3.new(0.02, 0.45, 0.02), CFrame.new(0.25, GLASS_TOP - 0.85, ROOF_FRONT + 0.15), Color3.fromRGB(230, 230, 230))
	for level, width in { 0.32, 0.24, 0.16 } do
		part("AirFreshener", Vector3.new(width, 0.13, 0.015), freshener * CFrame.new(0, -0.12 + level * 0.11, 0), Color3.fromRGB(40, 120, 60))
	end
	part("AirFreshener", Vector3.new(0.06, 0.1, 0.015), freshener * CFrame.new(0, -0.11, 0), Color3.fromRGB(40, 120, 60))

	model.WorldPivot = CFrame.new()
	model.Parent = parent
	return model
end

return CutsceneCar
