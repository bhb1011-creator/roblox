-- Skins für die KI-Figuren (Spieler, Familie Wagner, Sarp). Ein Skin ist ein Rezept, das eine
-- KOPIE der echten Figur verändert: Material/Farbe der Kleidungsteile, dazu angeschweißte Teile
-- (Krone, Umhang, Ketten, Krawatte …) und Effekte (Glitzern, Rauch, Licht).
-- So behalten die Figuren ihre Gelenke und Animationen.
--
--   Skins.apply(model, skinId, options) -> true/false
--     model   = vorbereitete Figur (z. B. aus RealFigure.prepare), schaut nach -Z
--     options.tie      = Krawatte am Anzug (Männer)
--     options.barefoot = Füße bleiben Haut (Lucy, Tommy)
--
-- Hinweis: SurfaceAppearance-Texturen kann ein Spielskript nicht neu setzen, nur entfernen.
-- Darum nutzen die Rezepte Materialien (Metall, Samt, Glas). Bessere KI-Texturen können später
-- als eigene Figur-Dateien dazukommen (der Textur-/Avatar-Generator lief am 11.11. nicht).
local Skins = {}

local M = Enum.Material

local CLOTHES = {
	"UpperTorso",
	"LowerTorso",
	"LeftUpperArm",
	"RightUpperArm",
	"LeftLowerArm",
	"RightLowerArm",
	"LeftUpperLeg",
	"RightUpperLeg",
	"LeftLowerLeg",
	"RightLowerLeg",
}
local FEET = { "LeftFoot", "RightFoot" }

local function bodyPart(model, name)
	local found = model:FindFirstChild(name)
	if found and found:IsA("BasePart") then
		return found
	end
	return nil
end

-- Kleidungsteile neu einfärben (Textur weg, Material + Farbe)
local function recolor(model, names, color, material, reflectance, transparency)
	for _, name in names do
		local part = bodyPart(model, name)
		if part then
			local surface = part:FindFirstChildOfClass("SurfaceAppearance")
			if surface then
				surface:Destroy()
			end
			if part:IsA("MeshPart") then
				part.TextureID = ""
			end
			part.Material = material
			part.Color = color
			part.Reflectance = reflectance or 0
			if transparency then
				part.Transparency = transparency
			end
		end
	end
end

-- Teil an ein Körperteil schweißen (`offset` relativ zum Körperteil)
local function attach(model, toName, name, size, offset, color, material, extra)
	local to = bodyPart(model, toName)
	if not to then
		return nil
	end
	local part = Instance.new("Part")
	part.Name = "Skin_" .. name
	part.Size = size
	part.CFrame = to.CFrame * offset
	part.Color = color
	part.Material = material or M.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = math.max(size.X, size.Y, size.Z) >= 1
	for key, value in extra or {} do
		part[key] = value
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = to
	weld.Part1 = part
	weld.Parent = part
	part.Parent = model
	return part
end

local function sparkle(part, color, rate)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SkinSparkle"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Rate = rate or 4
	emitter.Speed = NumberRange.new(0.2, 0.6)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = part
	return emitter
end

local function smoke(part, color, rate, size)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SkinSmoke"
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightInfluence = 0.3
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.6, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.6), NumberSequenceKeypoint.new(1, size * 1.6) })
	emitter.Lifetime = NumberRange.new(1.4, 2.4)
	emitter.Rate = rate
	emitter.Speed = NumberRange.new(0.4, 1.1)
	emitter.Acceleration = Vector3.new(0, 1.2, 0)
	emitter.RotSpeed = NumberRange.new(-30, 30)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.Parent = part
	return emitter
end

local function glow(part, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Name = "SkinGlow"
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = part
	return light
end

-- Kopfgröße für Kronen usw.
local function headInfo(model)
	local head = bodyPart(model, "Head")
	if not head then
		return nil
	end
	return head, head.Size
end

-- Krone aus Zacken rund um den Kopf
local function crown(model, color, height, gemColor)
	local head, size = headInfo(model)
	if not head then
		return
	end
	local radius = math.max(size.X, size.Z) * 0.42
	local base = CFrame.new(0, size.Y * 0.42, 0)
	attach(model, "Head", "CrownBand", Vector3.new(0.12, radius * 2.15, radius * 2.15), base * CFrame.Angles(0, 0, math.rad(90)), color, M.Metal, { Shape = Enum.PartType.Cylinder, Reflectance = 0.3, Transparency = 0 })
	-- der Ring ist eine volle Scheibe: innen dunkel abdecken, damit er wie ein Reif wirkt
	for i = 0, 9 do
		local angle = i / 10 * math.pi * 2
		local spike = height * (i % 2 == 0 and 1 or 0.6)
		attach(model, "Head", "CrownSpike", Vector3.new(0.14, spike, 0.14), base * CFrame.Angles(0, angle, 0) * CFrame.new(0, spike / 2 + 0.05, -radius) * CFrame.Angles(math.rad(-8), 0, 0), color, M.Metal, { Reflectance = 0.3 })
		if gemColor and i % 2 == 0 then
			attach(model, "Head", "CrownGem", Vector3.new(0.12, 0.12, 0.12), base * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.12, -radius - 0.06), gemColor, M.Neon, { Shape = Enum.PartType.Ball })
		end
	end
end

-- Hals = Unterkante des Kopfes, als Versatz im Oberkörper (bei Sarp ragt der Oberkörper-Teil
-- wegen des schiefen Halses höher als der Kopfansatz)
local function neckOffset(model)
	local torso = bodyPart(model, "UpperTorso")
	local head = bodyPart(model, "Head")
	if not (torso and head) then
		return nil
	end
	local neckWorld = head.Position - Vector3.new(0, head.Size.Y * 0.42, 0)
	local local_ = torso.CFrame:PointToObjectSpace(neckWorld)
	return torso, Vector3.new(0, math.min(local_.Y, torso.Size.Y * 0.45), 0)
end

-- Kette aus Gliedern um den Hals
local function neckChain(model, color)
	local torso, neck = neckOffset(model)
	if not torso then
		return
	end
	local size = torso.Size
	local rx, rz = size.X * 0.28, size.Z * 0.45
	for i = 0, 13 do
		local angle = i / 14 * math.pi * 2
		local x, z = math.sin(angle) * rx, -math.cos(angle) * rz
		local y = neck.Y - 0.1 - (1 + math.cos(angle)) * 0.14 -- vorne tiefer
		attach(model, "UpperTorso", "ChainLink", Vector3.new(0.05, 0.14, 0.09), CFrame.new(x, y, z) * CFrame.Angles(0, -angle, 0) * CFrame.Angles(0, 0, i % 2 == 0 and 0 or math.rad(90)), color, M.Metal, { Reflectance = 0.35 })
	end
	attach(model, "UpperTorso", "ChainPendant", Vector3.new(0.05, 0.3, 0.3), CFrame.new(0, neck.Y - 0.6, -rz - 0.05) * CFrame.Angles(0, math.rad(90), 0), color, M.Metal, { Shape = Enum.PartType.Cylinder, Reflectance = 0.35 })
end

-- Krawatte und Hemdkragen vorne auf der Brust
local function tie(model, tieColor, shirtColor)
	local torso = bodyPart(model, "UpperTorso")
	if not torso then
		return
	end
	local size = torso.Size
	local _, neck = neckOffset(model)
	local top = neck and neck.Y or size.Y * 0.45 -- Kragen sitzt am Hals
	local front = -size.Z / 2 - 0.02
	attach(model, "UpperTorso", "Shirt", Vector3.new(size.X * 0.22, size.Y * 0.55, 0.04), CFrame.new(0, top - size.Y * 0.3, front), shirtColor, M.Fabric)
	attach(model, "UpperTorso", "Tie", Vector3.new(size.X * 0.08, size.Y * 0.5, 0.05), CFrame.new(0, top - size.Y * 0.32, front - 0.02), tieColor, M.Fabric)
	attach(model, "UpperTorso", "TieKnot", Vector3.new(size.X * 0.1, size.Y * 0.08, 0.07), CFrame.new(0, top - size.Y * 0.07, front - 0.03), tieColor, M.Fabric)
end

-- Umhang hinten an den Schultern (zwei Bahnen, leicht nach außen)
local function cape(model, color, trimColor, length)
	local torso = bodyPart(model, "UpperTorso")
	if not torso then
		return
	end
	local size = torso.Size
	local back = size.Z / 2 + 0.06
	local _, neck = neckOffset(model)
	local top = neck and math.min(size.Y * 0.45, neck.Y + 0.1) or size.Y * 0.45
	-- bis kurz über die Füße (gemessen an der Figur), sonst die angegebene Länge
	local foot = bodyPart(model, "LeftFoot")
	if foot then
		local shoulderY = torso.Position.Y + top
		local footY = foot.Position.Y - foot.Size.Y / 2
		length = math.max(length, shoulderY - footY - 0.35)
	end
	for _, side in { -1, 1 } do
		local panel = CFrame.new(side * size.X * 0.24, top - length / 2, back) * CFrame.Angles(math.rad(6), side * math.rad(8), 0)
		attach(model, "UpperTorso", "Cape", Vector3.new(size.X * 0.55, length, 0.06), panel, color, M.Fabric)
		attach(model, "UpperTorso", "CapeTrim", Vector3.new(0.06, length, 0.08), panel * CFrame.new(side * size.X * 0.27, 0, 0), trimColor, M.Metal, { Reflectance = 0.25 })
	end
	attach(model, "UpperTorso", "CapeCollar", Vector3.new(size.X * 1.1, size.Y * 0.25, 0.1), CFrame.new(0, top + size.Y * 0.08, back - 0.02) * CFrame.Angles(math.rad(-15), 0, 0), color, M.Fabric)
end

-- Schulterstücke (Epauletten / Rüstung)
local function shoulders(model, color, fringe)
	for _, name in { "LeftUpperArm", "RightUpperArm" } do
		local arm = bodyPart(model, name)
		if arm then
			local size = arm.Size
			attach(model, name, "Shoulder", Vector3.new(size.X * 1.3, 0.14, size.Z * 1.3), CFrame.new(0, size.Y * 0.48, 0), color, M.Metal, { Reflectance = 0.3 })
			if fringe then
				for i = -2, 2 do
					attach(model, name, "Fringe", Vector3.new(0.05, 0.28, 0.05), CFrame.new(i * size.X * 0.12, size.Y * 0.35, -size.Z * 0.55), color, M.Metal)
				end
			end
		end
	end
end

local RECIPES = {}

-- Goldener Anzug (Golden Pack): Kleidung glänzendes Gold, Kopf und Hände bleiben, Glitzern
function RECIPES.GoldSuit(model, options)
	local gold = Color3.fromRGB(214, 170, 70)
	recolor(model, CLOTHES, gold, M.Metal, 0.28)
	if not options.barefoot then
		recolor(model, FEET, Color3.fromRGB(150, 112, 40), M.Metal, 0.35)
	end
	if options.tie then
		tie(model, Color3.fromRGB(40, 30, 10), Color3.fromRGB(245, 242, 235))
	end
	local torso = bodyPart(model, "UpperTorso")
	if torso then
		sparkle(torso, Color3.fromRGB(255, 220, 120), 5)
	end
end

-- Silberner Anzug (Spieler, 2500 Münzen / 249 R$)
function RECIPES.SilverSuit(model, options)
	recolor(model, CLOTHES, Color3.fromRGB(196, 199, 206), M.Metal, 0.3)
	if not options.barefoot then
		recolor(model, FEET, Color3.fromRGB(40, 40, 44), M.Leather, 0.1)
	end
	if options.tie then
		tie(model, Color3.fromRGB(30, 34, 46), Color3.fromRGB(245, 245, 248))
	end
	local torso = bodyPart(model, "UpperTorso")
	if torso then
		sparkle(torso, Color3.fromRGB(220, 230, 255), 3)
	end
end

-- Sarp VIP 1: „Gilded Horror“ – altes Gold, Dornenkrone, schwere Kette, rotes Glimmen
function RECIPES.GildedHorror(model)
	recolor(model, CLOTHES, Color3.fromRGB(170, 126, 46), M.Metal, 0.18)
	recolor(model, FEET, Color3.fromRGB(60, 44, 18), M.Metal, 0.1)
	crown(model, Color3.fromRGB(200, 155, 60), 0.55, Color3.fromRGB(200, 20, 20))
	neckChain(model, Color3.fromRGB(220, 175, 70))
	local head = bodyPart(model, "Head")
	if head then
		glow(head, Color3.fromRGB(255, 50, 30), 8, 1.2)
	end
	local torso = bodyPart(model, "UpperTorso")
	if torso then
		sparkle(torso, Color3.fromRGB(255, 200, 90), 3)
	end
end

-- Sarp VIP 2: „Crimson Count“ – Samtmantel in Blutrot, goldene Knöpfe und Epauletten, Umhang
function RECIPES.CrimsonCount(model)
	recolor(model, { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }, Color3.fromRGB(105, 8, 22), M.Fabric, 0)
	recolor(model, { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }, Color3.fromRGB(18, 14, 16), M.Fabric, 0)
	recolor(model, FEET, Color3.fromRGB(10, 10, 10), M.Leather, 0.2)
	local torso = bodyPart(model, "UpperTorso")
	if torso then
		local size = torso.Size
		for i = 0, 4 do
			attach(model, "UpperTorso", "Button", Vector3.new(0.1, 0.1, 0.1), CFrame.new(0, size.Y * (0.3 - i * 0.16), -size.Z / 2 - 0.03), Color3.fromRGB(220, 175, 70), M.Metal, { Shape = Enum.PartType.Ball, Reflectance = 0.3 })
		end
		attach(model, "UpperTorso", "Lace", Vector3.new(size.X * 0.25, size.Y * 0.2, 0.06), CFrame.new(0, size.Y * 0.38, -size.Z / 2 - 0.03), Color3.fromRGB(235, 230, 220), M.Fabric)
	end
	shoulders(model, Color3.fromRGB(220, 175, 70), true)
	cape(model, Color3.fromRGB(60, 4, 14), Color3.fromRGB(220, 175, 70), 4.2)
end

-- Sarp VIP 3: „Obsidian King“ – Körper aus schwarzem Glas, hohe Krone mit Rubinen, violette Aura
function RECIPES.ObsidianKing(model)
	recolor(model, CLOTHES, Color3.fromRGB(14, 10, 20), M.Glass, 0.35)
	recolor(model, FEET, Color3.fromRGB(14, 10, 20), M.Glass, 0.35)
	crown(model, Color3.fromRGB(225, 180, 75), 0.85, Color3.fromRGB(230, 20, 40))
	shoulders(model, Color3.fromRGB(225, 180, 75), false)
	cape(model, Color3.fromRGB(16, 12, 22), Color3.fromRGB(225, 180, 75), 4.6)
	local torso = bodyPart(model, "UpperTorso")
	if torso then
		glow(torso, Color3.fromRGB(150, 60, 255), 12, 1.0)
		sparkle(torso, Color3.fromRGB(170, 90, 255), 4)
	end
end

-- Shadow Sarp (einzeln, 399 R$ / 3500 Münzen) – schwarz wie ein Schatten, dunkler Rauch
function RECIPES.ShadowSarp(model)
	local black = Color3.fromRGB(6, 6, 8)
	recolor(model, CLOTHES, black, M.SmoothPlastic, 0)
	recolor(model, FEET, black, M.SmoothPlastic, 0)
	for _, name in { "UpperTorso", "LowerTorso", "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg" } do
		local part = bodyPart(model, name)
		if part then
			smoke(part, Color3.fromRGB(8, 8, 10), name:find("Torso") and 10 or 5, name:find("Torso") and 1.6 or 0.9)
		end
	end
	for _, name in { "LeftHand", "RightHand" } do
		recolor(model, { name }, black, M.SmoothPlastic, 0)
	end
	local head = bodyPart(model, "Head")
	if head then
		glow(head, Color3.fromRGB(200, 210, 255), 5, 0.6)
	end
end

function Skins.apply(model, skinId, options)
	local recipe = RECIPES[skinId]
	if not recipe then
		warn("Skins: unbekannter Skin " .. tostring(skinId))
		return false
	end
	local ok, err = pcall(recipe, model, options or {})
	if not ok then
		warn("Skins: " .. skinId .. " fehlgeschlagen: " .. tostring(err))
		return false
	end
	model:SetAttribute("Skin", skinId)
	return true
end

function Skins.has(skinId)
	return RECIPES[skinId] ~= nil
end

return Skins
