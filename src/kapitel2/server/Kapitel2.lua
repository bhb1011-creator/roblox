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
local Night = require(script.Parent.Night)
local World = require(script.Parent.World)

local Kapitel2 = {}

local CHOICE_TIMEOUT = 25 -- danach wird automatisch die erste Antwort genommen
local GAP = 0.4 -- Pause zwischen zwei Sätzen
local WAIT_FOR_GROUP = 10 -- Sekunden, die auf den zweiten Spieler gewartet wird
local WALK_SPEED = 8 -- im Haus etwas langsamer
local SNEAK_SPEED = 4 -- Schleichen (Taste C): leiser, Sarp hört einen nicht
local MAX_HEARTS = 3 -- Leben fürs ganze Kapitel (jeder Angriff kostet eins)
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
	print("Kapitel 2: Version " .. tostring(Config.BUILD))
	remotes:SetAttribute("Status", "Building the house …  (Version " .. tostring(Config.BUILD) .. ")")
	local event = Instance.new("RemoteEvent")
	event.Name = "SceneEvent"
	event.Parent = remotes
	local choiceEvent = Instance.new("RemoteEvent")
	choiceEvent.Name = "SceneChoice"
	choiceEvent.Parent = remotes
	-- Licht an/aus (Taste F): ohne Licht sieht Sarp einen nicht
	local lightEvent = Instance.new("RemoteEvent")
	lightEvent.Name = "Light"
	lightEvent.Parent = remotes
	lightEvent.OnServerEvent:Connect(function(player, on)
		if player:GetAttribute("CandleMode") == "none" then
			-- kein Licht mehr (die Kerze ist bei der Explosion verloren gegangen)
			player:SetAttribute("LightOff", true)
			return
		end
		player:SetAttribute("LightOff", on ~= true)
		local candle = player.Character and player.Character:FindFirstChild("PlayerCandle")
		local light = candle and candle:FindFirstChild("CandleLight", true)
		if light then
			light.Enabled = on == true
		end
	end)
	-- Schleichen an/aus (Taste C): nur während der Flucht erlaubt (Attribut "SneakAllowed")
	local sneakEvent = Instance.new("RemoteEvent")
	sneakEvent.Name = "Sneak"
	sneakEvent.Parent = remotes
	sneakEvent.OnServerEvent:Connect(function(player, on)
		on = on == true and remotes:GetAttribute("SneakAllowed") == true
		player:SetAttribute("Sneaking", on)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.WalkSpeed > 0 then
			humanoid.WalkSpeed = on and SNEAK_SPEED or WALK_SPEED
		end
	end)
	-- Versteck verlassen mit einer Taste (E / Leertaste / Knopf), Night.lua und Escape.lua hören zu
	local leaveHideEvent = Instance.new("RemoteEvent")
	leaveHideEvent.Name = "LeaveHide"
	leaveHideEvent.Parent = remotes
	-- Quick-Time-Event (die Familie hat einen gepackt): der Client meldet, ob man sich befreit hat
	local qteEvent = Instance.new("RemoteEvent")
	qteEvent.Name = "Qte"
	qteEvent.Parent = remotes
	-- Nach dem Game Over: "Nochmal versuchen"
	local restartEvent = Instance.new("RemoteEvent")
	restartEvent.Name = "Restart"
	restartEvent.Parent = remotes
	remotes.Parent = ReplicatedStorage

	House.mansion = true -- das große Herrenhaus statt des kleinen Holzhauses
	print("Kapitel 2: Welt und Haus werden gebaut …")
	local buildStarted = os.clock()
	local ok, problem = xpcall(function()
		World.build({ keepRadius = 450 }) -- nur die Umgebung ums Haus, nicht die ganze Strecke aus Kapitel 1
		task.wait()
		local removed = Mansion.clearAround(workspace:FindFirstChild("Level1"))
		require(ReplicatedStorage.Shared.Parts).optimize(workspace) -- Leistung (siehe Parts.optimize)
		print(string.format("Kapitel 2: Welt fertig nach %.1f s (%d Bäume und Teile ums Haus entfernt).", os.clock() - buildStarted, removed or 0))
	end, debug.traceback)
	local house = workspace:FindFirstChild("WagnerHouse", true)
	local doorModel = house and house:FindFirstChild("FrontDoor")
	if not ok or not (doorModel and doorModel.PrimaryPart) then
		local text = tostring(problem or "Haus oder Haustür fehlt")
		warn("Kapitel 2: FEHLER beim Bauen der Welt – bitte diese Meldung an Claude schicken:\n" .. text)
		remotes:SetAttribute("Status", "Build error (see Output):\n" .. (text:match("[^\n]+") or text))
		return
	end
	remotes:SetAttribute("Status", "Waking the Wagners …  (Version " .. tostring(Config.BUILD) .. ")")

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
	-- echte Figuren aus ReplicatedStorage.Wagners (assets/figuren), sonst die eingebauten
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
					local swing = a < 1 and math.sin(elapsed * 6 + index * math.pi) * 0.3 * (npc:GetAttribute("StepScale") or 1) or 0
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

	-- Gehen entlang mehrerer Punkte (Hallen-Koordinaten). Natürlich statt eckig: Ecken werden zu
	-- weichen Kurven, die Figur dreht sich allmählich in die Laufrichtung, läuft weich an und bremst
	-- am Ende ab; Schritte passen zum Tempo, die Knie beugen sich beim Vorschwingen.
	local function walkPath(npc, spots, speed, onStep)
		if not npc then
			return
		end
		local nextStep = 0
		local legs = {}
		for _, side in { "Left", "Right" } do
			local upper, lower = npc:FindFirstChild(side .. "UpperLeg"), npc:FindFirstChild(side .. "LowerLeg")
			local hip = upper and (upper:FindFirstChild(side .. "Hip") or upper:FindFirstChildOfClass("Motor6D"))
			local knee = lower and (lower:FindFirstChild(side .. "Knee") or lower:FindFirstChildOfClass("Motor6D"))
			if hip and hip:IsA("Motor6D") then
				table.insert(legs, {
					hip = hip,
					hipBase = hip.C0,
					knee = knee and knee:IsA("Motor6D") and knee or nil,
					kneeBase = knee and knee:IsA("Motor6D") and knee.C0 or nil,
				})
			end
		end
		local position = Wagners.ground(npc)
		-- Wegpunkte (Hallen-Koordinaten oder { at = Weltposition }) in Weltpunkte umrechnen und
		-- durchs Wegnetz führen: um Möbel herum, durch Türen, nie durch Wände
		local targets = {}
		for _, spot in spots do
			local goal = (type(spot) == "table" and rawget(spot, "at")) or hall(spot)
			local from = targets[#targets] or position
			local route = Mansion.route and Mansion.route(from, goal)
			for _, step in route or { goal } do
				table.insert(targets, step)
			end
		end
		local points = { position }
		for _, target in targets do
			if (target - points[#points]).Magnitude > 0.05 then
				table.insert(points, target)
			end
		end
		if #points < 2 then
			return
		end
		-- Ecken abrunden (kleiner Bogen, höchstens 1,6 Studs vor/nach der Ecke)
		local path = { points[1] }
		for index = 2, #points - 1 do
			local a, b, c = points[index - 1], points[index], points[index + 1]
			local radius = math.min(1.6, (b - a).Magnitude * 0.45, (c - b).Magnitude * 0.45)
			local p0 = b + (a - b).Unit * radius
			local p2 = b + (c - b).Unit * radius
			for k = 0, 6 do
				local u = k / 6
				table.insert(path, p0 * (1 - u) ^ 2 + b * (2 * (1 - u) * u) + p2 * u ^ 2)
			end
		end
		table.insert(path, points[#points])
		local lengths, total = { 0 }, 0
		for index = 2, #path do
			total += (path[index] - path[index - 1]).Magnitude
			lengths[index] = total
		end
		local root = npc:FindFirstChild("HumanoidRootPart")
		local look = root and root.CFrame.LookVector * Vector3.new(1, 0, 1) or Vector3.new(0, 0, -1)
		look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
		local stepScale = npc:GetAttribute("StepScale") or 1
		local stride = 2.2 -- Studs pro Doppelschritt
		local travelled, elapsed, phase, segment = 0, 0, 0, 2
		while travelled < total do
			local dt = RunService.Heartbeat:Wait()
			elapsed += dt
			-- weich anlaufen und vor dem Ziel abbremsen
			local pace = speed * math.clamp(math.min(0.3 + elapsed / 0.4, 0.3 + (total - travelled) / 1.2), 0.3, 1)
			travelled = math.min(travelled + pace * dt, total)
			while segment < #path and lengths[segment] < travelled do
				segment += 1
			end
			local a, b = path[segment - 1], path[segment]
			local span = lengths[segment] - lengths[segment - 1]
			local u = span > 0 and (travelled - lengths[segment - 1]) / span or 1
			position = a:Lerp(b, u)
			local heading = (b - a) * Vector3.new(1, 0, 1)
			if heading.Magnitude > 0.01 then
				look = look:Lerp(heading.Unit, math.min(dt * 7, 1))
				look = look.Magnitude > 0.01 and look.Unit or heading.Unit
			end
			Wagners.place(npc, position, position + look)
			if onStep and os.clock() >= nextStep then
				nextStep = os.clock() + 0.55
				onStep(position)
			end
			phase += pace * dt / stride * math.pi * 2
			local strength = (pace / speed) * stepScale
			for index, leg in legs do
				local swing = math.sin(phase + (index - 1) * math.pi) * 0.38 * strength
				pcall(function()
					leg.hip.C0 = leg.hipBase * CFrame.Angles(swing, 0, 0)
					if leg.knee then
						-- Knie beugt sich, während das Bein nach vorn schwingt
						local bend = math.max(0, math.cos(phase + (index - 1) * math.pi)) * 0.55 * strength
						leg.knee.C0 = leg.kneeBase * CFrame.Angles(-bend, 0, 0)
					end
				end)
			end
		end
		for _, leg in legs do
			pcall(function()
				leg.hip.C0 = leg.hipBase
				if leg.knee then
					leg.knee.C0 = leg.kneeBase
				end
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
				humanoid.WalkSpeed = enabled and (player:GetAttribute("Sneaking") and SNEAK_SPEED or WALK_SPEED) or 0
				humanoid.JumpHeight = enabled and 2 or 0
			end
		end
	end

	-- Eigene Kerze in der Hand (bekommt man von Mrs. Wagner). Die anderen sehen sie an
	-- der Hand, man selbst sieht sie unten links im Bild (macht Scene.lua auf dem Client).
	local candlesGiven = false
	-- "normal" = gelbe Kerze, "red" = rote Kerze von Richard (Flucht), "none" = keine mehr
	local candleMode = "normal"
	local function giveCandle(player)
		if candleMode == "none" then
			return
		end
		local red = candleMode == "red"
		local character = player.Character
		local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (hand and root) or character:FindFirstChild("PlayerCandle") then
			return
		end
		local model = Instance.new("Model")
		model.Name = "PlayerCandle"
		local base = CFrame.new(hand.Position) * root.CFrame.Rotation * CFrame.new(0, -0.25, -0.35)
		-- detaillierte Kerze im Messinghalter (ReplicatedStorage.Shared.CandleModel)
		local CandleModel = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CandleModel"))
		local flame = CandleModel.build(model, base, 1.15, { red = red, weldTo = hand }).flame
		local light = Instance.new("PointLight")
		light.Name = "CandleLight"
		light.Range = red and 15 or 22
		light.Brightness = red and 1.6 or 2
		light.Color = red and Color3.fromRGB(255, 40, 30) or Color3.fromRGB(255, 180, 110)
		light.Shadows = true
		light.Enabled = not player:GetAttribute("LightOff")
		light.Parent = flame
		model.Parent = character
	end

	-- Kerze für alle neu verteilen (oder wegnehmen)
	local function setCandleMode(mode)
		candleMode = mode
		candlesGiven = true
		for _, player in Players:GetPlayers() do
			local old = player.Character and player.Character:FindFirstChild("PlayerCandle")
			if old then
				old:Destroy()
			end
			player:SetAttribute("CandleMode", mode ~= "normal" and mode or nil)
			player:SetAttribute("LightOff", mode == "none")
			giveCandle(player)
		end
	end

	-- Wo man nach dem Sterben wieder anfängt (Flucht: im Raum hinter Tür 1)
	local checkpoint -- function(index) -> CFrame
	local loseHeartOnDeath -- (wird unten bei den Herzen festgelegt)
	local function spawnPlayer(player)
		local index = table.find(Players:GetPlayers(), player) or 1
		local cframe
		if player:GetAttribute("Hearts") == nil then
			player:SetAttribute("Hearts", MAX_HEARTS)
		end
		player:SetAttribute("CandleMode", candleMode ~= "normal" and candleMode or nil)
		if candleMode == "none" then
			player:SetAttribute("LightOff", true)
		end
		if checkpoint then
			cframe = checkpoint(index)
		elseif inside then
			local spot = hall(SPOTS.pullIn) + Vector3.new(index * 1.5 - 2, 0, 0)
			cframe = CFrame.lookAt(spot, Vector3.new(facing.X, spot.Y, facing.Z))
		else
			cframe = Route.doorSpawn(index)
		end
		ForestWalk.spawnWalker(player, cframe)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			player:SetAttribute("Sneaking", false)
			humanoid.WalkSpeed = frozen and 0 or WALK_SPEED
			humanoid.JumpHeight = frozen and 0 or 2
			if candlesGiven then
				giveCandle(player)
			end
			humanoid.Died:Connect(function()
				if loseHeartOnDeath then
					loseHeartOnDeath(player)
				end
				task.delay(3, function()
					if player.Parent and not player:GetAttribute("GameOver") then
						spawnPlayer(player)
					end
				end)
			end)
		end
	end

	------------------------------------------------------------------ Herzen (Leben) und Game Over
	-- Jeder Spieler hat 3 Herzen fürs ganze Kapitel. Jeder Angriff (Sarp erwischt einen, die
	-- Familie, die Explosion, Sterben) kostet eins, danach ist man wieder ganz gesund.
	-- Keine Herzen mehr: Game Over (auf dem Client mit "Nochmal versuchen").
	local function heartsOf(player)
		local hearts = player:GetAttribute("Hearts")
		if hearts == nil then
			hearts = MAX_HEARTS
			player:SetAttribute("Hearts", hearts)
		end
		return hearts
	end
	local function gameOver(player)
		player:SetAttribute("GameOver", true)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid then
			humanoid.WalkSpeed = 0
		end
		if root then
			root.Anchored = true
		end
		event:FireClient(player, { type = "gameOver" })
		print("Kapitel 2: GAME OVER für " .. player.Name)
	end
	local function loseHeart(player, reason)
		if player:GetAttribute("GameOver") then
			return 0
		end
		local hearts = math.max(heartsOf(player) - 1, 0)
		player:SetAttribute("Hearts", hearts)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = humanoid.MaxHealth
		end
		event:FireClient(player, { type = "heartLost", hearts = hearts, reason = reason })
		print(string.format("Kapitel 2: %s verliert ein Herz (%s) – noch %d", player.Name, tostring(reason), hearts))
		if hearts <= 0 then
			gameOver(player)
		end
		return hearts
	end
	loseHeartOnDeath = function(player)
		loseHeart(player, "gestorben")
	end
	restartEvent.OnServerEvent:Connect(function(player)
		if not player:GetAttribute("GameOver") then
			return
		end
		player:SetAttribute("GameOver", nil)
		player:SetAttribute("Hearts", MAX_HEARTS)
		spawnPlayer(player)
		event:FireClient(player, { type = "retry", restart = true })
	end)

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
		-- entry: Text, { solo = , duo = } oder { text = ..., voice = Name der Aufnahme }
		local voiceName
		if type(entry) == "table" and entry.text then
			voiceName = entry.voice
			entry = entry.text
			if type(voiceName) == "table" then
				voiceName = duo and voiceName.duo or voiceName.solo
			end
		end
		local text = Dialogue.text(entry, duo)
		local voice = Config.VOICES and Config.VOICES[speaker] or {}
		local duration = Dialogue.duration(text, voice.speed)
		local recording = voiceName and Config.VOICE_LINES and Config.VOICE_LINES[voiceName]
		if recording and recording.id ~= "" and (recording.length or 0) > 0 then
			duration = recording.length + 0.3
		end
		event:FireAllClients({ type = "line", speaker = speaker, name = name or Script.NAMES[speaker] or "", text = text, duration = duration, voice = voiceName })
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
			door.prompt.ActionText = target > 0 and "Close" or "Open"
		end
		door.moving = false
	end

	-- Sarp und die Familie öffnen Türen, durch die ihr Weg führt (Mansion.route)
	Mansion.openDoor = function(door)
		if door.angle == 0 and not door.moving and door.model then
			sfx("doorCreak", door.model.PrimaryPart and door.model.PrimaryPart.Position or Vector3.zero, { volume = 0.6, speed = 0.8 })
			moveDoor(door, door.openAngle, 0.45)
		end
	end

	local function setupDoors()
		for _, door in Mansion.doors do
			local leaf = door.model and door.model.PrimaryPart
			if leaf then
				local prompt = Instance.new("ProximityPrompt")
				prompt.ObjectText = "Door"
				prompt.ActionText = door.locked and "Open" or (door.angle > 0 and "Close" or "Open")
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
						-- z. B. Tür 1 mit der Axt aufbrechen (Night.lua setzt door.onLocked)
						if door.onLocked and door.onLocked(player) then
							return
						end
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
	local startNight -- wird weiter unten gesetzt (Night.lua)
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
				bed.prompt.ActionText = "Go to sleep"
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
		print("Kapitel 2: Alle liegen im Bett – die erste Nacht beginnt.")
		if startNight then
			task.spawn(startNight)
		end
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
						event:FireClient(player, { type = "hint", text = other.DisplayName .. " is already in bed.", seconds = 4 })
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
		event:FireClient(player, { type = "hint", text = "Good night …", seconds = 3 })
		humanoid.Died:Connect(function()
			if lying[player] == bed then
				lying[player] = nil
				bed.taken = nil
				bed.prompt.ActionText = "Go to sleep"
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
			prompt.ObjectText = "Bed"
			prompt.ActionText = "Go to sleep"
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
		event:FireAllClients({ type = "hint", text = "Go inside.", seconds = 4 })
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
	-- Mr. Wagner zeigt zur Treppe: Arm auf der Seite, wo die Treppe ist, weich gehoben und
	-- wirklich in ihre Richtung (nicht starr zur Seite), nach ein paar Sekunden wieder runter.
	function actions.point()
		if not mr then
			return
		end
		local root = mr:FindFirstChild("HumanoidRootPart")
		local target = mr:GetAttribute("LookAt")
		if not (root and typeof(target) == "Vector3") then
			return
		end
		local side = root.CFrame:PointToObjectSpace(target).X >= 0 and "Right" or "Left"
		local arm = mr:FindFirstChild(side .. "UpperArm")
		local shoulder = arm and arm:FindFirstChild(side .. "Shoulder")
		local hand = mr:FindFirstChild(side .. "Hand")
		if not (shoulder and shoulder:IsA("Motor6D") and hand) then
			return
		end
		local base = shoulder.C0
		local ok, raised = pcall(function()
			local pivot = shoulder.Part0.CFrame * shoulder.C0
			local current = (hand.Position - pivot.Position).Unit
			-- etwas tiefer als genau auf die Treppe: sieht entspannter aus
			local wanted = ((target - pivot.Position).Unit + Vector3.new(0, -0.25, 0)).Unit
			local axis = current:Cross(wanted)
			if axis.Magnitude < 1e-3 then
				return base
			end
			local angle = math.acos(math.clamp(current:Dot(wanted), -1, 1))
			local turned = CFrame.new(pivot.Position) * CFrame.fromAxisAngle(axis.Unit, angle) * (pivot - pivot.Position)
			return shoulder.Part0.CFrame:ToObjectSpace(turned)
		end)
		if not ok then
			return
		end
		local TweenService = game:GetService("TweenService")
		TweenService:Create(shoulder, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { C0 = raised }):Play()
		task.delay(3.8, function()
			if shoulder.Parent then
				TweenService:Create(shoulder, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { C0 = base }):Play()
			end
		end)
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

	-- Spielt eine Liste von Schritten ab (Sätze, Aktionen, Auswahl)
	local function runScript(steps, label)
		for number, step in steps do
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
				warn("Kapitel 2: Fehler in " .. (label or "Szene") .. " bei Schritt " .. number .. ":\n" .. tostring(problem))
			end
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

	------------------------------------------------------------------ Die erste Nacht (Night.lua)
	local nightStartAt -- "afterHide" beim Teststart
	startNight = function()
		local ok, problem = xpcall(Night.run, debug.traceback, {
			startAt = nightStartAt,
			event = event,
			remotes = remotes,
			sfx = sfx,
			say = say,
			runScript = runScript,
			actions = actions,
			npcs = npcs,
			walkPath = walkPath,
			moveDoor = moveDoor,
			hall = hall,
			setMovement = setMovement,
			standUp = standUp,
			lying = lying,
			beds = Mansion.beds,
			frontDoor = { set = setDoor, swing = swingDoor, open = DOOR_OPEN, position = doorFront },
			hiddenSpot = hiddenSpot,
			facing = facing,
			spawnPlayer = spawnPlayer,
			setCandleMode = setCandleMode,
			loseHeart = loseHeart,
			gameOver = gameOver,
			setCheckpoint = function(fn)
				checkpoint = fn
			end,
			walkSpeed = WALK_SPEED,
			sneakSpeed = SNEAK_SPEED,
		})
		if not ok then
			warn("Kapitel 2: Fehler in der Nacht:\n" .. tostring(problem))
			setMovement(true)
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
				bed.prompt.ActionText = "Go to sleep"
			end
		end
		if exploring and not asleep then
			task.defer(checkAllAsleep)
		end
	end)
	-- Klopfen: Hinweis an der Tür (E drücken oder antippen)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Klopfen"
	prompt.ObjectText = "Front door"
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

	-- Teststart (Config.TEST_START_KAPITEL2): man ist schon drin, hat eine Kerze, es ist Nacht
	local TEST_STARTS = {
		nachVerstecken = "direkt nach dem Verstecken",
		tuer1 = "im Raum hinter Tür 1 (Flucht)",
		schluessel = "im Vorratskeller vor dem Regal, mit dem Schlüssel",
		kapitel3 = "gleich in Kapitel 3 (Ritualraum)",
		huette = "gleich am Ende von Kapitel 3 (hinter der Brücke, Weg zu Sarps Hütte)",
	}
	local testStart = TEST_STARTS[Config.TEST_START_KAPITEL2] ~= nil
	-- (tuer1, schluessel und kapitel3 beginnen alle mit der Flucht; Escape.lua springt weiter)
	local escapeTest = testStart and Config.TEST_START_KAPITEL2 ~= "nachVerstecken"
	if testStart then
		print("Kapitel 2: TESTSTART " .. TEST_STARTS[Config.TEST_START_KAPITEL2] .. " (Config.TEST_START_KAPITEL2)")
		inside = true
		candlesGiven = true
		exploring = true
		started = true
		prompt.Enabled = false
		remotes:SetAttribute("TestStart", true)
		remotes:SetAttribute("Inside", true)
		for _, npc in { mrs, mr } do
			if npc then
				Wagners.place(npc, hiddenSpot, facing)
			end
		end
		-- Teststart "tuer1": man erscheint gleich im Raum hinter Tür 1 (nicht erst in der Halle)
		if escapeTest and Mansion.escape then
			checkpoint = function(index)
				local feet = Mansion.escape.checkpoint + Vector3.new((index - 1) * 1.2 - 0.6, 0, 0)
				local look = Mansion.escape.checkpointLook
				return CFrame.lookAt(feet, Vector3.new(look.X, feet.Y, look.Z))
			end
		end
	end

	-- Teststart "haus": nur das Haus ansehen – kein Gespräch, keine Nacht, kein Sarp.
	-- Man steht in der Halle, alle Türen gehen auf, die Betten bleiben aus (sonst käme die Nacht).
	local tour = Config.TEST_START_KAPITEL2 == "haus"
	if tour then
		print("Kapitel 2: TESTSTART Haus besichtigen (ohne Szene, ohne Sarp)")
		inside = true
		candlesGiven = true
		started = true
		prompt.Enabled = false
		remotes:SetAttribute("TestStart", true)
		remotes:SetAttribute("Inside", true)
		for _, npc in { mrs, mr } do
			if npc then
				Wagners.place(npc, hiddenSpot, facing)
			end
		end
		for _, door in Mansion.doors do
			door.locked = false
			if door.prompt then
				door.prompt.ActionText = door.angle > 0 and "Close" or "Open"
			end
		end
		-- vernagelte Tür 1: Bretter bleiben sichtbar, man kann aber hindurchgehen
		if Mansion.model then
			for _, part in Mansion.model:GetDescendants() do
				if part:IsA("BasePart") and part.Name == "Board" then
					part.CanCollide = false
				end
			end
		end
	end

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
				if testStart then
					-- Teststart: gleich in die Nacht, direkt nach dem Verstecken
					task.wait(3)
					asleep = true
					nightStartAt = escapeTest and Config.TEST_START_KAPITEL2 or "afterHide"
					remotes:SetAttribute("Night", true)
					task.spawn(startNight)
					return
				end
				if tour then
					return
				end
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
