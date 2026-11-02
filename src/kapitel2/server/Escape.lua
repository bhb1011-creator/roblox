-- Kapitel 2, die Flucht (startet, sobald jemand den Raum hinter Tür 1 betritt; siehe Night.lua).
--
--  1. Richard wartet am Pult. Er erklärt, was zu tun ist (ohne zu verraten, was mit seiner
--     Familie los ist) und gibt jedem eine rote Kerze. Taschenlampe gibt es keine mehr.
--  2. Man sucht Chemikalien und Schießpulver (je ein ausgeloster Platz, Mansion.escape.items).
--     Die Familie taucht auf, kommt auf einen zu und macht Schaden.
--  3. Am Pult ablegen, zusammenbauen, an den Safe, Lunte mit der Kerze anzünden, verstecken.
--  4. Explosion: der Safe ist offen, die Kerzen sind weg. Sarp hat es gehört, kommt hoch
--     und durchsucht den Raum (Schrank, hinter dem Bett, Truhe).
--  5. Danach: rote Kerzen zeigen den Weg nach unten. Schlüssel nehmen, schleichen (C),
--     Sarp läuft unten herum und ist tödlich (hört einen, wenn man nicht schleicht).
--  6. Der Schlüssel öffnet das Regal vor dem Geheimgang. Wer den Ritualraum betritt: schwarz.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Script = require(ReplicatedStorage.Shared.Kapitel2Dialogue)
local Mansion = require(script.Parent.Mansion)
local Wagners = require(script.Parent.Wagners)
local SarpStage2 = require(script.Parent.SarpStage2)

local Escape = {}

local FAMILY_DAMAGE = 20 -- pro Treffer der Familie
local FAMILY_SPEED = 5.5 -- etwas langsamer als man läuft (8)
local FUSE_TIME = 5 -- Sekunden zum Verstecken nach dem Anzünden
local BLAST_DAMAGE = 35 -- wer nicht versteckt ist und nah am Safe steht
local SEARCH_SPEED = 4.2
local PATROL_SPEED = 3.4
local CHASE_SPEED = 7.2
local HEAR_DISTANCE = 20 -- so weit hört Sarp Spieler, die nicht schleichen
local SEE_DISTANCE = 9 -- im Dunkeln sieht er einen nur aus der Nähe
local SNEAK_SEE_DISTANCE = 6 -- wer schleicht, fällt noch später auf
local CATCH_DISTANCE = 3.2

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
		return root ~= nil and humanoid ~= nil and humanoid.Health > 0
	end

	------------------------------------------------------------------ Neustart-Punkt
	local function checkpointFrame(index)
		local feet = room.checkpoint + Vector3.new((index - 1) * 1.2 - 0.6, 0, 0)
		local look = point(45.4, 43, O)
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
	for _, spot in room.hideSpots do
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
		prompt.ObjectText = spot.label or spot.name
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

	-- Erwischt (von Sarp): Jumpscare, kurz schwarz, dann geht es im Raum hinter Tür 1 weiter
	local function restartPlayer(player)
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
			local state = item and (item.placed and "am Pult" or (carriedBy[kind] and ("trägt " .. carriedBy[kind].DisplayName) or "gesucht")) or "gesucht"
			table.insert(list, { text = LABELS[kind] .. " – " .. state, done = item ~= nil and item.placed == true })
		end
		event:FireAllClients({ type = "objectives", title = "Für den Safe", items = list })
	end

	------------------------------------------------------------------ 1. Richard im Raum
	local mr = kit.mr
	if mr then
		Wagners.place(mr, point(44.6, 48.9, O), point(46.8, 52, O))
		mr:SetAttribute("Look", "player")
	end
	ctx.setMovement(true)
	ctx.actions.redCandles = function()
		ctx.setCandleMode("red")
		event:FireAllClients({ type = "redCandle" })
		sfx("doorCreak", point(44.6, 48.9, O + 3), { volume = 0.3, speed = 2 })
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
	local itemFolder = Instance.new("Folder")
	itemFolder.Name = "EscapeItems"
	itemFolder.Parent = Mansion.model or workspace
	for _, kind in { "chemicals", "powder" } do
		local spots = room.items[kind]
		local spot = spots[math.random(1, #spots)]
		print("[Kapitel2] " .. LABELS[kind] .. " liegen: " .. spot.name)
		local model = buildWorldModel(kind, CFrame.new(spot.at + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, math.random() * 6, 0), itemFolder)
		-- ein ganz schwaches Glimmen, damit man es im Dunkeln findet
		local glow = Instance.new("PointLight")
		glow.Range = 5
		glow.Brightness = 0.6
		glow.Color = Color3.fromRGB(255, 200, 150)
		glow.Parent = model.PrimaryPart
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = LABELS[kind]
		prompt.ActionText = "Nehmen"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 7
		prompt.RequiresLineOfSight = false
		prompt.Parent = model.PrimaryPart
		local item = { model = model, spot = spot, prompt = prompt, placed = false }
		items[kind] = item
		prompt.Triggered:Connect(function(player)
			if carriedBy[kind] or item.placed or phase ~= "search" then
				return
			end
			-- zu zweit trägt jeder nur eins (man soll sich aufteilen)
			if #Players:GetPlayers() >= 2 and #carrying(player) >= 1 then
				hint("Du trägst schon etwas. Das muss dein Partner tragen.", 3, player)
				return
			end
			carriedBy[kind] = player
			model.Parent = nil
			giveCarried(player, kind)
			hookRespawn(player)
			sfx("doorCreak", spot.at, { volume = 0.3, speed = 1.8 })
			lineAsync(kind == "chemicals" and "gotChemicals" or "gotPowder")
			hint(player.DisplayName .. " hat " .. WITH_ARTICLE[kind] .. ". Zurück zum Pult hinter Tür 1.", 5)
			showObjectives()
		end)
	end
	showObjectives()
	hint("Sucht Chemikalien und Schießpulver im ganzen Haus – auch im Keller.", 7)
	-- wer das Spiel verlässt, lässt seine Sachen fallen (sie liegen dann wieder am Fundort)
	local leavingConnection = Players.PlayerRemoving:Connect(function(player)
		for _, kind in carrying(player) do
			carriedBy[kind] = nil
			local item = items[kind]
			if item and not item.placed then
				item.model.Parent = itemFolder
			end
		end
		hidden[player] = nil
		caught[player] = nil
	end)

	-- Die Familie: taucht außer Sicht auf, kommt auf einen zu und schlägt zu (dann weg)
	local members = {}
	for name, model in kit.members or {} do
		if model then
			table.insert(members, { name = name, model = model })
		end
	end
	local function sameFloorPlayers(position)
		local list = {}
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and alive(player) and not hidden[player] and math.abs(root.Position.Y - position.Y - 3) < 7 then
				table.insert(list, { player = player, root = root, distance = (root.Position - position).Magnitude })
			end
		end
		table.sort(list, function(a, b)
			return a.distance < b.distance
		end)
		return list
	end
	local function familyHunt()
		task.wait(15)
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
				-- nicht im Raum hinter Tür 1 (dort ist Richard)
				if candidate ~= lastSpot and near and near.distance > 14 and near.distance < 40 and not Mansion.inRoom(near.root.Position, "tuer1", "O") and not kit.anyoneSees(spot, model) then
					feet, lastSpot = spot, candidate
					break
				end
			end
			if feet then
				kit.setFade(model, 1)
				local target = sameFloorPlayers(feet)[1]
				Wagners.place(model, feet, target and Vector3.new(target.root.Position.X, feet.Y, target.root.Position.Z) or feet + Vector3.new(0, 0, 1))
				model:SetAttribute("Look", "player")
				kit.fade(model, 1, 0, 1)
				local spoke = false
				local giveUp = os.clock() + 25
				while os.clock() < giveUp and (phase == "search" or phase == "bomb") do
					local position = Wagners.ground(model)
					local nearest = sameFloorPlayers(position)[1]
					if not nearest or nearest.distance > 40 or Mansion.inRoom(nearest.root.Position, "tuer1", "O") then
						break
					end
					if not spoke and nearest.distance < 26 then
						spoke = true
						local lines = Script.FAMILY_ANGRY[member.name]
						if lines then
							task.spawn(say, member.name, lines[math.random(1, #lines)])
						end
					end
					local targetFeet = nearest.root.Position - Vector3.new(0, footOffset(nearest.player), 0)
					if (targetFeet - position).Magnitude <= CATCH_DISTANCE then
						-- zuschlagen, dann verschwinden
						Wagners.place(model, position, targetFeet)
						local _, humanoid = rootOf(nearest.player)
						if humanoid then
							humanoid:TakeDamage(FAMILY_DAMAGE)
						end
						sfx("jumpscare", nearest.root.Position, { volume = 1.1, maxDistance = 40, speed = 1.4 })
						event:FireClient(nearest.player, { type = "hurt", health = humanoid and humanoid.Health })
						task.wait(0.3)
						break
					end
					local waypoint = kit.nextWaypoint(position, targetFeet)
					if (waypoint - position).Magnitude < 0.3 then
						waypoint = targetFeet
					end
					ctx.walkPath(model, { { at = waypoint } }, FAMILY_SPEED, kit.steps)
				end
				model:SetAttribute("Look", "down")
				kit.fade(model, 0, 1, 0.7)
				Wagners.place(model, ctx.hiddenSpot, ctx.facing)
				kit.setFade(model, 0)
			end
			task.wait(math.random(10, 18))
		end
	end
	task.spawn(familyHunt)
	-- Sarp ist weg, man hört ihn nur manchmal von unten
	task.spawn(function()
		while phase == "search" or phase == "bomb" do
			task.wait(math.random(30, 50))
			if phase == "search" or phase == "bomb" then
				sfx("sarpStep", point(47, 4, Mansion.FLOORS.K + 1), { count = 3, interval = 0.8, volume = 1.4, maxDistance = 400 })
			end
		end
	end)

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
			bombStep = "light"
			safePrompt.ActionText = "Lunte anzünden"
			safePrompt.HoldDuration = 1
			event:FireAllClients({ type = "objectives", title = "Für den Safe", items = { { text = "Lunte mit der Kerze anzünden", done = false } } })
			lineAsync("onSafe")
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
	task.spawn(function()
		line("lit")
		if mr then
			mr:SetAttribute("Look", "down")
			ctx.walkPath(mr, { { at = point(46.8, 53.5, O) }, { at = point(47.5, 57, O) } }, 9, kit.steps)
			Wagners.place(mr, ctx.hiddenSpot, ctx.facing)
		end
	end)
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
			humanoid:TakeDamage(BLAST_DAMAGE)
			event:FireClient(player, { type = "hurt", health = humanoid.Health })
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
	local E = Mansion.FLOORS.E
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
	if sarp then
		Wagners.place(sarp, point(48.5, 67, E), point(44, 69, E))
		sarpSays(Script.SARP_ALERT)
		kit.sarpWalk({ point(43.8, 69.3, E), point(43.7, 68.2, E), point(43.7, 59.3, O), point(46.8, 57, O), point(46.8, 54.6, O) }, SEARCH_SPEED)
		searchingRoom = true
		kit.sarpWalk({ point(46.6, 51.5, O) }, SEARCH_SPEED, interruptedInRoom)
		catchVisibleInRoom()
		-- die drei Verstecke in zufälliger Reihenfolge
		local order = table.clone(room.hideSpots)
		for i = #order, 2, -1 do
			local j = math.random(1, i)
			order[i], order[j] = order[j], order[i]
		end
		for _, spot in order do
			kit.sarpWalk({ spot.search }, SEARCH_SPEED, interruptedInRoom)
			catchVisibleInRoom()
			local feet = Wagners.ground(sarp)
			local target = spot.place.Position
			Wagners.place(sarp, feet, Vector3.new(target.X, feet.Y, target.Z))
			SarpStage2.look(sarp, 0, spot.kind == "lie" and 0.9 or 0.15)
			sfx("sarpBreath", target + Vector3.new(0, 2, 0), { volume = 1.4, maxDistance = 30 })
			if spot.occupant then
				event:FireClient(spot.occupant, { type = "nearScare", seconds = 3.5 })
				sarpSays(Script.SARP_WHISPERS)
			end
			local waitUntil = os.clock() + 3.5
			while os.clock() < waitUntil do
				if interruptedInRoom() then
					catchVisibleInRoom()
				end
				task.wait(0.1)
			end
			SarpStage2.look(sarp, 0, 0)
		end
		searchingRoom = false
		kit.whisper(Script.SARP_LEAVES)
		kit.sarpWalk({ point(46.8, 54.6, O), point(46.8, 57, O), point(43.7, 59.3, O), point(43.7, 68.2, E), point(48, 66, E) }, SEARCH_SPEED)
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

	-- Sarp läuft unten herum: hört, wer nicht schleicht; sieht im Dunkeln nur aus der Nähe
	local PATROL = {
		point(48, 66, E), point(51.4, 58, E), point(51.4, 50, E), point(46, 46, E), point(44, 40, E),
		point(48, 37, E), point(51, 36.5, E), point(48, 37, E), point(44, 40, E), point(46, 46, E), point(51.4, 50, E), point(51.4, 58, E),
	}
	local function notices(player)
		local root, humanoid = rootOf(player)
		local sarpRoot = sarp and sarp:FindFirstChild("HumanoidRootPart")
		if not (root and humanoid and sarpRoot) or humanoid.Health <= 0 or hidden[player] or caught[player] then
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
		if distance < (sneaking and SNEAK_SEE_DISTANCE or SEE_DISTANCE) then
			local eye = sarpRoot.Position + Vector3.new(0, 2.5, 0)
			return kit.clearLine(eye, root.Position, { sarp, player.Character })
		end
		return false
	end
	local function chase(player)
		event:FireClient(player, { type = "chased", text = "Er hat dich bemerkt – lauf!" })
		kit.whisper(Script.SARP_WHISPERS[math.random(1, #Script.SARP_WHISPERS)])
		local lostSince
		local giveUp = os.clock() + 25
		while phase == "sneak" and os.clock() < giveUp do
			local root = rootOf(player)
			if not root or not alive(player) or caught[player] or hidden[player] then
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
			if (target - feet).Magnitude <= CATCH_DISTANCE then
				catchPlayer(player, 2.5)
				break
			end
			kit.sarpWalk({ kit.nextWaypoint(feet, target) }, CHASE_SPEED, function()
				return lostSince ~= nil and os.clock() - lostSince > 0.5
			end)
		end
		event:FireClient(player, { type = "lost" })
		SarpStage2.look(sarp, 0.5, 0)
		task.wait(1)
		SarpStage2.look(sarp, -0.5, 0)
		task.wait(1)
		SarpStage2.look(sarp, 0, 0)
	end
	local function sarpPatrol()
		if not sarp then
			return
		end
		Wagners.place(sarp, PATROL[1], PATROL[2])
		local index = 1
		while phase == "sneak" do
			local target = PATROL[index % #PATROL + 1]
			local noticed
			local reached = kit.sarpWalk({ target }, PATROL_SPEED, function()
				if phase ~= "sneak" then
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
				chase(noticed)
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
		Wagners.place(sarp, kit.away, ctx.facing)
	end
	task.spawn(sarpPatrol)

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
