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
		Size = UDim2.new(0.8, 0, 0, 30),
		Font = Enum.Font.SpecialElite,
		Text = "Lädt …",
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
			end
			task.wait(1)
		end
	end)

	------------------------------------------------------------------ Kerzen
	local candles = {} -- Licht -> { base, flame }
	local candleDim, candleDimUntil = 1, 0
	-- nur im Haus und bei den Wagners suchen (nicht im ganzen Wald)
	local house
	local function scanCandles()
		house = house or workspace:FindFirstChild("WagnerHouse", true)
		for _, container in { house, workspace:FindFirstChild("Wagners") } do
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

	------------------------------------------------------------------ Nachrichten vom Server
	local remotes = ReplicatedStorage:WaitForChild("Kapitel2")
	local event = remotes:WaitForChild("SceneEvent")
	local choiceEvent = remotes:WaitForChild("SceneChoice")
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
			if not finished then
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
			hint("Sieh dich im Haus um.", 6)
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
	-- Wer später dazukommt, sieht sofort etwas
	if remotes:GetAttribute("Started") then
		beginOnce()
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

		-- Kerzen flackern (und gehen bei "candleOut" fast aus)
		if now - lastScan > 2 then
			lastScan = now
			scanCandles()
		end
		if now > candleDimUntil then
			candleDim += (1 - candleDim) * math.min(deltaTime * 3, 1)
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
