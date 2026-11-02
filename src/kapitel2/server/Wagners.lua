-- Kapitel 2: die Gastfamilie Wagner. Bisher Mrs. Wagner und Mr. Wagner, die Kinder
-- kommen später. Beide sind verankert und werden vom Server gestellt und bewegt
-- (Kapitel2.lua); die Clients drehen nur ihre Köpfe (Attribut "Look").
--
-- Beide sehen erst einmal ganz normal und freundlich aus (runde, menschliche Körper und
-- echte Gesichter statt der eckigen Roblox-Figuren) – dass sie von Sarp besessen
-- sind, merkt man nur an dem, was sie sagen und tun.
-- Mrs. Wagner (Margaret): um die 45, dunkelblaues Kleid, graugrüne Strickjacke, braune Haare
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

-- Runde Form (Ellipsoid oder Zylinder) an einem Körperteil. Zylinder stehen senkrecht.
local function rounded(model, bodyPart, name, size, offset, color, material, kind)
	local vertical = kind == "Cylinder"
	local partSize = vertical and Vector3.new(size.Y, size.X, size.Z) or size
	local frame = vertical and offset * CFrame.Angles(0, 0, math.rad(90)) or offset
	local part = attach(model, bodyPart, name, partSize, frame, color, material or Enum.Material.SmoothPlastic)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = vertical and Enum.MeshType.Cylinder or Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- Statt der Roblox-Standardkörper: schlanke, natürliche Formen in menschlichen Proportionen
-- (Oberkörper eher kantig, Arme und Beine schmal). Die eigentlichen Körperteile werden
-- unsichtbar, bewegen aber weiterhin alles, was daran hängt.
local function smoothBody(model, colors, build)
	build = build or {}
	local function part(name)
		return model:FindFirstChild(name)
	end
	for _, name in { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" } do
		local bodyPart = part(name)
		if bodyPart then
			bodyPart.Transparency = 1
		end
	end
	local fabric = Enum.Material.Fabric
	local skin = colors.skin
	local shoulders = build.shoulders or 0.84 -- Schulterbreite im Verhältnis zum Roblox-Oberkörper
	local waist = build.waist or 0.7
	local head = part("Head")
	if head then
		local hs = head.Size
		rounded(model, head, "HeadShape", Vector3.new(hs.X * 0.78, hs.Y * 1.0, hs.Z * 0.88), CFrame.new(0, 0.02, 0), skin)
	end
	local torso = part("UpperTorso")
	if torso then
		local t = torso.Size
		-- Brustkorb, darunter der etwas schmalere Bauch
		attach(model, torso, "Chest", Vector3.new(t.X * shoulders, t.Y * 0.6, t.Z * 0.6), CFrame.new(0, t.Y * 0.18, 0), colors.torso, fabric)
		attach(model, torso, "Belly", Vector3.new(t.X * waist, t.Y * 0.5, t.Z * 0.56), CFrame.new(0, -t.Y * 0.3, 0), colors.torso, fabric)
		-- runde Schulterlinie
		rounded(model, torso, "ShoulderLine", Vector3.new(t.Z * 0.6, t.X * shoulders, t.Z * 0.6), CFrame.new(0, t.Y * 0.47, 0) * CFrame.Angles(0, 0, math.rad(90)), colors.arms, fabric, "Cylinder")
		rounded(model, torso, "Neck", Vector3.new(t.X * 0.17, t.Y * 0.3, t.Z * 0.3), CFrame.new(0, t.Y * 0.58, 0.02), skin, nil, "Cylinder")
	end
	local hips = part("LowerTorso")
	if hips then
		local h = hips.Size
		attach(model, hips, "Pelvis", Vector3.new(h.X * (build.hips or 0.76), h.Y * 1.9, h.Z * 0.58), CFrame.new(0, -h.Y * 0.2, 0), colors.legs, fabric)
	end
	for _, side in { "Left", "Right" } do
		local upper, lower, hand = part(side .. "UpperArm"), part(side .. "LowerArm"), part(side .. "Hand")
		-- Die Roblox-Arme sitzen weit außen; die schmalen Arme rücken an den Körper
		local inward = side == "Left" and 1 or -1
		if upper then
			local u = upper.Size
			local x = inward * u.X * 0.4
			local thick = build.arm or 0.36
			rounded(model, upper, "Arm", Vector3.new(u.X * thick, u.Y * 1.04, u.Z * thick), CFrame.new(x, 0, 0), colors.arms, fabric, "Cylinder")
			rounded(model, upper, "Elbow", Vector3.new(u.X * thick * 0.96, u.X * thick * 0.96, u.Z * thick * 0.96), CFrame.new(x, -u.Y / 2, 0), colors.lowerArms or colors.arms, fabric)
		end
		if lower then
			local l = lower.Size
			local thick = (build.arm or 0.36) * 0.88
			rounded(model, lower, "Forearm", Vector3.new(l.X * thick, l.Y * 1.04, l.Z * thick), CFrame.new(inward * l.X * 0.4, 0, 0), colors.lowerArms or colors.arms, fabric, "Cylinder")
		end
		if hand then
			local h = hand.Size
			attach(model, hand, "Hand", Vector3.new(h.X * 0.14, h.Y * 1.6, h.Z * 0.3), CFrame.new(inward * h.X * 0.4, -h.Y * 0.25, 0), colors.hands or skin)
			rounded(model, hand, "Thumb", Vector3.new(h.X * 0.08, h.Y * 0.8, h.Z * 0.1), CFrame.new(inward * h.X * 0.36, -h.Y * 0.05, -h.Z * 0.16), colors.hands or skin)
		end
		local thigh, shin, foot = part(side .. "UpperLeg"), part(side .. "LowerLeg"), part(side .. "Foot")
		if thigh then
			local u = thigh.Size
			local thick = build.leg or 0.52
			rounded(model, thigh, "Thigh", Vector3.new(u.X * thick, u.Y * 1.04, u.Z * thick), CFrame.new(inward * u.X * 0.06, 0, 0), colors.legs, fabric, "Cylinder")
			rounded(model, thigh, "Knee", Vector3.new(u.X * thick * 0.88, u.X * thick * 0.88, u.Z * thick * 0.88), CFrame.new(inward * u.X * 0.06, -u.Y / 2, 0), colors.lowerLegs or colors.legs, fabric)
		end
		if shin then
			local l = shin.Size
			local thick = (build.leg or 0.52) * 0.8
			rounded(model, shin, "Shin", Vector3.new(l.X * thick, l.Y * 1.04, l.Z * thick), CFrame.new(inward * l.X * 0.06, 0, 0), colors.lowerLegs or colors.legs, fabric, "Cylinder")
		end
		if foot then
			local f = foot.Size
			attach(model, foot, "Shoe", Vector3.new(f.X * 0.4, f.Y * 0.9, f.Z * 0.95), CFrame.new(inward * f.X * 0.06, -f.Y * 0.05, -f.Z * 0.12), colors.shoes, Enum.Material.Leather)
			rounded(model, foot, "ShoeToe", Vector3.new(f.X * 0.4, f.Y * 0.9, f.Z * 0.4), CFrame.new(inward * f.X * 0.06, -f.Y * 0.05, -f.Z * 0.56), colors.shoes, Enum.Material.Leather)
		end
	end
end

-- Echtes Gesicht auf dem runden Kopf: Augen mit Lidern, Nase, Ohren, Lippen.
-- `look` = "woman" oder "man"
local function realFace(model, head, colors, look)
	local size = head.Size
	local hw, hh, hd = size.X * 0.39, size.Y * 0.5, size.Z * 0.44 -- Halbachsen der Kopfform
	local cy = 0.02
	local s = size.Y / 1.2
	-- wie weit vorne die Kopfoberfläche an dieser Stelle ist
	local function surface(x, y)
		local k = 1 - (x / hw) ^ 2 - ((y - cy) / hh) ^ 2
		return -hd * math.sqrt(math.max(k, 0.05))
	end
	local function piece(name, partSize, x, y, depth, color, material)
		return rounded(model, head, name, partSize, CFrame.new(x, y, surface(x, y) + depth), color, material)
	end
	local darker = colors.skin:Lerp(Color3.fromRGB(120, 80, 60), 0.18)
	local iris = colors.eyes or Color3.fromRGB(86, 64, 44)
	local eyeY = 0.07 * s
	for _, side in { -1, 1 } do
		local x = side * 0.17 * s
		piece("EyeWhite", Vector3.new(0.15 * s, 0.075 * s, 0.06), x, eyeY, 0.012, Color3.fromRGB(238, 234, 228))
		piece("Iris", Vector3.new(0.07 * s, 0.07 * s, 0.03), x, eyeY - 0.004, -0.008, iris)
		piece("Pupil", Vector3.new(0.032 * s, 0.032 * s, 0.02), x, eyeY - 0.004, -0.016, Color3.fromRGB(16, 12, 10))
		piece("EyeShine", Vector3.new(0.014 * s, 0.014 * s, 0.01), x + 0.012 * s, eyeY + 0.012 * s, -0.022, Color3.fromRGB(250, 250, 250))
		piece("Eyelid", Vector3.new(0.17 * s, 0.04 * s, 0.07), x, eyeY + 0.042 * s, 0.006, darker)
		if look == "woman" then
			piece("Lashes", Vector3.new(0.16 * s, 0.012 * s, 0.05), x, eyeY + 0.03 * s, -0.004, Color3.fromRGB(40, 28, 24))
		end
		local brow = piece("Brow", Vector3.new(0.18 * s, (look == "man" and 0.04 or 0.026) * s, 0.05), x, eyeY + 0.12 * s, 0.004, colors.brows or colors.hair)
		brow.CFrame *= CFrame.Angles(0, 0, math.rad(side * (look == "man" and 4 or 7)))
		-- Ohren an den Seiten
		rounded(model, head, "Ear", Vector3.new(0.08 * s, 0.26 * s, 0.18 * s), CFrame.new(side * hw * 0.98, 0.02 * s, 0.04 * s), colors.skin)
		if look == "woman" then
			piece("Cheek", Vector3.new(0.12 * s, 0.07 * s, 0.03), side * 0.21 * s, -0.08 * s, 0.006, colors.skin:Lerp(Color3.fromRGB(214, 140, 130), 0.4))
		end
	end
	-- Nase: Rücken und Spitze
	piece("Nose", Vector3.new(0.09 * s, 0.22 * s, 0.14 * s), 0, -0.04 * s, 0.03, colors.skin)
	piece("NoseTip", Vector3.new(0.11 * s, 0.08 * s, 0.1 * s), 0, -0.13 * s, -0.025, darker)
	-- Mund
	local lips = look == "woman" and Color3.fromRGB(176, 96, 96) or colors.skin:Lerp(Color3.fromRGB(120, 60, 56), 0.45)
	piece("Lips", Vector3.new(0.2 * s, 0.045 * s, 0.05), 0, -0.25 * s, 0.006, lips)
	if look == "woman" then
		for _, side in { -1, 1 } do
			local corner = piece("MouthCorner", Vector3.new(0.05 * s, 0.022 * s, 0.04), side * 0.11 * s, -0.24 * s, 0.004, lips)
			corner.CFrame *= CFrame.Angles(0, 0, math.rad(side * 25))
		end
	end
	return hw, hh, hd
end

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
		skin = Color3.fromRGB(232, 194, 168),
		torso = Color3.fromRGB(58, 78, 112), -- dunkelblaues Kleid
		arms = Color3.fromRGB(122, 128, 112), -- graugrüne Strickjacke
		legs = Color3.fromRGB(58, 78, 112),
		lowerLegs = Color3.fromRGB(196, 160, 136), -- Strumpfhose
		shoes = Color3.fromRGB(70, 46, 34),
		hair = Color3.fromRGB(112, 76, 50),
		brows = Color3.fromRGB(96, 66, 46),
		eyes = Color3.fromRGB(70, 100, 80),
	}
	local model = newBody("MrsWagner", colors, { HeightScale = 1.0, WidthScale = 0.8, DepthScale = 0.85, HeadScale = 0.82 })
	if not model then
		return nil
	end
	smoothBody(model, colors, { shoulders = 0.72, waist = 0.58, hips = 0.8, arm = 0.3, leg = 0.44 })
	local head, torso, hips = model.Head, model.UpperTorso, model.LowerTorso
	local hw, hh, hd = realFace(model, head, colors, "woman")
	local hair, fabric = colors.hair, Enum.Material.Fabric
	-- Haare: oben voll, hinten locker hochgesteckt, an den Schläfen etwas länger
	rounded(model, head, "Hair", Vector3.new(hw * 2.08, hh * 1.24, hd * 2.06), CFrame.new(0, hh * 0.7, hd * 0.08), hair, fabric)
	rounded(model, head, "HairBack", Vector3.new(hw * 2.04, hh * 1.5, hd * 1.14), CFrame.new(0, hh * 0.2, hd * 0.52), hair, fabric)
	rounded(model, head, "HairBun", Vector3.new(hw * 1.0, hw * 0.85, hw * 0.85), CFrame.new(0, hh * 0.5, hd * 1.05), hair, fabric)
	-- Seitenscheitel: eine Haarsträhne fällt schräg in die Stirn
	local fringe = rounded(model, head, "HairFringe", Vector3.new(hw * 1.2, hh * 0.32, hd * 0.5), CFrame.new(hw * 0.25, hh * 0.72, -hd * 0.7), hair, fabric)
	fringe.CFrame *= CFrame.Angles(math.rad(-25), 0, math.rad(-14))
	-- Kleid: Rock bis unter die Knie, nach unten etwas weiter
	local h, t = hips.Size, torso.Size
	attach(model, hips, "SkirtTop", Vector3.new(h.X * 0.84, 0.9, h.Z * 0.64), CFrame.new(0, -0.25, 0), colors.torso, fabric)
	attach(model, hips, "Skirt", Vector3.new(h.X * 0.9, 1.5, h.Z * 0.7), CFrame.new(0, -1.4, 0), colors.torso, fabric)
	attach(model, hips, "SkirtHem", Vector3.new(h.X * 0.92, 0.1, h.Z * 0.72), CFrame.new(0, -2.12, 0), Color3.fromRGB(46, 62, 92), fabric)
	-- offene Strickjacke über dem Kleid: vorne sieht man das blaue Kleid
	attach(model, torso, "Cardigan", Vector3.new(t.X * 0.75, t.Y * 0.62, t.Z * 0.64), CFrame.new(0, t.Y * 0.18, 0), colors.arms, fabric)
	attach(model, torso, "CardiganLow", Vector3.new(t.X * 0.62, t.Y * 0.52, t.Z * 0.6), CFrame.new(0, -t.Y * 0.3, 0), colors.arms, fabric)
	attach(model, torso, "DressFront", Vector3.new(t.X * 0.24, t.Y * 1.08, 0.04), CFrame.new(0, -t.Y * 0.04, -t.Z * 0.32 - 0.01), colors.torso, fabric)
	rounded(model, torso, "Collar", Vector3.new(t.X * 0.3, 0.12, t.Z * 0.42), CFrame.new(0, t.Y * 0.5, -0.02), Color3.fromRGB(226, 220, 206), fabric)
	attach(model, torso, "Locket", Vector3.new(0.1, 0.14, 0.04), CFrame.new(0, t.Y * 0.22, -t.Z * 0.32 - 0.04), Color3.fromRGB(176, 146, 70), Enum.Material.Metal)

	holdCandle(model)

	model.Parent = parent
	return model
end

function Wagners.buildMr(parent)
	local colors = {
		skin = Color3.fromRGB(222, 182, 152),
		torso = Color3.fromRGB(128, 148, 176), -- sauberes, hellblaues Hemd
		arms = Color3.fromRGB(128, 148, 176),
		lowerArms = Color3.fromRGB(222, 182, 152), -- hochgekrempelte Ärmel
		legs = Color3.fromRGB(56, 50, 46), -- dunkle Stoffhose
		shoes = Color3.fromRGB(40, 28, 22),
		hair = Color3.fromRGB(78, 64, 54),
		beard = Color3.fromRGB(86, 70, 58),
		eyes = Color3.fromRGB(80, 96, 120),
	}
	local model = newBody("MrWagner", colors, { HeightScale = 1.1, WidthScale = 0.86, DepthScale = 0.9, HeadScale = 0.84 })
	if not model then
		return nil
	end
	smoothBody(model, colors, { shoulders = 0.86, waist = 0.74, hips = 0.76, arm = 0.36, leg = 0.52 })
	local head, torso, hips = model.Head, model.UpperTorso, model.LowerTorso
	local hw, hh, hd = realFace(model, head, colors, "man")
	local s = head.Size.Y / 1.2
	local fabric = Enum.Material.Fabric
	-- kurze Haare, an den Seiten kürzer
	rounded(model, head, "Hair", Vector3.new(hw * 2.04, hh * 1.06, hd * 2.04), CFrame.new(0, hh * 0.76, hd * 0.05), colors.hair, fabric)
	rounded(model, head, "HairBack", Vector3.new(hw * 2.02, hh * 1.2, hd * 1.06), CFrame.new(0, hh * 0.25, hd * 0.5), colors.hair, fabric)
	for _, side in { -1, 1 } do
		-- kurze Koteletten
		rounded(model, head, "Sideburn", Vector3.new(hw * 0.2, hh * 0.5, hd * 0.4), CFrame.new(side * hw * 0.95, hh * 0.05, -hd * 0.05), colors.hair, fabric)
	end
	-- kurz gestutzter Bart um Kinn und Wangen, Schnurrbart, der Mund liegt davor
	rounded(model, head, "Beard", Vector3.new(hw * 1.9, hh * 1.05, hd * 1.92), CFrame.new(0, -hh * 0.55, -hd * 0.03), colors.beard, fabric)
	rounded(model, head, "Mustache", Vector3.new(0.3 * s, 0.07 * s, 0.1 * s), CFrame.new(0, -0.19 * s, -hd * 0.93), colors.beard, fabric)
	rounded(model, head, "LipsOverBeard", Vector3.new(0.18 * s, 0.04 * s, 0.05), CFrame.new(0, -0.255 * s, -hd * 0.97), colors.skin:Lerp(Color3.fromRGB(120, 60, 56), 0.45))
	-- Hemdkragen, Knopfleiste, Hosenträger, Gürtel
	local t, h = torso.Size, hips.Size
	rounded(model, torso, "Collar", Vector3.new(t.X * 0.32, 0.14, t.Z * 0.46), CFrame.new(0, t.Y * 0.5, -0.02), Color3.fromRGB(150, 168, 194), fabric)
	attach(model, torso, "Placket", Vector3.new(0.1, t.Y * 1.05, 0.03), CFrame.new(0, -t.Y * 0.05, -t.Z * 0.3 - 0.015), Color3.fromRGB(112, 132, 160), fabric)
	local strap = Color3.fromRGB(52, 36, 28)
	for _, side in { -1, 1 } do
		-- Hosenträger vorne und hinten (über Brust und Bauch)
		for _, back in { -1, 1 } do
			attach(model, torso, "Suspender", Vector3.new(0.12, t.Y * 0.62, 0.03), CFrame.new(side * t.X * 0.2, t.Y * 0.18, back * (t.Z * 0.3 + 0.016)), strap, Enum.Material.Leather)
			attach(model, torso, "Suspender", Vector3.new(0.12, t.Y * 0.52, 0.03), CFrame.new(side * t.X * 0.2, -t.Y * 0.3, back * (t.Z * 0.28 + 0.016)), strap, Enum.Material.Leather)
		end
	end
	attach(model, hips, "Belt", Vector3.new(h.X * 0.78, 0.18, h.Z * 0.6), CFrame.new(0, h.Y * 0.4, 0), Color3.fromRGB(34, 26, 20), Enum.Material.Leather)
	attach(model, hips, "Buckle", Vector3.new(0.18, 0.14, 0.04), CFrame.new(0, h.Y * 0.4, -h.Z * 0.3 - 0.02), Color3.fromRGB(160, 140, 90), Enum.Material.Metal)
	-- Ärmelaufschläge und Armbanduhr
	for _, sideName in { "Left", "Right" } do
		local lower = model:FindFirstChild(sideName .. "LowerArm")
		if lower then
			local inward = sideName == "Left" and 1 or -1
			rounded(model, lower, "Cuff", Vector3.new(lower.Size.X * 0.4, 0.24, lower.Size.Z * 0.4), CFrame.new(inward * lower.Size.X * 0.4, lower.Size.Y / 2 - 0.12, 0), colors.torso, fabric, "Cylinder")
		end
	end
	local leftLower = model:FindFirstChild("LeftLowerArm")
	if leftLower then
		rounded(model, leftLower, "Watch", Vector3.new(leftLower.Size.X * 0.36, 0.14, leftLower.Size.Z * 0.36), CFrame.new(leftLower.Size.X * 0.4, -leftLower.Size.Y / 2 + 0.14, 0), Color3.fromRGB(60, 44, 32), Enum.Material.Leather, "Cylinder")
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
