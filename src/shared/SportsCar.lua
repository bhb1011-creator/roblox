-- Sportwagen (Shop: Golden Pack / Sarp VIP Pack oder 3000 Münzen / 399 R$).
-- Flach und breit, mit echten Radhäusern, LED-Scheinwerfern, Heckflügel, Diffusor, vier
-- Auspuffrohren, großen Felgen mit roten Bremssätteln und einem Innenraum mit Schalensitzen.
--
--   SportsCar.build(parent, cframe, options) -> Model
--     options.paint  = Lackfarbe (Standard: glänzendes Schwarz)
--     options.accent = Zierfarbe (Standard: Gold)
--     options.plate  = Kennzeichen (Standard: "VIP 1")
-- Vorne ist -Z, der Fahrer sitzt links (-X). Boden = y 0 des CFrames. Alle Teile sind verankert.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.Parts)

local SportsCar = {}

local M = Enum.Material
local ALONG_Y = CFrame.Angles(0, 0, math.rad(90))
local ALONG_Z = CFrame.Angles(0, math.rad(90), 0)

local CARBON = Color3.fromRGB(24, 24, 27)
local BLACK = Color3.fromRGB(10, 10, 11)
local TIRE = Color3.fromRGB(22, 22, 22)
local CHROME = Color3.fromRGB(190, 192, 198)
local GLASS = Color3.fromRGB(30, 36, 44)
local LEATHER = Color3.fromRGB(26, 24, 24)
local RED = Color3.fromRGB(200, 20, 24)
local LED = Color3.fromRGB(235, 245, 255)

local W, L = 7.2, 15.5 -- Breite, Länge
local HALF = W / 2
local CORE = 2.4 -- halbe Breite des Rumpfes zwischen den Radhäusern
local BELT = 2.45 -- Oberkante Karosserie (Gürtellinie)
local ROOF = 3.95
local FRONT, BACK = -L / 2, L / 2
local WHEEL_FRONT, WHEEL_BACK = -4.9, 4.6
local WHEEL_R = 1.25

function SportsCar.build(parent, cframe, options)
	options = options or {}
	local PAINT = options.paint or Color3.fromRGB(14, 14, 16)
	local ACCENT = options.accent or Color3.fromRGB(212, 168, 70)
	local origin = cframe or CFrame.new()

	local model = Instance.new("Model")
	model.Name = "SportsCar"

	local function part(name, size, offset, color, material, extra)
		local props = {
			Name = name,
			Size = size,
			CFrame = origin * offset,
			Color = color,
			Material = material or M.SmoothPlastic,
			CanTouch = false,
			Parent = model,
		}
		for key, value in extra or {} do
			props[key] = value
		end
		local className = props.ClassName or "Part"
		props.ClassName = nil
		local created = Parts.new(className, props)
		if math.max(size.X, size.Y, size.Z) < 1 then
			created.CastShadow = false
		end
		return created
	end
	local function wedge(name, size, offset, color, material, extra)
		local props = { ClassName = "WedgePart" }
		for key, value in extra or {} do
			props[key] = value
		end
		return part(name, size, offset, color, material, props)
	end
	local function cyl(name, length, diameter, offset, color, material, extra)
		local props = { Shape = Enum.PartType.Cylinder }
		for key, value in extra or {} do
			props[key] = value
		end
		return part(name, Vector3.new(length, diameter, diameter), offset, color, material, props)
	end
	-- dünne Platte zwischen zwei Punkten (für schräge Scheiben)
	local function plate(name, width, from, to, thickness, color, material, extra)
		local length = (to - from).Magnitude
		return part(name, Vector3.new(width, thickness, length), CFrame.lookAt((from + to) / 2, to), color, material, extra), length
	end
	local function beam(name, from, to, thickness, color, material)
		return part(name, Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material)
	end

	local paint = { Reflectance = 0.18 }
	local glass = { Transparency = 0.35, Reflectance = 0.25 }

	------------------------------------------------------------------ Rumpf
	-- Mitte (zwischen den Radhäusern), vorne als flache, schräge Nase
	wedge("Nose", Vector3.new(CORE * 2, BELT - 1.0, 2.55), CFrame.new(0, (BELT + 1.0) / 2, FRONT + 1.275), PAINT, nil, paint)
	part("Hood", Vector3.new(CORE * 2, BELT - 1.0, 2.6), CFrame.new(0, (BELT + 1.0) / 2, -3.9), PAINT, nil, paint)
	part("RearDeck", Vector3.new(CORE * 2, BELT - 1.0, 3.7), CFrame.new(0, (BELT + 1.0) / 2, 4.25), PAINT, nil, paint)
	part("Tail", Vector3.new(W, BELT - 1.0, BACK - 6.1), CFrame.new(0, (BELT + 1.0) / 2, (6.1 + BACK) / 2), PAINT, nil, paint)
	part("Underbody", Vector3.new(CORE * 2 - 0.2, 0.45, L - 1.2), CFrame.new(0, 0.78, 0), CARBON)
	part("CabinFloor", Vector3.new(CORE * 2, 0.2, 5.0), CFrame.new(0, 1.1, -0.1), CARBON)

	for _, side in { -1, 1 } do
		local band = side * (CORE + (HALF - CORE) / 2) -- Mitte des äußeren Streifens
		local bandWidth = HALF - CORE
		-- vordere Ecke (schräg wie die Nase)
		wedge("FrontCorner", Vector3.new(bandWidth, 1.25, 1.35), CFrame.new(band, 1.0 + 0.625, FRONT + 0.675), PAINT, nil, paint)
		-- ausgestellte Kotflügel über den Rädern (höher als die Haube = breite Schultern)
		for _, wheelZ in { WHEEL_FRONT, WHEEL_BACK } do
			local rear = wheelZ > 0
			local top = rear and 2.95 or 2.8
			part("Fender", Vector3.new(bandWidth, top - 2.45, 3.0), CFrame.new(band, (top + 2.45) / 2, wheelZ), PAINT, nil, paint)
			part("FenderArch", Vector3.new(bandWidth, 0.12, 3.0), CFrame.new(band, 2.5, wheelZ), BLACK)
			-- Radhaus innen dunkel
			part("WheelHouse", Vector3.new(0.08, 1.6, 3.0), CFrame.new(side * (CORE + 0.02), 1.7, wheelZ), BLACK)
			-- weiche Rampen vor und hinter dem Kotflügel
			wedge("FenderRamp", Vector3.new(bandWidth, top - 2.45, 0.7), CFrame.new(band, (top + 2.45) / 2, wheelZ - 1.85), PAINT, nil, paint)
			wedge("FenderRamp", Vector3.new(bandWidth, top - 2.45, 0.7), CFrame.new(band, (top + 2.45) / 2, wheelZ + 1.85) * CFrame.Angles(0, math.pi, 0), PAINT, nil, paint)
		end
		-- Türen zwischen den Rädern
		local doorFrom, doorTo = WHEEL_FRONT + 1.5, WHEEL_BACK - 1.5
		part("Door", Vector3.new(bandWidth, BELT - 1.0, doorTo - doorFrom), CFrame.new(band, (BELT + 1.0) / 2, (doorFrom + doorTo) / 2), PAINT, nil, paint)
		part("DoorGap", Vector3.new(0.03, BELT - 1.2, 0.05), CFrame.new(side * (HALF + 0.005), (BELT + 1.1) / 2, -2.7), BLACK)
		part("DoorGap", Vector3.new(0.03, BELT - 1.2, 0.05), CFrame.new(side * (HALF + 0.005), (BELT + 1.1) / 2, 1.9), BLACK)
		part("DoorHandle", Vector3.new(0.04, 0.08, 0.55), CFrame.new(side * (HALF + 0.02), 2.2, 1.4), ACCENT, M.Metal)
		-- Lufteinlass hinter der Tür mit Lamellen
		part("SideIntake", Vector3.new(0.04, 0.7, 1.0), CFrame.new(side * (HALF + 0.01), 1.75, 2.45), BLACK)
		for i = -1, 1 do
			part("IntakeSlat", Vector3.new(0.06, 0.04, 1.0), CFrame.new(side * (HALF + 0.03), 1.75 + i * 0.2, 2.45), CARBON)
		end
		-- hinterer Teil und Ecke
		part("RearQuarter", Vector3.new(bandWidth, BELT - 1.0, 6.1 - (WHEEL_BACK + 1.5)), CFrame.new(band, (BELT + 1.0) / 2, (WHEEL_BACK + 1.5 + 6.1) / 2), PAINT, nil, paint)
		part("FrontQuarter", Vector3.new(bandWidth, BELT - 1.0, (WHEEL_FRONT - 1.5) - (FRONT + 1.35)), CFrame.new(band, (BELT + 1.0) / 2, (FRONT + 1.35 + WHEEL_FRONT - 1.5) / 2), PAINT, nil, paint)
		-- Seitenschweller aus Karbon mit goldener Zierleiste
		part("SideSkirt", Vector3.new(bandWidth + 0.1, 0.38, doorTo - doorFrom), CFrame.new(band + side * 0.05, 0.82, (doorFrom + doorTo) / 2), CARBON)
		part("SkirtAccent", Vector3.new(0.03, 0.05, doorTo - doorFrom - 0.4), CFrame.new(side * (HALF + 0.11), 0.95, (doorFrom + doorTo) / 2), ACCENT, M.Metal)
		-- Außenspiegel (aerodynamisch, auf einem Arm)
		beam("MirrorArm", Vector3.new(side * (HALF - 0.1), 2.55, -2.2), Vector3.new(side * (HALF + 0.35), 2.85, -2.1), 0.1, CARBON)
		part("Mirror", Vector3.new(0.55, 0.32, 0.6), CFrame.new(side * (HALF + 0.4), 2.9, -2.05), PAINT, nil, paint)
		part("MirrorGlass", Vector3.new(0.45, 0.24, 0.03), CFrame.new(side * (HALF + 0.4), 2.9, -1.74), Color3.fromRGB(90, 100, 110), M.Glass, { Reflectance = 0.6 })
	end

	------------------------------------------------------------------ Glashaus
	local shieldFrom = Vector3.new(0, BELT, -2.6)
	local shieldTo = Vector3.new(0, ROOF, -0.4)
	plate("Windshield", CORE * 2 + 1.2, shieldFrom, shieldTo, 0.08, GLASS, M.Glass, glass)
	part("Roof", Vector3.new(CORE * 2 + 1.2, 0.15, 2.6), CFrame.new(0, ROOF + 0.07, 0.9), PAINT, nil, paint)
	part("RoofAccent", Vector3.new(0.08, 0.04, 2.6), CFrame.new(0, ROOF + 0.16, 0.9), ACCENT, M.Metal)
	-- flaches Fließheck aus Glas über dem Motor
	local rearFrom = Vector3.new(0, ROOF, 2.2)
	local rearTo = Vector3.new(0, 2.55, 5.6)
	plate("RearGlass", CORE * 2 + 1.0, rearFrom, rearTo, 0.08, GLASS, M.Glass, glass)
	for i = 1, 5 do
		local t = i / 6
		local at = rearFrom:Lerp(rearTo, t)
		part("EngineSlat", Vector3.new(CORE * 2 - 0.4, 0.04, 0.12), CFrame.lookAt(at, at + (rearTo - rearFrom)) * CFrame.new(0, 0.07, 0), BLACK)
	end
	for _, side in { -1, 1 } do
		local x = side * (HALF - 0.6)
		-- Seitenscheiben: vorne schräg, Mitte, hinten schräg
		wedge("SideGlassFront", Vector3.new(0.08, ROOF - BELT, 2.2), CFrame.new(x, (ROOF + BELT) / 2, -1.5), GLASS, M.Glass, glass)
		part("SideGlass", Vector3.new(0.08, ROOF - BELT, 2.6), CFrame.new(x, (ROOF + BELT) / 2, 0.9), GLASS, M.Glass, glass)
		wedge("SideGlassRear", Vector3.new(0.08, ROOF - BELT, 3.4), CFrame.new(x, (ROOF + BELT) / 2, 3.9) * CFrame.Angles(0, math.pi, 0), GLASS, M.Glass, glass)
		beam("APillar", Vector3.new(x, BELT, -2.6), Vector3.new(x, ROOF, -0.4), 0.18, BLACK)
		beam("CPillar", Vector3.new(x, ROOF, 2.2), Vector3.new(x, 2.55, 5.6), 0.2, PAINT)
		part("RoofRail", Vector3.new(0.18, 0.18, 2.6), CFrame.new(x, ROOF, 0.9), BLACK)
		part("WindowTrim", Vector3.new(0.06, 0.06, 6.0), CFrame.new(side * (HALF - 0.55), BELT + 0.02, 0.4), ACCENT, M.Metal)
	end

	------------------------------------------------------------------ Front
	-- Scheinwerfer: schmal und schräg auf der Nase, LED-Streifen und Tagfahrlicht
	local noseSlope = math.atan((BELT - 1.0) / 2.55)
	for _, side in { -1, 1 } do
		local at = CFrame.new(side * 1.7, 1.0 + (BELT - 1.0) * (1.25 / 2.55) + 0.05, FRONT + 1.3) * CFrame.Angles(-noseSlope, 0, 0)
		part("HeadlightHousing", Vector3.new(1.6, 0.06, 0.55), at, BLACK, nil, { Reflectance = 0.2 })
		local light = part("Headlight", Vector3.new(1.3, 0.05, 0.1), at * CFrame.new(0, 0.03, -0.12), LED, M.Neon)
		Parts.light("SpotLight", light, { Face = Enum.NormalId.Front, Range = 30, Angle = 50, Brightness = 1.5, Color = LED })
		part("DRL", Vector3.new(1.45, 0.05, 0.04), at * CFrame.new(0, 0.03, 0.18), LED, M.Neon)
		-- große Lufteinlässe vorne
		part("FrontIntake", Vector3.new(1.4, 0.5, 0.05), CFrame.new(side * 2.3, 1.3, FRONT + 0.02), BLACK)
		for i = 0, 2 do
			part("IntakeFin", Vector3.new(0.05, 0.5, 0.12), CFrame.new(side * (1.85 + i * 0.45), 1.3, FRONT + 0.03), CARBON)
		end
		-- Lüftungsschlitze auf der Haube
		for i = 0, 3 do
			part("HoodVent", Vector3.new(0.9, 0.03, 0.08), CFrame.new(side * 1.0, BELT + 0.01, -4.6 + i * 0.22), BLACK)
		end
	end
	part("Grille", Vector3.new(2.0, 0.42, 0.05), CFrame.new(0, 1.25, FRONT + 0.02), BLACK)
	for i = -3, 3 do
		part("GrilleBar", Vector3.new(0.04, 0.4, 0.08), CFrame.new(i * 0.28, 1.25, FRONT + 0.01), CARBON)
	end
	part("GrilleFrame", Vector3.new(2.1, 0.05, 0.08), CFrame.new(0, 1.48, FRONT + 0.01), ACCENT, M.Metal)
	cyl("Badge", 0.04, 0.32, CFrame.new(0, 1.78, FRONT + 0.6) * CFrame.Angles(-noseSlope, 0, 0) * ALONG_Y, ACCENT, M.Metal)
	part("FrontBumper", Vector3.new(W - 0.2, 0.42, 0.6), CFrame.new(0, 0.79, FRONT + 0.3), PAINT, nil, paint)
	part("Splitter", Vector3.new(W + 0.1, 0.07, 0.75), CFrame.new(0, 0.55, FRONT + 0.2), CARBON)
	part("SplitterAccent", Vector3.new(W - 0.4, 0.03, 0.04), CFrame.new(0, 0.6, FRONT - 0.17), ACCENT, M.Metal)

	------------------------------------------------------------------ Heck
	-- durchgehendes Rücklicht-Band
	part("TailBar", Vector3.new(W - 0.5, 0.12, 0.06), CFrame.new(0, 2.2, BACK + 0.02), RED, M.Neon)
	for _, side in { -1, 1 } do
		local tail = part("Taillight", Vector3.new(1.1, 0.32, 0.08), CFrame.new(side * 2.85, 2.1, BACK + 0.03), RED, M.Neon)
		Parts.light("PointLight", tail, { Range = 6, Brightness = 0.6, Color = Color3.fromRGB(255, 40, 30) })
		-- vier Auspuffrohre
		for _, x in { 0.55, 1.0 } do
			cyl("Exhaust", 0.3, 0.36, CFrame.new(side * x, 0.95, BACK + 0.1) * ALONG_Z, CHROME, M.Metal)
			cyl("ExhaustInner", 0.32, 0.26, CFrame.new(side * x, 0.95, BACK + 0.11) * ALONG_Z, BLACK)
		end
	end
	part("Diffuser", Vector3.new(W - 1.0, 0.5, 0.7), CFrame.new(0, 0.82, BACK - 0.25), CARBON)
	for i = -4, 4 do
		if math.abs(i) > 1 or i == 0 then
			part("DiffuserFin", Vector3.new(0.05, 0.45, 0.7), CFrame.new(i * 0.55, 0.85, BACK + 0.05), BLACK)
		end
	end
	local rearPlate = part("RearPlate", Vector3.new(1.8, 0.45, 0.04), CFrame.new(0, 1.55, BACK + 0.03) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(235, 235, 230))
	Parts.text(Parts.surfaceGui(rearPlate, Enum.NormalId.Front), { Text = options.plate or "VIP 1", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(20, 20, 20) })
	part("RearBadge", Vector3.new(0.9, 0.12, 0.04), CFrame.new(0, 2.45, BACK + 0.03), ACCENT, M.Metal)
	-- Heckflügel aus Karbon auf zwei Stützen, mit Seitenplatten
	part("Wing", Vector3.new(W - 0.5, 0.12, 0.95), CFrame.new(0, 3.2, BACK - 0.75) * CFrame.Angles(math.rad(-6), 0, 0), CARBON)
	part("WingAccent", Vector3.new(W - 0.6, 0.03, 0.05), CFrame.new(0, 3.27, BACK - 0.3), ACCENT, M.Metal)
	for _, side in { -1, 1 } do
		part("WingStrut", Vector3.new(0.12, 0.75, 0.35), CFrame.new(side * 1.8, 2.82, BACK - 0.8), CARBON)
		part("WingEndplate", Vector3.new(0.06, 0.45, 1.1), CFrame.new(side * (HALF - 0.25), 3.2, BACK - 0.75), CARBON)
	end

	------------------------------------------------------------------ Räder
	for _, side in { -1, 1 } do
		for _, wheelZ in { WHEEL_FRONT, WHEEL_BACK } do
			local x = side * (HALF - 0.5)
			local center = CFrame.new(x, WHEEL_R, wheelZ)
			local outer = side * 0.5 -- Außenseite des Reifens
			cyl("Tire", 1.0, WHEEL_R * 2, center, TIRE, M.Rubber)
			cyl("Rim", 0.06, 2.05, center * CFrame.new(outer + side * 0.01, 0, 0), Color3.fromRGB(40, 40, 44), M.Metal)
			cyl("RimLip", 0.07, 2.12, center * CFrame.new(outer - side * 0.01, 0, 0), ACCENT, M.Metal)
			-- Bremsscheibe und roter Bremssattel hinter den Speichen
			cyl("BrakeDisc", 0.05, 1.6, center * CFrame.new(outer + side * 0.02, 0, 0), Color3.fromRGB(120, 120, 124), M.Metal)
			part("Caliper", Vector3.new(0.2, 0.5, 0.35), center * CFrame.new(outer + side * 0.05, 0.45, 0.35) * CFrame.Angles(math.rad(35), 0, 0), RED)
			-- zehn dünne Speichen (Doppelspeichen)
			for spoke = 0, 9 do
				local angle = spoke / 10 * math.pi * 2
				part("Spoke", Vector3.new(0.06, 0.1, 0.92), center * CFrame.new(outer + side * 0.08, 0, 0) * CFrame.Angles(angle, 0, 0) * CFrame.new(0, 0, 0.5), Color3.fromRGB(205, 165, 72), M.Metal)
			end
			cyl("WheelCap", 0.1, 0.4, center * CFrame.new(outer + side * 0.1, 0, 0), BLACK, M.Metal)
			cyl("WheelLogo", 0.11, 0.22, center * CFrame.new(outer + side * 0.105, 0, 0), ACCENT, M.Metal)
		end
	end

	------------------------------------------------------------------ Innenraum
	part("Dashboard", Vector3.new(CORE * 2, 0.75, 0.9), CFrame.new(0, 2.25, -2.15), CARBON)
	part("DashLeather", Vector3.new(CORE * 2, 0.06, 0.6), CFrame.new(0, 2.64, -2.0), LEATHER, M.Leather)
	part("DashAccent", Vector3.new(CORE * 2 - 0.2, 0.04, 0.04), CFrame.new(0, 2.4, -1.69), ACCENT, M.Metal)
	-- digitales Cockpit und Mittelbildschirm
	local cluster = part("Cluster", Vector3.new(1.0, 0.35, 0.04), CFrame.new(-1.25, 2.5, -1.68) * CFrame.Angles(math.rad(-10), 0, 0), BLACK)
	local clusterGui = Parts.surfaceGui(cluster, Enum.NormalId.Back, true)
	clusterGui.PixelsPerStud = 200
	Parts.text(clusterGui, { Text = "0 km/h   ▮▮▮▮▯   D", Font = Enum.Font.GothamBold, TextColor3 = ACCENT, Size = UDim2.fromScale(0.9, 0.6), Position = UDim2.fromScale(0.05, 0.2) })
	local screen = part("CenterScreen", Vector3.new(0.9, 0.5, 0.04), CFrame.new(0, 2.25, -1.68), BLACK)
	local screenGui = Parts.surfaceGui(screen, Enum.NormalId.Back, true)
	screenGui.PixelsPerStud = 200
	Parts.text(screenGui, { Text = "SPORT+", Font = Enum.Font.GothamBlack, TextColor3 = ACCENT, Size = UDim2.fromScale(0.8, 0.4), Position = UDim2.fromScale(0.1, 0.3) })
	-- Mitteltunnel mit Wählhebel und Startknopf
	part("Tunnel", Vector3.new(0.9, 0.6, 3.8), CFrame.new(0, 1.5, -0.2), CARBON)
	part("TunnelLeather", Vector3.new(0.92, 0.05, 1.6), CFrame.new(0, 1.82, 0.9), LEATHER, M.Leather)
	part("Selector", Vector3.new(0.22, 0.3, 0.4), CFrame.new(0, 1.95, -0.5), LEATHER, M.Leather)
	cyl("StartButton", 0.05, 0.18, CFrame.new(0, 1.83, -1.2) * ALONG_Y, RED, M.Neon)
	-- Lenkrad mit flacher Unterseite
	local wheelBase = CFrame.new(-1.25, 2.4, -1.25) * CFrame.Angles(math.rad(-20), 0, 0)
	part("SteeringColumn", Vector3.new(0.2, 0.2, 0.6), wheelBase * CFrame.new(0, 0, -0.3), CARBON)
	for i = 0, 23 do
		local angle = i / 24 * math.pi * 2
		if math.sin(angle) > -0.8 then
			part("WheelRim", Vector3.new(0.13, 0.15, 0.13), wheelBase * CFrame.Angles(0, 0, angle) * CFrame.new(0.5, 0, 0), i == 6 and ACCENT or LEATHER, M.Leather)
		end
	end
	part("WheelFlat", Vector3.new(0.6, 0.12, 0.13), wheelBase * CFrame.new(0, -0.42, 0), LEATHER, M.Leather)
	part("WheelHub", Vector3.new(0.34, 0.26, 0.1), wheelBase * CFrame.new(0, -0.03, 0.02), CARBON)
	for _, side in { -1, 1 } do
		part("WheelSpoke", Vector3.new(0.34, 0.08, 0.06), wheelBase * CFrame.new(side * 0.32, 0, 0.02), CARBON)
		part("ShiftPaddle", Vector3.new(0.18, 0.25, 0.03), wheelBase * CFrame.new(side * 0.32, 0.15, -0.1), ACCENT, M.Metal)
	end
	-- zwei Schalensitze aus Leder mit Gurten
	for _, side in { -1, 1 } do
		local x = side * 1.25
		part("SeatBase", Vector3.new(1.3, 0.3, 1.4), CFrame.new(x, 1.35, 0.7), CARBON)
		part("SeatCushion", Vector3.new(1.0, 0.25, 1.3), CFrame.new(x, 1.6, 0.7), LEATHER, M.Leather)
		local seatBack = CFrame.new(x, 1.55, 1.45) * CFrame.Angles(math.rad(15), 0, 0)
		part("SeatBack", Vector3.new(1.0, 1.9, 0.25), seatBack * CFrame.new(0, 0.95, 0), LEATHER, M.Leather)
		for _, bx in { -1, 1 } do
			part("SeatWing", Vector3.new(0.18, 1.7, 0.5), seatBack * CFrame.new(bx * 0.55, 0.85, -0.1), LEATHER, M.Leather)
			part("CushionWing", Vector3.new(0.18, 0.35, 1.3), CFrame.new(x + bx * 0.55, 1.68, 0.7), LEATHER, M.Leather)
			part("SeatStitch", Vector3.new(0.02, 1.6, 0.02), seatBack * CFrame.new(bx * 0.45, 0.9, -0.14), ACCENT)
			-- Hosenträgergurte
			part("Harness", Vector3.new(0.12, 1.4, 0.03), seatBack * CFrame.new(bx * 0.22, 1.0, -0.15), RED, M.Fabric)
		end
		part("SeatShell", Vector3.new(1.25, 1.95, 0.08), seatBack * CFrame.new(0, 0.95, 0.15), CARBON)
		part("SeatLogo", Vector3.new(0.35, 0.12, 0.02), seatBack * CFrame.new(0, 1.65, -0.13), ACCENT, M.Metal)
		-- Türverkleidung innen
		part("DoorInner", Vector3.new(0.06, 0.9, 4.0), CFrame.new(side * (CORE - 0.03), 1.9, -0.2), LEATHER, M.Leather)
		part("DoorAccent", Vector3.new(0.04, 0.04, 3.6), CFrame.new(side * (CORE - 0.07), 2.2, -0.2), ACCENT, M.Metal)
	end
	part("RearBulkhead", Vector3.new(CORE * 2, 1.4, 0.15), CFrame.new(0, 1.9, 2.35), CARBON)

	model.PrimaryPart = model:FindFirstChild("Hood")
	model.WorldPivot = origin
	model.Parent = parent
	return model
end

return SportsCar
