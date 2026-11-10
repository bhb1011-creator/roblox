-- Eine detaillierte Kerze im Messing-Kerzenhalter (für die Kerze im eigenen Bild, die Kerze
-- an der Hand der Spieler und die von Mrs. Wagner).
--
--   CandleModel.build(parent, base, scale, options) -> info
--     base   = CFrame der Unterseite des Tellers (aufrecht)
--     scale  = Größe (1 = Kerze im eigenen Bild)
--     options.red      = rote Kerze (Flucht)
--     options.weldTo   = Teil, an dem alles festgeschweißt wird (Hand); sonst verankert
--   info.parts  = { { part, offset } } (für Kerzen, die jedes Bild neu gesetzt werden)
--   info.wax    = Wachs-Teile (zum Umfärben), info.flame = äußere Flamme (dort hängt das Licht),
--   info.flameParts = alle Flammen-Teile, info.flameOffset = Mitte der Flamme
local CandleModel = {}

local BRASS = Color3.fromRGB(156, 122, 62)
local BRASS_DARK = Color3.fromRGB(104, 80, 40)
local WAX = Color3.fromRGB(232, 222, 198)
local WAX_RED = Color3.fromRGB(112, 22, 20)
local WICK = Color3.fromRGB(30, 24, 20)

CandleModel.WAX = WAX
CandleModel.WAX_RED = WAX_RED
CandleModel.FLAME = Color3.fromRGB(255, 168, 72)
CandleModel.FLAME_RED = Color3.fromRGB(255, 60, 40)
CandleModel.CORE = Color3.fromRGB(255, 236, 190)
CandleModel.CORE_RED = Color3.fromRGB(255, 170, 120)

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- Zylinder liegen in Roblox auf der Seite

function CandleModel.build(parent, base, scale, options)
	options = options or {}
	local red = options.red
	local info = { parts = {}, wax = {}, flameParts = {} }

	local function piece(name, shape, size, offset, color, material, extra)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = shape
		part.Size = size * scale
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.CastShadow = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		local scaled = CFrame.new(offset.Position * scale) * offset.Rotation
		part.CFrame = base * scaled
		for property, value in extra or {} do
			part[property] = value
		end
		if options.weldTo then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = options.weldTo
			weld.Part1 = part
			weld.Parent = part
		else
			part.Anchored = true
		end
		part.Parent = parent
		table.insert(info.parts, { part = part, offset = scaled })
		return part
	end
	local function cylinder(name, height, diameter, y, color, material, extra)
		return piece(name, Enum.PartType.Cylinder, Vector3.new(height, diameter, diameter), CFrame.new(0, y, 0) * UPRIGHT, color, material, extra)
	end
	-- Ellipsoid (Kugel-Netz in einem Block, damit sie länglich sein kann)
	local function ellipsoid(name, size, offset, color, material, extra)
		local part = piece(name, Enum.PartType.Block, size, offset, color, material, extra)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
		return part
	end

	-- Teller mit erhöhtem Rand und vertiefter Mitte
	cylinder("CandleHolder", 0.05, 0.5, 0.025, BRASS, Enum.Material.Metal)
	cylinder("HolderRim", 0.03, 0.54, 0.06, BRASS_DARK, Enum.Material.Metal)
	cylinder("HolderDish", 0.032, 0.46, 0.062, BRASS, Enum.Material.Metal)
	-- Fingerring an der Seite (aus kleinen Stücken gebogen)
	local ringRadius, ringCenter = 0.075, Vector3.new(0.3, 0.075, 0)
	for k = 0, 7 do
		local angle = math.rad(-110 + k * 34)
		local position = ringCenter + Vector3.new(math.cos(angle) * ringRadius, math.sin(angle) * ringRadius, 0)
		piece("HolderRing", Enum.PartType.Cylinder, Vector3.new(0.05, 0.026, 0.026), CFrame.new(position) * CFrame.Angles(0, 0, angle + math.rad(90)), BRASS_DARK, Enum.Material.Metal)
	end
	-- Tülle, in der die Kerze steckt
	cylinder("HolderSocket", 0.13, 0.2, 0.135, BRASS, Enum.Material.Metal)
	cylinder("HolderLip", 0.025, 0.25, 0.2, BRASS_DARK, Enum.Material.Metal)

	-- Kerze: Schaft, leicht eingesunkene Oberseite, Wachstropfen
	local waxColor = red and WAX_RED or WAX
	local bottom, height = 0.21, 0.48
	table.insert(info.wax, cylinder("Candle", height, 0.15, bottom + height / 2, waxColor, Enum.Material.SmoothPlastic))
	table.insert(info.wax, cylinder("CandleTop", 0.02, 0.13, bottom + height + 0.002, waxColor:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.SmoothPlastic))
	for k, drip in { { angle = 20, length = 0.16 }, { angle = 145, length = 0.26 }, { angle = 260, length = 0.11 } } do
		local a = math.rad(drip.angle)
		local x, z = math.cos(a) * 0.073, math.sin(a) * 0.073
		local top = bottom + height - 0.01
		table.insert(info.wax, piece("WaxDrip", Enum.PartType.Cylinder, Vector3.new(drip.length, 0.032, 0.032), CFrame.new(x, top - drip.length / 2, z) * UPRIGHT, waxColor, Enum.Material.SmoothPlastic))
		table.insert(info.wax, piece("WaxDropEnd", Enum.PartType.Ball, Vector3.new(0.042, 0.042, 0.042), CFrame.new(x, top - drip.length, z), waxColor, Enum.Material.SmoothPlastic))
		if k == 2 then
			-- ein Tropfen ist bis auf den Teller gelaufen
			table.insert(info.wax, piece("WaxPuddle", Enum.PartType.Cylinder, Vector3.new(0.014, 0.09, 0.09), CFrame.new(0.13, 0.082, 0.07) * UPRIGHT, waxColor, Enum.Material.SmoothPlastic))
		end
	end

	-- Docht mit glühender Spitze
	local wickTop = bottom + height + 0.07
	piece("CandleWick", Enum.PartType.Cylinder, Vector3.new(0.075, 0.016, 0.016), CFrame.new(0, wickTop - 0.035, 0) * CFrame.Angles(0, 0, math.rad(84)), WICK, Enum.Material.SmoothPlastic)
	table.insert(info.flameParts, piece("WickEmber", Enum.PartType.Ball, Vector3.new(0.022, 0.022, 0.022), CFrame.new(0.004, wickTop, 0), Color3.fromRGB(255, 90, 40), Enum.Material.Neon))

	-- Flamme: blauer Fuß, heller Kern, orange Hülle (das Licht hängt an der Hülle)
	local flameColor = red and CandleModel.FLAME_RED or CandleModel.FLAME
	local coreColor = red and CandleModel.CORE_RED or CandleModel.CORE
	local flameCenter = wickTop + 0.09
	info.flameOffset = CFrame.new(0, flameCenter * scale, 0)
	local flame = ellipsoid("CandleFlame", Vector3.new(0.085, 0.21, 0.085), CFrame.new(0, flameCenter, 0), flameColor, Enum.Material.Neon, { Transparency = 0.15 })
	local core = ellipsoid("CandleFlameCore", Vector3.new(0.045, 0.11, 0.045), CFrame.new(0, flameCenter - 0.035, 0), coreColor, Enum.Material.Neon)
	local blue = ellipsoid("CandleFlameBase", Vector3.new(0.05, 0.035, 0.05), CFrame.new(0, wickTop + 0.008, 0), Color3.fromRGB(90, 140, 255), Enum.Material.Neon, { Transparency = 0.45 })
	info.flame = flame
	table.insert(info.flameParts, flame)
	table.insert(info.flameParts, core)
	table.insert(info.flameParts, blue)
	info.core = core
	for _, part in info.flameParts do
		part:SetAttribute("BaseTransparency", part.Transparency)
	end
	return info
end

-- Umfärben (normal <-> rot), z. B. für die Kerze im eigenen Bild
function CandleModel.recolor(info, red)
	local wax = red and WAX_RED or WAX
	for _, part in info.wax do
		part.Color = part.Name == "CandleTop" and wax:Lerp(Color3.new(1, 1, 1), 0.15) or wax
	end
	info.flame.Color = red and CandleModel.FLAME_RED or CandleModel.FLAME
	info.core.Color = red and CandleModel.CORE_RED or CandleModel.CORE
end

return CandleModel
