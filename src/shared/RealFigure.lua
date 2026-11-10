-- Echte KI-Figuren (aus Roblox Studio, z. B. Sarp und das Biest) fürs Spiel vorbereiten.
-- Sie liegen als Modelldateien in assets/sarp und landen über Rojo in ReplicatedStorage.Sarp.
--
--   RealFigure.source(name)                 -> Vorlage oder nil (dann die alte Figur bauen)
--   RealFigure.prepare(source, options)     -> model, joints
--     options.height  = gewünschte Größe in Studs
--     options.keepRig = true: Gelenke so lassen (für Figuren mit Roblox-Animationen, z. B. Sarp
--                       in Kapitel 1), sonst werden sie zu Motor6D (für eigene Bewegungen)
--     options.relaxArms = Arme aus der T-Haltung nach unten (Standard: ja)
--     options.anchor  = HumanoidRootPart verankern (Standard: ja)
--   joints[name] = { motor = Motor6D, base = C0 in Ruhe }  (Namen wie bei Roblox: Neck, Waist,
--   LeftShoulder, LeftElbow, LeftHip, LeftKnee, ... und "Spine" = Waist)
-- Das Modell steht mit den Füßen auf y = 0 seines WorldPivot und schaut nach -Z.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RealFigure = {}

local JOINTS = {
	{ "Head", "Neck" },
	{ "UpperTorso", "Waist" },
	{ "LowerTorso", "Root" },
	{ "LeftUpperArm", "LeftShoulder" },
	{ "RightUpperArm", "RightShoulder" },
	{ "LeftLowerArm", "LeftElbow" },
	{ "RightLowerArm", "RightElbow" },
	{ "LeftHand", "LeftWrist" },
	{ "RightHand", "RightWrist" },
	{ "LeftUpperLeg", "LeftHip" },
	{ "RightUpperLeg", "RightHip" },
	{ "LeftLowerLeg", "LeftKnee" },
	{ "RightLowerLeg", "RightKnee" },
	{ "LeftFoot", "LeftAnkle" },
	{ "RightFoot", "RightAnkle" },
}

function RealFigure.source(name, folderName)
	local folder = ReplicatedStorage:FindFirstChild(folderName or "Sarp")
	local source = folder and folder:FindFirstChild(name)
	if source and source:IsA("Model") and source:FindFirstChildOfClass("Humanoid") and source:FindFirstChild("HumanoidRootPart") then
		return source
	end
	return nil
end

-- Gelenk (AnimationConstraint an Knochen) durch ein gleichwertiges Motor6D ersetzen
local function convert(model, partName, jointName)
	local part = model:FindFirstChild(partName)
	local old = part and part:FindFirstChild(jointName)
	if not old then
		return nil
	end
	if old:IsA("Motor6D") then
		return old
	end
	local ok, joint = pcall(function()
		local a0, a1 = old.Attachment0, old.Attachment1
		local part0 = a0:FindFirstAncestorWhichIsA("BasePart")
		local part1 = a1:FindFirstAncestorWhichIsA("BasePart")
		local motor = Instance.new("Motor6D")
		motor.Name = jointName
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = part0.CFrame:ToObjectSpace(a0.WorldCFrame)
		motor.C1 = part1.CFrame:ToObjectSpace(a1.WorldCFrame)
		-- sonst baut der Humanoid das Gelenk neu und löst es wieder
		a0.Name ..= "Fixed"
		a1.Name ..= "Fixed"
		return motor
	end)
	if not ok then
		warn("RealFigure: Gelenk nicht umgebaut:", partName, jointName, joint)
		return nil
	end
	old:Destroy()
	joint.Parent = part
	return joint
end

-- Arme aus der T-/A-Haltung locker nach unten hängen lassen
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
			local wanted = (-root.CFrame.UpVector + outward * 0.15).Unit
			local axis = current:Cross(wanted)
			if axis.Magnitude > 1e-3 then
				local angle = math.acos(math.clamp(current:Dot(wanted), -1, 1))
				local turn = CFrame.fromAxisAngle(axis.Unit, angle)
				joint.C0 = joint.Part0.CFrame:ToObjectSpace(CFrame.new(pivot.Position) * turn * (pivot - pivot.Position))
				model:SetAttribute(side .. "ArmRelax", turn:Inverse())
			end
		end
	end
end

local function bounds(model, root)
	local lowest, highest = math.huge, -math.huge
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= root and part.Transparency < 1 then
			lowest = math.min(lowest, part.Position.Y - part.Size.Y / 2)
			highest = math.max(highest, part.Position.Y + part.Size.Y / 2)
		end
	end
	return lowest, highest
end

function RealFigure.prepare(source, options)
	options = options or {}
	local model = source:Clone()
	for _, item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") then
			item:Destroy()
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	model.PrimaryPart = root
	model:PivotTo(CFrame.new(root.Position))
	if options.height then
		local low, high = bounds(model, root)
		if high > low then
			pcall(function()
				model:ScaleTo(model:GetScale() * options.height / (high - low))
			end)
		end
	end
	local joints = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = part == root and options.anchor ~= false
			part.CanCollide = false
			part.CanTouch = false
		elseif not options.keepRig and part:IsA("BallSocketConstraint") then
			part:Destroy()
		end
	end
	if not options.keepRig then
		pcall(function()
			humanoid.EvaluateStateMachine = false
		end)
		for _, info in JOINTS do
			local motor = convert(model, info[1], info[2])
			if motor then
				joints[info[2]] = { motor = motor, base = motor.C0 }
			end
		end
		if options.relaxArms ~= false then
			relaxArms(model)
			for _, name in { "LeftShoulder", "RightShoulder" } do
				if joints[name] then
					joints[name].base = joints[name].motor.C0
				end
			end
		end
		joints.Spine = joints.Waist
	end
	-- Füße auf y = 0 des Pivots
	local lowest = bounds(model, root)
	model:SetAttribute("FootOffset", root.Position.Y - lowest)
	model.WorldPivot = CFrame.new(root.Position.X, lowest, root.Position.Z)
	model:SetAttribute("RealFigure", true)
	return model, joints
end

return RealFigure
