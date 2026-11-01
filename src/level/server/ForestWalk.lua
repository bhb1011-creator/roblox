-- Ende "follow" auf dem Server: Die Spieler laufen selbst über den Waldweg. Sarp geht
-- gleichmäßig voraus und wartet nicht. Wer ihm nicht folgt, hört zuerst das Biest im
-- Wald, dann näher, und wenn man immer noch nicht kommt, jagt es einen. Wer zurück zu
-- Sarp rennt, ist sicher; wen es erwischt, der stirbt und taucht hinter Sarp wieder auf.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Route = require(ReplicatedStorage.Shared.LevelRoute)

local ForestWalk = {}

local LAG_DISTANCE = 26 -- so weit hinter Sarp gilt man als "nicht gefolgt"
local SAFE_DISTANCE = 16 -- so nah an Sarp ist man wieder sicher
local OFF_PATH = 22 -- so weit neben dem Weg gilt man auch als "nicht gefolgt"
local WARN_FIRST, WARN_SECOND, CHASE = 4, 9, 14 -- Sekunden Zurückbleiben bis zur nächsten Stufe
local BEAST_SPEED = 12.5 -- schneller als Gehen (9), langsamer als Rennen (15)
local BEAST_SPAWN_DISTANCE = 45
local CATCH_DISTANCE = 4.5
local RESPAWN_DELAY = 4.5

local function rootOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return root, humanoid
	end
	return nil
end

local function onGround(position)
	return Vector3.new(position.X, Route.groundY(position.X, position.Z), position.Z)
end

-- Spielfigur laden und an `cframe` stellen
local function spawnWalker(player, cframe)
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player:LoadCharacter()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Route.WALK_SPEED
		humanoid.UseJumpPower = false
		humanoid.JumpHeight = 2
		character:PivotTo(cframe + Vector3.new(0, humanoid.HipHeight + 1.5, 0))
	end
	player.ReplicationFocus = nil
end

-- Läuft, bis jemand an der Veranda ankommt. onProgress(anteil) meldet, wie weit der
-- vorderste Spieler ist (für die Erzählung).
function ForestWalk.run(cutscene, event, onProgress)
	for index, player in Players:GetPlayers() do
		task.spawn(spawnWalker, player, Route.walkerSpawn(index))
	end

	local walkLine = Route.walkLine()
	local length = walkLine.length
	local sarpStart = workspace:GetServerTimeNow() + Route.SARP_START_DELAY
	cutscene:SetAttribute("SarpStart", sarpStart)

	-- Unsichtbarer Punkt, dem die Clients ihr Biest folgen lassen
	local anchor = Instance.new("Part")
	anchor.Name = "BeastAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = CFrame.new(0, -200, 0)
	anchor:SetAttribute("Active", false)
	anchor.Parent = workspace

	local beast = { active = false, target = nil, position = nil, leavingUntil = nil }
	local walkers = {} -- pro Spieler: lag (Sekunden), stage (0–3), dead

	local function sarpProgress(now)
		return math.clamp(6 + math.max(0, now - sarpStart) * Route.SARP_WALK_SPEED, 0, length)
	end

	local function hideBeast()
		beast.active, beast.target, beast.leavingUntil = false, nil, nil
		anchor:SetAttribute("Active", false)
		anchor.CFrame = CFrame.new(0, -200, 0)
	end

	-- Ein Punkt im Wald hinter dem Spieler (weg von Sarp)
	local function behind(root, distance, now)
		local sarpPosition = walkLine.at(sarpProgress(now))
		local away = Vector3.new(root.Position.X - sarpPosition.X, 0, root.Position.Z - sarpPosition.Z)
		if away.Magnitude < 1 then
			away = -root.CFrame.LookVector
		end
		away = Vector3.new(away.X, 0, away.Z).Unit
		local sideways = away:Cross(Vector3.yAxis) * (math.random() - 0.5) * distance * 0.8
		local point = root.Position + away * distance + sideways
		if Route.distanceToHouse(point.X, point.Z) < 4 then
			point = root.Position - away * distance
		end
		return onGround(point)
	end

	local function catch(player, info)
		info.dead = true
		event:FireClient(player, { type = "caught" })
		task.delay(0.9, function()
			local _, humanoid = rootOf(player)
			if humanoid then
				humanoid.Health = 0
			end
		end)
		task.delay(RESPAWN_DELAY, function()
			-- hinter Sarp wieder auftauchen (nach der Ankunft vor der Veranda)
			local s = cutscene:GetAttribute("ArrivedAt") and length - 8 or math.max(0, sarpProgress(workspace:GetServerTimeNow()) - 12)
			spawnWalker(player, walkLine.cframeAt(s))
			info.lag, info.stage, info.dead = 0, 0, false
			event:FireClient(player, { type = "respawned" })
		end)
	end

	while true do
		local deltaTime = RunService.Heartbeat:Wait()
		local now = workspace:GetServerTimeNow()
		local sarpS = sarpProgress(now)
		local furthest = 0

		for _, player in Players:GetPlayers() do
			walkers[player] = walkers[player] or { lag = 0, stage = 0, dead = false }
			local info = walkers[player]
			local root = rootOf(player)
			if root and not info.dead then
				local s, offPath = Route.walkProgress(root.Position)
				if offPath < 40 then
					furthest = math.max(furthest, s)
				end
				local gap = sarpS - s
				if gap > LAG_DISTANCE or offPath > OFF_PATH then
					info.lag += deltaTime
				elseif gap < SAFE_DISTANCE then
					info.lag, info.stage = 0, 0
				end
				-- Stufen: zweimal Knurren als Warnung, dann kommt es
				if info.lag >= WARN_FIRST and info.stage < 1 then
					info.stage = 1
					event:FireClient(player, { type = "beastWarn", position = behind(root, 70, now), level = 1 })
				elseif info.lag >= WARN_SECOND and info.stage < 2 then
					info.stage = 2
					event:FireClient(player, { type = "beastWarn", position = behind(root, 40, now), level = 2 })
				elseif info.lag >= CHASE and info.stage < 3 and not beast.active then
					info.stage = 3
					beast.active, beast.target, beast.leavingUntil = true, player, nil
					beast.position = behind(root, BEAST_SPAWN_DISTANCE, now)
					anchor:SetAttribute("Active", true)
					event:FireAllClients({ type = "chase", target = player.UserId })
				end
			end
		end
		onProgress(furthest / length)

		-- Das Biest bewegen
		if beast.active then
			local target = beast.target
			local info = target and walkers[target]
			local root = target and target.Parent and rootOf(target)
			if beast.leavingUntil then
				-- es zieht sich in den Wald zurück
				if os.clock() > beast.leavingUntil then
					hideBeast()
				elseif root then
					local away = beast.position - root.Position
					away = Vector3.new(away.X, 0, away.Z)
					if away.Magnitude > 0.1 then
						beast.position = onGround(beast.position + away.Unit * BEAST_SPEED * deltaTime)
					end
				end
			elseif not root or not info or info.dead then
				hideBeast()
			elseif info.stage == 0 then
				-- der Spieler hat Sarp eingeholt: es lässt ab
				beast.leavingUntil = os.clock() + 2.5
				event:FireClient(target, { type = "escaped" })
			else
				local toward = Vector3.new(root.Position.X - beast.position.X, 0, root.Position.Z - beast.position.Z)
				if toward.Magnitude <= CATCH_DISTANCE then
					catch(target, info)
				else
					beast.position = onGround(beast.position + toward.Unit * math.min(BEAST_SPEED * deltaTime, toward.Magnitude))
				end
			end
			if beast.active and root then
				local look = Vector3.new(root.Position.X, beast.position.Y, root.Position.Z)
				if beast.leavingUntil then
					look = beast.position + (beast.position - look)
				end
				if (look - beast.position).Magnitude > 0.1 then
					anchor.CFrame = CFrame.lookAt(beast.position, look)
				end
			end
		end

		-- Jemand ist an der Veranda angekommen
		if furthest >= length - Route.ARRIVE_DISTANCE then
			break
		end
	end

	hideBeast()
	return anchor
end

return ForestWalk
