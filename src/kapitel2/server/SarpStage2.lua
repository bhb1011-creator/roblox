-- Sarp, Stufe 2 ("Verändert", siehe docs/konzept/sarp.md): noch erkennbar der Mann aus
-- Kapitel 1 (olivgrüne Jacke, Jeans), aber größer und dürrer, die Haut grau mit Schimmel,
-- schwarzer Schleim läuft aus Augen und Mund, der Hals ist verdreht, die Jacke zerrissen,
-- aus den Händen wachsen lange Knochenfinger, um den Kopf schwirren Fliegen.
-- Verankert wie die Wagners; bewegt wird er vom Server (Night.lua).
local Wagners = require(script.Parent.Wagners)

local SarpStage2 = {}

local SKIN = Color3.fromRGB(118, 124, 104) -- grau-grünlich, tot
local MOLD = Color3.fromRGB(176, 186, 150)
local SLIME = Color3.fromRGB(8, 8, 8)
local JACKET = Color3.fromRGB(58, 60, 44)
local JACKET_DARK = Color3.fromRGB(40, 42, 30)
local JEANS = Color3.fromRGB(38, 42, 54)
local BONE = Color3.fromRGB(206, 198, 180)
local GLOW = Color3.fromRGB(200, 40, 24)

function SarpStage2.build(parent)
	local colors = { skin = SKIN, torso = JACKET, arms = JACKET, legs = JEANS, shoes = Color3.fromRGB(40, 30, 22), hands = SKIN }
	local model = Wagners.newBody("Sarp", colors, { HeightScale = 1.28, WidthScale = 0.8, DepthScale = 0.78, HeadScale = 0.95 })
	if not model then
		return nil
	end
	local attach = Wagners.attach
	local head, torso, hips = model.Head, model.UpperTorso, model.LowerTorso
	local size = head.Size
	local front = -size.Z / 2 - 0.005
	local s = size.Y / 1.2
	-- Gesicht: tiefe, schwarze Augenhöhlen mit einem schwachen roten Punkt, zu breiter Mund,
	-- schwarzer Schleim läuft herunter
	for _, side in { -1, 1 } do
		local x = side * 0.2 * s
		attach(model, head, "EyeHole", Vector3.new(0.24 * s, 0.2 * s, 0.03), CFrame.new(x, 0.1 * s, front), SLIME)
		local glow = attach(model, head, "EyeGlow", Vector3.new(0.06 * s, 0.06 * s, 0.02), CFrame.new(x, 0.1 * s, front - 0.02), GLOW, Enum.Material.Neon)
		glow.CastShadow = false
		attach(model, head, "SlimeTear", Vector3.new(0.06 * s, 0.42 * s, 0.02), CFrame.new(x + side * 0.02, -0.12 * s, front - 0.004), SLIME, Enum.Material.Glass)
		attach(model, head, "MoldPatch", Vector3.new(0.22 * s, 0.16 * s, 0.02), CFrame.new(side * 0.33 * s, 0.32 * s * (side > 0 and 1 or -0.4), front + 0.01) * CFrame.Angles(0, 0, math.rad(side * 20)), MOLD, Enum.Material.Sand)
	end
	attach(model, head, "Mouth", Vector3.new(0.62 * s, 0.1 * s, 0.03), CFrame.new(0, -0.28 * s, front), SLIME)
	for i = -2, 2 do
		attach(model, head, "Tooth", Vector3.new(0.05 * s, 0.07 * s, 0.02), CFrame.new(i * 0.11 * s, -0.25 * s, front - 0.01), BONE)
	end
	attach(model, head, "SlimeDrip", Vector3.new(0.08 * s, 0.5 * s, 0.03), CFrame.new(0.12 * s, -0.5 * s, front + 0.02), SLIME, Enum.Material.Glass)
	-- dünne, strähnige Haare (nur noch wenige)
	attach(model, head, "Hair", Vector3.new(size.X * 0.9, 0.16, size.Z * 0.7), CFrame.new(-0.08, size.Y / 2 - 0.04, 0.1), Color3.fromRGB(30, 24, 20), Enum.Material.Fabric)
	-- zerrissene Jacke: Fetzen hängen herunter, schwarze Flecken
	for i, x in { -0.55, -0.15, 0.3, 0.6 } do
		attach(model, hips, "JacketShred", Vector3.new(0.3, 0.9 + (i % 2) * 0.5, 0.05), CFrame.new(x, -0.5 - (i % 2) * 0.25, -hips.Size.Z / 2 - 0.03) * CFrame.Angles(0, 0, math.rad((i - 2.5) * 8)), JACKET_DARK, Enum.Material.Fabric)
	end
	attach(model, torso, "Rip", Vector3.new(0.5, 0.7, 0.03), CFrame.new(0.35, 0.1, -torso.Size.Z / 2 - 0.016), SKIN, Enum.Material.Sand)
	attach(model, torso, "Slime", Vector3.new(0.35, 1.1, 0.03), CFrame.new(-0.3, -0.1, -torso.Size.Z / 2 - 0.017), SLIME, Enum.Material.Glass)
	attach(model, torso, "MoldPatch", Vector3.new(0.6, 0.45, 0.03), CFrame.new(0.4, 0.5, torso.Size.Z / 2 + 0.016), MOLD, Enum.Material.Sand)
	-- Knochenfinger: lang, dünn, krumm
	for _, sideName in { "Left", "Right" } do
		local hand = model:FindFirstChild(sideName .. "Hand")
		if hand then
			for i = -1.5, 1.5 do
				attach(model, hand, "BoneFinger", Vector3.new(0.07, 1.25, 0.07), CFrame.new(i * 0.13, -hand.Size.Y / 2 - 0.55, -0.05) * CFrame.Angles(math.rad(-12), 0, math.rad(i * 3)), BONE)
				attach(model, hand, "BoneTip", Vector3.new(0.05, 0.4, 0.05), CFrame.new(i * 0.13, -hand.Size.Y / 2 - 1.3, -0.25) * CFrame.Angles(math.rad(-40), 0, 0), BONE)
			end
		end
	end
	-- Fliegen um den Kopf
	pcall(function()
		local flies = Instance.new("ParticleEmitter")
		flies.Name = "Flies"
		flies.Color = ColorSequence.new(Color3.fromRGB(10, 10, 10))
		flies.Size = NumberSequence.new(0.08)
		flies.Rate = 18
		flies.Lifetime = NumberRange.new(1, 2)
		flies.Speed = NumberRange.new(1, 3)
		flies.SpreadAngle = Vector2.new(180, 180)
		flies.LightEmission = 0
		flies.Parent = head
	end)
	-- schwaches rotes Licht im Gesicht
	local light = Instance.new("PointLight")
	light.Name = "SarpGlow"
	light.Color = GLOW
	light.Range = 6
	light.Brightness = 0.6
	light.Parent = head
	-- verdrehter Hals: Kopf schief und zur Seite gedreht
	local neck = head:FindFirstChild("Neck")
	if neck then
		pcall(function()
			neck.C0 *= CFrame.Angles(0, math.rad(18), math.rad(34))
		end)
		model:SetAttribute("NeckBase", true)
	end
	model.Parent = parent
	return model
end

-- Kopf drehen (z. B. zu einem Versteck schauen oder nach unten unter den Tisch):
-- yaw = links/rechts, pitch = runter (positiv), relativ zur schiefen Grundhaltung
function SarpStage2.look(model, yaw, pitch)
	local head = model and model:FindFirstChild("Head")
	local neck = head and head:FindFirstChild("Neck")
	if not neck then
		return
	end
	local base = neck:GetAttribute("Base")
	if not base then
		neck:SetAttribute("Base", neck.C0)
		base = neck.C0
	end
	pcall(function()
		neck.C0 = base * CFrame.Angles(-(pitch or 0), yaw or 0, 0)
	end)
end

return SarpStage2
