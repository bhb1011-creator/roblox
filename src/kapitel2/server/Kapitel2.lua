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
	mrInside = Vector2.new(-3.6, -6.4), -- am Fuß der Treppe
	pullIn = Vector2.new(-1.6, -10),
}

local function hall(spot)
	return Route.housePoint(spot.X, spot.Y) + Vector3.new(0, HouseInterior.FLOOR, 0)
end

function Kapitel2.start()
	House.interior = true
	print("Kapitel 2: Welt und Haus werden gebaut …")
	World.build()
	print("Kapitel 2: Welt fertig.")

	local origin = Route.houseCFrame()
	local house = workspace:FindFirstChild("WagnerHouse", true)
	local doorModel = house:FindFirstChild("FrontDoor")
	local hingeCF = doorModel.PrimaryPart.CFrame
	local facing = Route.housePoint(-2, -20) -- die Wagners schauen zur Tür hinaus

	-- Gespräch: Server → Clients (Sätze, Auswahl, Geräusche) und zurück (Antwort)
	local remotes = Instance.new("Folder")
	remotes.Name = "Kapitel2"
	local event = Instance.new("RemoteEvent")
	event.Name = "SceneEvent"
	event.Parent = remotes
	local choiceEvent = Instance.new("RemoteEvent")
	choiceEvent.Name = "SceneChoice"
	choiceEvent.Parent = remotes
	remotes.Parent = ReplicatedStorage

	------------------------------------------------------------------ Die Wagners
	local family = Instance.new("Folder")
	family.Name = "Wagners"
	family.Parent = workspace
	local mrs = Wagners.buildMrs(family)
	local mr = Wagners.buildMr(family)
	local hiddenSpot = Route.housePoint(-2, -6) - Vector3.new(0, 80, 0)
	if mrs then
		Wagners.place(mrs, hall(SPOTS.mrsStart), facing)
		mrs:SetAttribute("Look", "player")
	end
	if mr then
		Wagners.place(mr, hiddenSpot, facing)
		mr:SetAttribute("Look", "down")
	end
	local npcs = { mrsWagner = mrs, mrWagner = mr }

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
					hip.joint.C0 = hip.base * CFrame.Angles(swing, 0, 0)
				end
				if a >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
		end)
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
		local inHall = p.X > House.HALL_X0 + 0.4 and p.X < House.HALL_X1 - 0.4 and p.Z > -Route.HOUSE_SIZE.Z / 2 + House.WALL + 0.3 and p.Z < House.HALL_Z1
		local dx, dz = p.X - hinge.X, p.Z - hinge.Y
		return inHall and math.sqrt(dx * dx + dz * dz) > 4.8
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
	function actions.mrAppears()
		event:FireAllClients({ type = "candleOut", duration = 0.7 })
		task.wait(0.3)
		if mr then
			Wagners.place(mr, hall(SPOTS.mrBehind), facing)
			mr:SetAttribute("Look", "player")
		end
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
			if allIn then
				break
			end
			local waited = os.clock() - start
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
		event:FireAllClients({ type = "inside" })
	end
	function actions.point()
		local arm = mr and mr:FindFirstChild("RightUpperArm")
		local shoulder = arm and arm:FindFirstChild("RightShoulder")
		if shoulder then
			local base = shoulder.C0
			shoulder.C0 = base * CFrame.Angles(math.rad(-15), 0, math.rad(105))
			task.delay(5, function()
				shoulder.C0 = base
			end)
		end
	end
	function actions.finish()
		setMovement(false)
		event:FireAllClients({ type = "finish" })
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
			actions[line.action]()
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
		for _, step in Script.SCRIPT do
			if step.choice then
				local index, chooser = ask(step.choice)
				local option = step.choice[index]
				say("player", option.text, chooser and chooser.DisplayName or "You")
				for _, line in option.reply do
					runLine(line)
				end
			else
				runLine(step)
			end
		end
	end

	------------------------------------------------------------------ Start
	-- Klopfen: Hinweis an der Tür (E drücken oder antippen)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Klopfen"
	prompt.ObjectText = "Haustür"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = doorModel:FindFirstChild("Door")
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
