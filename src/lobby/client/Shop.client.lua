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
	-- Handelsposten: Holzwand, vergilbtes Papier, Tinte, Messing, roter Stempel
	wood = Color3.fromRGB(70, 48, 33),
	woodDark = Color3.fromRGB(38, 26, 19),
	woodLight = Color3.fromRGB(104, 72, 48),
	paper = Color3.fromRGB(233, 220, 194),
	paperShade = Color3.fromRGB(214, 198, 166),
	ink = Color3.fromRGB(46, 36, 29),
	inkMuted = Color3.fromRGB(110, 92, 74),
	inkGreen = Color3.fromRGB(40, 96, 62),
	stamp = Color3.fromRGB(168, 38, 34),
	brass = Color3.fromRGB(206, 162, 82),
	brassDark = Color3.fromRGB(120, 86, 38),
	tape = Color3.fromRGB(226, 214, 170),
	coin = Color3.fromRGB(230, 184, 84),
	coinEdge = Color3.fromRGB(150, 106, 38),
	glowTop = Color3.fromRGB(92, 72, 54), -- warmes Licht hinter den 3D-Bildern
	glowBottom = Color3.fromRGB(30, 26, 23),
	titleFont = Enum.Font.SpecialElite,
	bodyFont = Enum.Font.GothamMedium,
	boldFont = Enum.Font.GothamBold,
	radius = 8,
	touch = 48, -- Mindesthöhe für alles, was man antippt
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
add({ id = "StarterPack", kind = "Starter", tab = "Bundles", title = starter.title, description = starter.description, robux = starter.robux, firstRobux = starter.firstTimeRobux, productId = starter.productId, firstProductId = starter.firstTimeProductId, preview = { kind = "item", item = "Backpack" }, note = "First time only", once = true })
for _, pack in ShopCatalog.PACKS do
	local previews = { GoldenPack = { kind = "family" }, SarpVip = { kind = "sarp", skin = "GildedHorror" }, Everything = { kind = "everything" } }
	local oldRobux
	if pack.id == "Everything" then
		-- so viel kosten die beiden Packs einzeln
		oldRobux = 0
		for _, other in ShopCatalog.PACKS do
			if other.id ~= "Everything" then
				oldRobux += other.robux
			end
		end
	end
	add({ id = pack.id, kind = "Pack", tab = "Bundles", title = pack.title, description = pack.description, robux = pack.robux, oldRobux = oldRobux, productId = pack.productId, preview = previews[pack.id], contents = titlesOf(pack.grants), note = pack.tag, once = true })
end
for _, outfit in ShopCatalog.OUTFITS do
	-- alter Preis = alle Teile einzeln
	local oldCoins, oldRobux = 0, 0
	for _, id in outfit.items do
		local item = ShopCatalog.find(id)
		oldCoins += item and item.coins or 0
		oldRobux += item and item.robux or 0
	end
	add({ id = outfit.id, kind = "Outfit", tab = "Bundles", title = outfit.title, description = outfit.description, coins = outfit.coins, robux = outfit.robux, oldCoins = oldCoins, oldRobux = oldRobux, productId = outfit.productId, preview = { kind = "fitting" }, tryItems = outfit.items, contents = titlesOf(outfit.items), note = "Save " .. math.floor((1 - outfit.coins / oldCoins) * 100 + 0.5) .. "%", once = true })
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
	add({ id = pass.id, kind = "Pass", tab = "Passes", title = pass.title, description = pass.description, robux = pass.robux, passId = pass.passId, logo = pass.id, once = true })
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

-- aktuelle und alte Preise: coins, robux, oldCoins, oldRobux
local function prices(entry)
	local robux, oldRobux = entry.robux, entry.oldRobux
	if entry.kind == "Starter" and entry.firstRobux and not state.owned.StarterPack then
		robux, oldRobux = entry.firstRobux, entry.robux
	end
	return entry.coins, robux, entry.oldCoins, oldRobux
end

-- „<s>alt</s> neu“ als RichText; alter Preis blass
local function struck(old, new)
	if old and old > new then
		return '<font transparency="0.45"><s>' .. money(old) .. "</s></font>  " .. money(new)
	end
	return money(new)
end

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

-- Modell in ein Vorschaufenster setzen, auf ein kleines Holzpodest; gibt eine Funktion zum Drehen zurück
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
	-- Podest unter dem Modell (dunkles Holz mit hellem Rand)
	local radius = math.clamp(math.max(size.X, size.Z) * 0.52, 0.6, 6)
	local bottom = cf.Position.Y - size.Y / 2
	local function disc(height, r, color, material)
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(height, r * 2, r * 2)
		part.CFrame = CFrame.new(cf.Position.X, bottom - height / 2, cf.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
		part.Color = color
		part.Material = material
		part.Anchored = true
		part.Parent = world
	end
	disc(math.min(radius * 0.08, 0.25), radius, Color3.fromRGB(58, 42, 32), Enum.Material.Wood)
	disc(radius * 0.02, radius * 1.03, Color3.fromRGB(150, 112, 60), Enum.Material.Wood)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 26
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local reach = math.max(size.X, size.Y * 1.08, size.Z) * 0.5
	local distance = reach / math.tan(math.rad(camera.FieldOfView / 2)) * 1.12
	local focus = cf.Position - Vector3.new(0, size.Y * 0.03, 0)
	local function aim(angle)
		local offset = Vector3.new(math.sin(angle), 0.16, -math.cos(angle)).Unit * distance
		camera.CFrame = CFrame.lookAt(focus + offset, focus)
	end
	aim(yaw or math.rad(-18))
	return aim
end

------------------------------------------------------------------ Bausteine der Oberfläche (Handelsposten-Stil)
-- gezeichnete Münze (statt eines Emojis)
local function coinIcon(parent, size, z)
	local coin = create("Frame", { Name = "Coin", Size = UDim2.fromOffset(size, size), BackgroundColor3 = T.coin, ZIndex = z, Parent = parent }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = T.coinEdge, Thickness = math.max(1, size / 10) }),
	})
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.52, 0.52), BackgroundTransparency = 1, ZIndex = z, Parent = coin }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = T.coinEdge, Thickness = 1, Transparency = 0.35 }),
	})
	return coin
end

-- Nagelkopf
local function nail(parent, position, z)
	return create("Frame", { Name = "Nail", AnchorPoint = Vector2.new(0.5, 0.5), Position = position, Size = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.fromRGB(150, 146, 140), ZIndex = z, Parent = parent }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = Color3.fromRGB(40, 36, 32), Thickness = 1 }),
	})
end

-- Bretterwand: dunkle Grundfarbe, Bretter mit leicht anderer Farbe und Fugen dazwischen
local function planks(parent, count, z, horizontal)
	local holder = create("Frame", { Name = "Planks", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = z, Parent = parent }, { corner(10) })
	local shades = { 0, 0.06, -0.04, 0.03, -0.07, 0.05, -0.02 }
	for i = 0, count - 1 do
		local k = shades[i % #shades + 1]
		local color = T.wood:Lerp(k > 0 and T.woodLight or T.woodDark, math.abs(k) * 4)
		local size = horizontal and UDim2.new(1, 0, 1 / count, -2) or UDim2.new(1 / count, -2, 1, 0)
		local pos = horizontal and UDim2.fromScale(0, i / count) or UDim2.fromScale(i / count, 0)
		create("Frame", { Name = "Plank", Position = pos, Size = size, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z, Parent = holder }, {
			create("UIGradient", { Rotation = horizontal and 0 or 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.92, 0.92, 0.92)), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.88, 0.88, 0.88)) }) }),
		})
	end
	return holder
end

-- Streifen Klebeband (halb durchsichtig, schräg)
local function tape(parent, position, rotation, z)
	return create("Frame", { Name = "Tape", AnchorPoint = Vector2.new(0.5, 0.5), Position = position, Size = UDim2.fromOffset(54, 16), Rotation = rotation, BackgroundColor3 = T.tape, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = z, Parent = parent })
end

-- roter Stempel („OWNED“)
local function stampLabel(parent, label, z)
	local stampFrame = create("TextLabel", {
		Name = "Stamp",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		Rotation = -12,
		BackgroundTransparency = 1,
		Font = Enum.Font.SpecialElite,
		Text = label,
		TextSize = 24,
		TextColor3 = T.stamp,
		TextTransparency = 0.12,
		ZIndex = z,
		Parent = parent,
	}, {
		create("UIStroke", { Color = T.stamp, Thickness = 3, Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		create("UICorner", { CornerRadius = UDim.new(0, 4) }),
		create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
	})
	return stampFrame
end

-- gestrichelte Linie (wie auf einer Quittung)
local function dashedLine(parent, order, z)
	local line = create("Frame", { Name = "Dashes", Size = UDim2.new(1, 0, 0, 6), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = z, Parent = parent }, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	for _ = 1, 40 do
		create("Frame", { Size = UDim2.fromOffset(7, 1), BackgroundColor3 = T.inkMuted, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = z, Parent = line })
	end
	line.ClipsDescendants = true
	return line
end

-- „Foto“: dunkler Rahmen, darin warmes Licht und das durchsichtige Vorschaufenster
local function photo(parent, z)
	local frame = create("Frame", { Name = "Photo", BackgroundColor3 = T.woodDark, ZIndex = z, Parent = parent }, { corner(4) })
	local back = create("Frame", { Name = "Backdrop", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = z, Parent = frame }, {
		corner(3),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(T.glowTop, T.glowBottom) }),
	})
	local view = create("ViewportFrame", {
		Name = "View",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(150, 138, 126),
		LightColor = Color3.fromRGB(255, 232, 205),
		LightDirection = Vector3.new(-0.6, -1, -0.8),
		ZIndex = z + 1,
		Parent = back,
	})
	return frame, view
end

------------------------------------------------------------------ Bewegung (kurz, gezielt; aus bei „weniger Bewegung“)
local function calm()
	return GuiService.ReducedMotionEnabled
end

local function tween(object, time, goal, style, direction)
	if calm() then
		for key, value in goal do
			object[key] = value
		end
		return nil
	end
	local t = TweenService:Create(object, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

-- Lichtschimmer, der beim Darüberfahren über einen Knopf läuft
local function addShine(button, z)
	button.ClipsDescendants = true
	local shine = create("Frame", { Name = "Shine", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z, Parent = button })
	local gradient = create("UIGradient", {
		Rotation = 18,
		Offset = Vector2.new(-1, 0),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.72), NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1) }),
		Parent = shine,
	})
	return function()
		if calm() then
			return
		end
		gradient.Offset = Vector2.new(-1, 0)
		TweenService:Create(gradient, TweenInfo.new(0.55, Enum.EasingStyle.Sine), { Offset = Vector2.new(1, 0) }):Play()
	end
end

-- Knopf „lebt“: wächst beim Darüberfahren, gibt beim Drücken nach, federt zurück
local function alive(button, options)
	options = options or {}
	local scale = button:FindFirstChildOfClass("UIScale") or create("UIScale", { Parent = button })
	local hover = options.hover or 1.04
	local sweep = options.shine and addShine(button, options.shineZ or 14)
	local inside = false
	local function rest()
		return button:GetAttribute("RestScale") or 1
	end
	button.MouseEnter:Connect(function()
		inside = true
		tween(scale, 0.12, { Scale = hover })
		if sweep then
			sweep()
		end
	end)
	button.MouseLeave:Connect(function()
		inside = false
		tween(scale, 0.16, { Scale = rest() })
	end)
	button.MouseButton1Down:Connect(function()
		tween(scale, 0.06, { Scale = 0.94 })
	end)
	button.MouseButton1Up:Connect(function()
		tween(scale, 0.3, { Scale = inside and hover or rest() }, Enum.EasingStyle.Back)
	end)
	return scale
end

------------------------------------------------------------------ Bundle-Plakate
-- Jedes Bundle bekommt ein eigenes Plakat: Farben, Titel-Schrift, Spruch und Verzierung.
-- Die 3D-Figuren stehen im unteren Teil, der Titel groß darüber.
local POSTERS = {
	StarterPack = { top = Color3.fromRGB(70, 98, 60), bottom = Color3.fromRGB(20, 30, 20), accent = Color3.fromRGB(240, 226, 176), font = Enum.Font.Bangers, title = "STARTER PACK", tag = "For your very first night", deco = "stripes" },
	GoldenPack = { top = Color3.fromRGB(130, 96, 32), bottom = Color3.fromRGB(18, 12, 6), accent = Color3.fromRGB(255, 214, 120), font = Enum.Font.Garamond, title = "GOLDEN PACK", tag = "The Wagners dress up", deco = "rays" },
	SarpVip = { top = Color3.fromRGB(118, 14, 20), bottom = Color3.fromRGB(10, 3, 5), accent = Color3.fromRGB(255, 96, 76), font = Enum.Font.Creepster, title = "SARP VIP", tag = "He wears gold now", deco = "scratches" },
	Everything = { top = Color3.fromRGB(140, 100, 36), mid = Color3.fromRGB(110, 20, 22), bottom = Color3.fromRGB(12, 6, 6), accent = Color3.fromRGB(255, 206, 128), font = Enum.Font.Garamond, title = "EVERYTHING", tag = "Every last thread", deco = "rays" },
	HikerSet = { top = Color3.fromRGB(196, 150, 42), bottom = Color3.fromRGB(40, 42, 28), accent = Color3.fromRGB(252, 244, 214), font = Enum.Font.Oswald, title = "HIKER SET", tag = "Rain or worse", deco = "stripes" },
	NightWalkSet = { top = Color3.fromRGB(34, 46, 92), bottom = Color3.fromRGB(5, 7, 16), accent = Color3.fromRGB(206, 220, 255), font = Enum.Font.Oswald, title = "NIGHT WALK", tag = "Bring a light", deco = "stars" },
	RoadTripSet = { top = Color3.fromRGB(204, 98, 44), bottom = Color3.fromRGB(44, 16, 14), accent = Color3.fromRGB(255, 230, 186), font = Enum.Font.Oswald, title = "ROAD TRIP", tag = "Don't stop for strangers", deco = "rays" },
}

local DEFAULT_GLOW = ColorSequence.new(T.glowTop, T.glowBottom)

-- Plakat auf ein „Foto“ legen (oder entfernen, wenn `entry` kein Bundle ist); `big` = Vorschau rechts
local function decoratePoster(view, entry, big)
	local back = view.Parent
	local old = back:FindFirstChild("Poster")
	if old then
		old:Destroy()
	end
	local gradient = back:FindFirstChildOfClass("UIGradient")
	local style = entry and POSTERS[entry.id]
	if not style then
		gradient.Color = DEFAULT_GLOW
		view.Position = UDim2.fromScale(0, 0)
		view.Size = UDim2.fromScale(1, 1)
		return
	end
	back.ClipsDescendants = true
	gradient.Color = style.mid and ColorSequence.new({ ColorSequenceKeypoint.new(0, style.top), ColorSequenceKeypoint.new(0.5, style.mid), ColorSequenceKeypoint.new(1, style.bottom) }) or ColorSequence.new(style.top, style.bottom)
	-- Figuren in den unteren Teil, damit der Titel Platz hat
	view.Position = UDim2.fromScale(0, big and 0.3 or 0.24)
	view.Size = UDim2.fromScale(1, big and 0.7 or 0.76)
	local z = view.ZIndex
	local poster = create("Frame", { Name = "Poster", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z - 1, Parent = back })
	local accent = style.accent
	if style.deco == "rays" then
		-- Strahlenkranz hinter den Figuren
		for i = 0, 8 do
			create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.72), Size = UDim2.new(0, big and 26 or 14, 2.4, 0), Rotation = i * 20 - 80, BackgroundColor3 = accent, BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = z - 1, Parent = poster })
		end
	elseif style.deco == "scratches" then
		-- Kratzspuren wie von Krallen
		for i = 0, 3 do
			create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.74 + i * 0.05, 0, 0.52, 0), Size = UDim2.new(0, big and 4 or 2, 0.9, 0), Rotation = 18, BackgroundColor3 = Color3.fromRGB(10, 2, 3), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = z - 1, Parent = poster })
		end
	elseif style.deco == "stars" then
		local rng = Random.new(7)
		for _ = 1, 18 do
			local size = rng:NextInteger(2, big and 4 or 3)
			create("Frame", { Position = UDim2.fromScale(rng:NextNumber(0.03, 0.97), rng:NextNumber(0.3, 0.9)), Size = UDim2.fromOffset(size, size), BackgroundColor3 = accent, BackgroundTransparency = rng:NextNumber(0.1, 0.5), BorderSizePixel = 0, ZIndex = z - 1, Parent = poster }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		end
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.82, 0.38), Size = UDim2.fromOffset(big and 34 or 18, big and 34 or 18), BackgroundColor3 = Color3.fromRGB(236, 232, 210), ZIndex = z - 1, Parent = poster }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	elseif style.deco == "stripes" then
		for i = 0, 2 do
			create("Frame", { Position = UDim2.new(0, 0, 0.27 + i * 0.035, 0), Size = UDim2.new(1, 0, 0, big and 3 or 2), BackgroundColor3 = accent, BackgroundTransparency = 0.55 + i * 0.12, BorderSizePixel = 0, ZIndex = z - 1, Parent = poster })
		end
	end
	-- Innenrahmen wie bei einem gedruckten Plakat
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, big and -14 or -8, 1, big and -14 or -8), BackgroundTransparency = 1, ZIndex = z + 1, Parent = poster }, {
		create("UIStroke", { Color = accent, Thickness = big and 2 or 1, Transparency = 0.45 }),
	})
	-- großer Titel und Spruch
	local title = create("TextLabel", {
		Name = "PosterTitle",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, big and 12 or 6),
		Size = UDim2.new(1, big and -30 or -16, 0.17, 0),
		BackgroundTransparency = 1,
		Font = style.font,
		Text = style.title,
		TextScaled = true,
		TextColor3 = accent,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 0.35,
		ZIndex = z + 2,
		Parent = poster,
	}, { create("UITextSizeConstraint", { MaxTextSize = big and 46 or 26 }) })
	create("TextLabel", {
		Name = "PosterTag",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.17, big and 14 or 6),
		Size = UDim2.new(1, -24, 0.07, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.SpecialElite,
		Text = style.tag:upper(),
		TextScaled = true,
		TextColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.2),
		TextTransparency = 0.1,
		ZIndex = z + 2,
		Parent = poster,
	}, { create("UITextSizeConstraint", { MaxTextSize = big and 15 or 10 }) })
	return title
end

------------------------------------------------------------------ Logos der Gamepässe
-- Abzeichen: runder Rand, Ring, gezeichnetes Symbol, Banner mit Namen
local LOGOS = {
	ThreeHearts = { top = Color3.fromRGB(150, 28, 36), bottom = Color3.fromRGB(46, 6, 10), accent = Color3.fromRGB(255, 196, 176), label = "3 HEARTS" },
	DoubleCoins = { top = Color3.fromRGB(150, 110, 32), bottom = Color3.fromRGB(52, 34, 8), accent = Color3.fromRGB(255, 226, 150), label = "2X COINS" },
	StrongFlashlight = { top = Color3.fromRGB(46, 60, 84), bottom = Color3.fromRGB(10, 14, 22), accent = Color3.fromRGB(255, 238, 176), label = "FLASHLIGHT" },
	Supervision = { top = Color3.fromRGB(34, 84, 70), bottom = Color3.fromRGB(8, 24, 20), accent = Color3.fromRGB(196, 255, 224), label = "SUPERVISION" },
	VipCar = { top = Color3.fromRGB(44, 40, 44), bottom = Color3.fromRGB(8, 8, 10), accent = Color3.fromRGB(236, 196, 96), label = "VIP CAR" },
}

local function round(frame)
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = frame })
	return frame
end

-- kleines Teil im Symbol-Feld (Position/Größe in Anteilen des Feldes)
local function shape(parent, x, y, w, h, color, z, props)
	local f = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z, Parent = parent })
	for key, value in props or {} do
		f[key] = value
	end
	return f
end

local function heart(parent, x, y, size, color, z)
	local box = shape(parent, x, y, size, size, color, z, { BackgroundTransparency = 1 })
	round(shape(box, 0.3, 0.36, 0.52, 0.52, color, z))
	round(shape(box, 0.7, 0.36, 0.52, 0.52, color, z))
	shape(box, 0.5, 0.56, 0.52, 0.52, color, z, { Rotation = 45 })
	return box
end

local ICONS = {}
function ICONS.ThreeHearts(icon, style, z)
	heart(icon, 0.24, 0.56, 0.34, Color3.fromRGB(200, 40, 46), z)
	heart(icon, 0.76, 0.56, 0.34, Color3.fromRGB(200, 40, 46), z)
	heart(icon, 0.5, 0.46, 0.48, Color3.fromRGB(236, 60, 62), z + 1)
end
function ICONS.DoubleCoins(icon, style, z)
	local coin = round(shape(icon, 0.5, 0.5, 0.8, 0.8, T.coin, z))
	create("UIStroke", { Color = T.coinEdge, Thickness = 3, Parent = coin })
	local ring = round(shape(coin, 0.5, 0.5, 0.8, 0.8, T.coin, z, { BackgroundTransparency = 1 }))
	create("UIStroke", { Color = T.coinEdge, Thickness = 2, Transparency = 0.3, Parent = ring })
	create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.8, 0.6), BackgroundTransparency = 1, Font = Enum.Font.Bangers, Text = "2x", TextScaled = true, TextColor3 = Color3.fromRGB(90, 58, 16), ZIndex = z + 1, Parent = coin })
end
function ICONS.StrongFlashlight(icon, style, z)
	-- Lichtkegel
	local beam = shape(icon, 0.66, 0.36, 0.9, 0.42, style.accent, z, { Rotation = -35 })
	create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) }), Parent = beam })
	-- Lampe
	local body = shape(icon, 0.34, 0.66, 0.46, 0.16, Color3.fromRGB(40, 40, 46), z + 1, { Rotation = -35 })
	create("UICorner", { CornerRadius = UDim.new(0.3, 0), Parent = body })
	shape(icon, 0.5, 0.54, 0.18, 0.26, Color3.fromRGB(70, 70, 78), z + 1, { Rotation = -35 })
	round(shape(icon, 0.55, 0.5, 0.12, 0.12, Color3.fromRGB(255, 246, 210), z + 2))
end
function ICONS.Supervision(icon, style, z)
	for i = 0, 7 do
		shape(icon, 0.5, 0.5, 0.03, 0.98, style.accent, z, { Rotation = i * 22.5, BackgroundTransparency = 0.55 })
	end
	local white = shape(icon, 0.5, 0.5, 0.82, 0.46, Color3.fromRGB(240, 236, 226), z + 1)
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = white })
	round(shape(icon, 0.5, 0.5, 0.36, 0.36, Color3.fromRGB(60, 170, 120), z + 2))
	round(shape(icon, 0.5, 0.5, 0.17, 0.17, Color3.fromRGB(10, 14, 12), z + 3))
	round(shape(icon, 0.56, 0.44, 0.06, 0.06, Color3.new(1, 1, 1), z + 4))
end
function ICONS.VipCar(icon, style, z)
	for i = -1, 1 do
		local star = create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + i * 0.22, i == 0 and 0.16 or 0.22), Size = UDim2.fromScale(0.2, 0.2), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "★", TextScaled = true, TextColor3 = style.accent, ZIndex = z, Parent = icon })
		star.Rotation = i * 12
	end
	local red = Color3.fromRGB(150, 26, 32)
	local body = shape(icon, 0.5, 0.62, 0.92, 0.2, red, z)
	create("UICorner", { CornerRadius = UDim.new(0.35, 0), Parent = body })
	local cabin = shape(icon, 0.47, 0.49, 0.48, 0.16, red:Lerp(Color3.new(0, 0, 0), 0.15), z)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = cabin })
	shape(icon, 0.47, 0.5, 0.36, 0.09, Color3.fromRGB(150, 190, 210), z + 1)
	for _, x in { 0.27, 0.73 } do
		round(shape(icon, x, 0.74, 0.18, 0.18, Color3.fromRGB(20, 20, 22), z + 1))
		round(shape(icon, x, 0.74, 0.08, 0.08, style.accent, z + 2))
	end
end

-- Logo in ein „Foto“-Feld legen (über dem leeren Vorschaufenster); nil entfernt es
local function passLogo(view, id, big)
	local back = view.Parent
	local old = back:FindFirstChild("Logo")
	if old then
		old:Destroy()
	end
	local style = id and LOGOS[id]
	if not style then
		return
	end
	local z = view.ZIndex + 1
	local holder = create("Frame", { Name = "Logo", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z, Parent = back })
	-- rundes Abzeichen, immer quadratisch und mittig
	local badge = round(create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.86, 0.86), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = z, Parent = holder }, {
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(style.top, style.bottom) }),
		create("UIStroke", { Color = style.accent, Thickness = big and 5 or 3 }),
	}))
	local ring = round(create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.84, 0.84), BackgroundTransparency = 1, ZIndex = z, Parent = badge }))
	create("UIStroke", { Color = style.accent, Thickness = big and 2 or 1, Transparency = 0.4, Parent = ring })
	local icon = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.56, 0.56), BackgroundTransparency = 1, ZIndex = z + 1, Parent = badge })
	ICONS[id](icon, style, z + 1)
	-- Banner mit Namen quer über den unteren Teil
	local banner = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromScale(1.16, 0.22), BackgroundColor3 = style.accent, ZIndex = z + 6, Parent = badge }, {
		create("UICorner", { CornerRadius = UDim.new(0, 3) }),
		create("UIStroke", { Color = style.bottom, Thickness = big and 3 or 2 }),
	})
	create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.9, 0.78), BackgroundTransparency = 1, Font = Enum.Font.Oswald, Text = style.label, TextScaled = true, TextColor3 = style.bottom, ZIndex = z + 7, Parent = banner })
	-- Bänder-Enden
	for _, side in { -1, 1 } do
		shape(badge, 0.5 + side * 0.6, 0.82, 0.12, 0.16, style.accent:Lerp(Color3.new(0, 0, 0), 0.3), z + 5, { Rotation = side * 12 })
	end
	return holder
end

local function priceRow(parent, z)
	return create("Frame", { Name = "PriceRow", BackgroundTransparency = 1, ZIndex = z, Parent = parent }, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
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

-- unten links: Münzen und ein kleines Holzschild „Shop“ (groß genug zum Tippen)
local hud = create("Frame", { Name = "Hud", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -18), Size = UDim2.fromOffset(170, 96), BackgroundTransparency = 1, Parent = gui })
local hudCoinRow = create("Frame", { Name = "CoinRow", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = hud }, {
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
coinIcon(hudCoinRow, 20, 2).LayoutOrder = 1
local hudCoins = text({ Name = "Coins", Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = 18, Text = "0", TextColor3 = T.paper, TextStrokeTransparency = 0.5, LayoutOrder = 2, Parent = hudCoinRow })
local hudButton = create("TextButton", {
	Name = "OpenShop",
	Position = UDim2.fromOffset(0, 38),
	Size = UDim2.fromOffset(150, 56),
	Rotation = -2,
	BackgroundColor3 = T.wood,
	AutoButtonColor = true,
	Font = T.titleFont,
	Text = "Shop",
	TextSize = 28,
	TextColor3 = T.paper,
	Parent = hud,
}, { corner(6), create("UIStroke", { Color = T.woodDark, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })
nail(hudButton, UDim2.new(0, 10, 0.5, 0), 2)
nail(hudButton, UDim2.new(1, -10, 0.5, 0), 2)

local overlay = create("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, Visible = false, ZIndex = 10, Parent = gui })
-- die Bretterwand
local root = create("Frame", {
	Name = "Root",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(1040, 640),
	BackgroundColor3 = T.woodDark,
	ZIndex = 11,
	Parent = overlay,
}, { corner(10), create("UIStroke", { Color = Color3.fromRGB(22, 15, 11), Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })
planks(root, 9, 11, false)
local vignette = create("Frame", { Name = "Vignette", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 11, Parent = root }, {
	corner(10),
	create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.75, 1), NumberSequenceKeypoint.new(1, 0.45) }) }),
})
for _, pos in { UDim2.fromOffset(12, 12), UDim2.new(1, -12, 0, 12), UDim2.new(0, 12, 1, -12), UDim2.new(1, -12, 1, -12) } do
	nail(root, pos, 12)
end

local rootScale = create("UIScale", { Parent = root })
-- warmes Laternenlicht von oben (flackert leicht, solange das Fenster offen ist)
local lantern = create("Frame", { Name = "LanternGlow", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0.8, 0, 0, 260), BackgroundColor3 = Color3.fromRGB(255, 186, 110), BackgroundTransparency = 0, ZIndex = 11, Parent = root }, {
	create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1) }) }),
})

-- Kopfzeile: Holzschild mit Namen, rechts Messingschild mit Münzen und Schließen
local sign = create("Frame", { Name = "Sign", BackgroundColor3 = T.woodLight, Rotation = -1, ZIndex = 12, Parent = root }, {
	corner(6),
	create("UIStroke", { Color = T.woodDark, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.78, 0.78, 0.78)) }),
})
nail(sign, UDim2.new(0, 10, 0.5, 0), 13)
nail(sign, UDim2.new(1, -10, 0.5, 0), 13)
local titleLabel = text({ Name = "Title", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, Font = T.titleFont, TextSize = 32, Text = "Shop", TextColor3 = T.paper, TextStrokeColor3 = T.woodDark, TextStrokeTransparency = 0.3, ZIndex = 13, Parent = sign })
local subtitle = text({ Name = "Subtitle", Font = Enum.Font.SpecialElite, TextSize = 15, TextColor3 = T.paperShade, Text = "", TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 12, Parent = root })
local coinBox = create("TextButton", { Name = "CoinBox", AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(170, T.touch), BackgroundColor3 = T.brass, AutoButtonColor = true, Text = "", ZIndex = 12, Parent = root }, {
	corner(6),
	create("UIStroke", { Color = T.brassDark, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.8, 0.78, 0.72)) }),
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
coinIcon(coinBox, 22, 13).LayoutOrder = 1
local coinsLabel = text({ Name = "Amount", Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = 18, TextColor3 = T.ink, Text = "0", ZIndex = 13, LayoutOrder = 2, Parent = coinBox })
local testNote = text({ Name = "TestNote", AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(220, 14), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.paperShade, Text = "Studio test coins, not saved", Visible = false, ZIndex = 12, Parent = root })
local closeButton = create("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(T.touch, T.touch),
	BackgroundColor3 = T.wood,
	AutoButtonColor = true,
	Font = T.titleFont,
	Text = "X",
	TextSize = 24,
	TextColor3 = T.paper,
	Modal = true, -- Maus frei, solange das Fenster offen ist
	ZIndex = 12,
	Parent = root,
}, { corner(6), create("UIStroke", { Color = T.woodDark, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })

-- Reiter: Papieretiketten an der Wand (aktives Etikett hell, die anderen vergilbt)
local tabBar = create("Frame", { Name = "Tabs", BackgroundTransparency = 1, ZIndex = 12, Parent = root }, {
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }),
})

-- Karten
local grid = create("ScrollingFrame", {
	Name = "Grid",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = T.paperShade,
	ScrollBarImageTransparency = 0.4,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 12,
	Parent = root,
}, {
	create("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 6) }),
})
local gridLayout = create("UIGridLayout", { CellSize = UDim2.fromOffset(200, 230), CellPadding = UDim2.fromOffset(14, 16), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })

-- rechts: Zettel wie eine Quittung (Anprobe, Beschreibung, Bezahlen)
local detail = create("Frame", { Name = "Detail", BackgroundColor3 = T.paper, ZIndex = 12, Parent = root }, {
	corner(3),
	create("UIStroke", { Color = T.paperShade, Thickness = 1 }),
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.93, 0.91, 0.86)) }),
})
tape(detail, UDim2.new(0.5, 0, 0, 0), -3, 16)
-- Kaffeefleck
create("Frame", { Name = "CoffeeRing", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -36, 1, -86), Size = UDim2.fromOffset(58, 58), BackgroundTransparency = 1, ZIndex = 12, Parent = detail }, {
	create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	create("UIStroke", { Color = Color3.fromRGB(150, 110, 70), Thickness = 3, Transparency = 0.78 }),
})
local stageBack, stage = photo(detail, 13)
stageBack.Name = "Stage"
local stageHint = text({ Name = "Hint", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -8), Size = UDim2.fromOffset(120, 14), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.paperShade, Text = "Drag to turn", ZIndex = 15, Parent = stageBack })
local resetButton = create("TextButton", { Name = "Reset", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(84, 36), BackgroundColor3 = T.paper, AutoButtonColor = true, Font = T.titleFont, Text = "Reset", TextSize = 16, TextColor3 = T.ink, ZIndex = 15, Visible = false, Parent = stageBack }, { corner(3), create("UIStroke", { Color = T.ink, Thickness = 1, Transparency = 0.5 }) })
local info = create("Frame", { Name = "Info", BackgroundTransparency = 1, ZIndex = 13, Parent = detail }, {
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local kindRow = create("Frame", { Name = "KindRow", Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 13, Parent = info }, {
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local rarityDot = create("Frame", { Name = "Dot", Size = UDim2.fromOffset(8, 8), BackgroundColor3 = T.inkMuted, LayoutOrder = 1, ZIndex = 13, Parent = kindRow }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
local kindLabel = text({ Name = "Kind", Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.SpecialElite, TextSize = 13, TextColor3 = T.inkMuted, Text = "", LayoutOrder = 2, ZIndex = 13, Parent = kindRow })
local nameLabel = text({ Name = "Name", Size = UDim2.new(1, 0, 0, 30), Font = T.titleFont, TextSize = 26, TextColor3 = T.ink, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", LayoutOrder = 2, ZIndex = 13, Parent = info })
dashedLine(info, 3, 13)
local descLabel = text({ Name = "Description", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.SpecialElite, TextSize = 14, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = T.inkMuted, Text = "", LayoutOrder = 4, ZIndex = 13, Parent = info })
local statusLabel = text({ Name = "Status", Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.SpecialElite, TextSize = 15, TextColor3 = T.inkGreen, Text = "", LayoutOrder = 5, ZIndex = 13, Parent = info })
local actions = create("Frame", { Name = "Actions", AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, ZIndex = 13, Parent = detail })

-- Meldung als kleiner Papierzettel unten in der Mitte
local message = create("TextLabel", {
	Name = "Message",
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(0, 34),
	AutomaticSize = Enum.AutomaticSize.X,
	Rotation = -1,
	BackgroundColor3 = T.paper,
	Font = Enum.Font.SpecialElite,
	TextSize = 16,
	Text = "",
	TextColor3 = T.ink,
	Visible = false,
	ZIndex = 20,
	Parent = root,
}, { corner(2), create("UIStroke", { Color = T.paperShade, Thickness = 1 }), create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }) })
local messageToken = 0
local function say(textValue, color)
	messageToken += 1
	local token = messageToken
	message.Text = textValue
	message.TextColor3 = color or T.ink
	message.Visible = true
	task.delay(3.5, function()
		if token == messageToken then
			message.Visible = false
		end
	end)
end

------------------------------------------------------------------ Aufbau je nach Bildschirmgröße
local layout = { compact = false, cardText = 18 }
local function applyLayout()
	local area = gui.AbsoluteSize
	if area.X < 50 then
		return
	end
	local W = math.min(area.X - 24, 1040)
	local H = math.min(area.Y - 24, 640)
	local compact = H < 520 or W < 860
	layout.compact = compact
	root.Size = UDim2.fromOffset(W, H)
	local pad = compact and 14 or 26
	local headerH = compact and 58 or 80
	-- Holzschild mit Namen
	sign.Position = UDim2.fromOffset(pad, compact and 6 or 12)
	sign.Size = UDim2.fromOffset(compact and 170 or 230, compact and 44 or 54)
	titleLabel.TextSize = compact and 26 or 34
	subtitle.Visible = not compact
	subtitle.Position = UDim2.fromOffset(pad + 250, 30)
	subtitle.Size = UDim2.fromOffset(math.max(W - 2 * pad - 250 - 250, 120), 20)
	closeButton.Position = UDim2.new(1, -pad, 0, compact and 6 or 16)
	coinBox.Position = UDim2.new(1, -pad - T.touch - 10, 0, compact and 6 or 16)
	coinBox.Size = UDim2.fromOffset(compact and 130 or 170, T.touch)
	testNote.Position = UDim2.new(1, -pad - T.touch - 10, 0, (compact and 6 or 16) + T.touch + 2)
	testNote.Visible = testNote:GetAttribute("Wanted") == true and not compact
	-- Etiketten
	tabBar.Position = UDim2.fromOffset(pad, headerH)
	tabBar.Size = UDim2.new(1, -2 * pad, 0, T.touch)
	-- Inhalt: Karten links an der Wand, Zettel rechts
	local top = headerH + T.touch + 8
	local contentH = H - top - pad
	local detailW = compact and math.floor(W * 0.42) or 348
	local gridW = W - 2 * pad - detailW - (compact and 10 or 20)
	grid.Position = UDim2.fromOffset(pad - 6, top - 10)
	grid.Size = UDim2.fromOffset(gridW + 6, contentH + 10)
	detail.Position = UDim2.fromOffset(W - pad - detailW, top)
	detail.Size = UDim2.fromOffset(detailW, contentH)
	local usable = gridW - 18
	local columns = usable >= 600 and 3 or usable >= 300 and 2 or 1
	local gap = compact and 10 or 14
	local cellW = math.floor((usable - gap * (columns - 1)) / columns)
	local thumbH = math.floor(cellW * (compact and 0.56 or 0.64))
	layout.cardText = compact and 15 or 18
	gridLayout.CellPadding = UDim2.fromOffset(gap, compact and 12 or 16)
	gridLayout.CellSize = UDim2.fromOffset(cellW, thumbH + (compact and 62 or 78))
	layout.thumbH = thumbH
	-- Zettel: Foto oben, Text, Knöpfe unten
	local inner = compact and 10 or 14
	local stageH = math.floor(math.clamp(contentH * (compact and 0.4 or 0.46), 110, 280))
	stageBack.Position = UDim2.fromOffset(inner, inner + 4)
	stageBack.Size = UDim2.new(1, -2 * inner, 0, stageH)
	local actionsH = (detailW - 2 * inner >= 280) and T.touch or (T.touch * 2 + 8)
	info.Position = UDim2.fromOffset(inner + 4, inner + stageH + (compact and 8 or 14))
	info.Size = UDim2.new(1, -2 * inner - 8, 0, contentH - stageH - actionsH - inner * 3 - 4)
	info.ClipsDescendants = true
	nameLabel.TextSize = compact and 20 or 26
	nameLabel.Size = UDim2.new(1, 0, 0, compact and 24 or 30)
	descLabel.TextSize = compact and 12 or 14
	actions.Position = UDim2.new(0, inner, 1, -inner)
	actions.Size = UDim2.new(1, -2 * inner, 0, actionsH)
	message.Position = UDim2.new(0.5, 0, 1, -pad)
end

------------------------------------------------------------------ Karten
local mode = "shop"
local currentTab
local selected
local cards = {}
local tabButtons = {}
local turn = math.rad(-18)
local aimStage

-- Preis auf dem Papier: Münze + Zahl, „or“, R$ in grüner Tinte
local function fillPrice(row, entry, size, z)
	for _, child in row:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	if isOwned(entry) then
		local wearing = entry.slot and state.equipped[entry.slot] == entry.id
		text({ Size = UDim2.fromOffset(0, size + 6), AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.SpecialElite, TextSize = size, TextColor3 = T.inkGreen, Text = wearing and "wearing it" or "in your bag", ZIndex = z, LayoutOrder = 1, Parent = row })
		return
	end
	local coins, robux, oldCoins, oldRobux = prices(entry)
	if coins then
		coinIcon(row, size - 1, z).LayoutOrder = 1
		text({ Size = UDim2.fromOffset(0, size + 4), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = size, TextColor3 = T.ink, RichText = true, Text = struck(oldCoins, coins), ZIndex = z, LayoutOrder = 2, Parent = row })
	end
	if robux then
		if coins then
			text({ Size = UDim2.fromOffset(0, size + 4), AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.SpecialElite, TextSize = size - 1, TextColor3 = T.inkMuted, Text = "or", ZIndex = z, LayoutOrder = 3, Parent = row })
		end
		text({ Size = UDim2.fromOffset(0, size + 4), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = size, TextColor3 = T.inkGreen, RichText = true, Text = "R$ " .. struck(oldRobux, robux), ZIndex = z, LayoutOrder = 4, Parent = row })
	end
	if not entry.coins and not entry.robux and entry.pack then
		local pack = byId[entry.pack]
		text({ Size = UDim2.fromOffset(0, size + 4), AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.SpecialElite, TextSize = size - 1, TextColor3 = T.inkMuted, Text = "in the " .. (pack and pack.title or "bundle"), ZIndex = z, LayoutOrder = 1, Parent = row })
	end
	if entry.kind == "Item" and (state.items[entry.id] or 0) > 0 then
		text({ Size = UDim2.fromOffset(0, size + 4), AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.SpecialElite, TextSize = size - 1, TextColor3 = T.inkGreen, Text = "  (" .. state.items[entry.id] .. " in bag)", ZIndex = z, LayoutOrder = 5, Parent = row })
	end
end

-- Klebeband je Karte etwas anders schief (die Karten selbst bleiben gerade: Vorschaufenster drehen nicht mit)
local TILT = { -1.6, 1.1, -0.6, 1.5, -1.2, 0.7, -0.4, 1.3 }

local function styleCard(card)
	local active = selected == card.entry
	card.stroke.Color = active and T.stamp or T.woodDark
	card.stroke.Thickness = active and 3 or 2
	card.stroke.Transparency = active and 0 or 0.35
	card.frame:SetAttribute("RestScale", active and 1.02 or 1)
	if card.scale.Scale < 1.03 then
		tween(card.scale, 0.18, { Scale = active and 1.02 or 1 })
	end
	fillPrice(card.price, card.entry, layout.compact and 13 or 15, 16)
	local owned = isOwned(card.entry)
	if owned and card.stampShown == false then
		-- gerade gekauft: Stempel kommt groß und knallt auf die Karte
		card.stamp.Visible = true
		local stampScale = card.stamp:FindFirstChildOfClass("UIScale")
		stampScale.Scale = 2.2
		card.stamp.TextTransparency = 1
		tween(stampScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(card.stamp, 0.2, { TextTransparency = 0.12 })
	else
		card.stamp.Visible = owned
	end
	card.stampShown = owned
end

local select -- weiter unten

local thumbQueue = {}
local function makeCard(entry, order)
	local tilt = TILT[(order - 1) % #TILT + 1]
	local frame = create("TextButton", { Name = entry.id, BackgroundColor3 = T.paper, AutoButtonColor = false, Text = "", LayoutOrder = order, ZIndex = 14, Parent = grid }, {
		corner(2),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.92, 0.9, 0.84)) }),
	})
	local stroke = create("UIStroke", { Color = T.paperShade, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
	local pic, view = photo(frame, 15)
	pic.Position = UDim2.fromOffset(8, 8)
	pic.Size = UDim2.new(1, -16, 0, layout.thumbH or 130)
	decoratePoster(view, entry, false)
	passLogo(view, entry.logo, false)
	tape(frame, UDim2.new(0.5, 0, 0, 0), tilt * -3, 18)
	if entry.note then
		-- gelber Notizzettel mit roter Schrift
		-- unten rechts auf dem Bild, damit er den Plakat-Titel nicht verdeckt
		local note = text({ Name = "Note", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -4, 0, (layout.thumbH or 130) + 2), Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, Rotation = 4, Font = Enum.Font.SpecialElite, TextSize = 13, TextColor3 = T.stamp, Text = entry.note, ZIndex = 19, Parent = frame })
		note.BackgroundTransparency = 0
		note.BackgroundColor3 = Color3.fromRGB(240, 222, 120)
		create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = note })
	end
	local titleY = (layout.thumbH or 130) + 14
	text({ Name = "Title", Position = UDim2.fromOffset(12, titleY), Size = UDim2.new(1, -24, 0, layout.cardText + 4), Font = T.titleFont, TextSize = layout.cardText, TextColor3 = T.ink, TextTruncate = Enum.TextTruncate.AtEnd, Text = entry.title, ZIndex = 16, Parent = frame })
	local price = priceRow(frame, 16)
	price.Position = UDim2.fromOffset(12, titleY + layout.cardText + 8)
	price.Size = UDim2.new(1, -24, 0, (layout.compact and 13 or 15) + 6)
	local stamp = stampLabel(frame, "OWNED", 19)
	stamp.Visible = false
	create("UIScale", { Parent = stamp })
	local cardScale = alive(frame, { hover = 1.035 })
	local card = { entry = entry, frame = frame, stroke = stroke, price = price, thumb = view, tilt = tilt, stamp = stamp, scale = cardScale }
	frame.MouseEnter:Connect(function()
		if selected ~= entry then
			stroke.Color = T.brassDark
			stroke.Transparency = 0
		end
	end)
	frame.MouseLeave:Connect(function()
		styleCard(card)
	end)
	frame.Activated:Connect(function()
		select(entry)
	end)
	styleCard(card)
	card.stampShown = isOwned(entry) -- erst ab jetzt „knallt“ ein neuer Stempel
	if not isOwned(entry) then
		card.stampShown = false
	end
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

local function styleTab(button, active)
	button.BackgroundColor3 = active and T.paper or T.paperShade:Lerp(T.wood, 0.35)
	button.TextColor3 = active and T.ink or T.inkMuted
	button.Rotation = active and 0 or button:GetAttribute("Tilt")
	button.Size = UDim2.new(0, 0, 0, active and T.touch or T.touch - 6)
end

local function showTab(tab)
	currentTab = tab
	for id, button in tabButtons do
		styleTab(button, id == tab)
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
	for index, info_ in list do
		local button = create("TextButton", {
			Name = info_[1],
			Size = UDim2.new(0, 0, 0, T.touch),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = T.paperShade,
			AutoButtonColor = true,
			Font = T.titleFont,
			Text = info_[2],
			TextSize = layout.compact and 16 or 19,
			TextColor3 = T.inkMuted,
			LayoutOrder = index,
			ZIndex = 13,
			Parent = tabBar,
		}, { corner(2), create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
		button:SetAttribute("Tilt", (index % 2 == 0) and 1.5 or -1.2)
		alive(button, { hover = 1.06 })
		button.Activated:Connect(function()
			showTab(info_[1])
			if cards[1] then
				select(cards[1].entry)
			end
		end)
		tabButtons[info_[1]] = button
	end
end

------------------------------------------------------------------ Anprobe und Knöpfe
local function refreshStage()
	if not selected then
		return
	end
	local entry = selected
	local model = previewFor(entry, fitting)
	if selected ~= entry then
		return
	end
	aimStage = show(stage, model, turn)
	local wearing = fitting.suit ~= nil or next(fitting.items) ~= nil
	resetButton.Visible = entry.preview ~= nil and entry.preview.kind == "fitting" and wearing
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

-- großer Knopf (48 hoch). style: "brass" (Münzen), "felt" (Robux), "paper" (leise)
local BUTTON_STYLES = {
	brass = { fill = T.brass, edge = T.brassDark, text = T.ink, font = T.boldFont },
	felt = { fill = Color3.fromRGB(44, 92, 62), edge = Color3.fromRGB(22, 52, 34), text = T.paper, font = T.boldFont },
	paper = { fill = T.paper, edge = T.ink, text = T.ink, font = T.titleFont },
	dim = { fill = T.paperShade, edge = T.inkMuted, text = T.inkMuted, font = T.boldFont },
}
local function bigButton(parent, label, style, order, onClick, options)
	options = options or {}
	local look = BUTTON_STYLES[style]
	local b = create("TextButton", {
		Size = UDim2.new(options.width or 1, options.width and -5 or 0, 0, T.touch),
		BackgroundColor3 = look.fill,
		AutoButtonColor = onClick ~= nil,
		Text = "",
		LayoutOrder = order,
		ZIndex = 14,
		Parent = parent,
	}, {
		corner(5),
		create("UIStroke", { Color = look.edge, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.84, 0.82, 0.78)) }),
	})
	-- Inhalt in eigenem Rahmen (die Anordnung soll den Lichtschimmer nicht mit verschieben)
	local content = create("Frame", { Name = "Content", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 15, Parent = b }, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	if options.coins then
		coinIcon(content, 20, 15).LayoutOrder = 1
	end
	text({ Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, Font = look.font, TextSize = 17, TextColor3 = look.text, RichText = true, Text = label, ZIndex = 15, LayoutOrder = 2, Parent = content })
	if onClick then
		alive(b, { shine = true, shineZ = 14, hover = 1.03 })
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
			say("Robux purchases open soon.", T.ink)
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
		say("Robux purchases open soon.", T.ink)
		return
	end
	MarketplaceService:PromptProductPurchase(player, productId)
end

local function buyWithCoins(entry)
	if state.coins < entry.coins then
		say("You need " .. money(entry.coins - state.coins) .. " more coins.", T.stamp)
		return
	end
	local ok, result = remotes.BuyWithCoins:InvokeServer(entry.id)
	say(result or (ok and "Done." or "Something went wrong."), ok and T.inkGreen or T.stamp)
end

local function equip(entry, on)
	local ok, result = remotes.Equip:InvokeServer(entry.slot, on and entry.id or nil)
	if ok then
		say(on and ("You are wearing " .. entry.title .. ".") or (entry.title .. " taken off."), T.inkGreen)
	else
		say(result or "Something went wrong.", T.stamp)
	end
end

local function renderActions(entry)
	actions:ClearAllChildren()
	statusLabel.Text = ""
	statusLabel.TextColor3 = T.inkGreen
	local rows = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 13, Parent = actions }, {
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom }),
	})
	if isOwned(entry) then
		if entry.slot then
			local on = state.equipped[entry.slot] == entry.id
			statusLabel.Text = on and "You are wearing this." or "It's yours."
			bigButton(rows, on and "Take off" or "Wear", on and "paper" or "brass", 2, function()
				equip(entry, not on)
			end)
		else
			statusLabel.Text = entry.kind == "Pack" and "This bundle is yours." or "It's yours."
		end
		return
	end
	if entry.kind == "Item" then
		statusLabel.Text = "In your bag: " .. (state.items[entry.id] or 0)
		statusLabel.TextColor3 = T.inkMuted
	end
	if entry.pack and not entry.coins and not entry.robux then
		local pack = byId[entry.pack]
		bigButton(rows, "See the " .. (pack and pack.title or "bundle"), "paper", 2, function()
			if pack then
				showTab(pack.tab)
				select(pack)
			end
		end)
		return
	end
	-- zwei Wege zu bezahlen: nebeneinander, wenn Platz ist, sonst untereinander
	local both = entry.coins and entry.robux
	local sideBySide = both and actions.AbsoluteSize.X >= 280
	local holder = rows
	if sideBySide then
		holder = create("Frame", { Size = UDim2.new(1, 0, 0, T.touch), BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 13, Parent = rows }, {
			create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
	end
	local coins, robux, oldCoins, oldRobux = prices(entry)
	if coins then
		local afford = state.coins >= coins
		bigButton(holder, struck(oldCoins, coins), afford and "brass" or "dim", 1, function()
			buyWithCoins(entry)
		end, { coins = true, width = sideBySide and 0.5 or nil })
	end
	if robux then
		bigButton(holder, "R$ " .. struck(oldRobux, robux), "felt", 3, function()
			promptRobux(entry)
		end, { width = sideBySide and 0.5 or nil })
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
	kindLabel.Text = (kinds[entry.kind] or "") .. (rarity and (" · " .. rarity.title:sub(1, 1) .. rarity.title:sub(2):lower()) or "")
	rarityDot.Visible = rarity ~= nil
	rarityDot.BackgroundColor3 = rarity and rarity.color:Lerp(T.ink, 0.35) or T.inkMuted
	nameLabel.Text = entry.title
	local description = entry.description or ""
	if entry.contents then
		description ..= "\nIncludes: " .. table.concat(entry.contents, ", ")
	end
	descLabel.Text = description
	stage:ClearAllChildren()
	decoratePoster(stage, entry, true)
	passLogo(stage, entry.logo, true)
	stageHint.Visible = entry.preview ~= nil -- nur drehbare 3D-Bilder
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
stageBack.InputBegan:Connect(function(input)
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
	applyLayout()
	if wantedMode and wantedMode ~= mode then
		mode = wantedMode
		currentTab = nil
	end
	buildTabs(mode == "kiosk" and KIOSK_TABS or SHOP_TABS)
	titleLabel.Text = mode == "kiosk" and "Kiosk" or "Shop"
	subtitle.Text = mode == "kiosk" and "Snacks for the long night. Max. 3 per round." or "Open late. Try anything on. No refunds."
	fitting.suit = state.equipped.Player
	table.clear(fitting.items)
	local entry = target and byId[target]
	local tabTarget = not entry and target or nil -- auch ein Reiter als Ziel ("Skins")
	hud.Visible = false
	overlay.Visible = true
	showTab(entry and entry.tab or tabTarget or currentTab or (mode == "kiosk" and "Snacks" or "Bundles"))
	if entry then
		select(entry)
	elseif cards[1] then
		select(cards[1].entry)
	end
	-- einblenden: Abdunklung und das Fenster federt auf (außer bei „weniger Bewegung“)
	if not calm() then
		overlay.BackgroundTransparency = 1
		rootScale.Scale = 0.9
		tween(overlay, 0.18, { BackgroundTransparency = 0.4 })
		tween(rootScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		rootScale.Scale = 1
	end
end

-- Bildschirmgröße ändert sich (Fenster, Drehen des Handys): neu anordnen
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if open then
		applyLayout()
		showTab(currentTab)
		if selected then
			select(selected)
		end
	end
end)

alive(hudButton, { shine = true, shineZ = 2, hover = 1.06 })
alive(closeButton, { hover = 1.08 })
alive(coinBox, { hover = 1.04 })
alive(resetButton, { hover = 1.06 })

-- Laterne flackert (nur solange offen)
task.spawn(function()
	local rng = Random.new()
	while true do
		task.wait(rng:NextNumber(0.08, 0.35))
		if open and not calm() then
			local dip = rng:NextNumber() < 0.1
			lantern.BackgroundTransparency = dip and rng:NextNumber(0.35, 0.55) or rng:NextNumber(0, 0.12)
		elseif open then
			lantern.BackgroundTransparency = 0.05
		end
	end
end)

hudButton.Activated:Connect(function()
	setOpen(true, "shop")
end)
closeButton.Activated:Connect(function()
	setOpen(false)
end)
coinBox.Activated:Connect(function()
	if mode == "shop" then
		showTab("Coins")
		if cards[1] then
			select(cards[1].entry)
		end
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if open and not processed and input.KeyCode == Enum.KeyCode.Escape then
		setOpen(false)
	end
end)

-- Andere Skripte (und Tests) können öffnen: VipShop:SetAttribute("Open", "shop" | "kiosk" | Artikel-ID | Reiter)
gui:GetAttributeChangedSignal("Open"):Connect(function()
	local target = gui:GetAttribute("Open")
	if type(target) == "string" and target ~= "" then
		gui:SetAttribute("Open", nil)
		if target == "shop" or target == "kiosk" then
			setOpen(true, target)
		else
			local entry = byId[target]
			local kioskTab = target == "Snacks" or target == "Extras"
			setOpen(true, (kioskTab or (entry and (entry.tab == "Snacks" or entry.tab == "Extras"))) and "kiosk" or "shop", target)
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
-- Münzen zählen sichtbar hoch oder runter, das Messingschild hüpft kurz
local shownCoins
local coinCounter = Instance.new("NumberValue")
coinCounter.Changed:Connect(function(value)
	hudCoins.Text = money(value)
	coinsLabel.Text = money(value)
end)
local coinScale = coinBox:FindFirstChildOfClass("UIScale") or create("UIScale", { Parent = coinBox })
local function showCoins(amount)
	if shownCoins == nil or calm() then
		coinCounter.Value = amount
		hudCoins.Text = money(amount)
		coinsLabel.Text = money(amount)
	elseif shownCoins ~= amount then
		TweenService:Create(coinCounter, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = amount }):Play()
		coinScale.Scale = 1.12
		tween(coinScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	shownCoins = amount
end

local function onDataChanged()
	readData()
	showCoins(state.coins)
	testNote:SetAttribute("Wanted", player:GetAttribute("TestCoins") == true)
	testNote.Visible = player:GetAttribute("TestCoins") == true and not layout.compact
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
