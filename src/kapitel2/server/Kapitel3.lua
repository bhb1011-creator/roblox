-- Kapitel 3: beginnt, sobald jemand die alte Tür hinter dem Regal öffnet (Escape.lua).
--
--  1. Schwarz, "KAPITEL 3".
--  2. Ritualraum: die Familie und Richard stehen starr wie Puppen im Kreis. Sie flüstern,
--     dann Stille, die Köpfe rucken herum, die Kerzen flackern – Sarp steht im Eingang.
--  3. Sarp greift dreimal an (Quick-Time-Events): ausweichen (A/D), losreißen (E schnell
--     drücken), im richtigen Moment den Kerzenständer umstoßen (Leertaste). Eins darf man
--     verpassen, beim zweiten: Game Over (danach beginnt die Sequenz von vorne).
--  4. Sarp brennt, die Familie bricht zusammen wie Puppen ohne Fäden, man rennt in den Tunnel.
--  5. Raus aus der Luke in den Wald: ein Waldweg, Sarp hinterher (man kann nicht verlieren).
--     Nach knapp der Hälfte dreht man sich um: Sarp verwandelt sich in das Biest (Stufe 3)
--     und kommt auf allen Vieren hinterher. Kurz darauf: schwarz (hier kommt später das Ende).
--
-- Der Server gibt nur den Takt vor; Kamera, Animationen und Anzeigen macht der Client
-- (Kapitel3.lua im Client-Ordner). Die Zeiten stehen in Shared/Kapitel3Data.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Shared.Kapitel3Data)
local Script = require(ReplicatedStorage.Shared.Kapitel2Dialogue)
local Forest = require(ReplicatedStorage.Shared.Forest)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Mansion = require(script.Parent.Mansion)
local Wagners = require(script.Parent.Wagners)

local Kapitel3 = {}

Kapitel3.TITLE = "Das Ritual" -- Untertitel der Kapitelkarte (hier ändern)

-- Wo der Waldweg gebaut wird: weit weg von allem anderen (man kommt durch die Luke
-- am Ende des Tunnels dorthin – dass es woanders ist, merkt man nicht)
local FOREST_ORIGIN = Vector3.new(2600, 0, 0)
-- der Weg (x, z relativ zu FOREST_ORIGIN): kurvig, damit man nie weit sieht
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
}
local PATH_HALF_WIDTH = 5.2 -- unsichtbare Wände links und rechts

------------------------------------------------------------------ Der Waldweg
local forestReady = false
local forestPoints -- Weltpunkte des Wegs
local forestStart -- wo man aus der Luke steigt

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
	local function breathe(i)
		if i % 8 == 0 then
			task.wait()
		end
	end
	-- Boden: Gras, darauf ein erdiger Weg; darüber nichts (Luft)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local frame = CFrame.lookAt((a + b) / 2, b)
		local length = (b - a).Magnitude
		terrain:FillBlock(frame * CFrame.new(0, -4, 0), Vector3.new(110, 8, length + 110), Enum.Material.LeafyGrass)
		terrain:FillBlock(frame * CFrame.new(0, 12, 0), Vector3.new(110, 24, length + 110), Enum.Material.Air)
		task.wait()
	end
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local frame = CFrame.lookAt((a + b) / 2, b)
		local length = (b - a).Magnitude
		terrain:FillBlock(frame * CFrame.new(0, -3.9, 0), Vector3.new(6, 8, length + 6), Enum.Material.Ground)
		-- unsichtbare Wände (man bleibt auf dem Weg)
		for _, side in { -1, 1 } do
			Parts.new("Part", {
				Name = "PathWall",
				Size = Vector3.new(1, 16, length + 3),
				CFrame = frame * CFrame.new(side * (PATH_HALF_WIDTH + 0.5), 8, 0),
				Transparency = 1,
				CanCollide = true,
				CanQuery = false,
				CanTouch = false,
				Parent = folder,
			})
		end
	end
	-- Wand hinter der Luke und am Ende
	for _, info in { { points[1], points[2], -1 }, { points[#points], points[#points - 1], -1 } } do
		local direction = (info[2] - info[1]).Unit
		local at = info[1] - direction * 3
		Parts.new("Part", {
			Name = "PathWall",
			Size = Vector3.new(PATH_HALF_WIDTH * 2 + 4, 16, 1),
			CFrame = CFrame.lookAt(at, at + direction) * CFrame.new(0, 8, 0),
			Transparency = 1,
			CanCollide = true,
			CanQuery = false,
			CanTouch = false,
			Parent = folder,
		})
	end
	-- Bäume: dicht am Weg, dahinter immer dichter Wald (nie auf dem Weg)
	local rng = Random.new(31)
	local _, _, total = Data.progress(points, points[1])
	local function clearOfPath(position, margin)
		local _, distance = Data.progress(points, position)
		return distance > margin
	end
	local count = 0
	local s = -20
	while s < total + 20 do
		local center, direction = Data.pointAt(points, math.clamp(s, 0, total))
		if s < 0 or s > total then
			center += direction * (s < 0 and s or s - total)
		end
		local right = Vector3.new(-direction.Z, 0, direction.X)
		for _, side in { -1, 1 } do
			-- erste Reihe direkt am Weg
			local near = center + right * side * rng:NextNumber(7, 11) + direction * rng:NextNumber(-2, 2)
			if clearOfPath(near, 6.5) then
				if rng:NextNumber() < 0.35 then
					Forest.builders.pine(folder, near, rng:NextNumber(30, 46), rng)
				elseif rng:NextNumber() < 0.15 then
					Forest.builders.deadTree(folder, near, rng)
				else
					Forest.builders.simplePine(folder, near, rng:NextNumber(30, 48), rng)
				end
				count += 1
			end
			-- Unterholz zwischen Weg und Bäumen
			local bush = center + right * side * rng:NextNumber(8, 10) + direction * rng:NextNumber(-3, 3)
			if rng:NextNumber() < 0.6 and clearOfPath(bush, 7.8) then
				Forest.builders.bush(folder, bush, rng)
			end
			-- weiter hinten
			for row = 1, 3 do
				local far = center + right * side * (11 + row * rng:NextNumber(7, 12)) + direction * rng:NextNumber(-4, 4)
				if clearOfPath(far, 9) then
					Forest.builders.simplePine(folder, far, rng:NextNumber(32, 52), rng)
					count += 1
				end
			end
			if rng:NextNumber() < 0.12 then
				local rock = center + right * side * rng:NextNumber(6.5, 10)
				if clearOfPath(rock, 6.5) then
					Forest.builders.rock(folder, rock, rng)
				end
			end
		end
		s += rng:NextNumber(5, 7.5)
		breathe(count)
	end
	-- Die Luke am Anfang: offen, daneben der Deckel, darunter die Leiter
	local hatchAt = points[1] - (points[2] - points[1]).Unit * 1.5
	local forward = (points[2] - points[1]).Unit
	local hatchFrame = CFrame.lookAt(hatchAt, hatchAt + forward)
	Parts.new("Part", { Name = "HatchHole", Size = Vector3.new(3.4, 0.2, 3.4), CFrame = hatchFrame * CFrame.new(0, 0.02, 0), Color = Color3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = folder })
	for _, x in { -1.8, 1.8 } do
		Parts.new("Part", { Name = "HatchFrame", Size = Vector3.new(0.4, 0.4, 4), CFrame = hatchFrame * CFrame.new(x, 0.15, 0), Color = Color3.fromRGB(70, 54, 36), Material = Enum.Material.WoodPlanks, Parent = folder })
	end
	for _, z in { -1.8, 1.8 } do
		Parts.new("Part", { Name = "HatchFrame", Size = Vector3.new(4, 0.4, 0.4), CFrame = hatchFrame * CFrame.new(0, 0.15, z), Color = Color3.fromRGB(70, 54, 36), Material = Enum.Material.WoodPlanks, Parent = folder })
	end
	-- der Deckel ist nach hinten aufgeklappt
	Parts.new("Part", { Name = "HatchLid", Size = Vector3.new(3.4, 0.35, 3.4), CFrame = hatchFrame * CFrame.new(0, 0.3, 1.8) * CFrame.Angles(math.rad(-105), 0, 0) * CFrame.new(0, 0, 1.7), Color = Color3.fromRGB(70, 54, 36), Material = Enum.Material.WoodPlanks, Parent = folder })
	for _, x in { -0.9, 0.9 } do
		Parts.new("Part", { Name = "LadderRail", Size = Vector3.new(0.25, 1.2, 0.25), CFrame = hatchFrame * CFrame.new(x, 0.4, -1.2), Color = Color3.fromRGB(90, 70, 46), Material = Enum.Material.Wood, Parent = folder })
	end
	forestStart = points[1] + forward * 2.5
	forestReady = true
	print(string.format("Kapitel 3: Waldweg fertig (%d Bäume, %.0f Studs lang)", count, total))
end

Kapitel3.buildForest = buildForest -- (auch zum Testen)

------------------------------------------------------------------ Ablauf
function Kapitel3.run(kit)
	local ctx = kit.ctx
	local remotes, event, say = ctx.remotes, ctx.event, ctx.say
	local rootOf = kit.rootOf
	local K = Mansion.FLOORS.K
	local function P(x, y)
		return Mansion.point(x, y, K)
	end
	remotes:SetAttribute("Phase", "kapitel3")
	remotes:SetAttribute("SneakAllowed", false)
	ctx.setMovement(false)
	event:FireAllClients({ type = "k3", step = "card", title = Kapitel3.TITLE })
	print("Kapitel 3: " .. #Players:GetPlayers() .. " Spieler – die Tür ist offen.")
	task.spawn(function()
		local ok, problem = pcall(buildForest)
		if not ok then
			warn("Kapitel 3: Waldweg konnte nicht gebaut werden: " .. tostring(problem))
			forestReady = true
		end
	end)

	local qteEvent = remotes:FindFirstChild("K3Qte")
	if not qteEvent then
		qteEvent = Instance.new("RemoteEvent")
		qteEvent.Name = "K3Qte"
		qteEvent.Parent = remotes
	end
	local results = {} -- Spieler -> { [Nummer] = true/false }
	qteEvent.OnServerEvent:Connect(function(player, index, success)
		if type(index) ~= "number" then
			return
		end
		results[player] = results[player] or {}
		if results[player][index] == nil then
			results[player][index] = success == true
		end
	end)

	------------------------------------------------ Aufstellung im Ritualraum
	local center = P(47, 3)
	local door = P(47, 16.6) -- dort steht Sarp plötzlich (im Geheimgang)
	local fleePath = { P(43.5, 7.6), P(39.6, 4.2), P(36.4, 2.6), P(31, 1.0) } -- in den Tunnel
	local function spotFor(index, count)
		if count <= 1 then
			return P(47, 10.2)
		end
		return P(index == 1 and 45.8 or 48.2, 10.2)
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

	-- Die Puppen: Richard am Altar, Mrs. Wagner, Lucy und Tommy im Kreis (Blick zur Mitte)
	local PUPPETS = {
		{ model = kit.mr, x = 47, y = 0.1 },
		{ model = kit.members and kit.members.mrsWagner, x = 44.1, y = 3.8 },
		{ model = kit.members and kit.members.tommy, x = 49.9, y = 3.8 },
		{ model = kit.members and kit.members.lucy, x = 47, y = 5.9 },
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
				local feet = P(info.x, info.y)
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

	-- alle bleiben stehen, während die Karte läuft
	for index, player in Players:GetPlayers() do
		placePlayer(player, index, #Players:GetPlayers())
	end
	task.wait(Data.CARD)

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
			ceiling = K + 5.6, -- so hoch darf Sarp im Ritualraum sein (die Decke ist niedrig)
		})
		-- was Sarp sagt (passend zur Kamera auf dem Client)
		task.delay(14.4, function()
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
				if not (results[player] and results[player][index] == true) then
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
				for _, player in lost do
					if player.Parent and ctx.gameOver then
						ctx.gameOver(player)
					end
				end
				local waitStart = os.clock()
				while true do
					local waiting = false
					for _, player in Players:GetPlayers() do
						if player:GetAttribute("GameOver") then
							waiting = true
						end
					end
					if not waiting or os.clock() - waitStart > 600 then
						break
					end
					task.wait(0.25)
				end
				task.wait(1.6)
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
			warn("Kapitel 3: Fehler in der Sequenz im Ritualraum: " .. tostring(survived))
			break
		end
		if survived then
			break
		end
	end

	------------------------------------------------ Durch den Wald
	local waitStart = os.clock()
	while not forestReady and os.clock() - waitStart < 20 do
		task.wait(0.1)
	end
	for _, info in PUPPETS do
		if info.model and info.model.Parent then
			info.model:SetAttribute("Look", "down")
			Wagners.place(info.model, ctx.hiddenSpot, ctx.facing)
		end
	end
	if not forestPoints then
		event:FireAllClients({ type = "k3", step = "end" })
		return
	end
	remotes:SetAttribute("Inside", false) -- draußen: Wald-Geräusche wieder an
	local forward = (forestPoints[2] - forestPoints[1]).Unit
	local function runFrame(index)
		local side = Vector3.new(-forward.Z, 0, forward.X)
		local feet = forestStart + side * ((index - 1) * 2 - (#Players:GetPlayers() > 1 and 1 or 0)) + Vector3.new(0, 0.05, 0)
		return CFrame.lookAt(feet, feet + forward)
	end
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
	local _, _, total = Data.progress(forestPoints, forestPoints[1])
	event:FireAllClients({ type = "k3", step = "run", path = forestPoints, length = total, sarp = sarp })
	task.wait(1.2) -- (man klettert aus der Luke, das Bild wird hell)
	local function setSpeed(speed)
		for _, player in Players:GetPlayers() do
			local _, humanoid = rootOf(player)
			if humanoid then
				humanoid.WalkSpeed = speed
			end
		end
	end
	setSpeed(Data.RUN_SPEED)
	local started = os.clock()
	local transformed = false
	while os.clock() - started < Data.RUN_MAX_TIME do
		local best = 0
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root then
				best = math.max(best, (Data.progress(forestPoints, root.Position)))
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
		if best >= total - Data.END_MARGIN then
			break
		end
		task.wait(0.1)
	end
	setSpeed(0)
	event:FireAllClients({ type = "k3", step = "end" })
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root then
			root.Anchored = true
		end
	end
	print("Kapitel 3: Flucht durch den Wald vorbei – schwarz (hier kommt später das Ende).")
end

return Kapitel3
