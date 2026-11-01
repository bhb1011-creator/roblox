-- Das Biest: ein großes, abgemagertes Wesen mit Knochenschädel und Geweih, langen Armen
-- mit Klauen und nach hinten geknickten Beinen. Jeder Client baut sich seine eigene Kopie
-- und bewegt die Gelenke selbst (Laufen, Atmen, Kopf zucken). Wo es ist, bestimmt der Server.
local Parts = require(script.Parent.Parts)

local Beast = {}

local SKIN = Color3.fromRGB(30, 26, 24)
local SKIN_LIGHT = Color3.fromRGB(58, 50, 45)
local BONE = Color3.fromRGB(196, 186, 162)
local CLAW = Color3.fromRGB(40, 36, 32)
local EYES = Color3.fromRGB(255, 70, 50)

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
			Parent = model,
		})
		if shape then
			part.Shape = shape
		end
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

	-- Bewegliches Teil mit Gelenk an `jointPosition` (dreht sich um die Querachse des Biests)
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

	-- Knochen zwischen zwei Punkten
	local function bone(jointName, parentPart, from, to, thickness, color)
		local part = newPart(jointName .. "Bone", Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color or SKIN)
		return jointed(jointName, parentPart, from, part)
	end

	local root = newPart("Root", Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), SKIN)
	root.Transparency = 1
	model.PrimaryPart = root

	------------------------------------------------------------------ Körper
	local pelvis = newPart("Pelvis", Vector3.new(2, 1.2, 1.4), CFrame.new(0, 4.6, 0.4), SKIN)
	jointed("Waist", root, Vector3.new(0, 4.6, 0.4), pelvis)
	-- nach vorne gebeugter Oberkörper
	local torso = newPart("Torso", Vector3.new(2.3, 4, 1.5), CFrame.new(0, 6.3, -0.7) * CFrame.Angles(-0.7, 0, 0), SKIN)
	jointed("Spine", pelvis, Vector3.new(0, 5, 0.3), torso)
	-- Rippen und Wirbelsäule zeichnen sich unter der Haut ab
	for i = 0, 4 do
		attach("Rib", torso, Vector3.new(2.36, 0.16, 0.5), torso.CFrame * CFrame.new(0, 1.2 - i * 0.55, -0.55), SKIN_LIGHT)
	end
	for i = 0, 6 do
		attach("Vertebra", torso, Vector3.new(0.35, 0.35, 0.35), torso.CFrame * CFrame.new(0, 1.7 - i * 0.55, 0.78), SKIN_LIGHT)
	end

	------------------------------------------------------------------ Kopf: Schädel mit Geweih
	local neckPosition = Vector3.new(0, 7.9, -2.2)
	local neck = newPart("Neck", Vector3.new(0.7, 0.7, 1.4), CFrame.lookAt(neckPosition, neckPosition + Vector3.new(0, 0.3, -1)) * CFrame.new(0, 0, -0.5), SKIN)
	jointed("Neck", torso, neckPosition, neck)
	local skull = attach("Skull", neck, Vector3.new(1.25, 1.1, 2.4), CFrame.new(0, 8.25, -3.6), BONE)
	attach("Snout", neck, Vector3.new(0.9, 0.6, 1.2), CFrame.new(0, 8.05, -5.1), BONE)
	for _, x in { -0.32, 0.32 } do
		attach("EyeSocket", neck, Vector3.new(0.4, 0.34, 0.1), CFrame.new(x, 8.4, -4.82), Color3.fromRGB(8, 6, 6))
		attach("Eye", neck, Vector3.new(0.12, 0.12, 0.05), CFrame.new(x, 8.4, -4.86), EYES, Enum.Material.Neon)
		-- Geweih: Hauptstange mit Enden
		local base = Vector3.new(x * 1.6, 8.8, -3.3)
		local tip = base + Vector3.new(x * 4, 2.6, 0.8)
		attach("Antler", neck, Vector3.new(0.18, 0.18, (tip - base).Magnitude), CFrame.lookAt((base + tip) / 2, tip), BONE)
		for t, branch in { [0.4] = Vector3.new(0, 1.6, -0.6), [0.75] = Vector3.new(x * 0.6, 1.4, 0.5) } do
			local from = base:Lerp(tip, t)
			attach("AntlerTine", neck, Vector3.new(0.13, 0.13, branch.Magnitude), CFrame.lookAt(from + branch / 2, from + branch), BONE)
		end
	end
	skull.Name = "Skull"
	-- Unterkiefer mit Zähnen (kann sich öffnen)
	local jawPosition = Vector3.new(0, 7.75, -3.2)
	local jaw = newPart("Jaw", Vector3.new(0.85, 0.28, 2.2), CFrame.new(0, 7.62, -4.3), BONE)
	jointed("Jaw", neck, jawPosition, jaw)
	for i = 0, 5 do
		for _, x in { -0.3, 0.3 } do
			attach("Tooth", jaw, Vector3.new(0.08, 0.32, 0.08), CFrame.new(x, 7.85, -5.2 + i * 0.28), Color3.fromRGB(225, 215, 190))
			attach("Tooth", neck, Vector3.new(0.08, 0.3, 0.08), CFrame.new(x * 1.05, 7.75, -5.55 + i * 0.28), Color3.fromRGB(225, 215, 190))
		end
	end

	------------------------------------------------------------------ Arme mit Klauen
	for _, side in { -1, 1 } do
		local name = side < 0 and "Left" or "Right"
		local shoulder = Vector3.new(side * 1.45, 7.5, -1.9)
		local elbow = shoulder + Vector3.new(side * 0.3, -3, -0.4)
		local wrist = elbow + Vector3.new(0, -3.2, -0.3)
		local upper = bone(name .. "Shoulder", torso, shoulder, elbow, 0.55)
		local lower = bone(name .. "Elbow", upper, elbow, wrist, 0.45)
		attach("Hand", lower, Vector3.new(0.6, 0.35, 0.7), CFrame.new(wrist), SKIN)
		for i = -1, 1 do
			local from = wrist + Vector3.new(i * 0.2, -0.1, -0.25)
			local to = from + Vector3.new(i * 0.15, -1.1, -0.5)
			attach("Claw", lower, Vector3.new(0.09, 0.09, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), CLAW)
		end
	end

	------------------------------------------------------------------ Beine (nach hinten geknickt)
	for _, side in { -1, 1 } do
		local name = side < 0 and "Left" or "Right"
		local hip = Vector3.new(side * 0.75, 4.4, 0.4)
		local knee = Vector3.new(side * 0.8, 2.5, -0.6)
		local ankle = Vector3.new(side * 0.8, 0.6, 0.6)
		local thigh = bone(name .. "Hip", pelvis, hip, knee, 0.75)
		local shin = bone(name .. "Knee", thigh, knee, ankle, 0.5)
		local toes = ankle + Vector3.new(0, -0.45, -1.1)
		attach("Foot", shin, Vector3.new(0.5, 0.3, (toes - ankle).Magnitude), CFrame.lookAt((ankle + toes) / 2, toes), SKIN)
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
	set("LeftHip", CFrame.Angles(swing * 0.7, 0, 0))
	set("RightHip", CFrame.Angles(-swing * 0.7, 0, 0))
	set("LeftKnee", CFrame.Angles(-math.max(0, math.cos(phase)) * 0.6 * amount, 0, 0))
	set("RightKnee", CFrame.Angles(-math.max(0, -math.cos(phase)) * 0.6 * amount, 0, 0))
	set("LeftShoulder", CFrame.Angles(-swing * 0.9, 0, 0))
	set("RightShoulder", CFrame.Angles(swing * 0.9, 0, 0))
	set("LeftElbow", CFrame.Angles(math.max(0, swing) * 0.5, 0, 0))
	set("RightElbow", CFrame.Angles(math.max(0, -swing) * 0.5, 0, 0))
	set("Spine", CFrame.Angles(math.abs(swing) * 0.12 * amount, 0, 0))
	set("Neck", CFrame.Angles(0, 0, twitch or 0))
	set("Jaw", CFrame.Angles(-(jaw or 0) * 0.6, 0, 0))
end

return Beast
