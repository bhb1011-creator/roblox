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
	-- Hinter der Parkbucht wendet die Straße in einer weiten Kehre (180°) und führt auf
	-- der anderen Seite des Waldes zurück. Dort liegt rechts, oben am Hang, das Haus.
	Vector3.new(80, 0, -1500),
	Vector3.new(130, 0, -1572),
	Vector3.new(210, 0, -1598),
	Vector3.new(285, 0, -1568),
	Vector3.new(326, 0, -1492),
	Vector3.new(336, 0, -1390),
	Vector3.new(332, 0, -1260),
	Vector3.new(322, 0, -1120),
	Vector3.new(305, 0, -980),
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

------------------------------------------------------------------ Abstände
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

------------------------------------------------------------------ Haus der Gastfamilie
-- Das Haus der Wagners steht nach der Kehre rechts der Straße, oben auf einem Hügel.
-- Die Vorderseite (mit Veranda) zeigt zur Straße.
LevelRoute.HOUSE_S = 2155
LevelRoute.HOUSE_OFFSET = 120
LevelRoute.HILL_HEIGHT = 14 -- so hoch liegt das Grundstück über der Straße
LevelRoute.HOUSE_SIZE = Vector3.new(40, 26, 30) -- Wohnhaus: Breite, Höhe (bis zum First), Tiefe
LevelRoute.GARAGE_X = 29 -- Mitte der Garage (rechts neben dem Wohnhaus, von vorne gesehen links)
LevelRoute.GARAGE_SIZE = Vector3.new(18, 13, 24)

local houseFrame -- flach auf Straßenhöhe; wird einmal berechnet
do
	local center = LevelRoute.sidePoint(LevelRoute.HOUSE_S, LevelRoute.HOUSE_OFFSET, 0)
	local road = LevelRoute.sidePoint(LevelRoute.HOUSE_S, 0, 0)
	houseFrame = CFrame.lookAt(Vector3.new(center.X, 0, center.Z), Vector3.new(road.X, 0, road.Z))
end
local houseInverse = houseFrame:Inverse()

-- Abstand zum Grundstück (Haus, Garage, Veranda und Hof), 0 = darauf
function LevelRoute.distanceToHouse(x, z)
	local yard = houseInverse * Vector3.new(x, 0, z)
	local dx = math.max(math.abs(yard.X - 4) - 43, 0)
	local dz = math.max(math.abs(yard.Z + 4) - 31, 0)
	return math.sqrt(dx * dx + dz * dz)
end

-- Höhe des Geländes über der Straße: flach auf dem Grundstück, ringsum ein Hang, der
-- gleichmäßig bis zur Straße und zur Parkbucht ausläuft (dort ist alles eben).
-- `rise` ist 0 am ebenen Rand und 1 am Grundstück, dazwischen steigt es gleichmäßig an.
function LevelRoute.hillHeight(x, z)
	local yard = LevelRoute.distanceToHouse(x, z)
	if yard > 320 then
		return 0
	end
	local edge = math.min(LevelRoute.distanceToRoad(x, z) - 14, LevelRoute.distanceToLayby(x, z) - 10)
	if edge <= 0 then
		return 0
	end
	local rise = edge / (edge + yard)
	local fade = math.clamp(1 - (yard - 120) / 200, 0, 1) -- weit weg vom Haus wird es wieder flach
	return LevelRoute.HILL_HEIGHT * rise * rise * (3 - 2 * rise) * fade
end

-- Höhe, auf der Dinge stehen (Boden), an der Stelle x, z
function LevelRoute.groundY(x, z)
	return LevelRoute.GROUND_Y + LevelRoute.hillHeight(x, z)
end

local function onHill(points)
	for i, point in points do
		points[i] = Vector3.new(point.X, LevelRoute.groundY(point.X, point.Z), point.Z)
	end
	return points
end

-- CFrame des Hauses: Mitte am Boden des Grundstücks, Blick zur Straße
function LevelRoute.houseCFrame()
	return houseFrame + Vector3.new(0, LevelRoute.GROUND_Y + LevelRoute.HILL_HEIGHT, 0)
end

-- Punkt relativ zum Haus (x nach rechts, z nach hinten; die Straße liegt bei -z), auf Grundstückshöhe
function LevelRoute.housePoint(x, z)
	return (LevelRoute.houseCFrame() * CFrame.new(x, 0, z)).Position
end

-- Vor der Verandatreppe (dort endet der Waldweg)
function LevelRoute.porchPoint()
	return LevelRoute.housePoint(-2, -LevelRoute.HOUSE_SIZE.Z / 2 - 11)
end

-- Waldweg: von der Parkbucht quer durch den Wald den Hügel hinauf, links am Haus vorbei
-- bis vor die Veranda. Kontrollpunkte (geglättet wird mit `polyline`).
function LevelRoute.forestPath()
	local stop = LevelRoute.STOP_S
	local start = LevelRoute.sidePoint(stop - 4, LevelRoute.LAYBY_OFFSET + LevelRoute.LAYBY_WIDTH / 2 - 0.5, 0)
	local enter = LevelRoute.sidePoint(stop - 2, 36, 0)
	local behind = LevelRoute.housePoint(-34, 34) -- hinter dem Haus, links
	local across = (behind - enter).Unit:Cross(Vector3.yAxis)
	local points = { start, enter }
	-- durch den Wald schlängelt sich der Weg in weichen Bögen
	for i, sideways in { 7, -5, 4 } do
		table.insert(points, enter:Lerp(behind, i / 4) + across * sideways)
	end
	table.insert(points, behind)
	table.insert(points, LevelRoute.housePoint(-38, 4))
	table.insert(points, LevelRoute.housePoint(-30, -24))
	table.insert(points, LevelRoute.porchPoint())
	return onHill(points)
end

-- Einfahrt: biegt rechts von der Straße ab und windet sich den Hang hinauf bis vor die Garage
function LevelRoute.drivewayPath()
	local x = LevelRoute.GARAGE_X
	local door = -LevelRoute.GARAGE_SIZE.Z / 2
	return onHill({
		LevelRoute.sidePoint(LevelRoute.HOUSE_S - 42, 6.5, 0),
		LevelRoute.sidePoint(LevelRoute.HOUSE_S - 32, 11, 0),
		LevelRoute.housePoint(-16, -92),
		LevelRoute.housePoint(4, -72),
		LevelRoute.housePoint(20, -54),
		LevelRoute.housePoint(x - 1, door - 26),
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
	-- Blickrichtung an der Stelle s (leicht vorausschauend). Mit `pitched` neigt sie sich
	-- am Hang mit (für das Auto), sonst bleibt sie waagerecht (für Figuren).
	function line.cframeAt(s, pitched)
		local here = line.at(s)
		local ahead = line.at(s + 3)
		if (ahead - here).Magnitude < 0.05 then
			ahead = here + (here - line.at(s - 3))
		end
		return CFrame.lookAt(here, pitched and ahead or Vector3.new(ahead.X, here.Y, ahead.Z))
	end
	line.samples, line.sums = samples, sums
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
-- Aus der Parkbucht zurück auf die Spur, durch die Kehre, dann die Einfahrt hinauf
function LevelRoute.driveToHouseLine()
	local points = {}
	for s = LevelRoute.STOP_S, LevelRoute.HOUSE_S - 50, 6 do
		local t = math.clamp((s - LevelRoute.STOP_S) / 45, 0, 1)
		local smooth = t * t * (3 - 2 * t)
		local lateral = LevelRoute.LAYBY_OFFSET + (LevelRoute.LANE_OFFSET - LevelRoute.LAYBY_OFFSET) * smooth
		local point = LevelRoute.sidePoint(s, lateral, 0)
		table.insert(points, Vector3.new(point.X, LevelRoute.GROUND_Y, point.Z))
	end
	-- die Einfahrt genau auf dem Boden (Punkte alle 2,5 Studs)
	for _, point in LevelRoute.drivewaySamples() do
		table.insert(points, point)
	end
	return LevelRoute.polyline(points, 2)
end
LevelRoute.DRIVE_TOP_SPEED = 30
LevelRoute.DRIVE_ACCELERATION = 7
LevelRoute.DRIVE_BRAKE = 34
LevelRoute.DRIVE_HIDE_SARP = 220 -- ab dieser Strecke sieht man die Parkbucht nicht mehr

function LevelRoute.driveDuration()
	return LevelRoute.profileDuration(LevelRoute.driveToHouseLine().length, LevelRoute.DRIVE_TOP_SPEED, LevelRoute.DRIVE_ACCELERATION, LevelRoute.DRIVE_BRAKE)
end

------------------------------------------------------------------ Ende B: selbst durch den Wald laufen
LevelRoute.WALK_SPEED = 9 -- Laufgeschwindigkeit der Spieler (mit Shift rennen: SPRINT_SPEED)
LevelRoute.SPRINT_SPEED = 15
LevelRoute.SARP_WALK_SPEED = 6 -- Sarp geht gleichmäßig und wartet nicht
LevelRoute.SARP_START_DELAY = 3 -- so lange nach dem Aussteigen, bis Sarp losgeht
LevelRoute.ARRIVE_DISTANCE = 14 -- so nah an der Veranda gilt man als angekommen

-- Geglättete Punkte des Waldwegs, jeder genau auf dem Boden (zum Bauen und Laufen)
local pathSamples = {}
do
	local flatLine = LevelRoute.polyline(LevelRoute.forestPath(), 1)
	for s = 0, flatLine.length, 2.5 do
		table.insert(pathSamples, flatLine.at(s))
	end
	table.insert(pathSamples, flatLine.at(flatLine.length))
	onHill(pathSamples)
end

function LevelRoute.forestPathSamples()
	return pathSamples
end

-- Wo die Spieler nach dem Aussteigen stehen (neben dem Auto, Blick zum Waldweg)
function LevelRoute.walkerSpawn(index)
	local car = LevelRoute.carCFrame(LevelRoute.STOP_S)
	local spot = (car * CFrame.new(5.2, 0, (index == 1) and -1.5 or 2)).Position
	local target = pathSamples[3]
	spot = Vector3.new(spot.X, LevelRoute.GROUND_Y, spot.Z)
	return CFrame.lookAt(spot, Vector3.new(target.X, spot.Y, target.Z))
end

-- Sarps Weg: vom Fenster über den Waldweg bis vor die Veranda
function LevelRoute.walkLine()
	local points = { LevelRoute.windowPoint() }
	for _, point in pathSamples do
		table.insert(points, point)
	end
	return LevelRoute.polyline(points, 1)
end

-- Wie weit jemand auf dem Weg ist (Studs) und wie weit er vom Weg entfernt steht
local walkLineCache
function LevelRoute.walkProgress(position)
	walkLineCache = walkLineCache or LevelRoute.walkLine()
	local samples, sums = walkLineCache.samples, walkLineCache.sums
	local bestS, bestDistance = 0, math.huge
	for i = 1, #samples, 2 do
		local sample = samples[i]
		local dx, dz = sample.X - position.X, sample.Z - position.Z
		local distance = dx * dx + dz * dz
		if distance < bestDistance then
			bestS, bestDistance = sums[i], distance
		end
	end
	return bestS, math.sqrt(bestDistance)
end

-- Sarps Abgang: von der Veranda seitlich am Haus vorbei in den Wald
function LevelRoute.leaveLine()
	return LevelRoute.polyline(onHill({
		LevelRoute.porchPoint(),
		LevelRoute.housePoint(-26, -30),
		LevelRoute.housePoint(-50, -36),
		LevelRoute.housePoint(-72, -30),
		LevelRoute.housePoint(-95, -20),
	}), 1)
end

------------------------------------------------------------------ Abstände zu Weg und Einfahrt
local drivewaySamples = {}
do
	local line = LevelRoute.polyline(LevelRoute.drivewayPath(), 1)
	for s = 0, line.length, 2.5 do
		table.insert(drivewaySamples, line.at(s))
	end
	table.insert(drivewaySamples, line.at(line.length))
	onHill(drivewaySamples)
end

function LevelRoute.drivewaySamples()
	return drivewaySamples
end

function LevelRoute.distanceToDriveway(x, z)
	return distanceToPolyline(x, z, drivewaySamples)
end

function LevelRoute.distanceToPath(x, z)
	return distanceToPolyline(x, z, pathSamples)
end

return LevelRoute
