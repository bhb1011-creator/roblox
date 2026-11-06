-- Kapitel 3 auf dem Client: Kapitelkarte, die Sequenz im Ritualraum mit den drei
-- Quick-Time-Events, die Flucht durch den Wald und Sarps Verwandlung (Stufe 3).
-- Der Server gibt den Takt vor (Nachrichten mit type = "k3"), alles Sichtbare passiert hier:
-- Kamera, Animationen (eigene Kopien von Sarp und dem Biest, die Gelenke der Familie nur
-- auf diesem Computer), Geräusche und Anzeigen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Data = require(Shared:WaitForChild("Kapitel3Data"))
local Beast = require(Shared:WaitForChild("Beast"))
local Script = require(Shared:WaitForChild("Kapitel2Dialogue"))

local Kapitel3 = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local UP = Vector3.yAxis
local remotes -- ReplicatedStorage.Kapitel2

------------------------------------------------------------------ Kleine Helfer
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function unit(v, fallback)
	if v.Magnitude < 1e-4 then
		return fallback or Vector3.new(0, 0, -1)
	end
	return v.Unit
end
local function ease(a, kind)
	a = math.clamp(a, 0, 1)
	if kind == "in" then
		return a * a * a
	elseif kind == "out" then
		return 1 - (1 - a) ^ 3
	elseif kind == "linear" then
		return a
	elseif kind == "back" then
		local c = 1.7
		return 1 + (c + 1) * (a - 1) ^ 3 + c * (a - 1) ^ 2
	end
	return a * a * (3 - 2 * a)
end
local function noise(t, seed)
	return math.noise(t, seed or 0.5) * 2
end

------------------------------------------------------------------ Geräusche
-- Solange ein Sound noch keine ID hat (Config.SOUNDS leer): ein vorhandener als Ersatz
-- (anderes Tempo). Die richtigen Dateien kommen später (siehe Config.SOUNDS, "Kapitel 3").
local FALLBACK = {
	chapterHit = { "sting", 0.45 },
	neckCrack = { "footstep", 1.9 },
	ritualSting = { "sting", 0.7 },
	clawSwipe = { "footstep", 2.2 },
	clawHit = { "sting", 1.3 },
	sarpGrab = { "sting", 0.9 },
	bodyFall = { "footstep", 0.5 },
	candleFall = { "footstep", 0.6 },
	fireBurst = { "sting", 0.5 },
	sarpBurn = { "sting", 0.55 },
	puppetCollapse = { "footstep", 0.4 },
	transformCrack = { "footstep", 1.4 },
	sarpStep = { "footstep", 0.42 },
	beastStep = { "footstep", 0.35 },
	heartbeat = { "footstep", 0.3 },
	roar = { "sting", 0.6 },
	sarpRoar = { "sting", 0.6 },
	jumpscare = { "sting", 0.85 },
	qteFail = { "sting", 1.6 },
}

local function makeSound(key, parent, props)
	local id = Config.SOUNDS[key] or ""
	local speed = 1
	if id == "" and FALLBACK[key] then
		id = Config.SOUNDS[FALLBACK[key][1]] or ""
		speed = FALLBACK[key][2]
	end
	if id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = id
	sound.RollOffMinDistance = 6
	sound.RollOffMaxDistance = 120
	for property, value in props or {} do
		sound[property] = value
	end
	sound.PlaybackSpeed *= speed
	sound.Parent = parent or SoundService
	return sound
end

local function play(key, props, parent)
	local sound = makeSound(key, parent, props)
	if sound then
		sound:Play()
		task.delay(10, function()
			sound:Destroy()
		end)
	end
	return sound
end

-- Geräusch an einer Stelle in der Welt
local function playAt(key, position, props)
	local holder = Instance.new("Part")
	holder.Name = "K3Sound"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.4, 0.4, 0.4)
	holder.CFrame = CFrame.new(position)
	holder.Parent = workspace
	local sound = play(key, props, holder)
	task.delay(10, function()
		holder:Destroy()
	end)
	return sound
end

-- Schleifen (Flüstern, Atmen, Musik): an, aus, Lautstärke
local loops = {}
local function loop(key, volume, parent)
	local current = loops[key]
	if current and current.Parent then
		TweenService:Create(current, TweenInfo.new(0.6), { Volume = volume }):Play()
		return current
	end
	local sound = makeSound(key, parent, { Looped = true, Volume = 0 })
	if sound then
		loops[key] = sound
		sound:Play()
		TweenService:Create(sound, TweenInfo.new(0.8), { Volume = volume }):Play()
	end
	return sound
end
local function stopLoop(key, fadeTime)
	local sound = loops[key]
	loops[key] = nil
	if sound then
		if fadeTime and fadeTime > 0 then
			TweenService:Create(sound, TweenInfo.new(fadeTime), { Volume = 0 }):Play()
			task.delay(fadeTime + 0.1, function()
				sound:Destroy()
			end)
		else
			sound:Destroy()
		end
	end
end
local function stopAllLoops()
	for key in loops do
		stopLoop(key, 0)
	end
end

------------------------------------------------------------------ Anzeige
local gui, black, cardTop, cardTitle, caption, bigHint, flash, scratches
local qteFrame, qteTitle, qteSub, dodgeButton, struggleButton, struggleBar, struggleFill, timingButton, timingTarget, timingRing, timeBar, timeFill
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

local function text(props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.SpecialElite
	props.AutoLocalize = false
	props.TextTransparency = props.TextTransparency or 1
	props.TextStrokeTransparency = props.TextStrokeTransparency or 1
	return create("TextLabel", props)
end

local function buildGui()
	gui = create("ScreenGui", {
		Name = "Kapitel3UI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 15,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- Balken oben und unten (Kino) während der Zwischensequenz
	for _, top in { true, false } do
		create("Frame", {
			Name = top and "BarTop" or "BarBottom",
			AnchorPoint = Vector2.new(0, top and 0 or 1),
			Position = UDim2.fromScale(0, top and 0 or 1),
			Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 40,
			Parent = gui,
		})
	end
	flash = create("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(150, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 44,
		Parent = gui,
	})
	-- drei Kratzer quer übers Bild (wenn Sarp trifft)
	scratches = create("Frame", {
		Name = "Scratches",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 45,
		Parent = gui,
	})
	for i = -1, 1 do
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + i * 0.08, 0.5 + i * 0.03),
			Size = UDim2.new(0.9, 0, 0, 7),
			Rotation = 28 + i * 3,
			BackgroundColor3 = Color3.fromRGB(120, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 45,
			Parent = scratches,
		})
	end
	black = create("Frame", {
		Name = "Black",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 50,
		Parent = gui,
	})
	cardTop = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(0.9, 0, 0, 40),
		Text = "",
		TextSize = 30,
		TextColor3 = Color3.fromRGB(235, 222, 205),
		ZIndex = 52,
		Parent = gui,
	})
	cardTitle = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0, 64),
		Text = "",
		TextSize = 52,
		TextColor3 = Color3.fromRGB(235, 222, 205),
		ZIndex = 52,
		Parent = gui,
	})
	-- Flüstern der Familie (unten, grau)
	caption = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.8),
		Size = UDim2.new(0.8, 0, 0, 40),
		Text = "",
		TextSize = 28,
		TextColor3 = Color3.fromRGB(190, 180, 172),
		Font = Enum.Font.Fondamento,
		ZIndex = 46,
		Parent = gui,
	})
	bigHint = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.9, 0, 0, 70),
		Text = "",
		TextSize = 54,
		TextColor3 = Color3.fromRGB(225, 40, 30),
		ZIndex = 47,
		Parent = gui,
	})

	-------------------------------------------------- Quick-Time-Events
	qteFrame = create("Frame", {
		Name = "Qte",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.56),
		Size = UDim2.fromOffset(460, 340),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 48,
		Parent = gui,
	})
	qteTitle = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(1, 0, 0, 46),
		Text = "",
		TextSize = 40,
		TextColor3 = Color3.fromRGB(245, 225, 210),
		TextTransparency = 0,
		TextStrokeTransparency = 0.3,
		ZIndex = 49,
		Parent = qteFrame,
	})
	qteSub = text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(1, 0, 0, 28),
		Text = "",
		TextSize = 22,
		TextColor3 = Color3.fromRGB(220, 210, 200),
		TextTransparency = 0,
		TextStrokeTransparency = 0.4,
		ZIndex = 49,
		Parent = qteFrame,
	})
	-- Zeitbalken (wird kürzer)
	timeBar = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -40),
		Size = UDim2.fromOffset(300, 8),
		BackgroundColor3 = Color3.fromRGB(40, 30, 28),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 49,
		Parent = qteFrame,
	})
	timeFill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(230, 70, 50),
		BorderSizePixel = 0,
		ZIndex = 50,
		Parent = timeBar,
	})
	-- 1) Ausweichen: ein großer Pfeil (Knopf zum Antippen am Handy)
	dodgeButton = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(220, 130),
		BackgroundColor3 = Color3.fromRGB(120, 18, 14),
		BackgroundTransparency = 0.15,
		Text = "",
		Font = Enum.Font.GothamBlack,
		TextSize = 64,
		TextColor3 = Color3.new(1, 1, 1),
		AutoLocalize = false,
		Visible = false,
		ZIndex = 49,
		Parent = qteFrame,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = dodgeButton })
	create("UIStroke", { Color = Color3.fromRGB(255, 200, 170), Thickness = 3, Parent = dodgeButton })
	-- 2) Losreißen: E schnell drücken, Balken füllt sich
	struggleButton = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.44),
		Size = UDim2.fromOffset(130, 130),
		BackgroundColor3 = Color3.fromRGB(120, 18, 14),
		BackgroundTransparency = 0.1,
		Text = UserInputService.TouchEnabled and "TIPP" or "E",
		Font = Enum.Font.GothamBlack,
		TextSize = UserInputService.TouchEnabled and 40 or 72,
		TextColor3 = Color3.new(1, 1, 1),
		AutoLocalize = false,
		Visible = false,
		ZIndex = 49,
		Parent = qteFrame,
	})
	create("UICorner", { CornerRadius = UDim.new(0.2, 0), Parent = struggleButton })
	create("UIStroke", { Color = Color3.fromRGB(255, 200, 170), Thickness = 3, Parent = struggleButton })
	struggleBar = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.44, 80),
		Size = UDim2.fromOffset(300, 18),
		BackgroundColor3 = Color3.fromRGB(40, 30, 28),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 49,
		Parent = qteFrame,
	})
	struggleFill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(240, 210, 130),
		BorderSizePixel = 0,
		ZIndex = 50,
		Parent = struggleBar,
	})
	-- 3) Timing: ein Kreis schrumpft auf den Zielkreis zu – im richtigen Moment drücken
	timingButton = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(380, 260),
		BackgroundTransparency = 1,
		Text = "",
		AutoLocalize = false,
		Visible = false,
		ZIndex = 49,
		Parent = qteFrame,
	})
	timingTarget = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(110, 110),
		BackgroundColor3 = Color3.fromRGB(120, 18, 14),
		BackgroundTransparency = 0.35,
		ZIndex = 49,
		Parent = timingButton,
	})
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = timingTarget })
	create("UIStroke", { Color = Color3.fromRGB(255, 220, 190), Thickness = 4, Parent = timingTarget })
	text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Text = UserInputService.TouchEnabled and "TIPP" or "LEER",
		TextSize = 24,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 0,
		ZIndex = 50,
		Parent = timingTarget,
	})
	timingRing = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(340, 340),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = timingButton,
	})
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = timingRing })
	create("UIStroke", { Color = Color3.fromRGB(255, 120, 90), Thickness = 5, Parent = timingRing })
end

local function setBlack(transparency, duration)
	if duration and duration > 0 then
		TweenService:Create(black, TweenInfo.new(duration), { BackgroundTransparency = transparency }):Play()
	else
		black.BackgroundTransparency = transparency
	end
end

local function showCard(top, title, visible, duration)
	cardTop.Text = top or cardTop.Text
	cardTitle.Text = title or cardTitle.Text
	for _, label in { cardTop, cardTitle } do
		TweenService:Create(label, TweenInfo.new(duration or 1.5), { TextTransparency = visible and 0 or 1, TextStrokeTransparency = visible and 0.6 or 1 }):Play()
	end
end

local function setBars(visible, duration)
	for _, name in { "BarTop", "BarBottom" } do
		TweenService:Create(gui[name], TweenInfo.new(duration or 0.8), { Size = UDim2.fromScale(1, visible and 0.07 or 0) }):Play()
	end
end

local captionToken = 0
local function whisperCaption(line, seconds)
	captionToken += 1
	local mine = captionToken
	caption.Text = line
	TweenService:Create(caption, TweenInfo.new(0.8), { TextTransparency = 0.15, TextStrokeTransparency = 0.7 }):Play()
	task.delay(seconds or 2, function()
		if captionToken == mine then
			TweenService:Create(caption, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end
local function hideCaption()
	captionToken += 1
	caption.TextTransparency = 1
	caption.TextStrokeTransparency = 1
end

local hintToken = 0
local function showBigHint(line, seconds, color)
	hintToken += 1
	local mine = hintToken
	bigHint.Text = line
	bigHint.TextColor3 = color or Color3.fromRGB(225, 40, 30)
	bigHint.TextSize = 70
	TweenService:Create(bigHint, TweenInfo.new(0.25), { TextTransparency = 0, TextStrokeTransparency = 0.3, TextSize = 54 }):Play()
	task.delay(seconds or 2, function()
		if hintToken == mine then
			TweenService:Create(bigHint, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local function redFlash(strength, duration)
	flash.BackgroundTransparency = 1 - (strength or 0.6)
	TweenService:Create(flash, TweenInfo.new(duration or 0.8), { BackgroundTransparency = 1 }):Play()
end

local function showScratches()
	scratches.Visible = true
	for _, line in scratches:GetChildren() do
		if line:IsA("Frame") then
			line.BackgroundTransparency = 0.05
			TweenService:Create(line, TweenInfo.new(1.4), { BackgroundTransparency = 1 }):Play()
		end
	end
	task.delay(1.5, function()
		scratches.Visible = false
	end)
end

------------------------------------------------------------------ Abbrechen (neuer Versuch, Game Over)
local token = 0
local CANCELLED = "K3Cancelled"
local function current(mine)
	return token == mine
end
-- warten; bricht den Ablauf ab, wenn inzwischen etwas Neues angefangen hat
local function hold(mine, seconds)
	local stop = os.clock() + seconds
	repeat
		RunService.RenderStepped:Wait() -- (wartet immer mindestens ein Bild)
		if token ~= mine then
			error(CANCELLED, 0)
		end
	until os.clock() >= stop
end
local function run(mine, fn, ...)
	local args = table.pack(...)
	task.spawn(function()
		local ok, problem = pcall(fn, table.unpack(args, 1, args.n))
		if not ok and problem ~= CANCELLED then
			warn("Kapitel 3 (Client): " .. tostring(problem))
		end
	end)
	return mine
end

------------------------------------------------------------------ Werte weich ändern
local tweens = {}
local function tweenValue(target, key, to, duration, kind)
	for i = #tweens, 1, -1 do
		if tweens[i].target == target and tweens[i].key == key then
			table.remove(tweens, i)
		end
	end
	if not duration or duration <= 0 then
		target[key] = to
		return
	end
	table.insert(tweens, { target = target, key = key, from = target[key], to = to, start = os.clock(), duration = duration, kind = kind })
end
local function updateTweens(now)
	for i = #tweens, 1, -1 do
		local tw = tweens[i]
		local a = math.clamp((now - tw.start) / tw.duration, 0, 1)
		local e = ease(a, tw.kind)
		if type(tw.from) == "number" then
			tw.target[tw.key] = tw.from + (tw.to - tw.from) * e
		else
			tw.target[tw.key] = tw.from:Lerp(tw.to, e)
		end
		if a >= 1 then
			table.remove(tweens, i)
		end
	end
end

------------------------------------------------------------------ Figuren bewegen (Rig)
-- Jedes Gelenk (Motor6D) bekommt eine Drehung relativ zur Grundhaltung ("base"). Die
-- Figur steht mit den Füßen bei `feet` und schaut nach `facing`; mit `grounded` wird sie so
-- hoch- oder runtergeschoben, dass ihr tiefster Punkt genau auf dem Boden liegt (dafür
-- wird die Haltung hier ausgerechnet, nicht erst von der Physik).
local Rig = {}
Rig.__index = Rig

function Rig.new(model, root, useBaseAttribute, rootOffset)
	local self = setmetatable({}, Rig)
	self.model = model
	self.root = root
	self.joints = {}
	self.motorOf = {}
	self.layers = {}
	self.rootOffset = rootOffset or CFrame.new()
	for _, item in model:GetDescendants() do
		if item:IsA("Motor6D") and item.Part0 and item.Part1 then
			local base = useBaseAttribute and item:GetAttribute("Base") or nil
			if typeof(base) ~= "CFrame" then
				base = item.C0
			end
			self.joints[item.Name] = { motor = item, base = base, current = CFrame.identity, from = CFrame.identity }
			self.motorOf[item.Part1] = item
		end
	end
	self:captureWelds()
	return self
end

function Rig:captureWelds()
	self.welds = {}
	self.solid = {}
	for _, item in self.model:GetDescendants() do
		if item:IsA("WeldConstraint") and item.Part0 and item.Part1 then
			table.insert(self.welds, { part = item.Part1, to = item.Part0, offset = item.Part0.CFrame:ToObjectSpace(item.Part1.CFrame) })
		elseif item:IsA("BasePart") and item ~= self.root and item.Transparency < 0.95 then
			table.insert(self.solid, item)
		end
	end
end

-- Haltung ändern: nur die genannten Gelenke, in `duration` Sekunden
function Rig:change(pose, duration, kind)
	local now = os.clock()
	for name, target in pose do
		local joint = self.joints[name]
		if joint then
			joint.from = joint.current
			joint.to = target
			joint.start = now
			joint.duration = duration or 0
			joint.kind = kind
		end
	end
end

-- ganze Haltung setzen (nicht genannte Gelenke gehen in die Grundhaltung)
function Rig:setPose(pose, duration, kind)
	local full = {}
	for name in self.joints do
		full[name] = pose[name] or CFrame.identity
	end
	self:change(full, duration, kind)
end

-- tiefster Punkt der Figur, wenn die Mitte bei `rootFrame` wäre
function Rig:lowest(rootFrame)
	local frames = { [self.root] = rootFrame }
	local motorOf = self.motorOf
	local function frameOf(part)
		local known = frames[part]
		if known then
			return known
		elseif known == false then
			return nil
		end
		local motor = motorOf[part]
		local parentFrame = motor and frameOf(motor.Part0)
		if not parentFrame then
			frames[part] = false
			return nil
		end
		local frame = parentFrame * motor.C0 * motor.C1:Inverse()
		frames[part] = frame
		return frame
	end
	for _, weld in self.welds do
		if frames[weld.part] == nil then
			local to = frameOf(weld.to)
			if to then
				frames[weld.part] = to * weld.offset
			end
		end
	end
	local lowest = math.huge
	for _, part in self.solid do
		local frame = frameOf(part)
		if frame then
			local half = part.Size / 2
			local extent = math.abs(frame.RightVector.Y) * half.X + math.abs(frame.UpVector.Y) * half.Y + math.abs(frame.LookVector.Y) * half.Z
			lowest = math.min(lowest, frame.Position.Y - extent)
		end
	end
	return lowest
end

function Rig:update(now)
	local extra = {}
	for _, layer in self.layers do
		local add = layer(now, self)
		if add then
			for name, frame in add do
				extra[name] = (extra[name] or CFrame.identity) * frame
			end
		end
	end
	for name, joint in self.joints do
		if joint.to then
			local a = joint.duration > 0 and math.clamp((now - joint.start) / joint.duration, 0, 1) or 1
			joint.current = joint.from:Lerp(joint.to, ease(a, joint.kind))
		end
		local relative = joint.current
		if extra[name] then
			relative = relative * extra[name]
		end
		if not joint.broken then
			local ok = pcall(function()
				joint.motor.C0 = joint.base * relative
			end)
			-- (manche Gelenke lassen sich nicht ändern: dann in Ruhe lassen)
			joint.broken = not ok
		end
	end
	if self.feet then
		local facing = unit(flat(self.facing or Vector3.new(0, 0, -1)))
		local rootFrame = CFrame.lookAt(self.feet, self.feet + facing) * (self.tilt or CFrame.identity) * self.rootOffset
		if self.grounded then
			local lowest = self:lowest(rootFrame)
			if lowest < math.huge then
				rootFrame += Vector3.new(0, self.feet.Y - lowest, 0)
			end
		end
		if self.lift then
			rootFrame += Vector3.new(0, self.lift, 0)
		end
		self.root.CFrame = rootFrame
	end
end

-- Alles zurück in die Grundhaltung
function Rig:reset()
	for _, joint in self.joints do
		joint.current = CFrame.identity
		joint.from = CFrame.identity
		joint.to = nil
		pcall(function()
			joint.motor.C0 = joint.base
		end)
	end
end

-- Größer werden (Verwandlung): kurz Grundhaltung, skalieren, neue Grundhaltung merken
function Rig:rescale(factor)
	for _, joint in self.joints do
		joint.motor.C0 = joint.base
	end
	local ok = pcall(function()
		self.model:ScaleTo(factor)
	end)
	if ok then
		for _, joint in self.joints do
			joint.base = joint.motor.C0
		end
		self:captureWelds()
	end
	return ok
end

function Rig:part(name)
	return self.model:FindFirstChild(name)
end

-- Kopie einer Figur nur für diesen Computer (Sarp)
local function localCopy(model, name)
	if not model then
		return nil
	end
	local ok, copy = pcall(function()
		return model:Clone()
	end)
	if not ok or not copy then
		return nil
	end
	copy.Name = name
	for _, item in copy:GetDescendants() do
		if item:IsA("BasePart") then
			item.CanCollide = false
			item.CanQuery = false
			item.CanTouch = false
		elseif item:IsA("LuaSourceContainer") then
			item:Destroy()
		end
	end
	local root = copy:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = true
	end
	copy.Parent = workspace
	return copy
end

local function footOffsetOf(model)
	local stored = model:GetAttribute("FootOffset")
	if stored then
		return stored
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	return humanoid and root and (humanoid.HipHeight + root.Size.Y / 2) or 3
end

------------------------------------------------------------------ Kamera
local active = false -- Zwischensequenz: die Kamera gehört Kapitel 3
local rigs = {} -- alle Figuren, die gerade bewegt werden
local cam = { fov = 70, shakeUntil = 0, shakeStrength = 0, kick = CFrame.identity }
local function shot(fn, blend, kind)
	cam.from = camera.CFrame
	cam.fn = fn
	cam.start = os.clock()
	cam.blend = blend or 0
	cam.kind = kind or "inout"
end
local function still(cframe, blend, kind)
	shot(function()
		return cframe
	end, blend, kind)
end
local function shake(strength, duration)
	cam.shakeStrength = strength
	cam.shakeUntil = os.clock() + duration
	cam.shakeDuration = duration
end
-- plötzlicher Stoß, der wieder abklingt
local function kick(offset)
	cam.kick = offset
end
local function setFov(value, duration)
	tweenValue(cam, "fov", value, duration or 0.6, "inout")
end

-- eigene Figur ausblenden (die Kamera steckt sonst im eigenen Kopf)
local hiddenParts = {}
local function hideOwnCharacter(hidden)
	local character = player.Character
	if hidden and character then
		for _, item in character:GetDescendants() do
			if item:IsA("BasePart") or item:IsA("Decal") then
				item.LocalTransparencyModifier = 1
				hiddenParts[item] = true
			end
		end
		for _, name in { "HeldAxe", "HeldCandle" } do
			local held = workspace:FindFirstChild(name)
			for _, item in held and held:GetDescendants() or {} do
				if item:IsA("BasePart") then
					item.LocalTransparencyModifier = 1
					hiddenParts[item] = true
				end
			end
		end
	elseif not hidden then
		for item in hiddenParts do
			if item.Parent then
				item.LocalTransparencyModifier = 0
			end
		end
		table.clear(hiddenParts)
	end
end

local function startCutscene()
	active = true
	camera.CameraType = Enum.CameraType.Scriptable
	cam.from = camera.CFrame
	cam.fn = nil
	cam.fov = 70
	setBars(true, 0.6)
end

local function stopCutscene(keepCamera)
	active = false
	cam.fn = nil
	hideOwnCharacter(false)
	setBars(false, 0.6)
	camera.FieldOfView = 70
	if not keepCamera then
		camera.CameraType = Enum.CameraType.Custom
	end
end

local function updateCamera(now)
	if not active then
		return
	end
	hideOwnCharacter(true)
	local target = cam.fn and cam.fn(now) or camera.CFrame
	local a = cam.blend > 0 and ease((now - cam.start) / cam.blend, cam.kind) or 1
	local frame = (cam.from or target):Lerp(target, a)
	if now < cam.shakeUntil then
		local left = (cam.shakeUntil - now) / math.max(cam.shakeDuration or 1, 0.01)
		local s = cam.shakeStrength * math.clamp(left * 1.5, 0, 1)
		frame *= CFrame.Angles(noise(now * 23, 1.1) * s, noise(now * 21, 2.3) * s, noise(now * 17, 3.7) * s * 0.6)
	end
	frame *= cam.kick
	cam.kick = cam.kick:Lerp(CFrame.identity, 0.12)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = frame
	camera.FieldOfView = cam.fov
end

------------------------------------------------------------------ Szene im Ritualraum
local scene -- alles, was zur aktuellen Sequenz gehört
local localFolder -- eigene Kopien und Requisiten (nur auf diesem Computer)

local function newLocalFolder()
	if localFolder then
		localFolder:Destroy()
	end
	localFolder = Instance.new("Folder")
	localFolder.Name = "Kapitel3Local"
	localFolder.Parent = workspace
	return localFolder
end

-- Kerzen im Ritualraum (zum Flackern und Ausgehen)
local function ritualCandles(center)
	local list = {}
	local house = workspace:FindFirstChild("WagnerHouse", true)
	for _, light in house and house:GetDescendants() or {} do
		if light:IsA("PointLight") and light.Parent and light.Parent:IsA("BasePart") and (light.Parent.Position - center).Magnitude < 12 then
			table.insert(list, light)
		end
	end
	return list
end
local function setCandles(list, on)
	for _, light in list do
		if light.Parent then
			light.Enabled = on
			light.Parent.LocalTransparencyModifier = on and 0 or 1
		end
	end
end

local function cleanupScene()
	local old = scene
	scene = nil
	if not old then
		return
	end
	for _, rig in old.puppets or {} do
		rig:reset()
	end
	if old.candles then
		setCandles(old.candles, true)
	end
	for i = #rigs, 1, -1 do
		table.remove(rigs, i)
	end
	table.clear(tweens)
	hideCaption()
	qteFrame.Visible = false
end

-- Puppen-Haltung: Kopf hängt, Arme leicht nach vorne wie an Fäden
local PUPPET_IDLE = {
	Neck = CFrame.fromEulerAnglesYXZ(-0.55, 0, 0.32),
	Waist = CFrame.Angles(-0.07, 0, 0.03),
	LeftShoulder = CFrame.Angles(0.28, 0, -0.14),
	RightShoulder = CFrame.Angles(0.28, 0, 0.14),
	LeftElbow = CFrame.Angles(0.4, 0, 0),
	RightElbow = CFrame.Angles(0.4, 0, 0),
}
-- zusammengesackt (die Fäden sind durch)
local PUPPET_COLLAPSED = {
	Neck = CFrame.fromEulerAnglesYXZ(-0.9, 0, 0.5),
	Waist = CFrame.Angles(-0.85, 0, 0.1),
	LeftShoulder = CFrame.Angles(0.15, 0, -0.35),
	RightShoulder = CFrame.Angles(0.1, 0, 0.4),
	LeftElbow = CFrame.Angles(0.2, 0, 0),
	RightElbow = CFrame.Angles(0.3, 0, 0),
	LeftHip = CFrame.Angles(1.35, 0, -0.1),
	RightHip = CFrame.Angles(1.25, 0, 0.12),
	LeftKnee = CFrame.Angles(-2.1, 0, 0),
	RightKnee = CFrame.Angles(-2.2, 0, 0),
}
-- Sarp im niedrigen Ritualraum: gebückt, lauernd
local SARP_IDLE = {
	Waist = CFrame.Angles(-0.3, 0, 0.06),
	Neck = CFrame.Angles(0.2, 0, 0),
	LeftShoulder = CFrame.Angles(0.2, 0, -0.18),
	RightShoulder = CFrame.Angles(0.2, 0, 0.18),
	LeftElbow = CFrame.Angles(0.35, 0, 0),
	RightElbow = CFrame.Angles(0.35, 0, 0),
	LeftHip = CFrame.Angles(0.22, 0, 0),
	RightHip = CFrame.Angles(0.22, 0, 0),
	LeftKnee = CFrame.Angles(-0.42, 0, 0),
	RightKnee = CFrame.Angles(-0.42, 0, 0),
}

-- Gehen/Rennen (R15): Phase in Bogenmaß, amount 0..1
local function walkLayer(state)
	return function()
		local amount = state.walk or 0
		if amount < 0.01 then
			return nil
		end
		local p = state.phase or 0
		local swing = math.sin(p) * amount
		return {
			LeftHip = CFrame.Angles(swing * 0.75, 0, 0),
			RightHip = CFrame.Angles(-swing * 0.75, 0, 0),
			LeftKnee = CFrame.Angles(-math.max(0, math.cos(p)) * 0.9 * amount, 0, 0),
			RightKnee = CFrame.Angles(-math.max(0, -math.cos(p)) * 0.9 * amount, 0, 0),
			LeftShoulder = CFrame.Angles(-swing * 0.6, 0, 0),
			RightShoulder = CFrame.Angles(swing * 0.6, 0, 0),
			Waist = CFrame.Angles(-0.25 * amount, math.sin(p) * 0.12 * amount, 0),
		}
	end
end

-- Kopf ruckartig zu einem Punkt drehen (Puppe): Winkel relativ zum Oberkörper
local function stareAngles(rig, target)
	local torso = rig:part("UpperTorso")
	local head = rig:part("Head")
	if not (torso and head) then
		return 0, 0
	end
	local relative = torso.CFrame:Inverse() * target - Vector3.new(0, torso.Size.Y / 2 + head.Size.Y / 2, 0)
	local yaw = math.clamp(math.atan2(-relative.X, -relative.Z), -2.95, 2.95)
	local pitch = math.clamp(math.atan2(relative.Y, Vector2.new(relative.X, relative.Z).Magnitude), -0.7, 0.7)
	return yaw, pitch
end

local function sarpHeadPosition(rig)
	local head = rig and rig:part("Head")
	return head and head.Position or (rig and rig.feet and rig.feet + Vector3.new(0, 5, 0)) or Vector3.zero
end

-- Kerzenständer aus Eisen mit drei roten Kerzen (nur auf diesem Computer)
local function buildCandelabrum(parent, base)
	local model = Instance.new("Model")
	model.Name = "K3Candelabrum"
	local function piece(name, size, offset, color, material, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		if shape then
			part.Shape = shape
		end
		part.CFrame = CFrame.new(base) * offset
		part.Color = color
		part.Material = material
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Parent = model
		return part
	end
	local iron = Color3.fromRGB(38, 36, 36)
	local side = CFrame.Angles(0, 0, math.rad(90))
	piece("Foot", Vector3.new(0.25, 1.4, 1.4), CFrame.new(0, 0.12, 0) * side, iron, Enum.Material.Metal, Enum.PartType.Cylinder)
	piece("Pole", Vector3.new(5.0, 0.18, 0.18), CFrame.new(0, 2.6, 0) * side, iron, Enum.Material.Metal, Enum.PartType.Cylinder)
	piece("Arm", Vector3.new(1.9, 0.14, 0.14), CFrame.new(0, 4.9, 0), iron, Enum.Material.Metal)
	for i = -1, 1 do
		piece("Cup", Vector3.new(0.15, 0.4, 0.4), CFrame.new(i * 0.85, 5.0, 0) * side, iron, Enum.Material.Metal, Enum.PartType.Cylinder)
		piece("Wax", Vector3.new(0.7, 0.2, 0.2), CFrame.new(i * 0.85, 5.4, 0) * side, Color3.fromRGB(110, 20, 18), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		local flame = piece("Flame", Vector3.new(0.16, 0.16, 0.16), CFrame.new(i * 0.85, 5.85, 0), Color3.fromRGB(255, 70, 40), Enum.Material.Neon, Enum.PartType.Ball)
		if i == 0 then
			local light = Instance.new("PointLight")
			light.Name = "K3CandleLight"
			light.Color = Color3.fromRGB(255, 60, 40)
			light.Range = 12
			light.Brightness = 1.6
			light.Shadows = true
			light.Parent = flame
		end
	end
	model.WorldPivot = CFrame.new(base)
	model.Parent = parent
	return model
end

-- Feuer auf Sarp (der Kerzenständer ist auf ihn gefallen)
local function setOnFire(rig)
	local fires = {}
	for _, name in { "UpperTorso", "Head", "LeftUpperArm", "RightUpperArm", "LowerTorso" } do
		local part = rig:part(name)
		if part then
			local fire = Instance.new("Fire")
			fire.Size = name == "UpperTorso" and 6 or 4
			fire.Heat = 12
			fire.Color = Color3.fromRGB(255, 120, 30)
			fire.SecondaryColor = Color3.fromRGB(200, 30, 10)
			fire.Parent = part
			table.insert(fires, fire)
		end
	end
	local torso = rig:part("UpperTorso")
	if torso then
		local light = Instance.new("PointLight")
		light.Name = "K3FireLight"
		light.Color = Color3.fromRGB(255, 130, 50)
		light.Range = 18
		light.Brightness = 3
		light.Shadows = true
		light.Parent = torso
		table.insert(rig.layers, function(now)
			if light.Parent then
				light.Brightness = 2.4 + noise(now * 9, 4.4) * 1.2
			end
			return nil
		end)
	end
	return fires
end

------------------------------------------------------------------ Quick-Time-Events (Eingabe)
local qte -- { kind, dir, deadline, need, count, onDone }
local function finishQte(success)
	local current = qte
	if not current then
		return
	end
	qte = nil
	qteFrame.Visible = false
	dodgeButton.Visible = false
	struggleButton.Visible = false
	struggleBar.Visible = false
	timingButton.Visible = false
	play(success and "qteSuccess" or "qteFail", { Volume = 0.9 })
	current.onDone(success)
end

local function qteInput(kind, value)
	if not qte or qte.kind ~= kind then
		return
	end
	if kind == "dodge" then
		finishQte(value == qte.dir)
	elseif kind == "struggle" then
		qte.count += 1
		struggleFill.Size = UDim2.fromScale(math.clamp(qte.count / qte.need, 0, 1), 1)
		struggleButton.Size = UDim2.fromOffset(118, 118)
		TweenService:Create(struggleButton, TweenInfo.new(0.12), { Size = UDim2.fromOffset(130, 130) }):Play()
		if qte.onTap then
			qte.onTap(qte.count / qte.need)
		end
		if qte.count >= qte.need then
			finishQte(true)
		end
	elseif kind == "timing" then
		local size = timingRing.AbsoluteSize.X
		local target = timingTarget.AbsoluteSize.X
		local ratio = target > 0 and size / target or 0
		finishQte(ratio >= 0.78 and ratio <= 1.3)
	end
end

local function startQte(kind, dir, window, onDone, onTap)
	qte = { kind = kind, dir = dir, deadline = os.clock() + window, window = window, onDone = onDone, onTap = onTap }
	qteFrame.Visible = true
	timeFill.Size = UDim2.fromScale(1, 1)
	TweenService:Create(timeFill, TweenInfo.new(window, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) }):Play()
	if kind == "dodge" then
		qteTitle.Text = "AUSWEICHEN!"
		local touch = UserInputService.TouchEnabled
		dodgeButton.Text = dir < 0 and (touch and "◀" or "◀  A") or (touch and "▶" or "D  ▶")
		dodgeButton.Position = UDim2.fromScale(dir < 0 and 0.3 or 0.7, 0.48)
		dodgeButton.Visible = true
		qteSub.Text = dir < 0 and "nach links" or "nach rechts"
	elseif kind == "struggle" then
		qte.need = Data.QTE.struggle.taps
		qte.count = 0
		qteTitle.Text = "REISS DICH LOS!"
		qteSub.Text = UserInputService.TouchEnabled and "schnell tippen" or "E schnell drücken"
		struggleFill.Size = UDim2.fromScale(0, 1)
		struggleButton.Visible = true
		struggleBar.Visible = true
	elseif kind == "timing" then
		qteTitle.Text = "JETZT – IM RICHTIGEN MOMENT!"
		qteSub.Text = UserInputService.TouchEnabled and "tippen, wenn der Kreis passt" or "Leertaste, wenn der Kreis passt"
		timingButton.Visible = true
		timingRing.Size = UDim2.fromOffset(340, 340)
		-- schrumpft bis weit unter den Zielkreis (110): wer zu spät drückt, verfehlt
		TweenService:Create(timingRing, TweenInfo.new(window, Enum.EasingStyle.Linear), { Size = UDim2.fromOffset(40, 40) }):Play()
	end
	local mine = qte
	task.delay(window, function()
		if qte == mine then
			finishQte(false)
		end
	end)
end

------------------------------------------------------------------ Nachrichten vom Server
local handlers = {}
local qteRemote
local function report(index, success)
	qteRemote = qteRemote or (remotes and remotes:FindFirstChild("K3Qte"))
	if qteRemote then
		qteRemote:FireServer(index, success)
	end
end

-- Die Tür ist auf: schwarz, KAPITEL 3
function handlers.card(message)
	token += 1
	setBlack(0, 0.35)
	task.delay(1.2, function()
		play("chapterHit", { Volume = 1.6 })
		showCard("KAPITEL 3", message.title or "", true, 1.8)
	end)
	task.delay(6.2, function()
		showCard(nil, nil, false, 1.4)
	end)
end

-- Die Sequenz im Ritualraum
function handlers.ritual(message)
	token += 1
	local mine = token
	cleanupScene()
	newLocalFolder()
	qte = nil
	setBlack(0, 0)
	showCard(nil, nil, false, 0.2)
	local S = { mine = mine, misses = 0 }
	scene = S
	local center = message.center
	local door = message.door
	S.center = center
	S.floorY = center.Y
	S.flee = message.flee or {}
	local spot = message.spots and message.spots[tostring(player.UserId)]
	if not spot then
		for _, any in message.spots or {} do
			spot = any
			break
		end
	end
	spot = spot or (center + Vector3.new(0, 0, 7))
	S.spot = spot
	local toDoor = unit(flat(door - spot))
	local right = Vector3.new(-toDoor.Z, 0, toDoor.X) -- (vom Spieler aus, wenn er zur Tür schaut: rechts)
	S.toDoor, S.right = toDoor, right
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local eyeHeight = head and math.clamp(head.Position.Y + 0.25 - spot.Y, 3.8, 5.2) or 4.6
	S.eye = spot + Vector3.new(0, eyeHeight, 0)
	S.sitEye = spot - toDoor * 1.3 + Vector3.new(0, 1.9, 0) -- nach hinten gefallen, auf dem Boden

	-- die Familie: Puppen
	S.puppets = {}
	for _, info in message.puppets or {} do
		local model = info.model
		local root = model and model:FindFirstChild("HumanoidRootPart")
		if root then
			local rig = Rig.new(model, root, true, CFrame.new(0, footOffsetOf(model), 0))
			rig.home = info.home
			rig:reset()
			root.CFrame = info.home
			rig.feet = info.home.Position - Vector3.new(0, footOffsetOf(model), 0)
			rig.facing = flat(center - rig.feet)
			rig.grounded = true
			rig:setPose(PUPPET_IDLE, 0)
			rig.stare = nil -- Punkt, zu dem der Kopf ruckt
			rig.seed = math.random() * 50
			-- Atmen im Gleichtakt (unheimlich: alle gleich) und Zucken an den Fäden
			table.insert(rig.layers, function(now)
				local pull = S.stringPull or 0
				local sway = math.sin(now * 0.9) * 0.03
				local add = {
					Waist = CFrame.Angles(0, 0, sway),
					LeftShoulder = CFrame.Angles(pull * 0.7, 0, -pull * 0.2),
					RightShoulder = CFrame.Angles(pull * 0.7, 0, pull * 0.2),
				}
				if rig.stare then
					-- Kopf zeigt ruckartig auf den Punkt (springt, statt weich zu drehen)
					local yaw, pitch = stareAngles(rig, rig.stare())
					local snap = rig.snapped
					if not snap or math.abs(yaw - snap.yaw) > 0.2 or math.abs(pitch - snap.pitch) > 0.15 then
						if not snap or now - snap.at > 0.45 then
							rig.snapped = { yaw = yaw, pitch = pitch, at = now }
						end
					end
					local s = rig.snapped or { yaw = yaw, pitch = pitch }
					local twitch = (math.noise(now * 3, rig.seed) > 0.42) and 0.08 or 0
					-- die Grundhaltung des Kopfes (hängend) wird ersetzt
					add.Neck = PUPPET_IDLE.Neck:Inverse() * CFrame.fromEulerAnglesYXZ(s.pitch, s.yaw, 0.18 + twitch)
				end
				return add
			end)
			table.insert(S.puppets, rig)
			table.insert(rigs, rig)
		end
	end
	S.stringPull = 0

	-- Sarp: eigene Kopie, im niedrigen Raum etwas kleiner (sonst steckt der Kopf in der Decke)
	local folder = localFolder
	local sarpModel = localCopy(message.sarp, "SarpK3")
	if sarpModel then
		sarpModel.Parent = folder
		local ceiling = (message.ceiling or (S.floorY + 5.6)) - S.floorY
		local height = sarpModel:GetExtentsSize().Y
		if height > ceiling then
			pcall(function()
				sarpModel:ScaleTo(sarpModel:GetScale() * ceiling / height)
			end)
		end
		local root = sarpModel:FindFirstChild("HumanoidRootPart")
		local rig = Rig.new(sarpModel, root, false, CFrame.new(0, footOffsetOf(sarpModel), 0))
		rig.feet = door + Vector3.new(0, -40, 0) -- erst versteckt
		rig.facing = flat(spot - door)
		rig.grounded = true
		rig.walkState = { walk = 0, phase = 0 }
		table.insert(rig.layers, walkLayer(rig.walkState))
		-- Atmen, Zucken
		table.insert(rig.layers, function(now)
			local breath = math.sin(now * 1.7) * 0.05
			local twitch = math.noise(now * 2.2, 9.1) > 0.45 and noise(now * 30, 2) * 0.12 or 0
			return {
				Waist = CFrame.Angles(breath, 0, 0),
				Neck = CFrame.Angles(0, twitch, twitch * 0.5),
			}
		end)
		-- (Arm zittert beim Ausholen, Kopf wird beim Losreißen weggestoßen)
		table.insert(rig.layers, function(now)
			local add = {}
			if S.armTremble then
				add.RightShoulder = CFrame.Angles(noise(now * 25, 5) * 0.06, 0, noise(now * 22, 6) * 0.05)
			end
			if S.headPush and S.headPush > 0.01 then
				add.Neck = CFrame.Angles(S.headPush, noise(now * 20, 7) * S.headPush * 0.5, 0)
			end
			if S.thrash then
				local t = now * 9
				add.Waist = CFrame.Angles(noise(t, 1) * 0.35, noise(t, 2) * 0.5, noise(t, 3) * 0.3)
				add.Neck = CFrame.Angles(noise(t, 4) * 0.7, noise(t, 5) * 0.9, noise(t, 6) * 0.6)
				add.LeftShoulder = CFrame.Angles(noise(t, 7) * 1.2, 0, noise(t, 8) * 0.8)
				add.RightShoulder = CFrame.Angles(noise(t, 9) * 1.2, 0, noise(t, 10) * 0.8)
				add.LeftElbow = CFrame.Angles(math.abs(noise(t, 11)) * 1.2, 0, 0)
				add.RightElbow = CFrame.Angles(math.abs(noise(t, 12)) * 1.2, 0, 0)
			end
			return add
		end)
		rig:setPose(SARP_IDLE, 0)
		-- schwaches rotes Licht, damit man ihn im dunklen Gang sieht
		local torso = rig:part("UpperTorso")
		if torso then
			local glow = Instance.new("PointLight")
			glow.Color = Color3.fromRGB(200, 40, 30)
			glow.Range = 9
			glow.Brightness = 1.1
			glow.Parent = torso
		end
		S.sarp = rig
		table.insert(rigs, rig)
	end

	-- der Kerzenständer neben einem (fällt später auf Sarp)
	local side = (spot - center):Dot(right) >= 0 and right or -right
	S.candelabrumBase = spot + side * 1.7 + toDoor * 0.7
	S.candelabrum = buildCandelabrum(folder, S.candelabrumBase)
	S.candles = ritualCandles(center)

	startCutscene()
	run(mine, function()
		local K = Script.KAPITEL3 or {}
		local whispers = K.whispers or {}
		------------------------------------------------ 0 s: von oben auf den Kreis, Flüstern
		local first = unit(flat(door - center))
		local ringDir = function(angle)
			local c, s = math.cos(angle), math.sin(angle)
			return Vector3.new(first.X * c - first.Z * s, 0, first.X * s + first.Z * c)
		end
		local startDir = ringDir(math.rad(35))
		still(CFrame.lookAt(center + startDir * 7.6 + UP * 5.0, center + UP * 2.2), 0)
		shot(function(now)
			local a = ease((now - S.t0) / 3.4, "inout")
			local position = (center + startDir * (7.6 - a * 1.0) + UP * (5.0 - a * 0.7))
			return CFrame.lookAt(position, center + UP * (2.2 + a * 0.6))
		end, 0)
		S.t0 = os.clock()
		setBlack(1, 2.2)
		loop("ritualWhisper", 0.9)
		task.delay(1.6, function()
			if current(mine) then
				whisperCaption(whispers[1] or "...", 2.2)
			end
		end)
		hold(mine, 3.4)
		------------------------------------------------ 3.4 s: Kamera fährt um den Kreis
		local orbitStart = os.clock()
		local fromAngle = math.rad(35)
		shot(function(now)
			local a = ease((now - orbitStart) / 7.6, "inout")
			local angle = fromAngle + a * math.rad(215)
			local position = center + ringDir(angle) * 6.9 + UP * (4.2 + math.sin(a * math.pi) * 0.3)
			local look = center + UP * 3.3 + Vector3.new(noise(now * 0.6, 1) * 0.15, noise(now * 0.5, 2) * 0.1, 0)
			return CFrame.lookAt(position, look)
		end, 0.8)
		task.delay(1.0, function()
			if current(mine) then
				whisperCaption(whispers[2] or "...", 2)
			end
		end)
		task.delay(3.2, function()
			if current(mine) then
				whisperCaption(whispers[3] or "...", 2.2)
				S.stringPull = 0.35 -- alle zucken gleichzeitig, wie an Fäden
				tweenValue(S, "stringPull", 0, 0.7, "out")
			end
		end)
		task.delay(5.4, function()
			if current(mine) then
				whisperCaption(whispers[4] or "...", 2)
			end
		end)
		-- die Köpfe rucken herum, einer nach dem anderen – zur Kamera
		local cameraPoint = function()
			return camera.CFrame.Position
		end
		for i, delay in { 3.2, 4.3, 5.1, 5.9 } do
			task.delay(delay, function()
				local rig = S.puppets[i]
				if current(mine) and rig then
					rig.stare = cameraPoint
					rig.snapped = nil
					local head = rig:part("Head")
					playAt("neckCrack", head and head.Position or center, { Volume = 1.4 })
				end
			end)
		end
		hold(mine, 7.6)
		------------------------------------------------ 11 s: Stille. Man selbst, alle starren einen an
		stopLoop("ritualWhisper", 0)
		hideCaption()
		still(CFrame.lookAt(S.eye, center + UP * 3.2), 0)
		setFov(66, 1.5)
		hold(mine, 1.6)
		------------------------------------------------ 12.6 s: die Kerzen flackern, gehen aus
		for _ = 1, 6 do
			setCandles(S.candles, false)
			hold(mine, 0.05 + math.random() * 0.07)
			setCandles(S.candles, true)
			hold(mine, 0.06 + math.random() * 0.1)
		end
		setCandles(S.candles, false)
		playAt("ritualSting", S.eye, { Volume = 1.3 })
		-- im Dunkeln: Sarp steht jetzt im Gang
		if S.sarp then
			S.sarp.feet = door
		end
		hold(mine, 0.45)
		setCandles(S.candles, true)
		------------------------------------------------ 13.5 s: ein Schritt hinter einem – umdrehen
		playAt("sarpStep", door + UP * 0.5, { Volume = 2.4 })
		for _, rig in S.puppets do
			-- alle Köpfe rucken zum Eingang (an einem vorbei)
			rig.stare = function()
				return sarpHeadPosition(S.sarp)
			end
			rig.snapped = nil
		end
		hold(mine, 0.35)
		local turnStart = os.clock()
		shot(function(now)
			local target = sarpHeadPosition(S.sarp)
			local a = ease((now - turnStart) / 1.0, "inout")
			-- dreht sich über die Schulter um (nicht durch die Wand schauen)
			local look = (center + UP * 3.2):Lerp(target, a) + S.right * math.sin(a * math.pi) * 2
			return CFrame.lookAt(S.eye, look)
		end, 0)
		setFov(56, 3.2)
		hold(mine, 2.6)
		------------------------------------------------ 16.5 s: er kommt näher
		if S.sarp then
			local stand = spot + toDoor * 3.2
			S.sarp.walkState.walk = 0.55
			local walkStart = os.clock()
			table.insert(S.sarp.layers, function(now)
				S.sarp.walkState.phase = (now - walkStart) * 4.2
				return nil
			end)
			tweenValue(S.sarp, "feet", stand, 2.4, "inout")
			for i = 0, 2 do
				task.delay(i * 0.75, function()
					if current(mine) then
						playAt("sarpStep", S.sarp.feet + UP * 0.5, { Volume = 2.2 })
					end
				end)
			end
			task.delay(2.4, function()
				if current(mine) then
					S.sarp.walkState.walk = 0
				end
			end)
		end
		shot(function()
			return CFrame.lookAt(S.eye, sarpHeadPosition(S.sarp))
		end, 0.4)
		setFov(68, 2)
		loop("heartbeat", 0.7)
	end)
end

-- Quick-Time-Events (der Server sagt, welches)
function handlers.qte(message)
	local S = scene
	if not S then
		return
	end
	local mine = S.mine
	local kind = message.kind
	local timing = Data.QTE[kind]
	local sarp = S.sarp
	local index = message.index
	local reported = false
	local function done(success)
		if reported then
			return
		end
		reported = true
		report(index, success)
		if not success then
			S.misses += 1
			if S.misses > Data.MAX_MISSES then
				S.dead = true -- (der Server schickt gleich "killed")
			else
				showBigHint("Noch ein Fehler – und er hat dich.", 2.2, Color3.fromRGB(235, 225, 210))
			end
		end
	end
	run(mine, function()
		local eye = S.eye
		local toDoor, right = S.toDoor, S.right
		local function lookAtSarp(from)
			return function()
				return CFrame.lookAt(from, sarpHeadPosition(sarp))
			end
		end
		if kind == "dodge" then
			------------------------------------------------ 1) Er holt mit den Klauen aus
			local dir = message.dir or 1
			if sarp then
				sarp:change({
					RightShoulder = CFrame.Angles(2.6, 0, 0.35),
					RightElbow = CFrame.Angles(0.9, 0, 0),
					Waist = CFrame.Angles(-0.15, -0.45, 0),
					Neck = CFrame.Angles(0.3, 0.2, 0),
				}, timing.windup * 0.8, "out")
			end
			playAt("sarpBreath", sarpHeadPosition(sarp), { Volume = 1.6 })
			shot(lookAtSarp(eye), 0.3)
			shake(0.006, timing.windup)
			hold(mine, timing.windup)
			S.armTremble = true
			local result
			startQte("dodge", dir, timing.window, function(success)
				result = success
			end)
			while result == nil do
				hold(mine, 0)
			end
			S.armTremble = false
			done(result)
			if S.dead then
				return
			end
			-- der Schlag
			if sarp then
				sarp:change({
					RightShoulder = CFrame.Angles(0.5, 0, -0.75),
					RightElbow = CFrame.Angles(0.15, 0, 0),
					Waist = CFrame.Angles(-0.4, 0.55, 0),
					Neck = CFrame.Angles(0.1, -0.2, 0),
				}, 0.18, "in")
			end
			play("clawSwipe", { Volume = 1.4 })
			if result then
				-- ausgewichen: zur Seite und runter, die Klauen gehen ins Leere
				local dodged = eye + right * dir * 1.5 - UP * 0.7
				local from = os.clock()
				shot(function(now)
					local a = ease((now - from) / 0.22, "out")
					local position = eye:Lerp(dodged, a)
					return CFrame.lookAt(position, sarpHeadPosition(sarp)) * CFrame.Angles(0, 0, -dir * 0.22 * a)
				end, 0)
				hold(mine, 0.45)
				if sarp then
					-- er stolpert nach vorne (zu viel Schwung)
					sarp:change({ Waist = CFrame.Angles(-0.65, 0.5, 0) }, 0.3, "out")
					tweenValue(sarp, "feet", sarp.feet - toDoor * 0.7 - right * dir * 0.3, 0.35, "out")
					playAt("sarpStep", sarp.feet + UP * 0.5, { Volume = 2 })
				end
				hold(mine, 0.7)
				shot(lookAtSarp(eye), 0.7)
			else
				hold(mine, 0.18)
				-- getroffen
				redFlash(0.65, 0.9)
				showScratches()
				play("clawHit", { Volume = 1.6 })
				kick(CFrame.new(-dir * 0.4, -0.2, 0.3) * CFrame.Angles(0.1, -dir * 0.25, dir * 0.45))
				shake(0.03, 0.6)
				hold(mine, 1.0)
				shot(lookAtSarp(eye), 0.6)
			end
			if sarp then
				sarp:change(SARP_IDLE, 0.9, "inout")
				tweenValue(sarp, "feet", S.spot + toDoor * 3.0, 0.9, "inout")
			end
		elseif kind == "struggle" then
			------------------------------------------------ 2) Er packt einen
			if sarp then
				tweenValue(sarp, "feet", S.spot + toDoor * 1.45, 0.3, "in")
				sarp:change({
					LeftShoulder = CFrame.Angles(1.5, 0, 0.25),
					RightShoulder = CFrame.Angles(1.5, 0, -0.25),
					LeftElbow = CFrame.Angles(0.35, 0, 0),
					RightElbow = CFrame.Angles(0.35, 0, 0),
					Waist = CFrame.Angles(-0.35, 0, 0),
					Neck = CFrame.Angles(-0.2, 0, 0),
				}, 0.3, "in")
			end
			hold(mine, 0.3)
			play("sarpGrab", { Volume = 1.6 })
			redFlash(0.35, 0.5)
			local pinned = eye - toDoor * 0.45 + UP * 0.15
			kick(CFrame.new(0, 0.1, 0.4) * CFrame.Angles(0.15, 0, 0.1))
			shot(lookAtSarp(pinned), 0.15, "out")
			setFov(78, 0.3)
			shake(0.02, timing.windup + timing.window)
			hold(mine, timing.windup - 0.3)
			local result
			S.headPush = 0
			startQte("struggle", nil, timing.window, function(success)
				result = success
			end, function()
				-- jeder Druck: man stößt ihn ein Stück weg
				S.headPush = math.min((S.headPush or 0) + 0.18, 0.5)
				tweenValue(S, "headPush", 0, 0.35, "out")
				kick(CFrame.Angles((math.random() - 0.5) * 0.08, (math.random() - 0.5) * 0.08, (math.random() - 0.5) * 0.1))
			end)
			while result == nil do
				hold(mine, 0)
			end
			done(result)
			S.headPush = 0
			if S.dead then
				return
			end
			setFov(68, 0.6)
			if result then
				-- losgerissen: er taumelt zurück, man fällt nach hinten auf den Boden
				if sarp then
					tweenValue(sarp, "feet", S.spot + toDoor * 3.8, 0.4, "out")
					sarp:change({
						Waist = CFrame.Angles(0.35, 0, 0),
						LeftShoulder = CFrame.Angles(2.2, 0, -0.6),
						RightShoulder = CFrame.Angles(2.0, 0, 0.6),
						Neck = CFrame.Angles(0.45, 0, 0),
					}, 0.3, "out")
				end
				play("bodyFall", { Volume = 1.2 })
				local fallStart = os.clock()
				shot(function(now)
					local a = ease((now - fallStart) / 0.55, "in")
					return CFrame.lookAt(pinned:Lerp(S.sitEye, a), sarpHeadPosition(sarp))
				end, 0)
				hold(mine, 0.55)
				kick(CFrame.new(0, -0.15, 0) * CFrame.Angles(-0.1, 0, 0.05))
				shake(0.02, 0.4)
			else
				-- er hebt einen hoch und schleudert einen zu Boden
				local up = pinned + UP * 0.8
				local liftStart = os.clock()
				shot(function(now)
					local a = ease((now - liftStart) / 0.35, "out")
					return CFrame.lookAt(pinned:Lerp(up, a), sarpHeadPosition(sarp))
				end, 0)
				if sarp then
					sarp:change({ LeftShoulder = CFrame.Angles(2.0, 0, 0.2), RightShoulder = CFrame.Angles(2.0, 0, -0.2), Waist = CFrame.Angles(0.1, 0, 0) }, 0.35, "out")
				end
				hold(mine, 0.4)
				play("sarpGrab", { Volume = 1.2, PlaybackSpeed = 0.8 })
				if sarp then
					sarp:change({ LeftShoulder = CFrame.Angles(0.6, 0, 0.3), RightShoulder = CFrame.Angles(0.6, 0, -0.3), Waist = CFrame.Angles(-0.5, 0.3, 0) }, 0.3, "in")
				end
				local throwStart = os.clock()
				shot(function(now)
					local a = ease((now - throwStart) / 0.45, "in")
					return CFrame.lookAt(up:Lerp(S.sitEye, a), sarpHeadPosition(sarp)) * CFrame.Angles(0, 0, a * 0.5)
				end, 0)
				hold(mine, 0.45)
				redFlash(0.7, 1)
				play("bodyFall", { Volume = 1.5 })
				shake(0.04, 0.6)
				hold(mine, 0.4)
				shot(lookAtSarp(S.sitEye), 0.8)
				if sarp then
					tweenValue(sarp, "feet", S.spot + toDoor * 3.3, 0.8, "out")
				end
			end
			if sarp then
				sarp:change(SARP_IDLE, 1.0, "inout")
			end
		elseif kind == "timing" then
			------------------------------------------------ 3) Er beugt sich über einen – der Kerzenständer!
			local sit = S.sitEye
			shot(lookAtSarp(sit), 0.4)
			if sarp then
				sarp.walkState.walk = 0.4
				local walkStart = os.clock()
				table.insert(sarp.layers, function(now)
					if sarp.walkState.walk > 0 then
						sarp.walkState.phase = (now - walkStart) * 3.6
					end
					return nil
				end)
				tweenValue(sarp, "feet", S.spot + S.toDoor * 1.2, timing.windup + timing.window, "linear")
				sarp:change({
					Waist = CFrame.Angles(-0.55, 0, 0),
					Neck = CFrame.Angles(-0.35, 0, 0),
					LeftShoulder = CFrame.Angles(1.1, 0, 0.3),
					RightShoulder = CFrame.Angles(1.1, 0, -0.3),
					LeftElbow = CFrame.Angles(0.5, 0, 0),
					RightElbow = CFrame.Angles(0.5, 0, 0),
				}, timing.windup + timing.window, "inout")
			end
			playAt("sarpBreath", sarpHeadPosition(sarp), { Volume = 1.8 })
			hold(mine, 0.5)
			-- kurzer Blick zum Kerzenständer
			local glanceStart = os.clock()
			local top = S.candelabrumBase + UP * 4.6
			shot(function(now)
				local a = math.sin(math.clamp((now - glanceStart) / 0.9, 0, 1) * math.pi)
				return CFrame.lookAt(sit, sarpHeadPosition(sarp):Lerp(top, a * 0.85))
			end, 0)
			hold(mine, timing.windup - 0.5)
			local result
			startQte("timing", nil, timing.window, function(success)
				result = success
			end)
			while result == nil do
				hold(mine, 0)
			end
			done(result)
			if sarp then
				sarp.walkState.walk = 0
				tweenValue(sarp, "feet", sarp.feet, 0)
			end
			if S.dead then
				return
			end
			local function topple()
				-- der Kerzenständer kippt auf ihn
				local base = S.candelabrumBase
				local towards = unit(flat(sarpHeadPosition(sarp) - base))
				local axis = UP:Cross(towards).Unit
				local fallStart = os.clock()
				play("candleFall", { Volume = 1.4 })
				local model = S.candelabrum
				local connection
				connection = RunService.RenderStepped:Connect(function()
					if not model.Parent then
						connection:Disconnect()
						return
					end
					local a = ease((os.clock() - fallStart) / 0.5, "in")
					model:PivotTo(CFrame.new(base) * CFrame.fromAxisAngle(axis, a * math.rad(62)))
					if a >= 1 then
						connection:Disconnect()
					end
				end)
				hold(mine, 0.45)
				play("fireBurst", { Volume = 1.6 })
				playAt("sarpBurn", sarpHeadPosition(sarp), { Volume = 2.4 })
				if sarp then
					setOnFire(sarp)
					S.thrash = true
					sarp:change({ Waist = CFrame.Angles(0.3, 0, 0), Neck = CFrame.Angles(0.4, 0, 0), LeftShoulder = CFrame.Angles(2.4, 0, -0.4), RightShoulder = CFrame.Angles(2.4, 0, 0.4) }, 0.3, "out")
					tweenValue(sarp, "feet", S.spot + S.toDoor * 4.2 + S.right * 0.8, 2.2, "out")
				end
				redFlash(0.25, 0.4)
				shake(0.03, 0.8)
				shot(lookAtSarp(sit), 0.3)
			end
			if result then
				topple()
			else
				-- er packt einen am Hals – und reißt dabei selbst den Kerzenständer um
				redFlash(0.6, 0.9)
				play("clawHit", { Volume = 1.5 })
				kick(CFrame.new(0, 0, 0.3) * CFrame.Angles(0.2, 0.1, -0.3))
				shake(0.035, 0.7)
				hold(mine, 0.7)
				topple()
			end
		end
	end)
end

-- Geschafft: Sarp brennt, die Familie bricht zusammen, raus in den Tunnel
function handlers.flee()
	local S = scene
	if not S then
		return
	end
	local mine = S.mine
	stopLoop("heartbeat", 1)
	run(mine, function()
		-- die Fäden sind durch: einer nach dem anderen sackt zusammen
		for i, rig in S.puppets do
			task.delay(0.15 + (i - 1) * 0.28, function()
				if current(mine) then
					rig.stare = nil
					rig.layers = {}
					rig:setPose(PUPPET_COLLAPSED, 0.32, "in")
					task.delay(0.3, function()
						if current(mine) then
							local head = rig:part("Head")
							playAt("puppetCollapse", head and head.Position or S.center, { Volume = 1.6 })
						end
					end)
				end
			end)
		end
		-- kurz zur Familie schauen
		local sit = S.sitEye
		shot(function()
			return CFrame.lookAt(sit, S.center + UP * 2)
		end, 0.6)
		hold(mine, 1.6)
		-- aufstehen, zum Tunnel drehen
		local standUp = S.spot + UP * (S.eye.Y - S.spot.Y)
		local path = { standUp }
		for _, p in S.flee do
			table.insert(path, p + UP * (S.eye.Y - S.spot.Y))
		end
		local getUp = os.clock()
		shot(function(now)
			local a = ease((now - getUp) / 0.7, "inout")
			return CFrame.lookAt(sit:Lerp(standUp, a), (S.center + UP * 2):Lerp(path[2] or standUp, a))
		end, 0)
		hold(mine, 0.7)
		-- rennen (mit Kopfwippen), einmal zurückschauen
		local lengths, total = {}, 0
		for i = 1, #path - 1 do
			lengths[i] = (path[i + 1] - path[i]).Magnitude
			total += lengths[i]
		end
		local runStart = os.clock()
		local function along(s)
			for i = 1, #path - 1 do
				if s <= lengths[i] or i == #path - 1 then
					return path[i]:Lerp(path[i + 1], math.clamp(s / lengths[i], 0, 1)), unit(path[i + 1] - path[i])
				end
				s -= lengths[i]
			end
			return path[#path], Vector3.new(0, 0, -1)
		end
		shot(function(now)
			local t = now - runStart
			local s = math.min(t * 5.2, total)
			local position, direction = along(s)
			local bob = math.abs(math.sin(t * 9)) * 0.22
			local look = position + direction * 6
			-- bei 1.6 s kurz über die Schulter zurück (Sarp brennt)
			local back = math.sin(math.clamp((t - 1.5) / 0.9, 0, 1) * math.pi)
			if back > 0 then
				look = look:Lerp(sarpHeadPosition(S.sarp), back * 0.9)
			end
			return CFrame.lookAt(position + UP * bob, look) * CFrame.Angles(0, 0, math.sin(t * 4.5) * 0.03)
		end, 0.3)
		play("runBreath", { Volume = 1.2 })
		task.delay(1.6, function()
			if current(mine) then
				playAt("sarpBurn", sarpHeadPosition(S.sarp), { Volume = 2, PlaybackSpeed = 0.85 })
			end
		end)
		hold(mine, 3.6)
		setBlack(0, 0.9)
		hold(mine, 1.0)
	end)
end

-- Zweimal verpasst: er erwischt einen
function handlers.killed()
	local S = scene
	if not S then
		return
	end
	local mine = S.mine
	qte = nil
	qteFrame.Visible = false
	stopLoop("heartbeat", 0)
	run(mine, function()
		local sarp = S.sarp
		local from = camera.CFrame.Position
		if sarp then
			S.thrash = false
			tweenValue(sarp, "feet", flat(from) + Vector3.new(0, S.floorY, 0) + S.toDoor * 1.0, 0.25, "in")
			sarp:change({ LeftShoulder = CFrame.Angles(1.6, 0, 0.3), RightShoulder = CFrame.Angles(1.6, 0, -0.3), Neck = CFrame.Angles(-0.3, 0, 0.3) }, 0.25, "in")
		end
		play("jumpscare", { Volume = 2.4 })
		shot(function()
			return CFrame.lookAt(from, sarpHeadPosition(sarp))
		end, 0.1)
		setFov(80, 0.3)
		shake(0.06, 1.2)
		redFlash(0.5, 1)
		hold(mine, 1.1)
		setBlack(0, 0.05)
		stopAllLoops()
	end)
end

-- Der Partner wurde erwischt (man selbst wartet)
function handlers.partnerKilled()
	local S = scene
	if not S then
		return
	end
	qte = nil
	qteFrame.Visible = false
	setBlack(0, 0.6)
	task.delay(0.7, function()
		showCard("", "Er hat deinen Partner erwischt …", true, 1)
	end)
end

------------------------------------------------------------------ Die Flucht durch den Wald
-- Biest auf allen Vieren (ausgerechnet, damit Hände und Füße auf dem Boden sind)
local BEAST_CRAWL = {
	Waist = CFrame.Angles(-0.95, 0, 0),
	LeftHip = CFrame.Angles(0.4, 0, 0),
	RightHip = CFrame.Angles(0.4, 0, 0),
	LeftKnee = CFrame.Angles(-0.15, 0, 0),
	RightKnee = CFrame.Angles(-0.15, 0, 0),
	LeftShoulder = CFrame.Angles(0.6, 0, 0),
	RightShoulder = CFrame.Angles(0.6, 0, 0),
	LeftElbow = CFrame.Angles(0.6, 0, 0),
	RightElbow = CFrame.Angles(0.6, 0, 0),
	Neck = CFrame.Angles(0.8, 0, 0),
	MouthLeft = CFrame.Angles(0, 0.25, 0),
	MouthRight = CFrame.Angles(0, -0.25, 0),
}
-- hochgereckt, Arme weit, Maul ganz offen (Brüllen)
local BEAST_ROAR = {
	Waist = CFrame.Angles(-0.4, 0, 0),
	LeftHip = CFrame.Angles(0.15, 0, 0),
	RightHip = CFrame.Angles(0.15, 0, 0),
	LeftKnee = CFrame.Angles(-0.25, 0, 0),
	RightKnee = CFrame.Angles(-0.25, 0, 0),
	LeftShoulder = CFrame.Angles(1.7, 0, -0.7),
	RightShoulder = CFrame.Angles(1.7, 0, 0.7),
	LeftElbow = CFrame.Angles(0.5, 0, 0),
	RightElbow = CFrame.Angles(0.5, 0, 0),
	Neck = CFrame.Angles(0.55, 0, 0),
	MouthLeft = CFrame.Angles(0, 0.95, 0),
	MouthRight = CFrame.Angles(0, -0.95, 0),
}
-- Sarp beim Rennen (Stufe 2): weit vorgebeugt, Arme greifen nach vorne
local SARP_RUN = {
	Waist = CFrame.Angles(-0.4, 0, 0),
	Neck = CFrame.Angles(0.35, 0, 0),
	LeftShoulder = CFrame.Angles(0.9, 0, -0.2),
	RightShoulder = CFrame.Angles(0.9, 0, 0.2),
	LeftElbow = CFrame.Angles(0.4, 0, 0),
	RightElbow = CFrame.Angles(0.4, 0, 0),
}
-- auf den Knien, vornübergebeugt, Hände am Boden (während der Verwandlung)
local SARP_KNEEL = {
	Waist = CFrame.Angles(-1.0, 0, 0),
	Neck = CFrame.Angles(-0.4, 0, 0.2),
	LeftShoulder = CFrame.Angles(1.3, 0, -0.25),
	RightShoulder = CFrame.Angles(1.3, 0, 0.25),
	LeftElbow = CFrame.Angles(0.2, 0, 0),
	RightElbow = CFrame.Angles(0.2, 0, 0),
	LeftHip = CFrame.Angles(0.15, 0, -0.1),
	RightHip = CFrame.Angles(0.15, 0, 0.1),
	LeftKnee = CFrame.Angles(-1.6, 0, 0),
	RightKnee = CFrame.Angles(-1.6, 0, 0),
}

local chase -- Zustand der Flucht

local function ownRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function handlers.run(message)
	token += 1
	local mine = token
	cleanupScene()
	local folder = newLocalFolder()
	qte = nil
	stopAllLoops()
	stopCutscene()
	setBlack(0, 0)
	local points = message.path or {}
	if #points < 2 then
		return
	end
	local C = { mine = mine, points = points, length = message.length or 0, form = "sarp", gap = 22, s = -3, started = os.clock() }
	chase = C
	-- Mondlicht (sonst sieht man im Wald gar nichts mehr – die Kerze ist weg)
	local moon = Instance.new("Part")
	moon.Name = "K3Moonlight"
	moon.Anchored = true
	moon.CanCollide = false
	moon.CanQuery = false
	moon.CanTouch = false
	moon.Transparency = 1
	moon.Size = Vector3.new(0.5, 0.5, 0.5)
	moon.Parent = folder
	local moonLight = Instance.new("PointLight")
	moonLight.Color = Color3.fromRGB(150, 165, 200)
	moonLight.Range = 34
	moonLight.Brightness = 0.55
	moonLight.Shadows = false
	moonLight.Parent = moon
	C.moon = moon

	-- Sarp (Stufe 2), eigene Kopie
	local sarpModel = localCopy(message.sarp, "SarpChase")
	if sarpModel then
		sarpModel.Parent = folder
		local rig = Rig.new(sarpModel, sarpModel:FindFirstChild("HumanoidRootPart"), false, CFrame.new(0, footOffsetOf(sarpModel), 0))
		rig.grounded = true
		rig.walkState = { walk = 0, phase = 0 }
		table.insert(rig.layers, walkLayer(rig.walkState))
		table.insert(rig.layers, function(now)
			if C.convulse then
				local t = now * 11
				local c = C.convulse
				return {
					Waist = CFrame.Angles(noise(t, 1) * 0.45 * c, noise(t, 2) * 0.5 * c, noise(t, 3) * 0.35 * c),
					Neck = CFrame.Angles(noise(t, 4) * 0.9 * c, noise(t, 5) * 1.1 * c, noise(t, 6) * 0.8 * c),
					LeftShoulder = CFrame.Angles(noise(t, 7) * 1.1 * c, 0, noise(t, 8) * 0.7 * c),
					RightShoulder = CFrame.Angles(noise(t, 9) * 1.1 * c, 0, noise(t, 10) * 0.7 * c),
				}
			end
			return {
				Neck = CFrame.Angles(0, (math.noise(now * 2, 3.3) > 0.4) and noise(now * 25, 1) * 0.2 or 0, 0),
			}
		end)
		rig:setPose(SARP_RUN, 0)
		rig.feet = points[1] - unit(points[2] - points[1]) * 1.5 + Vector3.new(0, 0, 0)
		rig.facing = points[2] - points[1]
		rig.lift = -9 -- noch unten in der Luke
		C.rig = rig
		table.insert(rigs, rig)
	end

	run(mine, function()
		hold(mine, 0.4)
		-- vorwärts schauen, dann die normale Kamera (Ego-Perspektive)
		local root = ownRoot()
		if root then
			camera.CFrame = CFrame.lookAt(root.Position + UP * 1.5, root.Position + UP * 1.5 + unit(flat(points[2] - points[1])))
		end
		camera.CameraType = Enum.CameraType.Custom
		setBlack(1, 1.2)
		loop("chaseMusic", 0.6)
		loop("runBreath", 0.8)
		hold(mine, 1.0)
		showBigHint("LAUF!", 2.4)
		-- er klettert aus der Luke
		local rig = C.rig
		if rig then
			playAt("sarpRoar", rig.feet + UP * 2, { Volume = 2.4 })
			tweenValue(rig, "lift", 0, 0.8, "out")
			rig:change({ LeftShoulder = CFrame.Angles(2.4, 0, -0.3), RightShoulder = CFrame.Angles(2.4, 0, 0.3) }, 0.3, "out")
			hold(mine, 0.8)
			rig:change(SARP_RUN, 0.4, "inout")
		end
		C.chasing = true
	end)
end

-- Verwandlung in Stufe 3: man bleibt stehen, die Kamera dreht sich um
function handlers.transform()
	local C = chase
	if not C then
		return
	end
	local mine = C.mine
	run(mine, function()
		local rig = C.rig
		C.chasing = false
		startCutscene()
		setBars(false, 0) -- (keine Kino-Balken: es soll sich anfühlen wie man selbst)
		local root = ownRoot()
		local function eye()
			local character = player.Character
			local head = character and character:FindFirstChild("Head")
			return head and head.Position + UP * 0.2 or (root and root.Position + UP * 1.5) or camera.CFrame.Position
		end
		local function lookBack()
			return CFrame.lookAt(eye(), sarpHeadPosition(rig) - UP * 0.5)
		end
		shot(lookBack, 0.55, "out")
		play("ritualSting", { Volume = 1 })
		if not rig then
			hold(mine, Data.TRANSFORM_TIME)
			stopCutscene()
			return
		end
		------------------------------------------------ er bleibt stehen, krampft
		rig.walkState.walk = 0
		rig:setPose({ Waist = CFrame.Angles(0.15, 0, 0), Neck = CFrame.Angles(0.3, 0, 0) }, 0.3, "out")
		hold(mine, 0.5)
		C.convulse = 0
		tweenValue(C, "convulse", 1, 0.4, "in")
		for i = 0, 4 do
			task.delay(i * 0.27, function()
				if current(mine) then
					playAt("transformCrack", sarpHeadPosition(rig), { Volume = 1.8, PlaybackSpeed = 0.9 + math.random() * 0.3 })
				end
			end)
		end
		local slime
		local torso = rig:part("UpperTorso")
		if torso then
			slime = Instance.new("ParticleEmitter")
			slime.Color = ColorSequence.new(Color3.fromRGB(8, 8, 8))
			slime.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.4) })
			slime.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
			slime.Lifetime = NumberRange.new(0.8, 1.6)
			slime.Speed = NumberRange.new(2, 6)
			slime.SpreadAngle = Vector2.new(180, 180)
			slime.Rate = 30
			slime.LightEmission = 0
			slime.Parent = torso
		end
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(230, 30, 20)
		glow.Range = 16
		glow.Brightness = 0.5
		glow.Parent = torso or rig.root
		tweenValue(glow, "Brightness", 2.5, 2.5, "in")
		shake(0.008, 1.4)
		hold(mine, 1.3)
		------------------------------------------------ bricht zusammen, auf die Knie
		rig:setPose(SARP_KNEEL, 0.35, "in")
		tweenValue(C, "convulse", 0.35, 0.3)
		play("bodyFall", { Volume = 1.3 })
		hold(mine, 0.5)
		------------------------------------------------ er wächst (ruckartig), wird dunkel
		local colors = {}
		for _, part in rig.model:GetDescendants() do
			if part:IsA("BasePart") then
				colors[part] = part.Color
			end
		end
		local dark = Color3.fromRGB(26, 22, 24)
		for step, factor in { 1.14, 1.3, 1.48, 1.66 } do
			if not current(mine) then
				return
			end
			rig:rescale(factor)
			for part, color in colors do
				if part.Parent then
					part.Color = color:Lerp(dark, step / 4 * 0.85)
				end
			end
			playAt("transformCrack", sarpHeadPosition(rig), { Volume = 2.2, PlaybackSpeed = 0.7 + step * 0.06 })
			kick(CFrame.Angles(0.03, 0, (math.random() - 0.5) * 0.06))
			shake(0.015, 0.35)
			if slime then
				slime.Rate = 30 + step * 25
			end
			hold(mine, 0.32)
		end
		------------------------------------------------ Rauch, Blitz – das Biest
		local smokeHolder = Instance.new("Part")
		smokeHolder.Anchored = true
		smokeHolder.CanCollide = false
		smokeHolder.CanQuery = false
		smokeHolder.CanTouch = false
		smokeHolder.Transparency = 1
		smokeHolder.Size = Vector3.new(1, 1, 1)
		smokeHolder.CFrame = CFrame.new(rig.feet + UP * 4)
		smokeHolder.Parent = localFolder
		local smoke = Instance.new("ParticleEmitter")
		smoke.Color = ColorSequence.new(Color3.fromRGB(20, 16, 16))
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 11) })
		smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		smoke.Lifetime = NumberRange.new(1.2, 2.2)
		smoke.Speed = NumberRange.new(3, 9)
		smoke.SpreadAngle = Vector2.new(180, 180)
		smoke.Rate = 0
		smoke.Parent = smokeHolder
		smoke:Emit(70)
		local burst = Instance.new("PointLight")
		burst.Color = Color3.fromRGB(255, 40, 20)
		burst.Range = 30
		burst.Brightness = 8
		burst.Parent = smokeHolder
		tweenValue(burst, "Brightness", 0, 1.2, "out")
		redFlash(0.35, 0.6)
		shake(0.04, 0.6)
		play("transformCrack", { Volume = 2.5, PlaybackSpeed = 0.6 })
		-- Sarp weg, das Biest erscheint (geduckt, Kopf unten) im Rauch
		local feet, facing = rig.feet, rig.facing
		for i = #rigs, 1, -1 do
			if rigs[i] == rig then
				table.remove(rigs, i)
			end
		end
		rig.model:Destroy()
		local model = Beast.build(localFolder)
		local beastRoot = model.PrimaryPart
		local beast = Rig.new(model, beastRoot, false, CFrame.new(0, 0.5, 0))
		beast.grounded = true
		beast.feet = feet
		beast.facing = facing
		beast.walkState = { phase = 0, amount = 0 }
		local crouch = table.clone(BEAST_CRAWL)
		crouch.Neck = CFrame.Angles(-0.2, 0, 0)
		beast:setPose(crouch, 0)
		-- Galopp auf allen Vieren
		table.insert(beast.layers, function(now)
			local amount = beast.walkState.amount or 0
			local p = beast.walkState.phase or 0
			local twitch = math.noise(now * 2.5, 8.8) > 0.45 and noise(now * 30, 3) * 0.15 or 0
			if amount < 0.01 then
				return { Neck = CFrame.Angles(0, twitch, twitch) }
			end
			local front, back = math.sin(p), math.sin(p + math.pi * 0.85)
			return {
				LeftShoulder = CFrame.Angles(front * 0.55 * amount, 0, 0),
				RightShoulder = CFrame.Angles(math.sin(p + 0.35) * 0.55 * amount, 0, 0),
				LeftElbow = CFrame.Angles(math.max(0, -front) * 0.5 * amount, 0, 0),
				RightElbow = CFrame.Angles(math.max(0, -math.sin(p + 0.35)) * 0.5 * amount, 0, 0),
				LeftHip = CFrame.Angles(back * 0.5 * amount, 0, 0),
				RightHip = CFrame.Angles(math.sin(p + math.pi * 0.85 + 0.3) * 0.5 * amount, 0, 0),
				LeftKnee = CFrame.Angles(-math.max(0, math.cos(p + math.pi * 0.85)) * 0.6 * amount, 0, 0),
				RightKnee = CFrame.Angles(-math.max(0, math.cos(p + math.pi * 0.85 + 0.3)) * 0.6 * amount, 0, 0),
				Waist = CFrame.Angles(math.sin(p * 2) * 0.07 * amount, 0, 0),
				Neck = CFrame.Angles(-math.sin(p * 2) * 0.06 * amount, twitch, twitch * 0.5),
			}
		end)
		beast:update(os.clock())
		-- einblenden
		local parts = {}
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 1
				table.insert(parts, part)
			end
		end
		local fadeStart = os.clock()
		local fader
		fader = RunService.RenderStepped:Connect(function()
			local a = math.clamp((os.clock() - fadeStart) / 0.45, 0, 1)
			for _, part in parts do
				if part.Parent then
					part.LocalTransparencyModifier = 1 - a
				end
			end
			if a >= 1 then
				fader:Disconnect()
			end
		end)
		C.rig = beast
		C.form = "beast"
		C.convulse = nil
		table.insert(rigs, beast)
		local breath = makeSound("beastBreath", beastRoot, { Looped = true, Volume = 1, RollOffMaxDistance = 90 })
		if breath then
			breath:Play()
		end
		shot(function()
			return CFrame.lookAt(eye(), sarpHeadPosition(beast))
		end, 0.4)
		hold(mine, 0.6)
		------------------------------------------------ es richtet sich auf und brüllt
		beast:setPose(BEAST_ROAR, 0.7, "out")
		hold(mine, 0.4)
		play("roar", { Volume = 2.6 })
		shake(0.045, 1.4)
		setFov(58, 0.25)
		hold(mine, 0.3)
		setFov(70, 1.2)
		hold(mine, 1.0)
		------------------------------------------------ auf alle Viere – und los
		beast:setPose(BEAST_CRAWL, 0.35, "in")
		play("beastStep", { Volume = 1.6 })
		hold(mine, 0.25)
		local forward = select(2, Data.pointAt(C.points, (root and Data.progress(C.points, root.Position)) or 0))
		local turnStart = os.clock()
		shot(function(now)
			local a = ease((now - turnStart) / 0.4, "inout")
			local e = eye()
			local back = sarpHeadPosition(beast)
			local ahead = e + unit(flat(forward)) * 10
			return CFrame.lookAt(e, back:Lerp(ahead, a))
		end, 0)
		hold(mine, 0.42)
		local e = eye()
		camera.CFrame = CFrame.lookAt(e, e + unit(flat(forward)) * 10)
		stopCutscene()
		showBigHint("LAUF!", 2)
		loop("chaseMusic", 0.9)
		C.gap = math.max(10, (root and Data.progress(C.points, root.Position) or 0) - C.s)
		C.chasing = true
	end)
end

-- Ende: es springt – schwarz
handlers["end"] = function()
	local C = chase
	local mine = token
	if C then
		C.lunge = true
	end
	run(mine, function()
		play("roar", { Volume = 2.8 })
		redFlash(0.6, 0.3)
		hold(mine, 0.32)
		setBlack(0, 0)
		stopAllLoops()
		hold(mine, 0.2)
		chase = nil
		for i = #rigs, 1, -1 do
			table.remove(rigs, i)
		end
		if localFolder then
			localFolder:Destroy()
			localFolder = nil
		end
		hold(mine, 3)
		showCard("", "Fortsetzung folgt …", true, 2)
	end)
end

-- Jedes Bild: die Verfolgung im Wald
local nextStep, nextBeat = 0, 0
local function updateChase(now, deltaTime)
	local C = chase
	if not C or not C.rig then
		return
	end
	local root = ownRoot()
	if C.moon and root then
		C.moon.CFrame = CFrame.new(root.Position + UP * 9)
	end
	local rig = C.rig
	if not (C.chasing or C.lunge) or not root then
		return
	end
	local playerS = Data.progress(C.points, root.Position)
	-- er bleibt knapp hinter einem (kommt näher, wenn man langsamer wird), fängt einen aber nie
	local wanted = C.form == "beast" and (8.5 + math.sin(now * 0.8) * 2) or (11 + math.sin(now * 0.6) * 2.5)
	if C.form == "beast" then
		C.gap += (wanted - C.gap) * math.min(deltaTime * 0.6, 1)
	else
		C.gap = wanted
	end
	local target = playerS - C.gap
	if C.lunge then
		target = playerS - 1.2
	end
	local maxSpeed = C.lunge and 60 or (C.form == "beast" and 30 or 22)
	local before = C.s
	C.s = math.min(C.s + math.clamp(target - C.s, -2 * deltaTime, maxSpeed * deltaTime), playerS - (C.lunge and 1 or 4.5))
	local moved = math.max(C.s - before, 0)
	local position, direction = Data.pointAt(C.points, math.max(C.s, 0))
	if C.s < 0 then
		position += direction * C.s
	end
	rig.feet = position
	rig.facing = direction
	local speed = moved / math.max(deltaTime, 1e-3)
	if C.form == "beast" then
		rig.walkState.amount = math.clamp(speed / 14, 0, 1)
		rig.walkState.phase = (rig.walkState.phase or 0) + moved / 11 * math.pi * 2
	else
		rig.walkState.walk = math.clamp(speed / 10, 0, 1)
		rig.walkState.phase = (rig.walkState.phase or 0) + moved / 6.5 * math.pi * 2
	end
	-- Schritte und Herzschlag
	local distance = playerS - C.s
	if speed > 3 and now >= nextStep then
		nextStep = now + (C.form == "beast" and 0.28 or 0.36)
		play(C.form == "beast" and "beastStep" or "sarpStep", { Volume = C.form == "beast" and 2 or 1.6 }, rig.root)
	end
	if now >= nextBeat then
		local closeness = 1 - math.clamp((distance - 4) / 20, 0, 1)
		nextBeat = now + 0.95 - closeness * 0.55
		play("heartbeat", { Volume = 0.5 + closeness * 1.4 })
	end
end

------------------------------------------------------------------ Start
function Kapitel3.run()
	buildGui()
	remotes = ReplicatedStorage:WaitForChild("Kapitel2")
	local event = remotes:WaitForChild("SceneEvent")
	event.OnClientEvent:Connect(function(message)
		if message.type == "k3" then
			local handler = handlers[message.step]
			if handler then
				task.spawn(function()
					local ok, problem = pcall(handler, message)
					if not ok and problem ~= CANCELLED then
						-- lieber den Raum zeigen als ein schwarzes Bild
						warn("Kapitel 3 (Client): Fehler bei '" .. tostring(message.step) .. "': " .. tostring(problem))
						setBlack(1, 0.5)
						stopCutscene()
					end
				end)
			end
		elseif message.type == "gameOver" then
			-- Game Over (Scene.lua) liegt darunter: das eigene Schwarz und die Sequenz weg
			token += 1
			qte = nil
			qteFrame.Visible = false
			setBlack(1, 0)
			showCard(nil, nil, false, 0.1)
			stopAllLoops()
			stopCutscene(true)
		end
	end)

	-- "Nochmal versuchen" gedrückt: gleich schwarz, bis die Sequenz von vorne beginnt
	player:GetAttributeChangedSignal("GameOver"):Connect(function()
		if player:GetAttribute("GameOver") == nil and remotes:GetAttribute("Phase") == "kapitel3" and not chase then
			setBlack(0, 0)
		end
	end)

	-- Tasten für die Quick-Time-Events (auch wenn Roblox die Taste schon benutzt, z. B.
	-- Leertaste = Springen; nur nicht beim Schreiben im Chat)
	UserInputService.InputBegan:Connect(function(input)
		if not qte or UserInputService:GetFocusedTextBox() then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.A or key == Enum.KeyCode.Left or key == Enum.KeyCode.DPadLeft then
			qteInput("dodge", -1)
		elseif key == Enum.KeyCode.D or key == Enum.KeyCode.Right or key == Enum.KeyCode.DPadRight then
			qteInput("dodge", 1)
		elseif key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonX then
			qteInput("struggle")
		elseif key == Enum.KeyCode.Space or key == Enum.KeyCode.ButtonA then
			qteInput("timing")
			if qte and qte.kind == "struggle" then
				qteInput("struggle") -- (Leertaste geht beim Losreißen auch)
			end
		end
	end)
	dodgeButton.Activated:Connect(function()
		if qte and qte.kind == "dodge" then
			qteInput("dodge", qte.dir)
		end
	end)
	struggleButton.Activated:Connect(function()
		qteInput("struggle")
	end)
	timingButton.Activated:Connect(function()
		qteInput("timing")
	end)

	-- jedes Bild: Figuren, Kamera, Verfolgung (nach der normalen Kamera)
	local lastProblem
	RunService:BindToRenderStep("Kapitel3", Enum.RenderPriority.Camera.Value + 10, function(deltaTime)
		local now = os.clock()
		local ok, problem = pcall(function()
			updateTweens(now)
			updateChase(now, deltaTime)
			for _, rig in rigs do
				if rig.root and rig.root.Parent then
					rig:update(now)
				end
			end
			updateCamera(now)
		end)
		if not ok and problem ~= lastProblem then
			lastProblem = problem
			warn("Kapitel 3 (Client, Bild): " .. tostring(problem))
		end
	end)
end

return Kapitel3
