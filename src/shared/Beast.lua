-- Das Biest: der Fremde in seiner letzten, übernatürlichen Gestalt (Stufe 3 aus dem
-- Konzept). Riesig und dürr, ein langer ovaler Kopf mit einem Maul vom Scheitel bis zum
-- Kinn voller Zähne, rot glühende Flecken und Adern, verfaulter Körper mit Fetzen der
-- olivgrünen Jacke, sehr lange dünne Arme und Beine mit Knochenfingern.
-- Jeder Client baut sich seine eigene Kopie und bewegt die Gelenke selbst. Wo es ist,
-- bestimmt der Server.
local Parts = require(script.Parent.Parts)

local Beast = {}

local SKIN = Color3.fromRGB(50, 46, 52) -- graues, totes Fleisch
local ROT = Color3.fromRGB(34, 30, 30)
local BONE = Color3.fromRGB(200, 194, 184)
local HEAD = Color3.fromRGB(206, 200, 190)
local JACKET = Color3.fromRGB(58, 60, 44) -- dieselbe Jacke wie in Stufe 1
local JACKET_DARK = Color3.fromRGB(40, 42, 30)
local GLOW = Color3.fromRGB(220, 30, 20)
local SLIME = Color3.fromRGB(10, 10, 10)

-- Mitte des Kopfes in Ruhehaltung (für den Schreckmoment direkt vor der Kamera)
Beast.HEAD = Vector3.new(0, 14.6, -0.9)

-- Baut das Biest in Ruhehaltung (Füße bei y = 0, Blick nach -Z). Gibt das Model und die
-- Gelenke zurück: joints[name] = { motor = Motor6D, base = C0 in Ruhe }.
function Beast.build(parent)
	local model = Instance.new("Model")
	model.Name = "Beast"
	local joints = {}

	local function newPart(name, size, cframe, color, material, shape)
		local part = Parts.new("Part", {
			Name = name,
			Size = size,
			CFrame = cframe,
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Parent = model,
		})
		if shape then
			part.Shape = shape
		end
		return part
	end

	-- Ellipsoid (Kugel, in jede Richtung unterschiedlich groß)
	local function oval(part)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
		return part
	end

	-- Teil, das fest an einem anderen hängt
	local function attach(name, target, size, cframe, color, material, shape)
		local part = newPart(name, size, cframe, color, material, shape)
		part.Anchored = false
		part.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = target
		weld.Part1 = part
		weld.Parent = part
		return part
	end

	-- Beweglich angehängtes Teil, Gelenk bei `jointPosition`
	local function jointed(jointName, parentPart, jointPosition, part)
		part.Anchored = false
		part.Massless = true
		local jointFrame = CFrame.new(jointPosition)
		local motor = Instance.new("Motor6D")
		motor.Name = jointName
		motor.Part0 = parentPart
		motor.Part1 = part
		motor.C0 = parentPart.CFrame:Inverse() * jointFrame
		motor.C1 = part.CFrame:Inverse() * jointFrame
		motor.Parent = part
		joints[jointName] = { motor = motor, base = motor.C0 }
		return part
	end

	-- Dünner Strich zwischen zwei Punkten, fest an `target`
	local function strand(name, target, from, to, thickness, color, material)
		return attach(name, target, Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material)
	end

	-- Knochen zwischen zwei Punkten mit Gelenk am Anfang
	local function bone(jointName, parentPart, from, to, thickness, color)
		local part = newPart(jointName .. "Bone", Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color or SKIN)
		return jointed(jointName, parentPart, from, part)
	end

	-- Glühende Ader entlang eines Knochens (leicht versetzt, im Zickzack)
	local function vein(target, from, to, offset)
		local mid = (from + to) / 2 + offset
		strand("Vein", target, from + offset * 0.6, mid, 0.06, GLOW, Enum.Material.Neon)
		strand("Vein", target, mid, to + offset * 0.6, 0.06, GLOW, Enum.Material.Neon)
	end

	local root = newPart("Root", Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), SKIN)
	root.Transparency = 1
	model.PrimaryPart = root

	------------------------------------------------------------------ Körper
	local pelvis = newPart("Pelvis", Vector3.new(1.3, 0.9, 0.8), CFrame.new(0, 6.9, 0.2), ROT)
	jointed("Waist", root, Vector3.new(0, 6.9, 0.2), pelvis)
	local torso = newPart("Torso", Vector3.new(1.7, 4.4, 0.9), CFrame.new(0, 9.4, 0) * CFrame.Angles(-0.12, 0, 0), SKIN)
	jointed("Spine", pelvis, Vector3.new(0, 7.2, 0.2), torso)
	local front = -0.47
	-- Rippen, glühende Adern, Fetzen der alten Jacke und schwarzer Schleim
	for i = 0, 5 do
		attach("Rib", torso, Vector3.new(1.5 - i * 0.05, 0.12, 0.08), torso.CFrame * CFrame.new(0, 1.4 - i * 0.42, front), Color3.fromRGB(78, 68, 62))
	end
	for _, info in { { -0.35, 1.9, 0.1, -1.6 }, { 0.3, 1.7, -0.2, -1.9 }, { 0.05, 0.4, 0.45, -1.2 } } do
		local from = (torso.CFrame * CFrame.new(info[1], info[2], front - 0.03)).Position
		local to = (torso.CFrame * CFrame.new(info[3], info[4], front - 0.03)).Position
		vein(torso, from, to, (torso.CFrame.RightVector * 0.18))
	end
	local rng = Random.new(3)
	for i = 1, 9 do
		local side = i % 2 == 0 and 1 or -1
		local x = side * rng:NextNumber(0.55, 0.95)
		local length = rng:NextNumber(2.2, 3.8)
		local top = torso.CFrame * CFrame.new(x, rng:NextNumber(0.8, 2.1), rng:NextNumber(-0.5, 0.5))
		attach("JacketRag", torso, Vector3.new(rng:NextNumber(0.35, 0.6), length, 0.05), top * CFrame.new(0, -length / 2, 0) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(-0.5, 0.5), side * rng:NextNumber(0.02, 0.12)), i % 3 == 0 and JACKET_DARK or JACKET, Enum.Material.Fabric)
	end
	attach("CollarRag", torso, Vector3.new(1.9, 0.3, 1.05), torso.CFrame * CFrame.new(0, 2.15, 0), JACKET_DARK, Enum.Material.Fabric)
	for i = 1, 7 do
		local start = (torso.CFrame * CFrame.new(rng:NextNumber(-0.6, 0.6), -2.15, front + 0.1)).Position
		strand("Slime", torso, start, start - Vector3.new(0, rng:NextNumber(0.5, 1.4), 0), 0.07, SLIME, Enum.Material.Glass)
	end

	------------------------------------------------------------------ Hals und Kopf
	local neckBase = Vector3.new(0, 11.5, -0.15)
	local neckTop = Vector3.new(0, 13.1, -0.65)
	local neck = newPart("Neck", Vector3.new(0.34, 0.34, (neckTop - neckBase).Magnitude), CFrame.lookAt((neckBase + neckTop) / 2, neckTop), SKIN)
	jointed("Neck", torso, neckBase, neck)
	for _, x in { -0.25, 0.25 } do
		strand("NeckStrand", neck, neckBase + Vector3.new(x, 0, 0.05), neckTop + Vector3.new(x * 0.4, 0.3, 0), 0.07, ROT)
	end
	-- Langer, ovaler Kopf, leicht nach hinten geneigt
	local headFrame = CFrame.new(Beast.HEAD) * CFrame.Angles(0.15, 0, 0)
	oval(attach("Head", neck, Vector3.new(1.5, 3.2, 1.25), headFrame, HEAD))
	-- Das Maul: ein dunkler Spalt vom Scheitel bis zum Kinn
	oval(attach("Mouth", neck, Vector3.new(0.42, 2.75, 0.95), headFrame * CFrame.new(0, -0.05, -0.33), Color3.fromRGB(28, 4, 4)))
	-- Rote, glühende Flecken auf dem Kopf
	for _, spot in { { -0.45, 0.9 }, { 0.5, 0.4 }, { -0.5, -0.5 }, { 0.42, -0.95 }, { -0.2, 1.3 }, { 0.3, 1.1 } } do
		local y = spot[2]
		local depth = 0.625 * math.sqrt(math.max(0.05, 1 - (y / 1.6) ^ 2 - (spot[1] / 0.75) ^ 2))
		attach("GlowSpot", neck, Vector3.new(0.13, 0.13, 0.13), headFrame * CFrame.new(spot[1], y, -depth), GLOW, Enum.Material.Neon, Enum.PartType.Ball)
	end
	local glow = Instance.new("PointLight")
	glow.Color = GLOW
	glow.Range = 14
	glow.Brightness = 1.4
	glow.Parent = model:FindFirstChild("Head")
	-- Zähne an beiden Seiten des Spalts; die Seiten klappen auf, wenn es das Maul öffnet
	for _, side in { -1, 1 } do
		local name = side < 0 and "MouthLeft" or "MouthRight"
		local hinge = newPart(name, Vector3.new(0.1, 2.6, 0.1), headFrame * CFrame.new(side * 0.05, -0.05, -0.62), HEAD)
		hinge.Transparency = 1
		jointed(name, neck, (headFrame * CFrame.new(0, -0.05, -0.45)).Position, hinge)
		for i = 0, 10 do
			local y = -1.15 + i * 0.23
			local depth = 0.625 * math.sqrt(math.max(0.08, 1 - (y / 1.6) ^ 2))
			local tooth = headFrame * CFrame.new(side * 0.19, y, -depth + 0.06) * CFrame.Angles(0, 0, side * math.rad(90))
			attach("Tooth", hinge, Vector3.new(0.09, 0.26, 0.1), tooth * CFrame.new(0, 0.08, 0), Color3.fromRGB(230, 222, 200))
		end
	end

	------------------------------------------------------------------ Arme mit Knochenfingern
	for _, side in { -1, 1 } do
		local name = side < 0 and "Left" or "Right"
		local shoulder = Vector3.new(side * 1.0, 11.1, 0)
		local elbow = Vector3.new(side * 2.4, 7.6, -0.3)
		local wrist = Vector3.new(side * 2.2, 3.8, -0.45)
		local upper = bone(name .. "Shoulder", torso, shoulder, elbow, 0.32)
		local lower = bone(name .. "Elbow", upper, elbow, wrist, 0.28)
		vein(upper, shoulder + Vector3.new(0, 0, -0.17), elbow + Vector3.new(0, 0, -0.15), Vector3.new(side * 0.05, 0, -0.02))
		attach("Hand", lower, Vector3.new(0.4, 0.3, 0.45), CFrame.new(wrist), BONE)
		for i = -1.5, 1.5 do
			local from = wrist + Vector3.new(i * 0.12, -0.1, -0.15)
			local knuckle = from + Vector3.new(i * 0.1, -0.8, -0.2)
			local tip = knuckle + Vector3.new(i * 0.05, -0.7, 0.25)
			strand("Finger", lower, from, knuckle, 0.07, BONE)
			strand("Finger", lower, knuckle, tip, 0.06, BONE)
		end
		-- Knochensporne, die aus den Schultern stechen
		for i = 1, 2 do
			local from = shoulder + Vector3.new(side * 0.1, 0.2, 0.1 * i)
			local mid = from + Vector3.new(side * 0.35, 0.55, 0)
			strand("BoneSpur", torso, from, mid, 0.07, BONE)
			strand("BoneSpur", torso, mid, mid + Vector3.new(side * 0.35, 0.05 * i, 0), 0.05, BONE)
		end
	end

	------------------------------------------------------------------ Lange, dünne Beine
	for _, side in { -1, 1 } do
		local name = side < 0 and "Left" or "Right"
		local hip = Vector3.new(side * 0.5, 6.7, 0.2)
		local knee = Vector3.new(side * 1.05, 3.4, -0.45)
		local ankle = Vector3.new(side * 0.9, 0.45, 0.25)
		local thigh = bone(name .. "Hip", pelvis, hip, knee, 0.4)
		local shin = bone(name .. "Knee", thigh, knee, ankle, 0.32)
		vein(shin, knee + Vector3.new(0, 0, -0.17), ankle + Vector3.new(0, 0.3, -0.15), Vector3.new(side * 0.04, 0, -0.02))
		for i = -1, 1 do
			local toe = ankle + Vector3.new(i * 0.18, -0.35, -0.9)
			strand("Toe", shin, ankle, toe, 0.09, ROT)
			strand("ToeClaw", shin, toe, toe + Vector3.new(i * 0.05, -0.08, -0.35), 0.05, BONE)
		end
	end

	model.WorldPivot = CFrame.new()
	model.Parent = parent
	return model, joints
end

-- Gelenke für einen Moment der Bewegung setzen.
-- phase: Laufphase (Bogenmaß), amount: 0 = stehen, 1 = rennen, jaw: 0..1 Maul offen
function Beast.pose(joints, phase, amount, jaw, twitch)
	local function set(name, angles)
		local joint = joints[name]
		if joint then
			joint.motor.C0 = joint.base * angles
		end
	end
	local swing = math.sin(phase) * amount
	set("LeftHip", CFrame.Angles(swing * 0.55, 0, 0))
	set("RightHip", CFrame.Angles(-swing * 0.55, 0, 0))
	set("LeftKnee", CFrame.Angles(-math.max(0, math.cos(phase)) * 0.7 * amount, 0, 0))
	set("RightKnee", CFrame.Angles(-math.max(0, -math.cos(phase)) * 0.7 * amount, 0, 0))
	set("LeftShoulder", CFrame.Angles(-swing * 0.7, 0, 0))
	set("RightShoulder", CFrame.Angles(swing * 0.7, 0, 0))
	set("LeftElbow", CFrame.Angles(math.max(0, swing) * 0.4, 0, 0))
	set("RightElbow", CFrame.Angles(math.max(0, -swing) * 0.4, 0, 0))
	set("Spine", CFrame.Angles(math.abs(swing) * 0.1 + 0.15 * amount, 0, 0))
	set("Neck", CFrame.Angles(0, 0, twitch or 0))
	local open = (jaw or 0) * 0.9
	set("MouthLeft", CFrame.Angles(0, open, 0))
	set("MouthRight", CFrame.Angles(0, -open, 0))
end

return Beast
