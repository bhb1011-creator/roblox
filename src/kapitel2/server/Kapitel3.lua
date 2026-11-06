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
}
local BRIDGE = 10 -- die Brücke geht von FOREST_PATH[10] bis FOREST_PATH[11]
local PATH_HALF_WIDTH = 9.5 -- unsichtbare Wände links und rechts (breiter Weg)
local BRIDGE_HALF_WIDTH = 2.9

local forestReady = false
local forestPoints -- Weltpunkte des Wegs
local forestStart -- wo man aus der Luke steigt
local bridgeStart, bridgeLength -- Strecke bis zum Anfang der Brücke, Länge der Brücke
local bridge -- { parts, floor }

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
	-- Die Schlucht: Fels rundherum, in der Mitte tief nach unten
	terrain:FillBlock(ravineFrame * CFrame.new(0, -60, 0), Vector3.new(280, 120, bridgeLength + 70), Enum.Material.Slate)
	terrain:FillBlock(ravineFrame * CFrame.new(0, -58, 0), Vector3.new(340, 124, bridgeLength - 4), Enum.Material.Air)
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
		for _, side in { -1, 1 } do
			wall(Vector3.new(1, 18, length + extra), frame * CFrame.new(side * (half + 0.5), 9, 0))
		end
	end
	-- an der Kante der Schlucht: nur die Brücke ist offen
	local edgeWidth = PATH_HALF_WIDTH - BRIDGE_HALF_WIDTH + 6
	for _, side in { -1, 1 } do
		wall(Vector3.new(edgeWidth, 18, 1), CFrame.lookAt(bridgeA, bridgeB) * CFrame.new(side * (BRIDGE_HALF_WIDTH + 0.5 + edgeWidth / 2), 9, -1))
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
		return distance > margin and not nearRavine(position, 6)
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
	print(string.format("Kapitel 3: Waldweg fertig (%d Bäume, %.0f Studs lang, Brücke bei %.0f)", count, total, bridgeStart))
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
	event:FireAllClients({ type = "k3", step = "card", title = Kapitel3.TITLE })
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
	local _, _, total = Data.progress(forestPoints, forestPoints[1])
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
		event:FireAllClients({ type = "k3", step = "run", path = forestPoints, length = total, bridgeStart = bridgeStart, bridgeLength = bridgeLength, sarp = sarp })
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
			if not transformed and best >= total * Data.TRANSFORM_AT then
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
		event:FireAllClients({ type = "k3", step = "end" })
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root then
				root.Anchored = true
			end
		end
		print("Kapitel 3: Die Brücke ist mit dem Biest eingestürzt – schwarz (hier kommt später das Ende).")
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
			break
		end
	end
end

return Kapitel3
