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
	Vector3.new(55, 0, -1650),
	Vector3.new(20, 0, -1850),
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

-- Waldweg, der von der Parkbucht in den Wald führt (von der Bucht nach innen)
function LevelRoute.forestPath()
	local s = LevelRoute.STOP_S - 4
	return {
		LevelRoute.sidePoint(s, LevelRoute.LAYBY_OFFSET + LevelRoute.LAYBY_WIDTH / 2 - 0.5, 0),
		LevelRoute.sidePoint(s, 34, 4),
		LevelRoute.sidePoint(s, 52, -5),
		LevelRoute.sidePoint(s, 72, 2),
	}
end

-- Der Fremde startet tief im Wald und läuft den Weg entlang bis ans Beifahrerfenster
function LevelRoute.strangerWaypoints()
	local path = LevelRoute.forestPath()
	local window = (LevelRoute.carCFrame(LevelRoute.STOP_S) * CFrame.new(7.2, 0, 0.6)).Position
	local waypoints = {}
	for i = #path, 1, -1 do
		table.insert(waypoints, Vector3.new(path[i].X, LevelRoute.GROUND_Y, path[i].Z))
	end
	table.insert(waypoints, Vector3.new(window.X, LevelRoute.GROUND_Y, window.Z))
	return waypoints
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

function LevelRoute.distanceToPath(x, z)
	return distanceToPolyline(x, z, LevelRoute.forestPath())
end

return LevelRoute
