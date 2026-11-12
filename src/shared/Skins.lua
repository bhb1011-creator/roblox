-- Skins für die KI-Figuren (Spieler, Familie Wagner, Sarp). Ein Skin ist ein Rezept, das eine
-- KOPIE der echten Figur verändert: Material/Farbe der Kleidungsteile, dazu angeschweißte Teile
-- (Krone, Umhang, Ketten, Krawatte …) und Effekte (Glitzern, Rauch, Licht).
-- So behalten die Figuren ihre Gelenke und Animationen.
--
--   Skins.apply(model, skinId, options) -> true/false
--     model   = vorbereitete Figur (z. B. aus RealFigure.prepare), schaut nach -Z
--     options.tuxedo   = GoldSuit als goldener Smoking (Richard, Tommy, Spieler)
--     options.jewelry  = Perlenkette mit Anhänger (Mrs. Wagner, Lucy)
--     options.tie      = Krawatte am einfachen Goldanzug
--     options.barefoot = Füße bleiben Haut (Lucy)
--   Anzug, Gürtel, Schulterpanzer usw. messen die Körperform mit Strahlen: die Figur sollte dafür
--   schon im workspace stehen (sonst wird geschätzt).
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
local attachToPart
local function attach(model, toName, name, size, offset, color, material, extra)
	local to = bodyPart(model, toName)
	if not to then
		return nil
	end
	return attachToPart(model, to, name, size, offset, color, material, extra)
end

function attachToPart(model, to, name, size, offset, color, material, extra)
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

------------------------------------------------------------------ Messen an der echten Form
-- Die KI-Figuren sind Skinned Meshes: ihre Bauteil-Kästen passen nicht genau zur sichtbaren Form.
-- Darum messen Anzug, Gürtel usw. die Oberfläche mit Strahlen (geht nur, wenn die Figur im
-- workspace steht; sonst wird geschätzt).

local function rootOf(model)
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

local function bodyParts(model, names)
	local list = {}
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" and not child.Name:find("^Skin_") then
			if not names or table.find(names, child.Name) then
				table.insert(list, child)
			end
		end
	end
	return list
end

-- Strahl von vorne (x, y im Raum der Wurzel) -> Treffpunkt in Weltkoordinaten, Bauteil
local function frontHit(model, x, y, names)
	local root = rootOf(model)
	if not root or not model:IsDescendantOf(workspace) then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = bodyParts(model, names)
	local origin = root.CFrame * CFrame.new(x, y, -8)
	local result = workspace:Raycast(origin.Position, root.CFrame.LookVector * -16, params)
	if result then
		return result.Position, result.Instance
	end
	return nil
end

-- Strahl von oben (x, z im Raum der Wurzel)
local function topHit(model, x, z, names)
	local root = rootOf(model)
	if not root or not model:IsDescendantOf(workspace) then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = bodyParts(model, names)
	local origin = root.CFrame * CFrame.new(x, 12, z)
	local result = workspace:Raycast(origin.Position, root.CFrame.UpVector * -24, params)
	if result then
		return result.Position, result.Instance
	end
	return nil
end

-- Teil mit Welt-CFrame an ein Bauteil schweißen
local function attachWorld(model, to, name, size, worldCFrame, color, material, extra)
	return attachToPart(model, to, name, size, to.CFrame:ToObjectSpace(worldCFrame), color, material, extra)
end

-- Maße des Oberkörpers im Raum der Wurzel: Hals-Höhe, Taillen-Höhe, halbe Brustbreite
local TORSO = { "UpperTorso", "LowerTorso" }
local function torsoFrame(model)
	local root = rootOf(model)
	local head = bodyPart(model, "Head")
	local lower = bodyPart(model, "LowerTorso")
	if not (root and head and lower) then
		return nil
	end
	local rcf = root.CFrame
	local frame = {}
	frame.root = rcf
	frame.neckY = rcf:PointToObjectSpace(head.Position).Y - head.Size.Y * 0.42
	frame.waistY = rcf:PointToObjectSpace(lower.Position).Y + lower.Size.Y * 0.3
	frame.height = frame.neckY - frame.waistY
	frame.scale = frame.height / 1.67 -- 1 = Mr. Wagner
	local width = 0
	for x = 0.05, 2, 0.05 do
		local _, part = frontHit(model, x, frame.neckY - frame.height * 0.45, TORSO)
		local _, partLeft = frontHit(model, -x, frame.neckY - frame.height * 0.45, TORSO)
		if part and partLeft then
			width = x
		elseif width > 0 then
			break
		end
	end
	frame.measured = width > 0
	frame.width = width > 0 and width or frame.height * 0.27
	return frame
end

-- CFrame flach auf der Vorderseite des Oberkörpers bei (x, y), etwas davor; nil wenn kein Treffer
local function onFront(model, frame, x, y, lift)
	local position, part = frontHit(model, x, y, TORSO)
	if not position then
		-- Schätzung, wenn nicht messbar
		local torso = bodyPart(model, "UpperTorso")
		if not torso then
			return nil
		end
		position = frame.root * Vector3.new(x, y, -frame.height * 0.2)
		part = torso
	end
	local rotation = frame.root.Rotation
	return CFrame.new(position) * rotation * CFrame.new(0, 0, -(lift or 0.02)), part
end

-- flache Leiste zwischen zwei Punkten der Vorderseite (Revers, Gürtel)
local function frontStrip(model, frame, name, x1, y1, x2, y2, width, thickness, color, material, extra)
	local a, part = onFront(model, frame, x1, y1, thickness / 2 + 0.01)
	local b = onFront(model, frame, x2, y2, thickness / 2 + 0.01)
	if not (a and b) then
		return nil
	end
	local up = (b.Position - a.Position)
	local length = up.Magnitude
	if length < 0.01 then
		return nil
	end
	up = up.Unit
	local back = -frame.root.LookVector
	local right = up:Cross(back).Unit
	back = right:Cross(up).Unit
	local cf = CFrame.fromMatrix((a.Position + b.Position) / 2, right, up, back)
	return attachWorld(model, part, name, Vector3.new(width, length, thickness), cf, color, material, extra)
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
	-- Reif aus 20 Stücken (offen, keine volle Scheibe)
	local segment = 2 * math.pi * radius / 20 + 0.03
	for i = 0, 19 do
		local angle = i / 20 * math.pi * 2
		attach(model, "Head", "CrownBand", Vector3.new(segment, 0.16, 0.07), base * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -radius), color, M.Metal, { Reflectance = 0.3 })
	end
	for i = 0, 9 do
		local angle = i / 10 * math.pi * 2
		local spike = height * (i % 2 == 0 and 1 or 0.6)
		local spikeCFrame = base * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.05, -radius) * CFrame.Angles(math.rad(-8), 0, 0)
		attach(model, "Head", "CrownSpike", Vector3.new(0.08, spike, 0.08), spikeCFrame * CFrame.new(0, spike / 2, 0), color, M.Metal, { Reflectance = 0.3 })
		attach(model, "Head", "CrownTip", Vector3.new(0.13, 0.13, 0.13), spikeCFrame * CFrame.new(0, spike, 0), color, M.Metal, { Shape = Enum.PartType.Ball, Reflectance = 0.35 })
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

-- schwere Kette vorne über der Brust (von Schulter zu Schulter, in der Mitte tiefer),
-- gemessen an der echten Körperform
local function neckChain(model, color)
	local frame = torsoFrame(model)
	if not frame then
		return
	end
	local neck, h, w, s = frame.neckY, frame.height, frame.width, frame.scale
	local count = 17
	for i = 0, count - 1 do
		local t = i / (count - 1) * 2 - 1
		local x = t * w * 0.62
		local y = neck - h * (0.04 + 0.22 * (1 - t * t))
		local cf, part = onFront(model, frame, x, y, 0.05)
		if cf then
			attachWorld(model, part, "ChainLink", Vector3.new(0.16, 0.1, 0.05) * s, cf * CFrame.Angles(0, i % 2 == 0 and 0 or math.rad(90), math.atan(-2 * t * 0.22 * h / (w * 0.62))), color, M.Metal, { Reflectance = 0.35 })
		end
	end
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

-- Smoking-Details vorne: weißes Hemd im V, schwarze Satin-Revers, Fliege, goldene Knöpfe,
-- Einstecktuch. Die Jacke selbst ist die umgefärbte Kleidung.
local function tuxedo(model, colors)
	local frame = torsoFrame(model)
	if not frame then
		return
	end
	local neck, h, w, s = frame.neckY, frame.height, frame.width, frame.scale
	local shirt, satin, accent = colors.shirt, colors.satin, colors.accent
	-- Hemd im V-Ausschnitt (schmale Streifen, nach unten schmaler; die Revers decken die Kanten)
	for f = 0.03, 0.47, 0.044 do
		local cf, part = onFront(model, frame, 0, neck - h * f, 0.02)
		if cf then
			local half = w * (0.27 - (f - 0.04) / 0.46 * 0.24) + w * 0.03
			attachWorld(model, part, "Shirt", Vector3.new(half * 2, h * 0.05, 0.04), cf, shirt, M.SmoothPlastic)
		end
	end
	-- Hemdknöpfe
	for _, f in { 0.24, 0.34 } do
		local cf, part = onFront(model, frame, 0, neck - h * f, 0.045)
		if cf then
			attachWorld(model, part, "ShirtStud", Vector3.new(0.045, 0.045, 0.045) * s, cf, accent, M.Metal, { Shape = Enum.PartType.Ball, Reflectance = 0.3 })
		end
	end
	-- Revers links und rechts (glänzender Satin), am Rand des V
	for _, side in { -1, 1 } do
		frontStrip(model, frame, "Lapel", side * w * 0.36, neck - h * 0.04, side * w * 0.12, neck - h * 0.5, w * 0.2, 0.05, satin, M.SmoothPlastic)
		frontStrip(model, frame, "LapelEdge", side * w * 0.47, neck - h * 0.06, side * w * 0.22, neck - h * 0.5, 0.035 * s, 0.06, accent, M.Metal, { Reflectance = 0.3 })
	end
	-- Fliege
	local bow, bowPart = onFront(model, frame, 0, neck - h * 0.13, 0.09)
	if bow then
		attachWorld(model, bowPart, "BowKnot", Vector3.new(0.1, 0.1, 0.08) * s, bow, satin, M.SmoothPlastic)
		for _, side in { -1, 1 } do
			attachWorld(model, bowPart, "BowWing", Vector3.new(0.2, 0.15, 0.06) * s, bow * CFrame.new(side * 0.13 * s, 0, 0.01) * CFrame.Angles(0, 0, side * math.rad(14)), satin, M.SmoothPlastic)
		end
	end
	-- Jackenknöpfe unter dem V
	for _, f in { 0.6, 0.76 } do
		local cf, part = onFront(model, frame, 0, neck - h * f, 0.04)
		if cf then
			attachWorld(model, part, "Button", Vector3.new(0.08, 0.08, 0.08) * s, cf, accent, M.Metal, { Shape = Enum.PartType.Ball, Reflectance = 0.35 })
		end
	end
	-- Brusttasche mit Einstecktuch (linke Brust der Figur = -X)
	local pocket, pocketPart = onFront(model, frame, -w * 0.62, neck - h * 0.36, 0.03)
	if pocket then
		attachWorld(model, pocketPart, "Pocket", Vector3.new(0.24, 0.03, 0.04) * s, pocket, satin, M.SmoothPlastic)
		attachWorld(model, pocketPart, "PocketSquare", Vector3.new(0.1, 0.1, 0.03) * s, pocket * CFrame.new(0, 0.05 * s, 0.005) * CFrame.Angles(0, 0, math.rad(45)), shirt, M.SmoothPlastic)
	end
	-- goldene Anstecknadel am Revers (rechts)
	local pin, pinPart = onFront(model, frame, w * 0.42, neck - h * 0.24, 0.07)
	if pin then
		attachWorld(model, pinPart, "LapelPin", Vector3.new(0.09, 0.09, 0.03) * s, pin * CFrame.Angles(0, 0, math.rad(45)), accent, M.Metal, { Reflectance = 0.4 })
	end
end

-- Schmuck (Perlenkette mit goldenem Anhänger) für Mrs. Wagner und Lucy
local function necklace(model, pearlColor, goldColor)
	local frame = torsoFrame(model)
	if not frame then
		return
	end
	local neck, h, w, s = frame.neckY, frame.height, frame.width, frame.scale
	-- Perlen in einem Bogen vorne am Hals
	for i = -6, 6 do
		local t = i / 6
		local x = t * w * 0.42
		local y = neck - h * (0.05 + 0.16 * (1 - t * t))
		local cf, part = onFront(model, frame, x, y, 0.035 * s)
		if cf then
			attachWorld(model, part, "Pearl", Vector3.new(0.07, 0.07, 0.07) * s, cf, pearlColor, M.SmoothPlastic, { Shape = Enum.PartType.Ball, Reflectance = 0.25 })
		end
	end
	local cf, part = onFront(model, frame, 0, neck - h * 0.27, 0.04 * s)
	if cf then
		attachWorld(model, part, "Pendant", Vector3.new(0.14, 0.14, 0.04) * s, cf * CFrame.Angles(0, 0, math.rad(45)), goldColor, M.Metal, { Reflectance = 0.4 })
		attachWorld(model, part, "PendantGem", Vector3.new(0.07, 0.07, 0.07) * s, cf * CFrame.new(0, 0, -0.03), Color3.fromRGB(40, 120, 255), M.Neon, { Shape = Enum.PartType.Ball })
	end
end

-- Gürtel mit Schnalle vorne (folgt der Bauchform)
local function belt(model, color, buckleColor, gemColor)
	local frame = torsoFrame(model)
	if not frame then
		return
	end
	local y = frame.waistY + frame.height * 0.02
	local w, s = frame.width * 0.95, frame.scale
	local steps = 6
	for i = 0, steps - 1 do
		local x1 = -w + (2 * w) * i / steps
		local x2 = -w + (2 * w) * (i + 1) / steps
		frontStrip(model, frame, "Belt", x1, y, x2, y, 0.16 * s, 0.06, color, M.Metal, { Reflectance = 0.25 })
	end
	local cf, part = onFront(model, frame, 0, y, 0.07)
	if cf then
		attachWorld(model, part, "Buckle", Vector3.new(0.34, 0.26, 0.06) * s, cf, buckleColor, M.Metal, { Reflectance = 0.35 })
		if gemColor then
			attachWorld(model, part, "BuckleGem", Vector3.new(0.12, 0.12, 0.12) * s, cf * CFrame.new(0, 0, -0.04), gemColor, M.Neon, { Shape = Enum.PartType.Ball })
		end
	end
end

-- große Brosche / Medaillon mitten auf der Brust
local function medallion(model, color, gemColor, lightColor)
	local frame = torsoFrame(model)
	if not frame then
		return
	end
	local s = frame.scale
	local cf, part = onFront(model, frame, 0, frame.neckY - frame.height * 0.36, 0.05)
	if not cf then
		return
	end
	attachWorld(model, part, "Medallion", Vector3.new(0.06, 0.5 * s, 0.5 * s), cf * CFrame.Angles(0, math.rad(90), 0), color, M.Metal, { Shape = Enum.PartType.Cylinder, Reflectance = 0.35 })
	for i = 0, 7 do
		local angle = i / 8 * math.pi * 2
		attachWorld(model, part, "MedallionRay", Vector3.new(0.06, 0.2, 0.04) * s, cf * CFrame.Angles(0, 0, angle) * CFrame.new(0, 0.3 * s, -0.01), color, M.Metal, { Reflectance = 0.35 })
	end
	local gem = attachWorld(model, part, "MedallionGem", Vector3.new(0.2, 0.2, 0.2) * s, cf * CFrame.new(0, 0, -0.06), gemColor, M.Neon, { Shape = Enum.PartType.Ball })
	if gem and lightColor then
		glow(gem, lightColor, 5, 0.8)
	end
end

-- Schulterpanzer mit Dornen (oben auf den Schultern gemessen)
local function pauldrons(model, color, gemColor)
	local frame = torsoFrame(model)
	if not frame then
		return
	end
	local s = frame.scale
	for _, side in { -1, 1 } do
		local x = side * frame.width * 0.8
		local torso = bodyPart(model, "UpperTorso")
		local z = torso and frame.root:PointToObjectSpace(torso.Position).Z or 0
		local position, part = topHit(model, x, z, { "UpperTorso", "LeftUpperArm", "RightUpperArm" })
		if not position then
			local arm = bodyPart(model, side < 0 and "LeftUpperArm" or "RightUpperArm")
			if arm then
				position, part = arm.Position + Vector3.new(0, arm.Size.Y * 0.45, 0), arm
			end
		end
		if position then
			local base = CFrame.new(position) * frame.root.Rotation
			attachWorld(model, part, "Pauldron", Vector3.new(0.62, 0.42, 0.66) * s, base * CFrame.new(side * 0.06 * s, 0.02 * s, 0), color, M.Metal, { Shape = Enum.PartType.Ball, Reflectance = 0.3 })
			for i = -1, 1 do
				attachWorld(model, part, "PauldronSpike", Vector3.new(0.07, 0.42, 0.07) * s, base * CFrame.new(side * 0.12 * s, 0.32 * s, i * 0.17 * s) * CFrame.Angles(i * math.rad(-14), 0, side * math.rad(-24)), color, M.Metal, { Reflectance = 0.3 })
			end
			if gemColor then
				attachWorld(model, part, "PauldronGem", Vector3.new(0.12, 0.12, 0.12) * s, base * CFrame.new(side * 0.06 * s, 0.06 * s, -0.31 * s), gemColor, M.Neon, { Shape = Enum.PartType.Ball })
			end
		end
	end
end

-- glühende Augen vorne am Kopf (Lage gemessen an Sarp: 0,17 über der Kopfmitte, 0,1 seitlich;
-- skaliert mit der Kopfgröße), sitzen halb in der Oberfläche
local function glowingEyes(model, color)
	local root = rootOf(model)
	local head = bodyPart(model, "Head")
	if not (root and head) then
		return
	end
	local center = root.CFrame:PointToObjectSpace(head.Position)
	local k = head.Size.Y / 1.2
	for _, side in { -1, 1 } do
		local x, y = center.X + side * 0.1 * k, center.Y + 0.17 * k
		local position = frontHit(model, x, y, { "Head" })
		local cf = position and (CFrame.new(position) * root.CFrame.Rotation) or (root.CFrame * CFrame.new(x, y, center.Z - head.Size.Z * 0.36))
		local eye = attachWorld(model, head, "Eye", Vector3.new(0.085, 0.07, 0.085) * k, cf * CFrame.new(0, 0, 0.012), color, M.Neon, { Shape = Enum.PartType.Ball })
		if eye and side == 1 then
			glow(eye, color, 3, 1.2)
		end
	end
end

-- alle sichtbaren Körperteile (auch Kopf und Hände) einfärben
local function recolorAll(model, color, material, reflectance)
	for _, part in bodyParts(model) do
		recolor(model, { part.Name }, color, material, reflectance)
	end
	for _, item in model:GetDescendants() do
		if item:IsA("Decal") then
			item:Destroy()
		end
	end
end

local RECIPES = {}

local JACKET = { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }
local LEGS = { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }
-- Smoking: Jacke nur oben, Hose ab der Hüfte (sonst wirkt die goldene Hüfte wie eine Badehose)
local COAT = { "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }
local TROUSERS = { "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }

-- Goldener Anzug (Golden Pack). options.tuxedo = goldener Smoking (glitzernde Jacke, schwarze
-- Hose, Hemd, Fliege, Revers); options.jewelry = Perlenkette; options.barefoot = Füße bleiben
function RECIPES.GoldSuit(model, options)
	local gold = Color3.fromRGB(214, 170, 70)
	if options.tuxedo then
		recolor(model, COAT, gold, M.Metal, 0.22)
		recolor(model, TROUSERS, Color3.fromRGB(16, 15, 18), M.SmoothPlastic, 0)
		recolor(model, FEET, Color3.fromRGB(20, 17, 15), M.SmoothPlastic, 0)
		tuxedo(model, { shirt = Color3.fromRGB(246, 243, 236), satin = Color3.fromRGB(14, 13, 16), accent = Color3.fromRGB(235, 192, 90) })
	else
		recolor(model, CLOTHES, gold, M.Metal, 0.28)
		if not options.barefoot then
			recolor(model, FEET, Color3.fromRGB(150, 112, 40), M.Metal, 0.35)
		end
		if options.tie then
			tie(model, Color3.fromRGB(40, 30, 10), Color3.fromRGB(245, 242, 235))
		end
	end
	if options.jewelry then
		necklace(model, Color3.fromRGB(250, 246, 236), Color3.fromRGB(235, 192, 90))
	end
	local torso = bodyPart(model, "UpperTorso")
	if torso then
		sparkle(torso, Color3.fromRGB(255, 220, 120), 5)
	end
end

-- Silberner Anzug (Spieler, 2500 Münzen / 249 R$): silberner Smoking
function RECIPES.SilverSuit(model, options)
	recolor(model, COAT, Color3.fromRGB(196, 199, 206), M.Metal, 0.25)
	recolor(model, TROUSERS, Color3.fromRGB(26, 28, 34), M.SmoothPlastic, 0)
	recolor(model, FEET, Color3.fromRGB(20, 17, 15), M.SmoothPlastic, 0)
	tuxedo(model, { shirt = Color3.fromRGB(246, 246, 250), satin = Color3.fromRGB(18, 20, 28), accent = Color3.fromRGB(225, 230, 240) })
	local torso = bodyPart(model, "UpperTorso")
	if torso then
		sparkle(torso, Color3.fromRGB(220, 230, 255), 3)
	end
end

-- Sarp VIP 1: „Gilded Horror“ – altes Gold, Dornenkrone, Schulterpanzer mit Dornen, Medaillon
-- mit glühendem Rubin, schwere Kette, Rubin-Gürtel, rotes Glimmen und fallender Goldstaub
function RECIPES.GildedHorror(model)
	local antique = Color3.fromRGB(170, 126, 46)
	local bright = Color3.fromRGB(225, 180, 75)
	local ruby = Color3.fromRGB(210, 16, 22)
	recolor(model, JACKET, antique, M.Metal, 0.18)
	recolor(model, LEGS, Color3.fromRGB(120, 86, 30), M.Metal, 0.12)
	recolor(model, FEET, Color3.fromRGB(60, 44, 18), M.Metal, 0.1)
	recolor(model, { "LeftHand", "RightHand" }, Color3.fromRGB(70, 50, 20), M.Metal, 0.1)
	crown(model, bright, 0.65, ruby)
	neckChain(model, bright)
	pauldrons(model, bright, ruby)
	medallion(model, bright, ruby, Color3.fromRGB(255, 40, 30))
	belt(model, Color3.fromRGB(60, 40, 14), bright, ruby)
	local head = bodyPart(model, "Head")
	if head then
		glow(head, Color3.fromRGB(255, 50, 30), 9, 1.4)
	end
	local torso = bodyPart(model, "UpperTorso")
	if torso then
		sparkle(torso, Color3.fromRGB(255, 200, 90), 6)
		local dust = sparkle(torso, Color3.fromRGB(255, 210, 110), 8)
		dust.Name = "SkinGoldDust"
		dust.Acceleration = Vector3.new(0, -3, 0)
		dust.Lifetime = NumberRange.new(1.2, 2)
		dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(1, 0) })
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

-- Shadow Sarp (einzeln, 399 R$ / 3500 Münzen) – ganz schwarz wie ein Schatten (auch Kopf und
-- Hände), dunkler Rauch und glühende rote Augen
function RECIPES.ShadowSarp(model)
	local black = Color3.fromRGB(5, 5, 7)
	recolorAll(model, black, M.Slate, 0)
	for _, name in { "Head", "UpperTorso", "LowerTorso", "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg" } do
		local part = bodyPart(model, name)
		if part then
			local torso = name:find("Torso") ~= nil
			smoke(part, Color3.fromRGB(8, 8, 10), torso and 10 or (name == "Head" and 4 or 5), torso and 1.6 or 0.9)
		end
	end
	glowingEyes(model, Color3.fromRGB(255, 25, 20))
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
