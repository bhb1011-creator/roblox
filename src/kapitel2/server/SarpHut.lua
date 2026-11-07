-- Sarps Hütte am Ende von Kapitel 3: eine alte Blockhütte an einer schlechten Schotterstraße,
-- mitten im Wald. Drinnen: Wohnraum mit Kamin, Kochecke, Tisch, Sessel, Sarps Jacke an der
-- Garderobe, das alte Telefon (mit Zettel: Notruf 110), der Spiegel über dem Waschtisch und
-- hinter einer Bretterwand die Schlafecke mit Bett und dem Foto auf dem Nachttisch.
--
-- Koordinaten: `road` ist ein CFrame am Ende des Waldwegs (Blick zur Hütte = -Z). Die Straße
-- läuft quer davor (entlang X), die Hütte steht dahinter. Alles wird relativ dazu gebaut.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.Parts)

local SarpHut = {}

local M = Enum.Material

-- Farben
local LOG = Color3.fromRGB(96, 72, 50)
local LOG_DARK = Color3.fromRGB(70, 52, 38)
local PLANK = Color3.fromRGB(104, 80, 58)
local PLANK_DARK = Color3.fromRGB(66, 50, 38)
local STONE = Color3.fromRGB(96, 92, 88)
local IRON = Color3.fromRGB(34, 32, 32)
local WARM = Color3.fromRGB(255, 176, 104)
local JACKET = Color3.fromRGB(58, 60, 44) -- Sarps olivgrüne Jacke
local FABRIC_RED = Color3.fromRGB(110, 40, 34)

-- Maße der Hütte (im eigenen Rahmen: Vorderwand bei z = 0, innen bis z = -21)
local HALF_W = 10.5 -- Außenwände links/rechts bei x = ±HALF_W
local BACK = -21.5 -- Rückwand
local FLOOR = 1.9 -- Oberkante des Bodens (die Hütte steht auf einem Steinsockel)
local WALL_H = 9 -- bis zur Traufe
local RIDGE = 5.6 -- so viel höher ist der First
local ROW = 0.82 -- Abstand der Baumstämme
local HUT_OFFSET = -19 -- Hütte so weit hinter dem Wegende (dazwischen liegt die Straße)
SarpHut.ROAD_Z = -7 -- Mitte der Straße (im Rahmen des Wegendes)
SarpHut.ROAD_HALF = 5.5

-- ground(position) = Höhe des Bodens (Terrain) an dieser Stelle (sonst 0)
function SarpHut.build(parent, road, ground)
	ground = ground or function()
		return road.Y
	end
	local folder = Instance.new("Model")
	folder.Name = "SarpHut"
	folder.Parent = parent
	-- die Hütte steht auf dem höchsten Punkt ihrer Grundfläche (nie im Boden)
	local hutBase = road * CFrame.new(0, 0, HUT_OFFSET)
	local highest = -math.huge
	for x = -13, 13, 2.6 do
		for z = 6, -24, -3 do
			highest = math.max(highest, ground((hutBase * CFrame.new(x, 0, z)).Position))
		end
	end
	local hutFrame = hutBase + Vector3.new(0, highest - hutBase.Y, 0)
	-- etwas auf den Boden stellen (Höhe vom Terrain an dieser Stelle)
	local function onGround(cframe)
		return cframe + Vector3.new(0, ground(cframe.Position) - cframe.Y, 0)
	end
	-- kein Terrain in der Hütte und unter der Veranda
	local terrain = workspace.Terrain
	terrain:FillBlock(hutFrame * CFrame.new(0, FLOOR + 8, -10.5), Vector3.new(24, 16, 24), Enum.Material.Air)
	terrain:FillBlock(hutFrame * CFrame.new(0, FLOOR + 8, 3), Vector3.new(16, 16, 6), Enum.Material.Air)
	local rng = Random.new(77)
	local info = { folder = folder, frame = hutFrame, road = road, lights = {} }

	local function L(x, y, z)
		return hutFrame * CFrame.new(x, y, z)
	end
	local function block(name, size, cframe, color, material, extra)
		local props = { Name = name, Size = size, CFrame = cframe, Color = color, Material = material or M.SmoothPlastic, Parent = folder }
		for key, value in extra or {} do
			props[key] = value
		end
		return Parts.new("Part", props)
	end
	local function deco(name, size, cframe, color, material, extra)
		extra = extra or {}
		extra.CanCollide = false
		if extra.CanQuery == nil then
			extra.CanQuery = false
		end
		extra.CanTouch = false
		return block(name, size, cframe, color, material, extra)
	end
	-- liegender Zylinder (Achse = X des CFrames)
	local function cyl(name, length, diameter, cframe, color, material, extra)
		extra = extra or {}
		extra.Shape = Enum.PartType.Cylinder
		return block(name, Vector3.new(length, diameter, diameter), cframe, color, material, extra)
	end
	local function ball(name, diameter, cframe, color, material)
		return deco(name, Vector3.new(diameter, diameter, diameter), cframe, color, material, { Shape = Enum.PartType.Ball })
	end
	local function light(name, at, color, range, brightness, shadows)
		local holder = deco(name, Vector3.new(0.2, 0.2, 0.2), at, Color3.new(), M.SmoothPlastic, { Transparency = 1 })
		local pointLight = Parts.light("PointLight", holder, { Color = color, Range = range, Brightness = brightness, Shadows = shadows ~= false })
		pointLight.Name = "HutLight"
		table.insert(info.lights, pointLight)
		return holder, pointLight
	end
	local function shade(color, amount)
		return color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, amount or 0.25))
	end
	-- Kerze mit Flamme und Licht
	local function candle(at, height, range)
		height = height or 0.7
		local c = cyl("Candle", height, 0.28, at * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(226, 214, 190), M.SmoothPlastic, { CanCollide = false })
		local flame = ball("Flame", 0.16, at * CFrame.new(0, height + 0.1, 0), Color3.fromRGB(255, 190, 90), M.Neon)
		flame.Size = Vector3.new(0.12, 0.24, 0.12)
		-- Wachs-Tropfen
		ball("Wax", 0.14, at * CFrame.new(0.13, height * 0.7, 0), Color3.fromRGB(226, 214, 190), M.SmoothPlastic)
		light("CandleLight", at * CFrame.new(0, height + 0.4, 0), Color3.fromRGB(255, 170, 90), range or 9, 0.9)
		return c
	end

	------------------------------------------------------------ Fundament und Boden
	block("Foundation", Vector3.new(HALF_W * 2 + 0.6, FLOOR + 3.65, -BACK + 0.6), L(0, (FLOOR - 0.35 - 4) / 2, BACK / 2), STONE, M.Cobblestone)
	-- einzelne große Steine am Sockel
	for k = 0, 22 do
		local along = rng:NextNumber(-HALF_W, HALF_W)
		local onFront = k % 2 == 0
		local at = onFront and L(along, FLOOR - 1.1, 0.25) or L(k % 4 == 1 and -HALF_W - 0.25 or HALF_W + 0.25, FLOOR - 1.1, rng:NextNumber(BACK, -0.5))
		deco("FoundationStone", Vector3.new(rng:NextNumber(0.9, 1.6), rng:NextNumber(0.6, 1), rng:NextNumber(0.5, 0.9)), at * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), shade(STONE, 0.3), M.Slate)
	end
	for x = -HALF_W + 0.5, HALF_W - 0.5, 1 do
		deco("FloorBoard", Vector3.new(0.96, 0.12, -BACK - 0.4), L(x, FLOOR + 0.05, BACK / 2), shade(PLANK, 0.35), M.WoodPlanks)
	end
	-- unsichtbarer, glatter Boden (man läuft nicht über einzelne Bretter)
	block("FloorCollider", Vector3.new(HALF_W * 2, 0.4, -BACK), L(0, FLOOR - 0.2, BACK / 2), PLANK, M.WoodPlanks, { Transparency = 1 })

	------------------------------------------------------------ Blockwände (Stämme mit Öffnungen)
	-- axis "x": Wand entlang X bei z = fixed; axis "z": Wand entlang Z bei x = fixed
	-- openings: { a, b, bottom, top } (entlang der Wand, Höhe über dem Boden)
	local rows = math.floor(WALL_H / ROW)
	local function logWall(axis, fixed, from, to, openings)
		for r = 0, rows - 1 do
			local y = FLOOR + 0.45 + r * ROW
			local h = y - FLOOR
			local cuts = {}
			for _, o in openings do
				if o[3] < h + 0.3 and o[4] > h - 0.3 then
					table.insert(cuts, o)
				end
			end
			table.sort(cuts, function(p, q)
				return p[1] < q[1]
			end)
			-- jede zweite Reihe steht an den Ecken über (Blockbau-Ecken)
			local over = (r % 2 == (axis == "x" and 0 or 1)) and 1.1 or 0.4
			local start = from - over
			local pieces = {}
			for _, o in cuts do
				table.insert(pieces, { start, o[1] })
				start = o[2]
			end
			table.insert(pieces, { start, to + over })
			for _, piece in pieces do
				local length = piece[2] - piece[1]
				if length > 0.2 then
					local mid = (piece[1] + piece[2]) / 2
					local frame = axis == "x" and L(mid, y, fixed) or L(fixed, y, mid) * CFrame.Angles(0, math.rad(90), 0)
					local diameter = 0.95 + rng:NextNumber(-0.06, 0.06)
					cyl("Log", length, diameter, frame * CFrame.Angles(rng:NextNumber(-0.3, 0.3), 0, 0), shade(LOG, 0.3), M.Wood)
				end
			end
		end
		-- Lehm zwischen den Stämmen (dunkle Fugen, innen und außen)
		local length = to - from
		for r = 0, rows - 2 do
			local y = FLOOR + 0.45 + r * ROW + ROW / 2
			local h = y - FLOOR
			local blocked = false
			for _, o in openings do
				if o[3] < h + 0.2 and o[4] > h - 0.2 then
					blocked = true
				end
			end
			if not blocked then
				local frame = axis == "x" and L((from + to) / 2, y, fixed) or L(fixed, y, (from + to) / 2) * CFrame.Angles(0, math.rad(90), 0)
				deco("Chinking", Vector3.new(length, 0.14, 0.7), frame, Color3.fromRGB(88, 80, 68), M.Concrete)
			end
		end
	end

	local DOOR = { -2, 2, 0, 7.2 }
	local frontWindowL = { -7.5, -4.5, 3.2, 6.2 }
	local frontWindowR = { 4.5, 7.5, 3.2, 6.2 }
	logWall("x", -0.5, -HALF_W, HALF_W, { DOOR, frontWindowL, frontWindowR })
	local backWindow = { 4.8, 7.6, 3.4, 6 } -- Schlafecke
	logWall("x", BACK, -HALF_W, HALF_W, { backWindow })
	local leftWindow = { -19.6, -16.6, 3.2, 6.2 } -- hinten links (entlang z)
	logWall("z", -HALF_W, BACK, -0.5, { leftWindow })
	local rightWindow = { -16, -13, 3.2, 6.2 } -- Schlafecke rechts
	logWall("z", HALF_W, BACK, -0.5, { rightWindow })
	-- unsichtbare, glatte Innenwände (damit man nicht an Stämmen hängen bleibt)
	local function collider(size, frame)
		block("WallCollider", size, frame, LOG, M.Wood, { Transparency = 1, CanQuery = false })
	end
	collider(Vector3.new(HALF_W * 2, WALL_H, 0.9), L(0, FLOOR + WALL_H / 2, BACK)) -- hinten
	collider(Vector3.new(0.9, WALL_H, -BACK), L(-HALF_W, FLOOR + WALL_H / 2, BACK / 2))
	collider(Vector3.new(0.9, WALL_H, -BACK), L(HALF_W, FLOOR + WALL_H / 2, BACK / 2))
	collider(Vector3.new(HALF_W - 2, WALL_H, 0.9), L(-(HALF_W + 2) / 2, FLOOR + WALL_H / 2, -0.5))
	collider(Vector3.new(HALF_W - 2, WALL_H, 0.9), L((HALF_W + 2) / 2, FLOOR + WALL_H / 2, -0.5))
	collider(Vector3.new(4, WALL_H - 7.2, 0.9), L(0, FLOOR + 7.2 + (WALL_H - 7.2) / 2, -0.5))

	-- Fenster: Rahmen, schmutziges Glas, Sprossen, Fensterbank, Läden außen
	local function window(axis, fixed, o, outside)
		local a, b, bottom, top = o[1], o[2], o[3], o[4]
		local mid, width, height = (a + b) / 2, b - a, top - bottom
		local function at(u, y, depth)
			if axis == "x" then
				return L(mid + u, FLOOR + y, fixed + depth * outside)
			end
			return L(fixed + depth * outside, FLOOR + y, mid + u) * CFrame.Angles(0, math.rad(90), 0)
		end
		local frameColor = Color3.fromRGB(58, 44, 32)
		deco("WindowFrame", Vector3.new(width + 0.4, 0.3, 1.1), at(0, top + 0.05, 0), frameColor, M.Wood)
		deco("WindowFrame", Vector3.new(width + 0.4, 0.3, 1.1), at(0, bottom - 0.05, 0), frameColor, M.Wood)
		deco("WindowFrame", Vector3.new(0.3, height, 1.1), at(-width / 2 - 0.05, (bottom + top) / 2, 0), frameColor, M.Wood)
		deco("WindowFrame", Vector3.new(0.3, height, 1.1), at(width / 2 + 0.05, (bottom + top) / 2, 0), frameColor, M.Wood)
		deco("WindowSill", Vector3.new(width + 0.8, 0.2, 0.7), at(0, bottom - 0.15, 0.6), frameColor, M.Wood)
		local glass = block("WindowGlass", Vector3.new(width, height, 0.08), at(0, (bottom + top) / 2, 0), Color3.fromRGB(150, 120, 80), M.Glass, { Transparency = 0.45, CanQuery = false })
		-- warmes Licht fällt aus dem Fenster nach draußen (man sieht die Hütte von Weitem)
		Parts.light("SurfaceLight", glass, { Face = outside > 0 and Enum.NormalId.Back or Enum.NormalId.Front, Color = Color3.fromRGB(255, 170, 100), Range = 14, Brightness = 0.9, Angle = 70, Shadows = false })
		deco("Mullion", Vector3.new(0.12, height, 0.16), at(0, (bottom + top) / 2, 0.05), frameColor, M.Wood)
		deco("Mullion", Vector3.new(width, 0.12, 0.16), at(0, (bottom + top) / 2, 0.05), frameColor, M.Wood)
		-- Fensterläden (einer hängt schief an einer Angel)
		for _, side in { -1, 1 } do
			local crooked = side == 1 and rng:NextNumber() < 0.5
			local shutterFrame = at(side * (width / 2 + width / 4 + 0.35), (bottom + top) / 2 - (crooked and 0.4 or 0), 0.62) * CFrame.Angles(0, 0, crooked and math.rad(side * 9) or 0)
			for k = -1, 1 do
				deco("Shutter", Vector3.new(width / 6 - 0.04, height + 0.2, 0.12), shutterFrame * CFrame.new(k * width / 6, 0, 0), shade(PLANK_DARK, 0.3), M.WoodPlanks)
			end
			deco("ShutterBar", Vector3.new(width / 2, 0.22, 0.08), shutterFrame * CFrame.new(0, height * 0.3, 0.08), PLANK_DARK, M.Wood)
			deco("ShutterBar", Vector3.new(width / 2, 0.22, 0.08), shutterFrame * CFrame.new(0, -height * 0.3, 0.08), PLANK_DARK, M.Wood)
		end
	end
	window("x", -0.5, frontWindowL, 1)
	window("x", -0.5, frontWindowR, 1)
	window("x", BACK, backWindow, -1)
	window("z", -HALF_W, leftWindow, -1)
	window("z", HALF_W, rightWindow, 1)

	-- Türrahmen und die Tür (steht offen, nach innen)
	local frameColor = Color3.fromRGB(58, 44, 32)
	deco("DoorFrame", Vector3.new(0.35, 7.3, 1.2), L(-2.15, FLOOR + 3.65, -0.5), frameColor, M.Wood)
	deco("DoorFrame", Vector3.new(0.35, 7.3, 1.2), L(2.15, FLOOR + 3.65, -0.5), frameColor, M.Wood)
	deco("DoorFrame", Vector3.new(4.7, 0.4, 1.2), L(0, FLOOR + 7.3, -0.5), frameColor, M.Wood)
	deco("Threshold", Vector3.new(4.2, 0.14, 1.2), L(0, FLOOR + 0.07, -0.5), PLANK_DARK, M.Wood)
	local hinge = L(-1.95, FLOOR + 3.6, -0.95) * CFrame.Angles(0, math.rad(78), 0)
	for k = 0, 4 do
		deco("Door", Vector3.new(0.76, 7.1, 0.22), hinge * CFrame.new(0.4 + k * 0.78, 0, 0), shade(PLANK, 0.3), M.WoodPlanks)
	end
	for _, y in { -2.6, 0, 2.6 } do
		deco("DoorBrace", Vector3.new(3.8, 0.4, 0.12), hinge * CFrame.new(1.95, y, -0.16), PLANK_DARK, M.Wood)
	end
	deco("DoorBrace", Vector3.new(0.35, 5.6, 0.12), hinge * CFrame.new(1.95, -1.3, -0.17) * CFrame.Angles(0, 0, math.rad(42)), PLANK_DARK, M.Wood)
	ball("DoorKnob", 0.26, hinge * CFrame.new(3.6, 0, 0.2), IRON, M.Metal)
	deco("Latch", Vector3.new(0.8, 0.12, 0.08), hinge * CFrame.new(3.4, 0.3, 0.18), IRON, M.Metal)
	-- Riegel innen (abgebrochen, liegt am Boden)
	deco("BrokenBar", Vector3.new(3.4, 0.3, 0.3), L(-3.6, FLOOR + 0.18, -2.2) * CFrame.Angles(0, math.rad(25), 0), PLANK_DARK, M.Wood)

	------------------------------------------------------------ Giebel und Dach
	-- Giebeldreiecke vorne und hinten aus senkrechten Brettern
	for _, z in { -0.5, BACK } do
		local x = -HALF_W - 0.3
		while x < HALF_W + 0.3 do
			local height = RIDGE * (1 - math.abs(x + 0.45) / (HALF_W + 0.8))
			if height > 0.2 then
				deco("Gable", Vector3.new(0.88, height, 0.4), L(x + 0.45, FLOOR + WALL_H + height / 2 - 0.1, z), shade(PLANK_DARK, 0.25), M.WoodPlanks)
			end
			x += 0.9
		end
	end
	block("GableCollider", Vector3.new(HALF_W * 2, 0.6, -BACK), L(0, FLOOR + WALL_H + 0.2, BACK / 2), LOG, M.Wood, { Transparency = 1, CanQuery = false })
	-- Hirschschädel mit Geweih über der Tür (am Giebel)
	local skull = L(0, FLOOR + WALL_H + 2, 0)
	deco("Skull", Vector3.new(0.9, 1.2, 0.7), skull * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(214, 206, 188), M.SmoothPlastic)
	deco("SkullSnout", Vector3.new(0.6, 0.9, 0.5), skull * CFrame.new(0, -0.8, 0.25) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(214, 206, 188), M.SmoothPlastic)
	for _, side in { -1, 1 } do
		ball("EyeHole", 0.3, skull * CFrame.new(side * 0.25, 0.05, 0.33), Color3.new(0.05, 0.05, 0.05), M.SmoothPlastic)
		local base = (skull * CFrame.new(side * 0.35, 0.55, 0)).Position
		local tip = base + (skull.RightVector * side * 1.6 + skull.UpVector * 1.4).Unit * 2
		Parts.beam({ Name = "Antler", Color = Color3.fromRGB(190, 176, 150), Material = M.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = folder }, base, tip, 0.14)
		local branch = base:Lerp(tip, 0.5)
		Parts.beam({ Name = "Antler", Color = Color3.fromRGB(190, 176, 150), Material = M.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = folder }, branch, branch + skull.UpVector * 0.9 + skull.LookVector * 0.2, 0.1)
	end

	-- Dachflächen (links und rechts), mit Überstand, darauf Schindelreihen
	local slope = math.atan(RIDGE / (HALF_W + 0.8))
	local slopeLength = math.sqrt(RIDGE ^ 2 + (HALF_W + 0.8) ^ 2) + 1.4
	local roofLength = -BACK + 2.6
	for _, side in { -1, 1 } do
		local roofFrame = L(side * (HALF_W + 0.8) / 2, FLOOR + WALL_H + RIDGE / 2 + 0.25, BACK / 2) * CFrame.Angles(0, 0, -side * slope)
		block("Roof", Vector3.new(slopeLength, 0.4, roofLength), roofFrame * CFrame.new(side * 0.6, 0, 0), PLANK_DARK, M.WoodPlanks)
		-- Schindeln: Reihen von unten nach oben, leicht versetzt, ein paar fehlen
		local rowsOnRoof = math.floor(slopeLength / 0.75)
		for k = 0, rowsOnRoof - 1 do
			local u = side * (slopeLength / 2 - 0.4 - k * 0.75) + side * 0.6
			local z = -roofLength / 2
			while z < roofLength / 2 - 0.2 do
				local width = rng:NextNumber(0.9, 1.6)
				if rng:NextNumber() > 0.035 then
					deco("Shingle", Vector3.new(0.9, 0.12, width - 0.06), roofFrame * CFrame.new(u, 0.26 + (k % 2) * 0.02, z + width / 2) * CFrame.Angles(0, 0, side * math.rad(4)), shade(Color3.fromRGB(62, 58, 54), 0.35), M.Slate)
				end
				z += width
			end
		end
		-- Moos in einer Ecke
		deco("Moss", Vector3.new(3, 0.1, 4), roofFrame * CFrame.new(side * (slopeLength / 2 - 2), 0.36, roofLength / 2 - 3), Color3.fromRGB(58, 74, 40), M.Grass)
	end
	deco("Ridge", Vector3.new(0.8, 0.5, roofLength + 0.2), L(0, FLOOR + WALL_H + RIDGE + 0.45, BACK / 2), PLANK_DARK, M.Wood)
	-- Balken innen (Querbalken und Firstbalken)
	for z = -2.5, BACK + 1, -4.5 do
		deco("TieBeam", Vector3.new(HALF_W * 2, 0.6, 0.6), L(0, FLOOR + WALL_H - 0.3, z), LOG_DARK, M.Wood)
		for _, side in { -1, 1 } do
			local from = (L(side * (HALF_W - 0.4), FLOOR + WALL_H, z)).Position
			local to = (L(0, FLOOR + WALL_H + RIDGE - 0.2, z)).Position
			Parts.beam({ Name = "Rafter", Color = LOG_DARK, Material = M.Wood, CanCollide = false, CanQuery = false, Parent = folder }, from, to, 0.5)
		end
	end
	deco("RidgeBeam", Vector3.new(0.55, 0.55, -BACK), L(0, FLOOR + WALL_H + RIDGE - 0.35, BACK / 2), LOG_DARK, M.Wood)

	------------------------------------------------------------ Schornstein und Kamin (links)
	local chimneyZ = -12
	block("Chimney", Vector3.new(2.6, WALL_H + RIDGE + 3.5, 3.4), L(-HALF_W - 1.4, (WALL_H + RIDGE + 3.5) / 2, chimneyZ), STONE, M.Cobblestone)
	block("ChimneyCap", Vector3.new(3.1, 0.4, 3.9), L(-HALF_W - 1.4, WALL_H + RIDGE + 3.6, chimneyZ), Color3.fromRGB(70, 66, 62), M.Slate)
	local smokeHolder = deco("ChimneySmoke", Vector3.new(1, 0.2, 1), L(-HALF_W - 1.4, WALL_H + RIDGE + 3.9, chimneyZ), Color3.new(), M.SmoothPlastic, { Transparency = 1 })
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(90, 90, 96))
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 5) })
	smoke.Lifetime = NumberRange.new(4, 6)
	smoke.Rate = 3
	smoke.Speed = NumberRange.new(2, 3)
	smoke.SpreadAngle = Vector2.new(12, 12)
	smoke.Acceleration = Vector3.new(1.5, 0.3, 0)
	smoke.Parent = smokeHolder
	-- Kamin innen: Steinsockel, Feuerloch, Glut, Sims
	block("Hearth", Vector3.new(2.2, 5.2, 4.6), L(-HALF_W + 0.9, FLOOR + 2.6, chimneyZ), STONE, M.Cobblestone)
	deco("HearthTop", Vector3.new(2.4, 3.6, 3.4), L(-HALF_W + 0.7, FLOOR + 5.2 + 1.8, chimneyZ), STONE, M.Cobblestone)
	deco("Firebox", Vector3.new(0.3, 2.2, 2.6), L(-HALF_W + 2.01, FLOOR + 1.3, chimneyZ), Color3.fromRGB(14, 12, 12), M.SmoothPlastic)
	deco("HearthStep", Vector3.new(1.6, 0.3, 5.2), L(-HALF_W + 2.6, FLOOR + 0.15, chimneyZ), Color3.fromRGB(80, 76, 72), M.Slate)
	for k = 1, 5 do
		ball("Ember", rng:NextNumber(0.25, 0.45), L(-HALF_W + 2.1 + rng:NextNumber(-0.1, 0.1), FLOOR + 0.35, chimneyZ + rng:NextNumber(-0.9, 0.9)), Color3.fromRGB(255, rng:NextInteger(70, 120), 30), M.Neon)
	end
	for k = -1, 1, 2 do
		cyl("FireLog", 1.8, 0.4, L(-HALF_W + 2.2, FLOOR + 0.5, chimneyZ + k * 0.3) * CFrame.Angles(0, math.rad(90 + k * 15), 0), Color3.fromRGB(30, 22, 18), M.Wood, { CanCollide = false })
	end
	local _, fireLight = light("FireLight", L(-HALF_W + 3, FLOOR + 1.2, chimneyZ), Color3.fromRGB(255, 120, 50), 18, 1.4)
	fireLight.Name = "HutFire"
	deco("Mantel", Vector3.new(1.1, 0.3, 5.4), L(-HALF_W + 2.3, FLOOR + 5.35, chimneyZ), LOG_DARK, M.Wood)
	-- auf dem Sims: Kerzen, Gläser, eine kleine Holzpuppe (wie im Ritualsaal)
	candle(L(-HALF_W + 2.3, FLOOR + 5.5, chimneyZ - 2.2), 0.6, 7)
	for k = 0, 2 do
		cyl("Jar", 0.6, 0.45, L(-HALF_W + 2.2, FLOOR + 5.8, chimneyZ - 1.2 + k * 0.55) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 110, 70):Lerp(Color3.fromRGB(60, 40, 30), k / 3), M.Glass, { Transparency = 0.3, CanCollide = false })
	end
	local puppet = L(-HALF_W + 2.2, FLOOR + 5.5, chimneyZ + 1.6) * CFrame.Angles(0, math.rad(90), 0)
	deco("PuppetBody", Vector3.new(0.3, 0.45, 0.18), puppet * CFrame.new(0, 0.38, 0), Color3.fromRGB(140, 110, 80), M.Wood)
	ball("PuppetHead", 0.26, puppet * CFrame.new(0, 0.74, 0), Color3.fromRGB(170, 140, 110), M.Wood)
	for _, side in { -1, 1 } do
		deco("PuppetLeg", Vector3.new(0.08, 0.3, 0.08), puppet * CFrame.new(side * 0.08, 0.1, -0.1) * CFrame.Angles(math.rad(80), 0, 0), Color3.fromRGB(140, 110, 80), M.Wood)
		deco("PuppetArm", Vector3.new(0.07, 0.32, 0.07), puppet * CFrame.new(side * 0.2, 0.4, 0) * CFrame.Angles(0, 0, side * 0.2), Color3.fromRGB(140, 110, 80), M.Wood)
		deco("PuppetString", Vector3.new(0.02, 0.9, 0.02), puppet * CFrame.new(side * 0.2, 0.95, 0), Color3.fromRGB(220, 210, 190), M.SmoothPlastic)
	end
	-- Geweih über dem Kamin
	local trophy = L(-HALF_W + 1.2, FLOOR + 7.6, chimneyZ) * CFrame.Angles(0, math.rad(90), 0)
	deco("TrophyBoard", Vector3.new(1.2, 1.4, 0.2), trophy, LOG_DARK, M.Wood)
	for _, side in { -1, 1 } do
		local base = (trophy * CFrame.new(side * 0.3, 0.4, -0.3)).Position
		local tip = base + (trophy.RightVector * side + trophy.UpVector * 1.2 - trophy.LookVector * 0.2).Unit * 2.2
		Parts.beam({ Name = "Antler", Color = Color3.fromRGB(180, 164, 138), Material = M.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = folder }, base, tip, 0.13)
		local mid = base:Lerp(tip, 0.45)
		Parts.beam({ Name = "Antler", Color = Color3.fromRGB(180, 164, 138), Material = M.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = folder }, mid, mid + trophy.UpVector * 0.8 - trophy.LookVector * 0.3, 0.09)
	end
	-- Schürhaken und Feuerholz neben dem Kamin
	Parts.beam({ Name = "Poker", Color = IRON, Material = M.Metal, CanCollide = false, CanQuery = false, Parent = folder }, L(-HALF_W + 2.2, FLOOR + 0.1, chimneyZ + 2.8).Position, L(-HALF_W + 1.6, FLOOR + 3, chimneyZ + 2.6).Position, 0.1)
	for k = 0, 8 do
		local row = math.floor(k / 3)
		cyl("Firewood", 1.6, 0.42, L(-HALF_W + 1.4, FLOOR + 0.25 + row * 0.38, chimneyZ - 3.4 + (k % 3) * 0.44 + row * 0.2) * CFrame.Angles(0, math.rad(90), 0), shade(Color3.fromRGB(110, 84, 58), 0.3), M.Wood, { CanCollide = false })
	end

	------------------------------------------------------------ Kochecke (vorne links)
	local counterZ = -6.2
	block("Counter", Vector3.new(2.2, 3, 5), L(-HALF_W + 1.6, FLOOR + 1.5, counterZ), PLANK, M.WoodPlanks)
	deco("CounterTop", Vector3.new(2.5, 0.2, 5.3), L(-HALF_W + 1.6, FLOOR + 3.1, counterZ), LOG_DARK, M.Wood)
	for k = -1, 1 do
		deco("Drawer", Vector3.new(0.08, 0.7, 1.4), L(-HALF_W + 2.72, FLOOR + 2.4, counterZ + k * 1.6), PLANK_DARK, M.Wood)
		ball("Knob", 0.14, L(-HALF_W + 2.78, FLOOR + 2.4, counterZ + k * 1.6), IRON, M.Metal)
	end
	deco("Basin", Vector3.new(1.4, 0.4, 1.6), L(-HALF_W + 1.6, FLOOR + 3.3, counterZ - 1.3), Color3.fromRGB(130, 130, 126), M.Metal)
	deco("CuttingBoard", Vector3.new(1, 0.08, 1.4), L(-HALF_W + 1.7, FLOOR + 3.24, counterZ + 0.5), Color3.fromRGB(150, 116, 80), M.Wood)
	deco("Knife", Vector3.new(0.06, 0.04, 0.9), L(-HALF_W + 1.9, FLOOR + 3.3, counterZ + 0.5) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(190, 190, 186), M.Metal)
	deco("Stain", Vector3.new(0.6, 0.02, 0.5), L(-HALF_W + 1.5, FLOOR + 3.29, counterZ + 0.4), Color3.fromRGB(70, 20, 18), M.SmoothPlastic)
	-- Ofen mit Rohr
	block("Stove", Vector3.new(2, 2.6, 2.2), L(-HALF_W + 1.4, FLOOR + 1.3, counterZ + 3.8), IRON, M.Metal)
	deco("StoveDoor", Vector3.new(0.08, 0.9, 1.2), L(-HALF_W + 2.42, FLOOR + 1.1, counterZ + 3.8), Color3.fromRGB(50, 46, 44), M.Metal)
	local pipeBase = L(-HALF_W + 1.2, FLOOR + 2.6, counterZ + 3.8)
	Parts.column({ Name = "StovePipe", Color = IRON, Material = M.Metal, CanCollide = false, CanQuery = false, Parent = folder }, WALL_H + 1, 0.5, pipeBase)
	cyl("Pot", 0.6, 0.9, L(-HALF_W + 1.5, FLOOR + 2.9, counterZ + 3.4) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 56, 52), M.Metal, { CanCollide = false })
	cyl("Kettle", 0.6, 0.7, L(-HALF_W + 1.4, FLOOR + 2.9, counterZ + 4.4) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 70, 40), M.Metal, { CanCollide = false })
	-- Regal über der Theke mit Gläsern und Dosen
	deco("Shelf", Vector3.new(1, 0.15, 4.6), L(-HALF_W + 1, FLOOR + 5.6, counterZ), LOG_DARK, M.Wood)
	for k = 0, 6 do
		local colors = { Color3.fromRGB(140, 120, 60), Color3.fromRGB(90, 40, 30), Color3.fromRGB(70, 90, 60), Color3.fromRGB(160, 150, 130) }
		cyl("ShelfJar", rng:NextNumber(0.5, 0.8), rng:NextNumber(0.35, 0.5), L(-HALF_W + 1, FLOOR + 6, counterZ - 2 + k * 0.62) * CFrame.Angles(0, 0, math.rad(90)), colors[rng:NextInteger(1, #colors)], M.Glass, { Transparency = 0.25, CanCollide = false })
	end
	-- getrocknete Kräuter an einer Schnur
	for k = 0, 4 do
		deco("Herbs", Vector3.new(0.3, 0.8, 0.3), L(-HALF_W + 1.4, FLOOR + 7.4, counterZ - 2 + k * 0.9), Color3.fromRGB(80, 90, 50):Lerp(Color3.fromRGB(110, 90, 50), rng:NextNumber()), M.Grass)
	end
	deco("HerbString", Vector3.new(0.04, 0.04, 4.4), L(-HALF_W + 1.4, FLOOR + 7.85, counterZ - 0.2), Color3.fromRGB(200, 190, 160), M.Fabric)
	cyl("Bucket", 1, 1, L(-HALF_W + 3.3, FLOOR + 0.5, counterZ - 2.2) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 110, 104), M.Metal)

	------------------------------------------------------------ Tisch mit Stühlen und Petroleumlampe
	local table0 = L(-3.4, FLOOR, -8.5)
	block("Table", Vector3.new(3.8, 0.25, 2.6), table0 * CFrame.new(0, 2.9, 0), Color3.fromRGB(96, 70, 48), M.WoodPlanks)
	for _, leg in { { -1.6, -1 }, { 1.6, -1 }, { -1.6, 1 }, { 1.6, 1 } } do
		deco("TableLeg", Vector3.new(0.3, 2.8, 0.3), table0 * CFrame.new(leg[1], 1.4, leg[2]), LOG_DARK, M.Wood)
	end
	local function chair(at)
		block("ChairSeat", Vector3.new(1.4, 0.2, 1.4), at * CFrame.new(0, 1.7, 0), PLANK, M.Wood)
		for _, leg in { { -0.6, -0.6 }, { 0.6, -0.6 }, { -0.6, 0.6 }, { 0.6, 0.6 } } do
			deco("ChairLeg", Vector3.new(0.18, 1.7, 0.18), at * CFrame.new(leg[1], 0.85, leg[2]), LOG_DARK, M.Wood)
		end
		for _, x in { -0.6, 0.6 } do
			deco("ChairBack", Vector3.new(0.18, 1.9, 0.18), at * CFrame.new(x, 2.65, 0.62), LOG_DARK, M.Wood)
		end
		for _, y in { 2.4, 3.3 } do
			deco("ChairRail", Vector3.new(1.3, 0.25, 0.12), at * CFrame.new(0, y, 0.62), PLANK, M.Wood)
		end
	end
	chair(table0 * CFrame.new(-0.8, 0, 2) * CFrame.Angles(0, math.rad(8), 0))
	-- der zweite Stuhl ist umgekippt
	local fallen = table0 * CFrame.new(1.6, 0.75, -2.4) * CFrame.Angles(math.rad(90), math.rad(20), 0)
	deco("ChairSeat", Vector3.new(1.4, 0.2, 1.4), fallen * CFrame.new(0, 0, 0), PLANK, M.Wood)
	for _, leg in { { -0.6, -0.6 }, { 0.6, -0.6 }, { -0.6, 0.6 }, { 0.6, 0.6 } } do
		deco("ChairLeg", Vector3.new(0.18, 1.7, 0.18), fallen * CFrame.new(leg[1], -0.85, leg[2]), LOG_DARK, M.Wood)
	end
	deco("ChairBack", Vector3.new(1.3, 1.9, 0.18), fallen * CFrame.new(0, 0.95, 0.62), PLANK, M.Wood)
	-- auf dem Tisch: Lampe, Teller, Becher, Zeitung, Messer im Holz
	local lamp = table0 * CFrame.new(0.6, 3.02, -0.2)
	cyl("LampBase", 0.4, 0.8, lamp * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 80, 40), M.Metal, { CanCollide = false })
	ball("LampGlass", 0.75, lamp * CFrame.new(0, 0.85, 0), Color3.fromRGB(255, 220, 160), M.Glass)
	deco("LampFlame", Vector3.new(0.12, 0.3, 0.12), lamp * CFrame.new(0, 0.8, 0), Color3.fromRGB(255, 190, 90), M.Neon)
	cyl("LampTop", 0.25, 0.4, lamp * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 50, 40), M.Metal, { CanCollide = false })
	light("TableLamp", lamp * CFrame.new(0, 1, 0), WARM, 22, 1.3)
	cyl("Plate", 0.08, 0.9, table0 * CFrame.new(-1.1, 3.06, 0.5) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 196, 186), M.SmoothPlastic, { CanCollide = false })
	ball("Bone", 0.25, table0 * CFrame.new(-1.1, 3.18, 0.5), Color3.fromRGB(210, 200, 180), M.SmoothPlastic)
	cyl("Mug", 0.45, 0.35, table0 * CFrame.new(-0.3, 3.25, 0.7) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 60, 50), M.SmoothPlastic, { CanCollide = false })
	local paper = deco("Newspaper", Vector3.new(1.3, 0.04, 0.9), table0 * CFrame.new(-0.9, 3.04, -0.6) * CFrame.Angles(0, 0.3, 0), Color3.fromRGB(205, 198, 176), M.SmoothPlastic)
	local paperGui = Parts.surfaceGui(paper, Enum.NormalId.Top, false)
	Parts.text(paperGui, { Text = "MISSING\n_____ ___ ____\n__ ____ _ ___", TextColor3 = Color3.fromRGB(40, 36, 30), Font = Enum.Font.Garamond })
	local knife = table0 * CFrame.new(1.3, 3.3, 0.7) * CFrame.Angles(math.rad(-80), 0, 0.2)
	deco("TableKnife", Vector3.new(0.1, 0.03, 0.7), knife, Color3.fromRGB(190, 190, 186), M.Metal)
	deco("KnifeHandle", Vector3.new(0.14, 0.14, 0.5), knife * CFrame.new(0, 0, -0.55), LOG_DARK, M.Wood)

	------------------------------------------------------------ Sessel am Kamin, Teppich, Beistelltisch
	local rug = L(-5.2, FLOOR + 0.13, -12.5)
	deco("Rug", Vector3.new(5, 0.06, 6), rug, FABRIC_RED, M.Fabric)
	deco("RugBorder", Vector3.new(4.2, 0.07, 5.2), rug, Color3.fromRGB(150, 110, 70), M.Fabric)
	deco("RugInner", Vector3.new(3.8, 0.08, 4.8), rug, Color3.fromRGB(96, 36, 30), M.Fabric)
	local armchair = L(-4.6, FLOOR, -12.5) * CFrame.Angles(0, math.rad(90), 0) -- Blick zum Kamin (-X)
	block("ArmchairSeat", Vector3.new(2.6, 1, 2.4), armchair * CFrame.new(0, 1.2, 0), Color3.fromRGB(86, 58, 44), M.Fabric)
	deco("ArmchairBack", Vector3.new(2.6, 2.8, 0.6), armchair * CFrame.new(0, 2.6, 1.0) * CFrame.Angles(math.rad(-8), 0, 0), Color3.fromRGB(86, 58, 44), M.Fabric)
	for _, side in { -1, 1 } do
		deco("ArmchairArm", Vector3.new(0.5, 1.6, 2.4), armchair * CFrame.new(side * 1.3, 1.6, 0), Color3.fromRGB(76, 50, 38), M.Fabric)
	end
	deco("Cushion", Vector3.new(2, 0.3, 1.9), armchair * CFrame.new(0, 1.85, -0.1), Color3.fromRGB(100, 70, 52), M.Fabric)
	deco("Blanket", Vector3.new(1.8, 1.6, 0.12), armchair * CFrame.new(0.3, 2.2, 0.7) * CFrame.Angles(math.rad(-20), 0, 0.15), Color3.fromRGB(70, 80, 60), M.Fabric)
	deco("Tear", Vector3.new(0.6, 0.04, 0.9), armchair * CFrame.new(-0.4, 1.86, -0.6), Color3.fromRGB(190, 170, 140), M.Fabric)
	local side = L(-3.2, FLOOR, -15.4)
	cyl("SideTable", 0.2, 1.4, side * CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.rad(90)), LOG_DARK, M.Wood)
	Parts.column({ Name = "SideTableLeg", Color = LOG_DARK, Material = M.Wood, CanCollide = false, CanQuery = false, Parent = folder }, 2, 0.25, side)
	deco("Book", Vector3.new(0.7, 0.18, 0.95), side * CFrame.new(-0.1, 2.3, 0) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(70, 30, 26), M.SmoothPlastic)
	deco("Pipe", Vector3.new(0.12, 0.12, 0.6), side * CFrame.new(0.35, 2.28, 0.2), Color3.fromRGB(60, 40, 30), M.Wood)
	ball("PipeBowl", 0.24, side * CFrame.new(0.35, 2.34, 0.5), Color3.fromRGB(60, 40, 30), M.Wood)

	------------------------------------------------------------ Garderobe mit Sarps Jacke, Stiefel (neben der Tür)
	local rack = L(-3.4, FLOOR, -1.4)
	Parts.column({ Name = "CoatRack", Color = LOG_DARK, Material = M.Wood, CanCollide = false, CanQuery = false, Parent = folder }, 6.2, 0.3, rack)
	for k = 0, 3 do
		local a = k * math.pi / 2
		deco("RackFoot", Vector3.new(0.18, 0.18, 1.1), rack * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.1, 0.5), LOG_DARK, M.Wood)
		deco("RackHook", Vector3.new(0.1, 0.1, 0.6), rack * CFrame.Angles(0, a, 0) * CFrame.new(0, 5.9, 0.25) * CFrame.Angles(math.rad(-30), 0, 0), IRON, M.Metal)
	end
	-- die Jacke hängt am Haken (gleiche Farbe wie Sarps Jacke)
	local coat = rack * CFrame.new(0, 4.1, -0.5)
	deco("SarpJacket", Vector3.new(1.9, 3.2, 0.5), coat, JACKET, M.Fabric)
	deco("SarpJacketCollar", Vector3.new(1.6, 0.5, 0.6), coat * CFrame.new(0, 1.7, 0), Color3.fromRGB(40, 42, 30), M.Fabric)
	for _, s in { -1, 1 } do
		deco("SarpJacketSleeve", Vector3.new(0.5, 2.9, 0.5), coat * CFrame.new(s * 1.1, -0.1, 0), JACKET, M.Fabric)
	end
	deco("SarpJacketPocket", Vector3.new(0.6, 0.5, 0.06), coat * CFrame.new(0.45, -0.8, -0.28), Color3.fromRGB(40, 42, 30), M.Fabric)
	deco("JacketTear", Vector3.new(0.5, 0.8, 0.06), coat * CFrame.new(-0.5, -0.9, -0.28) * CFrame.Angles(0, 0, 0.4), Color3.fromRGB(30, 30, 24), M.Fabric)
	deco("SarpHat", Vector3.new(1.4, 0.15, 1.4), rack * CFrame.new(0.3, 6.25, 0.1) * CFrame.Angles(0.2, 0, 0.15), Color3.fromRGB(46, 40, 34), M.Fabric)
	deco("SarpHatTop", Vector3.new(0.9, 0.5, 0.9), rack * CFrame.new(0.3, 6.5, 0.1) * CFrame.Angles(0.2, 0, 0.15), Color3.fromRGB(46, 40, 34), M.Fabric)
	for _, s in { -1, 1 } do
		local boot = rack * CFrame.new(-1.2 + s * 0.45, 0, -0.4) * CFrame.Angles(0, s * 0.15, 0)
		deco("Boot", Vector3.new(0.5, 1.4, 0.6), boot * CFrame.new(0, 0.7, 0), Color3.fromRGB(40, 32, 26), M.Fabric)
		deco("BootToe", Vector3.new(0.5, 0.45, 0.9), boot * CFrame.new(0, 0.23, -0.6), Color3.fromRGB(40, 32, 26), M.Fabric)
		deco("Mud", Vector3.new(0.7, 0.03, 1.2), boot * CFrame.new(0, 0.02, -0.4), Color3.fromRGB(56, 44, 32), M.Mud)
	end
	-- Schlammige Fußspuren von der Tür in den Raum
	for k = 0, 6 do
		deco("Footprint", Vector3.new(0.5, 0.02, 1), L(0.6 + (k % 2) * 0.8, FLOOR + 0.16, -1.8 - k * 1.5) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), Color3.fromRGB(50, 40, 30), M.Mud)
	end

	------------------------------------------------------------ Das Telefon (rechte Wand, vorne) mit Zettel
	local phoneFrame = L(HALF_W - 0.62, FLOOR + 4.6, -4.5) * CFrame.Angles(0, math.rad(90), 0) -- Vorderseite zeigt in den Raum (-X)
	local phone = block("Phone", Vector3.new(1.3, 1.9, 0.5), phoneFrame, Color3.fromRGB(196, 180, 150), M.SmoothPlastic)
	deco("PhoneBoard", Vector3.new(1.9, 2.6, 0.12), phoneFrame * CFrame.new(0, -0.1, 0.3), LOG_DARK, M.Wood)
	deco("PhoneScreen", Vector3.new(0.9, 0.3, 0.06), phoneFrame * CFrame.new(0, 0.6, -0.27), Color3.fromRGB(40, 46, 40), M.SmoothPlastic)
	-- Hörer links an der Gabel, Kabel nach unten
	local handset = phoneFrame * CFrame.new(-0.95, 0.1, -0.15)
	deco("Handset", Vector3.new(0.3, 1.6, 0.32), handset, Color3.fromRGB(30, 28, 26), M.SmoothPlastic)
	ball("HandsetEar", 0.5, handset * CFrame.new(0, 0.7, -0.1), Color3.fromRGB(30, 28, 26), M.SmoothPlastic)
	ball("HandsetMouth", 0.5, handset * CFrame.new(0, -0.7, -0.1), Color3.fromRGB(30, 28, 26), M.SmoothPlastic)
	for k = 0, 5 do
		ball("Cord", 0.14, handset * CFrame.new(0.1 + math.sin(k) * 0.08, -1 - k * 0.22, -0.05), Color3.fromRGB(30, 28, 26), M.SmoothPlastic)
	end
	-- Tasten 1–9, *, 0, # (Ziffer steht auf jeder Taste; man klickt sie im Spiel an)
	local keys = Instance.new("Folder")
	keys.Name = "PhoneKeys"
	keys.Parent = folder
	local labels = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#" }
	for i, label in labels do
		local column = (i - 1) % 3 - 1
		local row = math.floor((i - 1) / 3)
		local key = Parts.new("Part", {
			Name = "PhoneKey",
			Size = Vector3.new(0.3, 0.24, 0.12),
			CFrame = phoneFrame * CFrame.new(-column * 0.36, 0.15 - row * 0.3, -0.29), -- (von vorne gesehen: 1 links, 3 rechts)
			Color = Color3.fromRGB(236, 230, 214),
			Material = M.SmoothPlastic,
			CanCollide = false,
			CanTouch = false,
			CanQuery = true,
			Parent = keys,
		})
		key:SetAttribute("Digit", label)
		local gui = Parts.surfaceGui(key, Enum.NormalId.Front, false)
		gui.PixelsPerStud = 100
		Parts.text(gui, { Text = label, TextColor3 = Color3.fromRGB(30, 28, 26), Font = Enum.Font.GothamBold })
	end
	-- der Zettel daneben (mit Reißzwecke)
	local note = deco("PhoneNote", Vector3.new(1.1, 1.3, 0.04), phoneFrame * CFrame.new(1.45, 0.1, -0.1) * CFrame.Angles(0, 0, math.rad(-6)), Color3.fromRGB(226, 216, 180), M.SmoothPlastic)
	local noteGui = Parts.surfaceGui(note, Enum.NormalId.Front, false)
	noteGui.PixelsPerStud = 120
	Parts.text(noteGui, { Text = "EMERGENCY\n911", TextColor3 = Color3.fromRGB(150, 30, 26), Font = Enum.Font.PermanentMarker })
	ball("Pin", 0.12, phoneFrame * CFrame.new(1.45, 0.7, -0.14), Color3.fromRGB(180, 30, 30), M.SmoothPlastic)
	-- kleines Regal mit Telefonbuch darunter, Laterne darüber
	deco("PhoneShelf", Vector3.new(2.2, 0.15, 0.9), phoneFrame * CFrame.new(0.3, -1.45, -0.2), LOG_DARK, M.Wood)
	deco("PhoneBook", Vector3.new(0.9, 0.3, 0.6), phoneFrame * CFrame.new(0.6, -1.25, -0.25), Color3.fromRGB(150, 120, 40), M.SmoothPlastic)
	local lantern = phoneFrame * CFrame.new(-0.3, 2.1, -0.6)
	deco("LanternHook", Vector3.new(0.08, 0.08, 0.7), phoneFrame * CFrame.new(-0.3, 2.6, -0.3), IRON, M.Metal)
	deco("Lantern", Vector3.new(0.5, 0.6, 0.5), lantern, Color3.fromRGB(255, 210, 150), M.Glass, { Transparency = 0.3 })
	deco("LanternTop", Vector3.new(0.6, 0.15, 0.6), lantern * CFrame.new(0, 0.38, 0), IRON, M.Metal)
	light("PhoneLantern", lantern, WARM, 12, 1)
	info.phone = phone
	info.phoneKeys = keys
	info.phoneFrame = phoneFrame
	info.phoneView = phoneFrame * CFrame.new(0, 0.1, -2.8) -- wo die Kamera beim Wählen ist

	------------------------------------------------------------ Waschtisch mit dem Spiegel (Rückwand links)
	local washX = -6
	local wash = L(washX, FLOOR, BACK + 1.15)
	block("Washstand", Vector3.new(2.6, 2.8, 1.4), wash * CFrame.new(0, 1.4, 0), PLANK, M.WoodPlanks)
	deco("WashstandTop", Vector3.new(2.8, 0.15, 1.6), wash * CFrame.new(0, 2.88, 0), LOG_DARK, M.Wood)
	cyl("WashBowl", 0.45, 1.3, wash * CFrame.new(-0.3, 3.15, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(210, 206, 196), M.SmoothPlastic, { CanCollide = false })
	cyl("Water", 0.05, 1.1, wash * CFrame.new(-0.3, 3.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 60, 50), M.Glass, { CanCollide = false, Transparency = 0.2 })
	cyl("Pitcher", 0.9, 0.55, wash * CFrame.new(0.85, 3.4, -0.1) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 196, 186), M.SmoothPlastic, { CanCollide = false })
	deco("Towel", Vector3.new(0.12, 1.2, 0.9), wash * CFrame.new(1.38, 2.1, 0), Color3.fromRGB(190, 180, 160), M.Fabric)
	deco("TowelStain", Vector3.new(0.13, 0.5, 0.4), wash * CFrame.new(1.38, 2.0, 0.1), Color3.fromRGB(110, 40, 30), M.Fabric)
	deco("Razor", Vector3.new(0.5, 0.05, 0.12), wash * CFrame.new(0.4, 2.97, 0.4) * CFrame.Angles(0, 0.5, 0), Color3.fromRGB(190, 190, 186), M.Metal)
	candle(wash * CFrame.new(-1.05, 2.95, 0.35), 0.5, 10)
	local mirrorFrame = L(washX, FLOOR + 5.3, BACK + 0.55)
	deco("MirrorFrame", Vector3.new(2.7, 3.5, 0.2), mirrorFrame, Color3.fromRGB(50, 36, 26), M.Wood)
	local mirror = block("Mirror", Vector3.new(2.2, 3, 0.06), mirrorFrame * CFrame.new(0, 0, 0.12), Color3.fromRGB(150, 156, 160), M.Glass, { Reflectance = 0.55, CanCollide = false, Transparency = 0.05 })
	-- Sprünge im Glas
	Parts.beam({ Name = "Crack", Color = Color3.fromRGB(30, 30, 30), Material = M.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = folder }, (mirrorFrame * CFrame.new(0.7, 1.3, 0.17)).Position, (mirrorFrame * CFrame.new(0.1, 0.2, 0.17)).Position, 0.03)
	Parts.beam({ Name = "Crack", Color = Color3.fromRGB(30, 30, 30), Material = M.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = folder }, (mirrorFrame * CFrame.new(0.1, 0.2, 0.17)).Position, (mirrorFrame * CFrame.new(-0.6, -0.6, 0.17)).Position, 0.03)
	Parts.beam({ Name = "Crack", Color = Color3.fromRGB(30, 30, 30), Material = M.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = folder }, (mirrorFrame * CFrame.new(0.1, 0.2, 0.17)).Position, (mirrorFrame * CFrame.new(0.9, -0.3, 0.17)).Position, 0.03)
	info.mirror = mirror

	------------------------------------------------------------ Bücherregal und Wandschmuck (Rückwand Mitte)
	local shelfAt = L(-1.6, FLOOR, BACK + 0.9)
	block("Bookcase", Vector3.new(2.8, 6.4, 1.2), shelfAt * CFrame.new(0, 3.2, 0), LOG_DARK, M.Wood)
	for k = 0, 3 do
		local y = 0.7 + k * 1.5
		local x = -1.2
		while x < 1.1 do
			local width = rng:NextNumber(0.15, 0.3)
			local height = rng:NextNumber(0.8, 1.2)
			if rng:NextNumber() > 0.15 then
				deco("BookSpine", Vector3.new(width, height, 0.8), shelfAt * CFrame.new(x + width / 2, y + height / 2, -0.3), Color3.fromHSV(rng:NextNumber(0, 0.12), rng:NextNumber(0.3, 0.6), rng:NextNumber(0.2, 0.45)), M.SmoothPlastic)
			end
			x += width + 0.02
		end
	end
	-- Fallen und Seil an der Wand
	local trap = L(2.4 - 1.5, FLOOR + 5.6, BACK + 0.6)
	cyl("BearTrap", 0.12, 1.4, trap * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(80, 70, 60), M.Metal, { CanCollide = false })
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		deco("TrapTooth", Vector3.new(0.08, 0.25, 0.08), trap * CFrame.new(math.cos(a) * 0.55, math.sin(a) * 0.55, 0.05) * CFrame.Angles(0, 0, a - math.pi / 2), Color3.fromRGB(110, 100, 90), M.Metal)
	end

	------------------------------------------------------------ Bretterwand zur Schlafecke (x = 2.5, mit Durchgang)
	local partitionX = 2.5
	local doorwayFrom, doorwayTo = -9.4, -13.0 -- Durchgang (z)
	local function boards(fromZ, toZ)
		local z = fromZ
		while z > toZ + 0.05 do
			local width = math.min(0.8, z - toZ)
			block("PartitionBoard", Vector3.new(0.25, WALL_H, width - 0.03), L(partitionX, FLOOR + WALL_H / 2, z - width / 2), shade(PLANK, 0.3), M.WoodPlanks)
			z -= width
		end
	end
	boards(-8.6, doorwayFrom)
	-- Querwand zwischen Telefonecke und Schlafecke
	do
		local x = partitionX
		while x < HALF_W - 0.4 do
			local width = math.min(0.8, HALF_W - 0.4 - x)
			block("PartitionBoard", Vector3.new(width - 0.03, WALL_H, 0.25), L(x + width / 2, FLOOR + WALL_H / 2, -8.6), shade(PLANK, 0.3), M.WoodPlanks)
			x += width
		end
	end
	boards(doorwayTo, BACK + 0.45)
	deco("DoorwayBeam", Vector3.new(0.4, 0.5, -doorwayTo + doorwayFrom + 0.8), L(partitionX, FLOOR + 7.4, (doorwayFrom + doorwayTo) / 2), LOG_DARK, M.Wood)
	block("PartitionAbove", Vector3.new(0.25, WALL_H - 7.6, doorwayFrom - doorwayTo), L(partitionX, FLOOR + 7.6 + (WALL_H - 7.6) / 2, (doorwayFrom + doorwayTo) / 2), PLANK, M.WoodPlanks)
	-- Vorhang im Durchgang (halb zur Seite geschoben)
	deco("CurtainRod", Vector3.new(0.1, 0.1, -doorwayTo + doorwayFrom), L(partitionX - 0.25, FLOOR + 7.1, (doorwayFrom + doorwayTo) / 2), IRON, M.Metal)
	for k = 0, 3 do
		deco("Curtain", Vector3.new(0.08, 6.8, 0.42), L(partitionX - 0.25 + (k % 2) * 0.1, FLOOR + 3.65, doorwayFrom - 0.25 - k * 0.38) * CFrame.Angles(0, (k % 2 == 0) and 0.25 or -0.25, 0), Color3.fromRGB(96, 40, 34), M.Fabric)
	end

	------------------------------------------------------------ Schlafecke: Bett, Nachttisch mit dem Foto, Schrank
	local bed = L(7.2, FLOOR, BACK + 3.3) -- Kopfende an der Rückwand
	block("BedFrame", Vector3.new(4.4, 1.2, 6), bed * CFrame.new(0, 0.9, 0), LOG_DARK, M.Wood)
	block("Mattress", Vector3.new(4, 0.7, 5.6), bed * CFrame.new(0, 1.8, 0.1), Color3.fromRGB(176, 162, 130), M.Fabric)
	deco("Headboard", Vector3.new(4.6, 3.6, 0.4), bed * CFrame.new(0, 1.8, -2.9), LOG_DARK, M.Wood)
	for _, s in { -1, 1 } do
		cyl("BedPost", 4.4, 0.45, bed * CFrame.new(s * 2.2, 2.2, -2.9) * CFrame.Angles(0, 0, math.rad(90)), LOG, M.Wood, { CanCollide = false })
		cyl("BedPost", 2.2, 0.45, bed * CFrame.new(s * 2.2, 1.1, 2.9) * CFrame.Angles(0, 0, math.rad(90)), LOG, M.Wood, { CanCollide = false })
	end
	deco("Pillow", Vector3.new(2.4, 0.5, 1.1), bed * CFrame.new(0, 2.35, -2.1) * CFrame.Angles(0.1, 0, 0), Color3.fromRGB(210, 200, 180), M.Fabric)
	deco("Quilt", Vector3.new(4.2, 0.35, 3.8), bed * CFrame.new(0, 2.25, 0.9) * CFrame.Angles(0, 0.04, 0), Color3.fromRGB(110, 46, 40), M.Fabric)
	deco("QuiltFold", Vector3.new(3.4, 0.5, 0.9), bed * CFrame.new(-0.3, 2.4, -0.9) * CFrame.Angles(0.2, 0.08, 0), Color3.fromRGB(96, 38, 34), M.Fabric)
	for k = 0, 3 do
		deco("QuiltPatch", Vector3.new(0.9, 0.36, 0.9), bed * CFrame.new(-1.4 + k * 0.95, 2.26, 1.2 + (k % 2) * 0.9), Color3.fromRGB(150, 110, 70):Lerp(Color3.fromRGB(70, 80, 60), k / 4), M.Fabric)
	end
	-- Kratzspuren im Kopfteil
	for k = 0, 3 do
		deco("Scratch", Vector3.new(0.06, 1.6, 0.05), bed * CFrame.new(-0.6 + k * 0.3, 2.6, -2.68) * CFrame.Angles(0, 0, 0.25), Color3.fromRGB(150, 120, 90), M.Wood)
	end
	local bedPrompt = deco("BedPrompt", Vector3.new(1, 1, 1), bed * CFrame.new(0, 2.6, 0), Color3.new(), M.SmoothPlastic, { Transparency = 1 })
	info.bed = bedPrompt
	info.bedFrame = bed
	-- Nachttisch mit Kerze und dem Foto
	local stand = L(partitionX + 1.2, FLOOR, BACK + 1.3)
	block("Nightstand", Vector3.new(1.5, 2.4, 1.5), stand * CFrame.new(0, 1.2, 0), PLANK, M.WoodPlanks)
	deco("NightstandTop", Vector3.new(1.7, 0.12, 1.7), stand * CFrame.new(0, 2.46, 0), LOG_DARK, M.Wood)
	deco("NightstandDrawer", Vector3.new(1.2, 0.6, 0.06), stand * CFrame.new(0, 1.7, 0.76), PLANK_DARK, M.Wood)
	candle(stand * CFrame.new(-0.45, 2.52, -0.35), 0.45, 9)
	-- das Foto (Rahmen leicht nach hinten gekippt, Blick zum Durchgang)
	local photoAt = (stand * CFrame.new(0.2, 3.15, 0.1)).Position
	local photoFrame = CFrame.lookAt(photoAt, L(partitionX, FLOOR + 3.2, -11).Position) * CFrame.Angles(math.rad(10), 0, 0)
	deco("PhotoFrame", Vector3.new(0.95, 1.2, 0.1), photoFrame, Color3.fromRGB(70, 50, 34), M.Wood)
	deco("PhotoStand", Vector3.new(0.1, 1, 0.08), photoFrame * CFrame.new(0, -0.15, 0.3) * CFrame.Angles(math.rad(30), 0, 0), Color3.fromRGB(70, 50, 34), M.Wood)
	local photo = Parts.new("Part", { Name = "Photo", Size = Vector3.new(0.78, 1.02, 0.02), CFrame = photoFrame * CFrame.new(0, 0, -0.06), Color = Color3.fromRGB(150, 128, 96), Material = M.SmoothPlastic, CanCollide = false, CanTouch = false, CanQuery = true, Parent = folder })
	do
		-- ein altes Foto: Sarp vor dieser Hütte (sepia), unten "S."
		local gui = Parts.surfaceGui(photo, Enum.NormalId.Front, false)
		gui.PixelsPerStud = 160
		local function rect(x, y, w, h, color)
			local f = Instance.new("Frame")
			f.BorderSizePixel = 0
			f.BackgroundColor3 = color
			f.Position = UDim2.fromScale(x, y)
			f.Size = UDim2.fromScale(w, h)
			f.Parent = gui
			return f
		end
		rect(0, 0, 1, 1, Color3.fromRGB(170, 146, 110)) -- Himmel
		rect(0, 0.62, 1, 0.38, Color3.fromRGB(110, 90, 64)) -- Boden
		rect(0.05, 0.3, 0.55, 0.34, Color3.fromRGB(92, 72, 52)) -- Hütte
		rect(0.03, 0.22, 0.6, 0.1, Color3.fromRGB(70, 54, 40)) -- Dach
		rect(0.25, 0.44, 0.12, 0.2, Color3.fromRGB(50, 38, 28)) -- Tür
		-- die Gestalt: groß, dürr, mit Hut, ohne Gesicht
		rect(0.66, 0.12, 0.18, 0.04, Color3.fromRGB(46, 36, 28)) -- Hutkrempe
		rect(0.7, 0.04, 0.1, 0.09, Color3.fromRGB(46, 36, 28)) -- Hut
		rect(0.71, 0.16, 0.08, 0.09, Color3.fromRGB(140, 120, 96)) -- Kopf
		rect(0.67, 0.25, 0.16, 0.34, Color3.fromRGB(60, 62, 46)) -- Jacke
		rect(0.69, 0.59, 0.05, 0.22, Color3.fromRGB(46, 36, 28)) -- Beine
		rect(0.76, 0.59, 0.05, 0.22, Color3.fromRGB(46, 36, 28))
		local label = Parts.text(gui, { Text = "S.", TextColor3 = Color3.fromRGB(40, 30, 24), Font = Enum.Font.PermanentMarker })
		label.Size = UDim2.fromScale(0.3, 0.14)
		label.Position = UDim2.fromScale(0.05, 0.84)
		-- Flecken und Knicke
		local stain = rect(0.1, 0.7, 0.2, 0.12, Color3.fromRGB(120, 96, 70))
		stain.BackgroundTransparency = 0.4
		local crease = rect(0, 0.5, 1, 0.01, Color3.fromRGB(200, 186, 160))
		crease.BackgroundTransparency = 0.3
	end
	info.photo = photo
	-- Schrank, Stuhl mit Kleidern, Truhe
	local wardrobe = L(HALF_W - 1.1, FLOOR, -10.6)
	block("Wardrobe", Vector3.new(1.8, 7, 3.6), wardrobe * CFrame.new(0, 3.5, 0), LOG_DARK, M.WoodPlanks)
	for _, s in { -1, 1 } do
		deco("WardrobeDoor", Vector3.new(0.08, 6.4, 1.7), wardrobe * CFrame.new(-0.93, 3.4, s * 0.88), PLANK_DARK, M.WoodPlanks)
		ball("WardrobeKnob", 0.18, wardrobe * CFrame.new(-1, 3.6, s * 0.2), IRON, M.Metal)
	end
	-- (eine Tür einen Spalt offen, dahinter dunkel)
	deco("WardrobeGap", Vector3.new(0.06, 6.2, 0.12), wardrobe * CFrame.new(-0.95, 3.4, 0.02), Color3.new(0.02, 0.02, 0.02), M.SmoothPlastic)
	local trunk = L(7.2, FLOOR, BACK + 7.6)
	block("Trunk", Vector3.new(3.6, 1.6, 1.6), trunk * CFrame.new(0, 0.8, 0), Color3.fromRGB(80, 56, 38), M.Wood)
	for _, x in { -1.4, 1.4 } do
		deco("TrunkBand", Vector3.new(0.2, 1.65, 1.65), trunk * CFrame.new(x, 0.8, 0), IRON, M.Metal)
	end
	deco("TrunkLock", Vector3.new(0.4, 0.4, 0.1), trunk * CFrame.new(0, 1.2, 0.82), Color3.fromRGB(150, 130, 60), M.Metal)
	deco("Rope", Vector3.new(1.4, 0.3, 1.4), trunk * CFrame.new(0.6, 1.75, 0), Color3.fromRGB(150, 130, 90), M.Fabric)

	------------------------------------------------------------ Veranda vorne
	local porchDepth = 3.6
	for x = -6.4, 6.4, 0.8 do
		deco("PorchBoard", Vector3.new(0.76, 0.18, porchDepth), L(x, FLOOR - 0.05, porchDepth / 2 - 0.2), shade(PLANK, 0.35), M.WoodPlanks)
	end
	block("PorchCollider", Vector3.new(13.6, FLOOR + 0.6, porchDepth), L(0, (FLOOR - 0.6) / 2 + 0.3 - 0.3, porchDepth / 2 - 0.2), PLANK, M.Wood, { Transparency = 1 })
	-- Stufen (zwei Stufen nach unten)
	for k, depth in { 0.8, 1.6, 2.4 } do
		local height = FLOOR - k * FLOOR / 4
		block("Step", Vector3.new(4, height + 2, 0.8), L(0, (height - 2) / 2, porchDepth - 0.2 + depth - 0.4), shade(PLANK, 0.2), M.WoodPlanks)
	end
	-- Pfosten, Geländer, Vordach
	for _, x in { -6.4, 6.4, -2.4, 2.4 } do
		Parts.column({ Name = "PorchPost", Color = LOG, Material = M.Wood, Parent = folder }, 7.6, 0.5, L(x, FLOOR, porchDepth - 0.5))
	end
	for _, s in { -1, 1 } do
		deco("Rail", Vector3.new(3.8, 0.2, 0.2), L(s * 4.4, FLOOR + 2.6, porchDepth - 0.5), LOG_DARK, M.Wood)
		for k = 0, 4 do
			deco("Baluster", Vector3.new(0.14, 2.5, 0.14), L(s * (2.8 + k * 0.8), FLOOR + 1.3, porchDepth - 0.5), LOG_DARK, M.Wood)
		end
		block("SideRail", Vector3.new(0.2, 2.7, porchDepth), L(s * 6.4, FLOOR + 1.35, porchDepth / 2 - 0.2), LOG_DARK, M.Wood)
		block("FrontRailCollider", Vector3.new(4, 2.7, 0.3), L(s * 4.4, FLOOR + 1.35, porchDepth - 0.5), LOG_DARK, M.Wood, { Transparency = 1 })
	end
	local porchRoof = L(0, FLOOR + 8.1, porchDepth / 2) * CFrame.Angles(math.rad(-12), 0, 0)
	block("PorchRoof", Vector3.new(14.6, 0.35, porchDepth + 1.8), porchRoof, PLANK_DARK, M.WoodPlanks)
	for k = 0, 3 do
		deco("PorchShingles", Vector3.new(14.6, 0.1, 1.2), porchRoof * CFrame.new(0, 0.22, -1.6 + k * 1.15), shade(Color3.fromRGB(62, 58, 54), 0.3), M.Slate)
	end
	-- Laterne an der Tür (warmes Licht: man sieht die Hütte schon von Weitem)
	local doorLantern = L(2.9, FLOOR + 6.2, 0.25)
	deco("LanternArm", Vector3.new(0.1, 0.1, 0.8), doorLantern * CFrame.new(0, 0.55, -0.35), IRON, M.Metal)
	deco("DoorLantern", Vector3.new(0.55, 0.75, 0.55), doorLantern, Color3.fromRGB(255, 210, 150), M.Glass, { Transparency = 0.25 })
	deco("DoorLanternFlame", Vector3.new(0.14, 0.3, 0.14), doorLantern, Color3.fromRGB(255, 190, 90), M.Neon)
	deco("DoorLanternTop", Vector3.new(0.7, 0.18, 0.7), doorLantern * CFrame.new(0, 0.46, 0), IRON, M.Metal)
	light("PorchLight", doorLantern * CFrame.new(0, 0, 0.6), WARM, 22, 1.5)
	-- Schaukelstuhl, Fußmatte, Eimer
	local rocker = L(-4.4, FLOOR, 1.4) * CFrame.Angles(0, math.rad(200), 0)
	deco("RockerSeat", Vector3.new(1.6, 0.2, 1.6), rocker * CFrame.new(0, 1.6, 0), PLANK, M.Wood)
	deco("RockerBack", Vector3.new(1.6, 2.4, 0.2), rocker * CFrame.new(0, 2.9, 0.8) * CFrame.Angles(math.rad(-12), 0, 0), PLANK, M.Wood)
	for _, s in { -1, 1 } do
		deco("Rocker", Vector3.new(0.14, 0.2, 2.4), rocker * CFrame.new(s * 0.7, 0.15, 0), LOG_DARK, M.Wood)
		deco("RockerLeg", Vector3.new(0.14, 1.5, 0.14), rocker * CFrame.new(s * 0.7, 0.85, -0.6), LOG_DARK, M.Wood)
		deco("RockerLeg", Vector3.new(0.14, 1.5, 0.14), rocker * CFrame.new(s * 0.7, 0.85, 0.6), LOG_DARK, M.Wood)
	end
	deco("Doormat", Vector3.new(3, 0.05, 1.4), L(0, FLOOR + 0.06, 1.1), Color3.fromRGB(110, 90, 60), M.Fabric)

	------------------------------------------------------------ Draußen: Holzstapel, Hackklotz, Regentonne, Briefkasten
	for k = 0, 23 do
		local row = math.floor(k / 6)
		cyl("Woodpile", 2.2, 0.62, L(HALF_W + 1.2, 0.35 + row * 0.56, -3 - (k % 6) * 0.66 - (row % 2) * 0.3) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, math.rad(90), 0), shade(Color3.fromRGB(120, 92, 62), 0.3), M.Wood)
	end
	deco("WoodpileRoof", Vector3.new(2.6, 0.2, 4.6), L(HALF_W + 1.4, 3.2, -4.8) * CFrame.Angles(0, 0, math.rad(-10)), PLANK_DARK, M.WoodPlanks)
	block("WoodpileCollider", Vector3.new(2.4, 3, 4.4), L(HALF_W + 1.2, 1.5, -4.8), LOG, M.Wood, { Transparency = 1 })
	local stump = onGround(L(HALF_W + 1.8, 0, 3))
	Parts.column({ Name = "ChoppingBlock", Color = Color3.fromRGB(110, 84, 58), Material = M.Wood, Parent = folder }, 1.6, 1.8, stump)
	local axe = stump * CFrame.new(0.2, 2.1, 0) * CFrame.Angles(0, 0, math.rad(-25))
	deco("AxeHandle", Vector3.new(0.18, 2.4, 0.18), axe * CFrame.new(0, 0.6, 0), Color3.fromRGB(150, 116, 80), M.Wood)
	deco("AxeHead", Vector3.new(0.7, 0.5, 0.12), axe * CFrame.new(-0.15, -0.55, 0), Color3.fromRGB(120, 120, 116), M.Metal)
	for k = 0, 3 do
		deco("Chip", Vector3.new(0.5, 0.06, 0.25), stump * CFrame.new(rng:NextNumber(-1.8, 1.8), 0.05, rng:NextNumber(-1.8, 1.8)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Color3.fromRGB(170, 140, 100), M.Wood)
	end
	local barrel = onGround(L(-HALF_W - 0.6, 0, -1.4))
	Parts.column({ Name = "RainBarrel", Color = Color3.fromRGB(86, 62, 42), Material = M.WoodPlanks, Parent = folder }, 3, 2.2, barrel)
	for _, y in { 0.5, 2.5 } do
		Parts.column({ Name = "BarrelHoop", Color = IRON, Material = M.Metal, CanCollide = false, CanQuery = false, Parent = folder }, 0.15, 2.3, barrel * CFrame.new(0, y, 0))
	end
	Parts.column({ Name = "BarrelWater", Color = Color3.fromRGB(30, 34, 30), Material = M.Glass, CanCollide = false, CanQuery = false, Parent = folder }, 0.05, 2, barrel * CFrame.new(0, 2.85, 0))
	-- Briefkasten an der Straße: "SARP"
	local mailbox = onGround(road * CFrame.new(5.5, 0, SarpHut.ROAD_Z - SarpHut.ROAD_HALF - 1.2) * CFrame.Angles(0, math.rad(180), 0))
	Parts.column({ Name = "MailboxPost", Color = LOG_DARK, Material = M.Wood, Parent = folder }, 3.6, 0.35, mailbox)
	local box = deco("Mailbox", Vector3.new(0.9, 0.8, 1.6), mailbox * CFrame.new(0, 3.9, 0) * CFrame.Angles(0, 0, math.rad(4)), Color3.fromRGB(70, 74, 72), M.Metal)
	deco("MailboxFlag", Vector3.new(0.06, 0.6, 0.3), mailbox * CFrame.new(0.5, 4.3, 0.3), Color3.fromRGB(150, 40, 30), M.Metal)
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Parts.surfaceGui(box, face, false)
		gui.PixelsPerStud = 80
		Parts.text(gui, { Text = "SARP", TextColor3 = Color3.fromRGB(220, 214, 200), Font = Enum.Font.PermanentMarker })
	end
	-- kaputter Zaun links und rechts vom Weg zur Hütte
	for _, s in { -1, 1 } do
		for k = 0, 4 do
			local post = onGround(road * CFrame.new(s * (6.5 + k * 3), 0, SarpHut.ROAD_Z - SarpHut.ROAD_HALF - 2.2))
			if not (k == 2 and s == 1) then
				Parts.column({ Name = "FencePost", Color = shade(LOG_DARK, 0.3), Material = M.Wood, Parent = folder }, rng:NextNumber(2.4, 3.2), 0.35, post * CFrame.Angles(0, 0, rng:NextNumber(-0.12, 0.12)))
			end
			if k < 4 and rng:NextNumber() < 0.75 then
				local from = (post * CFrame.new(0, 2, 0)).Position
				local to = (post * CFrame.new(s * 3, 2 + rng:NextNumber(-0.6, 0.2), 0)).Position
				Parts.beam({ Name = "FenceRail", Color = shade(PLANK_DARK, 0.3), Material = M.Wood, CanCollide = false, CanQuery = false, Parent = folder }, from, to, 0.18)
			end
		end
	end

	-- Staub im Licht (Wohnraum)
	do
		local dust = deco("Dust", Vector3.new(14, 6, 14), L(-3, FLOOR + 4, -10), Color3.new(), M.SmoothPlastic, { Transparency = 1 })
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Dust"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 170))
		emitter.LightInfluence = 1
		emitter.Size = NumberSequence.new(0.06)
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(6, 10)
		emitter.Rate = 8
		emitter.Speed = NumberRange.new(0.05, 0.2)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Shape = Enum.ParticleEmitterShape.Box
		emitter.Parent = dust
	end

	------------------------------------------------------------ Der Hof: Sarps alter Pickup, Plumpsklo, Wäscheleine, Kisten
	local function R(x, z, angle)
		return onGround(road * CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(angle or 0), 0))
	end
	do
		-- verrosteter Pickup (Front zur Straße, ein Reifen platt)
		local truck = R(-21.5, -28, 172) * CFrame.Angles(0, 0, math.rad(1.5))
		local RUST = Color3.fromRGB(110, 62, 38)
		local PAINT = Color3.fromRGB(66, 78, 64)
		local function t(name, size, offset, color, material, extra)
			return deco(name, size, truck * offset, color, material, extra)
		end
		block("TruckBody", Vector3.new(6.4, 2.4, 15), truck * CFrame.new(0, 2.6, 0), PAINT, M.CorrodedMetal)
		t("TruckHood", Vector3.new(6.2, 0.4, 4.6), CFrame.new(0, 3.95, -5) * CFrame.Angles(math.rad(-2), 0, 0), PAINT, M.CorrodedMetal)
		t("TruckCab", Vector3.new(6, 2.6, 4.2), CFrame.new(0, 5.1, -0.9), PAINT, M.CorrodedMetal)
		t("TruckRoofDent", Vector3.new(2, 0.2, 1.6), CFrame.new(1, 6.42, -0.7), RUST, M.CorrodedMetal)
		t("Windshield", Vector3.new(5.6, 2, 0.12), CFrame.new(0, 5.1, -3.05) * CFrame.Angles(math.rad(-14), 0, 0), Color3.fromRGB(40, 46, 44), M.Glass, { Transparency = 0.35 })
		t("WindshieldCrack", Vector3.new(2.4, 0.05, 0.14), CFrame.new(-0.8, 5.3, -3.08) * CFrame.Angles(math.rad(-14), 0, math.rad(25)), Color3.fromRGB(200, 210, 210), M.SmoothPlastic, { Transparency = 0.3 })
		for _, side in { -1, 1 } do
			t("SideWindow", Vector3.new(0.12, 1.5, 2.8), CFrame.new(side * 3.01, 5.4, -1), Color3.fromRGB(40, 46, 44), M.Glass, { Transparency = 0.35 })
			t("BedWall", Vector3.new(0.3, 1.4, 6.6), CFrame.new(side * 3.05, 4.4, 4.1), PAINT, M.CorrodedMetal)
			t("RustPatch", Vector3.new(0.06, 1.2, 2.4), CFrame.new(side * 3.21, 2.6, rng:NextNumber(-5, 5)), RUST, M.CorrodedMetal)
			t("Headlight", Vector3.new(1, 0.7, 0.1), CFrame.new(side * 2.3, 3.2, -7.52), Color3.fromRGB(150, 150, 130), M.Glass)
			for _, z in { -4.8, 4.6 } do
				local flat = side == 1 and z > 0
				t("Tire", Vector3.new(1, 2.6, 2.6), CFrame.new(side * 3, flat and 1.0 or 1.3, z) * (flat and CFrame.new(0, 0, 0) or CFrame.identity), Color3.fromRGB(22, 22, 22), M.SmoothPlastic, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, flat and 2.1 or 2.6, 2.6) })
				t("Hub", Vector3.new(1.05, 1.1, 1.1), CFrame.new(side * 3, flat and 1.0 or 1.3, z), RUST, M.CorrodedMetal, { Shape = Enum.PartType.Cylinder })
			end
		end
		t("BedRear", Vector3.new(6.4, 1.4, 0.3), CFrame.new(0, 4.4, 7.4), PAINT, M.CorrodedMetal)
		t("Grille", Vector3.new(3.6, 1.2, 0.15), CFrame.new(0, 3.1, -7.55), Color3.fromRGB(80, 80, 76), M.Metal)
		t("Bumper", Vector3.new(6.6, 0.5, 0.4), CFrame.new(0, 2, -7.6), RUST, M.CorrodedMetal)
		-- auf der Ladefläche: Säcke, Seil, Kanister, eine Schaufel
		t("Sack", Vector3.new(1.8, 1, 2.6), CFrame.new(-1.3, 4.3, 3.6) * CFrame.Angles(0, 0.3, 0.1), Color3.fromRGB(130, 112, 84), M.Fabric)
		t("Sack", Vector3.new(1.8, 1, 2.6), CFrame.new(1.2, 4.3, 5.2) * CFrame.Angles(0, -0.2, -0.1), Color3.fromRGB(120, 104, 78), M.Fabric)
		t("Canister", Vector3.new(1, 1.6, 0.6), CFrame.new(2.2, 4.6, 2.2), Color3.fromRGB(130, 30, 26), M.Metal)
		t("Shovel", Vector3.new(0.15, 0.15, 4.6), CFrame.new(-0.4, 4.1, 4.4) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(110, 84, 58), M.Wood)
		t("TruckStain", Vector3.new(0.06, 0.8, 1.2), CFrame.new(-3.21, 3.1, 3.4), Color3.fromRGB(70, 20, 18), M.SmoothPlastic)
		-- Gras wächst um die Reifen (er steht schon lange hier)
		for k = 1, 6 do
			t("Weed", Vector3.new(0.12, rng:NextNumber(0.8, 1.6), 0.12), CFrame.new(rng:NextNumber(-3.6, 3.6), 0.5, rng:NextNumber(-7, 7)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3)), Color3.fromRGB(70, 90, 46), M.Grass)
		end
	end
	do
		-- Plumpsklo hinten rechts (Mond in der Tür)
		local o = R(21, -41, -20)
		block("Outhouse", Vector3.new(4.2, 7.4, 4.2), o * CFrame.new(0, 3.7, 0), shade(PLANK, 0.2), M.WoodPlanks)
		deco("OuthouseRoof", Vector3.new(5, 0.3, 5.2), o * CFrame.new(0, 7.6, 0.2) * CFrame.Angles(math.rad(10), 0, 0), PLANK_DARK, M.WoodPlanks)
		deco("OuthouseDoor", Vector3.new(3, 6.4, 0.15), o * CFrame.new(0, 3.4, 2.15), PLANK_DARK, M.WoodPlanks)
		deco("Moon", Vector3.new(0.5, 0.7, 0.18), o * CFrame.new(0, 5.6, 2.2), Color3.new(0.02, 0.02, 0.02), M.SmoothPlastic)
		for _, y in { 1.4, 5.4 } do
			deco("Hinge", Vector3.new(0.6, 0.12, 0.05), o * CFrame.new(-1.3, y, 2.25), IRON, M.Metal)
		end
	end
	do
		-- Wäscheleine von der Hütte zu einem Pfosten, mit alten Lumpen
		local pole = R(24, -31)
		Parts.column({ Name = "LinePole", Color = LOG_DARK, Material = M.Wood, Parent = folder }, 7.5, 0.4, pole)
		local from = L(HALF_W + 0.5, FLOOR + 6.5, -13).Position
		local to = (pole * CFrame.new(0, 7.1, 0)).Position
		local last = from
		for k = 1, 6 do
			local u = k / 6
			local point = from:Lerp(to, u) - Vector3.new(0, math.sin(u * math.pi) * 0.9, 0)
			Parts.beam({ Name = "Clothesline", Color = Color3.fromRGB(200, 196, 180), Material = M.Fabric, CanCollide = false, CanQuery = false, Parent = folder }, last, point, 0.05)
			last = point
		end
		local colors = { Color3.fromRGB(90, 30, 26), Color3.fromRGB(150, 140, 120), JACKET, Color3.fromRGB(70, 60, 50) }
		for k = 1, 4 do
			local u = k / 5
			local point = from:Lerp(to, u) - Vector3.new(0, math.sin(u * math.pi) * 0.9, 0)
			local size = Vector3.new(rng:NextNumber(1, 1.8), rng:NextNumber(1.4, 2.4), 0.05)
			deco("Rag", size, CFrame.lookAt(point, point + (to - from).Unit:Cross(Vector3.yAxis)) * CFrame.new(0, -size.Y / 2, 0) * CFrame.Angles(0, 0, rng:NextNumber(-0.1, 0.1)), colors[k], M.Fabric)
		end
	end
	do
		-- Kisten und ein Fass neben dem Holzstapel, Schubkarre
		local c = R(15.5, -31, 12)
		block("Crate", Vector3.new(2.4, 2.4, 2.4), c * CFrame.new(0, 1.2, 0), Color3.fromRGB(120, 92, 60), M.WoodPlanks)
		block("Crate", Vector3.new(2, 2, 2), c * CFrame.new(0.3, 3.4, 0.1) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(110, 84, 56), M.WoodPlanks)
		block("Crate", Vector3.new(2.2, 2.2, 2.2), c * CFrame.new(2.6, 1.1, 0.4) * CFrame.Angles(0, -0.3, 0), Color3.fromRGB(104, 80, 54), M.WoodPlanks)
		local drum = c * CFrame.new(-2.4, 0, 1.2)
		Parts.column({ Name = "OilDrum", Color = Color3.fromRGB(70, 40, 30), Material = M.CorrodedMetal, Parent = folder }, 3.2, 2, drum)
		local wb = R(-14, -16, 30)
		deco("Wheelbarrow", Vector3.new(2.2, 1, 3), wb * CFrame.new(0, 1.6, 0) * CFrame.Angles(math.rad(-8), 0, 0), Color3.fromRGB(90, 70, 50), M.CorrodedMetal)
		deco("WheelbarrowWheel", Vector3.new(0.3, 1.3, 1.3), wb * CFrame.new(0, 0.65, -1.8), Color3.fromRGB(30, 30, 30), M.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
		for _, side in { -1, 1 } do
			deco("WheelbarrowHandle", Vector3.new(0.15, 0.15, 3), wb * CFrame.new(side * 0.8, 1.2, 1.8) * CFrame.Angles(math.rad(12), 0, 0), Color3.fromRGB(110, 84, 58), M.Wood)
		end
	end
	do
		-- Telefonmasten an der Straße (eine Leitung führt zur Hütte)
		local poleZ = SarpHut.ROAD_Z + SarpHut.ROAD_HALF + 0.8
		local tops = {}
		for _, x in { -128, -90, -52, 14, 52, 90, 128 } do
			local base = R(x, poleZ, rng:NextNumber(-3, 3)) * CFrame.Angles(rng:NextNumber(-0.03, 0.03), 0, rng:NextNumber(-0.03, 0.03))
			Parts.column({ Name = "TelephonePole", Color = Color3.fromRGB(72, 56, 42), Material = M.Wood, Parent = folder }, 17, 0.75, base)
			deco("PoleCrossbar", Vector3.new(4.2, 0.35, 0.35), base * CFrame.new(0, 15.6, 0), Color3.fromRGB(72, 56, 42), M.Wood)
			for _, side in { -1.6, 1.6 } do
				deco("Insulator", Vector3.new(0.25, 0.4, 0.25), base * CFrame.new(side, 16, 0), Color3.fromRGB(90, 130, 110), M.Glass)
			end
			table.insert(tops, { x = x, base = base })
		end
		local function wire(from, to, sag)
			local last = from
			for k = 1, 8 do
				local u = k / 8
				local point = from:Lerp(to, u) - Vector3.new(0, math.sin(u * math.pi) * sag, 0)
				Parts.beam({ Name = "Wire", Color = Color3.fromRGB(20, 20, 20), Material = M.SmoothPlastic, CanCollide = false, CanQuery = false, CastShadow = false, Parent = folder }, last, point, 0.06)
				last = point
			end
		end
		for i = 1, #tops - 1 do
			for _, side in { -1.6, 1.6 } do
				wire((tops[i].base * CFrame.new(side, 16.2, 0)).Position, (tops[i + 1].base * CFrame.new(side, 16.2, 0)).Position, 2.2)
			end
		end
		for _, top in tops do
			if top.x == 14 then
				wire((top.base * CFrame.new(-1.6, 16.2, 0)).Position, L(HALF_W - 1, FLOOR + WALL_H + 0.6, -0.2).Position, 1.4)
			end
		end
		-- Straßenschild am Ende des Wegs und ein Warnschild am Zaun
		local signPost = R(-11.5, SarpHut.ROAD_Z - SarpHut.ROAD_HALF - 1.6, 0)
		Parts.column({ Name = "SignPost", Color = LOG_DARK, Material = M.Wood, Parent = folder }, 7, 0.35, signPost)
		local sign = deco("RoadSign", Vector3.new(4.4, 1, 0.12), signPost * CFrame.new(0, 6.3, -0.2) * CFrame.Angles(0, 0, math.rad(-3)), Color3.fromRGB(46, 80, 50), M.Metal)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local gui = Parts.surfaceGui(sign, face, false)
			Parts.text(gui, { Text = "OLD FOREST RD", TextColor3 = Color3.fromRGB(230, 230, 220), Font = Enum.Font.GothamBold })
		end
		local warning = deco("KeepOut", Vector3.new(2.6, 1.6, 0.1), road * CFrame.new(-9.5, 2.4, SarpHut.ROAD_Z - SarpHut.ROAD_HALF - 2.1) * CFrame.Angles(0, 0, math.rad(6)), Color3.fromRGB(200, 190, 160), M.WoodPlanks)
		warning.CFrame = onGround(warning.CFrame - Vector3.new(0, 2.4, 0)) + Vector3.new(0, 2.4, 0)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local gui = Parts.surfaceGui(warning, face, false)
			Parts.text(gui, { Text = "PRIVATE PROPERTY\nKEEP OUT", TextColor3 = Color3.fromRGB(140, 24, 20), Font = Enum.Font.PermanentMarker })
		end
	end
	do
		-- Glühwürmchen über der Lichtung
		local area = deco("Fireflies", Vector3.new(50, 5, 40), road * CFrame.new(0, 4, -26), Color3.new(), M.SmoothPlastic, { Transparency = 1 })
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Fireflies"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(210, 255, 120))
		emitter.LightEmission = 1
		emitter.Brightness = 3
		emitter.Size = NumberSequence.new(0.22)
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.1), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(4, 7)
		emitter.Rate = 5
		emitter.Speed = NumberRange.new(0.3, 0.9)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Drag = 0.5
		emitter.Shape = Enum.ParticleEmitterShape.Box
		emitter.Parent = area
	end

	-- Bereich innen (zum Prüfen, ob jemand drin ist): im Rahmen der Hütte
	info.inside = function(position)
		local p = hutFrame:PointToObjectSpace(position)
		return math.abs(p.X) < HALF_W - 0.3 and p.Z < -0.8 and p.Z > BACK + 0.3 and p.Y > -2 and p.Y < WALL_H + 4
	end
	-- wo die Spieler zum Schluss stehen (vor der Tür auf der Veranda) und wo das Auto hält
	info.porch = L(0, FLOOR, 2)
	info.door = L(0, FLOOR + 3.5, -0.5).Position
	info.carStop = onGround(road * CFrame.new(-2, 0, SarpHut.ROAD_Z) * CFrame.Angles(0, math.rad(-90), 0)) -- Blick nach +X
	info.roadFrom = road * CFrame.new(-150, 0, SarpHut.ROAD_Z)
	info.roadTo = road * CFrame.new(150, 0, SarpHut.ROAD_Z)
	info.bedView = bed * CFrame.new(0, 3.6, 0.6)
	-- Kamera beim Ende: drinnen (Blick zur offenen Tür, Blaulicht) und draußen über die Straße
	info.endInside = CFrame.lookAt(L(-3.5, FLOOR + 4.6, -15).Position, L(0.5, FLOOR + 3.4, 0).Position)
	info.endOutside = CFrame.lookAt((road * CFrame.new(-23, 6, -1)).Position, (road * CFrame.new(-2, 3, -9)).Position)
	return info
end

return SarpHut
