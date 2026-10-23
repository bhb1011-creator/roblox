-- Detailliertes Auto für die Zwischensequenz. Wird als Vorlage in ReplicatedStorage
-- gelegt; jeder Spieler bewegt eine eigene Kopie, damit die Fahrt flüssig aussieht.
-- Alle Teile hängen per Schweißnaht an "Root"; Lenkrad und Räder haben eigene
-- Gelenke ("SteeringWeld", "WheelWeld"), die der Client dreht.
-- Vorne ist -Z, der Fahrer sitzt links (-X). Boden unter der Fahrzeugmitte = Ursprung.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.Parts)

local CutsceneCar = {}

local PAINT = Color3.fromRGB(38, 52, 72)
local DARK = Color3.fromRGB(20, 20, 23)
local TRIM = Color3.fromRGB(38, 38, 42)
local CHROME = Color3.fromRGB(180, 182, 188)
local GLASS = Color3.fromRGB(70, 85, 100)
local INTERIOR = Color3.fromRGB(46, 42, 40)
local DASH = Color3.fromRGB(32, 31, 33)
local LINER = Color3.fromRGB(175, 170, 162)

local LENGTH, WIDTH = 15, 6.8
local SILL, GLASS_BOTTOM, GLASS_TOP = 2.9, 3.3, 5.8
local ROOF_FRONT, ROOF_BACK = -0.8, 6.8
local WHEEL_Z = 4.9

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
			Parent = model,
		}
		for key, value in extra or {} do
			props[key] = value
		end
		local className = props.ClassName or "Part"
		props.ClassName = nil
		local created = Parts.new(className, props)
		created.Anchored = false
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
	local function beam(name, from, to, thickness, color, material)
		local created = part(name, Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material)
		return created
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
	part("Floor", Vector3.new(WIDTH, 0.4, LENGTH), CFrame.new(0, 0.9, 0), TRIM)
	part("EngineBay", Vector3.new(WIDTH, SILL - 0.7, 4.3), CFrame.new(0, (SILL + 0.7) / 2, front + 2.15), PAINT, nil, paint)
	wedge("Hood", Vector3.new(WIDTH - 0.2, GLASS_BOTTOM - SILL, 4.3), CFrame.new(0, (SILL + GLASS_BOTTOM) / 2, front + 2.15), PAINT, nil, paint)
	part("Trunk", Vector3.new(WIDTH, GLASS_BOTTOM - 0.7, back - 5.9), CFrame.new(0, (GLASS_BOTTOM + 0.7) / 2, (5.9 + back) / 2), PAINT, nil, paint)
	part("Firewall", Vector3.new(WIDTH - 0.8, 2.4, 0.3), CFrame.new(0, 2.1, front + 4.4), DASH)
	for _, side in { -1, 1 } do
		local x = side * (WIDTH / 2 - 0.2)
		-- Türen (außen Lack, innen Verkleidung)
		part("Door", Vector3.new(0.4, GLASS_BOTTOM - 0.7, back - 1.6 - (front + 4.3)), CFrame.new(x, (GLASS_BOTTOM + 0.7) / 2, (front + 4.3 + back - 1.6) / 2), PAINT, nil, paint)
		part("DoorPanel", Vector3.new(0.1, 1.5, 7.4), CFrame.new(side * (WIDTH / 2 - 0.45), 2.55, 1.1), INTERIOR, Enum.Material.Fabric)
		part("Armrest", Vector3.new(0.35, 0.22, 2.2), CFrame.new(side * (WIDTH / 2 - 0.6), 2.85, 0.4), DASH)
		part("InnerHandle", Vector3.new(0.08, 0.15, 0.5), CFrame.new(side * (WIDTH / 2 - 0.52), 3.15, -1.2), CHROME, Enum.Material.Metal)
		part("WindowSwitch", Vector3.new(0.2, 0.06, 0.35), CFrame.new(side * (WIDTH / 2 - 0.6), 2.98, 0.9), Color3.fromRGB(15, 15, 15))
		part("Speaker", Vector3.new(0.08, 0.8, 0.8), CFrame.new(side * (WIDTH / 2 - 0.5), 1.6, -1.6) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(28, 28, 30), Enum.Material.Fabric, { Shape = Enum.PartType.Cylinder })
		part("DoorPocket", Vector3.new(0.3, 0.5, 2.6), CFrame.new(side * (WIDTH / 2 - 0.6), 1.5, 1.4), DASH)

		-- Scheiben, Säulen und Zierleisten
		part("SideWindow", Vector3.new(0.12, GLASS_TOP - GLASS_BOTTOM, ROOF_BACK - ROOF_FRONT), CFrame.new(x, (GLASS_BOTTOM + GLASS_TOP) / 2, (ROOF_FRONT + ROOF_BACK) / 2), GLASS, Enum.Material.Glass, glass)
		beam("APillar", Vector3.new(x, GLASS_BOTTOM, ROOF_FRONT - 2.4), Vector3.new(x, GLASS_TOP, ROOF_FRONT), 0.32, PAINT)
		beam("APillarTrim", Vector3.new(side * (WIDTH / 2 - 0.45), GLASS_BOTTOM, ROOF_FRONT - 2.3), Vector3.new(side * (WIDTH / 2 - 0.45), GLASS_TOP - 0.05, ROOF_FRONT + 0.05), 0.3, LINER)
		part("BPillar", Vector3.new(0.4, GLASS_TOP - GLASS_BOTTOM, 0.5), CFrame.new(side * (WIDTH / 2 - 0.3), (GLASS_BOTTOM + GLASS_TOP) / 2, 2.6), DARK)
		part("DPillar", Vector3.new(0.3, GLASS_TOP - GLASS_BOTTOM, 0.6), CFrame.new(x, (GLASS_BOTTOM + GLASS_TOP) / 2, ROOF_BACK - 0.3), PAINT, nil, paint)
		part("WindowTrim", Vector3.new(0.15, 0.12, ROOF_BACK - ROOF_FRONT), CFrame.new(side * (WIDTH / 2 - 0.1), GLASS_BOTTOM + 0.05, (ROOF_FRONT + ROOF_BACK) / 2), CHROME, Enum.Material.Metal)
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
		part("Indicator", Vector3.new(0.4, 0.25, 0.1), CFrame.new(side * 3.15, 2.45, front - 0.02), Color3.fromRGB(255, 150, 40), Enum.Material.Neon)
		local taillight = part("Taillight", Vector3.new(1.3, 0.45, 0.1), CFrame.new(side * 2.5, 2.5, back + 0.02), Color3.fromRGB(210, 20, 20), Enum.Material.Neon)
		Parts.light("PointLight", taillight, { Range = 7, Brightness = 0.8, Color = Color3.fromRGB(255, 40, 30) })
	end

	part("Roof", Vector3.new(WIDTH - 0.4, 0.3, ROOF_BACK - ROOF_FRONT), CFrame.new(0, GLASS_TOP + 0.15, (ROOF_FRONT + ROOF_BACK) / 2), PAINT, nil, paint)
	part("RoofLiner", Vector3.new(WIDTH - 0.8, 0.06, ROOF_BACK - ROOF_FRONT - 0.2), CFrame.new(0, GLASS_TOP - 0.03, (ROOF_FRONT + ROOF_BACK) / 2), LINER, Enum.Material.Fabric)
	for _, x in { -2.5, 2.5 } do
		part("RoofRail", Vector3.new(0.15, 0.2, 6), CFrame.new(x, GLASS_TOP + 0.4, 3), TRIM, Enum.Material.Metal)
	end
	wedge("Windshield", Vector3.new(WIDTH - 0.6, GLASS_TOP - GLASS_BOTTOM, 2.4), CFrame.new(0, (GLASS_BOTTOM + GLASS_TOP) / 2, ROOF_FRONT - 1.2), GLASS, Enum.Material.Glass, { Transparency = 0.7, Reflectance = 0.05 })
	part("RearWindow", Vector3.new(WIDTH - 0.6, GLASS_TOP - GLASS_BOTTOM, 0.12), CFrame.new(0, (GLASS_BOTTOM + GLASS_TOP) / 2, ROOF_BACK), GLASS, Enum.Material.Glass, glass)
	part("FrontBumper", Vector3.new(WIDTH + 0.2, 0.7, 0.5), CFrame.new(0, 1.1, front - 0.2), TRIM)
	part("RearBumper", Vector3.new(WIDTH + 0.2, 0.7, 0.5), CFrame.new(0, 1.1, back + 0.2), TRIM)
	part("Grille", Vector3.new(3.2, 0.7, 0.08), CFrame.new(0, 2.1, front - 0.03), DARK, Enum.Material.Metal)
	part("GrilleBar", Vector3.new(3.2, 0.1, 0.1), CFrame.new(0, 2.1, front - 0.07), CHROME, Enum.Material.Metal)
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
				part("RimSpoke", Vector3.new(1.16, 0.18, 1.3), center * CFrame.Angles(spoke / 5 * math.pi, 0, 0), Color3.fromRGB(120, 122, 128), Enum.Material.Metal, nil, axle)
			end
			part("WheelArch", Vector3.new(0.2, 0.45, 3.1), CFrame.new(side * (WIDTH / 2 + 0.05), 2.55, z), TRIM)
		end
	end

	------------------------------------------------------------------ Armaturenbrett
	part("Dashboard", Vector3.new(WIDTH - 0.8, 0.9, 1.6), CFrame.new(0, 3.65, ROOF_FRONT - 1.7), DASH)
	part("DashTop", Vector3.new(WIDTH - 0.8, 0.12, 1.2), CFrame.new(0, 4.12, ROOF_FRONT - 1.95), Color3.fromRGB(26, 25, 27), Enum.Material.Fabric)
	part("DashLowerDriver", Vector3.new(2.6, 0.9, 0.5), CFrame.new(-1.6, 2.9, ROOF_FRONT - 1.0), DASH)
	part("GloveBox", Vector3.new(2.4, 0.8, 0.5), CFrame.new(1.6, 3.0, ROOF_FRONT - 1.0), DASH)
	part("GloveBoxLine", Vector3.new(2.2, 0.04, 0.05), CFrame.new(1.6, 3.35, ROOF_FRONT - 0.74), Color3.fromRGB(12, 12, 12))
	part("ClusterHood", Vector3.new(2.1, 0.32, 0.9), CFrame.new(-1.35, 4.28, ROOF_FRONT - 1.3), Color3.fromRGB(22, 22, 24))

	-- Tacho und Drehzahlmesser (die Nadeln bewegt der Client)
	local cluster = part("Cluster", Vector3.new(1.9, 0.72, 0.05), CFrame.new(-1.35, 3.95, ROOF_FRONT - 0.88), Color3.fromRGB(8, 8, 10))
	local clusterGui = Parts.surfaceGui(cluster, Enum.NormalId.Back, true)
	clusterGui.PixelsPerStud = 160
	for i, info in { { "Speed", 0.27, "km/h" }, { "Rpm", 0.73, "x1000" } } do
		local dial = Instance.new("Frame")
		dial.Name = info[1] .. "Dial"
		dial.AnchorPoint = Vector2.new(0.5, 0.5)
		dial.Position = UDim2.fromScale(info[2], 0.5)
		dial.Size = UDim2.fromScale(0.36, 0.92)
		dial.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
		dial.Parent = clusterGui
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = dial
		local ring = Instance.new("UIStroke")
		ring.Color = Color3.fromRGB(255, 150, 60)
		ring.Thickness = 3
		ring.Parent = dial
		local needle = Instance.new("Frame")
		needle.Name = info[1] .. "Needle"
		needle.AnchorPoint = Vector2.new(0.5, 1)
		needle.Position = UDim2.fromScale(0.5, 0.5)
		needle.Size = UDim2.fromScale(0.04, 0.42)
		needle.BackgroundColor3 = Color3.fromRGB(255, 80, 40)
		needle.BorderSizePixel = 0
		needle.Rotation = -120
		needle.Parent = dial
		Parts.text(dial, {
			Name = info[1] .. "Text",
			Text = i == 1 and "0" or "",
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.fromRGB(240, 235, 225),
			Size = UDim2.fromScale(0.5, 0.2),
			Position = UDim2.fromScale(0.25, 0.62),
		})
		Parts.text(dial, {
			Text = info[3],
			Font = Enum.Font.Gotham,
			TextColor3 = Color3.fromRGB(170, 165, 155),
			Size = UDim2.fromScale(0.4, 0.12),
			Position = UDim2.fromScale(0.3, 0.8),
		})
	end
	Parts.light("PointLight", cluster, { Range = 3, Brightness = 0.6, Color = Color3.fromRGB(255, 170, 90) })

	-- Mittelkonsole: Radio, Lüftungen, Warnblinker, Regler
	part("CenterStack", Vector3.new(1.6, 1.7, 0.4), CFrame.new(0, 3.15, ROOF_FRONT - 0.95), DASH)
	local radio = part("RadioDisplay", Vector3.new(1.2, 0.35, 0.05), CFrame.new(0, 3.65, ROOF_FRONT - 0.73), Color3.fromRGB(8, 10, 12))
	local radioGui = Parts.surfaceGui(radio, Enum.NormalId.Back, true)
	radioGui.PixelsPerStud = 160
	Parts.text(radioGui, {
		Name = "RadioText",
		Text = "FM 98.4  RADIO WALDFUNK   18:47",
		Font = Enum.Font.Code,
		TextColor3 = Color3.fromRGB(120, 220, 255),
		Size = UDim2.fromScale(0.94, 0.7),
		Position = UDim2.fromScale(0.03, 0.15),
	})
	Parts.light("PointLight", radio, { Range = 2.5, Brightness = 0.4, Color = Color3.fromRGB(120, 200, 255) })
	for _, x in { -0.45, 0.45 } do
		part("Vent", Vector3.new(0.5, 0.3, 0.05), CFrame.new(x, 4.0, ROOF_FRONT - 0.73), Color3.fromRGB(12, 12, 13))
		for slat = -1, 1 do
			part("VentSlat", Vector3.new(0.48, 0.03, 0.06), CFrame.new(x, 4.0 + slat * 0.08, ROOF_FRONT - 0.71), Color3.fromRGB(55, 55, 58))
		end
	end
	for _, x in { -2.55, 2.55 } do
		part("SideVent", Vector3.new(0.5, 0.3, 0.05), CFrame.new(x, 3.95, ROOF_FRONT - 0.85), Color3.fromRGB(12, 12, 13))
	end
	part("HazardButton", Vector3.new(0.18, 0.18, 0.05), CFrame.new(0, 3.4, ROOF_FRONT - 0.73), Color3.fromRGB(190, 30, 30), Enum.Material.Neon)
	for i = -1, 1 do
		part("Knob", Vector3.new(0.08, 0.22, 0.22), CFrame.new(i * 0.4, 2.85, ROOF_FRONT - 0.73) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(60, 60, 64), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	end

	-- Konsole zwischen den Sitzen mit Schaltknüppel, Handbremse und Becherhaltern
	part("Console", Vector3.new(1.1, 0.8, 3.4), CFrame.new(0, 1.5, 0.5), DASH)
	part("ShifterBoot", Vector3.new(0.45, 0.3, 0.45), CFrame.new(0, 2.05, -0.3), Color3.fromRGB(18, 18, 18), Enum.Material.Fabric)
	part("ShifterStick", Vector3.new(0.12, 0.6, 0.12), CFrame.new(0, 2.45, -0.3), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
	part("ShifterKnob", Vector3.new(0.32, 0.32, 0.32), CFrame.new(0, 2.8, -0.3), Color3.fromRGB(25, 25, 25), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball })
	part("Handbrake", Vector3.new(0.16, 0.16, 1), CFrame.new(0, 2.05, 0.9) * CFrame.Angles(math.rad(12), 0, 0), Color3.fromRGB(28, 28, 28))
	for _, z in { 0.15, 0.55 } do
		part("CupHolder", Vector3.new(0.05, 0.4, 0.4), CFrame.new(0.3, 1.92, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(10, 10, 10), nil, { Shape = Enum.PartType.Cylinder })
	end
	part("Armrest", Vector3.new(1.1, 0.25, 1.4), CFrame.new(0, 2.05, 1.8), INTERIOR, Enum.Material.Fabric)

	-- Pedale
	for i, x in { -1.9, -1.45, -1.0 } do
		part("Pedal", Vector3.new(0.3, 0.45, 0.08), CFrame.new(x, 1.45, ROOF_FRONT - 1.9) * CFrame.Angles(math.rad(-20), 0, 0), i == 3 and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	end

	------------------------------------------------------------------ Lenkrad (dreht sich)
	local steeringBase = CFrame.new(-1.35, 4.05, ROOF_FRONT - 0.15) * CFrame.Angles(math.rad(-25), 0, 0)
	local hub, steeringWeld = joint("SteeringHub", steeringBase, "SteeringWeld")
	part("SteeringColumn", Vector3.new(0.3, 0.3, 1.1), steeringBase * CFrame.new(0, 0, -0.6), Color3.fromRGB(22, 22, 24))
	local radius, segments = 0.72, 20
	for i = 0, segments - 1 do
		local angle = i / segments * math.pi * 2
		part("WheelRim", Vector3.new(0.17, 2 * math.pi * radius / segments + 0.03, 0.17), steeringBase * CFrame.Angles(0, 0, angle) * CFrame.new(radius, 0, 0), Color3.fromRGB(24, 24, 26), Enum.Material.SmoothPlastic, nil, hub)
	end
	for _, angle in { 0, math.pi, -math.pi / 2 } do
		part("WheelSpoke", Vector3.new(radius, 0.14, 0.1), steeringBase * CFrame.Angles(0, 0, angle) * CFrame.new(radius / 2, 0, 0.02), Color3.fromRGB(30, 30, 33), nil, nil, hub)
	end
	part("WheelHub", Vector3.new(0.1, 0.42, 0.42), steeringBase * CFrame.new(0, 0, 0.05) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(35, 35, 38), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder }, hub)
	part("WheelLogo", Vector3.new(0.12, 0.16, 0.16), steeringBase * CFrame.new(0, 0, 0.08) * CFrame.Angles(0, math.rad(90), 0), CHROME, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder }, hub)
	steeringWeld:SetAttribute("IsSteering", true)

	------------------------------------------------------------------ Sitze, Gurte, Rückbank
	for _, side in { -1, 1 } do
		local x = side * 1.35
		part("SeatCushion", Vector3.new(2, 0.45, 2), CFrame.new(x, 1.6, 1.2), INTERIOR, Enum.Material.Fabric)
		part("SeatBase", Vector3.new(1.6, 0.4, 1.6), CFrame.new(x, 1.2, 1.2), DARK)
		part("SeatBack", Vector3.new(2, 2.9, 0.45), CFrame.new(x, 3.15, 2.35) * CFrame.Angles(math.rad(-10), 0, 0), INTERIOR, Enum.Material.Fabric)
		for _, bx in { -0.9, 0.9 } do
			part("SeatBolster", Vector3.new(0.3, 2.5, 0.55), CFrame.new(x + bx, 3.0, 2.3) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(38, 35, 33), Enum.Material.Fabric)
		end
		part("Headrest", Vector3.new(1.1, 0.7, 0.4), CFrame.new(x, 4.95, 2.65), INTERIOR, Enum.Material.Fabric)
		part("HeadrestPost", Vector3.new(0.6, 0.3, 0.08), CFrame.new(x, 4.55, 2.62), CHROME, Enum.Material.Metal)
		beam("SeatBelt", Vector3.new(side * 2.85, 5.2, 2.55), Vector3.new(side * 0.55, 1.95, 1.7), 0.1, Color3.fromRGB(28, 28, 30), Enum.Material.Fabric)
		part("BeltBuckle", Vector3.new(0.2, 0.35, 0.2), CFrame.new(side * 0.55, 1.95, 1.7), Color3.fromRGB(150, 150, 155), Enum.Material.Metal)
		part("FloorMat", Vector3.new(2, 0.04, 2.2), CFrame.new(x, 1.12, -0.9), Color3.fromRGB(25, 25, 25), Enum.Material.Fabric)
		part("SunVisor", Vector3.new(1.8, 0.08, 0.9), CFrame.new(x, GLASS_TOP - 0.15, ROOF_FRONT + 0.4) * CFrame.Angles(math.rad(8), 0, 0), LINER, Enum.Material.Fabric)
	end
	part("RearBench", Vector3.new(WIDTH - 1, 0.5, 1.8), CFrame.new(0, 1.65, 4.4), INTERIOR, Enum.Material.Fabric)
	part("RearBenchBack", Vector3.new(WIDTH - 1, 2.6, 0.4), CFrame.new(0, 3.1, 5.6) * CFrame.Angles(math.rad(-8), 0, 0), INTERIOR, Enum.Material.Fabric)
	for _, x in { -1.8, 0, 1.8 } do
		part("RearHeadrest", Vector3.new(1, 0.6, 0.35), CFrame.new(x, 4.65, 5.85), INTERIOR, Enum.Material.Fabric)
	end

	------------------------------------------------------------------ Rückspiegel, Duftbaum, Innenlicht
	part("MirrorStem", Vector3.new(0.1, 0.4, 0.1), CFrame.new(0, GLASS_TOP - 0.25, ROOF_FRONT + 0.1), DARK)
	part("RearViewMirror", Vector3.new(1.1, 0.35, 0.12), CFrame.new(0, GLASS_TOP - 0.55, ROOF_FRONT + 0.15), DARK)
	part("RearViewGlass", Vector3.new(1, 0.28, 0.03), CFrame.new(0, GLASS_TOP - 0.55, ROOF_FRONT + 0.22), Color3.fromRGB(80, 90, 100), Enum.Material.Glass, { Reflectance = 0.6 })
	part("FreshenerString", Vector3.new(0.02, 0.35, 0.02), CFrame.new(0.2, GLASS_TOP - 0.9, ROOF_FRONT + 0.15), Color3.fromRGB(230, 230, 230))
	part("AirFreshener", Vector3.new(0.28, 0.42, 0.03), CFrame.new(0.2, GLASS_TOP - 1.28, ROOF_FRONT + 0.15) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(40, 120, 60))
	local dome = part("DomeLight", Vector3.new(0.9, 0.08, 0.5), CFrame.new(0, GLASS_TOP - 0.07, 2.4), Color3.fromRGB(200, 195, 185))
	part("MapLight", Vector3.new(0.6, 0.06, 0.3), CFrame.new(0, GLASS_TOP - 0.07, ROOF_FRONT + 0.6), Color3.fromRGB(200, 195, 185))
	Parts.light("PointLight", dome, { Range = 6, Brightness = 0.25, Color = Color3.fromRGB(255, 220, 170) })

	model.WorldPivot = CFrame.new()
	model.Parent = parent
	return model
end

return CutsceneCar
