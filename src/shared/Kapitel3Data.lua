-- Kapitel 3: Zeiten und Wege, die Server und Client gleich kennen müssen.
-- (Der Server gibt den Takt vor, der Client spielt passend dazu die Animationen ab.)
local Kapitel3Data = {}

-- Kapitelkarte ("KAPITEL 3"), danach beginnt die Sequenz im Ritualraum
Kapitel3Data.CARD = 8.2

-- Ritualraum: Einleitung (Puppen, Flüstern, Stille, Sarp im Eingang) bis zum ersten Event
Kapitel3Data.INTRO = 19.5

-- Die drei Quick-Time-Events (der Reihe nach). windup = Sarp holt aus, window = so lange
-- hat man Zeit, outcome = so lange dauert danach die Animation (Treffer oder Ausweichen).
Kapitel3Data.ORDER = { "dodge", "struggle", "timing" }
Kapitel3Data.QTE = {
	dodge = { windup = 1.0, window = 1.25, outcome = 2.4 }, -- Pfeil: A oder D
	struggle = { windup = 1.2, window = 3.8, taps = 12, outcome = 2.7 }, -- E schnell drücken
	timing = { windup = 1.6, window = 1.8, outcome = 3.4 }, -- Kreis schrumpft: Leertaste
}
Kapitel3Data.MAX_MISSES = 1 -- so viele Events darf man verpassen (beim zweiten: Game Over)

-- Danach: Sarp brennt, die Familie bricht zusammen, man rennt in den Tunnel
Kapitel3Data.FLEE = 7.6

-- Die Flucht durch den Wald
Kapitel3Data.RUN_SPEED = 17
Kapitel3Data.TRANSFORM_AT = 0.42 -- so weit (Anteil des Wegs), dann verwandelt er sich
Kapitel3Data.TRANSFORM_TIME = 6.8 -- so lange schaut man zurück (man bleibt stehen)
Kapitel3Data.END_MARGIN = 28 -- so weit vor dem Ende des Wegs wird es schwarz
Kapitel3Data.RUN_MAX_TIME = 70 -- Sicherheitsnetz (Sekunden)

-- Wo auf dem Weg (Liste von Punkten) steht `position`? Gibt die Strecke ab dem Anfang
-- zurück, den seitlichen Abstand und die Länge des ganzen Wegs.
function Kapitel3Data.progress(points, position)
	local best, bestDistance, total = 0, math.huge, 0
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local length = ab.Magnitude
		local ap = Vector3.new(position.X - a.X, 0, position.Z - a.Z)
		local u = length > 0 and math.clamp(ap:Dot(ab) / (length * length), 0, 1) or 0
		local closest = Vector3.new(a.X, 0, a.Z) + ab * u
		local distance = (Vector3.new(position.X, 0, position.Z) - closest).Magnitude
		if distance < bestDistance then
			best, bestDistance = total + u * length, distance
		end
		total += length
	end
	return best, bestDistance, total
end

-- Punkt und Richtung bei Strecke `s` auf dem Weg
function Kapitel3Data.pointAt(points, s)
	local walked = 0
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local length = (b - a).Magnitude
		if s <= walked + length or i == #points - 1 then
			local u = length > 0 and math.clamp((s - walked) / length, 0, 1) or 0
			local direction = length > 0 and (b - a).Unit or Vector3.new(0, 0, -1)
			return a:Lerp(b, u), direction
		end
		walked += length
	end
	return points[1], Vector3.new(0, 0, -1)
end

return Kapitel3Data
