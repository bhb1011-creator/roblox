-- Der Fremde, Stufe 1: ein ganz normaler Mann. Kurze Haare, Kapuze unten,
-- olivgrüne Jacke, Jeans, Schlamm an den Schuhen. Komisch ist nur sein Verhalten.
-- Wird als Vorlage in ReplicatedStorage gelegt; der Client bewegt eine eigene Kopie.
local Players = game:GetService("Players")

local Stranger = {}

local SKIN = Color3.fromRGB(196, 160, 132)
local JACKET = Color3.fromRGB(58, 60, 44)
local JEANS = Color3.fromRGB(42, 48, 66)
local SHOES = Color3.fromRGB(52, 38, 28)
local HAIR = Color3.fromRGB(42, 30, 22)

local function weldTo(part, target)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = target
	weld.Part1 = part
	weld.Parent = part
end

-- Zusätzliches Teil, das an einem Körperteil festgemacht wird
local function attach(model, bodyPart, name, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = bodyPart.CFrame * offset
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
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

function Stranger.build(parent)
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = SKIN
	description.TorsoColor = JACKET
	description.LeftArmColor = JACKET
	description.RightArmColor = JACKET
	description.LeftLegColor = JEANS
	description.RightLegColor = JEANS

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn("Der Fremde konnte nicht erstellt werden:", model)
		return nil
	end
	model.Name = "Stranger"

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.WalkSpeed = 7 -- langsam, fast schleichend

	-- Hände in Hautfarbe, Schuhe dunkelbraun mit Schlamm
	for _, name in { "LeftHand", "RightHand" } do
		local hand = model:FindFirstChild(name)
		if hand then
			hand.Color = SKIN
		end
	end
	for _, name in { "LeftFoot", "RightFoot" } do
		local foot = model:FindFirstChild(name)
		if foot then
			foot.Color = SHOES
			attach(model, foot, "Mud", foot.Size + Vector3.new(0.04, -0.2, 0.04), CFrame.new(0, -0.12, 0), Color3.fromRGB(70, 52, 36), Enum.Material.Ground)
		end
	end

	local head = model:FindFirstChild("Head")
	local torso = model:FindFirstChild("UpperTorso")
	if head then
		local size = head.Size
		local front, top = -size.Z / 2 - 0.005, size.Y / 2
		-- Kurze Haare
		attach(model, head, "Hair", Vector3.new(size.X + 0.05, 0.35, size.Z + 0.05), CFrame.new(0, top - 0.1, 0.05), HAIR, Enum.Material.Fabric)
		attach(model, head, "HairBack", Vector3.new(size.X + 0.05, size.Y * 0.55, 0.3), CFrame.new(0, top * 0.35, size.Z / 2 - 0.05), HAIR, Enum.Material.Fabric)
		-- Normales Gesicht: Augen, die einen anstarren, ein leichtes Lächeln
		local face = head:FindFirstChildOfClass("Decal")
		if face then
			face:Destroy()
		end
		for _, x in { -0.2, 0.2 } do
			attach(model, head, "EyeWhite", Vector3.new(0.2, 0.12, 0.02), CFrame.new(x, 0.12, front), Color3.fromRGB(235, 230, 220))
			attach(model, head, "Pupil", Vector3.new(0.08, 0.08, 0.02), CFrame.new(x, 0.12, front - 0.015), Color3.fromRGB(25, 20, 18))
			attach(model, head, "Brow", Vector3.new(0.26, 0.05, 0.02), CFrame.new(x, 0.3, front), HAIR)
			attach(model, head, "EyeShadow", Vector3.new(0.22, 0.05, 0.02), CFrame.new(x, 0.02, front), Color3.fromRGB(150, 112, 96))
		end
		attach(model, head, "Mouth", Vector3.new(0.36, 0.04, 0.02), CFrame.new(0, -0.27, front), Color3.fromRGB(120, 70, 60))
		for _, x in { -0.2, 0.2 } do
			attach(model, head, "MouthCorner", Vector3.new(0.06, 0.04, 0.02), CFrame.new(x, -0.25, front), Color3.fromRGB(120, 70, 60))
		end
	end
	if torso then
		local chest = -torso.Size.Z / 2 - 0.01
		-- Kapuze hängt im Nacken, Reißverschluss und Taschen an der Jacke
		attach(model, torso, "Hood", Vector3.new(1.6, 0.5, 0.6), CFrame.new(0, 0.75, 0.45), Color3.fromRGB(50, 52, 38), Enum.Material.Fabric)
		attach(model, torso, "Collar", Vector3.new(1.3, 0.25, 1.05), CFrame.new(0, 0.82, 0), JACKET, Enum.Material.Fabric)
		attach(model, torso, "Zipper", Vector3.new(0.06, 1.5, 0.02), CFrame.new(0, 0, chest), Color3.fromRGB(30, 30, 28), Enum.Material.Metal)
		for _, x in { -0.5, 0.5 } do
			attach(model, torso, "Pocket", Vector3.new(0.45, 0.3, 0.02), CFrame.new(x, -0.45, chest), Color3.fromRGB(48, 50, 36), Enum.Material.Fabric)
		end
	end
	local sleeve = model:FindFirstChild("RightLowerArm")
	if sleeve then
		-- dunkler Fleck am Ärmel
		attach(model, sleeve, "Stain", Vector3.new(0.3, 0.35, 0.02), CFrame.new(0.1, -0.15, -sleeve.Size.Z / 2 - 0.01), Color3.fromRGB(35, 18, 14))
	end

	model.Parent = parent
	return model
end

return Stranger
