-- Kapitel 2, die erste Nacht (gestartet, sobald alle im Gästezimmer im Bett liegen):
--   1. Mitten in der Nacht wacht man von Schreien auf. Mrs. Wagner steht in der Tür und holt
--      einen zum Essen. Man folgt ihr ins Esszimmer, Mr. Wagner wartet dort.
--   2. Kurzes Gespräch am Tisch, dann klopft es schwer an der Haustür. Die Wagners rennen
--      durch die Küche weg und schließen hinter sich ab: "Versteck dich!"
--   3. Drei Verstecke im Esszimmer (Schrank, unter dem Tisch, hinter dem Vorhang). Sarp in
--      seiner zweiten Gestalt reißt die Tür auf, durchsucht das Zimmer und bleibt vor jedem
--      Versteck stehen. Wer nicht versteckt ist (oder rauskommt), wird gefunden: Jumpscare.
--      Werden alle gefunden, beginnt das Verstecken von vorne.
--   4. Er verlässt das Zimmer. Man ist allein im Haus – hier hört es erst einmal auf.
-- Texte: Shared/Kapitel2Dialogue (NIGHT_WAKE, NIGHT_DINNER, SARP_WHISPERS).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Script = require(ReplicatedStorage.Shared.Kapitel2Dialogue)
local Mansion = require(script.Parent.Mansion)
local Wagners = require(script.Parent.Wagners)
local SarpStage2 = require(script.Parent.SarpStage2)

local Night = {}

local HIDE_TIME = 22 -- Sekunden zum Verstecken
local SARP_SPEED = 4.2
local WALK_SPEED = 8
local MAX_ROUNDS = 5 -- so oft darf man gefunden werden, dann geht es trotzdem weiter
local FOLLOW_TIMEOUT = 45 -- wer dann noch nicht im Esszimmer ist, wird hingeholt

function Night.run(ctx)
	local event, sfx, say = ctx.event, ctx.sfx, ctx.say
	local actions = ctx.actions
	local mrs, mr = ctx.npcs.mrsWagner, ctx.npcs.mrWagner
	local E, O = Mansion.FLOORS.E, Mansion.FLOORS.O

	-- Punkt im Haus (Plan-Koordinaten) als Ziel für ctx.walkPath
	local function P(x, y, floorKey)
		return { at = Mansion.point(x, y, floorKey == "O" and O or E) }
	end
	local function point(x, y, floorKey)
		return Mansion.point(x, y, floorKey == "O" and O or floorKey == "K" and Mansion.FLOORS.K or E)
	end
	local function rootOf(player)
		local character = player.Character
		return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
	end
	local function inDiningRoom(player)
		local root = rootOf(player)
		return root ~= nil and Mansion.inRoom(root.Position, "ess", "E")
	end
	local function footOffset(player)
		local root, humanoid = rootOf(player)
		return humanoid and (humanoid.HipHeight + root.Size.Y / 2) or 3
	end
	-- Spieler kurz schwarz und woanders hinstellen
	local function bringTo(player, feet, lookAt)
		local root = rootOf(player)
		if not root then
			return
		end
		event:FireClient(player, { type = "blink" })
		task.delay(0.45, function()
			local position = feet + Vector3.new(0, footOffset(player), 0)
			player.Character:PivotTo(CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)))
		end)
	end
	local function steps(position)
		sfx("stepWood", position + Vector3.new(0, 0.5, 0), { volume = 0.7, maxDistance = 50 })
	end

	-- Teststart direkt nach dem Verstecken (Config.TEST_START_KAPITEL2 = "nachVerstecken")
	local afterHide = ctx.startAt == "afterHide"

	-- Stuhl am Esstisch: Mitte der Sitzfläche, Blick zum Tisch
	local function chair(x, y, faceX, faceY)
		local seat = point(x, y) + Vector3.new(0, 1.9, 0)
		return CFrame.lookAt(seat, point(faceX, faceY) + Vector3.new(0, 1.9, 0))
	end
	local CHAIRS = {
		mrsWagner = chair(64.5, 25.5, 67, 25.5),
		mrWagner = chair(67, 39.5, 67, 30),
		lucy = chair(64.5, 34.5, 67, 34.5),
		tommy = chair(69.5, 34.5, 67, 34.5),
	}

	------------------------------------------------------------------ 1. Aufwachen
	if not afterHide then
		task.wait(5)
		-- Schreie irgendwo im Haus (alles noch schwarz)
		for i, spot in { { 60, 30 }, { 40, 26 }, { 70, 46 } } do
			sfx("scream", point(spot[1], spot[2], i == 2 and "O" or "E") + Vector3.new(0, 4, 0), { volume = 1.2, maxDistance = 300, speed = 0.9 + i * 0.05 })
			task.wait(2.2)
		end
		task.wait(1.5)
		for player in ctx.lying do
			ctx.standUp(player)
		end
		-- Mrs. Wagner steht in der Tür vom Gästezimmer, Mr. Wagner sitzt am Kopf des Tisches
		if mrs then
			Wagners.place(mrs, point(51.4, 52.6, "O"), point(51.4, 45, "O"))
			mrs:SetAttribute("Look", "player")
		end
		if mr then
			Wagners.sit(mr, CHAIRS.mrWagner)
			mr:SetAttribute("Look", "down")
		end
	end
	-- die Kinder sitzen schon am Tisch
	local family = (mrs and mrs.Parent) or (mr and mr.Parent) or workspace
	local function buildKid(name, builder)
		local ok, model = pcall(builder, family)
		if not ok then
			warn("Kapitel 2: " .. name .. " konnte nicht gebaut werden: " .. tostring(model))
			return nil
		end
		return model
	end
	local lucy = buildKid("Lucy", Wagners.buildLucy)
	local tommy = buildKid("Tommy", Wagners.buildTommy)
	if lucy then
		Wagners.sit(lucy, CHAIRS.lucy)
		lucy:SetAttribute("Look", "player")
	end
	if tommy then
		Wagners.sit(tommy, CHAIRS.tommy)
		tommy:SetAttribute("Look", "down")
	end
	ctx.npcs.lucy = lucy
	ctx.npcs.tommy = tommy
	if not afterHide then
		ctx.remotes:SetAttribute("Phase", "wake")
		event:FireAllClients({ type = "wake" })
		task.wait(3)
	end

	------------------------------------------------------------------ Aktionen
	-- Mrs. Wagner geht voraus: Galerie, Treppe hinunter, durch Flur und Küche ins Esszimmer
	function actions.followMrs()
		ctx.setMovement(true)
		local flurDoor = Mansion.doorAt(51.4, 54.15, "E")
		if flurDoor and flurDoor.angle == 0 then
			task.spawn(ctx.moveDoor, flurDoor, flurDoor.openAngle, 0.8)
		end
		event:FireAllClients({ type = "hint", text = "Folge Mrs. Wagner nach unten.", seconds = 6 })
		local arrived = false
		task.spawn(function()
			ctx.walkPath(mrs, {
				P(51.4, 56, "O"),
				P(44.4, 56.8, "O"),
				P(43.8, 59.4, "O"),
				P(43.8, 68.0, "E"),
				P(44.3, 69.6, "E"),
				P(48, 64.5, "E"),
				P(51.4, 57.5, "E"),
				P(51.4, 50.5, "E"),
				P(44, 46, "E"),
				P(44, 38, "E"),
				P(52, 38, "E"),
				P(57, 38, "E"),
				P(62.6, 33, "E"),
				P(62.6, 26.5, "E"),
			}, 4.5, steps)
			if mrs then
				Wagners.sit(mrs, CHAIRS.mrsWagner)
			end
			arrived = true
		end)
		-- warten, bis sie da ist und alle im Esszimmer sind (Nachzügler werden hingeholt)
		local arrivedAt
		local nextHint = os.clock() + 25
		while true do
			task.wait(0.3)
			if arrived then
				arrivedAt = arrivedAt or os.clock()
				local everyone = true
				for _, player in Players:GetPlayers() do
					if not inDiningRoom(player) then
						everyone = false
					end
				end
				if everyone then
					break
				end
				if os.clock() - arrivedAt > FOLLOW_TIMEOUT then
					for index, player in Players:GetPlayers() do
						if not inDiningRoom(player) then
							bringTo(player, point(62 - index, 36), point(67, 30))
						end
					end
					task.wait(1)
					break
				end
				if os.clock() > nextHint then
					nextHint = os.clock() + 15
					event:FireAllClients({ type = "hint", text = "Ins Esszimmer – durch Flur und Küche.", seconds = 4 })
				end
			end
		end
	end

	-- Hinsetzen: unsichtbare Sitze auf zwei Stühlen
	local seats = {}
	local seated = false
	local function sitEveryone()
		for index, player in Players:GetPlayers() do
			local seat = seats[index]
			local _, humanoid = rootOf(player)
			if seat and humanoid and seat.Occupant ~= humanoid then
				pcall(function()
					seat:Sit(humanoid)
				end)
			end
		end
	end
	function actions.sitDown()
		for index, frame in Mansion.dinnerSeats or {} do
			local seat = Instance.new("Seat")
			seat.Name = "DinnerSeat"
			seat.Size = Vector3.new(1.6, 0.2, 1.6)
			seat.CFrame = frame * CFrame.new(0, 1.85, 0)
			seat.Anchored = true
			seat.Transparency = 1
			seat.CanCollide = false
			seat.Parent = workspace:FindFirstChild("WagnerHouse", true) or workspace
			seats[index] = seat
		end
		-- wer keinen Stuhl hat (mehr als zwei Spieler), steht am Tisch
		for index, player in Players:GetPlayers() do
			if not seats[index] then
				bringTo(player, point(64, 33 + index), point(67, 30))
			end
		end
		sitEveryone()
		seated = true
		-- aufstehen geht beim Essen nicht: wer aufsteht, sitzt gleich wieder
		for _, player in Players:GetPlayers() do
			local _, humanoid = rootOf(player)
			if humanoid then
				humanoid.Seated:Connect(function(active)
					if not active and seated then
						task.delay(0.3, sitEveryone)
					end
				end)
			end
		end
	end

	function actions.knock()
		sfx("heavyKnock", ctx.frontDoor.position, { count = 3, interval = 0.9, volume = 1.6, maxDistance = 300 })
		task.wait(0.6)
		event:FireAllClients({ type = "candleOut", duration = 1.4 })
		task.wait(2.4)
	end

	-- Die Wagners rennen durch die Küche weg und schließen hinter sich ab
	local kitchenDoor = Mansion.doorAt(54.25, 38, "E")
	local livingDoor = Mansion.doorAt(62, 42, "E")
	function actions.flee()
		seated = false
		for _, player in Players:GetPlayers() do
			local _, humanoid = rootOf(player)
			if humanoid then
				humanoid.Sit = false
			end
		end
		for _, npc in { mrs, mr, lucy, tommy } do
			if npc then
				npc:SetAttribute("Look", "down")
			end
		end
		-- alle springen von den Stühlen auf
		Wagners.stand(mrs, point(62.8, 25.5), point(57, 38))
		Wagners.stand(mr, point(67, 41), point(57, 38))
		Wagners.stand(lucy, point(62.8, 34.5), point(57, 38))
		Wagners.stand(tommy, point(71.2, 34.5), point(57, 38))
		task.wait(0.3)
		local done = 0
		task.spawn(function()
			ctx.walkPath(mrs, { P(60, 34), P(57, 38), P(51, 38), P(46, 36) }, 10, steps)
			done += 1
		end)
		task.spawn(function()
			ctx.walkPath(lucy, { P(61.5, 36.5), P(57, 37.6), P(51, 37.6), P(46, 35.5) }, 10, steps)
		end)
		task.spawn(function()
			ctx.walkPath(tommy, { P(71, 38.2), P(62, 39.2), P(57, 38.8), P(51, 38.8), P(46, 37.5) }, 10, steps)
		end)
		task.spawn(function()
			ctx.walkPath(mr, { P(61, 40), P(57, 38.4), P(51, 38.4), P(46, 37) }, 10, steps)
			done += 1
		end)
		local deadline = os.clock() + 8
		while done < 2 and os.clock() < deadline do
			task.wait(0.1)
		end
		for _, npc in { mrs, mr, lucy, tommy } do
			if npc then
				Wagners.place(npc, ctx.hiddenSpot, ctx.facing)
			end
		end
		if kitchenDoor then
			kitchenDoor.locked = true
			if kitchenDoor.angle > 0 then
				sfx("doorSlam", kitchenDoor.model.PrimaryPart.Position, { volume = 1.2 })
				ctx.moveDoor(kitchenDoor, 0, 0.3)
			end
			sfx("doorChain", kitchenDoor.model.PrimaryPart.Position, { volume = 0.8 })
		end
		if livingDoor then
			livingDoor.locked = true
			if livingDoor.angle > 0 then
				ctx.moveDoor(livingDoor, 0, 0.3)
			end
		end
		for _, seat in seats do
			seat:Destroy()
		end
		ctx.setMovement(true)
	end

	if not afterHide then
		ctx.runScript(Script.NIGHT_WAKE, "Aufwachen")
		ctx.runScript(Script.NIGHT_DINNER, "Abendessen")
	else
		-- Teststart: Familie weg, alle stehen im Esszimmer, die Türen sind offen
		for _, npc in { mrs, mr, lucy, tommy } do
			if npc then
				Wagners.stand(npc)
				Wagners.place(npc, ctx.hiddenSpot, ctx.facing)
			end
		end
		for index, player in Players:GetPlayers() do
			bringTo(player, point(60 + index, 36), point(67, 30))
		end
		ctx.setMovement(true)
		task.wait(1.5)
	end

	------------------------------------------------------------------ 3. Verstecken
	local spots = Mansion.hideSpots or {}
	local hidden = {} -- Spieler -> Versteck
	local caught = {} -- Spieler -> true
	local hidePhase = false
	local LABELS = { Schrank = "Schrank", Tisch = "Unter den Tisch", Vorhang = "Hinter den Vorhang" }

	local function leaveSpot(player, toExit)
		local spot = hidden[player]
		if not spot then
			return
		end
		hidden[player] = nil
		spot.occupant = nil
		if spot.promptObject then
			spot.promptObject.ActionText = "Verstecken"
		end
		local root, humanoid = rootOf(player)
		if root and humanoid then
			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
			humanoid.WalkSpeed = WALK_SPEED
			root.Anchored = false
			if toExit ~= false then
				player.Character:PivotTo(spot.exit + Vector3.new(0, footOffset(player), 0))
			end
		end
		event:FireClient(player, { type = "unhidden" })
	end
	local function enterSpot(player, spot)
		local root, humanoid = rootOf(player)
		if not (root and humanoid) then
			return
		end
		if spot.occupant and spot.occupant ~= player then
			event:FireClient(player, { type = "hint", text = "Da ist schon jemand.", seconds = 2 })
			return
		end
		hidden[player] = spot
		spot.occupant = player
		spot.promptObject.ActionText = "Rauskommen"
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
		root.Anchored = true
		if spot.kind == "lie" then
			humanoid.PlatformStand = true
			player.Character:PivotTo(spot.place)
		else
			player.Character:PivotTo(spot.place + Vector3.new(0, footOffset(player), 0))
		end
		event:FireClient(player, { type = "hidden", spot = spot.name })
	end
	local holder = Instance.new("Folder")
	holder.Name = "HidePrompts"
	holder.Parent = workspace:FindFirstChild("WagnerHouse", true) or workspace
	for _, spot in spots do
		local part = Instance.new("Part")
		part.Name = "HideSpot" .. spot.name
		part.Size = Vector3.new(1, 1, 1)
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CFrame = spot.prompt
		part.Parent = holder
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = LABELS[spot.name] or spot.name
		prompt.ActionText = "Verstecken"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 7
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = part
		spot.promptObject = prompt
		prompt.Triggered:Connect(function(player)
			if caught[player] then
				return
			end
			if hidden[player] == spot then
				leaveSpot(player)
			elseif not hidden[player] and hidePhase then
				enterSpot(player, spot)
			end
		end)
	end
	local function setPrompts(enabled)
		for _, spot in spots do
			if spot.promptObject then
				spot.promptObject.Enabled = enabled
			end
		end
	end

	-- Sarp
	local sarpFolder = Instance.new("Folder")
	sarpFolder.Name = "SarpNight"
	sarpFolder.Parent = workspace
	local sarp = SarpStage2.build(sarpFolder)
	local away = ctx.hiddenSpot - Vector3.new(0, 20, 0)
	if sarp then
		Wagners.place(sarp, away, ctx.facing)
	end

	-- Sarp bewegen; bricht ab, sobald `interrupted()` wahr ist
	local function sarpWalk(points, speed, interrupted)
		if not sarp then
			return true
		end
		local position = Wagners.ground(sarp)
		local hips = {}
		for _, name in { "LeftUpperLeg", "RightUpperLeg" } do
			local part = sarp:FindFirstChild(name)
			local joint = part and part:FindFirstChildOfClass("Motor6D")
			if joint then
				table.insert(hips, { joint = joint, base = joint.C0 })
			end
		end
		local nextStep = 0
		for _, target in points do
			local distance = (target - position).Magnitude
			if distance > 0.05 then
				local direction = (target - position).Unit
				local from, start = position, os.clock()
				while true do
					if interrupted and interrupted() then
						return false
					end
					local a = math.min((os.clock() - start) * speed / distance, 1)
					position = from:Lerp(target, a)
					Wagners.place(sarp, position, position + direction)
					for index, hip in hips do
						pcall(function()
							hip.joint.C0 = hip.base * CFrame.Angles(math.sin(os.clock() * 5 + index * math.pi) * 0.3, 0, 0)
						end)
					end
					if os.clock() >= nextStep then
						nextStep = os.clock() + 0.7
						-- sehr laut und weit zu hören: man merkt, wenn er näher kommt
						sfx("sarpStep", position + Vector3.new(0, 0.5, 0), { volume = 2.6, maxDistance = 170 })
					end
					if a >= 1 then
						break
					end
					RunService.Heartbeat:Wait()
				end
			end
		end
		for _, hip in hips do
			pcall(function()
				hip.joint.C0 = hip.base
			end)
		end
		return true
	end
	local function whisper(text)
		task.spawn(say, "sarpDemon", text, "Sarp")
	end

	-- Gefunden: Sarp steht plötzlich direkt vor einem, Jumpscare
	local function catchPlayer(player)
		caught[player] = true
		leaveSpot(player, false)
		local root = rootOf(player)
		if sarp and root then
			local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
			if look.Magnitude < 0.1 then
				look = Vector3.new(0, 0, -1)
			end
			local feet = root.Position - Vector3.new(0, footOffset(player), 0)
			local sarpFeet = feet + look.Unit * 2.6
			Wagners.place(sarp, sarpFeet, feet)
			SarpStage2.look(sarp, 0, 0.25)
		end
		local _, humanoid = rootOf(player)
		if humanoid then
			humanoid.WalkSpeed = 0
		end
		event:FireClient(player, { type = "jumpscare" })
		sfx("jumpscare", root and root.Position or ctx.frontDoor.position, { volume = 2, maxDistance = 60 })
		task.wait(1.6)
		event:FireClient(player, { type = "caught" })
		SarpStage2.look(sarp, 0, 0)
	end

	local function allCaught()
		for _, player in Players:GetPlayers() do
			if not caught[player] then
				return false
			end
		end
		return true
	end

	-- Eine Runde: Zeit zum Verstecken, dann kommt er
	local function hideRound(round)
		hidePhase = true
		setPrompts(true)
		event:FireAllClients({ type = "hint", text = round == 1 and "Versteck dich! Schnell!" or "Versteck dich – er kommt wieder!", seconds = 5 })
		event:FireAllClients({ type = "dim", level = 0.6, duration = 2 })
		for t = HIDE_TIME, 1, -1 do
			if t == 12 or t == 5 then
				event:FireAllClients({ type = "hint", text = "Noch " .. t .. " Sekunden …", seconds = 2 })
			end
			if t == 8 then
				sfx("heavyKnock", ctx.frontDoor.position, { count = 2, interval = 0.5, volume = 1.8, maxDistance = 300 })
			end
			task.wait(1)
		end
		-- die Haustür fliegt auf
		ctx.frontDoor.swing(ctx.frontDoor.open, 0.3, true)
		sfx("doorBurst", ctx.frontDoor.position, { volume = 2, maxDistance = 300 })
		event:FireAllClients({ type = "dim", level = 0.3, duration = 1.5 })
		local interruptedBy
		-- wer nicht versteckt ist (oder rauskommt), wird gefunden, solange er sucht
		local hunting = false
		local function interrupted()
			if hunting and not interruptedBy then
				for _, player in Players:GetPlayers() do
					if not caught[player] and not hidden[player] and rootOf(player) then
						interruptedBy = player
						break
					end
				end
			end
			return interruptedBy ~= nil
		end
		local function handleCatch()
			if interruptedBy then
				local player = interruptedBy
				catchPlayer(player)
				interruptedBy = nil
				return true
			end
			return false
		end

		-- er kommt durch Halle und Wohnzimmer
		Wagners.place(sarp, point(48, 70.5), point(48, 60))
		task.wait(0.6)
		whisper(Script.SARP_WHISPERS[1])
		-- solange er durch Halle und Wohnzimmer kommt, kann man sich noch verstecken
		local route = {
			{ points = { point(48, 66), point(52.5, 63), point(57, 62.5), point(60.5, 58), point(62, 46) } },
			{ action = "burst" },
			{ points = { point(62, 40), point(61, 34) } },
			{ search = "Tisch", points = { spots[2] and spots[2].search or point(63.4, 28) } },
			{ search = "Vorhang", points = { point(65, 24), spots[3] and spots[3].search or point(71, 19.8) } },
			{ search = "Schrank", points = { point(70, 26), point(72.5, 33), spots[1] and spots[1].search or point(75, 37.2) } },
			{ points = { point(68.5, 38.2), point(62, 39.5), point(62, 46), point(61, 52) } },
		}
		local stepIndex = 1
		while stepIndex <= #route and not allCaught() do
			local step = route[stepIndex]
			local completed = true
			if step.points then
				completed = sarpWalk(step.points, SARP_SPEED, interrupted)
			end
			local foundSomeone = handleCatch()
			if not completed or foundSomeone then
				-- nach dem Fund sucht er weiter (vom nächsten Punkt aus)
				task.wait(0.8)
				stepIndex += 1
				continue
			end
			if step.action == "burst" then
				-- ab jetzt sucht er: wer nicht versteckt ist, wird gefunden
				hunting = true
			end
			if step.action == "burst" and livingDoor then
				sfx("doorBurst", livingDoor.model.PrimaryPart.Position, { volume = 2, maxDistance = 200 })
				ctx.moveDoor(livingDoor, livingDoor.openAngle, 0.25)
				event:FireAllClients({ type = "dim", level = 0.22, duration = 1 })
			end
			if step.search then
				-- vor dem Versteck stehen bleiben, hineinschauen, atmen
				local spot
				for _, candidate in spots do
					if candidate.name == step.search then
						spot = candidate
					end
				end
				if spot and sarp then
					local target = spot.place.Position
					Wagners.place(sarp, Wagners.ground(sarp), Vector3.new(target.X, Wagners.ground(sarp).Y, target.Z))
					SarpStage2.look(sarp, 0, spot.kind == "lie" and 0.9 or 0.15)
					sfx("sarpBreath", target + Vector3.new(0, 2, 0), { volume = 1.4, maxDistance = 30 })
					if spot.occupant then
						event:FireClient(spot.occupant, { type = "nearScare", seconds = 3.5 })
						whisper(Script.SARP_WHISPERS[math.random(2, #Script.SARP_WHISPERS)])
					end
					local waitUntil = os.clock() + 3.5
					while os.clock() < waitUntil and not interrupted() do
						task.wait(0.1)
					end
					SarpStage2.look(sarp, 0, 0)
					if handleCatch() then
						task.wait(0.8)
					end
				end
			end
			stepIndex += 1
		end
		hunting = false
		if not allCaught() then
			whisper(Script.SARP_LEAVES)
			task.wait(0.5)
		end
		if sarp then
			Wagners.place(sarp, away, ctx.facing)
		end
		sfx("doorSlam", ctx.frontDoor.position, { volume = 1.2, maxDistance = 300 })
		hidePhase = false
		setPrompts(false)
		return not allCaught()
	end

	-- Alles zurück auf Anfang der Versteck-Runde (nach dem Gefundenwerden)
	local function resetRound()
		for _, player in Players:GetPlayers() do
			leaveSpot(player, false)
		end
		for index, player in Players:GetPlayers() do
			caught[player] = nil
			local root, humanoid = rootOf(player)
			if root and humanoid then
				root.Anchored = false
				humanoid.PlatformStand = false
				humanoid.AutoRotate = true
				humanoid.WalkSpeed = WALK_SPEED
				local feet = point(62 + index, 36)
				player.Character:PivotTo(CFrame.lookAt(feet + Vector3.new(0, footOffset(player), 0), point(67, 30) + Vector3.new(0, footOffset(player), 0)))
			end
			event:FireClient(player, { type = "retry" })
		end
		ctx.frontDoor.set(0)
		if livingDoor and livingDoor.angle > 0 then
			ctx.moveDoor(livingDoor, 0, 0.2)
		end
	end

	local survived = afterHide
	for round = 1, afterHide and 0 or MAX_ROUNDS do
		survived = hideRound(round)
		if survived then
			break
		end
		task.wait(2.5)
		resetRound()
		task.wait(2)
	end

	------------------------------------------------------------------ 4. Allein im Haus
	-- wer gefunden wurde, wacht wieder auf; alle dürfen aus den Verstecken
	for _, player in Players:GetPlayers() do
		if caught[player] then
			caught[player] = nil
			local _, humanoid = rootOf(player)
			if humanoid then
				humanoid.WalkSpeed = WALK_SPEED
			end
			event:FireClient(player, { type = "retry" })
		end
	end
	setPrompts(true)
	hidePhase = false
	for _, spot in spots do
		if spot.promptObject then
			spot.promptObject.ActionText = spot.occupant and "Rauskommen" or "Verstecken"
		end
	end
	if kitchenDoor then
		kitchenDoor.locked = false
	end
	if livingDoor then
		livingDoor.locked = false
	end
	task.wait(2)
	event:FireAllClients({ type = "hint", text = "Er ist weg … fürs Erste.", seconds = 4 })
	task.wait(3)

	------------------------------------------------------------------ 5. Richard kommt zurück
	function actions.richardComes()
		if kitchenDoor then
			kitchenDoor.locked = false
			if kitchenDoor.angle == 0 then
				sfx("doorCreak", kitchenDoor.model.PrimaryPart.Position, { volume = 0.6 })
				ctx.moveDoor(kitchenDoor, kitchenDoor.openAngle, 0.9)
			end
		end
		if mr then
			Wagners.place(mr, point(48, 38.2), point(60, 36))
			ctx.walkPath(mr, { P(52, 38.2), P(57, 38), P(60, 36.5) }, 4.5, steps)
			Wagners.place(mr, point(60, 36.5), point(66, 32))
			mr:SetAttribute("Look", "player")
		end
	end
	function actions.richardLeaves()
		if mr then
			mr:SetAttribute("Look", "down")
			ctx.walkPath(mr, { P(57, 38), P(51, 38.2), P(46, 37) }, 6, steps)
			Wagners.place(mr, ctx.hiddenSpot, ctx.facing)
		end
	end
	ctx.runScript(Script.NIGHT_RICHARD, "Richard")

	------------------------------------------------------------------ 6. Axt holen, Tür 1 aufbrechen
	-- (Sarp läuft dabei durchs Erdgeschoss; jetzt ist er nicht mehr tödlich, nur unheimlich)
	local doneWithNight = false
	local axeHolder
	local function giveAxe(player)
		local character = player.Character
		local hand = character and (character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"))
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (hand and root) or character:FindFirstChild("PlayerAxe") then
			return
		end
		local model = Instance.new("Model")
		model.Name = "PlayerAxe"
		local base = CFrame.new(hand.Position) * root.CFrame.Rotation * CFrame.new(0, -0.1, -0.2) * CFrame.Angles(math.rad(-70), 0, 0)
		local function piece(name, size, offset, color, material)
			local part = Instance.new("Part")
			part.Name = name
			part.Size = size
			part.CFrame = base * offset
			part.Color = color
			part.Material = material
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
			part.Parent = model
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hand
			weld.Part1 = part
			weld.Parent = part
		end
		piece("AxeHandle", Vector3.new(0.14, 2.6, 0.14), CFrame.new(0, 0.9, 0), Color3.fromRGB(120, 86, 52), Enum.Material.Wood)
		piece("AxeHead", Vector3.new(0.1, 0.55, 0.85), CFrame.new(0, 2.05, 0.28), Color3.fromRGB(110, 112, 116), Enum.Material.Metal)
		model.Parent = character
	end
	local axe = Mansion.axe
	local axePart = axe and axe.PrimaryPart
	if axePart then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Axt"
		prompt.ActionText = "Nehmen"
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 7
		prompt.RequiresLineOfSight = false
		prompt.Parent = axePart
		prompt.Triggered:Connect(function(player)
			if axeHolder then
				return
			end
			axeHolder = player
			axe.Parent = nil
			giveAxe(player)
			sfx("doorCreak", axePart.Position, { volume = 0.4, speed = 1.6 })
			event:FireAllClients({ type = "hint", text = player.DisplayName .. " hat die Axt. Jetzt nach oben zu Tür 1.", seconds = 6 })
			pcall(function()
				-- nach dem Neuspawnen die Axt wieder in die Hand geben
				player.CharacterAdded:Connect(function()
					task.wait(1)
					if axeHolder == player and not doneWithNight then
						giveAxe(player)
					end
				end)
			end)
		end)
	end

	-- Tür 1 (oben an der Galerie, vernagelt) mit der Axt aufbrechen
	local doorOne = Mansion.doorAt(46.8, 54.15, "O")
	local broken = false
	local function breakDoor(player)
		if broken or not doorOne then
			return
		end
		broken = true
		local origin = Mansion.origin
		local middle = origin * (doorOne.middle + Vector3.new(0, O + 4, 0))
		event:FireAllClients({ type = "hint", text = player.DisplayName .. " bricht die Tür auf …", seconds = 4 })
		for i = 1, 5 do
			sfx("doorBurst", middle, { volume = 1.2, speed = 1.2 + i * 0.05, maxDistance = 200 })
			task.wait(0.75)
			-- nach und nach fallen die Bretter ab
			if i >= 2 then
				for _, part in Mansion.model:GetDescendants() do
					if part:IsA("BasePart") and part.Name == "Board" and part.Anchored then
						local offset = part.Position - middle
						if math.abs(offset.Y) < 6 and Vector3.new(offset.X, 0, offset.Z).Magnitude < 3 and math.random() < 0.5 then
							part.Anchored = false
							part.CanCollide = true
						end
					end
				end
			end
		end
		for _, part in Mansion.model:GetDescendants() do
			if part:IsA("BasePart") and part.Name == "Board" and part.Anchored then
				local offset = part.Position - middle
				if math.abs(offset.Y) < 6 and Vector3.new(offset.X, 0, offset.Z).Magnitude < 3 then
					part.Anchored = false
					part.CanCollide = true
				end
			end
		end
		doorOne.locked = false
		sfx("doorSlam", middle, { volume = 1.4 })
		ctx.moveDoor(doorOne, doorOne.openAngle, 0.35)
		event:FireAllClients({ type = "hint", text = "Die Tür ist offen. Geh hinein.", seconds = 5 })
		ctx.remotes:SetAttribute("Phase", "doorOne")
		-- sobald jemand den Raum hinter Tür 1 betritt: alles schwarz
		local deadline = os.clock() + 180
		while os.clock() < deadline do
			local inside = false
			for _, other in Players:GetPlayers() do
				local root = rootOf(other)
				if root and Mansion.inRoom(root.Position, "tuer1", "O") then
					inside = true
				end
			end
			if inside then
				break
			end
			task.wait(0.2)
		end
		doneWithNight = true
		ctx.setMovement(false)
		event:FireAllClients({ type = "alone", instant = true, title = "Hinter Tür 1 …", subtitle = "Fortsetzung folgt" })
		print("Kapitel 2: Jemand ist in Raum hinter Tür 1 gegangen – Bild schwarz (hier geht es später weiter).")
	end
	if doorOne then
		doorOne.onLocked = function(player)
			if broken then
				return true
			end
			if player == axeHolder then
				task.spawn(breakDoor, player)
			else
				event:FireClient(player, { type = "hint", text = "Vernagelt. Mit einer Axt könnte man die Bretter aufbrechen.", seconds = 3 })
			end
			return true
		end
	end

	event:FireAllClients({ type = "hint", text = "Hol die Axt aus dem Keller (Kellertür in der Küche).", seconds = 7 })

	-- Sarp läuft durchs Erdgeschoss. Sieht er jemanden mit Licht, verfolgt er ihn und macht
	-- Schaden, wenn er nah genug ist. Man kann weglaufen – oder das Licht ausmachen (F):
	-- dann verliert er einen aus den Augen und geht wieder weg.
	local patrolDoors = { Mansion.doorAt(51.4, 54.15, "E"), Mansion.doorAt(44, 42, "E"), kitchenDoor, livingDoor, Mansion.doorAt(54.25, 63, "E") }
	for _, door in patrolDoors do
		if door and door.angle == 0 then
			door.locked = false
			task.spawn(ctx.moveDoor, door, door.openAngle, 0.6)
		end
	end
	local PATROL = {
		point(48, 66), point(51.4, 58), point(51.4, 50), point(44, 46), point(44, 38), point(52, 38), point(57, 38),
		point(62, 36), point(62, 40), point(62, 46), point(60.5, 58), point(57, 62.5), point(52.5, 63),
	}
	local SEE_DISTANCE = 26
	local CHASE_SPEED = 6.6 -- etwas langsamer als man selbst läuft (8)
	local HIT_DISTANCE = 3.6
	local HIT_DAMAGE = 25
	local function lightOn(player)
		return not player:GetAttribute("LightOff")
	end
	local function canSee(player, distanceLimit)
		local root = rootOf(player)
		local sarpRoot = sarp and sarp:FindFirstChild("HumanoidRootPart")
		local _, humanoid = rootOf(player)
		if not (root and sarpRoot and humanoid) or humanoid.Health <= 0 or hidden[player] then
			return false
		end
		local eye = sarpRoot.Position + Vector3.new(0, 2.5, 0)
		local offset = root.Position - eye
		if offset.Magnitude > (distanceLimit or SEE_DISTANCE) or math.abs(root.Position.Y - Wagners.ground(sarp).Y - 3) > 7 then
			return false
		end
		local visible = true
		pcall(function()
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { sarp, player.Character }
			local hit = workspace:Raycast(eye, offset, params)
			-- Türblätter und Kleinkram zählen nicht als Sichtschutz, Wände schon
			visible = hit == nil or not hit.Instance.Anchored or hit.Instance.Name:find("Door") ~= nil
		end)
		return visible
	end
	-- Wen sieht er gerade? Ohne Licht sieht er einen gar nicht.
	local function findTarget()
		for _, player in Players:GetPlayers() do
			if lightOn(player) and canSee(player, SEE_DISTANCE) then
				return player
			end
		end
		return nil
	end
	-- Weg zum Ziel: Roblox-Wegfindung (Treppen, Türen); wenn das nicht geht, gerade aus
	local PathfindingService
	pcall(function()
		PathfindingService = game:GetService("PathfindingService")
	end)
	local function nextWaypoint(from, to)
		if PathfindingService then
			local ok, result = pcall(function()
				local path = PathfindingService:CreatePath({ AgentRadius = 1.5, AgentHeight = 7, AgentCanJump = false })
				path:ComputeAsync(from, to)
				if path.Status == Enum.PathStatus.Success then
					local points = path:GetWaypoints()
					return points[math.min(3, #points)] and points[math.min(3, #points)].Position
				end
				return nil
			end)
			if ok and result then
				return result
			end
		end
		return to
	end
	local hitCooldown = {}
	local function chase(player)
		event:FireClient(player, { type = "chased" })
		whisper(Script.SARP_WHISPERS[math.random(1, #Script.SARP_WHISPERS)])
		local lostSince
		local giveUpAt = os.clock() + 40
		while not doneWithNight and os.clock() < giveUpAt do
			local root, humanoid = rootOf(player)
			if not (root and humanoid) or humanoid.Health <= 0 then
				break
			end
			-- Licht aus oder außer Sicht: er verliert einen nach kurzer Zeit
			local seen = lightOn(player) and canSee(player, SEE_DISTANCE + 8)
			if seen then
				lostSince = nil
			else
				lostSince = lostSince or os.clock()
				if os.clock() - lostSince > (lightOn(player) and 4 or 0.6) then
					break
				end
			end
			local feet = Wagners.ground(sarp)
			local target = root.Position - Vector3.new(0, footOffset(player), 0)
			local distance = (target - feet).Magnitude
			if distance <= HIT_DISTANCE then
				Wagners.place(sarp, feet, target)
				if os.clock() > (hitCooldown[player] or 0) then
					hitCooldown[player] = os.clock() + 1.3
					humanoid:TakeDamage(HIT_DAMAGE)
					sfx("jumpscare", root.Position, { volume = 1.2, maxDistance = 40, speed = 1.3 })
					event:FireClient(player, { type = "hurt", health = humanoid.Health })
				end
				RunService.Heartbeat:Wait()
			else
				local waypoint = nextWaypoint(feet, target)
				sarpWalk({ waypoint }, CHASE_SPEED, function()
					return (os.clock() - (lostSince or os.clock())) > 0.5
				end)
			end
		end
		event:FireClient(player, { type = "lost" })
		-- stehen bleiben, lauschen, dann weiter
		SarpStage2.look(sarp, 0.5, 0)
		task.wait(1)
		SarpStage2.look(sarp, -0.5, 0)
		task.wait(1)
		SarpStage2.look(sarp, 0, 0)
	end
	if sarp then
		Wagners.place(sarp, PATROL[1], PATROL[2])
		event:FireAllClients({ type = "hint", text = "F: Licht aus/an. Ohne Licht sieht er dich nicht – du ihn aber auch kaum.", seconds = 8 })
		task.spawn(function()
			local index = 1
			while not doneWithNight and sarp.Parent do
				local target = PATROL[index % #PATROL + 1]
				local seenPlayer
				local reached = sarpWalk({ target }, 3.6, function()
					seenPlayer = findTarget()
					return seenPlayer ~= nil
				end)
				if seenPlayer then
					chase(seenPlayer)
					-- zurück zum nächsten Punkt seiner Runde
					local feet = Wagners.ground(sarp)
					local nearest, nearestDistance = index, math.huge
					for i, p in PATROL do
						local d = (p - feet).Magnitude
						if d < nearestDistance then
							nearest, nearestDistance = i, d
						end
					end
					index = nearest
				elseif reached then
					index = index % #PATROL + 1
				end
			end
			Wagners.place(sarp, away, ctx.facing)
		end)
	end

	-- Die Familie geistert durchs Haus: steht irgendwo in der Ferne, sagt etwas Seltsames,
	-- und rennt weg und verschwindet, sobald man ihr zu nahe kommt
	local APPEAR = {
		{ 46, 63, "E" }, { 38, 50, "E" }, { 24, 52, "E" }, { 70, 63, "E" }, { 42, 28, "E" },
		{ 49, 57.5, "O" }, { 70, 37, "O" }, { 64, 64, "O" }, { 49, 27, "O" }, { 39, 27, "O" },
		{ 24, 46, "K" }, { 40, 38, "K" }, { 62, 30, "K" },
	}
	local LINES = {
		mrsWagner = { "You shouldn't be up so late.", "Dinner isn't over yet.", "He is so proud of you." },
		lucy = { "Do you want to see my room?", "Mommy says you'll stay forever.", "Shhh. He's listening." },
		tommy = { "I drew you today.", "Can you hear the walls?", "Don't open the first door." },
	}
	local members = { mrsWagner = mrs, lucy = lucy, tommy = tommy }
	local function nearestPlayer(position)
		local best, bestDistance
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and math.abs(root.Position.Y - position.Y - 3) < 7 then
				local distance = (root.Position - position).Magnitude
				if not bestDistance or distance < bestDistance then
					best, bestDistance = player, distance
				end
			end
		end
		return best, bestDistance
	end
	task.spawn(function()
		task.wait(12)
		local lastSpot
		while not doneWithNight do
			-- wer erscheint, und wo (nicht direkt neben einem Spieler)
			local names = {}
			for name, model in members do
				if model then
					table.insert(names, name)
				end
			end
			if #names == 0 then
				break
			end
			local name = names[math.random(1, #names)]
			local model = members[name]
			local spot
			for _ = 1, 12 do
				local candidate = APPEAR[math.random(1, #APPEAR)]
				local feet = point(candidate[1], candidate[2], candidate[3])
				local _, distance = nearestPlayer(feet)
				if candidate ~= lastSpot and (not distance or distance > 18) then
					spot = feet
					lastSpot = candidate
					break
				end
			end
			if spot then
				local player = nearestPlayer(spot)
				local root = player and rootOf(player)
				Wagners.place(model, spot, root and Vector3.new(root.Position.X, spot.Y, root.Position.Z) or spot + Vector3.new(0, 0, 1))
				model:SetAttribute("Look", "player")
				local spoke = false
				local shownUntil = os.clock() + 40
				while os.clock() < shownUntil and not doneWithNight do
					local near, distance = nearestPlayer(spot)
					if near and distance < 24 and not spoke then
						spoke = true
						local lines = LINES[name]
						task.spawn(say, name, lines[math.random(1, #lines)])
					end
					if near and distance < 10 then
						-- wegrennen und verschwinden
						local nearRoot = rootOf(near)
						local away = (spot - nearRoot.Position) * Vector3.new(1, 0, 1)
						away = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
						model:SetAttribute("Look", "down")
						sfx("stepWood", spot + Vector3.new(0, 0.5, 0), { count = 4, interval = 0.18, volume = 0.9 })
						ctx.walkPath(model, { { at = spot + away * 5 } }, 16)
						event:FireClient(near, { type = "candleOut", duration = 0.4 })
						break
					end
					task.wait(0.25)
				end
				Wagners.place(model, ctx.hiddenSpot, ctx.facing)
			end
			task.wait(math.random(14, 26))
		end
	end)
end

return Night
