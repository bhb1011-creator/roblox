-- Kapitel 2 auf dem Client: Ego-Perspektive vor der Haustür der Wagners, Handy als
-- Taschenlampe, Untertitel und Antworten wie in Kapitel 1. Die Wagners schauen einen
-- die ganze Zeit an (ihre Köpfe drehen sich mit), die Kerzen flackern, Geräusche
-- kommen vom Server (Klopfen, Schritte, Tür, Kette).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Route = require(Shared:WaitForChild("LevelRoute"))
local Speech = require(script.Parent:WaitForChild("Speech"))
local Choices = require(script.Parent:WaitForChild("Choices"))
local Ambience = require(script.Parent:WaitForChild("Ambience"))

local Kapitel2 = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Ersatz, solange ein Sound noch keine ID hat: anderer Sound, tiefer oder höher
local FALLBACK_SOUNDS = {
	footstep = "rbxasset://sounds/action_footsteps_plastic.mp3",
}
local FALLBACK_KEYS = {
	knock = { "footstep", 0.55 },
	doorSlam = { "footstep", 0.3 },
	stepWood = { "footstep", 0.8 },
	stepGravel = { "footstep", 0.95 },
	stepDirt = { "footstep", 0.7 },
	forestWind = { "wind", 1 },
	heavyKnock = { "footstep", 0.35 },
	doorBurst = { "footstep", 0.22 },
	sarpStep = { "footstep", 0.42 },
	heartbeat = { "footstep", 0.3 },
	scream = { "sting", 1.25 },
	jumpscare = { "sting", 0.85 },
}

local function makeSound(key, parent, props)
	local id = Config.SOUNDS and Config.SOUNDS[key] or ""
	local fallback = FALLBACK_KEYS[key]
	if id == "" and fallback then
		id = Config.SOUNDS[fallback[1]] or ""
		props = table.clone(props or {})
		props.PlaybackSpeed = fallback[2]
	end
	if id == "" then
		id = FALLBACK_SOUNDS[key] or (fallback and FALLBACK_SOUNDS[fallback[1]])
	end
	if not id then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = id
	for property, value in props or {} do
		sound[property] = value
	end
	sound.Parent = parent
	return sound
end

local function create(className, props)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	instance.Parent = props.Parent
	return instance
end

function Kapitel2.run()
	for _, coreType in { Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health, Enum.CoreGuiType.PlayerList } do
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreType, false)
	end

	------------------------------------------------------------------ Anzeige
	local gui = create("ScreenGui", {
		Name = "Kapitel2UI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 10,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local fade = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = gui,
	})
	local function label(props)
		props.BackgroundTransparency = 1
		props.TextTransparency = 1
		props.TextStrokeTransparency = 1
		props.ZIndex = 6
		props.AutoLocalize = false
		props.Parent = gui
		return create("TextLabel", props)
	end
	local chapter = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(0.8, 0, 0, 40),
		Font = Enum.Font.SpecialElite,
		Text = "KAPITEL 2",
		TextSize = 28,
		TextColor3 = Color3.fromRGB(220, 205, 185),
	})
	local chapterTitle = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.8, 0, 0, 60),
		Font = Enum.Font.SpecialElite,
		Text = "Die Wagners",
		TextSize = 48,
		TextColor3 = Color3.fromRGB(240, 230, 215),
	})
	local loadingLabel = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.8, 0, 0, 90),
		Font = Enum.Font.SpecialElite,
		Text = "Lädt …",
		TextWrapped = true,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(170, 165, 155),
	})
	loadingLabel.TextTransparency = 0
	local hintLabel = label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.12),
		Size = UDim2.new(0.8, 0, 0, 30),
		Font = Enum.Font.SpecialElite,
		Text = "",
		TextSize = 22,
		TextColor3 = Color3.fromRGB(220, 215, 205),
	})
	local function showText(target, visible, duration)
		TweenService:Create(target, TweenInfo.new(duration), {
			TextTransparency = visible and 0 or 1,
			TextStrokeTransparency = visible and 0.6 or 1,
		}):Play()
	end
	local hintToken = 0
	local function hint(text, seconds)
		hintToken += 1
		local mine = hintToken
		hintLabel.Text = text
		showText(hintLabel, true, 0.6)
		task.delay(seconds, function()
			if hintToken == mine then
				showText(hintLabel, false, 0.8)
			end
		end)
	end
	local function setFade(transparency, duration)
		TweenService:Create(fade, TweenInfo.new(duration), { BackgroundTransparency = transparency }):Play()
	end

	Speech.init(gui)
	Choices.init(gui)

	------------------------------------------------------------------ Handy als Taschenlampe
	local flashlight = create("Part", {
		Name = "PhoneLight",
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		CFrame = camera.CFrame,
		Parent = workspace,
	})
	create("SpotLight", {
		Face = Enum.NormalId.Front,
		Range = 40,
		Angle = 55,
		Brightness = 2.6,
		Color = Color3.fromRGB(225, 235, 255),
		Shadows = true,
		Parent = flashlight,
	})
	create("PointLight", { Range = 6, Brightness = 0.3, Color = Color3.fromRGB(225, 235, 255), Parent = flashlight })
	-- Die anderen Spieler leuchten auch mit dem Handy (Licht am Kopf)
	task.spawn(function()
		while gui.Parent do
			for _, other in Players:GetPlayers() do
				local head = other ~= player and other.Character and other.Character:FindFirstChild("Head")
				if head and not head:FindFirstChild("PhoneLight") then
					create("SpotLight", { Name = "PhoneLight", Face = Enum.NormalId.Front, Range = 34, Angle = 55, Brightness = 2, Color = Color3.fromRGB(225, 235, 255), Shadows = true, Parent = head })
				end
				local phone = head and head:FindFirstChild("PhoneLight")
				if phone then
					phone.Enabled = not other:GetAttribute("LightOff")
				end
			end
			task.wait(1)
		end
	end)

	------------------------------------------------------------------ Eigene Kerze
	-- Der Server hängt die Kerze an die Hand (für die anderen). Man selbst sieht sie
	-- unten links im Bild, mit eigenem Licht; die Kerze an der Hand bleibt unsichtbar.
	local candleDim, candleDimUntil = 1, 0 -- 1 = normal, kleiner = Kerzen fast aus
	local dimTarget = 1 -- so hell werden die Kerzen nach dem Flackern wieder ("dim")
	local ownCandleOff = false -- im Versteck ist die eigene Kerze aus
	local lightOff = false -- Taste F: Kerze und Handylicht aus (dann sieht Sarp einen nicht)
	local held = create("Model", { Name = "HeldCandle" })
	local heldParts = {}
	local function heldPiece(name, shape, size, color, material, offset)
		local part = create("Part", {
			Name = name,
			Shape = shape,
			Size = size,
			Color = color,
			Material = material,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Parent = held,
		})
		table.insert(heldParts, { part = part, offset = offset })
		return part
	end
	local upright = CFrame.Angles(0, 0, math.rad(90))
	heldPiece("CandleHolder", Enum.PartType.Cylinder, Vector3.new(0.08, 0.42, 0.42), Color3.fromRGB(120, 96, 52), Enum.Material.Metal, upright)
	heldPiece("Candle", Enum.PartType.Cylinder, Vector3.new(0.55, 0.15, 0.15), Color3.fromRGB(225, 215, 190), Enum.Material.SmoothPlastic, CFrame.new(0, 0.31, 0) * upright)
	local heldFlame = heldPiece("CandleFlame", Enum.PartType.Ball, Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 170, 70), Enum.Material.Neon, CFrame.new(0, 0.65, 0))
	local heldLight = create("PointLight", {
		Name = "OwnCandleLight",
		Range = 26,
		Brightness = 2.4,
		Color = Color3.fromRGB(255, 180, 110),
		Shadows = true,
		Parent = heldFlame,
	})
	local heldSeed = math.random() * 100
	local heldSway = CFrame.new()
	-- Axt (wenn man sie hat): unten rechts im Bild, die an der Hand bleibt unsichtbar
	local heldAxe = create("Model", { Name = "HeldAxe" })
	local axeParts = {}
	for _, info in {
		{ "AxeHandle", Vector3.new(0.1, 1.8, 0.1), Color3.fromRGB(120, 86, 52), Enum.Material.Wood, CFrame.new(0, 0, 0) },
		{ "AxeHead", Vector3.new(0.08, 0.4, 0.62), Color3.fromRGB(110, 112, 116), Enum.Material.Metal, CFrame.new(0, 0.8, 0.2) },
	} do
		local part = create("Part", {
			Name = info[1],
			Size = info[2],
			Color = info[3],
			Material = info[4],
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Parent = heldAxe,
		})
		table.insert(axeParts, { part = part, offset = info[5] })
	end
	local function updateHeldAxe()
		local character = player.Character
		local serverAxe = character and character:FindFirstChild("PlayerAxe")
		if not serverAxe then
			heldAxe.Parent = nil
			return
		end
		for _, part in serverAxe:GetDescendants() do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 1
			end
		end
		heldAxe.Parent = workspace
		local base = camera.CFrame * CFrame.new(0.75, -0.85, -1.5) * CFrame.Angles(math.rad(-15), math.rad(-20), math.rad(-25))
		for _, entry in axeParts do
			entry.part.CFrame = base * entry.offset
		end
	end

	local function updateHeldCandle(deltaTime, now)
		local character = player.Character
		local serverCandle = character and character:FindFirstChild("PlayerCandle")
		if not serverCandle then
			held.Parent = nil
			return
		end
		-- die Kerze an der eigenen Hand ausblenden (Licht kommt von der Kerze im Bild)
		for _, part in serverCandle:GetDescendants() do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 1
			elseif part:IsA("PointLight") then
				part.Enabled = false
			end
		end
		held.Parent = workspace -- nur auf diesem Computer (der Server kennt sie nicht)
		local sway = CFrame.new(math.noise(now * 0.7, 1) * 0.03, math.noise(now * 0.9, 2) * 0.03, 0)
		heldSway = heldSway:Lerp(sway, math.min(deltaTime * 4, 1))
		local base = camera.CFrame * CFrame.new(-0.62, -0.72, -1.45) * heldSway
		-- immer aufrecht, auch wenn man nach oben oder unten schaut
		base = CFrame.new(base.Position) * CFrame.Angles(0, select(2, camera.CFrame:ToOrientation()), 0)
		for _, entry in heldParts do
			entry.part.CFrame = base * entry.offset
		end
		local flicker = 0.85 + math.noise(now * 6, heldSeed) * 0.22 + math.noise(now * 17, heldSeed + 3) * 0.07
		local off = ownCandleOff or lightOff
		heldLight.Brightness = off and 0 or 2.4 * flicker * math.max(candleDim, 0.35)
		heldFlame.Transparency = off and 1 or 1 - math.clamp(candleDim * 1.2, 0, 1)
	end

	------------------------------------------------------------------ Kerzen
	local candles = {} -- Licht -> { base, flame }
	-- nur im Haus und bei den Wagners suchen (nicht im ganzen Wald)
	local house
	local function scanCandles()
		house = house or workspace:FindFirstChild("WagnerHouse", true)
		local containers = { house, workspace:FindFirstChild("Wagners") }
		for _, other in Players:GetPlayers() do
			local candle = other ~= player and other.Character and other.Character:FindFirstChild("PlayerCandle")
			if candle then
				table.insert(containers, candle)
			end
		end
		for _, container in containers do
			for _, light in container and container:GetDescendants() or {} do
				if light:IsA("PointLight") and light.Name == "CandleLight" and not candles[light] then
					candles[light] = { base = light.Brightness, seed = math.random() * 100 }
				end
			end
		end
	end

	------------------------------------------------------------------ Die Wagners schauen einen an
	local necks = {} -- Modell -> { joint, base, yaw, pitch }
	local function updateNecks(deltaTime)
		local family = workspace:FindFirstChild("Wagners")
		if not family then
			return
		end
		for _, model in family:GetChildren() do
			local head = model:FindFirstChild("Head")
			local torso = model:FindFirstChild("UpperTorso")
			local joint = head and head:FindFirstChild("Neck")
			if joint and torso then
				local info = necks[model]
				if not info then
					info = { joint = joint, base = joint.C0, yaw = 0, pitch = 0 }
					necks[model] = info
				end
				local look = model:GetAttribute("Look")
				local yaw, pitch = 0, 0
				local target
				if look == "player" then
					target = camera.CFrame.Position
				elseif look == "stairs" then
					target = model:GetAttribute("LookAt")
				end
				if target then
					local relative = torso.CFrame:Inverse() * target - Vector3.new(0, torso.Size.Y / 2 + head.Size.Y / 2, 0)
					yaw = math.clamp(math.atan2(-relative.X, -relative.Z), math.rad(-75), math.rad(75))
					pitch = math.clamp(math.atan2(relative.Y, Vector2.new(relative.X, relative.Z).Magnitude), math.rad(-40), math.rad(40))
				elseif look == "down" then
					pitch = math.rad(-28)
				end
				local blend = math.min(deltaTime * 4, 1)
				info.yaw += (yaw - info.yaw) * blend
				info.pitch += (pitch - info.pitch) * blend
				pcall(function()
					info.joint.C0 = info.base * CFrame.Angles(info.pitch, info.yaw, 0)
				end)
				Speech.setEmitter(model.Name == "MrsWagner" and "mrsWagner" or "mrWagner", head)
			end
		end
	end

	------------------------------------------------------------------ Geräusche vom Server
	local function playSfx(message)
		local count = message.count or 1
		task.spawn(function()
			for _ = 1, count do
				local parent = SoundService
				local holder
				if message.position then
					holder = create("Part", {
						Name = "SceneSound",
						Anchored = true,
						CanCollide = false,
						CanQuery = false,
						CanTouch = false,
						Transparency = 1,
						Size = Vector3.new(0.5, 0.5, 0.5),
						CFrame = CFrame.new(message.position),
						Parent = workspace,
					})
					parent = holder
				end
				local sound = makeSound(message.key, parent, {
					Volume = message.volume or 1,
					RollOffMinDistance = 8,
					RollOffMaxDistance = message.maxDistance or 90,
				})
				if sound then
					if message.speed then
						sound.PlaybackSpeed *= message.speed
					end
					sound.PlaybackSpeed *= 0.95 + math.random() * 0.1
					sound:Play()
				end
				task.delay(8, function()
					if holder then
						holder:Destroy()
					elseif sound then
						sound:Destroy()
					end
				end)
				task.wait(message.interval or 0.4)
			end
		end)
	end

	------------------------------------------------------------------ Jumpscare
	local shakeUntil = 0
	local nextBeat = 0
	local scareFlash = create("Frame", {
		Name = "ScareFlash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(110, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 9,
		Parent = gui,
	})
	-- Sarps Gesicht schießt auf die Kamera zu, roter Blitz, dann schwarz
	local function jumpscare()
		local sound = makeSound("jumpscare", SoundService, { Volume = 2.5 })
		if sound then
			sound:Play()
			task.delay(4, function()
				sound:Destroy()
			end)
		end
		local folder = workspace:FindFirstChild("SarpNight")
		local sarpModel = folder and folder:FindFirstChild("Sarp")
		local head = sarpModel and sarpModel:FindFirstChild("Head")
		if head then
			camera.CameraType = Enum.CameraType.Scriptable
			local start = os.clock()
			local connection
			connection = RunService.RenderStepped:Connect(function()
				local t = os.clock() - start
				if t > 1.4 or not head.Parent then
					connection:Disconnect()
					return
				end
				local look = head.CFrame.LookVector
				local distance = 3 - math.min(t / 0.3, 1) * 2.1
				local shake = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * 0.3
				camera.CFrame = CFrame.lookAt(head.Position + look * distance + shake, head.Position)
			end)
		end
		scareFlash.BackgroundTransparency = 0.3
		TweenService:Create(scareFlash, TweenInfo.new(0.9), { BackgroundTransparency = 1 }):Play()
		task.delay(1.25, function()
			setFade(0, 0.12)
		end)
	end

	------------------------------------------------------------------ Nachrichten vom Server
	-- Der Server legt diesen Ordner an, sobald er mit dem Bauen beginnt
	local remotes = ReplicatedStorage:WaitForChild("Kapitel2", 60)
	if not remotes then
		loadingLabel.Text = "Der Server startet nicht – bitte im Output nach roten Fehlern schauen."
		remotes = ReplicatedStorage:WaitForChild("Kapitel2")
	end
	-- Was der Server gerade macht (oder welcher Fehler passiert ist)
	local function showStatus()
		local status = remotes:GetAttribute("Status")
		if status and loadingLabel.Visible then
			loadingLabel.Text = status
		end
	end
	remotes:GetAttributeChangedSignal("Status"):Connect(showStatus)
	showStatus()
	local event = remotes:WaitForChild("SceneEvent")
	local choiceEvent = remotes:WaitForChild("SceneChoice")

	-- Licht an/aus: Taste F (am Handy: Knopf unten rechts)
	local lightEvent = remotes:WaitForChild("Light", 10)
	local function toggleLight()
		lightOff = not lightOff
		if lightEvent then
			lightEvent:FireServer(not lightOff)
		end
		hint(lightOff and "Licht aus." or "Licht an.", 1.5)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.F then
			toggleLight()
		end
	end)
	if UserInputService.TouchEnabled then
		local button = create("TextButton", {
			Name = "LightButton",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -24, 1, -160),
			Size = UDim2.fromOffset(70, 70),
			BackgroundColor3 = Color3.fromRGB(30, 26, 22),
			BackgroundTransparency = 0.3,
			Text = "Licht",
			TextColor3 = Color3.fromRGB(240, 220, 180),
			Font = Enum.Font.SpecialElite,
			TextSize = 18,
			AutoLocalize = false,
			ZIndex = 7,
			Parent = gui,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = button })
		button.Activated:Connect(toggleLight)
	end
	local houseInside = false
	local finished = false

	-- Erst aufblenden, wenn die eigene Spielfigur vor der Haustür steht
	local function begin()
		local character = player.Character or player.CharacterAdded:Wait()
		character:WaitForChild("HumanoidRootPart")
		task.wait(0.5)
		loadingLabel.Visible = false
		setFade(1, 2.5)
		task.delay(1.5, function()
			showText(chapter, true, 1.5)
			showText(chapterTitle, true, 2)
		end)
		task.delay(6, function()
			showText(chapter, false, 1.5)
			showText(chapterTitle, false, 1.5)
		end)
		task.delay(7.5, function()
			if not finished and not remotes:GetAttribute("TestStart") then
				hint("Klopf an die Tür.", 6)
			end
		end)
	end
	local begun = false
	local function beginOnce()
		if not begun then
			begun = true
			task.spawn(begin)
		end
	end

	event.OnClientEvent:Connect(function(message)
		local kind = message.type
		if kind == "start" then
			beginOnce()
		elseif kind == "line" then
			Speech.say(message.speaker, message.name, message.text, message.duration, message.voice)
		elseif kind == "choice" then
			local chooser = message.chooser and Players:GetPlayerByUserId(message.chooser)
			Choices.show(message.options, message.chooser == player.UserId, chooser and chooser.DisplayName or "Wer geklopft hat", message.timeout, function(index)
				choiceEvent:FireServer(index)
			end)
		elseif kind == "chosen" then
			Choices.chosen(message.index)
		elseif kind == "sfx" then
			playSfx(message)
		elseif kind == "candleOut" then
			scanCandles()
			candleDim, candleDimUntil = 0.03, os.clock() + (message.duration or 0.6)
		elseif kind == "hint" then
			hint(message.text, message.seconds or 4)
		elseif kind == "blink" then
			setFade(0, 0.4)
			task.delay(0.9, function()
				setFade(1, 0.8)
			end)
		elseif kind == "inside" then
			houseInside = true
		elseif kind == "explore" then
			hint("Sieh dich im Haus um. Euer Zimmer ist oben – zweite Tür links.", 7)
		elseif kind == "sleep" then
			-- alle liegen im Bett: einschlafen, dann mitten in der Nacht
			setFade(0, 4)
			task.delay(4.5, function()
				chapter.Text = "Mitten in der Nacht …"
				chapterTitle.Text = "03:17"
				showText(chapter, true, 1.5)
				showText(chapterTitle, true, 2)
			end)
			task.delay(9.5, function()
				showText(chapter, false, 1.5)
				showText(chapterTitle, false, 1.5)
			end)
		elseif kind == "wake" then
			finished = false
			dimTarget = 0.8
			showText(chapter, false, 0.5)
			showText(chapterTitle, false, 0.5)
			setFade(1, 2.5)
		elseif kind == "dim" then
			dimTarget = message.level or 1
			candleDimUntil = 0
		elseif kind == "hidden" then
			ownCandleOff = true
			hint("Versteckt. Sei ganz still … (E: rauskommen)", 5)
		elseif kind == "unhidden" then
			ownCandleOff = false
		elseif kind == "nearScare" then
			-- er steht direkt vor deinem Versteck
			local seconds = message.seconds or 3
			shakeUntil = os.clock() + seconds
			task.spawn(function()
				local stop = os.clock() + seconds
				while os.clock() < stop do
					local beat = makeSound("heartbeat", SoundService, { Volume = 1.6 })
					if beat then
						beat:Play()
						task.delay(2, function()
							beat:Destroy()
						end)
					end
					task.wait(0.45)
				end
			end)
		elseif kind == "jumpscare" then
			jumpscare()
		elseif kind == "hurt" then
			-- getroffen: roter Blitz, Bild wackelt
			scareFlash.BackgroundTransparency = 0.35
			TweenService:Create(scareFlash, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
			shakeUntil = os.clock() + 0.6
		elseif kind == "chased" then
			hint("Er hat dich gesehen – lauf! (F: Licht aus)", 4)
		elseif kind == "lost" then
			hint("Er hat dich verloren …", 3)
		elseif kind == "caught" then
			setFade(0, 0.1)
			chapter.Text = "Er hat dich gefunden …"
			chapterTitle.Text = ""
			showText(chapter, true, 0.8)
		elseif kind == "retry" then
			camera.CameraType = Enum.CameraType.Custom
			ownCandleOff = false
			showText(chapter, false, 0.5)
			showText(chapterTitle, false, 0.5)
			setFade(1, 1.2)
		elseif kind == "alone" and message.instant then
			-- sofort schwarz (z. B. beim Betreten des Raums hinter Tür 1)
			finished = true
			setFade(0, 0.25)
			task.delay(2, function()
				chapter.Text = message.title or ""
				chapterTitle.Text = message.subtitle or ""
				showText(chapter, true, 1.5)
				showText(chapterTitle, true, 2)
			end)
		elseif kind == "alone" then
			finished = true
			dimTarget = 0.6
			task.delay(1, function()
				chapter.Text = message.title or "Die Wagners sind weg."
				chapterTitle.Text = message.subtitle or "Du bist allein im Haus. Mit ihm."
				showText(chapter, true, 1.5)
				showText(chapterTitle, true, 2)
			end)
			task.delay(8, function()
				setFade(0, 3)
				showText(chapter, false, 1)
				showText(chapterTitle, false, 1)
			end)
			task.delay(11.5, function()
				chapter.Text = "ENDE VON KAPITEL 2 (TEIL 1)"
				chapterTitle.Text = "Fortsetzung folgt …"
				showText(chapter, true, 1.5)
				showText(chapterTitle, true, 2)
			end)
		elseif kind == "finish" then
			finished = true
			setFade(0, 3)
			task.delay(3.5, function()
				chapter.Text = "ENDE DES ANFANGS VON KAPITEL 2"
				chapterTitle.Text = "Fortsetzung folgt …"
				showText(chapter, true, 1.5)
				showText(chapterTitle, true, 2)
			end)
		end
	end)
	-- Wer später dazukommt, sieht sofort etwas (und weiß, dass man schon im Haus ist)
	if remotes:GetAttribute("Started") then
		beginOnce()
	end
	houseInside = houseInside or remotes:GetAttribute("Inside") == true
	remotes:GetAttributeChangedSignal("Inside"):Connect(function()
		houseInside = remotes:GetAttribute("Inside") == true
	end)
	if remotes:GetAttribute("Explore") then
		task.delay(8, function()
			hint("Sieh dich im Haus um.", 6)
		end)
	end
	-- falls die Startnachricht verloren geht: sobald die Spielfigur da ist
	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait()
		character:WaitForChild("HumanoidRootPart")
		task.wait(3)
		beginOnce()
	end)

	------------------------------------------------------------------ Jedes Bild
	Ambience.init(makeSound)
	local forest = makeSound("forest", SoundService, { Looped = true, Volume = 0 })
	if forest then
		forest:Play()
	end
	local origin = Route.houseCFrame()
	local lastScan = 0

	-- Bei der Antwortauswahl braucht man einen freien Mauszeiger (nach der Kamera setzen)
	RunService:BindToRenderStep("Kapitel2Shake", Enum.RenderPriority.Camera.Value + 2, function()
		-- Kamera zittert, wenn Sarp direkt vor dem Versteck steht
		if os.clock() < shakeUntil and camera.CameraType ~= Enum.CameraType.Scriptable then
			local amount = 0.006
			camera.CFrame *= CFrame.Angles((math.random() - 0.5) * amount, (math.random() - 0.5) * amount, 0)
		end
	end)
	RunService:BindToRenderStep("Kapitel2Mouse", Enum.RenderPriority.Camera.Value + 1, function()
		if Choices.isChoosing() then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		elseif UserInputService.MouseIconEnabled then
			UserInputService.MouseIconEnabled = false
		end
	end)

	RunService.RenderStepped:Connect(function(deltaTime)
		local now = os.clock()
		-- Handylicht folgt dem Blick
		local target = camera.CFrame * CFrame.new(0.35, -0.45, -0.3)
		flashlight.CFrame = flashlight.CFrame:Lerp(target, math.min(deltaTime * 10, 1))
		for _, light in flashlight:GetChildren() do
			light.Enabled = not lightOff
		end

		-- Kerzen flackern (und gehen bei "candleOut" fast aus)
		if now - lastScan > 2 then
			lastScan = now
			scanCandles()
		end
		if now > candleDimUntil then
			candleDim += (dimTarget - candleDim) * math.min(deltaTime * 3, 1)
		end
		for light, info in candles do
			if light.Parent then
				local flicker = 0.82 + math.noise(now * 6, info.seed) * 0.25 + math.noise(now * 17, info.seed + 3) * 0.08
				light.Brightness = info.base * flicker * candleDim
				local flame = light.Parent
				if flame.Name == "CandleFlame" then
					flame.Transparency = 1 - math.clamp(candleDim * 1.2, 0, 1)
				end
			else
				candles[light] = nil
			end
		end

		updateHeldCandle(deltaTime, now)
		updateHeldAxe()

		-- Herzschlag: je näher Sarp ist, desto schneller und lauter
		local sarpFolder = workspace:FindFirstChild("SarpNight")
		local sarpHead = sarpFolder and sarpFolder:FindFirstChild("Sarp") and sarpFolder.Sarp:FindFirstChild("Head")
		if sarpHead and not finished then
			local distance = (sarpHead.Position - camera.CFrame.Position).Magnitude
			if distance < 34 and now >= nextBeat then
				local closeness = 1 - math.clamp((distance - 5) / 29, 0, 1)
				nextBeat = now + 1.1 - closeness * 0.75
				local beat = makeSound("heartbeat", SoundService, { Volume = 0.4 + closeness * 1.6 })
				if beat then
					beat:Play()
					task.delay(2, function()
						beat:Destroy()
					end)
				end
			end
		end
		updateNecks(deltaTime)

		-- Im Haus ist es still: kein Wind, keine Tiere, nur das Haus knarrt
		local relative = origin:Inverse() * camera.CFrame.Position
		local inHouse = houseInside or (math.abs(relative.X) < Route.HOUSE_SIZE.X / 2 and math.abs(relative.Z) < Route.HOUSE_SIZE.Z / 2)
		Ambience.update(deltaTime, {
			camera = camera,
			walking = true,
			carStopped = false,
			quiet = inHouse,
			finished = finished,
		})
		if forest then
			local volume = finished and 0 or (inHouse and 0.05 or 0.5) * Ambience.forestFactor
			forest.Volume += (volume - forest.Volume) * math.min(deltaTime * 1.5, 1)
		end
	end)
end

return Kapitel2
