-- Kapitel 2: die Gastfamilie Wagner. Bisher Mrs. Wagner und Mr. Wagner, die Kinder
-- kommen später. Beide sind verankert und werden vom Server gestellt und bewegt
-- (Kapitel2.lua); die Clients drehen nur ihre Köpfe (Attribut "Look").
--
-- Mrs. Wagner (Margaret): um die 45, dunkelgrünes Kleid, graubraune Strickjacke, Haare
--   streng zu einem Knoten gebunden. Sehr blass, dunkle Ringe unter den Augen, kleine
--   starre Pupillen und ein Lächeln, das nie aufhört. Hält eine Kerze.
-- Mr. Wagner (Richard): groß und hager, schmutziges Hemd mit hochgekrempelten Ärmeln,
--   Hosenträger, ungepflegter Bart, müde Augen. Seine linke Hand ist verbunden – der
--   Verband ist blutig.
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

local function newBody(name, colors, scale)
	local description = Instance.new("HumanoidDescription")
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
	local face = model.Head:FindFirstChildOfClass("Decal")
	if face then
		face:Destroy()
	end
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
	return model
end

-- Augen, Brauen, Mund. `style`: "smile" (Mrs. Wagner) oder "tired" (Mr. Wagner)
local function face(model, head, style, colors)
	local size = head.Size
	local front = -size.Z / 2 - 0.005
	local s = size.Y / 1.2 -- Gesichter sind für einen 1.2 hohen Kopf gemacht
	for _, side in { -1, 1 } do
		local x = side * 0.2 * s
		if style == "smile" then
			attach(model, head, "EyeWhite", Vector3.new(0.21 * s, 0.14 * s, 0.02), CFrame.new(x, 0.12 * s, front), Color3.fromRGB(236, 232, 224))
			-- winzige, starre Pupillen
			attach(model, head, "Pupil", Vector3.new(0.055 * s, 0.055 * s, 0.02), CFrame.new(x, 0.12 * s, front - 0.012), Color3.fromRGB(18, 14, 12))
			attach(model, head, "EyeRing", Vector3.new(0.24 * s, 0.06 * s, 0.02), CFrame.new(x, 0.01 * s, front), Color3.fromRGB(128, 104, 112))
			attach(model, head, "Brow", Vector3.new(0.24 * s, 0.035 * s, 0.02), CFrame.new(x, 0.29 * s, front) * CFrame.Angles(0, 0, math.rad(side * 8)), colors.hair)
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
	if style == "smile" then
		-- breites, starres Lächeln
		local lips = Color3.fromRGB(128, 66, 66)
		attach(model, head, "Mouth", Vector3.new(0.4 * s, 0.035 * s, 0.02), CFrame.new(0, -0.26 * s, front), lips)
		for _, side in { -1, 1 } do
			attach(model, head, "MouthCorner", Vector3.new(0.12 * s, 0.035 * s, 0.02), CFrame.new(side * 0.24 * s, -0.235 * s, front) * CFrame.Angles(0, 0, math.rad(side * 28)), lips)
		end
	else
		-- Bart mit Schnurrbart, darin ein schmaler, gerader Mund
		attach(model, head, "Beard", Vector3.new(size.X * 0.82, 0.42 * s, 0.08), CFrame.new(0, -0.33 * s, front + 0.03), colors.beard, Enum.Material.Fabric)
		attach(model, head, "BeardChin", Vector3.new(size.X * 0.6, 0.22 * s, size.Z * 0.5), CFrame.new(0, -size.Y / 2 + 0.02, -size.Z * 0.22), colors.beard, Enum.Material.Fabric)
		for _, side in { -1, 1 } do
			attach(model, head, "BeardSide", Vector3.new(0.12, size.Y * 0.55, size.Z * 0.7), CFrame.new(side * (size.X / 2 + 0.03), -0.15 * s, -0.05), colors.beard, Enum.Material.Fabric)
		end
		attach(model, head, "Mustache", Vector3.new(0.48 * s, 0.09 * s, 0.04), CFrame.new(0, -0.14 * s, front - 0.01), colors.beard, Enum.Material.Fabric)
		attach(model, head, "Mouth", Vector3.new(0.26 * s, 0.03 * s, 0.02), CFrame.new(0, -0.23 * s, front - 0.04), Color3.fromRGB(70, 42, 38))
	end
end

function Wagners.buildMrs(parent)
	local colors = {
		skin = Color3.fromRGB(214, 198, 186),
		torso = Color3.fromRGB(44, 58, 50),
		arms = Color3.fromRGB(92, 82, 70),
		legs = Color3.fromRGB(58, 50, 46),
		shoes = Color3.fromRGB(22, 20, 18),
		hair = Color3.fromRGB(78, 66, 58),
	}
	local model = newBody("MrsWagner", colors, { HeightScale = 0.96, WidthScale = 0.85, DepthScale = 0.9 })
	if not model then
		return nil
	end
	local head, torso, hips = model.Head, model.UpperTorso, model.LowerTorso
	face(model, head, "smile", colors)
	local size = head.Size
	-- Haare: streng zurück, Knoten hinten, ein paar graue Strähnen
	attach(model, head, "Hair", Vector3.new(size.X + 0.06, 0.32, size.Z + 0.06), CFrame.new(0, size.Y / 2 - 0.1, 0.03), colors.hair, Enum.Material.Fabric)
	attach(model, head, "HairBack", Vector3.new(size.X + 0.06, size.Y * 0.6, 0.3), CFrame.new(0, size.Y * 0.18, size.Z / 2 - 0.08), colors.hair, Enum.Material.Fabric)
	attach(model, head, "HairBun", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, size.Y * 0.22, size.Z / 2 + 0.22), colors.hair, Enum.Material.Fabric, Enum.PartType.Ball)
	for _, x in { -0.25, 0.3 } do
		attach(model, head, "GrayStrand", Vector3.new(0.08, 0.05, size.Z * 0.7), CFrame.new(x, size.Y / 2 + 0.07, 0), Color3.fromRGB(150, 146, 140), Enum.Material.Fabric)
	end
	-- Kleid: langer Rock bis unter die Knie, Spitzenkragen, Medaillon
	attach(model, hips, "Skirt", Vector3.new(hips.Size.X + 0.45, 2.5, hips.Size.Z + 0.45), CFrame.new(0, -1.15, 0), colors.torso, Enum.Material.Fabric)
	attach(model, hips, "SkirtHem", Vector3.new(hips.Size.X + 0.55, 0.15, hips.Size.Z + 0.55), CFrame.new(0, -2.33, 0), Color3.fromRGB(34, 46, 40), Enum.Material.Fabric)
	local chest = -torso.Size.Z / 2 - 0.01
	attach(model, torso, "Collar", Vector3.new(0.9, 0.16, 0.05), CFrame.new(0, torso.Size.Y / 2 - 0.12, chest), Color3.fromRGB(214, 206, 190), Enum.Material.Fabric)
	attach(model, torso, "Locket", Vector3.new(0.16, 0.22, 0.04), CFrame.new(0, 0.15, chest - 0.01), Color3.fromRGB(150, 122, 60), Enum.Material.Metal)
	-- offene Strickjacke über dem Kleid
	for _, side in { -1, 1 } do
		attach(model, torso, "Cardigan", Vector3.new(torso.Size.X * 0.3, torso.Size.Y + 0.02, 0.05), CFrame.new(side * torso.Size.X * 0.36, 0, chest - 0.005), colors.arms, Enum.Material.Fabric)
	end
	attach(model, torso, "CardiganBack", Vector3.new(torso.Size.X + 0.04, torso.Size.Y + 0.02, 0.05), CFrame.new(0, 0, torso.Size.Z / 2 + 0.015), colors.arms, Enum.Material.Fabric)

	-- Rechter Arm angewinkelt (hält die Kerze vor der Brust). Die Kerze wird in der
	-- Grundhaltung so angebracht, dass sie nach dem Anwinkeln genau senkrecht steht.
	local up, bend = math.rad(35), math.rad(65)
	local hand = model.RightHand
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
	local shoulder = model.RightUpperArm:FindFirstChild("RightShoulder")
	local elbow = model.RightLowerArm:FindFirstChild("RightElbow")
	if shoulder and elbow then
		shoulder.C0 *= CFrame.Angles(up, 0, 0)
		elbow.C0 *= CFrame.Angles(bend, 0, 0)
	end

	model.Parent = parent
	return model
end

function Wagners.buildMr(parent)
	local colors = {
		skin = Color3.fromRGB(196, 168, 150),
		torso = Color3.fromRGB(160, 150, 128),
		arms = Color3.fromRGB(160, 150, 128),
		legs = Color3.fromRGB(50, 42, 36),
		shoes = Color3.fromRGB(30, 24, 20),
		hair = Color3.fromRGB(66, 62, 58),
		beard = Color3.fromRGB(62, 58, 52),
	}
	local model = newBody("MrWagner", colors, { HeightScale = 1.12, WidthScale = 0.86, DepthScale = 0.9 })
	if not model then
		return nil
	end
	local head, torso, hips = model.Head, model.UpperTorso, model.LowerTorso
	face(model, head, "tired", colors)
	local size = head.Size
	-- zerzauste, dünne Haare
	attach(model, head, "Hair", Vector3.new(size.X + 0.04, 0.24, size.Z * 0.8), CFrame.new(0.04, size.Y / 2 - 0.06, 0.12), colors.hair, Enum.Material.Fabric)
	attach(model, head, "HairBack", Vector3.new(size.X + 0.04, size.Y * 0.45, 0.25), CFrame.new(0, size.Y * 0.15, size.Z / 2 - 0.08), colors.hair, Enum.Material.Fabric)
	attach(model, head, "HairTuft", Vector3.new(0.3, 0.18, 0.3), CFrame.new(-0.3, size.Y / 2 + 0.06, -0.1) * CFrame.Angles(0, 0, math.rad(25)), colors.hair, Enum.Material.Fabric)
	-- Hosenträger und Gürtel
	local chest, back = -torso.Size.Z / 2 - 0.01, torso.Size.Z / 2 + 0.01
	for _, side in { -1, 1 } do
		attach(model, torso, "Suspender", Vector3.new(0.13, torso.Size.Y + 0.02, 0.03), CFrame.new(side * 0.34, 0, chest), Color3.fromRGB(46, 32, 26), Enum.Material.Fabric)
		attach(model, torso, "Suspender", Vector3.new(0.13, torso.Size.Y + 0.02, 0.03), CFrame.new(side * 0.2, 0, back) * CFrame.Angles(0, 0, math.rad(side * 14)), Color3.fromRGB(46, 32, 26), Enum.Material.Fabric)
	end
	attach(model, hips, "Belt", Vector3.new(hips.Size.X + 0.04, 0.16, hips.Size.Z + 0.04), CFrame.new(0, hips.Size.Y / 2 - 0.08, 0), Color3.fromRGB(34, 26, 20), Enum.Material.Leather)
	attach(model, torso, "Stain", Vector3.new(0.35, 0.28, 0.02), CFrame.new(-0.45, -0.35, chest - 0.005), Color3.fromRGB(110, 96, 74), Enum.Material.Fabric)
	-- hochgekrempelte Ärmel: Unterarme in Hautfarbe, Stoffwulst am Ellbogen
	for _, sideName in { "Left", "Right" } do
		local lower = model:FindFirstChild(sideName .. "LowerArm")
		if lower then
			lower.Color = colors.skin
			attach(model, lower, "Cuff", Vector3.new(lower.Size.X + 0.08, 0.22, lower.Size.Z + 0.08), CFrame.new(0, lower.Size.Y / 2 - 0.1, 0), colors.torso, Enum.Material.Fabric)
		end
	end
	-- verbundene linke Hand, der Verband ist blutig
	local leftHand = model.LeftHand
	attach(model, leftHand, "Bandage", leftHand.Size + Vector3.new(0.06, 0.04, 0.06), CFrame.new(), Color3.fromRGB(196, 190, 174), Enum.Material.Fabric)
	attach(model, leftHand, "Blood", Vector3.new(0.18, 0.2, 0.02), CFrame.new(0.02, -0.02, -leftHand.Size.Z / 2 - 0.045), Color3.fromRGB(110, 20, 18), Enum.Material.Fabric)

	model.Parent = parent
	return model
end

-- Figur an eine Stelle stellen: `ground` = Punkt auf dem Boden, `facing` = wohin sie schaut
function Wagners.place(model, ground, facing)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model.HumanoidRootPart
	local height = humanoid.HipHeight + root.Size.Y / 2
	local target = Vector3.new(facing.X, ground.Y, facing.Z)
	if (target - ground).Magnitude < 0.01 then
		target = ground + root.CFrame.LookVector
	end
	root.CFrame = CFrame.lookAt(ground, target) + Vector3.new(0, height, 0)
end

-- Wo die Füße der Figur gerade stehen
function Wagners.ground(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model.HumanoidRootPart
	return root.Position - Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)
end

return Wagners
