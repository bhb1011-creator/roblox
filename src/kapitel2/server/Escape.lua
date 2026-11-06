-- Kapitel 2, die Flucht (startet, sobald jemand den Raum hinter Tür 1 betritt; siehe Night.lua).
--
--  1. Richard wartet am Pult. Er erklärt, was zu tun ist (ohne zu verraten, was mit seiner
--     Familie los ist) und gibt jedem eine rote Kerze. Taschenlampe gibt es keine mehr.
--  2. Man sucht Chemikalien und Schießpulver (je mehrere ausgeloste Plätze, einer davon oben, Mansion.escape.items).
--     Sarp läuft dabei durchs ganze Haus (Erdgeschoss, Keller, oben) und ist tödlich: Er sieht
--     das rote Licht, hört, wer nicht schleicht. Der Raum hinter Tür 1 ist sicher.
--     Die Familie taucht auf und packt einen (höchstens 10 Sekunden lang in der Nähe):
--     Quick-Time-Event – schnell tippen, um sich loszureißen, sonst gibt es Schaden.
--  3. Am Pult ablegen, zusammenbauen, an den Safe, Lunte mit der Kerze anzünden, verstecken.
--  4. Explosion: der Safe ist offen, die Kerzen sind weg. Sarp hat es gehört, kommt hoch
--     und durchsucht den Raum (Schrank, hinter dem Bett, Truhe).
--  5. Danach: rote Kerzen zeigen den Weg nach unten. Schlüssel nehmen, schleichen (C),
--     Sarp läuft unten herum und ist tödlich (hört einen, wenn man nicht schleicht).
--  6. Der Schlüssel öffnet das Regal vor dem Geheimgang. Wer den Ritualraum betritt: schwarz.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Script = require(ReplicatedStorage.Shared.Kapitel2Dialogue)
local Mansion = require(script.Parent.Mansion)
local Wagners = require(script.Parent.Wagners)
local SarpStage2 = require(script.Parent.SarpStage2)

local Escape = {}

local FAMILY_SPEED = 6 -- etwas langsamer als man läuft (8)
local FAMILY_TIME = 10 -- so lange bleibt ein Familienmitglied höchstens in der Nähe
local QTE_TAPS, QTE_SECONDS = 10, 4 -- so oft tippen, so viel Zeit
local FUSE_TIME = 5 -- Sekunden zum Verstecken nach dem Anzünden
local BLAST_DAMAGE = 35 -- wer nicht versteckt ist und nah am Safe steht
local SEARCH_SPEED = 4.2
local RUSH_SPEED = 6.5 -- nach der Explosion rennt er zum Zimmer
local PATROL_SPEED = 3.4
local CHASE_SPEED = 7.2
local HEAR_DISTANCE = 16 -- so weit hört Sarp Spieler, die nicht schleichen
local LIGHT_SEE_DISTANCE = 26 -- das rote Licht sieht er von weitem
local SEE_DISTANCE = 12 -- im Dunkeln sieht er einen nur aus der Nähe
local SNEAK_SEE_DISTANCE = 8 -- wer schleicht, fällt später auf
local ALERT_SPEED = 5.5 -- so schnell kommt er dorthin, wo die Familie einen gepackt hat
local FAMILY_FIRST, FAMILY_PAUSE_MIN, FAMILY_PAUSE_MAX = 45, 40, 65 -- seltener
local CATCH_DISTANCE = 3.2
local ITEM_COPIES = 3 -- so oft liegt jede Sorte im Haus (an verschiedenen Plätzen)

local LABELS = { chemicals = "Chemikalien", powder = "Schießpulver" }
local WITH_ARTICLE = { chemicals = "die Chemikalien", powder = "das Schießpulver" }

function Escape.run(kit)
	local ctx = kit.ctx
	local event, sfx, say = ctx.event, ctx.sfx, ctx.say
	local point = Mansion.point -- (Plan-x, Plan-y, Höhe), Höhe z. B. Mansion.FLOORS.O
	local rootOf, footOffset = kit.rootOf, kit.footOffset
	local sarp = kit.sarp
	local room = Mansion.escape
	local O = Mansion.FLOORS.O
	if not room then
		warn("Kapitel 2: Mansion.escape fehlt – die Flucht kann nicht starten.")
		return
	end
	local remotes = ctx.remotes
	remotes:SetAttribute("Phase", "escape")

	-- Rundgang und Familien-Erscheinungen der Nacht hören erst auf (höchstens ein paar Sekunden)
	local waitStart = os.clock()
	while kit.isReady and not kit.isReady() and os.clock() - waitStart < 12 do
		task.wait(0.2)
	end
	if sarp then
		Wagners.place(sarp, kit.away, ctx.facing)
	end

	local phase = "intro" -- intro, search, bomb, blast, sneak, done
	local function hint(text, seconds, player)
		local message = { type = "hint", text = text, seconds = seconds or 5 }
		if player then
			event:FireClient(player, message)
		else
			event:FireAllClients(message)
		end
	end
	-- ein Satz aus Script.ESCAPE (wartet, bis er gesagt ist)
	local function line(key)
		local entry = Script.ESCAPE[key]
		if entry then
			say(entry[1], entry[2])
		end
	end
	local function lineAsync(key)
		task.spawn(line, key)
	end
	local function speedFor(player)
		return player:GetAttribute("Sneaking") and ctx.sneakSpeed or ctx.walkSpeed
	end
	local function alive(player)
		local root, humanoid = rootOf(player)
		return root ~= nil and humanoid ~= nil and humanoid.Health > 0 and not player:GetAttribute("GameOver")
	end

	------------------------------------------------------------------ Neustart-Punkt
	local function checkpointFrame(index)
		local feet = room.checkpoint + Vector3.new((index - 1) * 1.2 - 0.6, 0, 0)
		local look = room.checkpointLook
		return CFrame.lookAt(feet, Vector3.new(look.X, feet.Y, look.Z))
	end
	ctx.setCheckpoint(checkpointFrame)

	------------------------------------------------------------------ Verstecke im Raum
	local hidden = {} -- Spieler -> Versteck
	local caught = {} -- Spieler -> true (gerade erwischt, bis zum Neustart)
	local holder = Instance.new("Folder")
	holder.Name = "EscapeHidePrompts"
	holder.Parent = Mansion.model or workspace
	local function leaveSpot(player, toExit)
		local spot = hidden[player]
		if not spot then
			return
		end
		hidden[player] = nil
		spot.occupant = nil
		if spot.promptObject then
			spot.promptObject.ActionText = "Verstecken"
			spot.promptObject.Enabled = true
		end
		local root, humanoid = rootOf(player)
		if root and humanoid then
			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
			humanoid.WalkSpeed = speedFor(player)
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
			hint("Da ist schon jemand.", 2, player)
			return
		end
		hidden[player] = spot
		spot.occupant = player
		spot.promptObject.ActionText = "Rauskommen"
		spot.promptObject.Enabled = false -- rauskommen: E oder Leertaste (Remote "LeaveHide")
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
	local allSpots = {}
	for _, list in { room.hideSpots, room.houseHideSpots or {}, Mansion.hideSpots or {} } do
		for _, spot in list do
			-- (die Knöpfe der ersten Nacht im Esszimmer werden durch neue ersetzt)
			if spot.promptObject then
				spot.promptObject.Enabled = false
			end
			table.insert(allSpots, spot)
		end
	end
	for _, spot in allSpots do
		local part = Instance.new("Part")
		part.Name = "EscapeHide" .. spot.name
		part.Size = Vector3.new(1, 1, 1)
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CFrame = spot.prompt
		part.Parent = holder
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = spot.label or ({ Tisch = "Unter den Tisch", Vorhang = "Hinter den Vorhang" })[spot.name] or spot.name
		prompt.ActionText = "Verstecken"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 6
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
		spot.promptObject = prompt
		spot.occupant = nil
		prompt.Triggered:Connect(function(player)
			if caught[player] then
				return
			end
			if hidden[player] == spot then
				leaveSpot(player)
			elseif not hidden[player] then
				enterSpot(player, spot)
			end
		end)
	end

	local leaveHideEvent = remotes:FindFirstChild("LeaveHide")
	if leaveHideEvent then
		leaveHideEvent.OnServerEvent:Connect(function(player)
			if hidden[player] and not caught[player] then
				leaveSpot(player)
			end
		end)
	end

	-- Erwischt (von Sarp): Jumpscare, kurz schwarz, dann geht es im Raum hinter Tür 1 weiter
	local function restartPlayer(player)
		if player:GetAttribute("GameOver") then
			caught[player] = nil
			return
		end
		leaveSpot(player, false)
		local index = table.find(Players:GetPlayers(), player) or 1
		local root, humanoid = rootOf(player)
		if root and humanoid then
			root.Anchored = false
			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
			humanoid.WalkSpeed = speedFor(player)
			player.Character:PivotTo(checkpointFrame(index) + Vector3.new(0, footOffset(player), 0))
		end
		caught[player] = nil
		event:FireClient(player, { type = "retry" })
	end
	local function catchPlayer(player, restartAfter)
		if caught[player] then
			return
		end
		caught[player] = true
		leaveSpot(player, false)
		local root, humanoid = rootOf(player)
		if sarp and root then
			local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
			if look.Magnitude < 0.1 then
				look = Vector3.new(0, 0, -1)
			end
			local feet = root.Position - Vector3.new(0, footOffset(player), 0)
			Wagners.place(sarp, feet + look.Unit * 2.6, feet)
			SarpStage2.look(sarp, 0, 0.25)
		end
		if humanoid then
			humanoid.WalkSpeed = 0
		end
		event:FireClient(player, { type = "jumpscare" })
		sfx("jumpscare", root and root.Position or room.checkpoint, { volume = 2, maxDistance = 60 })
		task.wait(1.6)
		event:FireClient(player, { type = "caught" })
		if sarp then
			SarpStage2.look(sarp, 0, 0)
		end
		if ctx.loseHeart then
			ctx.loseHeart(player, "Sarp")
		end
		if restartAfter then
			task.delay(restartAfter, function()
				if caught[player] then
					restartPlayer(player)
				end
			end)
		end
	end

	------------------------------------------------------------------ Gegenstände in der Hand
	-- (wie die Axt: an der linken Hand; nach dem Neuspawnen wieder da)
	local function attachToHand(player, name, build)
		local character = player.Character
		local hand = character and (character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"))
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (hand and root) or character:FindFirstChild(name) then
			return
		end
		local model = Instance.new("Model")
		model.Name = name
		local base = CFrame.new(hand.Position) * root.CFrame.Rotation * CFrame.new(0, -0.3, -0.3)
		build(function(partName, size, offset, color, material, shape)
			local part = Instance.new("Part")
			part.Name = partName
			if shape then
				part.Shape = shape
			end
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
			return part
		end)
		model.Parent = character
	end
	local function dropFromHand(player, name)
		local carried = player.Character and player.Character:FindFirstChild(name)
		if carried then
			carried:Destroy()
		end
	end
	local upright = CFrame.Angles(0, 0, math.rad(90)) -- Zylinder stehen in Roblox auf der Seite
	local BUILDERS = {
		chemicals = function(piece)
			piece("Crate", Vector3.new(0.9, 0.5, 0.6), CFrame.new(), Color3.fromRGB(110, 84, 56), Enum.Material.WoodPlanks)
			for i = -1, 1 do
				piece("Bottle", Vector3.new(0.6, 0.22, 0.22), CFrame.new(i * 0.26, 0.45, 0) * upright, Color3.fromRGB(70, 40, 20), Enum.Material.Glass, Enum.PartType.Cylinder)
			end
		end,
		powder = function(piece)
			piece("Keg", Vector3.new(0.8, 0.6, 0.6), CFrame.new(0, 0.1, 0) * upright, Color3.fromRGB(66, 46, 30), Enum.Material.Wood, Enum.PartType.Cylinder)
			piece("KegBand", Vector3.new(0.08, 0.64, 0.64), CFrame.new(0, 0.3, 0) * upright, Color3.fromRGB(40, 40, 42), Enum.Material.Metal, Enum.PartType.Cylinder)
		end,
		charge = function(piece)
			piece("Charge", Vector3.new(1, 0.7, 0.6), CFrame.new(), Color3.fromRGB(66, 46, 30), Enum.Material.Wood)
			piece("ChargeTape", Vector3.new(1.04, 0.2, 0.64), CFrame.new(0, 0.1, 0), Color3.fromRGB(150, 140, 110), Enum.Material.Fabric)
			piece("Fuse", Vector3.new(0.06, 0.8, 0.06), CFrame.new(0.3, 0.7, 0) * CFrame.Angles(0, 0, math.rad(-20)), Color3.fromRGB(30, 26, 22), Enum.Material.Fabric)
		end,
		key = function(piece)
			piece("KeyBow", Vector3.new(0.05, 0.3, 0.3), CFrame.new(), Color3.fromRGB(190, 160, 80), Enum.Material.Metal, Enum.PartType.Cylinder)
			piece("KeyShaft", Vector3.new(0.06, 0.06, 0.6), CFrame.new(0, 0, -0.4), Color3.fromRGB(190, 160, 80), Enum.Material.Metal)
		end,
	}
	-- dasselbe als freistehendes Modell in der Welt (am Fundort, auf dem Pult, am Safe)
	local function buildWorldModel(kind, cframe, parent)
		local model = Instance.new("Model")
		model.Name = "Escape_" .. kind
		local first
		BUILDERS[kind](function(partName, size, offset, color, material, shape)
			local part = Instance.new("Part")
			part.Name = partName
			if shape then
				part.Shape = shape
			end
			part.Size = size * 1.4
			part.CFrame = cframe * CFrame.new(offset.Position * 1.4) * offset.Rotation
			part.Color = color
			part.Material = material
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.Parent = model
			first = first or part
			return part
		end)
		model.PrimaryPart = first
		model.Parent = parent
		return model
	end
	local carriedBy = {} -- Art -> Spieler
	local function carrying(player)
		local list = {}
		for kind, who in carriedBy do
			if who == player then
				table.insert(list, kind)
			end
		end
		return list
	end
	local function giveCarried(player, kind)
		attachToHand(player, "Carried_" .. kind, BUILDERS[kind])
	end
	local respawnHooked = {}
	local function hookRespawn(player)
		if respawnHooked[player] then
			return
		end
		respawnHooked[player] = true
		player.CharacterAdded:Connect(function()
			task.wait(1)
			for _, kind in carrying(player) do
				giveCarried(player, kind)
			end
		end)
	end

	------------------------------------------------------------------ Liste oben im Bild
	local items = {} -- Art -> { model, spot, prompt, placed }
	local function showObjectives()
		local list = {}
		for _, kind in { "chemicals", "powder" } do
			local item = items[kind]
			local state = item and (item.placed and "am Pult" or (carriedBy[kind] and ("trägt " .. carriedBy[kind].DisplayName) or "gesucht (liegt mehrmals im Haus)")) or "gesucht"
			table.insert(list, { text = LABELS[kind] .. " – " .. state, done = item ~= nil and item.placed == true })
		end
		event:FireAllClients({ type = "objectives", title = "Für den Safe", items = list })
	end

	------------------------------------------------------------------ Sarp: Rundgang, bemerken, verfolgen
	local E, K = Mansion.FLOORS.E, Mansion.FLOORS.K
	local function route(list)
		local out = {}
		for _, p in list do
			table.insert(out, point(p[1], p[2], p[3]))
		end
		return out
	end
	-- Während der Suche: durchs ganze Haus (Erdgeschoss, Keller, oben im langen Flur)
	local SEARCH_ROUTE = route({
		{ 48, 66, E }, { 51.4, 58, E }, { 51.4, 50, E }, { 46, 46, E }, { 44, 40, E }, { 48, 37, E }, { 51.6, 35.6, E },
		{ 52.1, 33.5, E }, { 52.1, 22.6, K }, { 48, 26, K }, { 43, 31, K }, { 42, 34.5, K }, { 42, 38, K }, { 54, 38, K },
		{ 61, 33, K }, { 54, 38, K }, { 42, 38, K }, { 34, 40, K }, { 26, 47, K }, { 34, 40, K }, { 42, 38, K }, { 42, 34.5, K },
		{ 43, 31, K }, { 48, 26, K }, { 52.1, 22.6, K }, { 52.1, 33.5, E }, { 48, 37, E }, { 44, 40, E }, { 46, 46, E },
		{ 51.4, 50, E }, { 51.4, 58, E }, { 48, 66, E }, { 43.8, 69.3, E }, { 43.7, 68.2, E }, { 43.7, 59.3, O }, { 50, 57, O },
		{ 54.25, 56.3, O }, { 58, 56.3, O }, { 66, 54.5, O }, { 68, 51, O }, { 64.6, 44, O }, { 63, 37.6, O }, { 46, 37, O },
		{ 40, 37, O }, { 46, 37, O }, { 63, 37.6, O }, { 64.6, 44, O }, { 68, 51, O }, { 66, 54.5, O }, { 58, 56.3, O },
		{ 54.25, 56.3, O }, { 50, 57, O }, { 43.7, 59.3, O }, { 43.7, 68.2, E }, { 43.8, 69.3, E },
	})
	-- Beim Schleichen am Ende: nur im Erdgeschoss (Halle, Flur, Küche), wo der Kerzenweg langführt
	local SNEAK_ROUTE = route({
		{ 48, 66, E }, { 51.4, 58, E }, { 51.4, 50, E }, { 46, 46, E }, { 44, 40, E }, { 48, 37, E }, { 51, 36.5, E },
		{ 48, 37, E }, { 44, 40, E }, { 46, 46, E }, { 51.4, 50, E }, { 51.4, 58, E },
	})
	local function patrolPhase()
		return phase == "search" or phase == "bomb" or phase == "sneak"
	end
	-- Bemerkt er diesen Spieler? Im Raum hinter Tür 1 ist man sicher.
	local function notices(player)
		local root, humanoid = rootOf(player)
		local sarpRoot = sarp and sarp:FindFirstChild("HumanoidRootPart")
		if not (root and humanoid and sarpRoot) or not alive(player) or hidden[player] or caught[player] then
			return false
		end
		if Mansion.inRoom(root.Position, "tuer1", "O") then
			return false
		end
		local feet = Wagners.ground(sarp)
		if math.abs(root.Position.Y - feet.Y - 3) > 7 then
			return false
		end
		local distance = (root.Position - sarpRoot.Position).Magnitude
		local sneaking = player:GetAttribute("Sneaking") == true
		local moving = false
		pcall(function()
			moving = humanoid.MoveDirection.Magnitude > 0.1
		end)
		if moving and not sneaking and distance < HEAR_DISTANCE then
			return true -- gehört
		end
		local lightOn = player:GetAttribute("CandleMode") == "red" and not player:GetAttribute("LightOff")
		local limit = lightOn and LIGHT_SEE_DISTANCE or (sneaking and SNEAK_SEE_DISTANCE or SEE_DISTANCE)
		if distance < limit then
			local eye = sarpRoot.Position + Vector3.new(0, 2.5, 0)
			return kit.clearLine(eye, root.Position, { sarp, player.Character })
		end
		return false
	end
	local searchHideSpot -- (weiter unten)
	local function chase(player)
		event:FireClient(player, { type = "chased", text = "Er hat dich bemerkt – lauf! (Sicher bist du nur in Großmutters Zimmer)" })
		kit.whisper(Script.SARP_WHISPERS[math.random(1, #Script.SARP_WHISPERS)])
		local lostSince
		local giveUp = os.clock() + 25
		local hidSpot, sawIt
		while patrolPhase() and os.clock() < giveUp do
			local root = rootOf(player)
			if hidden[player] then
				-- vor seinen Augen versteckt? Dann schaut er dort nach
				hidSpot = hidden[player]
				local sarpRoot = sarp:FindFirstChild("HumanoidRootPart")
				sawIt = sarpRoot ~= nil and (sarpRoot.Position - hidSpot.place.Position).Magnitude < 9 and lostSince == nil
				break
			end
			if not root or not alive(player) or caught[player] then
				break
			end
			if notices(player) then
				lostSince = nil
			else
				lostSince = lostSince or os.clock()
				if os.clock() - lostSince > 2.5 then
					break
				end
			end
			local feet = Wagners.ground(sarp)
			local target = root.Position - Vector3.new(0, footOffset(player), 0)
			if Mansion.walkDistance(feet, target) <= CATCH_DISTANCE and not Mansion.inRoom(root.Position, "tuer1", "O") then
				catchPlayer(player, 2.5)
				break
			end
			kit.sarpWalk({ kit.nextWaypoint(feet, target) }, CHASE_SPEED, function()
				return not patrolPhase() or (lostSince ~= nil and os.clock() - lostSince > 0.5)
			end)
		end
		if hidSpot and patrolPhase() then
			searchHideSpot(hidSpot, sawIt)
			return
		end
		event:FireClient(player, { type = "lost" })
		SarpStage2.look(sarp, 0.5, 0)
		task.wait(1)
		SarpStage2.look(sarp, -0.5, 0)
		task.wait(1)
		SarpStage2.look(sarp, 0, 0)
	end
	-- Er hat einen sich verstecken sehen (oder fast): dort nachschauen
	searchHideSpot = function(spot, sawIt)
		local giveUp = os.clock() + 12
		while patrolPhase() and os.clock() < giveUp do
			local feet = Wagners.ground(sarp)
			if (spot.search - feet).Magnitude < 1.5 then
				break
			end
			kit.sarpWalk({ kit.nextWaypoint(feet, spot.search) }, CHASE_SPEED * 0.7, function()
				return not patrolPhase()
			end)
		end
		if not patrolPhase() then
			return
		end
		local feet = Wagners.ground(sarp)
		local target = spot.place.Position
		Wagners.place(sarp, feet, Vector3.new(target.X, feet.Y, target.Z))
		SarpStage2.look(sarp, 0, spot.kind == "lie" and 0.9 or 0.15)
		sfx("sarpBreath", target + Vector3.new(0, 2, 0), { volume = 1.4, maxDistance = 30 })
		if spot.occupant then
			event:FireClient(spot.occupant, { type = "nearScare", seconds = 3 })
			kit.whisper(Script.SARP_WHISPERS[math.random(1, #Script.SARP_WHISPERS)])
		end
		task.wait(3)
		SarpStage2.look(sarp, 0, 0)
		-- hat er gesehen, wie man hineingeht, zieht er einen heraus
		if sawIt and spot.occupant and patrolPhase() then
			catchPlayer(spot.occupant, 2.5)
		else
			kit.whisper(Script.SARP_LEAVES)
		end
	end
	-- Lärm (die Familie hat jemanden gepackt): er geht genau dorthin
	local alertAt
	local function investigate(goal)
		local giveUp = os.clock() + 25
		while patrolPhase() and os.clock() < giveUp do
			local feet = Wagners.ground(sarp)
			if (goal - feet).Magnitude < 3 then
				break
			end
			local noticed
			kit.sarpWalk({ kit.nextWaypoint(feet, goal) }, ALERT_SPEED, function()
				if not patrolPhase() then
					return true
				end
				for _, player in Players:GetPlayers() do
					if notices(player) then
						noticed = player
						return true
					end
				end
				return false
			end)
			if noticed then
				return noticed
			end
		end
		-- umschauen
		for _, yaw in { 0.6, -0.6, 0 } do
			SarpStage2.look(sarp, yaw, 0)
			task.wait(0.8)
		end
		return nil
	end
	-- nächster Punkt des Rundgangs, möglichst auf demselben Stockwerk (nicht durch die Decke)
	local function nearestOnFloor(path, fallback)
		local feet = Wagners.ground(sarp)
		local nearest, nearestDistance = fallback, math.huge
		for i, p in path do
			local flat = Vector3.new(p.X - feet.X, 0, p.Z - feet.Z).Magnitude
			local d = flat + math.abs(p.Y - feet.Y) * 20
			if d < nearestDistance and (math.abs(p.Y - feet.Y) < 3 or nearestDistance == math.huge) then
				nearest, nearestDistance = i, d
			end
		end
		return nearest
	end
	local patrolRunning = false
	local function sarpPatrol(path)
		if not sarp then
			return
		end
		patrolRunning = true
		Wagners.place(sarp, path[1], path[2])
		local index = 1
		while patrolPhase() do
			if alertAt then
				local goal = alertAt
				alertAt = nil
				local noticed = investigate(goal)
				if noticed and patrolPhase() then
					chase(noticed)
				end
				index = nearestOnFloor(path, index)
			end
			local target = path[index % #path + 1]
			local noticed
			local reached = kit.sarpWalk({ target }, PATROL_SPEED, function()
				if not patrolPhase() then
					return true
				end
				for _, player in Players:GetPlayers() do
					if notices(player) then
						noticed = player
						return true
					end
				end
				return false
			end)
			if noticed and patrolPhase() then
				chase(noticed)
				-- weiter beim nächsten Punkt seines Rundgangs
				index = nearestOnFloor(path, index)
			elseif reached then
				index = index % #path + 1
			end
		end
		Wagners.place(sarp, kit.away, ctx.facing)
		patrolRunning = false
	end

	------------------------------------------------------------------ 1. Richard im Raum
	local mr = kit.mr
	if mr then
		Wagners.place(mr, room.richard, room.richardLook)
		mr:SetAttribute("Look", "player")
	end
	ctx.setMovement(true)
	ctx.actions.redCandles = function()
		ctx.setCandleMode("red")
		event:FireAllClients({ type = "redCandle" })
		sfx("doorCreak", room.richard + Vector3.new(0, 3, 0), { volume = 0.3, speed = 2 })
	end
	ctx.runScript(Script.ESCAPE_INTRO, "Flucht")
	if mr then
		mr:SetAttribute("Look", "down")
	end
	if #Players:GetPlayers() >= 2 then
		lineAsync("splitUp")
	end

	------------------------------------------------------------------ 2. Suchen
	phase = "search"
	remotes:SetAttribute("SneakAllowed", true)
	local itemFolder = Instance.new("Folder")
	itemFolder.Name = "EscapeItems"
	itemFolder.Parent = Mansion.model or workspace
	local LIFT = { chemicals = 0.37, powder = 0.45 } -- Modell-Unterkante auf die Fläche
	for _, kind in { "chemicals", "powder" } do
		-- mehrere verschiedene Plätze auslosen: einer oben (schnell zu finden), die anderen unten
		local upstairs, downstairs = {}, {}
		for _, spot in room.items[kind] do
			table.insert(spot.at.Y > Mansion.FLOORS.O and upstairs or downstairs, spot)
		end
		local chosen = {}
		if #upstairs > 0 then
			table.insert(chosen, upstairs[math.random(1, #upstairs)])
		end
		for _ = 1, math.min(ITEM_COPIES - #chosen, #downstairs) do
			table.insert(chosen, table.remove(downstairs, math.random(1, #downstairs)))
		end
		local item = { models = {}, placed = false }
		items[kind] = item
		for _, spot in chosen do
			print("[Kapitel2] " .. LABELS[kind] .. ": " .. spot.name)
			local model = buildWorldModel(kind, CFrame.new(spot.at + Vector3.new(0, LIFT[kind] + 0.02, 0)) * CFrame.Angles(0, math.rad(spot.yaw or 0), 0), itemFolder)
			-- Glimmen und ein dünner Umriss (auch durch Wände sichtbar), damit man es leicht findet
			local glow = Instance.new("PointLight")
			glow.Range = 8
			glow.Brightness = 0.9
			glow.Color = Color3.fromRGB(255, 200, 150)
			glow.Parent = model.PrimaryPart
			local outline = Instance.new("Highlight")
			outline.FillTransparency = 1
			outline.OutlineColor = Color3.fromRGB(255, 214, 140)
			outline.OutlineTransparency = 0.4
			outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			outline.Parent = model
			local prompt = Instance.new("ProximityPrompt")
			prompt.ObjectText = LABELS[kind]
			prompt.ActionText = "Nehmen"
			prompt.HoldDuration = 0.5
			prompt.MaxActivationDistance = 7
			prompt.RequiresLineOfSight = false
			prompt.Parent = model.PrimaryPart
			table.insert(item.models, model)
			prompt.Triggered:Connect(function(player)
				if carriedBy[kind] or item.placed or item.model or (phase ~= "search" and phase ~= "bomb") then
					return
				end
				-- zu zweit trägt jeder nur eins (man soll sich aufteilen)
				if #Players:GetPlayers() >= 2 and #carrying(player) >= 1 then
					hint("Du trägst schon etwas. Das muss dein Partner tragen.", 3, player)
					return
				end
				-- dieses nehmen, die anderen verschwinden
				item.model, item.spot, item.prompt = model, spot, prompt
				for _, other in item.models do
					if other ~= model then
						other:Destroy()
					end
				end
				carriedBy[kind] = player
				model.Parent = nil
				giveCarried(player, kind)
				hookRespawn(player)
				sfx("doorCreak", spot.at, { volume = 0.3, speed = 1.8 })
				lineAsync(kind == "chemicals" and "gotChemicals" or "gotPowder")
				hint(player.DisplayName .. " hat " .. WITH_ARTICLE[kind] .. ". Zurück zum Pult in Großmutters Zimmer.", 5)
				showObjectives()
			end)
		end
	end
	showObjectives()
	hint("Sucht Chemikalien und Schießpulver im Haus – oben, im Erdgeschoss und im Keller. Sie leuchten schwach.", 8)
	-- wer das Spiel verlässt, lässt seine Sachen fallen (sie liegen dann wieder am Fundort)
	local leavingConnection = Players.PlayerRemoving:Connect(function(player)
		for _, kind in carrying(player) do
			carriedBy[kind] = nil
			local item = items[kind]
			if item and not item.placed and item.model then
				item.model.Parent = itemFolder
			end
		end
		hidden[player] = nil
		caught[player] = nil
	end)

	-- Sarp läuft ab jetzt durchs ganze Haus (Hauptgefahr)
	task.spawn(sarpPatrol, SEARCH_ROUTE)
	hint("Sarp ist im Haus. Licht aus (F) und Schleichen (C) machen dich unauffälliger.", 7)

	-- Die Familie: taucht außer Sicht auf, kommt auf einen zu und packt einen.
	-- Dann Quick-Time-Event: schnell tippen, um sich loszureißen (sonst Schaden).
	-- Länger als FAMILY_TIME Sekunden bleibt niemand in der Nähe.
	local members = {}
	for name, model in kit.members or {} do
		if model then
			table.insert(members, { name = name, model = model })
		end
	end
	local qteEvent = remotes:FindFirstChild("Qte")
	local qteResult = {}
	if qteEvent then
		qteEvent.OnServerEvent:Connect(function(player, freed)
			qteResult[player] = freed == true
		end)
	end
	-- gepackt: man kann sich nicht bewegen, bis man sich losgerissen hat (oder die Zeit um ist)
	local function grab(player, member)
		local _, humanoid = rootOf(player)
		if not humanoid then
			return true
		end
		qteResult[player] = nil
		player:SetAttribute("Grabbed", true)
		humanoid.WalkSpeed = 0
		event:FireClient(player, { type = "qte", taps = QTE_TAPS, seconds = QTE_SECONDS, name = Script.NAMES[member.name] or "" })
		local deadline = os.clock() + QTE_SECONDS + 1.5
		while qteResult[player] == nil and os.clock() < deadline do
			task.wait(0.1)
		end
		local freed = qteResult[player] == true
		player:SetAttribute("Grabbed", nil)
		if humanoid.Health > 0 then
			humanoid.WalkSpeed = speedFor(player)
		end
		return freed
	end
	local function sameFloorPlayers(position)
		local list = {}
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and alive(player) and not hidden[player] and not caught[player] and math.abs(root.Position.Y - position.Y - 3) < 7 then
				table.insert(list, { player = player, root = root, distance = (root.Position - position).Magnitude })
			end
		end
		table.sort(list, function(a, b)
			return a.distance < b.distance
		end)
		return list
	end
	local function familyHunt()
		task.wait(FAMILY_FIRST)
		local lastSpot
		while phase == "search" or phase == "bomb" do
			if #members == 0 then
				return
			end
			local member = members[math.random(1, #members)]
			local model = member.model
			local feet
			for _ = 1, 20 do
				local candidate = kit.APPEAR[math.random(1, #kit.APPEAR)]
				local spot = point(candidate[1], candidate[2], Mansion.FLOORS[candidate[3]])
				local near = sameFloorPlayers(spot)[1]
				-- nicht im Raum hinter Tür 1 (dort ist man sicher)
				if candidate ~= lastSpot and near and near.distance > 12 and near.distance < 30 and not Mansion.inRoom(near.root.Position, "tuer1", "O") and not kit.anyoneSees(spot, model) then
					feet, lastSpot = spot, candidate
					break
				end
			end
			if feet then
				kit.setFade(model, 1)
				local target = sameFloorPlayers(feet)[1]
				Wagners.place(model, feet, target and Vector3.new(target.root.Position.X, feet.Y, target.root.Position.Z) or feet + Vector3.new(0, 0, 1))
				model:SetAttribute("Look", "player")
				kit.fade(model, 1, 0, 0.8)
				local spoke = false
				local giveUp = os.clock() + FAMILY_TIME
				while os.clock() < giveUp and (phase == "search" or phase == "bomb") do
					local position = Wagners.ground(model)
					local nearest = sameFloorPlayers(position)[1]
					if not nearest or nearest.distance > 35 or Mansion.inRoom(nearest.root.Position, "tuer1", "O") then
						break
					end
					if not spoke and nearest.distance < 24 then
						spoke = true
						local lines = Script.FAMILY_ANGRY[member.name]
						if lines then
							task.spawn(say, member.name, lines[math.random(1, #lines)])
						end
					end
					local targetFeet = nearest.root.Position - Vector3.new(0, footOffset(nearest.player), 0)
					if Mansion.walkDistance(position, targetFeet) <= CATCH_DISTANCE and not nearest.player:GetAttribute("Grabbed") then
						-- packen: Quick-Time-Event
						Wagners.place(model, position, targetFeet)
						sfx("jumpscare", nearest.root.Position, { volume = 0.9, maxDistance = 40, speed = 1.5 })
						local grabbedAt = targetFeet
						local freed = grab(nearest.player, member)
						if freed then
							event:FireClient(nearest.player, { type = "hint", text = "Losgerissen! Lauf – er hat es gehört!", seconds = 3 })
						else
							event:FireClient(nearest.player, { type = "hurt" })
							if ctx.loseHeart then
								ctx.loseHeart(nearest.player, member.name)
							end
						end
						-- der Lärm lockt Sarp an: er kommt genau dorthin
						alertAt = grabbedAt
						break
					end
					local waypoint = kit.nextWaypoint(position, targetFeet)
					if (waypoint - position).Magnitude < 0.3 then
						waypoint = targetFeet
					end
					ctx.walkPath(model, { { at = waypoint } }, FAMILY_SPEED, kit.steps)
				end
				model:SetAttribute("Look", "down")
				kit.fade(model, 0, 1, 0.6)
				Wagners.place(model, ctx.hiddenSpot, ctx.facing)
				kit.setFade(model, 0)
			end
			task.wait(math.random(FAMILY_PAUSE_MIN, FAMILY_PAUSE_MAX))
		end
	end
	task.spawn(familyHunt)

	------------------------------------------------------------------ 3. Pult und Safe
	local pultPart = Instance.new("Part")
	pultPart.Name = "EscapePult"
	pultPart.Size = Vector3.new(1, 1, 1)
	pultPart.Transparency = 1
	pultPart.Anchored = true
	pultPart.CanCollide = false
	pultPart.CanTouch = false
	pultPart.CFrame = room.pultPrompt
	pultPart.Parent = holder
	local pultPrompt = Instance.new("ProximityPrompt")
	pultPrompt.ObjectText = "Pult"
	pultPrompt.ActionText = "Ablegen"
	pultPrompt.HoldDuration = 0.4
	pultPrompt.MaxActivationDistance = 7
	pultPrompt.RequiresLineOfSight = false
	pultPrompt.Parent = pultPart
	local safePart = Instance.new("Part")
	safePart.Name = "EscapeSafe"
	safePart.Size = Vector3.new(1, 1, 1)
	safePart.Transparency = 1
	safePart.Anchored = true
	safePart.CanCollide = false
	safePart.CanTouch = false
	safePart.CFrame = room.safeFront
	safePart.Parent = holder
	local safePrompt = Instance.new("ProximityPrompt")
	safePrompt.ObjectText = "Safe"
	safePrompt.ActionText = "Ladung anbringen"
	safePrompt.HoldDuration = 0.8
	safePrompt.MaxActivationDistance = 7
	safePrompt.RequiresLineOfSight = false
	safePrompt.Enabled = false
	safePrompt.Parent = safePart

	local PULT_SLOTS = { chemicals = CFrame.new(0, 0.2, 0.55), powder = CFrame.new(0, 0.2, -0.55) }
	local bombStep = "collect" -- collect, build, take, attach, light, lit
	local chargeModel, chargeHolder
	pultPrompt.Triggered:Connect(function(player)
		if bombStep == "collect" then
			local mine = carrying(player)
			if #mine == 0 then
				hint("Bring Chemikalien und Schießpulver hierher.", 3, player)
				return
			end
			for _, kind in mine do
				local item = items[kind]
				item.placed = true
				carriedBy[kind] = nil
				dropFromHand(player, "Carried_" .. kind)
				item.model.Parent = itemFolder
				item.model:PivotTo(room.pult * PULT_SLOTS[kind])
				item.prompt.Enabled = false
			end
			sfx("doorCreak", room.pult.Position, { volume = 0.3, speed = 1.6 })
			showObjectives()
			if items.chemicals.placed and items.powder.placed then
				bombStep = "build"
				phase = "bomb"
				pultPrompt.ActionText = "Zusammenbauen"
				pultPrompt.HoldDuration = 2
				lineAsync("bothPlaced")
				hint("Halte E am Pult gedrückt: zusammenbauen.", 5)
			else
				lineAsync("firstPlaced")
			end
		elseif bombStep == "build" then
			bombStep = "building"
			pultPrompt.Enabled = false
			-- beide Sachen rutschen zusammen und werden zu einer Ladung
			local from = { chemicals = items.chemicals.model:GetPivot(), powder = items.powder.model:GetPivot() }
			local middle = room.pult * CFrame.new(0, 0.2, 0)
			for i = 1, 10 do
				for kind, start in from do
					items[kind].model:PivotTo(start:Lerp(middle, i / 10))
				end
				task.wait(0.08)
			end
			sfx("doorCreak", room.pult.Position, { volume = 0.4, speed = 0.8 })
			for _, kind in { "chemicals", "powder" } do
				items[kind].model:Destroy()
			end
			chargeModel = buildWorldModel("charge", middle, itemFolder)
			bombStep = "take"
			pultPrompt.ActionText = "Ladung nehmen"
			pultPrompt.HoldDuration = 0.4
			pultPrompt.Enabled = true
			event:FireAllClients({ type = "objectives", title = "Für den Safe", items = { { text = "Ladung an den Safe bringen", done = false } } })
			lineAsync("built")
		elseif bombStep == "take" then
			bombStep = "attach"
			chargeHolder = player
			chargeModel.Parent = nil
			attachToHand(player, "Carried_charge", BUILDERS.charge)
			pultPrompt.Enabled = false
			safePrompt.Enabled = true
			hint("Bring die Ladung zum Safe.", 4)
		end
	end)

	local lit = false
	safePrompt.Triggered:Connect(function(player)
		if bombStep == "attach" then
			if player ~= chargeHolder then
				hint((chargeHolder and chargeHolder.DisplayName or "Jemand") .. " hat die Ladung.", 3, player)
				return
			end
			dropFromHand(player, "Carried_charge")
			chargeModel.Parent = itemFolder
			chargeModel:PivotTo(room.safeFront * CFrame.new(0, -0.6, 0.15))
			bombStep = "richardLeaving"
			safePrompt.Enabled = false
			safePrompt.ActionText = "Lunte anzünden"
			safePrompt.HoldDuration = 1
			-- Richard geht vorher raus; erst dann kann man die Lunte anzünden
			task.spawn(function()
				line("onSafe")
				if mr then
					mr:SetAttribute("Look", "down")
					ctx.walkPath(mr, { { at = room.sarpEnter }, { at = room.doorOutside } }, 7, kit.steps)
					Wagners.place(mr, ctx.hiddenSpot, ctx.facing)
				end
				bombStep = "light"
				safePrompt.Enabled = true
				event:FireAllClients({ type = "objectives", title = "Für den Safe", items = { { text = "Lunte mit der Kerze anzünden", done = false } } })
				hint("Richard ist weg. Zünde die Lunte mit deiner Kerze an.", 5)
			end)
		elseif bombStep == "light" then
			if player:GetAttribute("LightOff") then
				hint("Du brauchst Licht: mach deine Kerze an (F).", 3, player)
				return
			end
			bombStep = "lit"
			safePrompt.Enabled = false
			lit = true
		end
	end)

	-- Richard bleibt am Pult, bis die Lunte brennt
	while not lit do
		-- wer stirbt, während er die Ladung trägt: sie liegt wieder auf dem Pult
		if bombStep == "attach" and chargeHolder and not alive(chargeHolder) then
			dropFromHand(chargeHolder, "Carried_charge")
			chargeHolder = nil
			chargeModel.Parent = itemFolder
			chargeModel:PivotTo(room.pult * CFrame.new(0, 0.2, 0))
			bombStep = "take"
			pultPrompt.Enabled = true
			safePrompt.Enabled = false
		end
		task.wait(0.25)
	end
	leavingConnection:Disconnect()

	------------------------------------------------------------------ 4. Die Lunte brennt
	local fuseTip = chargeModel and chargeModel:FindFirstChild("Fuse")
	local sparks
	pcall(function()
		sparks = Instance.new("Sparkles")
		sparks.SparkleColor = Color3.fromRGB(255, 180, 80)
		sparks.Parent = fuseTip
	end)
	sfx("fuse", room.safeFront.Position, { volume = 1.4, maxDistance = 40 })
	hint("Versteck dich! Schrank, hinter dem Bett oder in der Truhe!", FUSE_TIME)
	event:FireAllClients({ type = "objectives", clear = true })
	lineAsync("lit")
	for t = FUSE_TIME, 1, -1 do
		if t <= 3 then
			hint(tostring(t) .. " …", 1)
		end
		task.wait(1)
	end

	------------------------------------------------------------------ Explosion
	phase = "blast"
	local blastAt = room.safeFront.Position
	sfx("explosion", blastAt, { volume = 3, maxDistance = 400 })
	event:FireAllClients({ type = "explosion", position = blastAt })
	pcall(function()
		local blast = Instance.new("Explosion")
		blast.Position = blastAt
		blast.BlastRadius = 6
		blast.BlastPressure = 0
		blast.DestroyJointRadiusPercent = 0
		blast.ExplosionType = Enum.ExplosionType.NoCraters
		blast.Parent = workspace
	end)
	if chargeModel then
		chargeModel:Destroy()
	end
	-- die Safetür fliegt weg
	local door = room.safeDoor
	if door and door.PrimaryPart then
		pcall(function()
			for _, part in door:GetDescendants() do
				if part:IsA("BasePart") and part ~= door.PrimaryPart then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = door.PrimaryPart
					weld.Part1 = part
					weld.Parent = part
				end
			end
			for _, part in door:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = true
				end
			end
			local outward = (room.safeFront.Position - room.safeInside.Position) * Vector3.new(1, 0, 1)
			outward = outward.Magnitude > 0.01 and outward.Unit or Vector3.new(0, 0, 1)
			door.PrimaryPart.AssemblyLinearVelocity = outward * 28 + Vector3.new(0, 12, 0)
			door.PrimaryPart.AssemblyAngularVelocity = Vector3.new(4, 2, 0)
		end)
	end
	-- Rauch aus dem Safe
	pcall(function()
		local smoke = Instance.new("Smoke")
		smoke.Color = Color3.fromRGB(60, 58, 56)
		smoke.Opacity = 0.35
		smoke.RiseVelocity = 3
		smoke.Size = 4
		smoke.Parent = safePart
		task.delay(10, function()
			smoke.Enabled = false
		end)
	end)
	for _, player in Players:GetPlayers() do
		local root, humanoid = rootOf(player)
		if root and humanoid and not hidden[player] and (root.Position - blastAt).Magnitude < 10 then
			event:FireClient(player, { type = "hurt" })
			if ctx.loseHeart then
				ctx.loseHeart(player, "Explosion")
			else
				humanoid:TakeDamage(BLAST_DAMAGE)
			end
		end
	end
	-- die Kerzen sind weg (fliegen einem bei der Explosion aus der Hand)
	ctx.setCandleMode("none")
	event:FireAllClients({ type = "candleLost" })
	remotes:SetAttribute("SneakAllowed", true)
	-- der Schlüssel liegt im offenen Safe (nehmen kann man ihn, wenn Sarp wieder weg ist)
	local keyModel = buildWorldModel("key", room.safeInside * CFrame.Angles(0, math.rad(70), 0), itemFolder)
	local keyLight = Instance.new("PointLight")
	keyLight.Range = 4
	keyLight.Brightness = 0.8
	keyLight.Color = Color3.fromRGB(255, 210, 140)
	keyLight.Parent = keyModel.PrimaryPart
	local keyPrompt = Instance.new("ProximityPrompt")
	keyPrompt.ObjectText = "Schlüssel"
	keyPrompt.ActionText = "Nehmen"
	keyPrompt.HoldDuration = 0.4
	keyPrompt.MaxActivationDistance = 7
	keyPrompt.RequiresLineOfSight = false
	keyPrompt.Enabled = false
	keyPrompt.Parent = keyModel.PrimaryPart
	task.wait(2)
	line("candleLost")

	------------------------------------------------------------------ 5. Sarp kommt hoch und sucht
	sfx("sarpRoar", point(48, 66, Mansion.FLOORS.E + 4), { volume = 3, maxDistance = 500 })
	event:FireAllClients({ type = "dim", level = 0.4, duration = 1 })
	task.spawn(line, "heHeard")
	hint("Versteck dich! Er kommt!", 5)
	task.wait(3)
	local function sarpSays(list)
		kit.whisper(list[math.random(1, #list)])
	end
	local searchingRoom = false
	local function interruptedInRoom()
		if not searchingRoom then
			return false
		end
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and alive(player) and not hidden[player] and not caught[player] and Mansion.inRoom(root.Position, "tuer1", "O") then
				return true
			end
		end
		return false
	end
	local function catchVisibleInRoom()
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and alive(player) and not hidden[player] and not caught[player] and Mansion.inRoom(root.Position, "tuer1", "O") then
				catchPlayer(player)
			end
		end
	end
	-- (der Rundgang von vorhin ist vorbei, bevor er hochkommt)
	local stopWait = os.clock()
	while patrolRunning and os.clock() - stopWait < 6 do
		task.wait(0.1)
	end
	if sarp then
		Wagners.place(sarp, room.sarpStart, room.sarpApproach[1])
		sarpSays(Script.SARP_ALERT)
		kit.sarpWalk(room.sarpApproach, RUSH_SPEED) -- wütend: er rennt hoch
		searchingRoom = true
		kit.sarpWalk({ room.sarpEnter }, SEARCH_SPEED, interruptedInRoom)
		catchVisibleInRoom()
		-- einmal durchs Zimmer laufen (nicht in jedes Versteck schauen), dann wieder raus
		for _, at in room.sarpRoomWalk do
			kit.sarpWalk({ at }, SEARCH_SPEED, interruptedInRoom)
			catchVisibleInRoom()
			local sarpRoot = sarp:FindFirstChild("HumanoidRootPart")
			for _, spot in room.hideSpots do
				if spot.occupant and sarpRoot and (spot.place.Position - sarpRoot.Position).Magnitude < 7 then
					event:FireClient(spot.occupant, { type = "nearScare", seconds = 2.5 })
				end
			end
			if math.random() < 0.4 then
				sfx("sarpBreath", sarpRoot and sarpRoot.Position or at, { volume = 1.2, maxDistance = 30 })
			end
			task.wait(0.6)
		end
		searchingRoom = false
		kit.whisper(Script.SARP_LEAVES)
		local back = { room.sarpEnter }
		for i = #room.sarpApproach, 1, -1 do
			table.insert(back, room.sarpApproach[i])
		end
		table.insert(back, room.sarpStart)
		kit.sarpWalk(back, SEARCH_SPEED)
	end
	-- wer erwischt wurde, macht im Raum weiter
	for _, player in Players:GetPlayers() do
		if caught[player] then
			restartPlayer(player)
		end
	end
	task.wait(1.5)

	------------------------------------------------------------------ 6. Rote Kerzen, Schlüssel, schleichen
	phase = "sneak"
	local pathFolder = Instance.new("Model")
	pathFolder.Name = "EscapePathCandles"
	pathFolder.Parent = Mansion.model or workspace
	for _, at in room.path do
		local base = Instance.new("Part")
		base.Name = "RedPathCandle"
		base.Shape = Enum.PartType.Cylinder
		base.Size = Vector3.new(0.7, 0.28, 0.28)
		base.CFrame = CFrame.new(at + Vector3.new(0, 0.35, 0)) * upright
		base.Color = Color3.fromRGB(110, 20, 18)
		base.Material = Enum.Material.SmoothPlastic
		base.Anchored = true
		base.CanCollide = false
		base.CanTouch = false
		base.CastShadow = false
		base.Parent = pathFolder
		local flame = Instance.new("Part")
		flame.Name = "CandleFlame"
		flame.Shape = Enum.PartType.Ball
		flame.Size = Vector3.new(0.18, 0.18, 0.18)
		flame.CFrame = CFrame.new(at + Vector3.new(0, 0.82, 0))
		flame.Color = Color3.fromRGB(255, 40, 30)
		flame.Material = Enum.Material.Neon
		flame.Anchored = true
		flame.CanCollide = false
		flame.CanTouch = false
		flame.CastShadow = false
		flame.Parent = pathFolder
		local light = Instance.new("PointLight")
		light.Name = "CandleLight" -- flackert auf dem Client wie die anderen Kerzen
		light.Range = 9
		light.Brightness = 1.3
		light.Color = Color3.fromRGB(255, 30, 24)
		light.Parent = flame
	end
	local keyHolder
	keyPrompt.Triggered:Connect(function(player)
		if keyHolder then
			return
		end
		keyHolder = player
		keyModel.Parent = nil
		attachToHand(player, "Carried_key", BUILDERS.key)
		player.CharacterAdded:Connect(function()
			task.wait(1)
			if keyHolder == player then
				attachToHand(player, "Carried_key", BUILDERS.key)
			end
		end)
		event:FireAllClients({ type = "objectives", title = "Raus hier", items = { { text = "Schlüssel – trägt " .. player.DisplayName, done = true }, { text = "Den roten Kerzen folgen", done = false } } })
		task.spawn(function()
			line("takeKey")
			line("sneakHint")
		end)
		hint("C: Schleichen – dann hört er dich nicht. Er sieht dich nur, wenn er ganz nah ist.", 8)
	end)
	Players.PlayerRemoving:Connect(function(player)
		if player == keyHolder then
			-- der Schlüssel liegt wieder im Safe
			keyHolder = nil
			keyModel.Parent = itemFolder
		end
	end)
	keyPrompt.Enabled = true
	event:FireAllClients({ type = "objectives", title = "Raus hier", items = { { text = "Schlüssel aus dem Safe nehmen", done = false } } })
	task.spawn(function()
		line("afterSearch")
		if not keyHolder then
			hint("Nimm den Schlüssel aus dem Safe.", 5)
		end
	end)

	-- Regal vor dem Geheimgang: mit dem Schlüssel aufschließen
	local shelf = Mansion.secretShelf
	local shelfOpen = false
	local shelfPart
	if shelf then
		for _, part in shelf:GetDescendants() do
			if part:IsA("BasePart") then
				shelfPart = shelfPart or part
			end
		end
	end
	if shelfPart then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Regal"
		prompt.ActionText = "Aufschließen"
		prompt.HoldDuration = 0.8
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = shelfPart
		prompt.Triggered:Connect(function(player)
			if shelfOpen then
				return
			end
			if player ~= keyHolder then
				hint("Hinter dem Regal ist ein Schlüsselloch. " .. (keyHolder and (keyHolder.DisplayName .. " hat den Schlüssel.") or "Der Schlüssel liegt im Safe."), 4, player)
				lineAsync("shelfLocked")
				return
			end
			shelfOpen = true
			prompt.Enabled = false
			sfx("doorCreak", shelfPart.Position, { volume = 1, speed = 0.5 })
			local start = shelf:GetPivot()
			local offset = Mansion.origin.RightVector * 3.8 -- nach rechts (Plan +x) weg
			for i = 1, 20 do
				shelf:PivotTo(start + offset * (i / 20))
				task.wait(0.06)
			end
			event:FireAllClients({ type = "objectives", title = "Raus hier", items = { { text = "Durch den Geheimgang", done = false } } })
			lineAsync("shelfOpen")
		end)
	end

	-- Im Schleichen läuft Sarp nur im Erdgeschoss (dort, wo der Kerzenweg langführt)
	task.spawn(sarpPatrol, SNEAK_ROUTE)

	------------------------------------------------------------------ 7. Ritualraum: schwarz
	while true do
		local entered
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and Mansion.inRoom(root.Position, "ritual", "K") then
				entered = player
			end
		end
		if entered then
			break
		end
		task.wait(0.2)
	end
	phase = "done"
	remotes:SetAttribute("SneakAllowed", false)
	ctx.setMovement(false)
	event:FireAllClients({ type = "objectives", clear = true })
	event:FireAllClients({ type = "alone", instant = true, title = "Der Ritualraum …", subtitle = "Fortsetzung folgt" })
	print("Kapitel 2: Jemand hat den Ritualraum betreten – Bild schwarz (hier geht es später weiter).")
end

return Escape
