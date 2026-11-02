-- Kapitel 2 auf dem Server (gestartet von Main.server.lua): Man steht vor der Haustür der Wagners (wie am Ende von
-- Kapitel 1). Wer an die Tür klopft, startet die Begrüßung: Mrs. Wagner öffnet erst
-- einen Spalt, dann ganz; ihr Mann steht plötzlich hinter ihr. Sie bitten einen herein,
-- man geht selbst hinein und die Tür fällt zu. Texte und Ablauf: Shared/Kapitel2Dialogue.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Dialogue = require(ReplicatedStorage.Shared.Dialogue)
local Script = require(ReplicatedStorage.Shared.Kapitel2Dialogue)
local Route = require(ReplicatedStorage.Shared.LevelRoute)
local ForestWalk = require(script.Parent.ForestWalk)
local House = require(script.Parent.House)
local HouseInterior = require(script.Parent.HouseInterior)
local Mansion = require(script.Parent.Mansion)
local Wagners = require(script.Parent.Wagners)
local World = require(script.Parent.World)

local Kapitel2 = {}

local CHOICE_TIMEOUT = 25 -- danach wird automatisch die erste Antwort genommen
local GAP = 0.4 -- Pause zwischen zwei Sätzen
local WAIT_FOR_GROUP = 10 -- Sekunden, die auf den zweiten Spieler gewartet wird
local WALK_SPEED = 8 -- im Haus etwas langsamer
local DOOR_CRACK, DOOR_OPEN = math.rad(14), math.rad(88)
local REMIND_AFTER, PULL_IN_AFTER = 18, 40 -- Sekunden, wenn jemand draußen bleibt

-- Stellen in der Eingangshalle (x, z relativ zum Haus)
local SPOTS = {
	mrsStart = Vector2.new(0.2, -12.9), -- direkt hinter der Tür
	mrsBack = Vector2.new(-0.6, -10.2), -- außerhalb der aufgehenden Tür
	mrBehind = Vector2.new(-2.5, -8.7), -- plötzlich hinter ihr
	mrsInside = Vector2.new(1.6, -8),
	mrInside = Vector2.new(-3.2, -6.4), -- am Fuß der Treppe
	pullIn = Vector2.new(-1.6, -10),
}

local function hall(spot)
	return Route.housePoint(spot.X, spot.Y) + Vector3.new(0, HouseInterior.FLOOR, 0)
end

function Kapitel2.start()
	-- Gespräch: Server → Clients (Sätze, Auswahl, Geräusche) und zurück (Antwort).
	-- Wird zuerst angelegt, damit die Spieler gleich sehen, dass gebaut wird.
	-- Das Attribut "Status" zeigt der Ladebildschirm an.
	local remotes = Instance.new("Folder")
	remotes.Name = "Kapitel2"
	remotes:SetAttribute("Status", "Das Haus wird gebaut …")
	local event = Instance.new("RemoteEvent")
	event.Name = "SceneEvent"
	event.Parent = remotes
	local choiceEvent = Instance.new("RemoteEvent")
	choiceEvent.Name = "SceneChoice"
	choiceEvent.Parent = remotes
	remotes.Parent = ReplicatedStorage

	House.mansion = true -- das große Herrenhaus statt des kleinen Holzhauses
	print("Kapitel 2: Welt und Haus werden gebaut …")
	local buildStarted = os.clock()
	local ok, problem = xpcall(function()
		World.build()
		task.wait()
		local removed = Mansion.clearAround(workspace:FindFirstChild("Level1"))
		print(string.format("Kapitel 2: Welt fertig nach %.1f s (%d Bäume und Teile ums Haus entfernt).", os.clock() - buildStarted, removed or 0))
	end, debug.traceback)
	local house = workspace:FindFirstChild("WagnerHouse", true)
	local doorModel = house and house:FindFirstChild("FrontDoor")
	if not ok or not (doorModel and doorModel.PrimaryPart) then
		local text = tostring(problem or "Haus oder Haustür fehlt")
		warn("Kapitel 2: FEHLER beim Bauen der Welt – bitte diese Meldung an Claude schicken:\n" .. text)
		remotes:SetAttribute("Status", "Fehler beim Bauen (siehe Output):\n" .. (text:match("[^\n]+") or text))
		return
	end
	remotes:SetAttribute("Status", "Die Wagners werden geweckt …")

	local origin = Route.houseCFrame()
	local hingeCF = doorModel.PrimaryPart.CFrame
	local facing = Route.housePoint(-2, -20) -- die Wagners schauen zur Tür hinaus


	------------------------------------------------------------------ Die Wagners
	local family = Instance.new("Folder")
	family.Name = "Wagners"
	family.Parent = workspace
	-- Geht beim Bauen einer Figur etwas schief, läuft das Kapitel trotzdem weiter
	-- (der Fehler steht dann im Output)
	local function build(name, builder)
		local ok, result = xpcall(builder, debug.traceback, family)
		if not ok then
			warn("Kapitel 2: " .. name .. " konnte nicht gebaut werden:\n" .. tostring(result))
			return nil
		end
		return result
	end
	-- eigene Figuren aus ServerStorage.Wagners, sonst die eingebauten
	local mrs = build("Mrs. Wagner", function(folder)
		return Wagners.fromStudio("MrsWagner", folder) or Wagners.buildMrs(folder)
	end)
	local mr = build("Mr. Wagner", function(folder)
		return Wagners.fromStudio("MrWagner", folder) or Wagners.buildMr(folder)
	end)
	local hiddenSpot = Route.housePoint(-2, -6) - Vector3.new(0, 80, 0)
	if mrs then
		Wagners.place(mrs, hall(SPOTS.mrsStart), facing)
		mrs:SetAttribute("Look", "player")
	end
	-- Mr. Wagner wartet in der Küche und kommt während des Gesprächs zur Tür
	local function plan(x, y)
		return Vector2.new(x - 50, 57.4 - y) -- Bauplan -> Hallen-Koordinaten
	end
	local KITCHEN_TO_DOOR = { plan(44, 38), plan(44, 46), plan(51.4, 50), plan(51.4, 58), SPOTS.mrBehind }
	if mr then
		local start = hall(plan(46.5, 38))
		Wagners.place(mr, start, start + Vector3.new(-1, 0, 0))
		mr:SetAttribute("Look", "down")
	end
	local npcs = { mrsWagner = mrs, mrWagner = mr }

	-- Die Kinder (Lucy und Tommy) stehen erst später im Haus – Wagners.buildLucy und
	-- Wagners.buildTommy sind dafür schon fertig.

	-- Langsam rückwärts oder seitlich gleiten, Blick immer zur Tür (läuft nebenher)
	local function glide(npc, target, duration)
		if not npc then
			return
		end
		local from = Wagners.ground(npc)
		local hips = {}
		for _, name in { "LeftUpperLeg", "RightUpperLeg" } do
			local part = npc:FindFirstChild(name)
			local joint = part and part:FindFirstChildOfClass("Motor6D")
			if joint then
				table.insert(hips, { joint = joint, base = joint.C0 })
			end
		end
		task.spawn(function()
			local start = os.clock()
			while true do
				local elapsed = os.clock() - start
				local a = math.min(elapsed / duration, 1)
				local position = from:Lerp(target, a * a * (3 - 2 * a))
				Wagners.place(npc, position, facing)
				for index, hip in hips do
					local swing = a < 1 and math.sin(elapsed * 6 + index * math.pi) * 0.3 or 0
					pcall(function()
						hip.joint.C0 = hip.base * CFrame.Angles(swing, 0, 0)
					end)
				end
				if a >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
		end)
	end

	-- Gehen entlang mehrerer Punkte (Hallen-Koordinaten), Blick in Gehrichtung
	local function walkPath(npc, spots, speed, onStep)
		if not npc then
			return
		end
		local nextStep = 0
		local hips = {}
		for _, name in { "LeftUpperLeg", "RightUpperLeg" } do
			local part = npc:FindFirstChild(name)
			local joint = part and part:FindFirstChildOfClass("Motor6D")
			if joint then
				table.insert(hips, { joint = joint, base = joint.C0 })
			end
		end
		local position = Wagners.ground(npc)
		for _, spot in spots do
			local target = hall(spot)
			local distance = (target - position).Magnitude
			if distance > 0.05 then
				local direction = (target - position).Unit
				local from = position
				local start = os.clock()
				while true do
					local a = math.min((os.clock() - start) * speed / distance, 1)
					position = from:Lerp(target, a)
					Wagners.place(npc, position, position + direction)
					if onStep and os.clock() >= nextStep then
						nextStep = os.clock() + 0.55
						onStep(position)
					end
					for index, hip in hips do
						pcall(function()
							hip.joint.C0 = hip.base * CFrame.Angles(math.sin(os.clock() * 7 + index * math.pi) * 0.35, 0, 0)
						end)
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
	end

	------------------------------------------------------------------ Haustür
	local doorAngle = 0
	local function setDoor(angle)
		doorAngle = angle
		doorModel:PivotTo(hingeCF * CFrame.Angles(0, -angle, 0))
	end
	-- Tür drehen (wartet, bis sie fertig ist). `slam` = immer schneller werdend
	local function swingDoor(target, duration, slam)
		local from = doorAngle
		local start = os.clock()
		while true do
			local a = math.min((os.clock() - start) / duration, 1)
			local eased = slam and a * a or a * a * (3 - 2 * a)
			setDoor(from + (target - from) * eased)
			if a >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
	end
	local doorFront = (origin * CFrame.new(-2, House.BASE + 4.5, -Route.HOUSE_SIZE.Z / 2 - 0.6)).Position

	------------------------------------------------------------------ Spieler
	local frozen = false
	local inside = false -- Tür ist hinter allen zu
	local function setMovement(enabled)
		frozen = not enabled
		for _, player in Players:GetPlayers() do
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = enabled and WALK_SPEED or 0
				humanoid.JumpHeight = enabled and 2 or 0
			end
		end
	end

	-- Eigene Kerze in der Hand (bekommt man von Mrs. Wagner). Die anderen sehen sie an
	-- der Hand, man selbst sieht sie unten links im Bild (macht Scene.lua auf dem Client).
	local candlesGiven = false
	local function giveCandle(player)
		local character = player.Character
		local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (hand and root) or character:FindFirstChild("PlayerCandle") then
			return
		end
		local model = Instance.new("Model")
		model.Name = "PlayerCandle"
		local base = CFrame.new(hand.Position) * root.CFrame.Rotation * CFrame.new(0, -0.2, -0.35)
		local function piece(name, shape, size, cframe, color, material)
			local part = Instance.new("Part")
			part.Name = name
			part.Shape = shape
			part.Size = size
			part.CFrame = cframe
			part.Color = color
			part.Material = material
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
			part.CastShadow = false
			part.Parent = model
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hand
			weld.Part1 = part
			weld.Parent = part
			return part
		end
		local upright = CFrame.Angles(0, 0, math.rad(90)) -- Zylinder stehen in Roblox auf der Seite
		piece("CandleHolder", Enum.PartType.Cylinder, Vector3.new(0.12, 0.6, 0.6), base * upright, Color3.fromRGB(120, 96, 52), Enum.Material.Metal)
		piece("Candle", Enum.PartType.Cylinder, Vector3.new(0.8, 0.22, 0.22), base * CFrame.new(0, 0.46, 0) * upright, Color3.fromRGB(225, 215, 190), Enum.Material.SmoothPlastic)
		local flame = piece("CandleFlame", Enum.PartType.Ball, Vector3.new(0.16, 0.16, 0.16), base * CFrame.new(0, 0.95, 0), Color3.fromRGB(255, 170, 70), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Name = "CandleLight"
		light.Range = 16
		light.Brightness = 1.3
		light.Color = Color3.fromRGB(255, 180, 110)
		light.Shadows = true
		light.Parent = flame
		model.Parent = character
	end

	local function spawnPlayer(player)
		local index = table.find(Players:GetPlayers(), player) or 1
		local cframe
		if inside then
			local spot = hall(SPOTS.pullIn) + Vector3.new(index * 1.5 - 2, 0, 0)
			cframe = CFrame.lookAt(spot, Vector3.new(facing.X, spot.Y, facing.Z))
		else
			cframe = Route.doorSpawn(index)
		end
		ForestWalk.spawnWalker(player, cframe)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = frozen and 0 or WALK_SPEED
			humanoid.JumpHeight = frozen and 0 or 2
			if candlesGiven then
				giveCandle(player)
			end
			humanoid.Died:Connect(function()
				task.delay(3, function()
					if player.Parent then
						spawnPlayer(player)
					end
				end)
			end)
		end
	end

	-- Steht jemand noch draußen (oder dort, wo die Tür zufällt)?
	local hinge = Vector2.new(House.DOOR_HINGE.X, House.DOOR_HINGE.Z)
	local function isInside(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root then
			return true
		end
		local p = origin:Inverse() * root.Position
		-- irgendwo im Haus (nicht nur in der Halle) und nicht dort, wo die Tür zufällt
		local inHouse = Mansion.isInside(root.Position)
		local dx, dz = p.X - hinge.X, p.Z - hinge.Y
		return inHouse and math.sqrt(dx * dx + dz * dz) > 4.8
	end

	------------------------------------------------------------------ Sprechen und Antworten
	local duo = false
	local knocker
	local function say(speaker, entry, name)
		local text = Dialogue.text(entry, duo)
		local voice = Config.VOICES and Config.VOICES[speaker] or {}
		local duration = Dialogue.duration(text, voice.speed)
		event:FireAllClients({ type = "line", speaker = speaker, name = name or Script.NAMES[speaker] or "", text = text, duration = duration })
		task.wait(duration + GAP)
	end

	local function ask(options)
		local chooser = (knocker and knocker.Parent) and knocker or Players:GetPlayers()[1]
		local texts = {}
		for i, option in options do
			texts[i] = Dialogue.text(option.text, duo)
		end
		local picked
		local connection = choiceEvent.OnServerEvent:Connect(function(player, index)
			if player == chooser and not picked and type(index) == "number" and options[index] then
				picked = index
			end
		end)
		event:FireAllClients({ type = "choice", options = texts, chooser = chooser and chooser.UserId, timeout = CHOICE_TIMEOUT })
		local deadline = os.clock() + CHOICE_TIMEOUT
		while not picked and os.clock() < deadline and chooser and chooser.Parent do
			task.wait(0.1)
		end
		connection:Disconnect()
		picked = picked or 1
		event:FireAllClients({ type = "chosen", index = picked })
		return picked, chooser
	end

	local function sfx(key, position, options)
		local message = { type = "sfx", key = key, position = position }
		for k, v in options or {} do
			message[k] = v
		end
		event:FireAllClients(message)
	end

	------------------------------------------------------------------ Türen im Haus
	-- Jede Innentür kann man mit E öffnen und schließen; abgeschlossene Türen rütteln nur.
	-- Tür auf- oder zudrehen (wartet, bis sie fertig ist)
	local function moveDoor(door, target, duration)
		if door.moving or not door.model then
			return
		end
		door.moving = true
		local from = door.angle
		local start = os.clock()
		while true do
			local a = math.min((os.clock() - start) / (duration or 0.7), 1)
			door.angle = from + (target - from) * (a * a * (3 - 2 * a))
			door.model:PivotTo(door.frame(door.angle))
			if a >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		if door.prompt then
			door.prompt.ActionText = target > 0 and "Schließen" or "Öffnen"
		end
		door.moving = false
	end

	local function setupDoors()
		for _, door in Mansion.doors do
			local leaf = door.model and door.model.PrimaryPart
			if leaf then
				local prompt = Instance.new("ProximityPrompt")
				prompt.ObjectText = "Tür"
				prompt.ActionText = door.locked and "Öffnen" or (door.angle > 0 and "Schließen" or "Öffnen")
				prompt.HoldDuration = 0
				prompt.MaxActivationDistance = 7
				prompt.RequiresLineOfSight = false
				prompt.Style = Enum.ProximityPromptStyle.Default
				prompt.Parent = leaf
				door.prompt = prompt
				prompt.Triggered:Connect(function(player)
					if door.moving then
						return
					end
					if door.locked then
						sfx("knock", leaf.Position, { count = 2, interval = 0.13, volume = 0.5 })
						event:FireClient(player, { type = "hint", text = "Abgeschlossen.", seconds = 2 })
						return
					end
					sfx("doorCreak", leaf.Position, { volume = 0.45 })
					moveDoor(door, door.angle > 0 and 0 or door.openAngle)
				end)
			end
		end
	end

	------------------------------------------------------------------ Schlafen
	-- In den Betten im Gästezimmer kann man sich hinlegen (E). Liegen alle, schlafen sie
	-- ein – hier geht es später mit der Nacht weiter.
	local lying = {} -- Spieler -> Bett
	local asleep = false
	local exploring = false
	local function standUp(player)
		local bed = lying[player]
		lying[player] = nil
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if bed then
			bed.taken = nil
			if bed.prompt then
				bed.prompt.ActionText = "Schlafen gehen"
			end
		end
		if root and humanoid then
			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
			humanoid.WalkSpeed = WALK_SPEED
			root.Anchored = false
			if bed then
				-- am Fußende aufstehen
				local foot = bed.cframe * CFrame.new(0, 3.2, -bed.length / 2 - 1.6)
				character:PivotTo(CFrame.lookAt(foot.Position, foot.Position + bed.cframe.LookVector))
			end
		end
	end
	local function fallAsleep()
		if asleep then
			return
		end
		asleep = true
		remotes:SetAttribute("Night", true)
		event:FireAllClients({ type = "sleep" })
		print("Kapitel 2: Alle liegen im Bett – die Nacht beginnt (hier geht es später weiter).")
	end
	local function checkAllAsleep()
		local players = Players:GetPlayers()
		if #players == 0 then
			return
		end
		for _, player in players do
			if not lying[player] then
				for _, other in players do
					if lying[other] and other ~= player then
						event:FireClient(player, { type = "hint", text = other.DisplayName .. " liegt schon im Bett.", seconds = 4 })
					end
				end
				return
			end
		end
		task.delay(2.5, function()
			-- immer noch alle im Bett?
			for _, player in Players:GetPlayers() do
				if not lying[player] then
					return
				end
			end
			fallAsleep()
		end)
	end
	local function lieDown(player, bed)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and humanoid) or bed.taken then
			return
		end
		bed.taken = player
		lying[player] = bed
		bed.prompt.ActionText = "Aufstehen"
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
		root.Anchored = true
		-- auf dem Rücken liegen, Kopf auf dem Kissen
		local headward = -bed.cframe.LookVector -- zum Kopfende
		local center = bed.cframe * Vector3.new(0, 2.85, bed.length / 2 - 2.9)
		-- Gesicht nach oben, Kopf zum Kissen
		character:PivotTo(CFrame.lookAt(center, center + Vector3.new(0, 1, 0), headward))
		event:FireClient(player, { type = "hint", text = "Gute Nacht …", seconds = 3 })
		humanoid.Died:Connect(function()
			if lying[player] == bed then
				lying[player] = nil
				bed.taken = nil
				bed.prompt.ActionText = "Schlafen gehen"
			end
		end)
		checkAllAsleep()
	end
	local function setupBeds()
		for _, bed in Mansion.beds do
			local anchor = Instance.new("Part")
			anchor.Name = "BedPrompt"
			anchor.Size = Vector3.new(1, 1, 1)
			anchor.Transparency = 1
			anchor.Anchored = true
			anchor.CanCollide = false
			anchor.CanQuery = false
			anchor.CanTouch = false
			anchor.CFrame = bed.cframe * CFrame.new(0, 2.6, 0)
			anchor.Parent = workspace:FindFirstChild("WagnerHouse", true) or workspace
			local prompt = Instance.new("ProximityPrompt")
			prompt.ObjectText = "Bett"
			prompt.ActionText = "Schlafen gehen"
			prompt.HoldDuration = 0.4
			prompt.MaxActivationDistance = 7
			prompt.RequiresLineOfSight = false
			prompt.Enabled = false -- erst nach dem Gespräch
			prompt.Parent = anchor
			bed.prompt = prompt
			prompt.Triggered:Connect(function(player)
				if asleep then
					return
				end
				if lying[player] == bed then
					standUp(player)
				elseif not lying[player] then
					lieDown(player, bed)
				end
			end)
		end
	end

	------------------------------------------------------------------ Aktionen
	local actions = {}
	function actions.knock()
		sfx("knock", doorFront, { count = 3, interval = 0.42 })
		setMovement(false)
		task.wait(3.2)
	end
	function actions.stepsInside()
		local from, to = hall(Vector2.new(1.5, 1.5)), hall(SPOTS.mrsStart)
		for i = 0, 5 do
			sfx("stepWood", from:Lerp(to, i / 5) + Vector3.new(0, 0.5, 0), { volume = 0.9, maxDistance = 60 })
			task.wait(0.68)
		end
		task.wait(2) -- Stille hinter der Tür
	end
	function actions.doorCrack()
		sfx("doorCreak", doorFront, { volume = 0.8 })
		swingDoor(DOOR_CRACK, 1.5)
	end
	function actions.doorClose()
		swingDoor(0, 0.5)
		sfx("doorSlam", doorFront, { volume = 0.3 })
	end
	function actions.chain()
		sfx("doorChain", doorFront)
		glide(mrs, hall(SPOTS.mrsBack), 1.1)
		task.wait(1.1)
	end
	function actions.doorOpen()
		sfx("doorCreak", doorFront, { volume = 1, speed = 0.85 })
		swingDoor(DOOR_OPEN, 2.6)
	end
	-- Mr. Wagner geht aus der Küche durch den Flur zur Haustür (man hört seine Schritte)
	local mrArrived = false
	function actions.mrComes()
		if not mr or mrArrived then
			mrArrived = true
			return
		end
		task.spawn(function()
			local ok, problem = pcall(walkPath, mr, KITCHEN_TO_DOOR, 5, function(position)
				sfx("stepWood", position + Vector3.new(0, 0.5, 0), { volume = 0.7, maxDistance = 50 })
			end)
			if not ok then
				warn("Kapitel 2: Mr. Wagner konnte nicht zur Tür gehen: " .. tostring(problem))
			end
			Wagners.place(mr, hall(SPOTS.mrBehind), facing)
			mrArrived = true
		end)
	end
	function actions.mrAppears()
		if not mrArrived then
			actions.mrComes()
		end
		local deadline = os.clock() + 12
		while not mrArrived and os.clock() < deadline do
			task.wait(0.1)
		end
		if mr then
			Wagners.place(mr, hall(SPOTS.mrBehind), facing)
			mr:SetAttribute("Look", "player")
		end
		event:FireAllClients({ type = "candleOut", duration = 0.5 })
		task.wait(0.45)
		sfx("sting")
	end
	function actions.invite()
		glide(mrs, hall(SPOTS.mrsInside), 2.6)
		glide(mr, hall(SPOTS.mrInside), 2.6)
		task.wait(1.2)
		setMovement(true)
		event:FireAllClients({ type = "hint", text = "Geh hinein.", seconds = 4 })
		local start, reminded, pulled = os.clock(), false, false
		while true do
			local allIn = true
			for _, player in Players:GetPlayers() do
				if not isInside(player) then
					allIn = false
				end
			end
			local waited = os.clock() - start
			if allIn or waited > PULL_IN_AFTER + 8 then
				break
			end
			if not reminded and waited > REMIND_AFTER then
				reminded = true
				task.spawn(say, Script.COME_INSIDE.speaker, Script.COME_INSIDE.text)
			end
			if not pulled and waited > PULL_IN_AFTER then
				-- wer immer noch draußen ist, wird (kurz schwarz) hereingeholt
				pulled = true
				for index, player in Players:GetPlayers() do
					local character = player.Character
					if character and not isInside(player) then
						event:FireClient(player, { type = "blink" })
						task.delay(0.5, function()
							local spot = hall(SPOTS.pullIn) + Vector3.new(index * 1.5 - 2, 3, 0)
							character:PivotTo(CFrame.lookAt(spot, Vector3.new(facing.X, spot.Y, facing.Z)))
						end)
					end
				end
			end
			task.wait(0.2)
		end
		task.wait(0.5)
		inside = true
		sfx("doorSlam", doorFront, { volume = 1 })
		swingDoor(0, 0.4, true)
		remotes:SetAttribute("Inside", true)
		event:FireAllClients({ type = "inside" })
	end
	-- Die Wagners gehen durch die Tür hinter der Halle und schließen sie hinter sich
	function actions.leave()
		local door = Mansion.doorAt(51.4, 54.15, "E") -- Halle -> Flur
		if door and door.angle == 0 then
			moveDoor(door, door.openAngle, 0.6)
		end
		for _, npc in { mrs, mr } do
			if npc then
				npc:SetAttribute("Look", "down")
			end
		end
		local through = { Vector2.new(1.4, 1), Vector2.new(1.4, 6.5), Vector2.new(2.6, 9) }
		task.spawn(walkPath, mrs, { through[1], through[2], through[3] }, 4.5)
		task.wait(0.9)
		walkPath(mr, { Vector2.new(0, -2), through[1], through[2], Vector2.new(0.2, 9) }, 4.5)
		task.wait(0.4)
		if door then
			sfx("doorSlam", door.model.PrimaryPart.Position, { volume = 0.5 })
			moveDoor(door, 0, 0.5)
		end
		-- danach sind sie weg (in ihrem Zimmer)
		for _, npc in { mrs, mr } do
			if npc then
				Wagners.place(npc, hiddenSpot, facing)
			end
		end
	end
	function actions.candles()
		candlesGiven = true
		for _, player in Players:GetPlayers() do
			giveCandle(player)
		end
	end
	function actions.point()
		local arm = mr and mr:FindFirstChild("RightUpperArm")
		local shoulder = arm and arm:FindFirstChild("RightShoulder")
		if shoulder then
			local base = shoulder.C0
			pcall(function()
				shoulder.C0 = base * CFrame.Angles(math.rad(-15), 0, math.rad(105))
			end)
			task.delay(5, function()
				pcall(function()
					shoulder.C0 = base
				end)
			end)
		end
	end
	-- Ende des Gesprächs: Jetzt darf man sich frei im Haus umsehen
	function actions.finish()
		setMovement(true)
		exploring = true
		for _, bed in Mansion.beds do
			if bed.prompt then
				bed.prompt.Enabled = true
			end
		end
		if not candlesGiven then
			actions.candles()
		end
		remotes:SetAttribute("Explore", true)
		event:FireAllClients({ type = "explore" })
	end

	local stairsTop = (origin * CFrame.new(HouseInterior.STAIRS_TOP + Vector3.new(0, 5, 1.5))).Position
	local function runLine(line)
		local npc = line.speaker and npcs[line.speaker]
		if npc and line.look then
			npc:SetAttribute("Look", line.look)
			if line.look == "stairs" then
				npc:SetAttribute("LookAt", stairsTop)
			end
		end
		if line.action and actions[line.action] then
			-- Geht bei einer Aktion etwas schief, läuft das Gespräch trotzdem weiter
			local ok, problem = xpcall(actions[line.action], debug.traceback)
			if not ok then
				warn("Kapitel 2: Aktion '" .. line.action .. "' hatte einen Fehler:\n" .. tostring(problem))
			end
		end
		if line.text then
			say(line.speaker, line.text)
		end
		if line.wait then
			task.wait(line.wait)
		end
	end

	local function runScene()
		duo = #Players:GetPlayers() >= 2
		local finishedScene = false
		for number, step in Script.SCRIPT do
			local ok, problem = xpcall(function()
				if step.choice then
					local index, chooser = ask(step.choice)
					local option = step.choice[index]
					say("player", option.text, chooser and chooser.DisplayName or "You")
					for _, line in option.reply or {} do
						runLine(line)
					end
				else
					runLine(step)
				end
			end, debug.traceback)
			if not ok then
				warn("Kapitel 2: Fehler im Gespräch bei Schritt " .. number .. ":\n" .. tostring(problem))
			end
			if step.action == "finish" then
				finishedScene = true
			end
		end
		-- Sicherheitsnetz: Niemand bleibt eingefroren, auch wenn etwas schiefging
		if not finishedScene or frozen then
			actions.finish()
		end
	end

	------------------------------------------------------------------ Start
	local doorsOk, doorProblem = pcall(setupDoors)
	if not doorsOk then
		warn("Kapitel 2: Türen konnten nicht eingerichtet werden: " .. tostring(doorProblem))
	end
	local bedsOk, bedProblem = pcall(setupBeds)
	if not bedsOk then
		warn("Kapitel 2: Betten konnten nicht eingerichtet werden: " .. tostring(bedProblem))
	end
	Players.PlayerRemoving:Connect(function(player)
		local bed = lying[player]
		if bed then
			bed.taken = nil
			lying[player] = nil
			if bed.prompt then
				bed.prompt.ActionText = "Schlafen gehen"
			end
		end
		if exploring and not asleep then
			task.defer(checkAllAsleep)
		end
	end)
	-- Klopfen: Hinweis an der Tür (E drücken oder antippen)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Klopfen"
	prompt.ObjectText = "Haustür"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = doorModel:FindFirstChild("Door") or doorModel.PrimaryPart
	local started = false
	prompt.Triggered:Connect(function(player)
		if started then
			return
		end
		started = true
		knocker = player
		prompt:Destroy()
		task.spawn(runScene)
	end)

	local firstJoin
	local function onPlayerAdded(player)
		spawnPlayer(player)
		print("Kapitel 2: " .. player.Name .. " steht vor der Haustür.")
		if not firstJoin then
			firstJoin = os.clock()
			local joinData = player:GetJoinData()
			local teleportData = joinData and joinData.TeleportData
			local expected = type(teleportData) == "table" and teleportData.mode == "Duo" and 2 or 1
			task.spawn(function()
				while #Players:GetPlayers() < expected and os.clock() - firstJoin < WAIT_FOR_GROUP do
					task.wait(0.25)
				end
				task.wait(1)
				event:FireAllClients({ type = "start" })
				remotes:SetAttribute("Started", true)
				task.wait(5)
				if prompt.Parent then
					prompt.Enabled = true
				end
			end)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return Kapitel2
