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
		return Mansion.point(x, y, floorKey == "O" and O or E)
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

	------------------------------------------------------------------ 1. Aufwachen
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
	-- Mrs. Wagner steht in der Tür vom Gästezimmer, Mr. Wagner wartet am Esstisch
	if mrs then
		Wagners.place(mrs, point(51.4, 52.6, "O"), point(51.4, 45, "O"))
		mrs:SetAttribute("Look", "player")
	end
	if mr then
		Wagners.place(mr, point(67, 40.9), point(67, 30))
		mr:SetAttribute("Look", "down")
	end
	ctx.remotes:SetAttribute("Phase", "wake")
	event:FireAllClients({ type = "wake" })
	task.wait(3)

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
				Wagners.place(mrs, point(62.6, 26.5), point(67, 26.5))
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
		for _, npc in { mrs, mr } do
			if npc then
				npc:SetAttribute("Look", "down")
			end
		end
		local done = 0
		task.spawn(function()
			ctx.walkPath(mrs, { P(60, 34), P(57, 38), P(51, 38), P(46, 36) }, 10, steps)
			done += 1
		end)
		task.spawn(function()
			ctx.walkPath(mr, { P(61, 40), P(57, 38.4), P(51, 38.4), P(46, 37) }, 10, steps)
			done += 1
		end)
		local deadline = os.clock() + 8
		while done < 2 and os.clock() < deadline do
			task.wait(0.1)
		end
		for _, npc in { mrs, mr } do
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

	ctx.runScript(Script.NIGHT_WAKE, "Aufwachen")
	ctx.runScript(Script.NIGHT_DINNER, "Abendessen")

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
						sfx("sarpStep", position + Vector3.new(0, 0.5, 0), { volume = 1.1, maxDistance = 90 })
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

	local survived = false
	for round = 1, MAX_ROUNDS do
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
	task.wait(3)
	ctx.remotes:SetAttribute("Phase", "alone")
	event:FireAllClients({ type = "alone" })
	print("Kapitel 2: Sarp ist weg – man ist allein im Haus (hier geht es später weiter).")
end

return Night
