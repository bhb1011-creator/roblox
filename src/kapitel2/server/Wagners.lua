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

-- Gelenke, die sich bewegen (Kopf drehen, Arm anwinkeln, Beine beim Gehen). In
-- manchen Roblox-Versionen sind die Gelenke dieser Figuren schreibgeschützt
-- ("C0 is read only"). Deshalb werden sie durch eigene, gleichwertige ersetzt.
local MOVING_JOINTS = {
	{ "Head", "Neck" },
	{ "RightUpperArm", "RightShoulder" },
	{ "RightLowerArm", "RightElbow" },
	{ "LeftUpperLeg", "LeftHip" },
	{ "RightUpperLeg", "RightHip" },
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
		ok = pcall(function()
			local a0, a1 = old.Attachment0, old.Attachment1
			part0, part1, c0, c1 = a0.Parent, a1.Parent, a0.CFrame, a1.CFrame
		end)
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
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
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
		local lips = Color3.fromRGB(168, 92, 92)
		attach(model, head, "Mouth", Vector3.new(0.22 * s, 0.04 * s, 0.02), CFrame.new(0, -0.26 * s, front), lips)
		for _, side in { -1, 1 } do
			attach(model, head, "MouthCorner", Vector3.new(0.07 * s, 0.035 * s, 0.02), CFrame.new(side * 0.135 * s, -0.245 * s, front) * CFrame.Angles(0, 0, math.rad(side * 22)), lips)
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
		local lips = Color3.fromRGB(128, 66, 66)
		attach(model, head, "Mouth", Vector3.new(0.4 * s, 0.035 * s, 0.02), CFrame.new(0, -0.26 * s, front), lips)
		for _, side in { -1, 1 } do
			attach(model, head, "MouthCorner", Vector3.new(0.12 * s, 0.035 * s, 0.02), CFrame.new(side * 0.24 * s, -0.235 * s, front) * CFrame.Angles(0, 0, math.rad(side * 28)), lips)
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
	local upright = CFrame.Angles(-(up + bend), 0, 0)
	local lift = hand.Size.Y / 2
	attach(model, hand, "CandleHolder", Vector3.new(0.12, 0.6, 0.6), upright * CFrame.new(0, lift + 0.06, -0.05) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 96, 52), Enum.Material.Metal, Enum.PartType.Cylinder)
	attach(model, hand, "Candle", Vector3.new(0.9, 0.22, 0.22), upright * CFrame.new(0, lift + 0.57, -0.05) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(225, 215, 190), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local flame = attach(model, hand, "CandleFlame", Vector3.new(0.15, 0.15, 0.15), upright * CFrame.new(0, lift + 1.1, -0.05), Color3.fromRGB(255, 170, 70), Enum.Material.Neon, Enum.PartType.Ball)
	flame.CastShadow = false
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
	-- Haare: locker hochgesteckt, ein paar Strähnen an den Seiten
	attach(model, head, "Hair", Vector3.new(size.X + 0.08, 0.36, size.Z + 0.08), CFrame.new(0, size.Y / 2 - 0.1, 0.03), colors.hair, Enum.Material.Fabric)
	attach(model, head, "HairBack", Vector3.new(size.X + 0.08, size.Y * 0.7, 0.32), CFrame.new(0, size.Y * 0.12, size.Z / 2 - 0.08), colors.hair, Enum.Material.Fabric)
	attach(model, head, "HairBun", Vector3.new(0.75, 0.6, 0.6), CFrame.new(0, size.Y * 0.3, size.Z / 2 + 0.18), colors.hair, Enum.Material.Fabric, Enum.PartType.Ball)
	for _, side in { -1, 1 } do
		attach(model, head, "HairSide", Vector3.new(0.14, size.Y * 0.62, 0.3), CFrame.new(side * (size.X / 2 + 0.02), size.Y * 0.06, -0.05), colors.hair, Enum.Material.Fabric)
	end
	-- Kleid bis unter die Knie, weißer Kragen, kleine Kette
	attach(model, hips, "Skirt", Vector3.new(hips.Size.X + 0.45, 2.5, hips.Size.Z + 0.45), CFrame.new(0, -1.15, 0), colors.torso, Enum.Material.Fabric)
	attach(model, hips, "SkirtHem", Vector3.new(hips.Size.X + 0.55, 0.15, hips.Size.Z + 0.55), CFrame.new(0, -2.33, 0), Color3.fromRGB(46, 62, 92), Enum.Material.Fabric)
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
	-- kurze, ordentlich gekämmte Haare
	attach(model, head, "Hair", Vector3.new(size.X + 0.06, 0.26, size.Z + 0.04), CFrame.new(0, size.Y / 2 - 0.06, 0.02), colors.hair, Enum.Material.Fabric)
	attach(model, head, "HairBack", Vector3.new(size.X + 0.04, size.Y * 0.45, 0.25), CFrame.new(0, size.Y * 0.15, size.Z / 2 - 0.08), colors.hair, Enum.Material.Fabric)
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
	attach(model, head, "Hair", Vector3.new(size.X + 0.06, 0.3, size.Z + 0.06), CFrame.new(0, size.Y / 2 - 0.08, 0.03), colors.hair, Enum.Material.Fabric)
	attach(model, head, "HairLong", Vector3.new(size.X + 0.1, size.Y * 1.5, 0.3), CFrame.new(0, -size.Y * 0.2, size.Z / 2 - 0.04), colors.hair, Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		attach(model, head, "HairSide", Vector3.new(0.18, size.Y * 1.2, size.Z * 0.5), CFrame.new(side * (size.X / 2 + 0.04), -size.Y * 0.1, 0.1), colors.hair, Enum.Material.Fabric)
	end
	attach(model, hips, "Nightgown", Vector3.new(hips.Size.X + 0.35, 2.9, hips.Size.Z + 0.35), CFrame.new(0, -1.35, 0), colors.torso, Enum.Material.Fabric)
	attach(model, hips, "NightgownHem", Vector3.new(hips.Size.X + 0.45, 0.12, hips.Size.Z + 0.45), CFrame.new(0, -2.75, 0), Color3.fromRGB(190, 184, 172), Enum.Material.Fabric)
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
	attach(model, head, "Hair", Vector3.new(size.X + 0.08, 0.36, size.Z + 0.08), CFrame.new(0, size.Y / 2 - 0.06, 0.02), colors.hair, Enum.Material.Fabric)
	for i = -1, 1 do
		attach(model, head, "HairTuft", Vector3.new(0.3, 0.2, 0.3), CFrame.new(i * 0.32, size.Y / 2 + 0.1, -0.1 + i * 0.1) * CFrame.Angles(0, 0, math.rad(i * 30)), colors.hair, Enum.Material.Fabric)
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

-- Eigene Figuren aus Studio: Liegt in ServerStorage ein Ordner "Wagners" mit einem Modell
-- dieses Namens ("MrsWagner" oder "MrWagner"), wird eine Kopie davon benutzt statt der
-- selbst gebauten Figur. So kann man in Studio echte Roblox-Avatare (mit Kleidung, Haaren
-- und Gesicht) aussuchen. Skripte darin werden zur Sicherheit entfernt.
function Wagners.fromStudio(name, parent)
	local found, folder = pcall(function()
		return game:GetService("ServerStorage"):FindFirstChild("Wagners")
	end)
	folder = found and folder or nil
	local source = folder and folder:FindFirstChild(name)
	if not (source and source:IsA("Model")) then
		return nil
	end
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
	-- Abstand Mitte bis Füße messen, solange die Figur noch so steht wie in Studio
	local lowest = math.huge
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= root and part.Transparency < 1 then
			lowest = math.min(lowest, part.Position.Y - part.Size.Y / 2)
		end
	end
	if lowest < math.huge then
		model:SetAttribute("FootOffset", root.Position.Y - lowest)
	end
	-- Nur die Mitte ist verankert, alles andere hängt an den Gelenken
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = part == root
			part.CanCollide = false
		end
	end
	model.PrimaryPart = root
	for _, info in MOVING_JOINTS do
		replaceJoint(model, info[1], info[2])
	end
	if name == "MrsWagner" then
		holdCandle(model)
	end
	model.Parent = parent
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

-- Wo die Füße der Figur gerade stehen
function Wagners.ground(model)
	return model.HumanoidRootPart.Position - Vector3.new(0, footOffset(model), 0)
end

return Wagners
