-- Shop und Kiosk in der Lobby (ein Fenster, zwei Sortimente):
--   Shop  (Shop-Hütte, Knopf unten links): Bundles, Suits & Skins, Clothing, Passes, Coins
--   Kiosk (Verkäufer am Kiosk):            Snacks und Extras (Wiederbelebungen)
-- Rechts ist die Anprobe: Wer etwas auswählt, sieht es sofort an der eigenen Figur (Kleidung
-- und Anzüge sammeln sich, bis man „Reset“ drückt). Mit der Maus kann man die Figur drehen.
-- Jedes Teil hat zwei Preise zur Wahl: Münzen oder Robux.
-- Stil wie der Rest der Lobby: warmes Dunkelbraun, Schreibmaschinenschrift für Titel, ruhig.

-- Liegen im selben Studio-Ort auch die Skripte von Level 1, läuft nur das Level
if game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Level") then
	return
end

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShopCatalog = require(Shared:WaitForChild("ShopCatalog"))
local RealFigure = require(Shared:WaitForChild("RealFigure"))
local Skins = require(Shared:WaitForChild("Skins"))
local SportsCar = require(Shared:WaitForChild("SportsCar"))
local remotes = ReplicatedStorage:WaitForChild("ShopRemotes")

local player = Players.LocalPlayer

------------------------------------------------------------------ Gestaltung (Tokens)
local T = {
	panel = Color3.fromRGB(26, 22, 20),
	surface = Color3.fromRGB(35, 30, 27),
	surfaceHover = Color3.fromRGB(44, 38, 34),
	well = Color3.fromRGB(46, 40, 36), -- Hintergrund der Vorschaubilder
	line = Color3.fromRGB(255, 214, 150),
	text = Color3.fromRGB(240, 228, 210),
	muted = Color3.fromRGB(168, 152, 134),
	accent = Color3.fromRGB(214, 166, 92),
	onAccent = Color3.fromRGB(32, 24, 16),
	robux = Color3.fromRGB(64, 128, 90),
	good = Color3.fromRGB(150, 190, 130),
	bad = Color3.fromRGB(226, 128, 112),
	titleFont = Enum.Font.SpecialElite,
	bodyFont = Enum.Font.GothamMedium,
	boldFont = Enum.Font.GothamBold,
	radius = 6,
}

local function create(className, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or T.radius) })
end

local function hairline(transparency)
	return create("UIStroke", { Color = T.line, Thickness = 1, Transparency = transparency or 0.82, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(props)
	props.BackgroundTransparency = 1
	props.TextColor3 = props.TextColor3 or T.text
	props.Font = props.Font or T.bodyFont
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

local function money(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

------------------------------------------------------------------ Spielerdaten
local state = { coins = 0, owned = {}, items = {}, equipped = {} }

local function readData()
	state.coins = player:GetAttribute("Coins") or 0
	local raw = player:GetAttribute("ShopData")
	if raw then
		local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
		if ok and type(data) == "table" then
			state.owned = data.Owned or {}
			state.items = data.Items or {}
			state.equipped = data.Equipped or {}
		end
	end
end
readData()

------------------------------------------------------------------ Sortiment
-- entry: id, kind, tab, title, description, coins, robux, productId, passId, slot, rarity,
--        preview = { kind = ... }, contents (Liste von Titeln), once (einmal kaufbar)
local entries = {}
local byId = {}
local function add(entry)
	table.insert(entries, entry)
	byId[entry.id] = entry
	return entry
end

local function titlesOf(ids)
	local names = {}
	for _, id in ids or {} do
		local found = ShopCatalog.find(id)
		table.insert(names, found and found.title or id)
	end
	return names
end

-- Shop: Bundles
local starter = ShopCatalog.STARTER_PACK
add({ id = "StarterPack", kind = "Starter", tab = "Bundles", title = starter.title, description = starter.description, robux = starter.robux, firstRobux = starter.firstTimeRobux, productId = starter.productId, firstProductId = starter.firstTimeProductId, preview = { kind = "item", item = "Backpack" }, note = "First purchase only 50 R$", once = true })
for _, pack in ShopCatalog.PACKS do
	local previews = { GoldenPack = { kind = "family" }, SarpVip = { kind = "sarp", skin = "GildedHorror" }, Everything = { kind = "everything" } }
	add({ id = pack.id, kind = "Pack", tab = "Bundles", title = pack.title, description = pack.description, robux = pack.robux, productId = pack.productId, preview = previews[pack.id], contents = titlesOf(pack.grants), note = pack.tag, once = true })
end
for _, outfit in ShopCatalog.OUTFITS do
	add({ id = outfit.id, kind = "Outfit", tab = "Bundles", title = outfit.title, description = outfit.description, coins = outfit.coins, robux = outfit.robux, productId = outfit.productId, preview = { kind = "fitting" }, tryItems = outfit.items, contents = titlesOf(outfit.items), once = true })
end
-- Shop: Anzüge und Skins
for _, skin in ShopCatalog.SKINS do
	local preview = skin.slot == "Sarp" and { kind = "sarp", skin = skin.id } or { kind = "fitting" }
	add({ id = skin.id, kind = "Skin", tab = "Skins", title = skin.title, description = skin.description, coins = skin.coins, robux = skin.robux, productId = skin.productId, pack = skin.pack, slot = skin.slot, rarity = skin.rarity, preview = preview, trySuit = skin.slot == "Player" and skin.id or nil, once = true })
end
local car = ShopCatalog.SPORTS_CAR
add({ id = car.id, kind = "Car", tab = "Skins", title = car.title, description = car.description, coins = car.coins, robux = car.robux, productId = car.productId, rarity = car.rarity, preview = { kind = "car" }, once = true })
-- Shop: Kleidung
for _, item in ShopCatalog.CLOTHING do
	add({ id = item.id, kind = "Clothing", tab = "Clothing", title = item.title, description = "Clothing for your character. Wearing it in the game comes soon.", coins = item.coins, robux = item.robux, productId = item.productId, rarity = item.rarity, slot = item.slot, preview = { kind = "fitting" }, tryItems = { item.id }, once = true })
end
-- Shop: Pässe und Münzen
for _, pass in ShopCatalog.GAMEPASSES do
	add({ id = pass.id, kind = "Pass", tab = "Passes", title = pass.title, description = pass.description, robux = pass.robux, passId = pass.passId, preview = { kind = "pass", pass = pass.id }, once = true })
end
for _, pack in ShopCatalog.COIN_PACKS do
	add({ id = pack.id, kind = "CoinPack", tab = "Coins", title = money(pack.coins) .. " coins", description = "Spend coins on suits, clothing and snacks.", robux = pack.robux, productId = pack.productId, preview = { kind = "coins", amount = pack.coins }, note = pack.tag and (pack.tag:sub(1, 1) .. pack.tag:sub(2):lower()) or nil })
end
local boost = ShopCatalog.COIN_BOOST
add({ id = boost.id, kind = "Boost", tab = "Coins", title = boost.title, description = boost.description, robux = boost.robux, productId = boost.productId, preview = { kind = "coins", amount = 200, double = true } })
-- Kiosk: Snacks und Extras
for _, item in ShopCatalog.ITEMS do
	add({ id = item.id, kind = "Item", tab = "Snacks", title = item.title, description = item.description .. "\nYou can use up to 3 snacks per round.", coins = item.coins, robux = item.robux, productId = item.productId, preview = { kind = "snack", item = item.id } })
end
for index, product in Config.PRODUCTS do
	add({ id = "Product" .. index, kind = "Product", tab = "Extras", title = product.title, description = product.description, robux = product.robux, productId = product.id, preview = { kind = "revive", amount = product.amount, field = product.field } })
end

local SHOP_TABS = { { "Bundles", "Bundles" }, { "Skins", "Suits & Skins" }, { "Clothing", "Clothing" }, { "Passes", "Passes" }, { "Coins", "Coins" } }
local KIOSK_TABS = { { "Snacks", "Snacks" }, { "Extras", "Extras" } }

local function isOwned(entry)
	if not entry.once then
		return false
	end
	if state.owned[entry.id] then
		return true
	end
	if entry.kind == "Outfit" then
		for _, id in entry.tryItems do
			if not state.owned[id] then
				return false
			end
		end
		return true
	end
	return false
end

------------------------------------------------------------------ 3D-Modelle für Vorschau und Karten
local cache = {}
local buildArea = CFrame.new(0, 3000, 0)

-- Vorschaufenster zeigen keine SurfaceAppearance und Glas sieht silbern aus: aufbereiten
local function fitForViewport(model)
	for _, item in model:GetDescendants() do
		if item:IsA("ParticleEmitter") or item:IsA("Light") or item:IsA("ProximityPrompt") then
			item:Destroy()
		elseif item:IsA("SurfaceAppearance") then
			item:Destroy() -- Farbtextur hat buildFigure schon an die MeshPart gesetzt
		elseif item:IsA("BasePart") and item.Material == Enum.Material.Glass then
			item.Material = Enum.Material.SmoothPlastic
			item.Reflectance = 0.15
		end
	end
	return model
end

local function buildFigure(spec, skinId, options)
	local container = ReplicatedStorage:FindFirstChild(spec.folder)
	local template = container and container:FindFirstChild(spec.name)
	if not template then
		return nil
	end
	local model = RealFigure.prepare(template, { anchor = true, height = spec.height })
	local texture = ShopCatalog.FIGURE_TEXTURES[spec.name]
	if texture then
		for _, part in model:GetDescendants() do
			if part:IsA("MeshPart") and part:FindFirstChildOfClass("SurfaceAppearance") then
				part.TextureID = texture
			end
		end
	end
	model:PivotTo(buildArea)
	model.Parent = workspace -- der Skin misst die Körperform mit Strahlen
	if skinId then
		Skins.apply(model, skinId, options)
	end
	model.Parent = nil
	model:PivotTo(CFrame.new())
	return fitForViewport(model)
end

local function clothingTemplate(id)
	local folder = ReplicatedStorage:FindFirstChild("Shop") and ReplicatedStorage.Shop:FindFirstChild("Kleidung")
	return folder and folder:FindFirstChild(id)
end

-- ein Kleidungsstück an die Figur hängen (ungefähr passend, nur für die Anprobe)
local function wear(model, id)
	local item = ShopCatalog.find(id)
	local template = clothingTemplate(id)
	local root = model:FindFirstChild("HumanoidRootPart")
	local head = model:FindFirstChild("Head")
	if not (item and template and root and head) then
		return
	end
	local rot = root.CFrame.Rotation
	local headTop = head.Position.Y + head.Size.Y * 0.5
	local headBottom = head.Position.Y - head.Size.Y * 0.42
	local lower = model:FindFirstChild("LowerTorso")
	local hip = lower and (lower.Position.Y - lower.Size.Y * 0.2) or headBottom - 2
	local front = root.CFrame.LookVector -- Blickrichtung der Figur
	local function place(name, size, cf)
		local part = template:Clone()
		part.Name = "Try_" .. name
		part.Anchored = true
		part.CanCollide = false
		part.Size = size
		part.CFrame = cf
		part.Parent = model
		return part
	end
	local function scaledTo(axis, value)
		local s = template.Size
		local k = value / s[axis]
		return s * k
	end
	local headWidth = math.min(head.Size.X, head.Size.Z) * 1.1
	if item.slot == "Head" then
		local size = scaledTo("X", headWidth * (id == "Headlamp" and 1.08 or 1.18))
		local y = id == "Headlamp" and (head.Position.Y + head.Size.Y * 0.12) or (headTop - size.Y * 0.42)
		place(id, size, CFrame.new(head.Position.X, y, head.Position.Z) * rot)
	elseif item.slot == "Face" then
		local size = scaledTo("X", headWidth * 1.02)
		local pos = head.Position + Vector3.new(0, head.Size.Y * 0.08, 0) + front * (head.Size.Z * 0.36)
		place(id, size, CFrame.new(pos) * rot)
	elseif item.slot == "Neck" then
		local size = scaledTo("X", headWidth * 1.8)
		local pos = Vector3.new(head.Position.X, headBottom - size.Y * 0.35, head.Position.Z) + front * 0.1
		place(id, size, CFrame.new(pos) * rot)
	elseif item.slot == "Back" then
		local size = scaledTo("Y", (headBottom - hip) * 0.85)
		local torso = model:FindFirstChild("UpperTorso")
		local center = torso and torso.Position or root.Position
		local pos = Vector3.new(center.X, (headBottom + hip) / 2, center.Z) - front * (0.35 + size.Z * 0.45)
		place(id, size, CFrame.new(pos) * rot)
	elseif item.slot == "Jacket" then
		local size = scaledTo("Y", (headBottom - hip) * 1.18)
		local torso = model:FindFirstChild("UpperTorso")
		local center = torso and torso.Position or root.Position
		place(id, size, CFrame.new(center.X, (headBottom + hip) / 2 - size.Y * 0.04, center.Z) * rot)
	elseif item.slot == "Hands" then
		for _, side in { "Left", "Right" } do
			local hand = model:FindFirstChild(side .. "Hand")
			if hand then
				local size = scaledTo("Y", hand.Size.Y * 1.15)
				place(id .. side, size, CFrame.new(hand.Position) * rot)
			end
		end
	elseif item.slot == "Feet" then
		local left, right = model:FindFirstChild("LeftFoot"), model:FindFirstChild("RightFoot")
		if left and right then
			local span = (left.Position - right.Position).Magnitude + math.max(left.Size.X, right.Size.X)
			local size = scaledTo("X", span * 1.05)
			local bottom = math.min(left.Position.Y - left.Size.Y / 2, right.Position.Y - right.Size.Y / 2)
			local mid = (left.Position + right.Position) / 2
			place(id, size, CFrame.new(mid.X, bottom + size.Y / 2, mid.Z) * rot)
		end
	end
end

-- kleine gebaute Modelle für Snacks, Pässe, Münzen
local function block(parent, size, cf, color, material, shape)
	return create("Part", { Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Shape = shape or Enum.PartType.Block, Anchored = true, CanCollide = false, Parent = parent })
end

local function coinStack(parent, amount, double)
	local stacks = amount >= 5000 and 4 or amount >= 1500 and 3 or amount >= 500 and 2 or 1
	for s = 1, stacks do
		local height = 3 + s * 2
		for i = 0, height - 1 do
			local x = (s - (stacks + 1) / 2) * 1.25
			block(parent, Vector3.new(0.2, 1.1, 1.1), CFrame.new(x, i * 0.22, (s % 2) * 0.3) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(214, 170, 76), Enum.Material.Metal, Enum.PartType.Cylinder)
		end
	end
	if double then
		block(parent, Vector3.new(0.2, 1.1, 1.1), CFrame.new(1.5, 0.6, -0.4) * CFrame.Angles(0, math.rad(70), math.rad(90)), Color3.fromRGB(230, 190, 90), Enum.Material.Metal, Enum.PartType.Cylinder)
	end
end

local SNACK_COLORS = { EnergyBar = Color3.fromRGB(190, 60, 44), Coffee = Color3.fromRGB(230, 225, 215), MintGum = Color3.fromRGB(90, 170, 140), GummyBears = Color3.fromRGB(230, 170, 60), XRayGlasses = Color3.fromRGB(40, 40, 46) }
local function snackModel(parent, id)
	local color = SNACK_COLORS[id] or T.accent
	if id == "EnergyBar" then
		block(parent, Vector3.new(3, 0.5, 1.2), CFrame.Angles(0, math.rad(20), math.rad(8)), color)
		block(parent, Vector3.new(1, 0.52, 1.22), CFrame.Angles(0, math.rad(20), math.rad(8)), Color3.fromRGB(240, 220, 170))
	elseif id == "Coffee" then
		block(parent, Vector3.new(2, 1.4, 1.4), CFrame.Angles(0, 0, math.rad(90)), color, nil, Enum.PartType.Cylinder)
		block(parent, Vector3.new(0.2, 1.5, 1.5), CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 40, 30), nil, Enum.PartType.Cylinder)
		block(parent, Vector3.new(0.6, 1.42, 1.42), CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 100, 60), Enum.Material.Cardboard, Enum.PartType.Cylinder)
	elseif id == "MintGum" then
		block(parent, Vector3.new(2, 1.3, 0.5), CFrame.Angles(0, math.rad(-20), 0), color)
		block(parent, Vector3.new(2.02, 0.35, 0.52), CFrame.new(0, 0.3, 0) * CFrame.Angles(0, math.rad(-20), 0), Color3.fromRGB(235, 245, 240))
	elseif id == "GummyBears" then
		block(parent, Vector3.new(2, 2.4, 0.8), CFrame.new(), color, Enum.Material.Plastic)
		for i, c in { Color3.fromRGB(200, 40, 40), Color3.fromRGB(60, 160, 60), Color3.fromRGB(240, 200, 40) } do
			block(parent, Vector3.new(0.5, 0.5, 0.5), CFrame.new(-0.9 + i * 0.45, -1.35, -0.6), c, Enum.Material.Glass, Enum.PartType.Ball)
		end
	elseif id == "XRayGlasses" then
		for _, x in { -0.7, 0.7 } do
			block(parent, Vector3.new(0.12, 1, 1), CFrame.new(x, 0, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(120, 230, 160), Enum.Material.Neon, Enum.PartType.Cylinder)
			block(parent, Vector3.new(0.1, 1.15, 1.15), CFrame.new(x, 0, 0.04) * CFrame.Angles(0, math.rad(90), 0), color, Enum.Material.Metal, Enum.PartType.Cylinder)
		end
		block(parent, Vector3.new(0.5, 0.12, 0.12), CFrame.new(0, 0.2, 0), color, Enum.Material.Metal)
	end
end

local function passModel(parent, id)
	if id == "ThreeHearts" then
		for i = -1, 1 do
			local base = CFrame.new(i * 1.4, 0, 0)
			local red = Color3.fromRGB(180, 40, 44)
			block(parent, Vector3.new(0.7, 0.7, 0.5), base * CFrame.new(-0.22, 0.15, 0), red, nil, Enum.PartType.Ball)
			block(parent, Vector3.new(0.7, 0.7, 0.5), base * CFrame.new(0.22, 0.15, 0), red, nil, Enum.PartType.Ball)
			block(parent, Vector3.new(0.62, 0.62, 0.45), base * CFrame.new(0, -0.15, 0) * CFrame.Angles(0, 0, math.rad(45)), red)
		end
	elseif id == "DoubleCoins" then
		coinStack(parent, 500, true)
	elseif id == "StrongFlashlight" then
		block(parent, Vector3.new(2.6, 0.5, 0.5), CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(40, 40, 44), Enum.Material.Metal, Enum.PartType.Cylinder)
		block(parent, Vector3.new(0.6, 0.8, 0.8), CFrame.Angles(0, math.rad(25), 0) * CFrame.new(1.5, 0, 0), Color3.fromRGB(60, 60, 64), Enum.Material.Metal, Enum.PartType.Cylinder)
		block(parent, Vector3.new(0.1, 0.7, 0.7), CFrame.Angles(0, math.rad(25), 0) * CFrame.new(1.82, 0, 0), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, Enum.PartType.Cylinder)
	elseif id == "Supervision" then
		block(parent, Vector3.new(2.4, 1.4, 0.6), CFrame.new(), Color3.fromRGB(235, 230, 220), nil, Enum.PartType.Ball)
		block(parent, Vector3.new(0.9, 0.9, 0.3), CFrame.new(0, 0, -0.25), Color3.fromRGB(110, 170, 210), nil, Enum.PartType.Ball)
		block(parent, Vector3.new(0.4, 0.4, 0.2), CFrame.new(0, 0, -0.38), Color3.fromRGB(20, 20, 24), nil, Enum.PartType.Ball)
	elseif id == "VipCar" then
		SportsCar.build(parent, CFrame.new(), { paint = Color3.fromRGB(120, 24, 30) })
	end
end

local function reviveModel(parent, amount)
	for i = 1, math.min(amount, 3) do
		local base = CFrame.new((i - (math.min(amount, 3) + 1) / 2) * 1.3, 0, 0)
		block(parent, Vector3.new(0.4, 1.4, 0.4), base, Color3.fromRGB(230, 225, 215))
		block(parent, Vector3.new(1.2, 0.4, 0.4), base, Color3.fromRGB(230, 225, 215))
		block(parent, Vector3.new(0.42, 1.42, 0.42), base, Color3.fromRGB(190, 50, 46), Enum.Material.Neon)
	end
end

-- Anprobe: eigene Figur mit Anzug und Kleidung
local fitting = { suit = nil, items = {} } -- items[slot] = id

local function fittingKey(suit, items)
	local list = {}
	for slot, id in items do
		table.insert(list, slot .. "=" .. id)
	end
	table.sort(list)
	return "fit:" .. tostring(suit) .. ":" .. table.concat(list, ",")
end

-- ohne Anzug: schlichtes dunkles Outfit (wie eine Schaufensterpuppe), damit Kleidung gut wirkt
-- und keine Texturflecken der Vorschau stören
local PLAIN = {
	UpperTorso = Color3.fromRGB(58, 54, 52), LowerTorso = Color3.fromRGB(40, 40, 46),
	LeftUpperArm = Color3.fromRGB(58, 54, 52), RightUpperArm = Color3.fromRGB(58, 54, 52),
	LeftLowerArm = Color3.fromRGB(58, 54, 52), RightLowerArm = Color3.fromRGB(58, 54, 52),
	LeftUpperLeg = Color3.fromRGB(40, 40, 46), RightUpperLeg = Color3.fromRGB(40, 40, 46),
	LeftLowerLeg = Color3.fromRGB(40, 40, 46), RightLowerLeg = Color3.fromRGB(40, 40, 46),
	LeftFoot = Color3.fromRGB(28, 26, 26), RightFoot = Color3.fromRGB(28, 26, 26),
}
local function plainOutfit(model)
	for name, color in PLAIN do
		local part = model:FindFirstChild(name)
		if part and part:IsA("MeshPart") then
			part.TextureID = ""
			part.Color = color
			part.Material = Enum.Material.Fabric
		end
	end
end

local function buildFitting(suit, items)
	local skin = suit and ShopCatalog.find(suit)
	local spec = skin and skin.preview or { folder = "Spieler", name = "Spieler1", height = 5.9 }
	local model = buildFigure(spec, suit, skin and skin.options)
	if model and not suit then
		plainOutfit(model)
	end
	if model then
		for _, id in items do
			wear(model, id)
		end
	end
	return model
end

local function previewFor(entry, tried)
	local preview = entry.preview
	if not preview then
		return nil
	end
	local key
	if preview.kind == "fitting" then
		key = fittingKey(tried.suit, tried.items)
	else
		key = preview.kind .. ":" .. tostring(preview.skin or preview.item or preview.pass or preview.amount or "") .. tostring(preview.double or "")
	end
	if cache[key] ~= nil then
		return cache[key] or nil
	end
	local ok, model = pcall(function()
		local holder = Instance.new("Model")
		if preview.kind == "fitting" then
			return buildFitting(tried.suit, tried.items)
		elseif preview.kind == "sarp" then
			local skin = ShopCatalog.find(preview.skin)
			return buildFigure(skin.preview, skin.id, skin.options)
		elseif preview.kind == "family" or preview.kind == "everything" then
			local x = -2.6
			for _, spec in ShopCatalog.FAMILY_GOLD do
				local figure = buildFigure(spec, "GoldSuit", spec.options)
				if figure then
					figure:PivotTo(CFrame.new(x, 0, 0))
					figure.Parent = holder
					x += 1.7
				end
			end
			if preview.kind == "everything" then
				local skin = ShopCatalog.find("GildedHorror")
				local sarp = buildFigure(skin.preview, skin.id, skin.options)
				if sarp then
					sarp:PivotTo(CFrame.new(x + 0.6, 0, 0.8))
					sarp.Parent = holder
				end
			end
		elseif preview.kind == "car" then
			SportsCar.build(holder, CFrame.new())
		elseif preview.kind == "item" then
			local template = clothingTemplate(preview.item)
			if template then
				local part = template:Clone()
				part.Anchored = true
				part.CFrame = CFrame.new()
				part.Parent = holder
			end
		elseif preview.kind == "snack" then
			snackModel(holder, preview.item)
		elseif preview.kind == "pass" then
			passModel(holder, preview.pass)
		elseif preview.kind == "coins" then
			coinStack(holder, preview.amount, preview.double)
		elseif preview.kind == "revive" then
			reviveModel(holder, preview.amount)
		end
		return fitForViewport(holder)
	end)
	if not ok then
		warn("Shop-Vorschau fehlgeschlagen:", model)
		model = nil
	end
	cache[key] = model or false
	return model
end

-- Modell in ein Vorschaufenster setzen; gibt eine Funktion zum Drehen zurück
local function show(viewport, model, yaw)
	viewport:ClearAllChildren()
	if not model then
		return nil
	end
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local clone = model:Clone()
	clone.Parent = world
	local cf, size = clone:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 28
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local radius = math.max(size.X, size.Y * 1.05, size.Z) * 0.5
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.1
	local focus = cf.Position
	local function aim(angle)
		local offset = Vector3.new(math.sin(angle), 0.12, -math.cos(angle)).Unit * distance
		camera.CFrame = CFrame.lookAt(focus + offset, focus)
	end
	aim(yaw or math.rad(-18))
	return aim
end

------------------------------------------------------------------ Fenster
local gui = create("ScreenGui", {
	Name = "VipShop",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	DisplayOrder = 30,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

-- unten links: Münzen und ein ruhiger Shop-Knopf
local hud = create("Frame", { Name = "Hud", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -18), Size = UDim2.fromOffset(150, 74), BackgroundTransparency = 1, Parent = gui })
local hudCoins = text({ Name = "Coins", Size = UDim2.new(1, 0, 0, 24), Font = T.boldFont, TextSize = 16, Text = "0 coins", TextColor3 = T.text, TextStrokeTransparency = 0.6, Parent = hud })
local hudButton = create("TextButton", {
	Name = "OpenShop",
	Position = UDim2.fromOffset(0, 30),
	Size = UDim2.fromOffset(120, 40),
	BackgroundColor3 = T.panel,
	BackgroundTransparency = 0.15,
	AutoButtonColor = true,
	Font = T.titleFont,
	Text = "Shop",
	TextSize = 22,
	TextColor3 = T.text,
	Parent = hud,
}, { corner(), hairline(0.7) })

local overlay = create("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Visible = false, ZIndex = 10, Parent = gui })
local root = create("Frame", {
	Name = "Root",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(1000, 600),
	BackgroundColor3 = T.panel,
	ZIndex = 11,
	Parent = overlay,
}, { corner(10), hairline(0.75) })
local scale = create("UIScale", { Parent = root })
-- an die nutzbare Fläche anpassen (ohne Roblox-Leiste oben)
local function updateScale()
	local size = gui.AbsoluteSize
	if size.X < 10 then
		return
	end
	scale.Scale = math.clamp(math.min((size.X - 32) / 1000, (size.Y - 32) / 600), 0.5, 1.2)
end
updateScale()
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)

-- Kopfzeile
local header = create("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1, ZIndex = 12, Parent = root })
local titleLabel = text({ Name = "Title", Position = UDim2.fromOffset(28, 14), Size = UDim2.fromOffset(400, 30), Font = T.titleFont, TextSize = 30, Text = "Shop", ZIndex = 12, Parent = header })
local subtitle = text({ Name = "Subtitle", Position = UDim2.fromOffset(29, 44), Size = UDim2.fromOffset(500, 18), TextSize = 14, TextColor3 = T.muted, Text = "", ZIndex = 12, Parent = header })
local coinsLabel = text({ Name = "Coins", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -120, 0, 18), Size = UDim2.fromOffset(240, 22), Font = T.boldFont, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Right, Text = "0 coins", ZIndex = 12, Parent = header })
local testNote = text({ Name = "TestNote", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -120, 0, 42), Size = UDim2.fromOffset(240, 16), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.muted, Text = "Studio test coins, not saved", Visible = false, ZIndex = 12, Parent = header })
local closeButton = create("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -24, 0, 18),
	Size = UDim2.fromOffset(80, 34),
	BackgroundColor3 = T.surface,
	AutoButtonColor = true,
	Font = T.boldFont,
	Text = "Close",
	TextSize = 14,
	TextColor3 = T.text,
	Modal = true, -- Maus frei, solange das Fenster offen ist
	ZIndex = 12,
	Parent = header,
}, { corner(), hairline(0.8) })

-- Reiter
local tabBar = create("Frame", { Name = "Tabs", Position = UDim2.fromOffset(24, 72), Size = UDim2.new(0, 620, 0, 36), BackgroundTransparency = 1, ZIndex = 12, Parent = root }, {
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 22), SortOrder = Enum.SortOrder.LayoutOrder }),
})
create("Frame", { Name = "Divider", Position = UDim2.fromOffset(24, 108), Size = UDim2.new(1, -48, 0, 1), BackgroundColor3 = T.line, BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 12, Parent = root })

-- Karten links
local grid = create("ScrollingFrame", {
	Name = "Grid",
	Position = UDim2.fromOffset(24, 124),
	Size = UDim2.fromOffset(612, 452),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = T.muted,
	ScrollBarImageTransparency = 0.4,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ZIndex = 12,
	Parent = root,
}, {
	create("UIGridLayout", { CellSize = UDim2.fromOffset(192, 206), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
	create("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
})

-- Anprobe / Details rechts
local detail = create("Frame", { Name = "Detail", Position = UDim2.fromOffset(652, 124), Size = UDim2.fromOffset(324, 452), BackgroundColor3 = T.surface, ZIndex = 12, Parent = root }, { corner(8) })
local stage = create("ViewportFrame", {
	Name = "Stage",
	Position = UDim2.fromOffset(10, 10),
	Size = UDim2.new(1, -20, 0, 214),
	BackgroundColor3 = T.well,
	Ambient = Color3.fromRGB(150, 140, 130),
	LightColor = Color3.fromRGB(255, 236, 214),
	LightDirection = Vector3.new(-0.6, -1, -0.8),
	ZIndex = 13,
	Parent = detail,
}, { corner() })
local stageHint = text({ Name = "Hint", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 0, 218), Size = UDim2.fromOffset(160, 14), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.muted, Text = "Drag to turn", ZIndex = 14, Parent = detail })
local resetButton = create("TextButton", { Name = "Reset", Position = UDim2.fromOffset(18, 200), Size = UDim2.fromOffset(58, 18), BackgroundTransparency = 1, Font = T.boldFont, Text = "Reset", TextSize = 12, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 14, Visible = false, Parent = detail })
local kindLabel = text({ Name = "Kind", Position = UDim2.fromOffset(18, 234), Size = UDim2.new(1, -36, 0, 14), Font = T.boldFont, TextSize = 11, TextColor3 = T.muted, Text = "", ZIndex = 13, Parent = detail })
local nameLabel = text({ Name = "Name", Position = UDim2.fromOffset(18, 250), Size = UDim2.new(1, -36, 0, 28), Font = T.titleFont, TextSize = 24, Text = "", ZIndex = 13, Parent = detail })
local descLabel = text({ Name = "Description", Position = UDim2.fromOffset(18, 282), Size = UDim2.new(1, -36, 0, 70), TextSize = 13, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = T.muted, Text = "", ZIndex = 13, Parent = detail })
local statusLabel = text({ Name = "Status", Position = UDim2.fromOffset(18, 352), Size = UDim2.new(1, -36, 0, 16), Font = T.boldFont, TextSize = 12, TextColor3 = T.good, Text = "", ZIndex = 13, Parent = detail })
local actions = create("Frame", { Name = "Actions", Position = UDim2.fromOffset(16, 372), Size = UDim2.new(1, -32, 0, 70), BackgroundTransparency = 1, ZIndex = 13, Parent = detail })

local messageLabel = text({ Name = "Message", AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(28, 580), Size = UDim2.fromOffset(600, 16), TextSize = 13, Text = "", TextColor3 = T.muted, ZIndex = 12, Parent = root })
local messageToken = 0
local function say(message, color)
	messageToken += 1
	local token = messageToken
	messageLabel.Text = message
	messageLabel.TextColor3 = color or T.text
	messageLabel.TextTransparency = 0
	task.delay(4, function()
		if token == messageToken then
			TweenService:Create(messageLabel, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		end
	end)
end

------------------------------------------------------------------ Karten
local mode = "shop"
local currentTab
local selected
local cards = {}
local tabButtons = {}
local turn = math.rad(-18)
local aimStage

local function priceLine(entry)
	if isOwned(entry) then
		if entry.slot and state.equipped[entry.slot] == entry.id then
			return "Wearing", T.good
		end
		return "Owned", T.good
	end
	local parts = {}
	if entry.coins then
		table.insert(parts, money(entry.coins) .. " coins")
	end
	if entry.robux then
		table.insert(parts, "R$ " .. money(entry.robux))
	end
	if #parts == 0 and entry.pack then
		local pack = byId[entry.pack]
		return "In the " .. (pack and pack.title or "pack"), T.muted
	end
	local line = table.concat(parts, "  ·  ")
	if entry.kind == "Item" and (state.items[entry.id] or 0) > 0 then
		line ..= "   (" .. state.items[entry.id] .. " in bag)"
	end
	return line, T.muted
end

local function styleCard(card)
	local entry = card.entry
	local line, color = priceLine(entry)
	card.price.Text = line
	card.price.TextColor3 = color
	local active = selected == entry
	card.stroke.Transparency = active and 0.25 or 0.88
	card.frame.BackgroundColor3 = active and T.surfaceHover or T.surface
end

local select -- weiter unten

local thumbQueue = {}
local function makeCard(entry, order)
	local frame = create("TextButton", { Name = entry.id, BackgroundColor3 = T.surface, AutoButtonColor = false, Text = "", LayoutOrder = order, ZIndex = 13, Parent = grid }, { corner(8) })
	local stroke = create("UIStroke", { Color = T.line, Thickness = 1, Transparency = 0.88, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
	local thumb = create("ViewportFrame", {
		Name = "Thumb",
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 0, 124),
		BackgroundColor3 = T.well,
		Ambient = Color3.fromRGB(160, 150, 140),
		LightColor = Color3.fromRGB(255, 236, 214),
		LightDirection = Vector3.new(-0.6, -1, -0.8),
		ZIndex = 14,
		Parent = frame,
	}, { corner() })
	if entry.note then
		text({ Name = "Note", Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 14), Font = T.boldFont, TextSize = 11, TextColor3 = T.accent, Text = entry.note, ZIndex = 15, Parent = frame })
	end
	text({ Name = "Title", Position = UDim2.fromOffset(14, 142), Size = UDim2.new(1, -28, 0, 22), Font = T.titleFont, TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd, Text = entry.title, ZIndex = 14, Parent = frame })
	local price = text({ Name = "Price", Position = UDim2.fromOffset(14, 168), Size = UDim2.new(1, -28, 0, 26), TextSize = 13, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 14, Parent = frame })
	local card = { entry = entry, frame = frame, stroke = stroke, price = price, thumb = thumb }
	frame.MouseEnter:Connect(function()
		if selected ~= entry then
			frame.BackgroundColor3 = T.surfaceHover
		end
	end)
	frame.MouseLeave:Connect(function()
		styleCard(card)
	end)
	frame.Activated:Connect(function()
		select(entry)
	end)
	styleCard(card)
	table.insert(thumbQueue, card)
	return card
end

-- Bilder der Karten nach und nach bauen (Kleidung als Teil allein, nicht an der Figur)
task.spawn(function()
	while true do
		local card = table.remove(thumbQueue, 1)
		if card and card.frame.Parent then
			local entry = card.entry
			local model
			if entry.kind == "Clothing" then
				model = previewFor({ preview = { kind = "item", item = entry.id } }, fitting)
			elseif entry.preview and entry.preview.kind == "fitting" then
				local items = {}
				for _, id in entry.tryItems or {} do
					local item = ShopCatalog.find(id)
					items[item.slot] = id
				end
				model = previewFor(entry, { suit = entry.trySuit, items = items })
			else
				model = previewFor(entry, fitting)
			end
			show(card.thumb, model, math.rad(-20))
		end
		task.wait(card and 0.02 or 0.15)
	end
end)

local function showTab(tab)
	currentTab = tab
	for id, button in tabButtons do
		local active = id == tab
		button.TextColor3 = active and T.text or T.muted
		button.Underline.Visible = active
	end
	for _, card in cards do
		card.frame:Destroy()
	end
	table.clear(cards)
	table.clear(thumbQueue)
	local order = 0
	for _, entry in entries do
		if entry.tab == tab then
			order += 1
			table.insert(cards, makeCard(entry, order))
		end
	end
	grid.CanvasPosition = Vector2.zero
end

local function buildTabs(list)
	for _, button in tabButtons do
		button:Destroy()
	end
	table.clear(tabButtons)
	for index, info in list do
		local button = create("TextButton", {
			Name = info[1],
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = T.boldFont,
			Text = info[2],
			TextSize = 15,
			TextColor3 = T.muted,
			LayoutOrder = index,
			ZIndex = 13,
			Parent = tabBar,
		})
		create("Frame", { Name = "Underline", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = T.accent, BorderSizePixel = 0, Visible = false, ZIndex = 14, Parent = button })
		button.Activated:Connect(function()
			showTab(info[1])
			if cards[1] then
				select(cards[1].entry)
			end
		end)
		tabButtons[info[1]] = button
	end
end

------------------------------------------------------------------ Anprobe und Knöpfe
local function refreshStage()
	if not selected then
		return
	end
	local tried = fitting
	local entry = selected
	local model = previewFor(entry, tried)
	aimStage = show(stage, model, turn)
	local wearing = fitting.suit ~= nil or next(fitting.items) ~= nil
	resetButton.Visible = entry.preview and entry.preview.kind == "fitting" and wearing
end

-- Auswahl probiert Kleidung und Anzüge sofort an (sammelt sich auf der Figur)
local function tryOn(entry)
	if entry.trySuit then
		fitting.suit = entry.trySuit
	end
	for _, id in entry.tryItems or {} do
		local item = ShopCatalog.find(id)
		if item then
			fitting.items[item.slot] = id
		end
	end
end

local function button(parent, label, fill, textColor, order, onClick, width)
	local b = create("TextButton", {
		Size = UDim2.new(width or 1, width and -5 or 0, 0, 36),
		BackgroundColor3 = fill,
		AutoButtonColor = onClick ~= nil,
		Font = T.boldFont,
		Text = label,
		TextSize = 14,
		TextColor3 = textColor,
		LayoutOrder = order,
		ZIndex = 14,
		Parent = parent,
	}, { corner() })
	if onClick then
		local busy = false
		b.Activated:Connect(function()
			if busy then
				return
			end
			busy = true
			onClick()
			busy = false
		end)
	end
	return b
end

local function promptRobux(entry)
	if entry.kind == "Pass" then
		if not entry.passId or entry.passId == 0 then
			say("Robux purchases open soon.", T.accent)
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, entry.passId)
		return
	end
	local productId = entry.productId
	if entry.kind == "Starter" and not state.owned.StarterPack and entry.firstProductId and entry.firstProductId ~= 0 then
		productId = entry.firstProductId
	end
	if not productId or productId == 0 then
		say("Robux purchases open soon.", T.accent)
		return
	end
	MarketplaceService:PromptProductPurchase(player, productId)
end

local function buyWithCoins(entry)
	if state.coins < entry.coins then
		say("You need " .. money(entry.coins - state.coins) .. " more coins.", T.bad)
		return
	end
	local ok, result = remotes.BuyWithCoins:InvokeServer(entry.id)
	say(result or (ok and "Done." or "Something went wrong."), ok and T.good or T.bad)
end

local function equip(entry, on)
	local ok, result = remotes.Equip:InvokeServer(entry.slot, on and entry.id or nil)
	if ok then
		say(on and ("You are wearing " .. entry.title .. ".") or (entry.title .. " taken off."), T.good)
	else
		say(result or "Something went wrong.", T.bad)
	end
end

local function renderActions(entry)
	actions:ClearAllChildren()
	statusLabel.Text = ""
	local rows = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 13, Parent = actions }, {
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom }),
	})
	if isOwned(entry) then
		if entry.slot then
			local on = state.equipped[entry.slot] == entry.id
			statusLabel.Text = on and "You are wearing this." or "You own this."
			button(rows, on and "Take off" or "Wear", on and T.surfaceHover or T.accent, on and T.text or T.onAccent, 2, function()
				equip(entry, not on)
			end)
		else
			statusLabel.Text = entry.kind == "Pack" and "You own this bundle." or "You own this."
		end
		return
	end
	if entry.kind == "Item" then
		statusLabel.Text = "In your bag: " .. (state.items[entry.id] or 0)
		statusLabel.TextColor3 = T.muted
	else
		statusLabel.TextColor3 = T.good
	end
	if entry.pack and not entry.coins and not entry.robux then
		local pack = byId[entry.pack]
		button(rows, "See the " .. (pack and pack.title or "bundle"), T.accent, T.onAccent, 2, function()
			if pack then
				showTab(pack.tab)
				select(pack)
			end
		end)
		return
	end
	-- zwei Wege zu bezahlen, nebeneinander
	local pay = create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 13, Parent = rows }, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local both = entry.coins and entry.robux
	if entry.coins then
		local afford = state.coins >= entry.coins
		button(pay, money(entry.coins) .. " coins", afford and T.accent or T.surfaceHover, afford and T.onAccent or T.muted, 1, function()
			buyWithCoins(entry)
		end, both and 0.5 or nil)
	end
	if entry.robux then
		local price = entry.robux
		local label = "R$ " .. money(price)
		if entry.kind == "Starter" and entry.firstRobux and not state.owned.StarterPack then
			label = "R$ " .. entry.firstRobux .. "  (instead of " .. price .. ")"
		end
		button(pay, label, T.robux, T.text, 2, function()
			promptRobux(entry)
		end, both and 0.5 or nil)
	end
end

function select(entry)
	selected = entry
	for _, card in cards do
		styleCard(card)
	end
	tryOn(entry)
	local rarity = entry.rarity and ShopCatalog.RARITIES[entry.rarity]
	local kinds = { Skin = "Suit & skin", Car = "Car", Clothing = "Clothing", Outfit = "Clothing set", Pack = "Bundle", Starter = "Bundle", Pass = "Game pass", CoinPack = "Coins", Boost = "Boost", Item = "Snack", Product = "Extra" }
	kindLabel.Text = (kinds[entry.kind] or "") .. (rarity and ("  ·  " .. rarity.title:sub(1, 1) .. rarity.title:sub(2):lower()) or "")
	nameLabel.Text = entry.title
	local description = entry.description or ""
	if entry.contents then
		description ..= "\n\nIncludes: " .. table.concat(entry.contents, ", ")
	end
	descLabel.Text = description
	stage:ClearAllChildren()
	task.spawn(refreshStage)
	renderActions(entry)
end

resetButton.Activated:Connect(function()
	fitting.suit = state.equipped.Player
	table.clear(fitting.items)
	refreshStage()
end)

-- Figur mit der Maus (oder dem Finger) drehen
local dragging = false
local lastX
stage.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		lastX = input.Position.X
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local dx = input.Position.X - lastX
		lastX = input.Position.X
		turn -= dx * 0.012
		if aimStage then
			aimStage(turn)
		end
	end
end)

------------------------------------------------------------------ Öffnen / Schließen
local open = false
local function setOpen(value, wantedMode, target)
	open = value
	if not value then
		GuiService.SelectedObject = nil
		overlay.Visible = false
		hud.Visible = true
		return
	end
	readData()
	if wantedMode and wantedMode ~= mode then
		mode = wantedMode
		currentTab = nil
	end
	buildTabs(mode == "kiosk" and KIOSK_TABS or SHOP_TABS)
	titleLabel.Text = mode == "kiosk" and "Kiosk" or "Shop"
	subtitle.Text = mode == "kiosk" and "Snacks for the long night. Use up to 3 per round." or "Suits, clothing and bundles. Pick anything to try it on."
	fitting.suit = state.equipped.Player
	table.clear(fitting.items)
	local entry = target and byId[target]
	local tabTarget = not entry and target or nil -- auch ein Reiter als Ziel ("Skins")
	showTab(entry and entry.tab or tabTarget or currentTab or (mode == "kiosk" and "Snacks" or "Bundles"))
	if entry then
		select(entry)
	elseif cards[1] then
		select(cards[1].entry)
	end
	hud.Visible = false
	overlay.Visible = true
	-- kurz und ruhig einblenden (Abdunklung), außer bei „weniger Bewegung“
	if not GuiService.ReducedMotionEnabled then
		overlay.BackgroundTransparency = 1
		TweenService:Create(overlay, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.5 }):Play()
	end
end

hudButton.Activated:Connect(function()
	setOpen(true, "shop")
end)
closeButton.Activated:Connect(function()
	setOpen(false)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if open and not processed and input.KeyCode == Enum.KeyCode.Escape then
		setOpen(false)
	end
end)

-- Andere Skripte (und Tests) können öffnen: VipShop:SetAttribute("Open", "shop" | "kiosk" | Artikel-ID)
gui:GetAttributeChangedSignal("Open"):Connect(function()
	local target = gui:GetAttribute("Open")
	if type(target) == "string" and target ~= "" then
		gui:SetAttribute("Open", nil)
		if target == "shop" or target == "kiosk" then
			setOpen(true, target)
		else
			local entry = byId[target]
			setOpen(true, entry and (entry.tab == "Snacks" or entry.tab == "Extras") and "kiosk" or "shop", target)
		end
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player then
		return
	end
	if CollectionService:HasTag(prompt, "ShopHutPrompt") then
		setOpen(true, "shop", prompt:GetAttribute("ShopTab"))
	elseif CollectionService:HasTag(prompt, "ShowroomItemPrompt") then
		setOpen(true, "shop", prompt:GetAttribute("ShopItem"))
	elseif CollectionService:HasTag(prompt, "KioskPrompt") or CollectionService:HasTag(prompt, "ShopPrompt") then
		setOpen(true, "kiosk")
	end
end)

-- Daten geändert (Kauf, Anziehen): neu anzeigen
local function onDataChanged()
	readData()
	hudCoins.Text = money(state.coins) .. " coins"
	coinsLabel.Text = money(state.coins) .. " coins"
	testNote.Visible = player:GetAttribute("TestCoins") == true
	if open then
		for _, card in cards do
			styleCard(card)
		end
		if selected then
			renderActions(selected)
		end
	end
end
player:GetAttributeChangedSignal("Coins"):Connect(onDataChanged)
player:GetAttributeChangedSignal("ShopData"):Connect(onDataChanged)
onDataChanged()
