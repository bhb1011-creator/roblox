-- Zwischensequenz 1: Man sitzt im Auto (Fahrer oder Beifahrer) und schaut sich in der
-- Ego-Perspektive um. Während der Fahrt erzählt eine Stimme, wo man herkommt. Das Auto
-- hält in der Parkbucht, Sarp kommt aus dem Wald ans Fenster und redet mit einem.
-- Der Fahrer wählt die Antworten. Danach eines von zwei Enden:
--   "drive":  weiterfahren, um die Kurve, die Einfahrt hoch – Sarp steht schon da.
--   "follow": zu Fuß mit Handylicht über den Waldweg bis zum Haus, dort verschwindet Sarp.
-- Dazu laufen Musik im Autoradio, Motor, Fahrgeräusche, Blinker, Bremsen, Schotter,
-- Waldgeräusche, Rauschen im Radio und Schreck-Akzente.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Dialogue = require(Shared:WaitForChild("Dialogue"))
local Route = require(Shared:WaitForChild("LevelRoute"))
local Speech = require(script.Parent:WaitForChild("Speech"))
local Choices = require(script.Parent:WaitForChild("Choices"))
local player = Players.LocalPlayer
local cutscene = ReplicatedStorage:WaitForChild("Cutscene")
local puppets = cutscene:WaitForChild("Puppets")
local dialogueEvent = cutscene:WaitForChild("DialogueEvent")
local dialogueChoice = cutscene:WaitForChild("DialogueChoice")

local SIT_ANIMATION = "rbxassetid://2506281703"
local WALK_ANIMATION = "rbxassetid://507777826"
local IDLE_ANIMATION = "rbxassetid://507766388"
local LOOK_SIDE = math.rad(110)
local LOOK_UP, LOOK_DOWN = math.rad(40), math.rad(55)
local SENSITIVITY = 0.0035
local WALK_LOOK_SIDE = math.rad(160)
local SIDE_BY_SIDE = { Driver = -1.2, Passenger = 1.2 } -- zu zweit läuft man nebeneinander

for _, coreType in { Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health, Enum.CoreGuiType.PlayerList } do
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreType, false)
end

------------------------------------------------------------------ Anzeige
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

local gui = create("ScreenGui", {
	Name = "CutsceneUI",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 10,
	Parent = player:WaitForChild("PlayerGui"),
})
-- Kinobalken oben und unten
for _, info in { { 0, 0 }, { 1, 1 } } do
	create("Frame", {
		AnchorPoint = Vector2.new(0, info[2]),
		Position = UDim2.fromScale(0, info[1]),
		Size = UDim2.fromScale(1, 0.09),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = gui,
	})
end
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
	props.Parent = gui
	return create("TextLabel", props)
end
local chapter = label({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.new(0.8, 0, 0, 40),
	Font = Enum.Font.SpecialElite,
	Text = "KAPITEL 1",
	TextSize = 28,
	TextColor3 = Color3.fromRGB(220, 205, 185),
})
local chapterTitle = label({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0.8, 0, 0, 60),
	Font = Enum.Font.SpecialElite,
	Text = "Die Fahrt",
	TextSize = 48,
	TextColor3 = Color3.fromRGB(240, 230, 215),
})
Speech.init(gui)
Choices.init(gui)

local function showText(target, visible, duration)
	TweenService:Create(target, TweenInfo.new(duration), {
		TextTransparency = visible and 0 or 1,
		TextStrokeTransparency = visible and 0.6 or 1,
	}):Play()
end

------------------------------------------------------------------ Start abwarten
local startTime = cutscene:GetAttribute("StartTime")
while not startTime do
	cutscene:GetAttributeChangedSignal("StartTime"):Wait()
	startTime = cutscene:GetAttribute("StartTime")
end
local seatName = player:GetAttribute("CutsceneSeat")
while not seatName do
	player:GetAttributeChangedSignal("CutsceneSeat"):Wait()
	seatName = player:GetAttribute("CutsceneSeat")
end
local duo = cutscene:GetAttribute("Duo") == true

------------------------------------------------------------------ Eigenes Auto
local car = cutscene:WaitForChild("Car"):Clone()
local root = car.PrimaryPart
root.Anchored = true
-- Rechte Blinker (in der Vorlage liegt das Auto im Ursprung, rechts ist +X)
local rightIndicators = {}
for _, part in car:GetDescendants() do
	if part:IsA("BasePart") and part.Name == "Indicator" and part.Position.X > 0 then
		table.insert(rightIndicators, { part = part, color = part.Color })
	end
end
local blinkerArrow = car:FindFirstChild("BlinkerArrow", true)
local radioText = car:FindFirstChild("RadioText", true)
car.Parent = workspace
root.CFrame = Route.carCFrame(Route.START_S)

local steering
local wheels = {}
for _, descendant in car:GetDescendants() do
	if descendant:IsA("Weld") then
		if descendant.Name == "SteeringWeld" then
			steering = { weld = descendant, base = descendant.C0 }
		elseif descendant.Name == "WheelWeld" then
			table.insert(wheels, { weld = descendant, base = descendant.C0, front = descendant:GetAttribute("Front") })
		end
	end
end
local speedNeedle = car:FindFirstChild("SpeedNeedle", true)
local speedText = car:FindFirstChild("SpeedText", true)
local rpmNeedle = car:FindFirstChild("RpmNeedle", true)

local function loadTrack(humanoid, animationId, looped)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, track = pcall(animator.LoadAnimation, animator, animation)
	if ok then
		track.Looped = looped
		return track
	end
	return nil
end

-- Werden weiter unten gefüllt, aber schon vom Fremden benutzt
local sounds = {}
local strangerSteps

------------------------------------------------------------------ Mitfahrer als Puppe im Auto
local seatedPlayers = {}
local function seatPuppets()
	for _, other in Players:GetPlayers() do
		local otherSeat = other:GetAttribute("CutsceneSeat")
		local template = puppets:FindFirstChild(tostring(other.UserId))
		if other ~= player and not seatedPlayers[other] and otherSeat and template then
			seatedPlayers[other] = true
			local puppet = template:Clone()
			local hip = puppet:FindFirstChild("HumanoidRootPart")
			local humanoid = puppet:FindFirstChildOfClass("Humanoid")
			for _, part in puppet:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = false
					part.Massless = true
				end
			end
			hip.CFrame = root.CFrame * Route.CAR_HIPS[otherSeat]
			local weld = Instance.new("Weld")
			weld.Part0 = root
			weld.Part1 = hip
			weld.C0 = Route.CAR_HIPS[otherSeat]
			weld.Parent = hip
			puppet.Parent = car
			local sit = loadTrack(humanoid, SIT_ANIMATION, true)
			if sit then
				sit:Play(0)
			end
			seatedPlayers[other] = { puppet = puppet, hip = hip, weld = weld, sit = sit, humanoid = humanoid, seat = otherSeat }
		end
	end
end
seatPuppets()
puppets.ChildAdded:Connect(seatPuppets)
Players.PlayerAdded:Connect(function(other)
	other:GetAttributeChangedSignal("CutsceneSeat"):Connect(seatPuppets)
end)

------------------------------------------------------------------ Sarp (der Fremde)
-- Er wird nicht von der Physik bewegt, sondern zeitgesteuert entlang fester Linien.
-- So sehen alle Spieler ihn zur selben Zeit am selben Ort.
local stranger, strangerRoot, strangerHumanoid, strangerIdle, strangerWalk, strangerNeck
local strangerHeight = Vector3.zero
local strangerLine = Route.strangerLine()
local strangerTemplate = cutscene:WaitForChild("Stranger", 10)
if strangerTemplate then
	stranger = strangerTemplate:Clone()
	strangerRoot = stranger:FindFirstChild("HumanoidRootPart")
	strangerHumanoid = stranger:FindFirstChildOfClass("Humanoid")
	strangerHeight = Vector3.new(0, strangerHumanoid.HipHeight + strangerRoot.Size.Y / 2, 0)
	for _, part in stranger:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
	strangerRoot.Anchored = true
	stranger.Parent = workspace
	stranger:PivotTo(strangerLine.cframeAt(0) + strangerHeight)
	strangerIdle = loadTrack(strangerHumanoid, IDLE_ANIMATION, true)
	strangerWalk = loadTrack(strangerHumanoid, WALK_ANIMATION, true)
	if strangerIdle then
		strangerIdle:Play()
	end
	local head = stranger:FindFirstChild("Head")
	local neck = head and head:FindFirstChild("Neck")
	if neck and neck:IsA("Motor6D") then
		strangerNeck = { motor = neck, base = neck.C0 }
	end
end

-- Gehen oder Stehen umschalten (mit passender Animation)
local strangerWalking = false
local function setStrangerWalking(walking, speed)
	if walking == strangerWalking then
		return
	end
	strangerWalking = walking
	if walking then
		if strangerIdle then
			strangerIdle:Stop(0.3)
		end
		if strangerWalk then
			strangerWalk:Play(0.3, 1, speed or 0.55)
		end
	else
		if strangerWalk then
			strangerWalk:Stop(0.4)
		end
		if strangerIdle then
			strangerIdle:Play(0.4)
		end
	end
end

-- Haltung am Fenster: Zielwerte, denen die aktuellen Werte weich folgen
-- (lean = vorbeugen, tilt = Kopf schief, back = Schritt zurück, turn = zum Weg drehen)
local pose = { lean = 0, tilt = 0, back = 0, turn = 0 }
local poseTarget = { lean = 0, tilt = 0, back = 0, turn = 0 }
local strangerArrived = false
local sarpLeaveStart -- Ende "follow": wann er weggeht
local sarpFaceGroup = false
local sarpGone = false

------------------------------------------------------------------ Flackernde Laterne an der Parkbucht
task.spawn(function()
	local rng = Random.new()
	while true do
		task.wait(rng:NextNumber(0.8, 3.5))
		local lamps = CollectionService:GetTagged("FlickerLamp")
		local lens = #lamps > 0 and lamps[rng:NextInteger(1, #lamps)]
		if lens then
			local light = lens:FindFirstChildWhichIsA("Light")
			if light then
				local brightness, color = light.Brightness, lens.Color
				for _ = 1, rng:NextInteger(2, 6) do
					light.Brightness = brightness * 0.05
					lens.Color = color:Lerp(Color3.new(0, 0, 0), 0.8)
					task.wait(rng:NextNumber(0.03, 0.15))
					light.Brightness = brightness
					lens.Color = color
					task.wait(rng:NextNumber(0.04, 0.2))
				end
			end
		end
	end
end)

------------------------------------------------------------------ Sounds
-- IDs stehen in Config.SOUNDS. Fehlt eine ID, wird ein Ersatz genommen oder der Sound
-- fällt weg. Klopfen und Ast-Knacken klingen ohne eigene ID wie tiefe Schritte.
local FALLBACK_SOUNDS = {
	footstep = "rbxasset://sounds/action_footsteps_plastic.mp3",
}
local FALLBACK_KEYS = { knock = "footstep", twig = "footstep" }
local function makeSound(key, parent, props)
	local id = Config.SOUNDS and Config.SOUNDS[key] or ""
	if id == "" and FALLBACK_KEYS[key] then
		id = Config.SOUNDS[FALLBACK_KEYS[key]] or ""
		props = table.clone(props or {})
		props.PlaybackSpeed = key == "knock" and 0.55 or 1.9
	end
	if id == "" then
		id = FALLBACK_SOUNDS[key] or FALLBACK_SOUNDS[FALLBACK_KEYS[key]]
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

sounds = {
	engine = makeSound("engine", SoundService, { Looped = true, Volume = 0 }),
	road = makeSound("road", SoundService, { Looped = true, Volume = 0 }),
	wind = makeSound("wind", SoundService, { Looped = true, Volume = 0 }),
	forest = makeSound("forest", SoundService, { Looped = true, Volume = 0 }),
	gravel = makeSound("gravel", SoundService, { Looped = true, Volume = 0 }),
	music = makeSound("music", SoundService, { Looped = true, Volume = 0 }),
	radioStatic = makeSound("radioStatic", SoundService, { Looped = true, Volume = 0 }),
	brake = makeSound("brake", SoundService, { Volume = 0.35 }),
	blinker = makeSound("blinker", SoundService, { Volume = 0.5 }),
	sting = makeSound("sting", SoundService, { Volume = 0.7 }),
	knock = makeSound("knock", SoundService, { Volume = 0.9 }),
	twig = makeSound("twig", SoundService, { Volume = 0.8 }),
	steps = makeSound("footstep", SoundService, { Volume = 0.3 }),
}
-- Das Radio klingt wie aus kleinen Autolautsprechern
if sounds.music then
	local speaker = Instance.new("EqualizerSoundEffect")
	speaker.LowGain = -4
	speaker.MidGain = 0
	speaker.HighGain = -7
	speaker.Parent = sounds.music
end
for _, sound in sounds do
	if sound.Looped then
		sound:Play()
	end
end
-- Die alte Laterne summt (3D-Sound, nur in der Nähe hörbar)
for _, lens in CollectionService:GetTagged("FlickerLamp") do
	local buzz = makeSound("lampBuzz", lens, { Looped = true, Volume = 0.35, RollOffMaxDistance = 45 })
	if buzz then
		buzz:Play()
	end
end
strangerSteps = stranger and makeSound("footstep", strangerRoot, { Volume = 0.6, RollOffMaxDistance = 60 })
local function strangerStep()
	if strangerSteps then
		strangerSteps.PlaybackSpeed = 0.9 + math.random() * 0.2
		strangerSteps:Play()
	end
end

-- Lautstärke weich an ein Ziel annähern
local function blend(sound, volume, speed, deltaTime)
	if sound then
		sound.Volume += (volume - sound.Volume) * math.min(deltaTime * (speed or 3), 1)
	end
end

------------------------------------------------------------------ Umsehen mit Maus oder Finger
local yaw, pitch = 0, 0
UserInputService.InputChanged:Connect(function(input)
	local kind = input.UserInputType
	if (kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch) and not Choices.isChoosing() then
		local side = cutscene:GetAttribute("Branch") == "follow" and WALK_LOOK_SIDE or LOOK_SIDE
		yaw = math.clamp(yaw - input.Delta.X * SENSITIVITY, -side, side)
		pitch = math.clamp(pitch - input.Delta.Y * SENSITIVITY, -LOOK_DOWN, LOOK_UP)
	end
end)

------------------------------------------------------------------ Ablauf
local done = {}
local function once(name, action)
	if not done[name] then
		done[name] = true
		action()
	end
end

local camera = workspace.CurrentCamera
local wheelSpin = 0
local lastBlink, wasBlinking = false, false
local radioOff = false
local finished = false
local shakeUntil, shakeStrength = 0, 0
local sarpStepTimer = 0
local lastStepIndex = 0

local driveLine = Route.driveToHouseLine()
local walkLine = Route.walkLine()
local leaveLine = Route.leaveLine()
local walkStop = walkLine.length - Route.WALK_STOP_BEFORE
local walkSetup = 1.2 -- Sekunden nach Beginn von "follow": jetzt ist alles schwarz, man steigt aus
local garageSpot = Route.housePoint(Route.GARAGE_X, -Route.GARAGE_SIZE.Z / 2 - 3.5)

local function flat(position, height)
	return Vector3.new(position.X, height, position.Z)
end

-- Sarps Platz am Beifahrerfenster, Blick zum Auto
local windowPoint = Route.windowPoint()
local windowBase = CFrame.lookAt(windowPoint, flat(Route.carCFrame(Route.STOP_S).Position, windowPoint.Y))
local pathTurn
do
	local relative = windowBase:Inverse() * flat(Route.forestPath()[3], windowPoint.Y)
	pathTurn = math.atan2(-relative.X, -relative.Z)
end
local function windowPose()
	return windowBase
		* CFrame.new(0, 0, pose.back * 2.5 - pose.lean * 0.4)
		* CFrame.Angles(0, pose.turn * pathTurn, 0)
		* CFrame.Angles(-pose.lean * 0.2, 0, 0)
end

-- Lenkeinschlag entlang einer Linie (wie Route.steerAt)
local function lineSteer(line, s)
	local now, ahead = line.cframeAt(s).LookVector, line.cframeAt(s + 14).LookVector
	return math.clamp(math.asin(math.clamp(now:Cross(ahead).Y, -1, 1)), -0.5, 0.5)
end

------------------------------------------------------------------ Gespräch
local function handleAction(action)
	if action == "knock" then
		-- er beugt sich vor und klopft an die Scheibe
		poseTarget.lean = 1
		if sounds.knock then
			sounds.knock:Play()
		end
		shakeUntil, shakeStrength = os.clock() + 1.1, 0.05
		task.delay(1.5, function()
			poseTarget.lean = 0.4
		end)
	elseif action == "lean" then
		poseTarget.lean = 0.6
	elseif action == "tilt" then
		poseTarget.tilt = 1
	elseif action == "turnToPath" then
		poseTarget.turn = 1
		poseTarget.tilt = 0
	elseif action == "faceCar" then
		poseTarget.turn = 0
		poseTarget.lean = 0.5
		poseTarget.tilt = 0.4
	elseif action == "stepBack" then
		poseTarget.back = 1
		poseTarget.lean = 0
		poseTarget.tilt = 0.7
	elseif action == "crack" then
		if sounds.twig then
			sounds.twig:Play()
		end
	elseif action == "faceGroup" then
		sarpFaceGroup = true
	elseif action == "leave" then
		sarpLeaveStart = os.clock()
		sarpFaceGroup = false
	end
end

dialogueEvent.OnClientEvent:Connect(function(message)
	if message.type == "line" then
		Speech.say(message.speaker, message.name, message.text, message.duration)
	elseif message.type == "action" then
		handleAction(message.action)
	elseif message.type == "choice" then
		local chooser = message.chooser and Players:GetPlayerByUserId(message.chooser)
		Choices.show(message.options, message.chooser == player.UserId, chooser and chooser.DisplayName or "Der Fahrer", message.timeout, function(index)
			dialogueChoice:FireServer(index)
		end)
	elseif message.type == "chosen" then
		Choices.chosen(message.index)
	end
end)

local branch, branchStart
local function readBranch()
	branch = cutscene:GetAttribute("Branch")
	branchStart = cutscene:GetAttribute("BranchStart")
end
cutscene:GetAttributeChangedSignal("Branch"):Connect(readBranch)
readBranch()

------------------------------------------------------------------ Ende "follow": aussteigen
local flashlight
local function setupWalk()
	yaw, pitch = 0, 0
	-- Handylicht: folgt dem Blick mit etwas Verzögerung
	flashlight = Instance.new("Part")
	flashlight.Name = "PhoneLight"
	flashlight.Size = Vector3.new(0.2, 0.2, 0.2)
	flashlight.Transparency = 1
	flashlight.Anchored = true
	flashlight.CanCollide = false
	flashlight.CanQuery = false
	flashlight.CastShadow = false
	flashlight.CFrame = camera.CFrame
	local beam = Instance.new("SpotLight")
	beam.Face = Enum.NormalId.Front
	beam.Range = 42
	beam.Angle = 55
	beam.Brightness = 3.2
	beam.Color = Color3.fromRGB(225, 235, 255)
	beam.Shadows = true
	beam.Parent = flashlight
	local spill = Instance.new("PointLight")
	spill.Range = 7
	spill.Brightness = 0.35
	spill.Color = Color3.fromRGB(225, 235, 255)
	spill.Parent = flashlight
	flashlight.Parent = workspace

	-- Der Mitfahrer steigt auch aus und läuft neben einem her
	for _, info in seatedPlayers do
		if type(info) == "table" then
			if info.weld then
				info.weld:Destroy()
			end
			info.hip.Anchored = true
			if info.sit then
				info.sit:Stop(0)
			end
			info.walk = loadTrack(info.humanoid, WALK_ANIMATION, true)
			info.idle = loadTrack(info.humanoid, IDLE_ANIMATION, true)
			info.height = info.humanoid.HipHeight + info.hip.Size.Y / 2
			info.walking = false
			info.puppet.Parent = workspace
		end
	end
end

local function updatePuppets(walkS, moving)
	for _, info in seatedPlayers do
		if type(info) == "table" and info.height then
			local lateral = SIDE_BY_SIDE[info.seat] or 0
			info.hip.CFrame = walkLine.cframeAt(walkS) * CFrame.new(lateral, 0, 0) + Vector3.new(0, info.height, 0)
			if moving ~= info.walking then
				info.walking = moving
				local start, stop = info.walk, info.idle
				if not moving then
					start, stop = info.idle, info.walk
				end
				if stop then
					stop:Stop(0.3)
				end
				if start then
					start:Play(0.3, 1, moving and 0.8 or 1)
				end
			end
		end
	end
end

------------------------------------------------------------------ Sarp bewegen
local function updateStranger(t, bt, deltaTime, carPosition, driveS, walkS)
	if not stranger or sarpGone then
		return
	end
	for key, target in poseTarget do
		pose[key] += (target - pose[key]) * math.min(deltaTime * 3, 1)
	end
	if strangerNeck then
		strangerNeck.motor.C0 = strangerNeck.base * CFrame.Angles(0, 0, math.rad(28) * pose.tilt)
	end
	local function step(interval)
		sarpStepTimer += deltaTime
		if sarpStepTimer >= interval then
			sarpStepTimer = 0
			strangerStep()
		end
	end

	-- Ende "follow": er geht vorneweg, bleibt an der Veranda stehen und verschwindet dann
	if branch == "follow" and bt and bt >= walkSetup then
		if sarpLeaveStart then
			local elapsed = os.clock() - sarpLeaveStart
			setStrangerWalking(true, 0.5)
			step(0.8)
			strangerRoot.CFrame = leaveLine.cframeAt(elapsed * 4.5) + strangerHeight
			-- zwischen den Bäumen löst er sich auf
			local vanish = math.clamp((elapsed - 4) / 2.5, 0, 1)
			for _, part in stranger:GetDescendants() do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = vanish
				end
			end
			if vanish >= 1 then
				sarpGone = true
				stranger:Destroy()
			end
			return
		end
		local sarpS = math.min(walkS + 7, walkLine.length)
		local moving = bt > Route.WALK_FADE and sarpS < walkLine.length - 0.05
		setStrangerWalking(moving, 0.75)
		if moving then
			step(0.62)
		end
		local cframe = walkLine.cframeAt(sarpS)
		if sarpFaceGroup then
			cframe = CFrame.lookAt(cframe.Position, flat(camera.CFrame.Position, cframe.Position.Y))
		end
		strangerRoot.CFrame = cframe + strangerHeight
		return
	end

	-- Ende "drive": er bleibt zurück und schaut dem Auto nach. Hinter der Kurve steht
	-- er plötzlich vor der Garage im Scheinwerferlicht.
	if branch == "drive" and bt and bt >= 0 then
		setStrangerWalking(false)
		if driveS > 175 then
			poseTarget.tilt = 0.8
			strangerRoot.CFrame = CFrame.lookAt(garageSpot, flat(carPosition, garageSpot.Y)) + strangerHeight
		else
			local stand = (windowBase * CFrame.new(0, 0, 2.5)).Position
			strangerRoot.CFrame = CFrame.lookAt(stand, flat(carPosition, stand.Y)) + strangerHeight
		end
		return
	end

	-- Er kommt aus dem Wald zum Auto
	local walkT = t - Route.STRANGER_START
	local arrival = strangerLine.length / Route.STRANGER_SPEED
	if walkT < 0 then
		strangerRoot.CFrame = strangerLine.cframeAt(0) + strangerHeight
	elseif walkT < arrival then
		setStrangerWalking(true, 0.55)
		step(0.72)
		strangerRoot.CFrame = strangerLine.cframeAt(walkT * Route.STRANGER_SPEED) + strangerHeight
	else
		setStrangerWalking(false)
		if not strangerArrived then
			strangerArrived = true
			if sounds.sting then
				sounds.sting:Play()
			end
		end
		-- Drehung und Vorbeugen um die Füße, dann auf Hüfthöhe
		strangerRoot.CFrame = windowPose() * CFrame.new(strangerHeight)
	end
end

------------------------------------------------------------------ Jedes Bild
RunService.RenderStepped:Connect(function(deltaTime)
	local now = workspace:GetServerTimeNow()
	local t = now - startTime
	local bt = branchStart and now - branchStart or nil
	local driving = branch == "drive" and bt ~= nil and bt >= 0
	local walking = branch == "follow" and bt ~= nil and bt >= walkSetup

	-- Wo ist das Auto? Erst die Fahrt in die Parkbucht, im Ende "drive" weiter zum Haus
	local s, speed, steer, carFrame, moving
	if driving then
		s, speed = Route.profile(bt, driveLine.length, Route.DRIVE_TOP_SPEED, Route.DRIVE_ACCELERATION, Route.DRIVE_BRAKE)
		carFrame, steer = driveLine.cframeAt(s), lineSteer(driveLine, s)
		moving = math.clamp(speed / 30, 0, 1)
	else
		s, speed = Route.driveDistance(t)
		carFrame, steer = Route.carCFrame(s), Route.steerAt(s)
		moving = math.clamp(speed / Route.SPEED, 0, 1)
	end

	-- Auto: Straßenunebenheiten und leichtes Wanken, im Stand nur der laufende Motor
	local engineRunning = not walking
	local bump = (math.noise(s * 0.12, 1.7) * 0.05 + math.noise(t * 9, 4.2) * 0.008) * moving
		+ (engineRunning and math.noise(t * 14, 8.1) * 0.004 or 0)
	local roll = math.noise(s * 0.05, 3.3) * 0.012 * moving
	root.CFrame = carFrame * CFrame.new(0, bump, 0) * CFrame.Angles(0, 0, roll)

	-- Räder und Lenkrad
	wheelSpin = (wheelSpin + speed * deltaTime / 1.25) % (math.pi * 2)
	for _, wheel in wheels do
		local turn = wheel.front and CFrame.Angles(0, steer * 0.6, 0) or CFrame.new()
		wheel.weld.C0 = wheel.base * turn * CFrame.Angles(-wheelSpin, 0, 0)
	end
	if steering then
		steering.weld.C0 = steering.base * CFrame.Angles(0, 0, steer * 4)
	end

	-- Tacho und Drehzahl
	local kmh = speed * 1.3
	if speedNeedle then
		speedNeedle.Rotation = -120 + math.clamp(kmh / 200, 0, 1) * 240
		speedText.Text = tostring(math.floor(kmh + 0.5))
	end
	if rpmNeedle then
		local rpm = engineRunning and (0.12 + 0.3 * moving + math.noise(t * 2, 5) * 0.02) or 0
		rpmNeedle.Rotation = -120 + rpm * 240
	end

	-- Kamera: im Auto in den Augen des Spielers, zu Fuß auf Augenhöhe mit Schrittwippen
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 74
	local shake = os.clock() < shakeUntil and shakeStrength or 0
	local headShake = Vector3.new(
		math.noise(t * 1.3, 0.5) * 0.03 + (math.random() - 0.5) * shake,
		math.noise(t * 1.1, 2.5) * 0.03 + (math.random() - 0.5) * shake,
		0
	)
	local look = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	local walkS = 0
	if walking then
		walkS = math.clamp((bt - Route.WALK_FADE) * Route.WALK_SPEED, 0, walkStop)
		local stepping = bt > Route.WALK_FADE and walkS < walkStop
		local phase = walkS * 1.1
		local lateral = duo and SIDE_BY_SIDE[seatName] or 0
		camera.CFrame = walkLine.cframeAt(walkS)
			* CFrame.new(lateral + math.sin(phase) * 0.06, Route.WALK_EYE_HEIGHT + math.abs(math.sin(phase)) * 0.16, 0)
			* CFrame.new(headShake)
			* look
		local stepIndex = math.floor(phase / math.pi)
		if stepIndex ~= lastStepIndex then
			lastStepIndex = stepIndex
			if stepping and sounds.steps then
				sounds.steps.PlaybackSpeed = 0.85 + math.random() * 0.2
				sounds.steps:Play()
			end
		end
		updatePuppets(walkS, stepping)
		if flashlight then
			local target = camera.CFrame * CFrame.new(0.35, -0.45, -0.3)
			flashlight.CFrame = flashlight.CFrame:Lerp(target, math.min(deltaTime * 10, 1))
		end
	else
		camera.CFrame = root.CFrame * Route.CAR_EYES[seatName] * CFrame.new(headShake) * look
	end
	if Choices.isChoosing() then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end

	updateStranger(t, bt, deltaTime, root.Position, driving and s or 0, walkS)

	-- Sounds: Motor, Fahrgeräusche, Wald und Radio. Am Ende wird alles leise.
	local master = finished and 0 or 1
	local onGravel
	if driving then
		onGravel = s < 40 or s > driveLine.length - 45
	else
		onGravel = s > Route.LAYBY_START_S - 10
	end
	if sounds.engine then
		sounds.engine.PlaybackSpeed = 0.75 + 0.55 * moving
	end
	blend(sounds.engine, (engineRunning and 0.35 + 0.15 * moving or 0) * master, 3, deltaTime)
	blend(sounds.road, (onGravel and 0 or 0.45 * moving) * master, 3, deltaTime)
	blend(sounds.wind, 0.22 * moving * moving * master, 3, deltaTime)
	blend(sounds.gravel, (onGravel and 0.5 * moving or 0) * master, 5, deltaTime)
	blend(sounds.forest, (walking and 0.6 or speed < 1 and 0.45 or 0.1) * master, 0.8, deltaTime)
	local musicVolume = (t < 0 or radioOff) and 0 or (Speech.isSpeaking() and 0.14 or 0.32)
	blend(sounds.music, musicVolume * master, radioOff and 1.5 or 0.6, deltaTime)
	blend(sounds.radioStatic, (radioOff and not walking and 0.22 or 0) * master, 1.5, deltaTime)
	if t >= Route.CRUISE_TIME + 0.6 then
		once("brake", function()
			if sounds.brake then
				sounds.brake:Play()
			end
		end)
	end
	if driving and s > driveLine.length - 12 then
		once("brakeHouse", function()
			if sounds.brake then
				sounds.brake.Volume = 0.2
				sounds.brake:Play()
			end
		end)
	end

	-- Blinker rechts: beim Ranfahren an die Parkbucht und vor der Einfahrt zum Haus
	local blinking = (not branch and t >= Route.CRUISE_TIME - 3 and t <= Route.STOP_TIME + 2)
		or (driving and s > driveLine.length - 80 and s < driveLine.length - 10)
	local blinkOn = blinking and (t % 0.76) < 0.38
	if blinkOn ~= lastBlink or blinking ~= wasBlinking then
		lastBlink, wasBlinking = blinkOn, blinking
		for _, indicator in rightIndicators do
			if blinkOn then
				indicator.part.Color = Color3.fromRGB(255, 170, 40)
			elseif blinking then
				indicator.part.Color = indicator.color:Lerp(Color3.new(0, 0, 0), 0.6)
			else
				indicator.part.Color = indicator.color
			end
		end
		if blinkerArrow then
			blinkerArrow.TextTransparency = blinkOn and 0 or 1
		end
		if blinking and sounds.blinker then
			sounds.blinker.PlaybackSpeed = blinkOn and 1 or 0.85
			sounds.blinker:Play()
		end
	end

	-- Zeitplan
	if t >= 0 then
		once("fadeIn", function()
			TweenService:Create(fade, TweenInfo.new(2.5), { BackgroundTransparency = 1 }):Play()
		end)
	end
	if t >= 2.5 then
		once("chapterIn", function()
			showText(chapter, true, 1.5)
			showText(chapterTitle, true, 2)
		end)
	end
	if t >= 7 then
		once("chapterOut", function()
			showText(chapter, false, 1.5)
			showText(chapterTitle, false, 1.5)
		end)
	end
	-- Erzählung während der Fahrt
	for index, entry in Dialogue.NARRATION do
		if t >= entry.at and t < entry.at + 3 then
			once("narration" .. index, function()
				local text = Dialogue.text(entry.text, duo)
				local voice = Config.VOICES and Config.VOICES.narrator
				Speech.say("narrator", nil, text, Dialogue.duration(text, voice and voice.speed))
				if entry.radioOff then
					radioOff = true
					if radioText then
						radioText.Text = "FM --.-   ~~ KEIN EMPFANG ~~"
					end
				end
			end)
		end
	end
	-- Ende "drive": die Scheinwerfer erfassen ihn vor der Garage
	if driving and s > driveLine.length - 30 then
		once("garageSting", function()
			if sounds.sting then
				sounds.sting:Play()
			end
		end)
	end
	-- Ende "follow": abblenden, aussteigen, aufblenden
	if branch == "follow" and bt then
		if bt >= 0 then
			once("followFadeOut", function()
				TweenService:Create(fade, TweenInfo.new(0.9), { BackgroundTransparency = 0 }):Play()
			end)
		end
		if bt >= walkSetup then
			once("followSetup", setupWalk)
		end
		if bt >= walkSetup + 1 then
			once("followFadeIn", function()
				TweenService:Create(fade, TweenInfo.new(1.5), { BackgroundTransparency = 1 }):Play()
			end)
		end
	end
	-- Schluss: schwarz, "Fortsetzung folgt …"
	if cutscene:GetAttribute("Finished") then
		once("finish", function()
			finished = true
			TweenService:Create(fade, TweenInfo.new(3), { BackgroundTransparency = 0 }):Play()
			task.delay(3.5, function()
				chapter.Text = "ENDE VON KAPITEL 1"
				chapterTitle.Text = "Fortsetzung folgt …"
				showText(chapter, true, 1.5)
				showText(chapterTitle, true, 2)
			end)
		end)
	end
end)
