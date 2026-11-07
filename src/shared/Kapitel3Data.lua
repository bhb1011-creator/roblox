-- Kapitel 3: Zeiten und Wege, die Server und Client gleich kennen müssen.
-- (Der Server gibt den Takt vor, der Client spielt passend dazu die Animationen ab.)
local Kapitel3Data = {}

-- Kapitelkarte ("KAPITEL 3"), danach beginnt die Sequenz im Ritualraum
Kapitel3Data.CARD = 8.2

-- Ritualraum: Einleitung (Puppen, Flüstern, Stille, Sarp im Eingang) bis zum ersten Event
Kapitel3Data.INTRO = 21.5

-- Die drei Quick-Time-Events (der Reihe nach), jeweils EIN Tastendruck. windup = Sarp holt
-- aus, window = so lange hat man Zeit, outcome = so lange dauert danach die Animation.
Kapitel3Data.ORDER = { "dodge", "struggle", "timing" }
Kapitel3Data.QTE = {
	dodge = { windup = 1.0, window = 1.25, outcome = 2.4 }, -- Pfeil: A oder D
	struggle = { windup = 1.2, window = 1.6, taps = 1, outcome = 2.7 }, -- E drücken
	timing = { windup = 1.6, window = 1.8, outcome = 3.4 }, -- Kreis schrumpft: Leertaste
}
Kapitel3Data.MAX_MISSES = 1 -- so viele Events darf man verpassen (beim zweiten: Game Over)

-- Danach: Sarp brennt, die Familie bricht zusammen, man rennt in den Tunnel
Kapitel3Data.FLEE = 7.6

-- Die Flucht durch den Wald
Kapitel3Data.RUN_SPEED = 17
Kapitel3Data.TRANSFORM_AT = 0.42 -- so weit (Anteil des Wegs), dann verwandelt er sich
Kapitel3Data.TRANSFORM_TIME = 6.8 -- so lange schaut man zurück (man bleibt stehen)
-- Am Ende: alle sind über die Brücke (BRIDGE_CLEAR Studs dahinter), man dreht sich um, das
-- Biest ist auf der Brücke – nach BRIDGE_BREAK Sekunden stürzt sie ein, nach BRIDGE_SCENE schwarz
Kapitel3Data.BRIDGE_CLEAR = 6
Kapitel3Data.BRIDGE_BREAK = 1.3
Kapitel3Data.BRIDGE_SCENE = 4.6
-- Wer zu langsam ist, wird erwischt: Sarp/das Biest laufen etwas langsamer als man selbst
-- und bleiben höchstens MAX_GAP Studs zurück. Bleibt man stehen, ist er in gut einer
-- Sekunde da; wer durchläuft, ist sicher.
Kapitel3Data.SARP_SPEED = 10.5
Kapitel3Data.BEAST_SPEED = 11.5
Kapitel3Data.MAX_GAP = 14
Kapitel3Data.CATCH_GAP = 2.4
Kapitel3Data.RUN_MAX_TIME = 120 -- Sicherheitsnetz (Sekunden)

-- Was auf dem Weg passiert (s = Strecke ab der Luke in Studs; die Verwandlung ist bei
-- etwa 305, die Brücke beginnt bei 637). "beast" = erst nach der Verwandlung.
--   jump  = umgestürzter Baum quer über dem Weg: LEERTASTE (sonst stolpert man)
--   duck  = tiefer Stamm auf Kopfhöhe: C (sonst stößt man sich den Kopf)
--   mud   = Schlamm: man wird langsamer        creek = Bach: noch langsamer
--   tree  = das Biest rammt einen Baum, der hinter einem auf den Weg kracht
--   side  = Angriff aus dem Gebüsch (vorher wird es still): A oder D
Kapitel3Data.OBSTACLES = {
	{ kind = "jump", s = 125 },
	{ kind = "duck", s = 195 },
	{ kind = "mud", from = 236, to = 270 },
	{ kind = "creek", s = 392, length = 12 },
	{ kind = "jump", s = 420 },
	{ kind = "tree", s = 470, beast = true },
	{ kind = "duck", s = 502 },
	{ kind = "side", s = 548, beast = true },
	{ kind = "jump", s = 582 },
}
Kapitel3Data.PROMPT_DISTANCE = 11 -- so weit vorher erscheint "LEERTASTE" / "C"
Kapitel3Data.STUMBLE_TIME = 0.75 -- verpasst: so lange kommt man kaum vorwärts
Kapitel3Data.MUD_SPEED = 11.5
Kapitel3Data.CREEK_SPEED = 10
Kapitel3Data.SIDE_SILENCE = 30 -- so viele Studs vor dem Angriff wird es still
Kapitel3Data.SIDE_WINDOW = 1.15 -- so lange hat man Zeit zum Ausweichen
Kapitel3Data.TREE_BLOCK = 1.5 -- so lange hält der umgestürzte Baum das Biest auf

-- Das Ende in Sarps Hütte
Kapitel3Data.PHONE_NUMBER = "911" -- steht auf dem Zettel neben dem Telefon
Kapitel3Data.PHONE_RING = 4.2 -- so lange klingelt es, bis die Polizei abnimmt
-- Halluzinationen (Spiegel, Foto): so nah und so genau muss man hinschauen
Kapitel3Data.SCARE_MIRROR_RANGE = 11
Kapitel3Data.SCARE_PHOTO_RANGE = 7
-- Schlussszene (Sekunden nach "Ausruhen"): schwarz, "Etwas später …", Blaulicht und
-- Klopfen, Antwort, draußen: das Auto fährt weg, schwarz, "ENDE"
Kapitel3Data.END_LATER = 2.4
Kapitel3Data.END_INSIDE = 6
Kapitel3Data.END_KNOCK = 7.6
Kapitel3Data.END_ANSWER = 11
Kapitel3Data.END_OUTSIDE = 14.2
Kapitel3Data.END_DRIVE = 17
Kapitel3Data.END_FADE = 24
Kapitel3Data.END_TITLE = 26.5

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
