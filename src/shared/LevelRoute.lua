-- Strecke der ersten Zwischensequenz (Level 1): Waldstraße, Fahrspur, Parkbucht,
-- Waldweg und Fahrplan. Server (baut die Straße) und Client (fährt das Auto)
-- benutzen dieselben Rechnungen, deshalb sehen alle Spieler dasselbe.
local LevelRoute = {}

LevelRoute.GROUND_Y = 0.2 -- Oberkante von Straße und Parkbucht
LevelRoute.ROAD_WIDTH = 20
LevelRoute.LANE_OFFSET = 4.8 -- Mitte der rechten Fahrspur
LevelRoute.LAYBY_OFFSET = 16.5 -- Mitte der Parkbucht rechts neben der Straße
LevelRoute.LAYBY_WIDTH = 13

LevelRoute.SPEED = 42 -- Studs pro Sekunde (etwa 55 km/h)
LevelRoute.CRUISE_TIME = 30 -- so lange fährt man, bevor gebremst wird
LevelRoute.BRAKE_DISTANCE = 75
LevelRoute.START_S = 60

-- Im Auto (relativ zur Fahrzeugmitte am Boden): Augen für die Kamera und Hüfte für Mitfahrer
LevelRoute.CAR_EYES = { Driver = CFrame.new(-1.35, 4.75, 1.85), Passenger = CFrame.new(1.35, 4.75, 1.85) }
LevelRoute.CAR_HIPS = { Driver = CFrame.new(-1.35, 3.2, 1.45), Passenger = CFrame.new(1.35, 3.2, 1.45) }

local SAMPLE_SPACING = 4
local CONTROL_POINTS = {
	Vector3.new(0, 0, 60),
	Vector3.new(0, 0, -120),
	Vector3.new(45, 0, -320),
	Vector3.new(20, 0, -520),
	Vector3.new(-55, 0, -700),
	Vector3.new(-40, 0, -900),
	Vector3.new(25, 0, -1060),
	Vector3.new(60, 0, -1220),
	Vector3.new(62, 0, -1420),
	-- Hinter der Parkbucht macht die Straße eine Rechtskurve; danach liegt rechts das Haus
	Vector3.new(80, 0, -1500),
	Vector3.new(140, 0, -1555),
	Vector3.new(250, 0, -1580),
	Vector3.new(380, 0, -1585),
}

local function catmullRom(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5
		* ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

-- Fein abgetastete Straßenmitte mit aufsummierter Länge
local points, lengths = {}, {}
do
	local count = #CONTROL_POINTS
	for i = 1, count - 1 do
		local p0 = CONTROL_POINTS[math.max(i - 1, 1)]
		local p1, p2 = CONTROL_POINTS[i], CONTROL_POINTS[i + 1]
		local p3 = CONTROL_POINTS[math.min(i + 2, count)]
		local steps = math.max(1, math.ceil((p2 - p1).Magnitude / SAMPLE_SPACING))
		for step = 0, steps - 1 do
			table.insert(points, catmullRom(p0, p1, p2, p3, step / steps))
		end
	end
	table.insert(points, CONTROL_POINTS[count])
	lengths[1] = 0
	for i = 2, #points do
		lengths[i] = lengths[i - 1] + (points[i] - points[i - 1]).Magnitude
	end
end
LevelRoute.TOTAL_LENGTH = lengths[#lengths]

-- Bremsen und Halten in der Parkbucht
local deceleration = LevelRoute.SPEED ^ 2 / (2 * LevelRoute.BRAKE_DISTANCE)
LevelRoute.STOP_S = LevelRoute.START_S + LevelRoute.SPEED * LevelRoute.CRUISE_TIME + LevelRoute.BRAKE_DISTANCE
LevelRoute.STOP_TIME = LevelRoute.CRUISE_TIME + LevelRoute.SPEED / deceleration
LevelRoute.LAYBY_START_S = LevelRoute.STOP_S - 55
LevelRoute.LAYBY_END_S = LevelRoute.STOP_S + 20

-- Position der Straßenmitte nach `s` Studs Strecke
function LevelRoute.centerAt(s)
	s = math.clamp(s, 0, LevelRoute.TOTAL_LENGTH)
	local low, high = 1, #lengths
	while high - low > 1 do
		local middle = (low + high) // 2
		if lengths[middle] <= s then
			low = middle
		else
			high = middle
		end
	end
	local span = lengths[high] - lengths[low]
	local alpha = span > 0 and (s - lengths[low]) / span or 0
	return points[low]:Lerp(points[high], alpha)
end

-- Richtung der Straße und "rechts" an der Stelle `s`
function LevelRoute.frameAt(s)
	local ahead = LevelRoute.centerAt(s + 2)
	local behind = LevelRoute.centerAt(s - 2)
	local forward = (ahead - behind).Unit
	return LevelRoute.centerAt(s), forward, forward:Cross(Vector3.yAxis)
end

-- Punkt seitlich der Straße (positiv = rechts)
function LevelRoute.sidePoint(s, offset, forwardOffset)
	local center, forward, right = LevelRoute.frameAt(s)
	return center + right * offset + forward * (forwardOffset or 0)
end

-- Gefahrene Strecke und Geschwindigkeit nach `t` Sekunden
function LevelRoute.driveDistance(t)
	local speed = LevelRoute.SPEED
	if t <= 0 then
		return LevelRoute.START_S, speed
	elseif t <= LevelRoute.CRUISE_TIME then
		return LevelRoute.START_S + speed * t, speed
	end
	local braking = math.min(t - LevelRoute.CRUISE_TIME, speed / deceleration)
	local s = LevelRoute.START_S + speed * LevelRoute.CRUISE_TIME + speed * braking - 0.5 * deceleration * braking ^ 2
	return s, math.max(0, speed - deceleration * braking)
end

-- Seitlicher Abstand des Autos: rechte Spur, am Ende sanft in die Parkbucht
local function lateralAt(s)
	local t = math.clamp((s - (LevelRoute.STOP_S - 70)) / 60, 0, 1)
	local smooth = t * t * (3 - 2 * t)
	return LevelRoute.LANE_OFFSET + (LevelRoute.LAYBY_OFFSET - LevelRoute.LANE_OFFSET) * smooth
end

local function carPosition(s)
	local center, _, right = LevelRoute.frameAt(s)
	return Vector3.new(center.X, LevelRoute.GROUND_Y, center.Z) + right * lateralAt(s)
end

-- CFrame des Autos (Boden unter der Fahrzeugmitte, Blick in Fahrtrichtung)
function LevelRoute.carCFrame(s)
	local position = carPosition(s)
	return CFrame.lookAt(position, carPosition(s + 3))
end

-- Lenkeinschlag (Bogenmaß): wie stark sich die Richtung in den nächsten Metern ändert
function LevelRoute.steerAt(s)
	local _, forwardNow = LevelRoute.frameAt(s)
	local _, forwardAhead = LevelRoute.frameAt(s + 14)
	local cross = forwardNow:Cross(forwardAhead).Y
	return math.clamp(math.asin(math.clamp(cross, -1, 1)), -0.5, 0.5)
end

-- Abgetastete Straßenmitte (z. B. alle 8 Studs) zum Bauen
function LevelRoute.roadSamples(spacing)
	local samples = {}
	local s = 0
	while s < LevelRoute.TOTAL_LENGTH do
		table.insert(samples, s)
		s += spacing
	end
	table.insert(samples, LevelRoute.TOTAL_LENGTH)
	return samples
end

------------------------------------------------------------------ Haus der Gastfamilie
-- Das Haus der Wagners steht hinter der Rechtskurve rechts der Straße.
-- Die Vorderseite (mit Veranda) zeigt zur Straße.
LevelRoute.HOUSE_S = 1620
LevelRoute.HOUSE_OFFSET = 62
LevelRoute.HOUSE_SIZE = Vector3.new(40, 26, 30) -- Wohnhaus: Breite, Höhe (bis zum First), Tiefe
LevelRoute.GARAGE_X = 29 -- Mitte der Garage (rechts neben dem Wohnhaus, von vorne gesehen links)
LevelRoute.GARAGE_SIZE = Vector3.new(18, 13, 24)

function LevelRoute.houseCFrame()
	local center = LevelRoute.sidePoint(LevelRoute.HOUSE_S, LevelRoute.HOUSE_OFFSET, 0)
	local road = LevelRoute.sidePoint(LevelRoute.HOUSE_S, 0, 0)
	return CFrame.lookAt(
		Vector3.new(center.X, LevelRoute.GROUND_Y, center.Z),
		Vector3.new(road.X, LevelRoute.GROUND_Y, road.Z)
	)
end

-- Punkt relativ zum Haus (x nach rechts, z nach hinten; die Straße liegt bei -z)
function LevelRoute.housePoint(x, z)
	return (LevelRoute.houseCFrame() * CFrame.new(x, 0, z)).Position
end

-- Vor der Verandatreppe (dort endet der Waldweg)
function LevelRoute.porchPoint()
	return LevelRoute.housePoint(-2, -LevelRoute.HOUSE_SIZE.Z / 2 - 11)
end

local function onGround(points)
	for i, point in points do
		points[i] = Vector3.new(point.X, LevelRoute.GROUND_Y, point.Z)
	end
	return points
end

-- Waldweg von der Parkbucht quer durch den Wald (Abkürzung durch die Kurve) bis vor das Haus
function LevelRoute.forestPath()
	local stop = LevelRoute.STOP_S
	local points = {
		LevelRoute.sidePoint(stop - 4, LevelRoute.LAYBY_OFFSET + LevelRoute.LAYBY_WIDTH / 2 - 0.5, 0),
		LevelRoute.sidePoint(stop + 2, 34, 0),
	}
	-- dazwischen schlängelt sich der Weg; er kommt links neben dem Haus aus dem Wald
	local from, corner = points[2], LevelRoute.housePoint(-36, -24)
	local across = (corner - from).Unit:Cross(Vector3.yAxis)
	local wiggle = { 6, -5, 7, -3 }
	for i, sideways in wiggle do
		table.insert(points, from:Lerp(corner, i / (#wiggle + 1)) + across * sideways)
	end
	table.insert(points, corner)
	table.insert(points, LevelRoute.porchPoint())
	return onGround(points)
end

-- Einfahrt: biegt am Haus rechts von der Straße ab und endet vor dem Garagentor
function LevelRoute.drivewayPath()
	local x = LevelRoute.GARAGE_X
	local door = -LevelRoute.GARAGE_SIZE.Z / 2
	return onGround({
		LevelRoute.sidePoint(LevelRoute.HOUSE_S - 6, 6.5, 0),
		LevelRoute.sidePoint(LevelRoute.HOUSE_S + 6, 10.5, 0),
		LevelRoute.housePoint(x - 6, door - 30),
		LevelRoute.housePoint(x - 1, door - 22),
		LevelRoute.housePoint(x, door - 14),
	})
end

-- Wo Sarp am Beifahrerfenster steht
function LevelRoute.windowPoint()
	local window = (LevelRoute.carCFrame(LevelRoute.STOP_S) * CFrame.new(7.2, 0, 0.6)).Position
	return Vector3.new(window.X, LevelRoute.GROUND_Y, window.Z)
end

-- Sarp kommt aus dem Wald (vom dritten Wegpunkt) bis ans Beifahrerfenster
function LevelRoute.strangerWaypoints()
	local path = LevelRoute.forestPath()
	return { path[3], path[2], path[1], LevelRoute.windowPoint() }
end

------------------------------------------------------------------ Linienzüge mit Längenangabe
-- Glättet Punkte (Catmull-Rom) und erlaubt "Position nach s Studs".
function LevelRoute.polyline(controlPoints, spacing)
	local samples = {}
	local count = #controlPoints
	for i = 1, count - 1 do
		local p0 = controlPoints[math.max(i - 1, 1)]
		local p1, p2 = controlPoints[i], controlPoints[i + 1]
		local p3 = controlPoints[math.min(i + 2, count)]
		local steps = math.max(1, math.ceil((p2 - p1).Magnitude / (spacing or 2)))
		for step = 0, steps - 1 do
			table.insert(samples, catmullRom(p0, p1, p2, p3, step / steps))
		end
	end
	table.insert(samples, controlPoints[count])
	local sums = { 0 }
	for i = 2, #samples do
		sums[i] = sums[i - 1] + (samples[i] - samples[i - 1]).Magnitude
	end

	local line = { length = sums[#sums] }
	function line.at(s)
		s = math.clamp(s, 0, line.length)
		local low, high = 1, #sums
		while high - low > 1 do
			local middle = (low + high) // 2
			if sums[middle] <= s then
				low = middle
			else
				high = middle
			end
		end
		local span = sums[high] - sums[low]
		return samples[low]:Lerp(samples[high], span > 0 and (s - sums[low]) / span or 0)
	end
	-- Blickrichtung an der Stelle s (leicht vorausschauend)
	function line.cframeAt(s)
		local here = line.at(s)
		local ahead = line.at(s + 3)
		if (ahead - here).Magnitude < 0.05 then
			ahead = here + (here - line.at(s - 3))
		end
		return CFrame.lookAt(here, Vector3.new(ahead.X, here.Y, ahead.Z))
	end
	return line
end

-- Fahrplan: anfahren, gleichmäßig fahren, am Ende bremsen. Gibt Strecke und Tempo zurück.
function LevelRoute.profile(t, length, topSpeed, acceleration, brakeDistance)
	if t <= 0 then
		return 0, 0
	end
	local brake = topSpeed ^ 2 / (2 * brakeDistance)
	local accelTime = topSpeed / acceleration
	local accelDistance = 0.5 * acceleration * accelTime ^ 2
	local cruiseDistance = math.max(0, length - accelDistance - brakeDistance)
	local cruiseTime = cruiseDistance / topSpeed
	if t < accelTime then
		return 0.5 * acceleration * t ^ 2, acceleration * t
	elseif t < accelTime + cruiseTime then
		return accelDistance + topSpeed * (t - accelTime), topSpeed
	end
	local braking = math.min(t - accelTime - cruiseTime, topSpeed / brake)
	local s = accelDistance + cruiseDistance + topSpeed * braking - 0.5 * brake * braking ^ 2
	return math.min(s, length), math.max(0, topSpeed - brake * braking)
end

-- Wie lange `profile` für die ganze Strecke braucht
function LevelRoute.profileDuration(length, topSpeed, acceleration, brakeDistance)
	local accelTime = topSpeed / acceleration
	local accelDistance = 0.5 * acceleration * accelTime ^ 2
	local cruiseDistance = math.max(0, length - accelDistance - brakeDistance)
	local brake = topSpeed ^ 2 / (2 * brakeDistance)
	return accelTime + cruiseDistance / topSpeed + topSpeed / brake
end

------------------------------------------------------------------ Sarp kommt ans Auto
-- Er läuft los, kurz bevor das Auto steht, gleichmäßig und langsam. Alle Spieler
-- sehen ihn deshalb zur selben Zeit am selben Ort.
LevelRoute.STRANGER_SPEED = 4.5
LevelRoute.STRANGER_START = LevelRoute.STOP_TIME - 3

function LevelRoute.strangerLine()
	return LevelRoute.polyline(LevelRoute.strangerWaypoints(), 1)
end

-- Sekunden nach dem Start, wann Sarp am Fenster steht
function LevelRoute.strangerArrival()
	return LevelRoute.STRANGER_START + LevelRoute.strangerLine().length / LevelRoute.STRANGER_SPEED
end
LevelRoute.DIALOGUE_DELAY = 2.5 -- so lange starrt er stumm, bevor er klopft

------------------------------------------------------------------ Ende A: weiterfahren zum Haus
-- Aus der Parkbucht zurück auf die Spur, durch die Kurve, dann die Einfahrt hoch
function LevelRoute.driveToHouseLine()
	local points = {}
	for s = LevelRoute.STOP_S, LevelRoute.HOUSE_S - 14, 6 do
		local t = math.clamp((s - LevelRoute.STOP_S) / 45, 0, 1)
		local smooth = t * t * (3 - 2 * t)
		local lateral = LevelRoute.LAYBY_OFFSET + (LevelRoute.LANE_OFFSET - LevelRoute.LAYBY_OFFSET) * smooth
		table.insert(points, LevelRoute.sidePoint(s, lateral, 0))
	end
	for _, point in LevelRoute.drivewayPath() do
		table.insert(points, point)
	end
	return LevelRoute.polyline(onGround(points), 2)
end
LevelRoute.DRIVE_TOP_SPEED = 21
LevelRoute.DRIVE_ACCELERATION = 6
LevelRoute.DRIVE_BRAKE = 34

function LevelRoute.driveDuration()
	return LevelRoute.profileDuration(LevelRoute.driveToHouseLine().length, LevelRoute.DRIVE_TOP_SPEED, LevelRoute.DRIVE_ACCELERATION, LevelRoute.DRIVE_BRAKE)
end

------------------------------------------------------------------ Ende B: zu Fuß durch den Wald
-- Vom Beifahrerfenster über den Waldweg bis vor die Veranda
function LevelRoute.walkLine()
	local points = { LevelRoute.windowPoint() - LevelRoute.carCFrame(LevelRoute.STOP_S).RightVector * 1.5 }
	for _, point in LevelRoute.forestPath() do
		table.insert(points, point)
	end
	return LevelRoute.polyline(points, 2)
end
LevelRoute.WALK_SPEED = 8.5
LevelRoute.WALK_EYE_HEIGHT = 4.6
LevelRoute.WALK_FADE = 3 -- Sekunden (Abblenden, Aussteigen, Aufblenden), bevor man losläuft
LevelRoute.WALK_STOP_BEFORE = 7 -- so weit vor der Veranda bleibt man stehen

function LevelRoute.walkDuration()
	return LevelRoute.WALK_FADE + (LevelRoute.walkLine().length - LevelRoute.WALK_STOP_BEFORE) / LevelRoute.WALK_SPEED
end

-- Sarps Abgang: von der Veranda seitlich am Haus vorbei in den Wald
function LevelRoute.leaveLine()
	return LevelRoute.polyline(onGround({
		LevelRoute.porchPoint(),
		LevelRoute.housePoint(-26, -26),
		LevelRoute.housePoint(-32, -4),
		LevelRoute.housePoint(-36, 20),
		LevelRoute.housePoint(-42, 44),
	}), 1)
end

local function distanceToPolyline(x, z, polyline)
	local best = math.huge
	for i = 1, #polyline - 1 do
		local a, b = polyline[i], polyline[i + 1]
		local dx, dz = b.X - a.X, b.Z - a.Z
		local lengthSquared = dx * dx + dz * dz
		local t = lengthSquared > 0 and math.clamp(((x - a.X) * dx + (z - a.Z) * dz) / lengthSquared, 0, 1) or 0
		local px, pz = a.X + dx * t - x, a.Z + dz * t - z
		best = math.min(best, math.sqrt(px * px + pz * pz))
	end
	return best
end

-- Grobe Straßenmitte (alle 16 Studs) für Abstandsberechnungen
local coarse = {}
for _, s in LevelRoute.roadSamples(16) do
	table.insert(coarse, LevelRoute.centerAt(s))
end
local laybyLine = {}
for s = LevelRoute.LAYBY_START_S, LevelRoute.LAYBY_END_S, 5 do
	table.insert(laybyLine, LevelRoute.sidePoint(s, LevelRoute.LAYBY_OFFSET, 0))
end

function LevelRoute.distanceToRoad(x, z)
	return distanceToPolyline(x, z, coarse)
end

function LevelRoute.distanceToLayby(x, z)
	return distanceToPolyline(x, z, laybyLine)
end

local function samplesOf(line, spacing)
	local samples = {}
	for s = 0, line.length, spacing do
		table.insert(samples, line.at(s))
	end
	table.insert(samples, line.at(line.length))
	return samples
end
local drivewayLine = samplesOf(LevelRoute.polyline(LevelRoute.drivewayPath(), 2), 3)
local pathLine = samplesOf(LevelRoute.polyline(LevelRoute.forestPath(), 2), 3)

-- Geglättete Punkte des Waldwegs (zum Bauen)
function LevelRoute.forestPathSamples()
	return pathLine
end
function LevelRoute.drivewaySamples()
	return drivewayLine
end

function LevelRoute.distanceToDriveway(x, z)
	return distanceToPolyline(x, z, drivewayLine)
end

-- Abstand zum Grundstück (Haus, Garage, Veranda und Hof), 0 = am Rand
function LevelRoute.distanceToHouse(x, z)
	local yard = LevelRoute.houseCFrame():Inverse() * Vector3.new(x, LevelRoute.GROUND_Y, z)
	local dx = math.max(math.abs(yard.X - 4) - 42, 0)
	local dz = math.max(math.abs(yard.Z + 4) - 30, 0)
	return math.sqrt(dx * dx + dz * dz)
end

function LevelRoute.distanceToPath(x, z)
	return distanceToPolyline(x, z, pathLine)
end

return LevelRoute
