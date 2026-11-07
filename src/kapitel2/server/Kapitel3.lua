-- Kapitel 3: beginnt, sobald jemand die alte Tür hinter dem Regal öffnet (Escape.lua).
--
--  1. Schwarz, "KAPITEL 3". Man steht danach in einem großen, runden Ritualsaal (eigener
--     Ort, weit weg vom Haus – man wird dorthin gebracht, während das Bild schwarz ist).
--  2. Die Familie und Richard stehen starr wie Puppen im Kreis. Sie flüstern, dann Stille,
--     die Köpfe rucken herum, die Kerzen flackern – Sarp steht im Eingang.
--  3. Sarp greift dreimal an (Quick-Time-Events, jeweils EIN Tastendruck): ausweichen (A/D),
--     losreißen (E), im richtigen Moment den Kerzenständer umstoßen (Leertaste). Eins darf man
--     verpassen, beim zweiten: Game Over (danach beginnt die Sequenz von vorne).
--  4. Sarp brennt, die Familie bricht zusammen wie Puppen ohne Fäden, man rennt in den Tunnel.
--  5. Raus aus der Luke in den Wald: ein breiter Waldweg, Sarp hinterher. Wer stehen bleibt
--     oder hängen bleibt, wird erwischt (Game Over, die Flucht beginnt von vorne). Nach
--     knapp der Hälfte dreht man sich um: Sarp verwandelt sich in das Biest (Stufe 3) und
--     kommt auf allen Vieren hinterher.
--  6. Am Ende: eine Schlucht mit einer Hängebrücke. Man rennt hinüber, das Biest hinterher –
--     unter ihm stürzt die Brücke ein, es fällt in die Schlucht (erst mal weg). Schwarz
--     (hier kommt später das Ende).
--
-- Der Server gibt nur den Takt vor; Kamera, Animationen und Anzeigen macht der Client
-- (Kapitel3.lua im Client-Ordner). Die Zeiten stehen in Shared/Kapitel3Data.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Shared.Kapitel3Data)
local Script = require(ReplicatedStorage.Shared.Kapitel2Dialogue)
local Forest = require(ReplicatedStorage.Shared.Forest)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Wagners = require(script.Parent.Wagners)
local SarpHut = require(script.Parent.SarpHut)
local ForestDressing = require(script.Parent.ForestDressing)

local Kapitel3 = {}

Kapitel3.TITLE = "Das Ritual" -- Untertitel der Kapitelkarte (hier ändern)

local M = Enum.Material

local function block(parent, name, size, cframe, color, material, extra)
	local props = { Name = name, Size = size, CFrame = cframe, Color = color, Material = material or M.SmoothPlastic, Parent = parent }
	for key, value in extra or {} do
		props[key] = value
	end
	return Parts.new("Part", props)
end

local function ball(parent, name, diameter, position, color, material)
	return block(parent, name, Vector3.new(diameter, diameter, diameter), CFrame.new(position), color, material, { Shape = Enum.PartType.Ball, CanCollide = false })
end

local function column(parent, name, height, diameter, base, color, material, extra)
	local props = { Name = name, Color = color, Material = material or M.SmoothPlastic, Parent = parent }
	for key, value in extra or {} do
		props[key] = value
	end
	return Parts.column(props, height, diameter, base)
end

------------------------------------------------------------------ Der Ritualsaal
-- Rund, groß, hohe Decke. Der Eingang (von der Tür hinter dem Regal) liegt im Süden (+Z),
-- der Tunnel nach draußen im Westen (-X). In der Mitte der Kerzenkreis mit der Familie.
local HALL_CENTER = Vector3.new(2900, 0, 0)
local HALL_RADIUS, HALL_HEIGHT = 22, 16
local hall -- Ordner mit allem (die Kerzenlichter heißen "HallCandle")

local function H(x, z, y)
	return HALL_CENTER + Vector3.new(x, y or 0, z)
end

local function buildHall()
	local folder = Instance.new("Folder")
	folder.Name = "Kapitel3Hall"
	folder.Parent = workspace
	local STONE = Color3.fromRGB(56, 52, 50)
	local DARK = Color3.fromRGB(34, 31, 30)
	local WOOD = Color3.fromRGB(70, 52, 36)
	local BLOOD = Color3.fromRGB(110, 16, 14)
	local size = HALL_RADIUS * 2 + 8
	block(folder, "HallFloor", Vector3.new(size, 1, size), CFrame.new(H(0, 0, -0.5)), Color3.fromRGB(42, 39, 37), M.Slate)
	block(folder, "HallCeiling", Vector3.new(size, 1.2, size), CFrame.new(H(0, 0, HALL_HEIGHT + 0.6)), DARK, M.Slate)
	-- runde Wand aus 48 Stücken; Eingang (Süden) und Tunnel (Westen) offen, darüber ein Sturz
	local pieces = 48
	local width = 2 * HALL_RADIUS * math.sin(math.pi / pieces) + 0.5
	for i = 0, pieces - 1 do
		local angle = (i + 0.5) / pieces * math.pi * 2
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local center = HALL_CENTER + direction * (HALL_RADIUS + 1)
		local frame = CFrame.lookAt(center, center - direction)
		local degrees = math.deg(angle)
		local opening = math.abs(degrees - 90) < 7 or math.abs(degrees - 180) < 7
		if opening then
			block(folder, "HallLintel", Vector3.new(width, HALL_HEIGHT - 9, 2), frame + Vector3.new(0, 9 + (HALL_HEIGHT - 9) / 2, 0), STONE, M.Cobblestone)
		else
			block(folder, "HallWall", Vector3.new(width, HALL_HEIGHT, 2), frame + Vector3.new(0, HALL_HEIGHT / 2, 0), STONE, M.Cobblestone)
		end
		-- Fotos früherer Gäste an der Wand (rot durchgestrichen)
		if not opening and i % 4 == 2 then
			local at = HALL_CENTER + direction * (HALL_RADIUS - 0.05) + Vector3.new(0, 6.2, 0)
			local look = CFrame.lookAt(at, at - direction)
			block(folder, "GuestPhoto", Vector3.new(1.2, 1.6, 0.06), look, Color3.fromRGB(160, 150, 130), M.SmoothPlastic, { CanCollide = false })
			block(folder, "PhotoCross", Vector3.new(1.3, 0.1, 0.02), look * CFrame.new(0, 0, -0.05) * CFrame.Angles(0, 0, math.rad(40)), BLOOD, M.SmoothPlastic, { CanCollide = false })
		end
	end
	-- Säulen
	for k = 0, 7 do
		local angle = math.rad(22.5 + k * 45)
		local base = H(math.cos(angle) * 17, math.sin(angle) * 17)
		block(folder, "Pillar", Vector3.new(2.6, HALL_HEIGHT, 2.6), CFrame.new(base + Vector3.new(0, HALL_HEIGHT / 2, 0)), STONE, M.Cobblestone)
		block(folder, "PillarBase", Vector3.new(3.4, 1, 3.4), CFrame.new(base + Vector3.new(0, 0.5, 0)), DARK, M.Slate)
		block(folder, "PillarTop", Vector3.new(3.4, 1, 3.4), CFrame.new(base + Vector3.new(0, HALL_HEIGHT - 0.5, 0)), DARK, M.Slate)
		-- Ketten hängen von der Decke
		local chain = base + Vector3.new(-math.cos(angle) * 3, 0, -math.sin(angle) * 3)
		block(folder, "Chain", Vector3.new(0.15, 5, 0.15), CFrame.new(chain + Vector3.new(0, HALL_HEIGHT - 2.5, 0)), Color3.fromRGB(40, 40, 42), M.Metal, { CanCollide = false })
	end
	-- Kerzenkreis mit Zeichen auf dem Boden
	local rng = Random.new(7)
	for i = 0, 11 do
		local angle = i / 12 * math.pi * 2
		local base = H(math.cos(angle) * 7.5, math.sin(angle) * 7.5)
		local height = rng:NextNumber(1.4, 2.8)
		column(folder, "HallCandleWax", height, 0.45, CFrame.new(base), Color3.fromRGB(210, 196, 170), M.SmoothPlastic, { CanCollide = false })
		local flame = ball(folder, "HallCandleFlame", 0.28, base + Vector3.new(0, height + 0.2, 0), Color3.fromRGB(255, 150, 70), M.Neon)
		local light = Instance.new("PointLight")
		light.Name = "HallCandle"
		light.Color = Color3.fromRGB(255, 130, 70)
		light.Range = 16
		light.Brightness = 1.2
		light.Shadows = true
		light.Parent = flame
	end
	local function floorLine(a, b, thickness)
		local length = (b - a).Magnitude
		block(folder, "Sigil", Vector3.new(thickness, 0.04, length), CFrame.lookAt((a + b) / 2, b) + Vector3.new(0, 0.02, 0), BLOOD, M.SmoothPlastic, { CanCollide = false })
	end
	for _, radius in { 8.3, 5.2 } do
		for i = 0, 23 do
			local a1, a2 = i / 24 * math.pi * 2, (i + 1) / 24 * math.pi * 2
			floorLine(H(math.cos(a1) * radius, math.sin(a1) * radius), H(math.cos(a2) * radius, math.sin(a2) * radius), 0.22)
		end
	end
	for i = 0, 4 do
		local a1 = i / 5 * math.pi * 2 - math.pi / 2
		local a2 = (i + 2) / 5 * math.pi * 2 - math.pi / 2
		floorLine(H(math.cos(a1) * 8, math.sin(a1) * 8), H(math.cos(a2) * 8, math.sin(a2) * 8), 0.18)
	end
	-- Altar im Norden
	block(folder, "Altar", Vector3.new(7, 3, 3), CFrame.new(H(0, -12.5, 1.5)), DARK, M.Slate)
	block(folder, "AltarCloth", Vector3.new(7.2, 0.1, 2.2), CFrame.new(H(0, -12.5, 3.05)), BLOOD, M.Fabric)
	ball(folder, "Skull", 0.9, H(0, -12.5, 3.5), Color3.fromRGB(215, 205, 185), M.SmoothPlastic)
	for _, x in { -2.8, 2.8 } do
		column(folder, "AltarCandle", 2.2, 0.4, CFrame.new(H(x, -12.5, 3.05)), Color3.fromRGB(110, 20, 18), M.SmoothPlastic, { CanCollide = false })
		local flame = ball(folder, "HallCandleFlame", 0.26, H(x, -12.5, 5.45), Color3.fromRGB(255, 70, 40), M.Neon)
		local light = Instance.new("PointLight")
		light.Name = "HallCandle"
		light.Color = Color3.fromRGB(255, 60, 40)
		light.Range = 14
		light.Brightness = 1.3
		light.Parent = flame
	end
	-- großer roter Kreis an der Wand hinter dem Altar
	for i = 0, 15 do
		local a1, a2 = i / 16 * math.pi * 2, (i + 1) / 16 * math.pi * 2
		local p1 = H(math.cos(a1) * 3.2, -HALL_RADIUS + 0.4, 9 + math.sin(a1) * 3.2)
		local p2 = H(math.cos(a2) * 3.2, -HALL_RADIUS + 0.4, 9 + math.sin(a2) * 3.2)
		block(folder, "WallSigil", Vector3.new(0.3, (p2 - p1).Magnitude + 0.1, 0.05), CFrame.lookAt((p1 + p2) / 2, (p1 + p2) / 2 + Vector3.new(0, 0, 1)) * CFrame.Angles(0, 0, math.atan2(p2.X - p1.X, p2.Y - p1.Y)), BLOOD, M.SmoothPlastic, { CanCollide = false })
	end
	-- Feuerschalen: am Eingang und neben dem Altar
	for _, at in { H(-5, 18.5), H(5, 18.5), H(-6, -12), H(6, -12) } do
		column(folder, "BrazierStand", 3, 0.5, CFrame.new(at), Color3.fromRGB(40, 38, 38), M.Metal)
		column(folder, "BrazierBowl", 0.8, 2, CFrame.new(at + Vector3.new(0, 3, 0)), Color3.fromRGB(45, 42, 40), M.Metal)
		local coals = ball(folder, "HallCandleFlame", 1.3, at + Vector3.new(0, 3.9, 0), Color3.fromRGB(255, 110, 40), M.Neon)
		local fire = Instance.new("Fire")
		fire.Size = 4
		fire.Heat = 8
		fire.Color = Color3.fromRGB(255, 130, 50)
		fire.SecondaryColor = Color3.fromRGB(180, 40, 10)
		fire.Parent = coals
		local light = Instance.new("PointLight")
		light.Name = "HallCandle"
		light.Color = Color3.fromRGB(255, 120, 50)
		light.Range = 22
		light.Brightness = 1.6
		light.Shadows = true
		light.Parent = coals
	end
	-- Eingangsgang (Süden): hier kommt man her, hier steht nachher Sarp
	block(folder, "HallwayFloor", Vector3.new(6, 1, 13), CFrame.new(H(0, 32.5, -0.5)), Color3.fromRGB(42, 39, 37), M.Slate)
	block(folder, "HallwayCeiling", Vector3.new(8, 1, 16), CFrame.new(H(0, 30, 9.5)), DARK, M.Slate)
	for _, x in { -3.5, 3.5 } do
		block(folder, "HallwayWall", Vector3.new(1, 9, 16), CFrame.new(H(x, 30, 4.5)), STONE, M.Cobblestone)
	end
	for step = 0, 4 do
		block(folder, "HallwayStep", Vector3.new(6, 0.6 + step * 0.6, 1.2), CFrame.new(H(0, 33 + step * 1.2, (0.6 + step * 0.6) / 2)), DARK, M.Slate)
	end
	block(folder, "HallwayEnd", Vector3.new(6, 9, 1), CFrame.new(H(0, 39, 4.5)), STONE, M.Cobblestone)
	block(folder, "OldDoor", Vector3.new(3, 5.5, 0.3), CFrame.new(H(-1.2, 38.3, 5.9)) * CFrame.Angles(0, math.rad(-70), 0), Color3.fromRGB(46, 34, 26), M.WoodPlanks)
	-- Tunnel nach draußen (Westen): Holzstützen, Erde
	block(folder, "TunnelFloor", Vector3.new(22, 1, 6), CFrame.new(H(-37, 0, -0.5)), Color3.fromRGB(66, 52, 38), M.Ground)
	block(folder, "TunnelCeiling", Vector3.new(26, 1, 8), CFrame.new(H(-35, 0, 8.5)), Color3.fromRGB(50, 40, 30), M.Ground)
	for _, z in { -3.5, 3.5 } do
		block(folder, "TunnelWall", Vector3.new(26, 8, 1), CFrame.new(H(-35, z, 4)), Color3.fromRGB(58, 46, 34), M.Ground)
	end
	for x = -25, -47, -5 do
		for _, z in { -2.6, 2.6 } do
			block(folder, "TunnelPost", Vector3.new(0.5, 8, 0.5), CFrame.new(H(x, z, 4)), WOOD, M.Wood)
		end
		block(folder, "TunnelBeam", Vector3.new(0.62, 0.5, 5.8), CFrame.new(H(x, 0, 7.7)), WOOD, M.Wood)
	end
	block(folder, "TunnelEnd", Vector3.new(1, 8, 6), CFrame.new(H(-48, 0, 4)), Color3.fromRGB(30, 24, 20), M.Ground)
	hall = folder
	return folder
end

------------------------------------------------------------------ Der Waldweg mit der Schlucht
-- Weit weg von allem anderen (man kommt durch die Luke am Ende des Tunnels dorthin).
local FOREST_ORIGIN = Vector3.new(2600, 0, 0)
-- der Weg (x, z relativ zu FOREST_ORIGIN): kurvig, damit man nie weit sieht; am Ende über
-- die Schlucht (Brücke von Punkt BRIDGE bis BRIDGE + 1)
local FOREST_PATH = {
	{ 0, 0 },
	{ 0, -70 },
	{ 22, -140 },
	{ 4, -215 },
	{ -28, -280 },
	{ -20, -355 },
	{ 14, -425 },
	{ 8, -500 },
	{ -16, -570 },
	{ -14, -612 },
	{ -14, -652 },
	{ -14, -700 },
	-- nach der Schlucht: um eine Kurve bis zur Straße vor Sarps Hütte
	{ -6, -738 },
	{ 16, -764 },
	{ 46, -778 },
}
local CHASE_END = 12 -- bis hierher geht die Verfolgung (danach nur noch der Weg zur Hütte)
local BRIDGE = 10 -- die Brücke geht von FOREST_PATH[10] bis FOREST_PATH[11]
local PATH_HALF_WIDTH = 9.5 -- unsichtbare Wände links und rechts (breiter Weg)
local BRIDGE_HALF_WIDTH = 2.9

local forestReady = false
local forestPoints -- Weltpunkte des Wegs
local forestStart -- wo man aus der Luke steigt
local bridgeStart, bridgeLength -- Strecke bis zum Anfang der Brücke, Länge der Brücke
local bridge -- { parts, floor }
local chaseTotal -- Länge des Wegs bis zum Ende der Verfolgung
local hut -- Sarps Hütte (siehe SarpHut.lua)
local roadFrame -- Ende des Wegs an der Straße (Blick zur Hütte = -Z)

local function buildForest()
	local folder = Instance.new("Folder")
	folder.Name = "Kapitel3Forest"
	folder.Parent = workspace
	local terrain = workspace.Terrain
	local points = {}
	for _, p in FOREST_PATH do
		table.insert(points, FOREST_ORIGIN + Vector3.new(p[1], 0, p[2]))
	end
	forestPoints = points
	local s = 0
	for i = 1, BRIDGE - 1 do
		s += (points[i + 1] - points[i]).Magnitude
	end
	bridgeStart = s
	chaseTotal = 0
	for i = 1, CHASE_END - 1 do
		chaseTotal += (points[i + 1] - points[i]).Magnitude
	end
	local lastDirection = Vector3.new(points[#points].X - points[#points - 1].X, 0, points[#points].Z - points[#points - 1].Z).Unit
	roadFrame = CFrame.lookAt(points[#points], points[#points] + lastDirection)
	-- die Lichtung mit der Hütte (im Rahmen des Wegendes)
	local function inClearing(position, margin)
		local p = roadFrame:PointToObjectSpace(position)
		margin = margin or 0
		local onRoad = math.abs(p.Z - SarpHut.ROAD_Z) < SarpHut.ROAD_HALF + 3 + margin
		return (math.abs(p.X) < 30 + margin and p.Z < 4 + margin and p.Z > -48 - margin) or onRoad
	end
	bridgeLength = (points[BRIDGE + 1] - points[BRIDGE]).Magnitude
	local bridgeA, bridgeB = points[BRIDGE], points[BRIDGE + 1]
	local bridgeDirection = (bridgeB - bridgeA).Unit
	local ravineCenter = (bridgeA + bridgeB) / 2
	local ravineFrame = CFrame.lookAt(ravineCenter, ravineCenter + bridgeDirection)
	local function nearRavine(position, margin)
		local relative = ravineFrame:PointToObjectSpace(position)
		return math.abs(relative.Z) < bridgeLength / 2 + margin
	end

	-- Boden: Gras, darauf ein breiter, erdiger Weg; darüber nichts (Luft)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local frame = CFrame.lookAt((a + b) / 2, b)
		local length = (b - a).Magnitude
		terrain:FillBlock(frame * CFrame.new(0, -4, 0), Vector3.new(140, 8, length + 140), Enum.Material.LeafyGrass)
		terrain:FillBlock(frame * CFrame.new(0, 14, 0), Vector3.new(140, 28, length + 140), Enum.Material.Air)
		task.wait()
	end
	for i = 1, #points - 1 do
		if i ~= BRIDGE then
			local a, b = points[i], points[i + 1]
			local frame = CFrame.lookAt((a + b) / 2, b)
			terrain:FillBlock(frame * CFrame.new(0, -3.9, 0), Vector3.new(10, 8, (b - a).Magnitude + 8), Enum.Material.Ground)
		end
	end
	-- Schlamm und Bach auf dem Weg (Kapitel3Data.OBSTACLES); was dort zu sehen ist, baut der Client
	for _, obstacle in Data.OBSTACLES do
		local from, to, width = obstacle.from, obstacle.to, 11
		if obstacle.kind == "creek" then
			from, to, width = obstacle.s - obstacle.length / 2 - 3, obstacle.s + obstacle.length / 2 + 3, 30
		end
		if from and to then
			local at = from
			while at <= to do
				local center, direction = Data.pointAt(points, at)
				terrain:FillBlock(CFrame.lookAt(center, center + Vector3.new(direction.X, 0, direction.Z)) * CFrame.new(0, -4, 0), Vector3.new(width, 8, 4.5), Enum.Material.Mud)
				at += 3
			end
		end
	end
	-- Die Schlucht: tief, unten schmaler (V-förmig), die Wände unregelmäßig – Vorsprünge
	-- aus verschiedenem Fels, Höhlen, Moos, ein zerklüfteter Rand; unten ein Fluss mit
	-- Geröll, darüber Nebel. (In der Mitte unter der Brücke bleibt Platz zum Fallen.)
	terrain:FillBlock(ravineFrame * CFrame.new(0, -60, 0), Vector3.new(280, 120, bridgeLength + 70), Enum.Material.Slate)
	local RAVINE_DEPTH = 112
	local function ravineWidth(depth)
		return (bridgeLength - 4) * (1 - math.clamp(depth / RAVINE_DEPTH, 0, 1) * 0.5)
	end
	for depth = 0, RAVINE_DEPTH, 4 do
		terrain:FillBlock(ravineFrame * CFrame.new(0, -depth - 2, 0), Vector3.new(340, 4.4, ravineWidth(depth)), Enum.Material.Air)
	end
	task.wait()
	terrain:FillBlock(ravineFrame * CFrame.new(0, -RAVINE_DEPTH + 2, 0), Vector3.new(340, 6, ravineWidth(RAVINE_DEPTH) + 2), Enum.Material.Water)
	do
		local rocks = Random.new(23)
		local materials = { Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Basalt, Enum.Material.Rock, Enum.Material.Limestone }
		local count = 0
		for _, side in { -1, 1 } do
			for x = -150, 150, 6 do
				-- zerklüfteter Rand oben (nicht am Weg und an der Brücke)
				if math.abs(x) > 14 and rocks:NextNumber() < 0.6 then
					terrain:FillBall(ravineFrame * Vector3.new(x + rocks:NextNumber(-2, 2), -1, side * (ravineWidth(0) / 2 + rocks:NextNumber(0, 1.5))), rocks:NextNumber(2, 3.6), Enum.Material.Air)
				end
				for depth = 3, RAVINE_DEPTH - 6, 7 do
					local wall = side * ravineWidth(depth) / 2
					local px = x + rocks:NextNumber(-3, 3)
					local py = -depth + rocks:NextNumber(-3, 3)
					local roll = rocks:NextNumber()
					if roll < 0.5 and math.abs(px) > 10 then
						-- Vorsprung (ragt in die Schlucht), manchmal mit Moos obendrauf
						local radius = rocks:NextNumber(2.5, 7)
						local center = ravineFrame * Vector3.new(px, py, wall - side * rocks:NextNumber(0, radius * 0.55))
						terrain:FillBall(center, radius, materials[rocks:NextInteger(1, #materials)])
						if rocks:NextNumber() < 0.2 then
							terrain:FillBall(center + Vector3.new(0, radius * 0.75, 0), radius * 0.45, Enum.Material.Grass)
						end
					elseif roll < 0.72 and depth > 10 then
						-- Höhle / Nische in der Wand
						terrain:FillBall(ravineFrame * Vector3.new(px, py, wall + side * rocks:NextNumber(0.5, 2)), rocks:NextNumber(2, 5), Enum.Material.Air)
					end
					count += 1
					if count % 30 == 0 then
						task.wait()
					end
				end
				-- Geröll unten am Fluss
				if rocks:NextNumber() < 0.5 then
					terrain:FillBall(ravineFrame * Vector3.new(x + rocks:NextNumber(-3, 3), -RAVINE_DEPTH + 3, side * (ravineWidth(RAVINE_DEPTH) / 2 - rocks:NextNumber(0, 2))), rocks:NextNumber(1.5, 3.5), Enum.Material.Rock)
				end
			end
		end
		-- Nebel tief in der Schlucht
		local mist = Parts.new("Part", { Name = "RavineMist", Size = Vector3.new(260, 24, ravineWidth(75)), CFrame = ravineFrame * CFrame.new(0, -75, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = folder })
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(150, 158, 170))
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.75), NumberSequenceKeypoint.new(1, 1) })
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 18) })
		emitter.Lifetime = NumberRange.new(10, 16)
		emitter.Rate = 6
		emitter.Speed = NumberRange.new(0.5, 1.5)
		emitter.SpreadAngle = Vector2.new(180, 20)
		emitter.Shape = Enum.ParticleEmitterShape.Box
		emitter.Parent = mist
	end
	task.wait()
	-- Lichtung und die schlechte Schotterstraße (Erde, Schlamm in den Fahrspuren, Steine)
	terrain:FillBlock(roadFrame * CFrame.new(0, -4, -24), Vector3.new(400, 8, 130), Enum.Material.LeafyGrass)
	terrain:FillBlock(roadFrame * CFrame.new(0, 14, -24), Vector3.new(400, 28, 130), Enum.Material.Air)
	-- (alles genau bis y = 0, damit nichts halb in einem Voxel steckt und den Boden anhebt)
	terrain:FillBlock(roadFrame * CFrame.new(0, -4, SarpHut.ROAD_Z), Vector3.new(400, 8, SarpHut.ROAD_HALF * 2), Enum.Material.Ground)
	for _, lane in { -2.6, 2.6 } do
		terrain:FillBlock(roadFrame * CFrame.new(0, -4, SarpHut.ROAD_Z + lane), Vector3.new(400, 8, 1.6), Enum.Material.Mud)
	end
	terrain:FillBlock(roadFrame * CFrame.new(0, -4, SarpHut.ROAD_Z), Vector3.new(400, 8, 1.4), Enum.Material.Pebble)
	do
		local puddles = Random.new(5)
		for _ = 1, 14 do
			local x = puddles:NextNumber(-180, 180)
			terrain:FillBlock(roadFrame * CFrame.new(x, -4, SarpHut.ROAD_Z + puddles:NextNumber(-3, 3)), Vector3.new(puddles:NextNumber(3, 7), 8, puddles:NextNumber(2, 4)), Enum.Material.Mud)
		end
	end
	-- vom Wegende zur Hütte: festgetretene Erde
	terrain:FillBlock(roadFrame * CFrame.new(0, -4, -15), Vector3.new(5, 8, 8), Enum.Material.Ground)
	-- auf dem Waldweg: Flecken aus Schlamm, Kies und Moos (nicht überall gleich braun)
	do
		local patches = Random.new(17)
		local walked = 0
		for i = 1, #points - 1 do
			if i ~= BRIDGE then
				local a, b = points[i], points[i + 1]
				local length = (b - a).Magnitude
				local frame = CFrame.lookAt(a, b)
				local along = patches:NextNumber(3, 10)
				while along < length do
					local materials = { Enum.Material.Mud, Enum.Material.Pebble, Enum.Material.Ground, Enum.Material.Grass }
					local material = materials[patches:NextInteger(1, #materials)]
					local x = material == Enum.Material.Grass and (patches:NextNumber() < 0.5 and -4.5 or 4.5) or patches:NextNumber(-2.5, 2.5)
					terrain:FillBlock(frame * CFrame.new(x, -4, -along) * CFrame.Angles(0, patches:NextNumber(-0.5, 0.5), 0), Vector3.new(patches:NextNumber(2.5, 5), 8, patches:NextNumber(3, 7)), material)
					along += patches:NextNumber(7, 16)
				end
			end
			walked += 1
			if walked % 3 == 0 then
				task.wait()
			end
		end
	end
	task.wait()

	-- unsichtbare Wände (man bleibt auf dem Weg bzw. auf der Brücke)
	local function wall(size, frame)
		Parts.new("Part", { Name = "PathWall", Size = size, CFrame = frame, Transparency = 1, CanCollide = true, CanQuery = false, CanTouch = false, Parent = folder })
	end
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local frame = CFrame.lookAt((a + b) / 2, b)
		local length = (b - a).Magnitude
		local half = i == BRIDGE and BRIDGE_HALF_WIDTH or PATH_HALF_WIDTH
		local extra = i == BRIDGE and 0 or 10 -- (an Kurven keine Lücken)
		local shift = 0
		if i == #points - 1 then
			-- (das letzte Stück endet genau an der Lichtung)
			extra, shift = 5, 2.5
		end
		for _, side in { -1, 1 } do
			wall(Vector3.new(1, 18, length + extra), frame * CFrame.new(side * (half + 0.5), 9, shift))
		end
	end
	-- an der Kante der Schlucht: nur die Brücke ist offen
	local edgeWidth = PATH_HALF_WIDTH - BRIDGE_HALF_WIDTH + 6
	for _, side in { -1, 1 } do
		wall(Vector3.new(edgeWidth, 18, 1), CFrame.lookAt(bridgeA, bridgeB) * CFrame.new(side * (BRIDGE_HALF_WIDTH + 0.5 + edgeWidth / 2), 9, -1))
	end
	-- die Lichtung: links und rechts quer über die Straße, hinten, vorne (bis auf den Weg)
	wall(Vector3.new(1, 18, 54), roadFrame * CFrame.new(-30, 9, -23))
	wall(Vector3.new(1, 18, 54), roadFrame * CFrame.new(30, 9, -23))
	wall(Vector3.new(61, 18, 1), roadFrame * CFrame.new(0, 9, -49))
	for _, side in { -1, 1 } do
		wall(Vector3.new(30 - PATH_HALF_WIDTH, 18, 1), roadFrame * CFrame.new(side * (PATH_HALF_WIDTH + (30 - PATH_HALF_WIDTH) / 2), 9, 0.5))
	end
	-- hinter der Luke
	local forward = (points[2] - points[1]).Unit
	local behind = points[1] - forward * 3
	wall(Vector3.new(PATH_HALF_WIDTH * 2 + 8, 18, 1), CFrame.lookAt(behind, behind + forward) * CFrame.new(0, 9, 0))

	-- Bäume: am Weg entlang, dahinter dichter Wald (nie auf dem Weg, nicht in der Schlucht)
	local rng = Random.new(31)
	local _, _, total = Data.progress(points, points[1])
	local function clear(position, margin)
		local _, distance = Data.progress(points, position)
		return distance > margin and not nearRavine(position, 6) and not inClearing(position, 3)
	end
	local count = 0
	s = -20
	while s < total + 20 do
		local center, direction = Data.pointAt(points, math.clamp(s, 0, total))
		if s < 0 or s > total then
			center += direction * (s < 0 and s or s - total)
		end
		local right = Vector3.new(-direction.Z, 0, direction.X)
		for _, side in { -1, 1 } do
			local near = center + right * side * rng:NextNumber(12.5, 16) + direction * rng:NextNumber(-2, 2)
			if clear(near, 11.5) then
				if rng:NextNumber() < 0.35 then
					Forest.builders.pine(folder, near, rng:NextNumber(30, 46), rng)
				elseif rng:NextNumber() < 0.15 then
					Forest.builders.deadTree(folder, near, rng)
				else
					Forest.builders.simplePine(folder, near, rng:NextNumber(30, 48), rng)
				end
				count += 1
			end
			local bush = center + right * side * rng:NextNumber(13, 15) + direction * rng:NextNumber(-3, 3)
			if rng:NextNumber() < 0.6 and clear(bush, 12.8) then
				Forest.builders.bush(folder, bush, rng)
			end
			for row = 1, 3 do
				local far = center + right * side * (16 + row * rng:NextNumber(7, 12)) + direction * rng:NextNumber(-4, 4)
				if clear(far, 14) then
					Forest.builders.simplePine(folder, far, rng:NextNumber(32, 52), rng)
					count += 1
				end
			end
			if rng:NextNumber() < 0.12 then
				local rock = center + right * side * rng:NextNumber(11, 14)
				if clear(rock, 11) then
					Forest.builders.rock(folder, rock, rng)
				end
			end
		end
		s += rng:NextNumber(5, 7.5)
		if count % 8 == 0 then
			task.wait()
		end
	end

	-- Sarps Hütte und der Wald rund um die Lichtung und an der Straße entlang
	-- Bodenhöhe an einer Stelle (Strahl von oben auf das Terrain)
	local groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Include
	groundParams.FilterDescendantsInstances = { terrain }
	local function groundAt(position)
		local hit = workspace:Raycast(Vector3.new(position.X, 40, position.Z), Vector3.new(0, -80, 0), groundParams)
		return hit and hit.Position.Y or 0
	end
	local hutOk, hutResult = pcall(SarpHut.build, folder, roadFrame, groundAt)
	if hutOk then
		hut = hutResult
	else
		warn("Kapitel 3: Sarps Hütte konnte nicht gebaut werden: " .. tostring(hutResult))
	end
	task.wait()
	for _ = 1, 260 do
		local p = Vector3.new(rng:NextNumber(-150, 150), 0, rng:NextNumber(-90, 30))
		local world = roadFrame * p
		local _, distance = Data.progress(points, world)
		if distance > 13 and not inClearing(world, 1) and not nearRavine(world, 6) then
			if rng:NextNumber() < 0.3 then
				Forest.builders.pine(folder, world, rng:NextNumber(30, 46), rng)
			else
				Forest.builders.simplePine(folder, world, rng:NextNumber(32, 50), rng)
			end
			count += 1
			if count % 8 == 0 then
				task.wait()
			end
		end
	end
	-- Details am Weg (Farne, Gras, Laub, Wurzeln, Nebel, Glühwürmchen)
	pcall(ForestDressing.terrain, points, function(position)
		return not nearRavine(position, 4) and not inClearing(position, -2)
	end, 2, total)
	local dressOk, dressProblem = pcall(ForestDressing.path, folder, points, function(position)
		return not nearRavine(position, 4) and not inClearing(position, -2)
	end, 4, total)
	if not dressOk then
		warn("Kapitel 3: Details am Weg fehlen: " .. tostring(dressProblem))
	end
	-- Büsche am Rand der Lichtung
	for _ = 1, 40 do
		local p = Vector3.new(rng:NextNumber(-34, 34), 0, rng:NextNumber(-52, 2))
		local local0 = p
		if math.abs(local0.X) > 27 or local0.Z < -45 then
			local world = roadFrame * p
			if math.abs(local0.Z - SarpHut.ROAD_Z) > SarpHut.ROAD_HALF + 2 then
				Forest.builders.bush(folder, world, rng)
			end
		end
	end

	-- Die Hängebrücke über die Schlucht (stürzt ein, wenn man mitten drauf ist)
	local bridgeFolder = Instance.new("Model")
	bridgeFolder.Name = "Bridge"
	bridgeFolder.Parent = folder
	local bridgeFrame = CFrame.lookAt(bridgeA, bridgeB)
	local parts = {}
	local plankCount = math.floor(bridgeLength / 1.3)
	for k = 0, plankCount do
		local z = -k * bridgeLength / plankCount
		local sag = math.sin(k / plankCount * math.pi) * 1.2
		local plank = block(bridgeFolder, "Plank", Vector3.new(5.4, 0.3, 1.05), bridgeFrame * CFrame.new(0, -0.15 - sag, z) * CFrame.Angles(0, rng:NextNumber(-0.04, 0.04), 0), Color3.fromRGB(92, 70, 48):Lerp(Color3.fromRGB(60, 48, 36), rng:NextNumber()), M.WoodPlanks, { CanCollide = false })
		table.insert(parts, plank)
		if k % 3 == 0 then
			for _, x in { -2.8, 2.8 } do
				table.insert(parts, block(bridgeFolder, "Hanger", Vector3.new(0.12, 3, 0.12), bridgeFrame * CFrame.new(x, 1.35 - sag * 0.5, z), Color3.fromRGB(120, 104, 80), M.Fabric, { CanCollide = false }))
			end
		end
	end
	for _, x in { -2.8, 2.8 } do
		-- Seile oben (Handlauf) und unten, in Stücken, damit sie mit durchhängen und einzeln fallen
		for k = 0, 7 do
			local z0, z1 = -k * bridgeLength / 8, -(k + 1) * bridgeLength / 8
			local sag0 = math.sin(k / 8 * math.pi) * 1.2
			local sag1 = math.sin((k + 1) / 8 * math.pi) * 1.2
			for _, height in { 3, 0 } do
				local p0 = (bridgeFrame * CFrame.new(x, height - sag0 * (height > 0 and 0.5 or 1), z0)).Position
				local p1 = (bridgeFrame * CFrame.new(x, height - sag1 * (height > 0 and 0.5 or 1), z1)).Position
				table.insert(parts, Parts.beam({ Name = "Rope", Color = Color3.fromRGB(120, 104, 80), Material = M.Fabric, CanCollide = false, Parent = bridgeFolder }, p0, p1, 0.16))
			end
		end
		-- Pfosten an beiden Enden (bleiben stehen)
		for _, at in { bridgeA, bridgeB } do
			local post = (CFrame.lookAt(at, at + bridgeDirection) * CFrame.new(x, 0, 0)).Position
			block(folder, "BridgePost", Vector3.new(0.6, 4, 0.6), CFrame.new(post + Vector3.new(0, 1.5, 0)), Color3.fromRGB(70, 52, 36), M.Wood)
		end
	end
	-- unsichtbarer Boden unter den Brettern (zum Laufen, folgt dem Durchhängen grob)
	local floor = {}
	for k = 0, 7 do
		local p0 = (bridgeFrame * CFrame.new(0, -0.2 - math.sin(k / 8 * math.pi) * 1.2, -k * bridgeLength / 8)).Position
		local p1 = (bridgeFrame * CFrame.new(0, -0.2 - math.sin((k + 1) / 8 * math.pi) * 1.2, -(k + 1) * bridgeLength / 8)).Position
		table.insert(floor, block(bridgeFolder, "BridgeFloor", Vector3.new(BRIDGE_HALF_WIDTH * 2, 0.4, (p1 - p0).Magnitude + 0.3), CFrame.lookAt((p0 + p1) / 2, p1), Color3.new(), M.SmoothPlastic, { Transparency = 1 }))
	end
	bridge = { parts = parts, floor = floor }

	-- Die Luke am Anfang: offen, daneben der Deckel
	local hatchAt = points[1] - forward * 1.5
	local hatchFrame = CFrame.lookAt(hatchAt, hatchAt + forward)
	block(folder, "HatchHole", Vector3.new(3.4, 0.2, 3.4), hatchFrame * CFrame.new(0, 0.02, 0), Color3.new(0, 0, 0), M.SmoothPlastic, { CanCollide = false })
	for _, x in { -1.8, 1.8 } do
		block(folder, "HatchFrame", Vector3.new(0.4, 0.4, 4), hatchFrame * CFrame.new(x, 0.15, 0), Color3.fromRGB(70, 54, 36), M.WoodPlanks)
	end
	for _, z in { -1.8, 1.8 } do
		block(folder, "HatchFrame", Vector3.new(4, 0.4, 0.4), hatchFrame * CFrame.new(0, 0.15, z), Color3.fromRGB(70, 54, 36), M.WoodPlanks)
	end
	block(folder, "HatchLid", Vector3.new(3.4, 0.35, 3.4), hatchFrame * CFrame.new(0, 0.3, 1.8) * CFrame.Angles(math.rad(-105), 0, 0) * CFrame.new(0, 0, 1.7), Color3.fromRGB(70, 54, 36), M.WoodPlanks)
	forestStart = points[1] + forward * 2.5
	forestReady = true
	print(string.format("Kapitel 3: Waldweg fertig (%d Bäume, %.0f Studs lang, Brücke bei %.0f, Hütte: %s)", count, total, bridgeStart, hut and "ja" or "nein"))
	if hut then
		print(string.format("Kapitel 3: Hütte steht auf Höhe %.2f, Polizeiauto hält auf Höhe %.2f (Boden am Wegende %.2f)", hut.frame.Y, hut.carStop.Y, groundAt(roadFrame.Position)))
	end
end

Kapitel3.buildForest = buildForest -- (auch zum Testen)
Kapitel3.buildHall = buildHall

-- Die Brücke stürzt ein (alles fällt in die Schlucht – mit dem Biest)
local function collapseBridge()
	if not bridge then
		return
	end
	for _, part in bridge.floor do
		part:Destroy()
	end
	-- (danach kann niemand mehr in die Schlucht laufen)
	local a, b = forestPoints[BRIDGE], forestPoints[BRIDGE + 1]
	Parts.new("Part", { Name = "PathWall", Size = Vector3.new(PATH_HALF_WIDTH * 2 + 4, 18, 1), CFrame = CFrame.lookAt(b, b + (b - a).Unit) * CFrame.new(0, 9, 0.5), Transparency = 1, CanCollide = true, CanQuery = false, CanTouch = false, Parent = workspace:FindFirstChild("Kapitel3Forest") or workspace })
	local rng = Random.new()
	for _, part in bridge.parts do
		if part.Parent then
			part.Anchored = false
			part.CanCollide = false
			part.AssemblyLinearVelocity = Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(-8, 2), rng:NextNumber(-3, 3))
			part.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-4, 4), rng:NextNumber(-4, 4), rng:NextNumber(-4, 4))
		end
	end
end

------------------------------------------------------------------ Ablauf
function Kapitel3.run(kit)
	local ctx = kit.ctx
	local remotes, event, say = ctx.remotes, ctx.event, ctx.say
	local rootOf = kit.rootOf
	remotes:SetAttribute("Phase", "kapitel3")
	remotes:SetAttribute("SneakAllowed", false)
	ctx.setMovement(false)
	-- Teststart "huette": gleich hinter der Brücke (Weg zu Sarps Hütte, Telefon, Ende)
	local skipToHut = ctx.startAt == "huette"
	if not skipToHut then
		event:FireAllClients({ type = "k3", step = "card", title = Kapitel3.TITLE })
	end
	print("Kapitel 3: " .. #Players:GetPlayers() .. " Spieler – die Tür ist offen.")
	local hallOk, hallProblem = pcall(buildHall)
	if not hallOk then
		warn("Kapitel 3: Ritualsaal konnte nicht gebaut werden: " .. tostring(hallProblem))
	end
	task.spawn(function()
		local ok, problem = pcall(buildForest)
		if not ok then
			warn("Kapitel 3: Waldweg konnte nicht gebaut werden: " .. tostring(problem))
			forestReady = true
		end
	end)

	local function remote(name)
		local found = remotes:FindFirstChild(name)
		if not found then
			found = Instance.new("RemoteEvent")
			found.Name = name
			found.Parent = remotes
		end
		return found
	end
	local results = {} -- Spieler -> { [Nummer] = true/false }
	remote("K3Qte").OnServerEvent:Connect(function(player, index, success)
		if type(index) ~= "number" then
			return
		end
		results[player] = results[player] or {}
		if results[player][index] == nil then
			results[player][index] = success == true
		end
	end)
	local runActive = false
	local caughtBy = {} -- im Wald erwischt (meldet der Client)
	remote("K3Caught").OnServerEvent:Connect(function(player)
		if runActive then
			caughtBy[player] = true
		end
	end)

	-- Game Over: warten, bis alle "Nochmal versuchen" gedrückt haben
	local function gameOverFor(lost)
		for _, player in lost do
			if player.Parent and ctx.gameOver then
				ctx.gameOver(player)
			end
		end
		local waitStart = os.clock()
		while os.clock() - waitStart < 600 do
			local waiting = false
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("GameOver") then
					waiting = true
				end
			end
			if not waiting then
				break
			end
			task.wait(0.25)
		end
		task.wait(1.6)
	end

	------------------------------------------------ Das Ende: Sarps Hütte
	-- Hinter der Brücke um die Kurve: die Hütte an der Straße. Drinnen merkt man, wem sie
	-- gehört. Telefon (Zettel: 110), dann warten: Spiegel und Foto (Halluzinationen, man muss
	-- mindestens eine gesehen haben), danach ins Bett – die Polizei kommt und fährt einen weg.
	local function afterBridgeFrame(index)
		local a, b = forestPoints[BRIDGE + 1], forestPoints[BRIDGE + 2]
		local dir = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local feet = a + dir * (Data.BRIDGE_CLEAR + 4) + side * ((index - 1) * 2.5 - (#Players:GetPlayers() > 1 and 1.25 or 0)) + Vector3.new(0, 0.05, 0)
		return CFrame.lookAt(feet, feet + dir)
	end
	local function finale()
		if not (hut and forestPoints) then
			event:FireAllClients({ type = "k3", step = "end" })
			return
		end
		local _, _, pathLength = Data.progress(forestPoints, forestPoints[1])
		remotes:SetAttribute("Inside", false)
		ctx.setCheckpoint(afterBridgeFrame)
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root then
				root.Anchored = false
			end
		end
		ctx.setMovement(true)
		event:FireAllClients({
			type = "k3",
			step = "walk",
			hut = hut.folder,
			mirror = hut.mirror,
			photo = hut.photo,
			phone = hut.phone,
			phoneKeys = hut.phoneKeys,
			phoneView = hut.phoneView,
			carStop = hut.carStop,
			endInside = hut.endInside,
			endOutside = hut.endOutside,
			door = hut.door,
		})
		event:FireAllClients({ type = "objectives", title = "Weg hier", items = { { text = "Dem Weg folgen", done = false } } })

		local state = { called = false, calling = false, scared = {}, resting = false }
		local function prompt(parent, action, object, hold)
			local p = Instance.new("ProximityPrompt")
			p.ActionText = action
			p.ObjectText = object
			p.HoldDuration = hold or 0
			p.MaxActivationDistance = 7
			p.RequiresLineOfSight = false
			p.Parent = parent
			return p
		end
		-- das Telefon: der Client zeigt es groß, man klickt die Tasten an
		local phonePrompt = prompt(hut.phone, "Telefonieren", "Altes Telefon")
		phonePrompt.Triggered:Connect(function(player)
			if state.called or state.calling then
				event:FireClient(player, { type = "hint", text = "Die Polizei ist schon unterwegs.", seconds = 3 })
				return
			end
			event:FireClient(player, { type = "k3", step = "phone" })
		end)
		remote("K3Phone").OnServerEvent:Connect(function(player, number)
			if state.called or state.calling or number ~= Data.PHONE_NUMBER then
				return
			end
			state.calling = true
			phonePrompt.Enabled = false
			task.spawn(function()
				event:FireAllClients({ type = "k3", step = "calling", caller = player.UserId })
				task.wait(Data.PHONE_RING)
				local K = Script.KAPITEL3
				say("police", K.police1)
				say("player", K.call1)
				say("police", K.police2)
				say("player", K.call2)
				say("police", K.police3)
				event:FireAllClients({ type = "k3", step = "hangUp" })
				state.called = true
				state.calling = false
				phonePrompt.Enabled = true
				event:FireAllClients({ type = "objectives", title = "Sarps Hütte", items = { { text = "Die Polizei rufen", done = true }, { text = "Irgendetwas stimmt nicht … (Spiegel, Foto am Bett)", done = false }, { text = "Auf die Polizei warten: ausruhen (Bett)", done = false } } })
				event:FireAllClients({ type = "hint", text = "Die Polizei ist unterwegs. Ruh dich aus … (Bett hinter dem Vorhang)", seconds = 5 })
				event:FireAllClients({ type = "k3", step = "scares" })
			end)
		end)
		remote("K3Scare").OnServerEvent:Connect(function(player, kind)
			if state.called and (kind == "mirror" or kind == "photo") and not state.scared[player] then
				state.scared[player] = true
				print("Kapitel 3: " .. player.Name .. " hat die Halluzination gesehen (" .. kind .. ")")
			end
		end)
		-- das Bett: erst nach dem Anruf und erst, wenn man mindestens einen Schreck hatte
		local bedPrompt = prompt(hut.bed, "Ausruhen", "Bett", 0.6)
		bedPrompt.Triggered:Connect(function(player)
			if state.resting then
				return
			end
			if not state.called then
				event:FireClient(player, { type = "hint", text = state.calling and "Erst das Telefonat …" or "Erst die Polizei anrufen.", seconds = 3 })
				return
			end
			if not state.scared[player] then
				event:FireClient(player, { type = "hint", text = "Ich kann jetzt nicht schlafen … Der Spiegel … das Foto neben dem Bett … irgendetwas stimmt hier nicht.", seconds = 5 })
				return
			end
			state.resting = true
		end)

		local seen, entered = false, false
		while not state.resting do
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				if root then
					if not seen and Data.progress(forestPoints, root.Position) > pathLength - 50 then
						seen = true
						task.spawn(say, "player", Script.KAPITEL3.hutSeen)
					end
					if not entered and hut.inside(root.Position) then
						entered = true
						task.spawn(function()
							say("player", Script.KAPITEL3.hutInside)
							if not (state.called or state.calling) then
								say("player", Script.KAPITEL3.hutPhone)
								if not (state.called or state.calling) then
									event:FireAllClients({ type = "objectives", title = "Sarps Hütte", items = { { text = "Die Polizei rufen (Telefon)", done = false } } })
								end
							end
						end)
					end
				end
			end
			task.wait(0.2)
		end

		-- Ende: ausruhen – später kommt die Polizei, man fährt mit (das Auto fährt weg)
		phonePrompt.Enabled = false
		bedPrompt.Enabled = false
		ctx.setMovement(false)
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root then
				root.Anchored = true
			end
		end
		event:FireAllClients({ type = "objectives", clear = true })
		event:FireAllClients({ type = "k3", step = "rest" })
		local started = os.clock()
		local function waitUntil(t)
			local left = t - (os.clock() - started)
			if left > 0 then
				task.wait(left)
			end
		end
		waitUntil(Data.END_KNOCK + 0.5)
		say("police", Script.KAPITEL3.knock)
		waitUntil(Data.END_ANSWER)
		say("player", Script.KAPITEL3.comingOut)
		waitUntil(Data.END_TITLE + 2)
		print("Kapitel 3: ENDE – die Polizei hat alle abgeholt.")
	end

	if skipToHut then
		local waitStart = os.clock()
		while not forestReady and os.clock() - waitStart < 30 do
			task.wait(0.1)
		end
		if not forestPoints then
			return
		end
		task.wait(1)
		for index, player in Players:GetPlayers() do
			local root, humanoid = rootOf(player)
			if root and humanoid then
				player.Character:PivotTo(afterBridgeFrame(index) + Vector3.new(0, kit.footOffset(player), 0))
				humanoid.JumpHeight = 2
			end
		end
		collapseBridge()
		finale()
		return
	end

	------------------------------------------------ Aufstellung im Ritualsaal
	local center = H(0, 0)
	local door = H(0, 23) -- dort steht Sarp plötzlich (im Eingang)
	local fleePath = { H(-6, 9), H(-14, 4), H(-21.5, 0.3), H(-30, 0), H(-38, 0) } -- in den Tunnel
	local function spotFor(index, count)
		if count <= 1 then
			return H(0, 12)
		end
		return H(index == 1 and -1.4 or 1.4, 12)
	end
	local function placePlayer(player, index, count)
		local root, humanoid = rootOf(player)
		if not (root and humanoid) then
			return
		end
		local feet = spotFor(index, count)
		root.Anchored = true
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		player.Character:PivotTo(CFrame.lookAt(feet, Vector3.new(center.X, feet.Y, center.Z)) + Vector3.new(0, kit.footOffset(player), 0))
	end
	ctx.setCheckpoint(function(index)
		local feet = spotFor(index, #Players:GetPlayers())
		return CFrame.lookAt(feet, Vector3.new(center.X, feet.Y, center.Z))
	end)

	-- Die Puppen: Richard vorne am Altar, Mrs. Wagner, Lucy und Tommy im Kreis (Blick zur Mitte)
	local PUPPETS = {
		{ model = kit.mr, x = 0, z = -4 },
		{ model = kit.members and kit.members.mrsWagner, x = -4, z = 0 },
		{ model = kit.members and kit.members.tommy, x = 4, z = 0 },
		{ model = kit.members and kit.members.lucy, x = 0, z = 4 },
	}
	local function storeBases(model)
		for _, joint in model:GetDescendants() do
			if joint:IsA("Motor6D") and joint:GetAttribute("Base") == nil then
				joint:SetAttribute("Base", joint.C0)
			end
		end
	end
	local function setupPuppets()
		local list = {}
		for _, info in PUPPETS do
			local model = info.model
			if model and model.Parent then
				pcall(Wagners.stand, model)
				if kit.setFade then
					kit.setFade(model, 0)
				end
				local feet = H(info.x, info.z)
				Wagners.place(model, feet, center)
				model:SetAttribute("Look", "puppet")
				storeBases(model)
				table.insert(list, { model = model, home = model.HumanoidRootPart.CFrame })
			end
		end
		return list
	end
	local sarp = kit.sarp
	if sarp then
		Wagners.place(sarp, kit.away, ctx.facing)
		storeBases(sarp)
	end

	-- während die Karte läuft, werden alle in den Saal gebracht
	task.wait(1)
	for index, player in Players:GetPlayers() do
		placePlayer(player, index, #Players:GetPlayers())
	end
	task.wait(Data.CARD - 1)

	------------------------------------------------ Die Sequenz (bei Game Over von vorne)
	local function ritual(attempt)
		local players = Players:GetPlayers()
		local spots = {}
		for index, player in players do
			placePlayer(player, index, #players)
			spots[tostring(player.UserId)] = spotFor(index, #players)
		end
		local puppets = setupPuppets()
		if sarp then
			Wagners.place(sarp, kit.away, ctx.facing)
		end
		for _, player in players do
			results[player] = {}
		end
		event:FireAllClients({
			type = "k3",
			step = "ritual",
			attempt = attempt,
			center = center,
			door = door,
			flee = fleePath,
			spots = spots,
			puppets = puppets,
			sarp = sarp,
			hall = hall,
			ceiling = center.Y + HALL_HEIGHT - 1,
		})
		-- was Sarp sagt (passend zur Kamera auf dem Client)
		task.delay(14.6, function()
			say("sarpDemon", Script.KAPITEL3.sarpDoor, "Sarp")
			task.wait(0.2)
			say("sarpDemon", Script.KAPITEL3.sarpNobody, "Sarp")
		end)
		task.wait(Data.INTRO)

		local misses = {}
		for index, kind in Data.ORDER do
			local timing = Data.QTE[kind]
			event:FireAllClients({ type = "k3", step = "qte", index = index, kind = kind, dir = math.random() < 0.5 and -1 or 1 })
			if kind == "struggle" then
				task.delay(timing.windup * 0.4, function()
					say("sarpDemon", Script.KAPITEL3.sarpGrab, "Sarp")
				end)
			end
			local deadline = os.clock() + timing.windup + timing.window + 2
			while os.clock() < deadline do
				local all = true
				for _, player in Players:GetPlayers() do
					if not (results[player] and results[player][index] ~= nil) then
						all = false
					end
				end
				if all then
					break
				end
				task.wait(0.05)
			end
			local lost = {}
			for _, player in Players:GetPlayers() do
				local result = results[player] and results[player][index]
				if result == nil then
					-- keine Antwort vom Client (dort ist etwas kaputt): nicht als Fehler zählen
					warn(string.format("Kapitel 3: keine Antwort von %s bei Event %d (%s) – zählt als geschafft", player.Name, index, kind))
				elseif result == false then
					misses[player] = (misses[player] or 0) + 1
					print(string.format("Kapitel 3: %s hat Event %d (%s) verpasst (%d)", player.Name, index, kind, misses[player]))
					if misses[player] > Data.MAX_MISSES then
						table.insert(lost, player)
					end
				end
			end
			if #lost > 0 then
				-- zweimal verpasst: Sarp erwischt einen – Game Over (danach von vorne)
				for _, player in Players:GetPlayers() do
					event:FireClient(player, { type = "k3", step = table.find(lost, player) and "killed" or "partnerKilled" })
				end
				task.wait(2.6)
				gameOverFor(lost)
				return false
			end
			task.wait(timing.outcome)
		end

		-- geschafft: Sarp brennt, die Puppen fallen, raus in den Tunnel
		event:FireAllClients({ type = "k3", step = "flee" })
		task.delay(1.6, function()
			say("player", Script.KAPITEL3.tunnel)
		end)
		task.wait(Data.FLEE)
		return true
	end

	local attempt = 0
	while true do
		attempt += 1
		local ok, survived = pcall(ritual, attempt)
		if not ok then
			warn("Kapitel 3: Fehler in der Sequenz im Ritualsaal: " .. tostring(survived))
			break
		end
		if survived then
			break
		end
	end
	for _, info in PUPPETS do
		if info.model and info.model.Parent then
			info.model:SetAttribute("Look", "down")
			Wagners.place(info.model, ctx.hiddenSpot, ctx.facing)
		end
	end

	------------------------------------------------ Durch den Wald (bei Game Over von vorne)
	local waitStart = os.clock()
	while not forestReady and os.clock() - waitStart < 20 do
		task.wait(0.1)
	end
	if not forestPoints then
		event:FireAllClients({ type = "k3", step = "end" })
		return
	end
	remotes:SetAttribute("Inside", false) -- draußen: Wald-Geräusche wieder an
	local forward = (forestPoints[2] - forestPoints[1]).Unit
	local function runFrame(index)
		local side = Vector3.new(-forward.Z, 0, forward.X)
		local feet = forestStart + side * ((index - 1) * 2.5 - (#Players:GetPlayers() > 1 and 1.25 or 0)) + Vector3.new(0, 0.05, 0)
		return CFrame.lookAt(feet, feet + forward)
	end
	local function setSpeed(speed)
		for _, player in Players:GetPlayers() do
			local _, humanoid = rootOf(player)
			if humanoid then
				humanoid.WalkSpeed = speed
			end
		end
	end
	local function forestRun()
		ctx.setCheckpoint(runFrame)
		for index, player in Players:GetPlayers() do
			local root, humanoid = rootOf(player)
			if root and humanoid then
				player.Character:PivotTo(runFrame(index) + Vector3.new(0, kit.footOffset(player), 0))
				root.Anchored = false
				humanoid.WalkSpeed = 0
				humanoid.JumpHeight = 2
			end
		end
		table.clear(caughtBy)
		runActive = true
		event:FireAllClients({ type = "k3", step = "run", path = forestPoints, length = chaseTotal, bridgeStart = bridgeStart, bridgeLength = bridgeLength, sarp = sarp })
		task.wait(1.2) -- (man klettert aus der Luke, das Bild wird hell)
		setSpeed(Data.RUN_SPEED)
		local started = os.clock()
		local transformed = false
		while os.clock() - started < Data.RUN_MAX_TIME do
			-- erwischt (zu langsam): Game Over, danach die Flucht von vorne
			if next(caughtBy) then
				runActive = false
				setSpeed(0)
				local lost = {}
				for _, player in Players:GetPlayers() do
					if caughtBy[player] then
						table.insert(lost, player)
					else
						event:FireClient(player, { type = "k3", step = "partnerKilled" })
					end
				end
				task.wait(1.6)
				gameOverFor(lost)
				return false
			end
			local best, last = 0, math.huge
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				if root then
					local progress = Data.progress(forestPoints, root.Position)
					best = math.max(best, progress)
					last = math.min(last, progress)
				end
			end
			if not transformed and best >= chaseTotal * Data.TRANSFORM_AT then
				transformed = true
				-- man bleibt stehen und schaut zurück: er verwandelt sich
				setSpeed(0)
				event:FireAllClients({ type = "k3", step = "transform" })
				task.wait(Data.TRANSFORM_TIME)
				setSpeed(Data.RUN_SPEED)
			end
			-- alle sind über die Brücke: hinter ihnen stürzt sie ein (mit dem Biest darauf)
			if last < math.huge and last >= bridgeStart + bridgeLength + Data.BRIDGE_CLEAR then
				break
			end
			task.wait(0.1)
		end
		runActive = false
		setSpeed(0)
		event:FireAllClients({ type = "k3", step = "bridge", bridgeStart = bridgeStart, bridgeLength = bridgeLength })
		task.wait(Data.BRIDGE_BREAK)
		collapseBridge()
		task.wait(Data.BRIDGE_SCENE - Data.BRIDGE_BREAK)
		print("Kapitel 3: Die Brücke ist mit dem Biest eingestürzt – weiter zur Hütte.")
		return true
	end
	while true do
		local ok, done = pcall(forestRun)
		if not ok then
			warn("Kapitel 3: Fehler bei der Flucht durch den Wald: " .. tostring(done))
			event:FireAllClients({ type = "k3", step = "end" })
			break
		end
		if done then
			local ok2, problem = pcall(finale)
			if not ok2 then
				warn("Kapitel 3: Fehler beim Ende (Sarps Hütte): " .. tostring(problem))
				event:FireAllClients({ type = "k3", step = "end" })
			end
			break
		end
	end
end

return Kapitel3
