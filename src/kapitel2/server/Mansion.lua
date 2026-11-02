-- Kapitel 2: das große Herrenhaus der Wagners (Bauplan: docs/konzept/hausplan.html).
-- Keller, Erdgeschoss, Obergeschoss, runder Turm vorne rechts, Erker, ein sechseckiger
-- Glas-Wintergarten, ein Ritualraum im Keller und ein Tunnel in den Wald.
--
-- Alle Maße stehen in "Plan-Koordinaten" wie im Bauplan (x nach rechts, y nach vorne,
-- vorne ist die Haustür bei y = 72). L() rechnet sie in Haus-Koordinaten um.
-- Die Eingangshalle liegt genau dort, wo sie beim kleinen Haus war (Veranda und Tür
-- bleiben gleich, das Gespräch in Kapitel2.lua funktioniert unverändert).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.Parts)
local Route = require(ReplicatedStorage.Shared.LevelRoute)
local Furniture = require(script.Parent.Furniture)
local HouseInterior = require(script.Parent.HouseInterior)

local Mansion = {}
Mansion.doors = {}
Mansion.beds = {}

local BASE, STORY = 1.6, 10
local TOP = BASE + 2 * STORY -- Oberkante Wände Obergeschoss
local TOWER_TOP = TOP + 8
local FLOOR = { K = -8.3, E = BASE + 0.1, O = BASE + STORY, T = TOP } -- Oberkante Fußboden
local CEIL = { K = -0.5, E = BASE + STORY - 0.6, O = TOP - 0.4, T = TOWER_TOP - 0.4 } -- Unterkante Decke
local WALL_Y = { K = { -8.6, -0.5 }, E = { -0.5, BASE + STORY }, O = { BASE + STORY, TOP }, T = { TOP, TOWER_TOP } }
local THICK = { ext = 0.8, int = 0.5, stone = 1.0, glass = 0.4 }

Mansion.FLOOR = FLOOR

local COLORS = {
	siding = Color3.fromRGB(92, 84, 72),
	sidingLine = Color3.fromRGB(64, 57, 49),
	trim = Color3.fromRGB(150, 144, 130),
	plaster = Color3.fromRGB(150, 140, 122),
	ceiling = Color3.fromRGB(120, 112, 98),
	stone = Color3.fromRGB(78, 74, 68),
	roof = Color3.fromRGB(46, 44, 44),
	ridge = Color3.fromRGB(30, 30, 30),
	glass = Color3.fromRGB(12, 14, 16),
	glassHouse = Color3.fromRGB(110, 130, 128),
	shutter = Color3.fromRGB(38, 52, 44),
	curtain = Color3.fromRGB(120, 112, 100),
	door = Color3.fromRGB(52, 40, 30),
	wood = Color3.fromRGB(58, 44, 32),
	brick = Color3.fromRGB(84, 50, 40),
	metal = Color3.fromRGB(70, 72, 76),
	board = Color3.fromRGB(40, 30, 22),
	blood = Color3.fromRGB(110, 16, 14),
}
local M = Enum.Material

------------------------------------------------------------------ Geometrie
local function L(x, y, height)
	return Vector3.new(x - 50, height or 0, 57.4 - y)
end

local function octagon(cx, cy, r, sides, start)
	local points = {}
	for i = 0, sides - 1 do
		local angle = math.rad(start + i * 360 / sides)
		table.insert(points, { cx + r * math.cos(angle), cy + r * math.sin(angle) })
	end
	return points
end

local function R(x0, y0, x1, y1)
	return { { x0, y0 }, { x1, y0 }, { x1, y1 }, { x0, y1 } }
end

local TOWER = octagon(84, 66, 9, 8, 22.5)
local K = {} -- die Turm-Ecken einzeln: K[0] … K[7]
for i = 0, 7 do
	K[i] = TOWER[i + 1]
end
local HEX = octagon(14, 19.6, 12, 6, 0) -- Wintergarten
local RITUAL = octagon(47, 3, 9.3, 12, 15)

local function pointInPolygon(x, y, poly)
	local inside = false
	local j = #poly
	for i = 1, #poly do
		local xi, yi, xj, yj = poly[i][1], poly[i][2], poly[j][1], poly[j][2]
		if (yi > y) ~= (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi then
			inside = not inside
		end
		j = i
	end
	return inside
end

-- Vieleck in Dreiecke zerlegen (Ohren abschneiden)
local function triangulate(poly)
	local points = {}
	for _, p in poly do
		table.insert(points, p)
	end
	local area = 0
	for i = 1, #points do
		local a, b = points[i], points[i % #points + 1]
		area += a[1] * b[2] - b[1] * a[2]
	end
	local sign = area > 0 and 1 or -1
	local function cross(a, b, c)
		return (b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1])
	end
	-- Punkte auf einer Geraden entfernen
	local i = 1
	while i <= #points and #points > 3 do
		local a, b, c = points[(i - 2) % #points + 1], points[i], points[i % #points + 1]
		if math.abs(cross(a, b, c)) < 1e-6 then
			table.remove(points, i)
		else
			i += 1
		end
	end
	local function inTriangle(p, a, b, c)
		local d1, d2, d3 = cross(a, b, p) * sign, cross(b, c, p) * sign, cross(c, a, p) * sign
		return d1 > 1e-6 and d2 > 1e-6 and d3 > 1e-6
	end
	local triangles = {}
	local guard = 0
	while #points > 3 and guard < 200 do
		guard += 1
		local found = false
		for index = 1, #points do
			local a, b, c = points[(index - 2) % #points + 1], points[index], points[index % #points + 1]
			if cross(a, b, c) * sign > 1e-6 then
				local blocked = false
				for _, p in points do
					if p ~= a and p ~= b and p ~= c and inTriangle(p, a, b, c) then
						blocked = true
						break
					end
				end
				if not blocked then
					table.insert(triangles, { a, b, c })
					table.remove(points, index)
					found = true
					break
				end
			end
		end
		if not found then
			break
		end
	end
	if #points == 3 then
		table.insert(triangles, points)
	end
	return triangles
end

------------------------------------------------------------------ Bauhelfer
local origin, current
local rng = Random.new(1313)

-- Kurz Luft holen: Roblox bricht ein Skript ab, das zu lange ohne Pause läuft
-- ("Script timeout"). Das Haus hat über 5000 Teile, darum wird zwischendurch
-- immer wieder einen Moment gewartet.
local lastBreath = os.clock()
local function breathe()
	if os.clock() - lastBreath > 0.1 then
		task.wait()
		lastBreath = os.clock()
	end
end
Mansion.breathe = breathe

local function box(name, size, cf, color, material, extra)
	breathe()
	local props = { Name = name, Size = size, CFrame = origin * cf, Color = color, Material = material or M.SmoothPlastic, Parent = current }
	for key, value in extra or {} do
		props[key] = value
	end
	return Parts.new("Part", props)
end

local function cyl(name, height, diameter, cf, color, material, extra)
	breathe()
	local props = { Name = name, Color = color, Material = material or M.SmoothPlastic, Parent = current }
	for key, value in extra or {} do
		props[key] = value
	end
	return Parts.column(props, height, diameter, origin * cf)
end

local function ball(name, diameter, cf, color, material)
	return box(name, Vector3.new(diameter, diameter, diameter), cf, color, material, { Shape = Enum.PartType.Ball })
end

-- Balken zwischen zwei Punkten (Haus-Koordinaten)
local function beam(name, from, to, thickness, color, material)
	local length = (to - from).Magnitude
	local middle = (from + to) / 2
	local up = math.abs((to - from).Unit.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
	return box(name, Vector3.new(thickness, thickness, length), CFrame.lookAt(middle, to, up), color, material or M.Wood)
end

-- Dreieck (Haus-Koordinaten) aus zwei Keilen, `thickness` dick
local function triangle(name, a, b, c, thickness, color, material, extra)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	if ac:Cross(ab).Magnitude < 1e-6 then
		return
	end
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local w1, w2 = math.abs(ab:Dot(back)), math.abs(ac:Dot(back))
	local m1, m2 = (a + b) / 2, (a + c) / 2
	local function wedge(size, cf)
		if size.Y < 0.01 or size.Z < 0.01 then
			return
		end
		breathe()
		local props = { Name = name, Size = size, CFrame = origin * cf, Color = color, Material = material or M.SmoothPlastic, Parent = current }
		for key, value in extra or {} do
			props[key] = value
		end
		Parts.new("WedgePart", props)
	end
	wedge(Vector3.new(thickness, height, w1), CFrame.lookAt(m1, m1 - back, up))
	wedge(Vector3.new(thickness, height, w2), CFrame.lookAt(m2, m2 + back, up))
end

local builder = {
	box = box,
	boxWorld = box,
	cyl = cyl,
	ball = ball,
	beam = function(name, from, to, thickness, color, material)
		return beam(name, from, to, thickness, color, material)
	end,
}

-- Stelle auf dem Boden: Plan-Koordinaten, Höhe, Blickrichtung ("N" = nach hinten,
-- "S" = nach vorne, "E" = nach rechts, "W" = nach links) oder ein Winkel in Grad
local DIRS = { N = Vector3.new(0, 0, 1), S = Vector3.new(0, 0, -1), E = Vector3.new(1, 0, 0), W = Vector3.new(-1, 0, 0) }
local function at(x, y, height, facing)
	local position = L(x, y, height)
	local direction = DIRS[facing or "S"]
	if type(facing) == "number" then
		direction = Vector3.new(math.sin(math.rad(facing)), 0, math.cos(math.rad(facing)))
	end
	return CFrame.lookAt(position, position + direction)
end

local function candle(cf, height, range, brightness)
	return HouseInterior.candle(current, origin * cf, height, range, brightness)
end

local function newFolder(name, parent)
	local folder = Instance.new("Model")
	folder.Name = name
	folder.Parent = parent
	return folder
end

------------------------------------------------------------------ Räume
-- wall = Tapete (Farbe, Material), wainscot = Holzverkleidung unten,
-- floor = Fußboden. Erdgeschoss = E, Obergeschoss = O, Keller = K, Turmspitze = T.
local WOOD_FLOOR = { Color3.fromRGB(58, 44, 32), M.WoodPlanks }
local TILE_FLOOR = { Color3.fromRGB(96, 92, 86), M.Slate }
local KITCHEN_FLOOR = { Color3.fromRGB(110, 104, 92), M.Slate }
local STONE_FLOOR = { Color3.fromRGB(70, 68, 64), M.Concrete }

local ROOMS = {
	E = {
		{ id = "hall", name = "Eingangshalle", poly = R(41.75, 54.15, 54.25, 72), wall = { Color3.fromRGB(58, 66, 56), M.Fabric }, wainscot = true, floor = WOOD_FLOOR, void = true },
		{ id = "flur", name = "Flur", poly = { { 34, 42 }, { 54.25, 42 }, { 54.25, 54.15 }, { 41.75, 54.15 }, { 41.75, 60 }, { 34, 60 } }, wall = { Color3.fromRGB(72, 60, 52), M.Fabric }, wainscot = true, floor = WOOD_FLOOR },
		{ id = "wohn", name = "Wohnzimmer", poly = { { 54.25, 42 }, { 80.56, 42 }, K[5], K[4], K[3], { 72.5, 72 }, { 54.25, 72 } }, wall = { Color3.fromRGB(84, 50, 46), M.Fabric }, floor = WOOD_FLOOR },
		{ id = "turm", name = "Turmzimmer", poly = TOWER, wall = { Color3.fromRGB(60, 70, 74), M.Fabric }, floor = WOOD_FLOOR },
		{ id = "ess", name = "Esszimmer", poly = { { 54.25, 18 }, { 66, 18 }, { 68, 12 }, { 76, 12 }, { 78, 18 }, { 80.56, 18 }, { 80.56, 42 }, { 54.25, 42 } }, wall = { Color3.fromRGB(52, 60, 48), M.Fabric }, wainscot = true, floor = WOOD_FLOOR },
		{ id = "kueche", name = "Küche", poly = { { 34, 20 }, { 54.25, 20 }, { 54.25, 22 }, { 50, 22 }, { 50, 34 }, { 54.25, 34 }, { 54.25, 42 }, { 34, 42 } }, wall = { Color3.fromRGB(150, 140, 112), M.SmoothPlastic }, tiles = true, floor = KITCHEN_FLOOR },
		{ id = "kellertreppe", name = "Kellertreppe", poly = R(50, 22, 54.25, 34), wall = { Color3.fromRGB(110, 102, 88), M.SmoothPlastic }, noFloor = true },
		{ id = "speise", name = "Speisekammer", poly = R(40, 8, 54.25, 20), wall = { Color3.fromRGB(110, 100, 84), M.SmoothPlastic }, floor = KITCHEN_FLOOR },
		{ id = "salon", name = "Salon", poly = R(14, 38, 34, 60), wall = { Color3.fromRGB(64, 56, 74), M.Fabric }, wainscot = true, floor = WOOD_FLOOR },
		{ id = "arbeit", name = "Arbeitszimmer", poly = { { 10, 60 }, { 36, 60 }, { 36, 80 }, { 18, 80 }, { 10, 72 } }, wall = { Color3.fromRGB(62, 46, 34), M.WoodPlanks }, floor = WOOD_FLOOR },
		{ id = "wc", name = "WC", poly = R(36, 60, 41.75, 72), wall = { Color3.fromRGB(150, 150, 140), M.CeramicTiles }, floor = TILE_FLOOR },
		{ id = "gartenflur", name = "Flur zum Garten", poly = { { 8, 30 }, { 34, 30 }, { 34, 38 }, { 14, 38 }, { 8, 34 } }, wall = { Color3.fromRGB(100, 94, 80), M.SmoothPlastic }, floor = TILE_FLOOR },
		{ id = "winter", name = "Wintergarten", poly = HEX, floor = { Color3.fromRGB(80, 80, 76), M.Slate }, glass = true },
	},
	O = {
		{ id = "hall", name = "Eingangshalle", poly = R(41.75, 54.15, 54.25, 72), wall = { Color3.fromRGB(58, 66, 56), M.Fabric }, void = true },
		{ id = "gang", name = "Langer Flur", poly = { { 34, 34 }, { 80.56, 34 }, { 80.56, 44 }, { 74.56, 52 }, { 62, 52 }, { 62, 40 }, { 34, 40 } }, wall = { Color3.fromRGB(66, 58, 50), M.Fabric }, wainscot = true, floor = WOOD_FLOOR },
		{ id = "tuer1", name = "Tür 1", poly = R(41.75, 40, 48.6, 54.15), wall = { Color3.fromRGB(40, 36, 32), M.Fabric }, floor = WOOD_FLOOR },
		{ id = "gaeste", name = "Gästezimmer", poly = R(48.6, 40, 62, 54.15), wall = { Color3.fromRGB(96, 84, 66), M.Fabric }, floor = WOOD_FLOOR },
		{ id = "spiel", name = "Spielzimmer", poly = { { 54.25, 54.15 }, { 62, 54.15 }, { 62, 52 }, { 74.56, 52 }, { 80.56, 44 }, K[5], K[4], K[3], { 72.5, 72 }, { 54.25, 72 } }, wall = { Color3.fromRGB(110, 100, 60), M.Fabric }, floor = WOOD_FLOOR },
		{ id = "naeh", name = "Nähzimmer", poly = TOWER, wall = { Color3.fromRGB(100, 80, 80), M.Fabric }, floor = WOOD_FLOOR },
		{ id = "tommy", name = "Zimmer Tommy", poly = R(34, 20, 44, 34), wall = { Color3.fromRGB(70, 90, 110), M.Fabric }, floor = WOOD_FLOOR },
		{ id = "lucy", name = "Zimmer Lucy", poly = R(44, 20, 54.25, 34), wall = { Color3.fromRGB(120, 90, 100), M.Fabric }, floor = WOOD_FLOOR },
		{ id = "bad", name = "Bad", poly = R(54.25, 18, 64, 34), wall = { Color3.fromRGB(160, 160, 150), M.CeramicTiles }, floor = TILE_FLOOR },
		{ id = "eltern", name = "Elternschlafzimmer", poly = { { 64, 18 }, { 66, 18 }, { 68, 12 }, { 76, 12 }, { 78, 18 }, { 80.56, 18 }, { 80.56, 34 }, { 64, 34 } }, wall = { Color3.fromRGB(80, 64, 56), M.Fabric }, floor = WOOD_FLOOR },
		{ id = "oma", name = "Großmutters Zimmer", poly = { { 14, 38 }, { 34, 38 }, { 34, 40 }, { 41.75, 40 }, { 41.75, 60 }, { 14, 60 } }, wall = { Color3.fromRGB(90, 86, 70), M.Fabric }, floor = WOOD_FLOOR },
	},
	T = {
		{ id = "turmspitze", name = "Turmspitze", poly = TOWER, wall = { Color3.fromRGB(70, 60, 50), M.WoodPlanks } },
	},
	K = {
		{ id = "vorrat", name = "Vorratskeller", poly = R(34, 20, 54.25, 34), floor = STONE_FLOOR },
		{ id = "kgang", name = "Kellergang", poly = R(34, 34, 54.25, 42), floor = STONE_FLOOR },
		{ id = "wasch", name = "Waschkeller", poly = R(14, 38, 34, 60), floor = STONE_FLOOR },
		{ id = "heiz", name = "Heizungsraum", poly = R(54.25, 18, 70, 42), floor = STONE_FLOOR },
		{ id = "kriech", name = "Kriechkeller", poly = R(70, 18, 80.56, 42), floor = STONE_FLOOR, ceiling = -2.3 },
		{ id = "gang", name = "Geheimgang", poly = R(45, 12, 49, 20), floor = STONE_FLOOR, ceiling = -2.6 },
		{ id = "ritual", name = "Ritualraum", poly = RITUAL, floor = { Color3.fromRGB(40, 38, 36), M.Slate }, ceiling = -2.3 },
	},
}

local function roomAt(floorKey, x, y)
	for _, room in ROOMS[floorKey] do
		if pointInPolygon(x, y, room.poly) then
			return room
		end
	end
	return nil
end

------------------------------------------------------------------ Wände
-- Öffnungen: { x, y, kind, w = Breite, h = Höhe, sill = Brüstung, angle = Tür offen (Grad),
-- swing = in welchen Raum die Tür aufgeht (id), boards = vernagelt (zu welchem Raum hin),
-- locked = abgeschlossen (alle anderen Türen kann man mit E öffnen und schließen) }
local DOOR_W, DOOR_H = 3.6, 7.6
local WINDOW_W, WINDOW_H, SILL = 3.2, 5.2, 3.0

local function toPlan(v)
	return v.X + 50, 57.4 - v.Z
end

local function buildWall(floorKey, a, b, kind, openings, topOverride)
	local A, B = L(a[1], a[2]), L(b[1], b[2])
	local span = B - A
	local length = span.Magnitude
	if length < 0.05 then
		return
	end
	local dir = span.Unit
	local normal = Vector3.new(-dir.Z, 0, dir.X)
	local t = THICK[kind]
	local y0, y1 = WALL_Y[floorKey][1], WALL_Y[floorKey][2]
	if floorKey == "E" and kind == "ext" then
		y0 = -1.2
	end
	if kind == "glass" then
		y1 = FLOOR.E + 8
	end
	if topOverride then
		y1 = topOverride
	end
	local floorTop = FLOOR[floorKey]
	local extend = kind == "int" and 0.2 or 0

	-- welche Räume liegen links und rechts?
	local function sideRoom(side)
		local probe = A + span / 2 + normal * side * (t / 2 + 0.9)
		local x, y = toPlan(probe)
		return roomAt(floorKey, x, y)
	end
	local rooms = { [1] = sideRoom(1), [-1] = sideRoom(-1) }

	local function piece(s0, s1, ya, yb)
		if s1 - s0 < 0.02 or yb - ya < 0.02 then
			return
		end
		local middle = A + dir * ((s0 + s1) / 2) + Vector3.new(0, (ya + yb) / 2, 0)
		local frame = CFrame.lookAt(middle, middle + normal)
		local len, height = s1 - s0, yb - ya
		if kind == "glass" then
			-- Glaswand: weißer Holzsockel, Glas, Sprossen
			local knee = math.min(yb, floorTop + 2.2)
			if knee > ya then
				local kc = A + dir * ((s0 + s1) / 2) + Vector3.new(0, (ya + knee) / 2, 0)
				box("GlassWallBase", Vector3.new(len, knee - ya, t + 0.1), CFrame.lookAt(kc, kc + normal), COLORS.trim, M.Wood)
			end
			if yb > knee then
				local gc = A + dir * ((s0 + s1) / 2) + Vector3.new(0, (knee + yb) / 2, 0)
				box("GlassPane", Vector3.new(len, yb - knee, 0.12), CFrame.lookAt(gc, gc + normal), COLORS.glassHouse, M.Glass, { Transparency = 0.55 })
				local count = math.max(1, math.floor(len / 2.2))
				for i = 1, count - 1 do
					local mc = A + dir * (s0 + i * len / count) + Vector3.new(0, (knee + yb) / 2, 0)
					box("Mullion", Vector3.new(0.16, yb - knee, t + 0.06), CFrame.lookAt(mc, mc + normal), COLORS.trim, M.Wood)
				end
				box("GlassRail", Vector3.new(len, 0.2, t + 0.06), frame * CFrame.new(0, (yb - 0.1) - (ya + yb) / 2, 0), COLORS.trim, M.Wood)
			end
			return
		end
		local color = kind == "ext" and COLORS.siding or kind == "stone" and COLORS.stone or COLORS.plaster
		local material = kind == "ext" and M.WoodPlanks or kind == "stone" and M.Cobblestone or M.SmoothPlastic
		box(kind == "stone" and "StoneWall" or "Wall", Vector3.new(len, height, t), frame, color, material)

		for _, side in { 1, -1 } do
			local room = rooms[side]
			local offset = side * t / 2
			if room and room.wall then
				local ceiling = room.ceiling or CEIL[floorKey]
				-- `grow` = etwas länger als die Wand, damit die Enden nicht genau mit der Tapete
				-- abschließen (sonst flackern die Flächen in Roblox)
				local function panel(name, from, to, depth, panelColor, panelMaterial, grow)
					local lo, hi = math.max(from, ya), math.min(to, yb)
					if hi - lo > 0.02 then
						local pc = A + dir * ((s0 + s1) / 2) + normal * (offset + side * (0.02 + depth / 2)) + Vector3.new(0, (lo + hi) / 2, 0)
						box(name, Vector3.new(len + (grow or 0), hi - lo, depth), CFrame.lookAt(pc, pc + normal), panelColor, panelMaterial)
					end
				end
				if room.wainscot then
					panel("Wallpaper", floorTop + 3.1, ceiling, 0.06, room.wall[1], room.wall[2])
					panel("Wainscot", floorTop, floorTop + 3.1, 0.12, Color3.fromRGB(46, 36, 28), M.WoodPlanks, 0.02)
					panel("ChairRail", floorTop + 3.0, floorTop + 3.25, 0.2, Color3.fromRGB(70, 56, 42), M.Wood, 0.04)
				elseif room.tiles then
					panel("Wallpaper", floorTop + 4, ceiling, 0.06, room.wall[1], room.wall[2])
					panel("WallTiles", floorTop, floorTop + 4, 0.1, Color3.fromRGB(176, 172, 158), M.CeramicTiles)
				else
					panel("Wallpaper", floorTop + 0.45, ceiling, 0.06, room.wall[1], room.wall[2])
					panel("Baseboard", floorTop, floorTop + 0.45, 0.14, Color3.fromRGB(46, 36, 28), M.Wood, 0.03)
				end
			elseif not room and kind == "ext" then
				-- außen: waagerechte Bretter und ein Steinsockel
				local first = math.max(ya, BASE + 0.9)
				local yy = BASE + 0.9
				while yy < first do
					yy += 1.1
				end
				while yy < yb - 0.3 do
					if math.abs(yy - (BASE + STORY)) > 0.45 then
						local bc = A + dir * ((s0 + s1) / 2) + normal * (offset + side * 0.06) + Vector3.new(0, yy, 0)
						box("Siding", Vector3.new(len - 0.02, 0.12, 0.12), CFrame.lookAt(bc, bc + normal), COLORS.sidingLine, M.Wood)
					end
					yy += 1.1
				end
				if floorKey == "E" and ya < BASE then
					local hi = math.min(BASE, yb)
					local sc = A + dir * ((s0 + s1) / 2) + normal * (offset + side * 0.15) + Vector3.new(0, (ya + hi) / 2, 0)
					box("Plinth", Vector3.new(len, hi - ya, 0.3), CFrame.lookAt(sc, sc + normal), COLORS.stone, M.Cobblestone)
				end
				-- Zierbrett an der Oberkante (zwischen den Stockwerken und oben)
				if yb >= y1 - 0.01 then
					local tc = A + dir * ((s0 + s1) / 2) + normal * (offset + side * 0.15) + Vector3.new(0, y1 - 0.3, 0)
					box("Trim", Vector3.new(len, 0.6, 0.3), CFrame.lookAt(tc, tc + normal), COLORS.trim, M.Wood)
				end
			end
		end
	end

	-- Öffnungen entlang der Wand sortieren
	local list = {}
	for _, o in openings or {} do
		local s = (L(o[1], o[2]) - A):Dot(dir)
		local w = o.w or (o.kind == "window" and WINDOW_W or o.kind == "frontdoor" and 4 or DOOR_W)
		table.insert(list, { s = s, w = w, o = o })
	end
	table.sort(list, function(p, q)
		return p.s < q.s
	end)

	local cursor = -extend
	for _, item in list do
		local o = item.o
		local s0, s1 = item.s - item.w / 2, item.s + item.w / 2
		piece(cursor, s0, y0, y1)
		local bottom, top
		if o.kind == "window" then
			bottom = floorTop + (o.sill or SILL)
			top = bottom + (o.h or WINDOW_H)
		elseif o.kind == "frontdoor" then
			bottom, top = BASE, BASE + 7.8
		else
			bottom = floorTop
			top = floorTop + (o.h or DOOR_H)
		end
		if o.kind ~= "window" then
			-- für Tests: alle Türen und Durchgänge (offen = man kann durchgehen)
			table.insert(Mansion.doors, {
				floor = floorKey,
				x = o[1],
				y = o[2],
				middle = A + dir * item.s,
				normal = normal,
				width = item.w,
				kind = o.kind,
				open = o.kind == "opening" or o.kind == "frontdoor" or (o.angle or 0) > 0,
			})
		end
		piece(s0, s1, y0, bottom - (o.kind == "window" and 0 or 0.05))
		piece(s0, s1, top, y1)
		cursor = s1

		local middle = A + dir * item.s
		local function onSide(side, dy, size, name, color, material, depth, extra)
			local c = middle + normal * side * (t / 2 + depth) + Vector3.new(0, dy, 0)
			return box(name, size, CFrame.lookAt(c, c + normal * side), color, material, extra)
		end
		if o.kind == "window" then
			local h = top - bottom
			local mid = (bottom + top) / 2
			local wcf = CFrame.lookAt(middle + Vector3.new(0, mid, 0), middle + Vector3.new(0, mid, 0) + normal)
			box("WindowGlass", Vector3.new(item.w, h, 0.12), wcf, COLORS.glass, M.Glass, { Reflectance = 0.12 })
			box("WindowBar", Vector3.new(0.14, h, 0.2), wcf, COLORS.trim, M.Wood)
			box("WindowBar", Vector3.new(item.w, 0.14, 0.18), wcf * CFrame.new(0, h * 0.12, 0), COLORS.trim, M.Wood)
			for _, side in { 1, -1 } do
				if rooms[side] == nil then
					-- außen: Rahmen, Fensterbank, Läden
					onSide(side, top + 0.2, Vector3.new(item.w + 0.8, 0.4, 0.3), "WindowFrame", COLORS.trim, M.Wood, 0.15)
					onSide(side, bottom - 0.15, Vector3.new(item.w + 1.1, 0.3, 0.6), "WindowSill", COLORS.trim, M.Wood, 0.3)
					for _, e in { -1, 1 } do
						local c = middle + dir * e * (item.w / 2 + 0.2) + normal * side * (t / 2 + 0.15) + Vector3.new(0, mid, 0)
						box("WindowFrame", Vector3.new(0.4, h, 0.3), CFrame.lookAt(c, c + normal * side), COLORS.trim, M.Wood)
						if not o.noShutters and rng:NextNumber() < 0.8 then
							local tilt = rng:NextNumber() < 0.15 and math.rad(rng:NextNumber(8, 14)) * e or 0
							local sc = middle + dir * e * (item.w / 2 + 1.1) + normal * side * (t / 2 + 0.25 + (e > 0 and 0.05 or 0)) + Vector3.new(0, mid, 0)
							box("Shutter", Vector3.new(1.3, h + 0.4, 0.2), CFrame.lookAt(sc, sc + normal * side) * CFrame.Angles(0, 0, tilt), COLORS.shutter, M.WoodPlanks)
						end
					end
					if o.boarded then
						for i, angle in { 12, -9, 4 } do
							local c = middle + normal * side * (t / 2 + 0.45) + Vector3.new(0, mid + (i - 2) * 1.4, 0)
							box("Board", Vector3.new(item.w + 1, 0.6, 0.15), CFrame.lookAt(c, c + normal * side) * CFrame.Angles(0, 0, math.rad(angle)), COLORS.board, M.WoodPlanks)
						end
					end
				else
					onSide(side, bottom - 0.05, Vector3.new(item.w + 0.43, 0.16, 0.5), "InnerSill", Color3.fromRGB(70, 56, 42), M.Wood, 0.26)
					if rng:NextNumber() < 0.6 then
						onSide(side, mid, Vector3.new(item.w * 0.45, h, 0.04), "Curtain", COLORS.curtain, M.Fabric, 0.12)
					end
				end
			end
		elseif o.kind == "door" or o.kind == "opening" then
			-- Türrahmen auf beiden Seiten
			for _, side in { 1, -1 } do
				if rooms[side] then
					for _, e in { -1, 1 } do
						local c = middle + dir * e * (item.w / 2 + 0.1) + normal * side * (t / 2 + 0.09) + Vector3.new(0, bottom + (top - bottom) / 2, 0)
						box("DoorCasing", Vector3.new(0.3, top - bottom + 0.1, 0.18), CFrame.lookAt(c, c + normal * side), Color3.fromRGB(70, 56, 42), M.Wood)
					end
					onSide(side, top + 0.2, Vector3.new(item.w + 0.6, 0.3, 0.18), "DoorCasing", Color3.fromRGB(70, 56, 42), M.Wood, 0.09)
				end
			end
			if o.kind == "door" then
				local swingSide = 1
				if o.swing then
					swingSide = (rooms[-1] and rooms[-1].id == o.swing) and -1 or 1
				end
				-- Das Türblatt wird geschlossen gebaut und dann um die Angel gedreht.
				-- Offene Türen stehen ganz offen (sonst versperrt das Türblatt den Weg).
				local hinge = A + dir * s0
				local function leafFrame(angle)
					local leafDir = dir * math.cos(angle) + normal * swingSide * math.sin(angle)
					local leafNormal = Vector3.new(-leafDir.Z, 0, leafDir.X)
					local leafCenter = hinge + leafDir * (item.w / 2) + Vector3.new(0, bottom + (top - bottom) / 2, 0)
					return CFrame.lookAt(leafCenter, leafCenter + leafNormal)
				end
				local lcf = leafFrame(0)
				local wallFolder = current
				local doorModel = Instance.new("Model")
				doorModel.Name = "InnerDoor"
				doorModel.Parent = wallFolder
				current = doorModel
				local leaf = box("DoorLeaf", Vector3.new(item.w - 0.15, top - bottom - 0.08, 0.16), lcf, o.glassDoor and COLORS.trim or COLORS.door, M.WoodPlanks)
				if o.glassDoor then
					box("DoorGlass", Vector3.new(item.w - 1, top - bottom - 2, 0.2), lcf * CFrame.new(0, 0.4, 0), COLORS.glassHouse, M.Glass, { Transparency = 0.5 })
				else
					for _, y in { -1.6, 1.6 } do
						box("DoorPanel", Vector3.new(item.w - 1.1, 2.6, 0.22), lcf * CFrame.new(0, y, 0), Color3.fromRGB(44, 34, 26), M.Wood)
					end
				end
				for _, f in { 1, -1 } do
					box("DoorKnob", Vector3.new(0.25, 0.25, 0.25), lcf * CFrame.new((item.w / 2 - 0.45) * -1, -0.2, f * 0.16), Color3.fromRGB(120, 96, 52), M.Metal, { Shape = Enum.PartType.Ball })
				end
				current = wallFolder
				doorModel.PrimaryPart = leaf
				local entry = Mansion.doors[#Mansion.doors]
				entry.model = doorModel
				entry.locked = o.locked == true
				entry.frame = function(angle)
					return origin * leafFrame(angle)
				end
				entry.openAngle = math.rad(95)
				entry.angle = (o.angle or 0) > 0 and entry.openAngle or 0
				if entry.angle > 0 then
					doorModel:PivotTo(entry.frame(entry.angle))
				end
				if o.boards then
					local side = (rooms[-1] and rooms[-1].id == o.boards) and -1 or 1
					for i, angle in { 14, -10, 6 } do
						-- liegen auf dem Türrahmen auf
						local c = middle + normal * side * (t / 2 + 0.25) + Vector3.new(0, bottom + 1.6 + i * 1.5, 0)
						box("Board", Vector3.new(item.w + 0.6, 0.55, 0.14), CFrame.lookAt(c, c + normal * side) * CFrame.Angles(0, 0, math.rad(angle)), COLORS.board, M.WoodPlanks)
					end
					for i = 1, 5 do
						-- direkt auf dem Türblatt
						local c = middle + dir * (-0.9 + i * 0.32) + normal * side * 0.12 + Vector3.new(0, bottom + 1.5, 0)
						box("Scratch", Vector3.new(0.05, 1.4, 0.02), CFrame.lookAt(c, c + normal * side) * CFrame.Angles(0, 0, math.rad(8 - i * 3)), Color3.fromRGB(30, 22, 18))
					end
				end
			end
		end
	end
	piece(cursor, length + extend, y0, y1)
end

-- Wandzug durch mehrere Punkte; `openings` wird dem passenden Abschnitt zugeordnet
local function wallChain(floorKey, kind, points, openings, closed)
	local count = closed and #points or #points - 1
	for i = 1, count do
		local a, b = points[i], points[i % #points + 1]
		local mine = {}
		for _, o in openings or {} do
			-- liegt die Öffnung auf diesem Abschnitt?
			local ax, ay, bx, by = a[1], a[2], b[1], b[2]
			local dx, dy = bx - ax, by - ay
			local len2 = dx * dx + dy * dy
			local u = ((o[1] - ax) * dx + (o[2] - ay) * dy) / len2
			local px, py = ax + u * dx, ay + u * dy
			if u > 0 and u < 1 and (px - o[1]) ^ 2 + (py - o[2]) ^ 2 < 0.36 then
				table.insert(mine, o)
			end
		end
		buildWall(floorKey, a, b, kind, mine)
	end
	-- Ecksäulen an den Knicken (außen)
	if kind == "ext" or kind == "stone" or kind == "glass" then
		local y0, y1 = WALL_Y[floorKey][1], WALL_Y[floorKey][2]
		if floorKey == "E" and kind ~= "stone" then
			y0 = -1.2
		end
		for i = 1, #points do
			if closed or (i > 1 and i < #points) then
				local p, prev, nxt = points[i], points[(i - 2) % #points + 1], points[i % #points + 1]
				local d1 = Vector3.new(p[1] - prev[1], 0, p[2] - prev[2])
				local d2 = Vector3.new(nxt[1] - p[1], 0, nxt[2] - p[2])
				local turn = math.abs(d1.Unit:Dot(d2.Unit))
				-- nur an Außenecken (sonst steht die Säule innen als Pfosten im Raum)
				local inside = 0
				for _, dx in { -1, 1 } do
					for _, dy in { -1, 1 } do
						if roomAt(floorKey, p[1] + dx, p[2] + dy) then
							inside += 1
						end
					end
				end
				if turn < 0.995 and inside <= 2 then
					local diameter = THICK[kind] + 0.35
					local color = kind == "stone" and COLORS.stone or COLORS.trim
					local material = kind == "stone" and M.Cobblestone or M.Wood
					cyl("CornerPost", y1 - y0, diameter, CFrame.new(L(p[1], p[2], y0)), color, material)
				end
			end
		end
	end
end

------------------------------------------------------------------ Böden und Decken
local function slab(name, poly, top, thickness, color, material)
	if #poly == 4 and poly[1][2] == poly[2][2] and poly[2][1] == poly[3][1] and poly[3][2] == poly[4][2] and poly[4][1] == poly[1][1] then
		local x0, x1 = math.min(poly[1][1], poly[3][1]), math.max(poly[1][1], poly[3][1])
		local y0, y1 = math.min(poly[1][2], poly[3][2]), math.max(poly[1][2], poly[3][2])
		local c = L((x0 + x1) / 2, (y0 + y1) / 2, top - thickness / 2)
		box(name, Vector3.new(x1 - x0, thickness, y1 - y0), CFrame.new(c), color, material)
		return
	end
	for _, tri in triangulate(poly) do
		local y = top - thickness / 2
		triangle(name, L(tri[1][1], tri[1][2], y), L(tri[2][1], tri[2][2], y), L(tri[3][1], tri[3][2], y), thickness, color, material)
	end
end

------------------------------------------------------------------ Dächer
-- Walmdach über einem Rechteck (Plan-Koordinaten), Traufe bei `base`
-- `overhang` = Dachüberstand; eine Zahl für alle Seiten oder eine Tabelle pro Seite
-- ({ x0 =, x1 =, y0 =, y1 = }). Negativ = das Dach endet vor der Wand (an einer
-- höheren Hauswand, damit es nicht in den Raum dahinter ragt). Dort gibt es keine Rinne.
local function hipRoof(x0, y0, x1, y1, base, rise, overhang)
	overhang = overhang or 1.2
	local over = type(overhang) == "table" and overhang or {}
	local default = type(overhang) == "number" and overhang or 1.2
	local ox0, ox1 = over.x0 or default, over.x1 or default
	local oy0, oy1 = over.y0 or default, over.y1 or default
	local a = L(x0 - ox0, y0 - oy0, base)
	local c = L(x1 + ox1, y1 + oy1, base)
	local minX, maxX = math.min(a.X, c.X), math.max(a.X, c.X)
	local minZ, maxZ = math.min(a.Z, c.Z), math.max(a.Z, c.Z)
	local w, d = maxX - minX, maxZ - minZ
	local top = base + rise
	local p1, p2, p3, p4 = Vector3.new(minX, base, minZ), Vector3.new(maxX, base, minZ), Vector3.new(maxX, base, maxZ), Vector3.new(minX, base, maxZ)
	local r1, r2
	if w >= d then
		local inset = d / 2
		r1, r2 = Vector3.new(minX + inset, top, (minZ + maxZ) / 2), Vector3.new(maxX - inset, top, (minZ + maxZ) / 2)
		triangle("Roof", p1, p2, r2, 0.5, COLORS.roof, M.Slate)
		triangle("Roof", p1, r2, r1, 0.5, COLORS.roof, M.Slate)
		triangle("Roof", p4, p3, r2, 0.5, COLORS.roof, M.Slate)
		triangle("Roof", p4, r2, r1, 0.5, COLORS.roof, M.Slate)
		triangle("Roof", p1, p4, r1, 0.5, COLORS.roof, M.Slate)
		triangle("Roof", p2, p3, r2, 0.5, COLORS.roof, M.Slate)
		beam("RoofHip", p1, r1, 0.5, COLORS.ridge, M.Slate)
		beam("RoofHip", p4, r1, 0.5, COLORS.ridge, M.Slate)
		beam("RoofHip", p2, r2, 0.5, COLORS.ridge, M.Slate)
		beam("RoofHip", p3, r2, 0.5, COLORS.ridge, M.Slate)
	else
		local inset = w / 2
		r1, r2 = Vector3.new((minX + maxX) / 2, top, minZ + inset), Vector3.new((minX + maxX) / 2, top, maxZ - inset)
		triangle("Roof", p1, p4, r2, 0.5, COLORS.roof, M.Slate)
		triangle("Roof", p1, r2, r1, 0.5, COLORS.roof, M.Slate)
		triangle("Roof", p2, p3, r2, 0.5, COLORS.roof, M.Slate)
		triangle("Roof", p2, r2, r1, 0.5, COLORS.roof, M.Slate)
		triangle("Roof", p1, p2, r1, 0.5, COLORS.roof, M.Slate)
		triangle("Roof", p4, p3, r2, 0.5, COLORS.roof, M.Slate)
		beam("RoofHip", p1, r1, 0.5, COLORS.ridge, M.Slate)
		beam("RoofHip", p2, r1, 0.5, COLORS.ridge, M.Slate)
		beam("RoofHip", p3, r2, 0.5, COLORS.ridge, M.Slate)
		beam("RoofHip", p4, r2, 0.5, COLORS.ridge, M.Slate)
	end
	if (r2 - r1).Magnitude > 0.1 then
		beam("RoofRidge", r1, r2, 0.6, COLORS.ridge, M.Slate)
	end
	-- Regenrinnen an der Traufe
	-- (p1..p4 liegen bei Haus-x = min/max und Haus-z = min/max; Plan-x wächst mit
	-- Haus-x, Plan-y wächst gegen Haus-z)
	local sideOver = { oy1, ox1, oy0, ox0 }
	for index, edge in { { p1, p2 }, { p2, p3 }, { p3, p4 }, { p4, p1 } } do
		if sideOver[index] > 0 then
			beam("Gutter", edge[1] - Vector3.new(0, 0.3, 0), edge[2] - Vector3.new(0, 0.3, 0), 0.35, COLORS.metal, M.Metal)
		end
	end
end

-- Zeltdach über einem konvexen Vieleck (Spitze über der Mitte)
local function pyramidRoof(poly, base, rise, overhang, color, material, extra, name)
	local cx, cy = 0, 0
	for _, p in poly do
		cx += p[1] / #poly
		cy += p[2] / #poly
	end
	local apex = L(cx, cy, base + rise)
	local ring = {}
	for _, p in poly do
		local dx, dy = p[1] - cx, p[2] - cy
		local len = math.sqrt(dx * dx + dy * dy)
		local scale = (len + overhang) / len
		table.insert(ring, L(cx + dx * scale, cy + dy * scale, base))
	end
	for i = 1, #ring do
		triangle(name or "Roof", ring[i], ring[i % #ring + 1], apex, 0.5, color or COLORS.roof, material or M.Slate, extra)
		beam("RoofHip", ring[i], apex, 0.4, extra and COLORS.trim or COLORS.ridge, extra and M.Wood or M.Slate)
	end
	return apex
end

------------------------------------------------------------------ Wände: Daten
local DOOR = "door"
local WIN = "window"

local function buildWalls()
	local tw = { w = 2.2 } -- schmale Turmfenster
	------------------------------------------------ Erdgeschoss außen
	wallChain("E", "ext", {
		{ 41.75, 72 }, { 54.25, 72 }, { 72.5, 72 }, K[3], K[2], K[1], K[0], K[7], K[6], K[5],
		{ 80.56, 42 }, { 80.56, 18 }, { 78, 18 }, { 76, 12 }, { 68, 12 }, { 66, 18 }, { 54.25, 18 }, { 54.25, 8 }, { 40, 8 }, { 40, 20 }, { 34, 20 }, { 34, 30 }, { 20, 30 },
	}, {
		{ 48, 72, kind = "frontdoor" },
		{ 58.5, 72, kind = WIN }, { 66, 72, kind = WIN },
		{ 84, 74.32, kind = WIN, w = tw.w }, { 89.88, 71.88, kind = WIN, w = tw.w }, { 92.31, 66, kind = WIN, w = tw.w }, { 89.88, 60.12, kind = WIN, w = tw.w },
		{ 80.56, 24, kind = WIN }, { 80.56, 36, kind = WIN },
		{ 77, 15, kind = WIN, w = 2 }, { 72, 12, kind = WIN }, { 67, 15, kind = WIN, w = 2 },
		{ 60, 18, kind = WIN },
		{ 47, 8, kind = WIN, w = 2, h = 2.4, sill = 5, noShutters = true },
		{ 37, 20, kind = WIN, w = 2.4 }, { 34, 25, kind = WIN },
		{ 27, 30, kind = WIN, w = 2.6 },
	}, false)
	wallChain("E", "ext", {
		{ 8, 30 }, { 8, 34 }, { 14, 38 }, { 14, 60 }, { 10, 60 }, { 10, 72 }, { 18, 80 }, { 36, 80 }, { 36, 72 }, { 41.75, 72 },
	}, {
		{ 11, 36, kind = WIN, w = 2 },
		{ 14, 44, kind = WIN }, { 14, 54, kind = WIN },
		{ 10, 66, kind = WIN }, { 14, 76, kind = WIN, w = 2.6 }, { 24, 80, kind = WIN }, { 31, 80, kind = WIN },
		{ 39, 72, kind = WIN, w = 1.6, h = 2.4, sill = 5.5, noShutters = true },
	}, false)
	-- Wintergarten: Glas
	wallChain("E", "glass", { { 20, 30 }, HEX[1], HEX[6], HEX[5], HEX[4], { 8, 30 } }, {
		{ 14, 9.2, kind = DOOR, angle = 0, glassDoor = true, locked = true },
	}, false)
	buildWall("E", { 8, 30 }, { 20, 30 }, "int", { { 14, 30, kind = DOOR, angle = 70, swing = "winter", glassDoor = true } })
	for _, p in { { 20, 30 }, { 8, 30 } } do
		cyl("CornerPost", WALL_Y.E[2] + 1.2, THICK.ext + 0.35, CFrame.new(L(p[1], p[2], -1.2)), COLORS.trim, M.Wood)
	end

	------------------------------------------------ Erdgeschoss innen
	local function int(a, b, openings)
		buildWall("E", a, b, "int", openings)
	end
	int({ 41.75, 54.15 }, { 41.75, 60 })
	int({ 41.75, 60 }, { 41.75, 72 })
	int({ 41.75, 54.15 }, { 54.25, 54.15 }, { { 51.4, 54.15, kind = DOOR, angle = 80, swing = "flur" } })
	int({ 54.25, 54.15 }, { 54.25, 72 }, { { 54.25, 63, kind = DOOR, angle = 75, swing = "wohn" } })
	int({ 54.25, 42 }, { 54.25, 54.15 }, { { 54.25, 48, kind = DOOR, angle = 0 } })
	int({ 34, 42 }, { 54.25, 42 }, { { 44, 42, kind = DOOR, angle = 85, swing = "kueche" } })
	int({ 34, 42 }, { 34, 60 }, { { 34, 50, kind = DOOR, angle = 70, swing = "salon" } })
	int({ 54.25, 20 }, { 54.25, 22 })
	int({ 54.25, 34 }, { 54.25, 42 }, { { 54.25, 38, kind = DOOR, angle = 80, swing = "ess" } })
	int({ 54.25, 22 }, { 54.25, 34 })
	int({ 54.25, 18 }, { 54.25, 20 })
	int({ 40, 20 }, { 54.25, 20 }, { { 47, 20, kind = DOOR, angle = 60, swing = "speise" } })
	int({ 34, 30 }, { 34, 38 }, { { 34, 34, kind = DOOR, angle = 70, swing = "gartenflur" } })
	int({ 14, 38 }, { 34, 38 })
	int({ 14, 60 }, { 34, 60 }, { { 24, 60, kind = DOOR, angle = 0, locked = true } }) -- Arbeitszimmer: abgeschlossen
	int({ 34, 60 }, { 41.75, 60 }, { { 39, 60, kind = DOOR, angle = 0 } })
	int({ 36, 60 }, { 36, 72 })
	int({ 54.25, 42 }, { 80.56, 42 }, { { 62, 42, kind = DOOR, angle = 0 } })
	int(K[3], K[4])
	int(K[4], K[5], { { 78.12, 60.12, kind = DOOR, angle = 70, swing = "turm" } })
	-- Kellertreppe: Wände und Kellertür
	int({ 50, 22 }, { 50, 34 })
	int({ 50, 22 }, { 54.25, 22 })
	int({ 50, 34 }, { 54.25, 34 }, { { 52.12, 34, kind = DOOR, angle = 0, w = 3.2 } })

	------------------------------------------------ Obergeschoss außen
	wallChain("O", "ext", {
		{ 41.75, 72 }, { 54.25, 72 }, { 72.5, 72 }, K[3], K[2], K[1], K[0], K[7], K[6], K[5],
		{ 80.56, 44 }, { 80.56, 34 }, { 80.56, 18 }, { 78, 18 }, { 76, 12 }, { 68, 12 }, { 66, 18 }, { 54.25, 18 }, { 54.25, 20 }, { 44, 20 }, { 34, 20 }, { 34, 34 }, { 34, 38 }, { 14, 38 }, { 14, 60 }, { 41.75, 60 }, { 41.75, 72 },
	}, {
		{ 48, 72, kind = WIN },
		{ 58.5, 72, kind = WIN }, { 66, 72, kind = WIN, boarded = true },
		{ 84, 74.32, kind = WIN, w = tw.w }, { 89.88, 71.88, kind = WIN, w = tw.w }, { 92.31, 66, kind = WIN, w = tw.w }, { 89.88, 60.12, kind = WIN, w = tw.w },
		{ 80.56, 50, kind = WIN }, { 80.56, 37, kind = WIN }, { 80.56, 26, kind = WIN },
		{ 77, 15, kind = WIN, w = 2 }, { 72, 12, kind = WIN }, { 67, 15, kind = WIN, w = 2 },
		{ 59, 18, kind = WIN }, { 49, 20, kind = WIN }, { 39, 20, kind = WIN },
		{ 34, 27, kind = WIN }, { 34, 36, kind = WIN, w = 2.4 },
		{ 24, 38, kind = WIN }, { 14, 44, kind = WIN }, { 14, 54, kind = WIN, boarded = true },
	}, true)

	------------------------------------------------ Obergeschoss innen
	local function intO(a, b, openings)
		buildWall("O", a, b, "int", openings)
	end
	intO({ 41.75, 40 }, { 41.75, 54.15 })
	intO({ 41.75, 54.15 }, { 41.75, 60 })
	intO({ 41.75, 54.15 }, { 48.6, 54.15 }, { { 46.8, 54.15, kind = DOOR, angle = 0, w = 3.2, boards = "hall", locked = true } })
	intO({ 48.6, 54.15 }, { 54.25, 54.15 }, { { 51.4, 54.15, kind = DOOR, angle = 75, w = 3.2, swing = "gaeste" } })
	-- vom Ende der Galerie ins Spielzimmer (und von dort in den langen Flur)
	intO({ 54.25, 54.15 }, { 54.25, 72 }, { { 54.25, 56.2, kind = DOOR, angle = 70, w = 3.2, swing = "spiel" } })
	intO({ 48.6, 40 }, { 48.6, 54.15 })
	intO({ 34, 40 }, { 41.75, 40 }, { { 38, 40, kind = DOOR, angle = 0, locked = true } }) -- Großmutter: abgeschlossen
	intO({ 41.75, 40 }, { 48.6, 40 })
	intO({ 48.6, 40 }, { 62, 40 })
	intO({ 62, 40 }, { 62, 52 })
	intO({ 62, 52 }, { 62, 54.15 })
	intO({ 54.25, 54.15 }, { 62, 54.15 })
	intO({ 62, 52 }, { 74.56, 52 }, { { 68, 52, kind = DOOR, angle = 80, swing = "gang" } }) -- geht zum Flur auf (sonst steht sie im Weg)
	intO({ 74.56, 52 }, { 80.56, 44 })
	local corridorDoors = {
		{ 39, 34, kind = DOOR, angle = 25, swing = "tommy" },
		{ 49, 34, kind = DOOR, angle = 15, swing = "lucy" },
		{ 59, 34, kind = DOOR, angle = 80, swing = "bad" },
		{ 72, 34, kind = DOOR, angle = 0, locked = true }, -- Eltern: abgeschlossen
	}
	for _, segment in { { 34, 44 }, { 44, 54.25 }, { 54.25, 64 }, { 64, 80.56 } } do
		local mine = {}
		for _, o in corridorDoors do
			if o[1] > segment[1] and o[1] < segment[2] then
				table.insert(mine, o)
			end
		end
		intO({ segment[1], 34 }, { segment[2], 34 }, mine)
	end
	intO({ 44, 20 }, { 44, 34 })
	intO({ 54.25, 20 }, { 54.25, 34 })
	intO({ 64, 18 }, { 64, 34 })
	intO({ 34, 38 }, { 34, 40 })
	intO(K[3], K[4])
	intO(K[4], K[5], { { 78.12, 60.12, kind = DOOR, angle = 0 } })

	------------------------------------------------ Turmspitze (über dem Dach)
	wallChain("T", "ext", { K[0], K[1], K[2], K[3], K[4], K[5], K[6], K[7] }, {
		{ 84, 74.32, kind = WIN, w = 1.6, h = 2.4, sill = 2.8, noShutters = true },
		{ 75.68, 66, kind = WIN, w = 1.6, h = 2.4, sill = 2.8, noShutters = true },
		{ 92.31, 66, kind = WIN, w = 1.6, h = 2.4, sill = 2.8, noShutters = true },
	}, true)

	------------------------------------------------ Keller (Stein)
	local function stone(a, b, openings)
		buildWall("K", a, b, "stone", openings)
	end
	stone({ 34, 20 }, { 34, 42 }, { { 34, 40, kind = "opening", w = 3.2 } })
	stone({ 34, 20 }, { 54.25, 20 }, { { 47, 20, kind = "opening", w = 3.4, h = 6.6 } })
	stone({ 34, 34 }, { 54.25, 34 }, { { 42, 34, kind = "opening", w = 3.4 } })
	stone({ 34, 42 }, { 70, 42 })
	stone({ 14, 38 }, { 34, 38 })
	stone({ 14, 38 }, { 14, 60 })
	stone({ 14, 60 }, { 34, 60 })
	stone({ 34, 42 }, { 34, 60 })
	stone({ 54.25, 18 }, { 54.25, 42 }, { { 54.25, 38, kind = "opening", w = 3.4 } })
	stone({ 54.25, 18 }, { 80.56, 18 })
	stone({ 70, 18 }, { 70, 42 }, { { 70, 30, kind = "opening", w = 3.4, h = 5.6 } })
	stone({ 70, 42 }, { 80.56, 42 })
	stone({ 80.56, 18 }, { 80.56, 42 })
	stone({ 45, 12 }, { 45, 20 })
	stone({ 49, 12 }, { 49, 20 })
	-- Ritualraum: rund, Öffnung zum Geheimgang (unten) und zum Tunnel (links)
	for i = 1, #RITUAL do
		local a, b = RITUAL[i], RITUAL[i % #RITUAL + 1]
		local mx, my = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
		local toPassage = my > 10.5 and math.abs(mx - 47) < 3
		local toTunnel = mx < 39.5 and math.abs(my - 3) < 3
		if not toPassage and not toTunnel then
			buildWall("K", a, b, "stone", nil, -2.3)
		end
	end
end

------------------------------------------------------------------ Böden, Decken, Dächer
local function buildFloorsAndRoofs()
	for floorKey, list in ROOMS do
		for _, room in list do
			if room.floor and not room.noFloor and not (room.void and floorKey == "O") then
				local top = FLOOR[floorKey]
				local thickness = floorKey == "E" and top + 0.5 or floorKey == "K" and 0.3 or 0.5
				-- 0.012 höher als die Wände darunter, sonst flackern deren Oberkanten im Boden
				slab("Floor", room.poly, top + 0.012, thickness + 0.012, room.floor[1], room.floor[2])
			end
			-- Decken
			if floorKey == "E" and not room.void and not room.glass then
				slab("Ceiling", room.poly, CEIL.E + 0.1, 0.1, COLORS.ceiling, M.SmoothPlastic)
			elseif floorKey == "O" or floorKey == "T" then
				slab("Ceiling", room.poly, CEIL[floorKey] + 0.4, 0.4, COLORS.ceiling, M.SmoothPlastic)
			elseif floorKey == "K" and room.ceiling then
				slab("Ceiling", room.poly, room.ceiling + 0.3, 0.3, COLORS.stone, M.Slate)
			end
		end
	end
	-- Hauptdach: drei Walmdächer, die sich überschneiden
	hipRoof(14, 38, 41.75, 60, TOP, 7)
	hipRoof(34, 18, 80.56, 40, TOP, 7)
	hipRoof(41.75, 40, 80.56, 72, TOP, 9)
	pyramidRoof({ { 66, 18 }, { 68, 12 }, { 76, 12 }, { 78, 18 } }, TOP, 4, 1)
	-- niedrige Anbauten
	pyramidRoof({ { 10, 60 }, { 36, 60 }, { 36, 80 }, { 18, 80 }, { 10, 72 } }, BASE + STORY, 5, 1.2)
	-- WC und Speisekammer stoßen an höhere Wände: dort kein Überstand (sonst ragt das
	-- Dach in die Eingangshalle über der Treppe bzw. in die Kinderzimmer)
	hipRoof(36, 60, 41.75, 72, BASE + STORY, 2.5, { x0 = 0.8, x1 = -0.45, y0 = 0.8, y1 = 0.8 })
	hipRoof(40, 8, 54.25, 20, BASE + STORY, 3.5, { x0 = 1, x1 = 1, y0 = 1, y1 = -0.45 })
	pyramidRoof({ { 8, 30 }, { 34, 30 }, { 34, 38 }, { 14, 38 }, { 8, 34 } }, BASE + STORY, 3, 1)
	-- Wintergarten: Glasdach mit weißen Sprossen
	pyramidRoof(HEX, FLOOR.E + 8, 6, 0.6, COLORS.glassHouse, M.Glass, { Transparency = 0.55 }, "GlassRoof")
	-- Turm: spitzes Achteckdach mit Wetterfahne
	local apex = pyramidRoof(TOWER, TOWER_TOP, 15, 1.2)
	cyl("Finial", 3, 0.3, CFrame.new(apex), COLORS.metal, M.Metal)
	ball("FinialBall", 0.7, CFrame.new(apex + Vector3.new(0, 3.2, 0)), COLORS.metal, M.Metal)
	box("WeatherVane", Vector3.new(0.08, 0.6, 1.8), CFrame.new(apex + Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, math.rad(35), 0), COLORS.metal, M.Metal)
	-- Schornsteine (Kamin im Wohnzimmer, Küchenherd)
	box("Chimney", Vector3.new(3, TOP + 12, 3.4), CFrame.new(L(82.36, 50, (TOP + 12) / 2 - 0.6)), COLORS.brick, M.Brick)
	box("ChimneyCap", Vector3.new(3.6, 0.5, 4), CFrame.new(L(82.36, 50, TOP + 11.6)), COLORS.stone, M.Concrete)
	box("Chimney", Vector3.new(2.6, 12, 2.6), CFrame.new(L(37, 31, TOP + 4)), COLORS.brick, M.Brick)
	box("ChimneyCap", Vector3.new(3.2, 0.5, 3.2), CFrame.new(L(37, 31, TOP + 10.2)), COLORS.stone, M.Concrete)
	-- Steinsockel unter dem Glashaus
	for i = 1, 6 do
		local a, b = HEX[i], HEX[i % 6 + 1]
		local A, B = L(a[1], a[2], -0.6), L(b[1], b[2], -0.6)
		local mid = (A + B) / 2
		box("Plinth", Vector3.new((B - A).Magnitude, 1.2, 0.8), CFrame.lookAt(mid, mid + (B - A):Cross(Vector3.yAxis)), COLORS.stone, M.Cobblestone)
	end
end

------------------------------------------------------------------ Treppen
local function buildStairs()
	-- Kellertreppe: von der Küche (oben bei y = 34) steil hinunter nach hinten (y = 22)
	local steps = 13
	local run = 12 / steps
	local rise = (FLOOR.E - FLOOR.K) / steps
	for i = 1, steps - 1 do
		local top = FLOOR.E - i * rise
		local y = 34 - (i - 0.5) * run
		local height = top - (FLOOR.K - 0.3)
		box("CellarStair", Vector3.new(4.2, height, run), CFrame.new(L(52.12, y, (FLOOR.K - 0.3) + height / 2)), Color3.fromRGB(70, 56, 42), M.WoodPlanks)
	end
	box("CellarHandrail", Vector3.new(0.2, 0.2, 15.6), CFrame.lookAt(L(50.4, 34, FLOOR.E + 3), L(50.4, 22, FLOOR.K + 3)), Color3.fromRGB(46, 36, 28), M.Wood)
end

------------------------------------------------------------------ Möbel
local function buildFurniture()
	local b = builder
	local E, O, Kf = FLOOR.E, FLOOR.O, FLOOR.K
	local function lit(cf, h)
		candle(cf, h or 0.8, 9, 0.9)
	end

	-- Flur
	Furniture.rug(b, at(44, 48, E), 6, 9, Color3.fromRGB(70, 30, 28))
	Furniture.picture(b, at(34.4, 46, E + 6, "E"), 2.4, 3, Color3.fromRGB(60, 54, 44), true)
	local console = Furniture.table(b, at(40, 42.8, E, "S"), 4, 1.2, 2.8)
	lit(console * CFrame.new(1.2, 0, 0))

	-- Wohnzimmer: Kamin, Möbel unter Tüchern
	Furniture.fireplace(b, at(79.5, 50, E, "W"))
	Furniture.picture(b, at(80.02, 50, E + 8.2, "W"), 3.2, 4, Color3.fromRGB(50, 40, 34), true)
	Furniture.rug(b, at(68, 52, E), 10, 8, Color3.fromRGB(80, 34, 30))
	Furniture.sofa(b, at(67, 50, E, "E"), 6, Color3.fromRGB(96, 36, 34), true)
	Furniture.sofa(b, at(72, 45, E, "S"), 2.6, Color3.fromRGB(96, 36, 34), true)
	Furniture.sofa(b, at(72, 56, E, "N"), 2.6, Color3.fromRGB(96, 36, 34), true)
	Furniture.table(b, at(72, 50.5, E), 3, 2, 1.6)
	Furniture.shelf(b, at(57.2, 42.9, E, "S"), 5, 7.5, "books", rng) -- links und rechts der Tür zum Esszimmer
	Furniture.shelf(b, at(66.6, 42.9, E, "S"), 4, 7.5, "books", rng)
	Furniture.picture(b, at(54.64, 66, E + 5.5, "E"), 2, 2.6, Color3.fromRGB(70, 60, 50), true)

	-- Turmzimmer
	Furniture.rug(b, at(84, 66, E), 9, 9, Color3.fromRGB(40, 50, 60))
	Furniture.sofa(b, at(85, 64, E, "S"), 2.6, Color3.fromRGB(60, 40, 30), false)
	local side = Furniture.table(b, at(88, 67, E), 1.6, 1.6, 2.2)
	box("Book", Vector3.new(1, 0.25, 1.3), side * CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(80, 30, 26), M.Fabric)

	-- Esszimmer: Tisch für sieben, gedeckt
	local tableTop = Furniture.table(b, at(67, 30, E, "N"), 4, 15, 2.9, Color3.fromRGB(56, 40, 28))
	box("TableRunner", Vector3.new(1.4, 0.03, 14), tableTop * CFrame.new(0, 0.02, 0), Color3.fromRGB(110, 30, 28), M.Fabric)
	for i = -1, 1 do
		Furniture.chair(b, at(64.5, 30 + i * 4.5, E, "E"))
		Furniture.chair(b, at(69.5, 30 + i * 4.5, E, "W"))
		for _, x in { 65.4, 68.6 } do
			box("Plate", Vector3.new(1.1, 0.06, 1.1), CFrame.new(L(x, 30 + i * 4.5, E + 2.93)), Color3.fromRGB(210, 204, 190), M.SmoothPlastic)
		end
	end
	Furniture.chair(b, at(67, 39.5, E, "N"))
	box("Plate", Vector3.new(1.1, 0.06, 1.1), CFrame.new(L(67, 36.4, E + 2.93)), Color3.fromRGB(210, 204, 190), M.SmoothPlastic)
	for _, y in { 24, 30, 36 } do
		lit(at(67, y, E + 2.9), 1)
	end
	Furniture.shelf(b, at(72, 13, E, "N"), 6, 3.2, "books", rng)
	Furniture.picture(b, at(80.02, 30, E + 6, "W"), 3, 4, Color3.fromRGB(40, 50, 40), true)
	Furniture.picture(b, at(58, 18.54, E + 6, "S"), 2.4, 3, Color3.fromRGB(56, 46, 40), true)

	-- Küche
	Furniture.counter(b, at(40.5, 21.3, E, "S"), 9)
	Furniture.sink(b, at(39, 21.3, E, "S"))
	Furniture.stove(b, at(35.4, 39.5, E, "E"))
	Furniture.fridge(b, at(47.6, 40.6, E, "N"))
	local kitchenTable = Furniture.table(b, at(42, 31, E), 5, 3.4, 2.9)
	lit(kitchenTable * CFrame.new(0.8, 0, 0.4), 0.7)
	for _, c in { { 39, 31, "E" }, { 45, 31, "W" }, { 42, 28.6, "S" }, { 42, 33.6, "N" } } do
		Furniture.chair(b, at(c[1], c[2], E, c[3]))
	end
	-- Töpfe hängen an einer Stange, die mit Ketten an der Decke hängt
	box("PotRack", Vector3.new(6.8, 0.12, 0.12), CFrame.new(L(38.4, 20.9, E + 7.3)), COLORS.metal, M.Metal)
	for _, x in { 35.4, 41.4 } do
		box("PotRackChain", Vector3.new(0.06, CEIL.E - (E + 7.3) + 0.2, 0.06), CFrame.new(L(x, 20.9, (CEIL.E + E + 7.3) / 2 + 0.1)), COLORS.metal, M.Metal)
	end
	for i = 0, 3 do
		cyl("HangingPot", 0.8, 0.9, at(36 + i * 1.6, 20.9, E + 6.4), Color3.fromRGB(60, 58, 56), M.Metal)
		box("PotHook", Vector3.new(0.05, 0.16, 0.05), CFrame.new(L(36 + i * 1.6, 20.9, E + 7.2 + 0.0)), COLORS.metal, M.Metal)
	end
	box("KnifeBlock", Vector3.new(0.6, 0.9, 0.5), CFrame.new(L(43.5, 21.2, E + 3.65)), Color3.fromRGB(40, 30, 22), M.Wood)

	-- Speisekammer
	Furniture.shelf(b, at(44, 8.9, E, "N"), 7, 7.5, "jars", rng)
	Furniture.shelf(b, at(51, 8.9, E, "N"), 5, 7.5, "jars", rng)
	for i = 0, 2 do
		box("Sack", Vector3.new(1.6, 2, 1.2), CFrame.new(L(41.5 + i * 1.8, 17, E + 1)) * CFrame.Angles(0, i * 0.4, 0), Color3.fromRGB(150, 130, 96), M.Fabric)
	end

	-- Salon: Klavier (hier steht Tommy)
	Furniture.piano(b, at(15.4, 47, E, "E"))
	Furniture.sofa(b, at(26, 55, E, "N"), 6, Color3.fromRGB(70, 50, 80), true)
	Furniture.rug(b, at(25, 48, E), 10, 10, Color3.fromRGB(60, 40, 70))
	local gramo = Furniture.table(b, at(31, 41, E), 2, 2, 2.6)
	box("Gramophone", Vector3.new(1.2, 0.5, 1.2), gramo * CFrame.new(0, 0.25, 0), Color3.fromRGB(50, 34, 24), M.Wood)
	box("GramophoneHorn", Vector3.new(1.2, 1.2, 0.2), gramo * CFrame.new(0, 1.0, 0.3) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(140, 110, 50), M.Metal)
	Furniture.picture(b, at(24, 38.39, E + 6, "S"), 3, 2.2, Color3.fromRGB(80, 70, 60), true)

	-- Arbeitszimmer (abgeschlossen)
	Furniture.desk(b, at(22, 68, E, "S"), rng)
	Furniture.shelf(b, at(10.9, 66, E, "E"), 5, 8, "books", rng)
	Furniture.shelf(b, at(30, 60.9, E, "S"), 5, 8, "books", rng)
	Furniture.rug(b, at(22, 70, E), 8, 7, Color3.fromRGB(50, 40, 30))
	box("Map", Vector3.new(4, 2.6, 0.04), CFrame.new(L(35.8, 68, E + 5.5)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(180, 160, 120), M.SmoothPlastic)
	ball("Globe", 1.4, CFrame.new(L(32, 76, E + 3.4)), Color3.fromRGB(70, 90, 110), M.SmoothPlastic)
	cyl("GlobeStand", 2.7, 0.5, at(32, 76, E), Color3.fromRGB(46, 36, 28), M.Wood)

	-- WC
	Furniture.toilet(b, at(39, 70.8, E, "N"))
	Furniture.sink(b, at(37, 64, E, "E"))
	Furniture.mirror(b, at(36.4, 64, E + 5.6, "E"), true)

	-- Flur zum Garten
	box("Bench", Vector3.new(5, 0.3, 1.4), CFrame.new(L(24, 37, E + 1.7)), Color3.fromRGB(70, 56, 42), M.Wood)
	for i = 0, 2 do
		box("RainCoat", Vector3.new(1.2, 3.2, 0.5), CFrame.new(L(19 + i * 3, 37.4, E + 5.5)), Color3.fromRGB(60 + i * 20, 70, 50), M.Fabric)
	end

	-- Wintergarten: tote Pflanzen, Korbstühle
	for i, p in { { 9, 20 }, { 20, 14 }, { 20, 24 }, { 7, 13 }, { 8, 25 } } do
		cyl("PlantPot", 1.6, 1.8, at(p[1], p[2], E), Color3.fromRGB(110, 62, 44), M.Concrete)
		box("DeadPlant", Vector3.new(1.2, 2.4, 1.2), CFrame.new(L(p[1], p[2], E + 2.8)) * CFrame.Angles(0, i, math.rad(15)), Color3.fromRGB(70, 58, 40), M.Grass)
	end
	Furniture.chair(b, at(19, 19, E, "W"), Color3.fromRGB(120, 100, 70))
	Furniture.chair(b, at(9, 16, E, "E"), Color3.fromRGB(120, 100, 70))

	------------------------------------------------ Obergeschoss
	-- langer Flur: Läufer, Bilder, Kerze
	Furniture.rug(b, at(56, 37, O), 40, 3.6, Color3.fromRGB(70, 30, 28))
	-- Bilder an den Flurwänden (Bildseite zum Flur)
	for _, x in { 46, 54 } do
		Furniture.picture(b, at(x, 39.61, O + 5.5, "N"), 2, 2.6, Color3.fromRGB(60, 54, 44), x == 46)
	end
	for _, x in { 66, 76 } do
		Furniture.picture(b, at(x, 34.39, O + 5.5, "S"), 2, 2.6, Color3.fromRGB(60, 54, 44), x == 66)
	end
	local hallTable = Furniture.table(b, at(64.5, 41.5, O), 2.4, 1.4, 2.8)
	lit(hallTable)

	-- Gästezimmer (euer Zimmer): zwei Betten
	-- (Mansion.beds: hier kann man sich zum Schlafen hinlegen, siehe Kapitel2.lua)
	for _, x in { 52, 58.5 } do
		local bedFrame = at(x, 42.8, O, "S")
		Furniture.bed(b, bedFrame, 4, 7, x < 55 and Color3.fromRGB(110, 90, 70) or Color3.fromRGB(90, 96, 80))
		table.insert(Mansion.beds, { cframe = origin * bedFrame, length = 7, width = 4 })
	end
	Furniture.nightstand(b, at(55.2, 41, O, "S"))
	Furniture.wardrobe(b, at(61.3, 50, O, "W"), 4)
	Furniture.rug(b, at(55, 49, O), 6, 4, Color3.fromRGB(80, 60, 50))

	-- hinter Tür 1: leer, nur ein Stuhl, der zur Wand schaut, und Kratzer
	Furniture.chair(b, at(45, 42, O, "N"))
	for i = 1, 12 do
		local x = 42.09 -- direkt auf der Tapete
		box("Scratch", Vector3.new(0.05, rng:NextNumber(1, 3), 0.02), CFrame.new(L(x, 44 + i * 0.7, O + 2 + rng:NextNumber(0, 3))) * CFrame.Angles(0, math.rad(90), math.rad(rng:NextNumber(-20, 20))), Color3.fromRGB(20, 16, 14))
	end

	-- Tommys Zimmer: Bett, Spielkiste, Zeichnungen
	Furniture.bed(b, at(36.6, 23.5, O, "S"), 3.2, 5.6, Color3.fromRGB(60, 80, 120))
	Furniture.toyBox(b, at(41.5, 23, O, "S"))
	Furniture.rug(b, at(39, 29, O), 6, 5, Color3.fromRGB(50, 70, 100))
	for i, p in { { 43.66, 24, "W" }, { 43.66, 28, "W" }, { 38, 20.49, "S" }, { 41, 20.49, "S" }, { 34.49, 30, "E" } } do
		Furniture.drawing(b, at(p[1], p[2], O + 4.5 + (i % 2) * 0.6, p[3]))
	end
	for i = 0, 4 do
		box("Crayon", Vector3.new(0.12, 0.12, 0.6), CFrame.new(L(38 + i * 0.4, 30, O + 0.1)) * CFrame.Angles(0, i, 0), Color3.fromRGB(40 + i * 40, 30, 30 + i * 20))
	end

	-- Lucys Zimmer: Bett, Puppen, Spieluhr, Puppenhaus
	Furniture.bed(b, at(51.4, 23.5, O, "S"), 3.4, 5.8, Color3.fromRGB(150, 110, 120))
	local stand = Furniture.nightstand(b, at(48.6, 21.2, O, "S"))
	box("MusicBox", Vector3.new(0.8, 0.5, 0.6), stand * CFrame.new(0, 0.25, 0), Color3.fromRGB(150, 110, 90), M.Wood)
	Furniture.dollhouse(b, at(46.5, 31.5, O, "N"))
	box("DollShelf", Vector3.new(0.6, 0.15, 6), CFrame.new(L(44.6, 27, O + 4.5)), Color3.fromRGB(110, 84, 60), M.Wood)
	for i = 0, 4 do
		Furniture.doll(b, at(44.7, 24.6 + i * 1.2, O + 4.58, "E"), Color3.fromRGB(120 + i * 20, 60, 70))
	end

	-- Bad
	Furniture.bathtub(b, at(56.6, 24, O, "E"))
	Furniture.sink(b, at(61, 18.9, O, "N"))
	Furniture.mirror(b, at(61, 18.6, O + 5.6, "N"), true)
	Furniture.toilet(b, at(62.9, 30, O, "W"))

	-- Elternschlafzimmer
	Furniture.bed(b, at(72, 26, O, "S"), 6, 7, Color3.fromRGB(90, 50, 46))
	Furniture.nightstand(b, at(68, 21, O, "S"))
	Furniture.nightstand(b, at(76, 21, O, "S"))
	Furniture.wardrobe(b, at(79.4, 29.5, O, "W"), 4)
	Furniture.mirror(b, at(64.4, 26, O + 5.2, "E"))
	Furniture.picture(b, at(72, 12.54, O + 5, "S"), 4, 3, Color3.fromRGB(60, 50, 44), true) -- Familienfoto, Gesichter zerkratzt

	-- Spielzimmer
	Furniture.rockingHorse(b, at(66, 62, O, -60))
	Furniture.toyBox(b, at(57, 70.6, O, "N"))
	Furniture.shelf(b, at(56, 64.5, O, "E"), 4, 5, "books", rng)
	local tea = Furniture.table(b, at(68, 67, O), 2.4, 2.4, 1.8)
	for i = 0, 3 do
		box("TeaCup", Vector3.new(0.35, 0.3, 0.35), tea * CFrame.new(math.cos(i * 1.57) * 0.7, 0.15, math.sin(i * 1.57) * 0.7), Color3.fromRGB(210, 200, 190))
	end
	for i, color in { Color3.fromRGB(160, 40, 40), Color3.fromRGB(40, 90, 160), Color3.fromRGB(200, 170, 40), Color3.fromRGB(60, 140, 60) } do
		box("Block", Vector3.new(0.6, 0.6, 0.6), CFrame.new(L(61 + i * 0.9, 64 + (i % 2), O + 0.3)) * CFrame.Angles(0, i * 0.7, 0), color, M.Wood)
	end

	-- Nähzimmer im Turm
	Furniture.sewing(b, at(84, 70, O, "S"))
	Furniture.rug(b, at(84, 66, O), 8, 8, Color3.fromRGB(80, 50, 50))

	-- Großmutters Zimmer (abgeschlossen): Bett unter Tuch, Schaukelstuhl, Staub
	Furniture.bed(b, at(18, 44, O, "E"), 4.6, 7, Color3.fromRGB(180, 174, 160))
	Furniture.wardrobe(b, at(30, 38.9, O, "S"), 4)
	Furniture.chair(b, at(28, 52, O, 200), Color3.fromRGB(60, 46, 34))
	Furniture.picture(b, at(14.54, 52, O + 5, "E"), 2.2, 3, Color3.fromRGB(70, 66, 56), true)
	Furniture.sofa(b, at(36, 56, O, "W"), 3, Color3.fromRGB(80, 70, 60), true)
	for i = 1, 6 do
		box("Cobweb", Vector3.new(2.4, 2.4, 0.02), CFrame.new(L(14.6 + (i % 2) * 26.6, 38.6 + i * 3.2, CEIL.O - 1.1)) * CFrame.Angles(0, math.rad(45), math.rad(45)), Color3.fromRGB(200, 200, 196), M.SmoothPlastic, { Transparency = 0.7, CanCollide = false })
	end

	------------------------------------------------ Keller
	Furniture.shelf(b, at(36, 21, Kf, "S"), 3.6, 7, "jars", rng)
	Furniture.shelf(b, at(41, 21, Kf, "S"), 3.6, 7, "jars", rng)
	-- das verschiebbare Regal vor dem Geheimgang
	local secret = Instance.new("Model")
	secret.Name = "SecretShelf"
	local before = current
	current = secret
	Furniture.shelf(b, at(47, 20.75, Kf, "S"), 3.6, 6.6, "jars", rng)
	current = before
	secret.Parent = current
	Furniture.shelf(b, at(35, 30, Kf, "E"), 6, 7, "jars", rng)
	for i = 0, 3 do
		box("Crate", Vector3.new(2, 1.6, 2), CFrame.new(L(38 + i * 2.3, 25.5, Kf + 0.8)) * CFrame.Angles(0, i * 0.3, 0), Color3.fromRGB(100, 80, 56), M.WoodPlanks)
	end
	-- Waschkeller
	Furniture.washtub(b, at(20, 44, Kf))
	-- Wäscheleinen von Wand zu Wand gespannt
	Furniture.clothesline(b, L(14.5, 50, Kf + 6.4), L(33.5, 50, Kf + 6.4), rng)
	Furniture.clothesline(b, L(14.5, 55, Kf + 6.4), L(33.5, 55, Kf + 6.4), rng)
	-- Heizungsraum
	Furniture.boiler(b, at(60, 24, Kf, "S"))
	for i = 0, 2 do
		local pipeY = Kf + 7.6 - i * 0.4
		beam("Pipe", L(55, 20 + i * 2, pipeY), L(69, 20 + i * 2, pipeY), 0.3, COLORS.metal, M.Metal)
		-- Halterungen an der Decke
		for _, x in { 57, 62, 67 } do
			box("PipeHanger", Vector3.new(0.08, CEIL.K - pipeY + 0.1, 0.08), CFrame.new(L(x, 20 + i * 2, (CEIL.K + pipeY) / 2 + 0.05)), COLORS.metal, M.Metal)
		end
	end
	-- Kriechkeller: Kisten
	for i = 0, 5 do
		box("Box", Vector3.new(2, 1.5, 2), CFrame.new(L(72 + (i % 3) * 2.8, 22 + math.floor(i / 3) * 12, Kf + 0.75)) * CFrame.Angles(0, i, 0), Color3.fromRGB(110, 90, 64), M.Cardboard)
	end
	-- Ritualraum: Altar, Kreis aus Kerzen, Zeichen, Fotos früherer Gäste
	Furniture.altar(b, at(47, -2.6, Kf, "S"))
	local circle = {}
	for i = 0, 11 do
		local angle = i / 12 * math.pi * 2
		local p = Vector3.new(47 + math.cos(angle) * 5.2, 0, 3 + math.sin(angle) * 5.2)
		table.insert(circle, p)
		if i % 2 == 0 then
			candle(CFrame.new(L(p.X, p.Z, Kf)), 1.2, 9, 0.8)
		end
	end
	for i = 1, #circle do
		local a, c = circle[i], circle[i % #circle + 1]
		beam("Sigil", L(a.X, a.Z, Kf + 0.03), L(c.X, c.Z, Kf + 0.03), 0.18, COLORS.blood, M.SmoothPlastic)
	end
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2 - math.pi / 2
		local c = (i + 2) / 5 * math.pi * 2 - math.pi / 2
		beam("Sigil", L(47 + math.cos(a) * 4.6, 3 + math.sin(a) * 4.6, Kf + 0.04), L(47 + math.cos(c) * 4.6, 3 + math.sin(c) * 4.6, Kf + 0.04), 0.16, COLORS.blood, M.SmoothPlastic)
	end
	for i = 0, 7 do
		local angle = math.rad(200 + i * 18)
		local p = L(47 + math.cos(angle) * 8.6, 3 + math.sin(angle) * 8.6, Kf + 5.2)
		box("GuestPhoto", Vector3.new(0.9, 1.2, 0.05), CFrame.lookAt(p, L(47, 3, Kf + 5.2)), Color3.fromRGB(160, 150, 130), M.SmoothPlastic)
		box("PhotoCross", Vector3.new(0.9, 0.08, 0.02), CFrame.lookAt(p, L(47, 3, Kf + 5.2)) * CFrame.new(0, 0, -0.04) * CFrame.Angles(0, 0, math.rad(40)), COLORS.blood, M.SmoothPlastic)
	end
end

------------------------------------------------------------------ Gelände und Tunnel
local TUNNEL = { { 37.6, 3 }, { 28, 0 }, { 18, 6 }, { 8, -2 }, { -6, -6 }, { -20, -2 } }

local function buildTerrainAndTunnel()
	local terrain = workspace.Terrain
	-- Gelände unter und um das Haus einebnen (knapp unter dem Hof), Keller ausheben
	local center = L(46, 44)
	local size = Vector3.new(104, 0, 96)
	breathe()
	terrain:FillBlock(origin * CFrame.new(center.X, -8, center.Z), Vector3.new(size.X, 15.2, size.Z), Enum.Material.Ground)
	breathe()
	terrain:FillBlock(origin * CFrame.new(center.X, 22, center.Z), Vector3.new(size.X, 44.8, size.Z), Enum.Material.Air)
	for _, room in ROOMS.K do
		local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
		for _, p in room.poly do
			minX, maxX = math.min(minX, p[1]), math.max(maxX, p[1])
			minY, maxY = math.min(minY, p[2]), math.max(maxY, p[2])
		end
		-- unter dem Haus bis unter den Fußboden, draußen nur bis zur eigenen Decke
		local top = room.id == "ritual" and -2.0 or -0.3
		local c = L((minX + maxX) / 2, (minY + maxY) / 2, (-8.9 + top) / 2)
		breathe()
		terrain:FillBlock(origin * CFrame.new(c), Vector3.new(maxX - minX + 2, top + 8.9, maxY - minY + 2), Enum.Material.Air)
	end
	-- Tunnel: windet sich vom Ritualraum hinaus in den Wald, mit Holzstützen. Hinter dem
	-- Haus fällt das Gelände ab, deshalb geht der Tunnel mit nach unten (immer Erde darüber).
	local function groundAt(point)
		local world = origin * point
		return Route.groundY(world.X, world.Z) - origin.Y
	end
	local function tunnelFloor(x, y)
		local point = L(x, y)
		local ground = math.min(groundAt(point), -0.4)
		return Vector3.new(point.X, math.min(FLOOR.K, ground - 8.6), point.Z)
	end
	for i = 1, #TUNNEL - 1 do
		local a, c = tunnelFloor(TUNNEL[i][1], TUNNEL[i][2]), tunnelFloor(TUNNEL[i + 1][1], TUNNEL[i + 1][2])
		local length = (c - a).Magnitude
		local mid = (a + c) / 2
		local frame = CFrame.lookAt(mid, c)
		breathe()
		terrain:FillBlock(origin * frame * CFrame.new(0, 2.9, 0), Vector3.new(4.6, 5.8, length + 4), Enum.Material.Air)
		box("TunnelFloor", Vector3.new(4.6, 0.4, length + 2), frame * CFrame.new(0, -0.2, 0), Color3.fromRGB(70, 56, 40), M.Ground)
		local count = math.floor(length / 6)
		for k = 0, count do
			local s = -length / 2 + k * length / math.max(count, 1)
			for _, x in { -2, 2 } do
				box("TunnelPost", Vector3.new(0.5, 5.4, 0.5), frame * CFrame.new(x, 2.7, s), Color3.fromRGB(80, 60, 40), M.Wood)
			end
			box("TunnelBeam", Vector3.new(4.6, 0.5, 0.5), frame * CFrame.new(0, 5.4, s), Color3.fromRGB(80, 60, 40), M.Wood)
		end
	end
	-- am Ende: ein Schacht mit Leiter hinauf zu einer verschlossenen Luke im Waldboden
	local last = tunnelFloor(TUNNEL[#TUNNEL][1], TUNNEL[#TUNNEL][2])
	local surface = groundAt(Vector3.new(last.X, 0, last.Z))
	local height = surface - last.Y
	breathe()
	terrain:FillBlock(origin * CFrame.new(last + Vector3.new(0, height / 2, -1.4)), Vector3.new(4, height, 4), Enum.Material.Air)
	for k = 0, math.floor((height - 1) / 0.9) do
		box("LadderRung", Vector3.new(2, 0.2, 0.2), CFrame.new(last + Vector3.new(0, 0.8 + k * 0.9, -1.8)), Color3.fromRGB(90, 70, 46), M.Wood)
	end
	for _, x in { -1, 1 } do
		box("LadderRail", Vector3.new(0.25, height, 0.25), CFrame.new(last + Vector3.new(x, height / 2, -1.8)), Color3.fromRGB(90, 70, 46), M.Wood)
	end
	box("Hatch", Vector3.new(3.4, 0.4, 3.4), CFrame.new(last + Vector3.new(0, height - 0.1, -1.4)), Color3.fromRGB(70, 54, 36), M.WoodPlanks)
end

------------------------------------------------------------------ Fußabdruck (zum Freiräumen)
local FOOTPRINT = {
	{ 41.75, 72 }, { 54.25, 72 }, { 72.5, 72 }, K[3], K[2], K[1], K[0], K[7], K[6], K[5],
	{ 80.56, 18 }, { 78, 18 }, { 76, 12 }, { 68, 12 }, { 66, 18 }, { 54.25, 18 }, { 54.25, 8 }, { 40, 8 }, { 40, 20 }, { 34, 20 }, { 34, 30 }, { 20, 30 },
	HEX[1], HEX[6], HEX[5], HEX[4], { 8, 30 }, { 8, 34 }, { 14, 38 }, { 14, 60 }, { 10, 60 }, { 10, 72 }, { 18, 80 }, { 36, 80 }, { 36, 72 },
}

local function distanceToSegment(px, py, a, b)
	local dx, dy = b[1] - a[1], b[2] - a[2]
	local u = math.clamp(((px - a[1]) * dx + (py - a[2]) * dy) / (dx * dx + dy * dy), 0, 1)
	local x, y = a[1] + u * dx - px, a[2] + u * dy - py
	return math.sqrt(x * x + y * y)
end

-- Liegt ein Punkt (Welt) im Haus oder näher als `margin` daran?
-- Steht dieser Punkt im Haus (im Grundriss, nicht tief im Keller oder Tunnel)?
function Mansion.isInside(worldPosition)
	if not origin then
		return false
	end
	local relative = origin:Inverse() * worldPosition
	return relative.Y > -12 and pointInPolygon(relative.X + 50, 57.4 - relative.Z, FOOTPRINT)
end

function Mansion.covers(worldPosition, margin)
	local relative = origin:Inverse() * worldPosition
	local x, y = relative.X + 50, 57.4 - relative.Z
	if pointInPolygon(x, y, FOOTPRINT) or pointInPolygon(x, y, RITUAL) then
		return true
	end
	for i = 1, #FOOTPRINT do
		if distanceToSegment(x, y, FOOTPRINT[i], FOOTPRINT[i % #FOOTPRINT + 1]) < margin then
			return true
		end
	end
	-- auch über dem Ritualraum und dem Tunnel (unter der Erde) darf nichts stehen
	for i = 1, #RITUAL do
		if distanceToSegment(x, y, RITUAL[i], RITUAL[i % #RITUAL + 1]) < margin then
			return true
		end
	end
	for i = 1, #TUNNEL - 1 do
		if distanceToSegment(x, y, TUNNEL[i], TUNNEL[i + 1]) < margin then
			return true
		end
	end
	return false
end

-- Bäume, Büsche, Wegplatten usw. aus Kapitel 1 entfernen, die im Haus stehen würden
function Mansion.clearAround(levelFolder)
	if not origin or not levelFolder then
		return
	end
	local removed = 0
	local function visit(folder)
		for _, child in folder:GetChildren() do
			breathe()
			if child ~= Mansion.model then
				if child:IsA("Folder") then
					visit(child)
				else
					local position
					if child:IsA("Model") then
						local part = child:FindFirstChildWhichIsA("BasePart", true)
						position = part and part.Position
					elseif child:IsA("BasePart") then
						position = child.Position
					end
					-- Bäume (Modelle) brauchen mehr Abstand, ihre Kronen sind breit
					local margin = child:IsA("Model") and 15 or 6
					if position and position.Y > origin.Y - 20 and Mansion.covers(position, margin) then
						child:Destroy()
						removed += 1
					end
				end
			end
		end
	end
	visit(levelFolder)
	return removed
end

------------------------------------------------------------------ Start
function Mansion.build(model, houseOrigin)
	origin = houseOrigin
	Mansion.doors = {}
	Mansion.beds = {}
	Mansion.model = model
	Mansion.origin = houseOrigin
	local root = newFolder("Mansion", model)

	local steps = {
		{ "Ground", buildTerrainAndTunnel },
		{ "Walls", buildWalls },
		{ "FloorsAndRoofs", buildFloorsAndRoofs },
		{ "Stairs", buildStairs },
		{ "Furniture", buildFurniture },
	}
	for _, step in steps do
		local started = os.clock()
		current = newFolder(step[1], root)
		step[2]()
		print(string.format("Kapitel 2: Haus – %s fertig (%.1f s)", step[1], os.clock() - started))
		task.wait()
		lastBreath = os.clock()
	end
	-- Eingangshalle wie bisher: Treppe, Galerie, Uhr, Garderobe, Spiegel …
	HouseInterior.build(model, origin, true)
	task.wait()
	lastBreath = os.clock()
	return root
end

-- Die Tür an dieser Stelle im Plan (für Szenen, z. B. die Wagners schließen sie)
function Mansion.doorAt(x, y, floorKey)
	for _, door in Mansion.doors do
		if door.model and door.floor == (floorKey or "E") and math.abs(door.x - x) < 0.3 and math.abs(door.y - y) < 0.3 then
			return door
		end
	end
	return nil
end

-- Stellen für die Familie (Haus-Koordinaten über dem Boden)
function Mansion.spot(x, y, floorKey)
	return origin * CFrame.new(L(x, y, FLOOR[floorKey or "E"]))
end

return Mansion
