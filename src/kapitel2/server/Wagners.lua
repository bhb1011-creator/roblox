-- Kapitel 2: die Gastfamilie Wagner. Bisher Mrs. Wagner und Mr. Wagner, die Kinder
-- kommen später. Beide sind verankert und werden vom Server gestellt und bewegt
-- (Kapitel2.lua); die Clients drehen nur ihre Köpfe (Attribut "Look").
--
-- Beide sehen erst einmal ganz normal und freundlich aus (im selben Roblox-Stil wie die
-- Kinder) – dass sie von Sarp besessen sind, merkt man nur an dem, was sie sagen und tun.
-- Mrs. Wagner (Margaret): um die 45, dunkelblaues Kleid, helle Strickjacke, braune Haare
--   locker hochgesteckt, freundliches Lächeln. Hält eine Kerze.
-- Mr. Wagner (Richard): groß, hellblaues Hemd mit hochgekrempelten Ärmeln, Hosenträger,
--   kurzer gepflegter Bart, Armbanduhr.
local Players = game:GetService("Players")

local Wagners = {}

local function weldTo(part, target)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = target
	weld.Part1 = part
	weld.Parent = part
end

-- Zusätzliches Teil, an einem Körperteil festgemacht
local function attach(model, bodyPart, name, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = bodyPart.CFrame * offset
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	weldTo(part, bodyPart)
	part.Parent = model
	return part
end

-- Langes Kleid / Nachthemd bis zum Boden, in drei Stufen nach unten weiter (A-Linie).
-- Die Beine sind ganz verdeckt und schwingen beim Gehen nicht (StepScale 0): die Figur
-- gleitet. So kann nichts mehr durch den Stoff stechen. Die unteren Stufen haben das
-- Attribut "DressLower": beim Sitzen/Knien werden sie ausgeblendet.
local function longDress(model, hips, name, color, hemColor, topExtra, bottomExtra)
	local lowest = math.huge
	for _, footName in { "LeftFoot", "RightFoot" } do
		local foot = model:FindFirstChild(footName)
		if foot then
			lowest = math.min(lowest, foot.Position.Y - foot.Size.Y / 2)
		end
	end
	if lowest == math.huge then
		lowest = hips.Position.Y - 3
	end
	local top = hips.Size.Y * 0.3 -- etwas unter der Taille
	local bottom = lowest - hips.Position.Y + 0.06 -- knapp über dem Boden
	local length = top - bottom
	local tiers = 3
	for i = 0, tiers - 1 do
		local extra = topExtra + (bottomExtra - topExtra) * (i + 0.5) / tiers
		local height = length / tiers + 0.02
		local y = top - length * (i + 0.5) / tiers
		local part = attach(model, hips, name, Vector3.new(hips.Size.X + extra, height, hips.Size.Z + extra), CFrame.new(0, y, 0), color, Enum.Material.Fabric)
		if i > 0 then
			part:SetAttribute("DressLower", true)
		end
	end
	local hem = attach(model, hips, name .. "Hem", Vector3.new(hips.Size.X + bottomExtra + 0.06, 0.12, hips.Size.Z + bottomExtra + 0.06), CFrame.new(0, bottom + 0.06, 0), hemColor, Enum.Material.Fabric)
	hem:SetAttribute("DressLower", true)
	model:SetAttribute("StepScale", 0) -- Beine bewegen sich nicht, die Figur gleitet
end

-- unteres Kleid ein-/ausblenden (Sitzen, Knien)
function Wagners.showLowerDress(model, visible)
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part:GetAttribute("DressLower") then
			part.Transparency = visible and 0 or 1
		end
	end
end

-- Gelenke, die sich bewegen (Kopf drehen, Arm anwinkeln, Beine beim Gehen). In
-- manchen Roblox-Versionen sind die Gelenke dieser Figuren schreibgeschützt
-- ("C0 is read only"). Deshalb werden sie durch eigene, gleichwertige ersetzt.
local MOVING_JOINTS = {
	{ "Head", "Neck" },
	{ "RightUpperArm", "RightShoulder" },
	{ "RightLowerArm", "RightElbow" },
	{ "LeftUpperLeg", "LeftHip" },
	{ "RightUpperLeg", "RightHip" },
	{ "LeftLowerLeg", "LeftKnee" },
	{ "RightLowerLeg", "RightKnee" },
	-- für Kapitel 3 (Puppen im Ritualraum, Sarps Angriffe und Verwandlung)
	{ "LeftUpperArm", "LeftShoulder" },
	{ "LeftLowerArm", "LeftElbow" },
	{ "UpperTorso", "Waist" },
	{ "LowerTorso", "Root" },
	{ "LeftFoot", "LeftAnkle" },
	{ "RightFoot", "RightAnkle" },
	{ "LeftHand", "LeftWrist" },
	{ "RightHand", "RightWrist" },
}

local function replaceJoint(model, partName, jointName)
	local part = model:FindFirstChild(partName)
	local old = part and part:FindFirstChild(jointName)
	if not old then
		return
	end
	local part0, part1, c0, c1
	local ok = pcall(function()
		part0, part1, c0, c1 = old.Part0, old.Part1, old.C0, old.C1
	end)
	if not ok or not part0 then
		-- neuere Figuren: Gelenk mit zwei Attachments statt C0/C1
		-- (bei den KI-Figuren hängen die Attachments an Knochen, daher über die Weltlage)
		ok = pcall(function()
			local a0, a1 = old.Attachment0, old.Attachment1
			part0 = a0:FindFirstAncestorWhichIsA("BasePart")
			part1 = a1:FindFirstAncestorWhichIsA("BasePart")
			c0 = part0.CFrame:ToObjectSpace(a0.WorldCFrame)
			c1 = part1.CFrame:ToObjectSpace(a1.WorldCFrame)
		end)
	end
	-- KI-Figuren (AnimationConstraint an Knochen): die Gelenkpunkte umbenennen. Sonst baut
	-- der Humanoid Hals/Schultern neu und löst unser Gelenk wieder (Part0 = nil), sobald
	-- die Figur in die Welt kommt.
	if old:IsA("AnimationConstraint") then
		for _, point in { old.Attachment0, old.Attachment1 } do
			if point then
				point.Name ..= "Fixed"
			end
		end
	end
	if not ok or not part0 or not part1 then
		warn("Gelenk konnte nicht ersetzt werden:", partName, jointName)
		return
	end
	local joint = Instance.new("Motor6D")
	joint.Name = jointName
	joint.Part0 = part0
	joint.Part1 = part1
	joint.C0 = c0
	joint.C1 = c1
	old:Destroy()
	joint.Parent = part
end

-- Echte Roblox-Frisuren aus dem Katalog (von Roblox selbst, für NPCs frei nutzbar).
-- Lädt eine nicht, bekommt die Figur die alten Haare aus Bausteinen.
local HAIR = {
	MrsWagner = { 81688919 }, -- ungemachter, kastanienbrauner Dutt
	MrWagner = { 13477818 }, -- kurze, normale Haare
	Lucy = { 1772372988 }, -- langes, glattes schwarzes Haar ohne Pony (Augen frei)
	Tommy = { 147193065 }, -- zerzauste braune Haare
}

local function createModel(description)
	return pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
end

local function newBody(name, colors, scale)
	local description = Instance.new("HumanoidDescription")
	pcall(function()
		description.Face = 0 -- kein Roblox-Gesicht
		description.Head = 0 -- klassischer runder Kopf
	end)
	description.HeadColor = colors.skin
	description.TorsoColor = colors.torso
	description.LeftArmColor = colors.arms
	description.RightArmColor = colors.arms
	description.LeftLegColor = colors.legs
	description.RightLegColor = colors.legs
	for property, value in scale do
		pcall(function()
			description[property] = value
		end)
	end
	local hair = HAIR[name]
	if hair then
		local ids = {}
		for _, id in hair do
			table.insert(ids, tostring(id))
		end
		description.HairAccessory = table.concat(ids, ",")
	end
	local ok, model = createModel(description)
	if not ok and hair then
		warn(name .. ": echte Haare konnten nicht geladen werden, nehme Bausteine.", model)
		description.HairAccessory = ""
		ok, model = createModel(description)
	end
	if not ok then
		warn(name .. " konnte nicht erstellt werden:", model)
		return nil
	end
	model.Name = name
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	pcall(function()
		humanoid.EvaluateStateMachine = false
	end)
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	-- Das Roblox-Gesicht komplett entfernen (Aufkleber, Gesichtssteuerung und das
	-- Gesicht, das bei neueren Köpfen direkt in der Kopf-Textur steckt). Sonst sieht man
	-- es unter dem eigenen Gesicht durchscheinen.
	local head = model.Head
	for _, child in head:GetDescendants() do
		if child:IsA("Decal") or child:IsA("FaceControls") or child.Name == "face" then
			child:Destroy()
		end
	end
	pcall(function()
		head.TextureID = ""
	end)
	pcall(function()
		head.Color = colors.skin
	end)
	for _, partName in { "LeftHand", "RightHand" } do
		local hand = model:FindFirstChild(partName)
		if hand then
			hand.Color = colors.hands or colors.skin
		end
	end
	for _, partName in { "LeftFoot", "RightFoot" } do
		local foot = model:FindFirstChild(partName)
		if foot then
			foot.Color = colors.shoes
		end
	end
	-- Haare aus dem Katalog: nicht anklickbar, ohne Gewicht, kein Kollidieren
	local hasHair = false
	for _, accessory in model:GetChildren() do
		if accessory:IsA("Accessory") then
			hasHair = true
			for _, part in accessory:GetDescendants() do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
					part.Massless = true
				end
			end
		end
	end
	model:SetAttribute("RealHair", hasHair)
	model.HumanoidRootPart.Anchored = true
	for _, info in MOVING_JOINTS do
		replaceJoint(model, info[1], info[2])
	end
	return model
end

-- Augen, Brauen, Mund. `style`: "smile" (Mrs. Wagner) oder "tired" (Mr. Wagner)

-- für andere Figuren (z. B. Sarps zweite Gestalt in SarpStage2.lua)
Wagners.newBody = newBody
Wagners.attach = attach

local function face(model, head, style, colors)
	local size = head.Size
	local front = -size.Z / 2 - 0.005
	local s = size.Y / 1.2 -- Gesichter sind für einen 1.2 hohen Kopf gemacht
	for _, side in { -1, 1 } do
		local x = side * 0.2 * s
		if style == "friendly" or style == "kind" then
			-- ganz normale, freundliche Augen: Iris mit Pupille, kleiner Lichtpunkt
			local iris = colors.eyes or Color3.fromRGB(86, 64, 44)
			attach(model, head, "EyeWhite", Vector3.new(0.2 * s, 0.13 * s, 0.02), CFrame.new(x, 0.12 * s, front), Color3.fromRGB(240, 236, 230))
			attach(model, head, "Iris", Vector3.new(0.1 * s, 0.11 * s, 0.02), CFrame.new(x, 0.115 * s, front - 0.008), iris)
			attach(model, head, "Pupil", Vector3.new(0.05 * s, 0.05 * s, 0.02), CFrame.new(x, 0.115 * s, front - 0.014), Color3.fromRGB(20, 16, 14))
			attach(model, head, "EyeShine", Vector3.new(0.022 * s, 0.022 * s, 0.02), CFrame.new(x + 0.02 * s, 0.135 * s, front - 0.018), Color3.fromRGB(250, 250, 250))
			attach(model, head, "Brow", Vector3.new(0.22 * s, (style == "kind" and 0.05 or 0.03) * s, 0.02), CFrame.new(x, 0.27 * s, front) * CFrame.Angles(0, 0, math.rad(side * 5)), colors.hair)
		elseif style == "smile" then
			attach(model, head, "EyeWhite", Vector3.new(0.21 * s, 0.14 * s, 0.02), CFrame.new(x, 0.12 * s, front), Color3.fromRGB(236, 232, 224))
			-- winzige, starre Pupillen
			attach(model, head, "Pupil", Vector3.new(0.055 * s, 0.055 * s, 0.02), CFrame.new(x, 0.12 * s, front - 0.012), Color3.fromRGB(18, 14, 12))
			attach(model, head, "EyeRing", Vector3.new(0.24 * s, 0.06 * s, 0.02), CFrame.new(x, 0.01 * s, front), Color3.fromRGB(128, 104, 112))
			attach(model, head, "Brow", Vector3.new(0.24 * s, 0.035 * s, 0.02), CFrame.new(x, 0.29 * s, front) * CFrame.Angles(0, 0, math.rad(side * 8)), colors.hair)
		elseif style == "child" then
			-- große, fast ganz schwarze Augen, die nichts anschauen
			attach(model, head, "EyeWhite", Vector3.new(0.22 * s, 0.18 * s, 0.02), CFrame.new(x, 0.1 * s, front), Color3.fromRGB(226, 222, 214))
			attach(model, head, "Pupil", Vector3.new(0.16 * s, 0.15 * s, 0.02), CFrame.new(x, 0.09 * s, front - 0.012), Color3.fromRGB(12, 10, 10))
			attach(model, head, "EyeRing", Vector3.new(0.22 * s, 0.05 * s, 0.02), CFrame.new(x, -0.02 * s, front), Color3.fromRGB(120, 100, 110))
			attach(model, head, "Brow", Vector3.new(0.2 * s, 0.03 * s, 0.02), CFrame.new(x, 0.27 * s, front), colors.hair)
		else
			-- müde, halb geschlossene Augen mit schweren Lidern und Tränensäcken
			attach(model, head, "EyeWhite", Vector3.new(0.19 * s, 0.09 * s, 0.02), CFrame.new(x, 0.11 * s, front), Color3.fromRGB(214, 206, 192))
			attach(model, head, "Pupil", Vector3.new(0.07 * s, 0.07 * s, 0.02), CFrame.new(x, 0.1 * s, front - 0.012), Color3.fromRGB(24, 20, 18))
			attach(model, head, "Eyelid", Vector3.new(0.21 * s, 0.05 * s, 0.02), CFrame.new(x, 0.16 * s, front - 0.014), Color3.fromRGB(150, 116, 100))
			attach(model, head, "EyeBag", Vector3.new(0.22 * s, 0.05 * s, 0.02), CFrame.new(x, 0.03 * s, front), Color3.fromRGB(140, 108, 98))
			-- dicke Brauen, zusammengezogen
			attach(model, head, "Brow", Vector3.new(0.27 * s, 0.07 * s, 0.02), CFrame.new(x, 0.27 * s, front) * CFrame.Angles(0, 0, math.rad(-side * 12)), colors.hair)
		end
	end
	if style == "friendly" then
		-- freundliches, leichtes Lächeln
		-- (Mundwinkel in derselben roten Farbe und dicht am Mund, sonst wirken sie wie Zähne)
		local lips = Color3.fromRGB(170, 46, 52)
		attach(model, head, "Mouth", Vector3.new(0.22 * s, 0.045 * s, 0.02), CFrame.new(0, -0.26 * s, front), lips)
		for _, side in { -1, 1 } do
			attach(model, head, "MouthCorner", Vector3.new(0.06 * s, 0.035 * s, 0.02), CFrame.new(side * 0.125 * s, -0.25 * s, front - 0.001) * CFrame.Angles(0, 0, math.rad(side * 18)), lips)
		end
		-- etwas Rouge auf den Wangen
		for _, side in { -1, 1 } do
			attach(model, head, "Cheek", Vector3.new(0.14 * s, 0.07 * s, 0.02), CFrame.new(side * 0.29 * s, -0.08 * s, front + 0.004), Color3.fromRGB(214, 160, 150))
		end
	elseif style == "kind" then
		-- kurz gestutzter, gepflegter Bart, darin ein ruhiger Mund
		local function round(name, partSize, offset)
			local part = attach(model, head, name, partSize, offset, colors.beard, Enum.Material.Fabric)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = part
			return part
		end
		round("Beard", Vector3.new(size.X * 0.8, size.Y * 0.36, size.Z * 0.72), CFrame.new(0, -size.Y * 0.32, -size.Z * 0.1))
		round("Mustache", Vector3.new(0.42 * s, 0.09 * s, 0.1 * s), CFrame.new(0, -0.16 * s, front + 0.04))
		attach(model, head, "Mouth", Vector3.new(0.2 * s, 0.035 * s, 0.02), CFrame.new(0, -0.25 * s, front - 0.02), Color3.fromRGB(120, 70, 64))
	elseif style == "child" then
		-- kleiner, gerader Mund
		attach(model, head, "Mouth", Vector3.new(0.16 * s, 0.035 * s, 0.02), CFrame.new(0, -0.25 * s, front), Color3.fromRGB(120, 70, 70))
	elseif style == "smile" then
		-- breites, starres Lächeln
		local lips = Color3.fromRGB(150, 40, 46)
		attach(model, head, "Mouth", Vector3.new(0.4 * s, 0.04 * s, 0.02), CFrame.new(0, -0.26 * s, front), lips)
		for _, side in { -1, 1 } do
			attach(model, head, "MouthCorner", Vector3.new(0.1 * s, 0.035 * s, 0.02), CFrame.new(side * 0.225 * s, -0.24 * s, front - 0.001) * CFrame.Angles(0, 0, math.rad(side * 22)), lips)
		end
	else
		-- runder, ungepflegter Bart um Kinn und Wangen (Ellipsoide statt Platten, damit er
		-- dem runden Kopf folgt), darüber ein Schnurrbart und ein schmaler, gerader Mund
		local function round(name, partSize, offset)
			local part = attach(model, head, name, partSize, offset, colors.beard, Enum.Material.Fabric)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = part
			return part
		end
		round("Beard", Vector3.new(size.X * 0.86, size.Y * 0.46, size.Z * 0.78), CFrame.new(0, -size.Y * 0.3, -size.Z * 0.1))
		round("BeardChin", Vector3.new(size.X * 0.5, size.Y * 0.3, size.Z * 0.42), CFrame.new(0, -size.Y * 0.44, -size.Z * 0.28))
		round("Mustache", Vector3.new(0.5 * s, 0.12 * s, 0.14 * s), CFrame.new(0, -0.15 * s, front + 0.04))
		attach(model, head, "Mouth", Vector3.new(0.24 * s, 0.035 * s, 0.02), CFrame.new(0, -0.25 * s, front - 0.02), Color3.fromRGB(70, 42, 38))
	end
end

-- Rechter Arm angewinkelt, in der Hand eine brennende Kerze (Mrs. Wagner). Die Kerze wird
-- in der Grundhaltung so angebracht, dass sie nach dem Anwinkeln genau senkrecht steht.
local function holdCandle(model)
	local hand = model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm")
	if not hand then
		return
	end
	local upperArm = model:FindFirstChild("RightUpperArm")
	local lowerArm = model:FindFirstChild("RightLowerArm")
	local up, bend = math.rad(35), math.rad(65)
	local shoulder = upperArm and upperArm:FindFirstChild("RightShoulder")
	local elbow = lowerArm and lowerArm:FindFirstChild("RightElbow")
	local canBend = shoulder ~= nil and elbow ~= nil and pcall(function()
		shoulder.C0 = shoulder.C0
		elbow.C0 = elbow.C0
	end)
	if not canBend then
		up, bend = 0, 0 -- Arm bleibt hängen, die Kerze trotzdem senkrecht
	end
	-- KI-Figuren: der Arm wurde vorher nach unten gedreht (relaxArms) – das hier ausgleichen
	local upright = CFrame.Angles(-(up + bend), 0, 0) * (model:GetAttribute("RightArmRelax") or CFrame.new())
	local lift = hand.Size.Y / 2
	-- detaillierte Kerze im Messinghalter (ReplicatedStorage.Shared.CandleModel), an der Hand fest
	local CandleModel = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CandleModel"))
	local flame = CandleModel.build(model, hand.CFrame * upright * CFrame.new(0, lift, -0.05), 1.25, { weldTo = hand }).flame
	local light = Instance.new("PointLight")
	light.Name = "CandleLight"
	light.Range = 9
	light.Brightness = 1.3
	light.Color = Color3.fromRGB(255, 160, 85)
	light.Shadows = true
	light.Parent = flame
	if canBend then
		shoulder.C0 *= CFrame.Angles(up, 0, 0)
		elbow.C0 *= CFrame.Angles(bend, 0, 0)
	end
end

function Wagners.buildMrs(parent)
	local real = Wagners.fromStudio("MrsWagner", parent) -- echte Figur aus assets/figuren
	if real then
		return real
	end
	-- ganz normale, freundliche Frau – dass sie besessen ist, sieht man ihr nicht an
	local colors = {
		skin = Color3.fromRGB(234, 196, 168),
		torso = Color3.fromRGB(58, 78, 112), -- dunkelblaues Kleid
		arms = Color3.fromRGB(196, 176, 146), -- helle, beige Strickjacke
		legs = Color3.fromRGB(150, 120, 100),
		shoes = Color3.fromRGB(70, 48, 36),
		hair = Color3.fromRGB(120, 82, 52),
		eyes = Color3.fromRGB(70, 100, 80),
	}
	local model = newBody("MrsWagner", colors, { HeightScale = 0.96, WidthScale = 0.85, DepthScale = 0.9 })
	if not model then
		return nil
	end
	local head, torso, hips = model.Head, model.UpperTorso, model.LowerTorso
	face(model, head, "friendly", colors)
	local size = head.Size
	-- Haare: locker hochgesteckt (nur falls die echten Haare nicht geladen haben)
	if not model:GetAttribute("RealHair") then
		attach(model, head, "Hair", Vector3.new(size.X + 0.08, 0.36, size.Z + 0.08), CFrame.new(0, size.Y / 2 - 0.1, 0.03), colors.hair, Enum.Material.Fabric)
		attach(model, head, "HairBack", Vector3.new(size.X + 0.08, size.Y * 0.7, 0.32), CFrame.new(0, size.Y * 0.12, size.Z / 2 - 0.08), colors.hair, Enum.Material.Fabric)
		attach(model, head, "HairBun", Vector3.new(0.75, 0.6, 0.6), CFrame.new(0, size.Y * 0.3, size.Z / 2 + 0.18), colors.hair, Enum.Material.Fabric, Enum.PartType.Ball)
		for _, side in { -1, 1 } do
			attach(model, head, "HairSide", Vector3.new(0.14, size.Y * 0.62, 0.3), CFrame.new(side * (size.X / 2 + 0.02), size.Y * 0.06, -0.05), colors.hair, Enum.Material.Fabric)
		end
	end
	-- Kleid bis unter die Knie, weißer Kragen, kleine Kette
	longDress(model, hips, "Skirt", colors.torso, Color3.fromRGB(46, 62, 92), 0.4, 1.0)
	local chest = -torso.Size.Z / 2 - 0.01
	attach(model, torso, "Collar", Vector3.new(0.9, 0.16, 0.05), CFrame.new(0, torso.Size.Y / 2 - 0.12, chest), Color3.fromRGB(214, 206, 190), Enum.Material.Fabric)
	attach(model, torso, "Locket", Vector3.new(0.16, 0.22, 0.04), CFrame.new(0, 0.15, chest - 0.01), Color3.fromRGB(150, 122, 60), Enum.Material.Metal)
	-- offene Strickjacke über dem Kleid
	for _, side in { -1, 1 } do
		attach(model, torso, "Cardigan", Vector3.new(torso.Size.X * 0.3, torso.Size.Y + 0.02, 0.05), CFrame.new(side * torso.Size.X * 0.36, 0, chest - 0.005), colors.arms, Enum.Material.Fabric)
	end
	attach(model, torso, "CardiganBack", Vector3.new(torso.Size.X + 0.04, torso.Size.Y + 0.02, 0.05), CFrame.new(0, 0, torso.Size.Z / 2 + 0.015), colors.arms, Enum.Material.Fabric)

	holdCandle(model)

	model.Parent = parent
	return model
end

function Wagners.buildMr(parent)
	local real = Wagners.fromStudio("MrWagner", parent) -- echte Figur aus assets/figuren
	if real then
		return real
	end
	local colors = {
		skin = Color3.fromRGB(222, 182, 152),
		torso = Color3.fromRGB(120, 140, 168), -- sauberes, hellblaues Hemd
		arms = Color3.fromRGB(120, 140, 168),
		legs = Color3.fromRGB(50, 42, 36),
		shoes = Color3.fromRGB(30, 24, 20),
		hair = Color3.fromRGB(66, 62, 58),
		beard = Color3.fromRGB(78, 66, 56),
		eyes = Color3.fromRGB(80, 96, 120),
	}
	local model = newBody("MrWagner", colors, { HeightScale = 1.12, WidthScale = 0.86, DepthScale = 0.9 })
	if not model then
		return nil
	end
	local head, torso, hips = model.Head, model.UpperTorso, model.LowerTorso
	face(model, head, "kind", colors)
	local size = head.Size
	-- kurze, ordentlich gekämmte Haare (nur falls die echten Haare nicht geladen haben)
	if not model:GetAttribute("RealHair") then
		attach(model, head, "Hair", Vector3.new(size.X + 0.06, 0.26, size.Z + 0.04), CFrame.new(0, size.Y / 2 - 0.06, 0.02), colors.hair, Enum.Material.Fabric)
		attach(model, head, "HairBack", Vector3.new(size.X + 0.04, size.Y * 0.45, 0.25), CFrame.new(0, size.Y * 0.15, size.Z / 2 - 0.08), colors.hair, Enum.Material.Fabric)
	end
	-- Hosenträger und Gürtel
	local chest, back = -torso.Size.Z / 2 - 0.01, torso.Size.Z / 2 + 0.01
	for _, side in { -1, 1 } do
		attach(model, torso, "Suspender", Vector3.new(0.13, torso.Size.Y + 0.02, 0.03), CFrame.new(side * 0.34, 0, chest), Color3.fromRGB(46, 32, 26), Enum.Material.Fabric)
		attach(model, torso, "Suspender", Vector3.new(0.13, torso.Size.Y + 0.02, 0.03), CFrame.new(side * 0.2, 0, back) * CFrame.Angles(0, 0, math.rad(side * 14)), Color3.fromRGB(46, 32, 26), Enum.Material.Fabric)
	end
	attach(model, hips, "Belt", Vector3.new(hips.Size.X + 0.04, 0.16, hips.Size.Z + 0.04), CFrame.new(0, hips.Size.Y / 2 - 0.08, 0), Color3.fromRGB(34, 26, 20), Enum.Material.Leather)
	-- hochgekrempelte Ärmel: Unterarme in Hautfarbe, Stoffwulst am Ellbogen
	for _, sideName in { "Left", "Right" } do
		local lower = model:FindFirstChild(sideName .. "LowerArm")
		if lower then
			lower.Color = colors.skin
			attach(model, lower, "Cuff", Vector3.new(lower.Size.X + 0.08, 0.22, lower.Size.Z + 0.08), CFrame.new(0, lower.Size.Y / 2 - 0.1, 0), colors.torso, Enum.Material.Fabric)
		end
	end
	-- Armbanduhr
	local leftLower = model:FindFirstChild("LeftLowerArm")
	if leftLower then
		attach(model, leftLower, "Watch", Vector3.new(leftLower.Size.X + 0.06, 0.14, leftLower.Size.Z + 0.06), CFrame.new(0, -leftLower.Size.Y / 2 + 0.12, 0), Color3.fromRGB(60, 44, 32), Enum.Material.Leather)
	end

	model.Parent = parent
	return model
end

function Wagners.buildLucy(parent)
	local real = Wagners.fromStudio("Lucy", parent) -- echte Figur aus assets/figuren
	if real then
		return real
	end
	local colors = {
		skin = Color3.fromRGB(220, 206, 196),
		torso = Color3.fromRGB(214, 208, 196),
		arms = Color3.fromRGB(214, 208, 196),
		legs = Color3.fromRGB(220, 206, 196),
		shoes = Color3.fromRGB(210, 194, 184),
		hair = Color3.fromRGB(40, 30, 26),
	}
	local model = newBody("Lucy", colors, { HeightScale = 0.72, WidthScale = 0.72, DepthScale = 0.8, HeadScale = 0.95 })
	if not model then
		return nil
	end
	local head, hips = model.Head, model.LowerTorso
	face(model, head, "smile", colors)
	local size = head.Size
	if not model:GetAttribute("RealHair") then
		attach(model, head, "Hair", Vector3.new(size.X + 0.06, 0.3, size.Z + 0.06), CFrame.new(0, size.Y / 2 - 0.08, 0.03), colors.hair, Enum.Material.Fabric)
		attach(model, head, "HairLong", Vector3.new(size.X + 0.1, size.Y * 1.5, 0.3), CFrame.new(0, -size.Y * 0.2, size.Z / 2 - 0.04), colors.hair, Enum.Material.Fabric)
		for _, side in { -1, 1 } do
			attach(model, head, "HairSide", Vector3.new(0.18, size.Y * 1.2, size.Z * 0.5), CFrame.new(side * (size.X / 2 + 0.04), -size.Y * 0.1, 0.1), colors.hair, Enum.Material.Fabric)
		end
	end
	longDress(model, hips, "Nightgown", colors.torso, Color3.fromRGB(190, 184, 172), 0.3, 0.8)
	-- die Puppe in der linken Hand
	local hand = model.LeftHand
	attach(model, hand, "DollBody", Vector3.new(0.3, 0.45, 0.22), CFrame.new(0, -0.35, -0.15), Color3.fromRGB(120, 40, 50), Enum.Material.Fabric)
	attach(model, hand, "DollHead", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, -0.05, -0.15), Color3.fromRGB(220, 214, 200), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	model.Parent = parent
	return model
end

-- Tommy (Sohn, ca. 7): gestreifter Schlafanzug, zerzauste Haare, große dunkle Augen.
-- Hält eine Zeichnung.
function Wagners.buildTommy(parent)
	local real = Wagners.fromStudio("Tommy", parent) -- echte Figur aus assets/figuren
	if real then
		return real
	end
	local colors = {
		skin = Color3.fromRGB(214, 196, 180),
		torso = Color3.fromRGB(70, 90, 130),
		arms = Color3.fromRGB(70, 90, 130),
		legs = Color3.fromRGB(70, 90, 130),
		shoes = Color3.fromRGB(200, 180, 166),
		hair = Color3.fromRGB(92, 70, 48),
	}
	local model = newBody("Tommy", colors, { HeightScale = 0.58, WidthScale = 0.7, DepthScale = 0.8, HeadScale = 1 })
	if not model then
		return nil
	end
	local head, torso = model.Head, model.UpperTorso
	face(model, head, "child", colors)
	local size = head.Size
	if not model:GetAttribute("RealHair") then
		attach(model, head, "Hair", Vector3.new(size.X + 0.08, 0.36, size.Z + 0.08), CFrame.new(0, size.Y / 2 - 0.06, 0.02), colors.hair, Enum.Material.Fabric)
		for i = -1, 1 do
			attach(model, head, "HairTuft", Vector3.new(0.3, 0.2, 0.3), CFrame.new(i * 0.32, size.Y / 2 + 0.1, -0.1 + i * 0.1) * CFrame.Angles(0, 0, math.rad(i * 30)), colors.hair, Enum.Material.Fabric)
		end
	end
	-- Streifen auf dem Schlafanzug
	for k = -2, 2 do
		attach(model, torso, "Stripe", Vector3.new(torso.Size.X + 0.02, 0.08, torso.Size.Z + 0.02), CFrame.new(0, k * torso.Size.Y / 5, 0), Color3.fromRGB(190, 196, 206), Enum.Material.Fabric)
	end
	-- die Zeichnung in der rechten Hand
	local hand = model.RightHand
	attach(model, hand, "Drawing", Vector3.new(0.9, 0.7, 0.02), CFrame.new(0, -0.3, -0.2), Color3.fromRGB(214, 206, 186), Enum.Material.SmoothPlastic)
	attach(model, hand, "DrawingFigure", Vector3.new(0.08, 0.45, 0.01), CFrame.new(0.15, -0.3, -0.215), Color3.fromRGB(16, 14, 12), Enum.Material.SmoothPlastic)
	model.Parent = parent
	return model
end

-- Figur an eine Stelle stellen: `ground` = Punkt auf dem Boden, `facing` = wohin sie schaut
-- Abstand von der Mitte des HumanoidRootPart bis zu den Fußsohlen
local function footOffset(model)
	local stored = model:GetAttribute("FootOffset")
	if stored then
		return stored
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return humanoid.HipHeight + model.HumanoidRootPart.Size.Y / 2
end

-- Echte Figuren (KI-Avatare aus Roblox Studio): liegen als Modelldateien in
-- assets/figuren (Rojo legt sie nach ReplicatedStorage.Wagners). Gibt es dort ein Modell mit
-- diesem Namen ("MrsWagner", "MrWagner", "Lucy", "Tommy"), wird eine Kopie davon benutzt
-- statt der selbst gebauten Figur. Skripte darin werden zur Sicherheit entfernt.
local FIGURE_HEIGHT = { MrsWagner = 5.3, MrWagner = 5.9, Lucy = 4.3, Tommy = 3.6 }
local FIGURE_STEP = { MrsWagner = 0.5, Lucy = 0.5 } -- lange Kleider: Beine schwingen weniger

-- KI-Figuren stehen mit ausgestreckten Armen (T-/A-Haltung). Hier hängen die Arme
-- locker nach unten, ein wenig vom Körper weg (die Hände stechen nicht ins Kleid).
local function relaxArms(model)
	local root = model.HumanoidRootPart
	for _, side in { "Left", "Right" } do
		local upper = model:FindFirstChild(side .. "UpperArm")
		local joint = upper and upper:FindFirstChild(side .. "Shoulder")
		local hand = model:FindFirstChild(side .. "Hand")
		if joint and joint:IsA("Motor6D") and hand then
			local pivot = joint.Part0.CFrame * joint.C0
			local current = (hand.Position - pivot.Position).Unit
			local outward = root.CFrame.RightVector * (side == "Right" and 1 or -1)
			local wanted = (-root.CFrame.UpVector + outward * 0.12).Unit
			local axis = current:Cross(wanted)
			if axis.Magnitude > 1e-3 then
				local angle = math.acos(math.clamp(current:Dot(wanted), -1, 1))
				local turn = CFrame.fromAxisAngle(axis.Unit, angle)
				local turned = CFrame.new(pivot.Position) * turn * (pivot - pivot.Position)
				joint.C0 = joint.Part0.CFrame:ToObjectSpace(turned)
				-- Drehung merken: Dinge in der Hand (Kerze, Puppe, Bild) gleichen sie aus
				model:SetAttribute(side .. "ArmRelax", turn:Inverse())
			end
		end
	end
end

local function holdDoll(model)
	local hand = model:FindFirstChild("LeftHand")
	if hand then
		local relax = model:GetAttribute("LeftArmRelax") or CFrame.new()
		attach(model, hand, "DollBody", Vector3.new(0.3, 0.45, 0.22), relax * CFrame.new(0, -0.35, -0.15), Color3.fromRGB(120, 40, 50), Enum.Material.Fabric)
		attach(model, hand, "DollHead", Vector3.new(0.3, 0.3, 0.3), relax * CFrame.new(0, -0.05, -0.15), Color3.fromRGB(220, 214, 200), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
end

local function holdDrawing(model)
	local hand = model:FindFirstChild("RightHand")
	if hand then
		local relax = model:GetAttribute("RightArmRelax") or CFrame.new()
		attach(model, hand, "Drawing", Vector3.new(0.9, 0.7, 0.02), relax * CFrame.new(0, -0.3, -0.2), Color3.fromRGB(214, 206, 186), Enum.Material.SmoothPlastic)
		attach(model, hand, "DrawingFigure", Vector3.new(0.08, 0.45, 0.01), relax * CFrame.new(0.15, -0.3, -0.215), Color3.fromRGB(16, 14, 12), Enum.Material.SmoothPlastic)
	end
end

-- Kam ein Körperteil ohne Form an (Rojo darf MeshId nicht setzen), wird es hier mit der
-- gesicherten Modell-ID neu erzeugt; Kinder (Knochen, Gelenke, Textur) ziehen mit um.
-- Passiert einmal pro Figur am Original in ReplicatedStorage.Wagners.
local function repairMeshes(source, name)
	if source:GetAttribute("MeshesChecked") then
		return
	end
	source:SetAttribute("MeshesChecked", true)
	local ok, ids = pcall(require, script.Parent:FindFirstChild("FigurenMeshes"))
	ids = ok and ids and ids[name]
	if not ids then
		return
	end
	local AssetService = game:GetService("AssetService")
	local fixed = 0
	for _, old in source:GetChildren() do
		if old:IsA("MeshPart") and old.MeshId == "" and ids[old.Name] then
			local made, new = pcall(function()
				return AssetService:CreateMeshPartAsync("rbxassetid://" .. ids[old.Name], {
					CollisionFidelity = Enum.CollisionFidelity.Box,
				})
			end)
			if made and new then
				new.Name = old.Name
				new.Size = old.Size
				new.CFrame = old.CFrame
				new.Color = old.Color
				new.Transparency = old.Transparency
				new.Anchored = old.Anchored
				for _, child in old:GetChildren() do
					child.Parent = new
				end
				new.Parent = source
				old:Destroy()
				fixed += 1
			else
				warn("Kapitel 2: " .. name .. "." .. old.Name .. " konnte nicht geladen werden:", new)
			end
		end
	end
	if fixed > 0 then
		print("Kapitel 2: " .. name .. " – " .. fixed .. " Körperteile neu geladen.")
	end
end

function Wagners.fromStudio(name, parent)
	-- ReplicatedStorage: dort können die Spieler sie schon vorladen (FigurenVorladen.client.lua)
	local found, folder = pcall(function()
		return game:GetService("ReplicatedStorage"):FindFirstChild("Wagners")
			or game:GetService("ServerStorage"):FindFirstChild("Wagners")
	end)
	folder = found and folder or nil
	local source = folder and folder:FindFirstChild(name)
	if not (source and source:IsA("Model")) then
		return nil
	end
	repairMeshes(source, name)
	local model = source:Clone()
	model.Name = name
	for _, item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") then
			item:Destroy()
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root) then
		warn("Kapitel 2: ServerStorage.Wagners." .. name .. " ist keine Spielfigur (Humanoid und HumanoidRootPart fehlen) – nehme die eingebaute Figur.")
		model:Destroy()
		return nil
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	pcall(function()
		humanoid.EvaluateStateMachine = false
	end)
	-- aufrecht hinstellen und auf die richtige Größe bringen
	local function measure()
		local lowest, highest = math.huge, -math.huge
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and part ~= root and part.Transparency < 1 then
				lowest = math.min(lowest, part.Position.Y - part.Size.Y / 2)
				highest = math.max(highest, part.Position.Y + part.Size.Y / 2)
			end
		end
		return lowest, highest
	end
	model.PrimaryPart = root
	model:PivotTo(CFrame.new(root.Position))
	local low, high = measure()
	local wanted = FIGURE_HEIGHT[name]
	if wanted and high > low then
		pcall(function()
			model:ScaleTo(model:GetScale() * wanted / (high - low))
		end)
	end
	-- Nur die Mitte ist verankert, alles andere hängt an den Gelenken.
	-- KI-Figuren: Gelenke sind dort AnimationConstraints (an Knochen) – werden zu Motor6D.
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = part == root
			part.CanCollide = false
			part.CanTouch = false
		elseif part:IsA("BallSocketConstraint") then
			part:Destroy()
		end
	end
	for _, info in MOVING_JOINTS do
		replaceJoint(model, info[1], info[2])
	end
	relaxArms(model)
	-- Abstand Mitte bis Füße messen (nach dem Skalieren, mit hängenden Armen)
	local lowest = measure()
	if lowest < math.huge then
		model:SetAttribute("FootOffset", root.Position.Y - lowest)
	end
	model:SetAttribute("RealFigure", true)
	if FIGURE_STEP[name] then
		model:SetAttribute("StepScale", FIGURE_STEP[name])
	end
	-- Erst in die Welt stellen, dann Dinge in die Hand geben: nur dort rechnet Roblox die
	-- Gelenke sofort um, sonst sitzen Kerze/Puppe/Bild schief neben der Hand.
	model.Parent = parent
	if name == "MrsWagner" then
		holdCandle(model)
	elseif name == "Lucy" then
		holdDoll(model)
	elseif name == "Tommy" then
		holdDrawing(model)
	end
	return model
end

function Wagners.place(model, ground, facing)
	local root = model.HumanoidRootPart
	local height = footOffset(model)
	local target = Vector3.new(facing.X, ground.Y, facing.Z)
	if (target - ground).Magnitude < 0.01 then
		target = ground + root.CFrame.LookVector
	end
	root.CFrame = CFrame.lookAt(ground, target) + Vector3.new(0, height, 0)
end

-- Hinsetzen: Oberschenkel nach vorne, Unterschenkel nach unten, Hüfte auf die Sitzfläche.
-- `seat` = Mitte der Sitzfläche (oben), Blickrichtung = wohin man auf dem Stuhl schaut.
function Wagners.sit(model, seat)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	local lowerTorso = model and model:FindFirstChild("LowerTorso")
	if not (root and lowerTorso) then
		return
	end
	if not model:GetAttribute("Sitting") then
		-- Abstand Mitte -> Hüftgelenk messen, solange die Figur noch steht
		local hip = model:FindFirstChild("LeftUpperLeg") and model.LeftUpperLeg:FindFirstChild("LeftHip")
		local hipY = hip and (lowerTorso.CFrame * hip.C0).Position.Y or (root.Position.Y - root.Size.Y / 2)
		model:SetAttribute("HipOffset", root.Position.Y - hipY)
		for _, side in { "Left", "Right" } do
			local upper, lower = model:FindFirstChild(side .. "UpperLeg"), model:FindFirstChild(side .. "LowerLeg")
			local hipJoint = upper and upper:FindFirstChild(side .. "Hip")
			local kneeJoint = lower and lower:FindFirstChild(side .. "Knee")
			for _, joint in { hipJoint, kneeJoint } do
				if joint and not joint:GetAttribute("Standing") then
					joint:SetAttribute("Standing", joint.C0)
				end
			end
			pcall(function()
				hipJoint.C0 = hipJoint:GetAttribute("Standing") * CFrame.Angles(math.rad(90), 0, 0)
				kneeJoint.C0 = kneeJoint:GetAttribute("Standing") * CFrame.Angles(math.rad(-90), 0, 0)
			end)
		end
		model:SetAttribute("Sitting", true)
		Wagners.showLowerDress(model, false)
	end
	local thigh = model:FindFirstChild("LeftUpperLeg")
	local thighHalf = thigh and thigh.Size.Z / 2 or 0.5
	local look = seat.LookVector * Vector3.new(1, 0, 1)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
	local position = seat.Position - look * 0.35 + Vector3.new(0, thighHalf + (model:GetAttribute("HipOffset") or 1), 0)
	root.CFrame = CFrame.lookAt(position, position + look)
end

-- Wieder aufstehen und neben den Stuhl stellen (`feet` = wo die Füße hinkommen)
function Wagners.stand(model, feet, lookAt)
	if not (model and model:GetAttribute("Sitting")) then
		return
	end
	for _, side in { "Left", "Right" } do
		for _, name in { side .. "Hip", side .. "Knee" } do
			local part = model:FindFirstChild(side .. (name:find("Hip") and "UpperLeg" or "LowerLeg"))
			local joint = part and part:FindFirstChild(name)
			if joint and joint:GetAttribute("Standing") then
				pcall(function()
					joint.C0 = joint:GetAttribute("Standing")
				end)
			end
		end
	end
	model:SetAttribute("Sitting", false)
	Wagners.showLowerDress(model, true)
	if feet then
		Wagners.place(model, feet, lookAt or (feet + model.HumanoidRootPart.CFrame.LookVector))
	end
end

-- Wo die Füße der Figur gerade stehen
function Wagners.ground(model)
	return model.HumanoidRootPart.Position - Vector3.new(0, footOffset(model), 0)
end

return Wagners
