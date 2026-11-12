-- Alle Shop-Daten an einer Stelle (Plan: plan_shop_spielfluss.md). Spieltexte auf Englisch.
-- Robux-Preise sind die vom User festgelegten Preise; der echte Preis kommt später per
-- MarketplaceService:GetProductInfo (sobald die Produkte im Creator Hub angelegt sind).
-- `productId` / `passId` = 0 heißt: noch nicht im Creator Hub angelegt.
local ShopCatalog = {}

ShopCatalog.COINS_PER_WIN = 150 -- Münzen für das geschaffte Spiel (Boni kommen später)
ShopCatalog.REVIVE_ROBUX = 30
ShopCatalog.MAX_HEARTS = 2
ShopCatalog.MAX_HEARTS_PASS = 3

-- Seltenheiten (Gratis-Automat und Farben im Shop)
ShopCatalog.RARITIES = {
	Common = { title = "COMMON", chance = 60, color = Color3.fromRGB(190, 190, 190) },
	Rare = { title = "RARE", chance = 30, color = Color3.fromRGB(80, 160, 255) },
	Epic = { title = "EPIC", chance = 9, color = Color3.fromRGB(190, 90, 255) },
	Legendary = { title = "LEGENDARY", chance = 1, color = Color3.fromRGB(255, 190, 60) },
}

-- Kleidung und Accessoires (Modelle: ReplicatedStorage.Shop.Kleidung.<id>), Münzen ODER Robux
ShopCatalog.CLOTHING = {
	{ id = "Scarf", title = "Wool Scarf", coins = 250, rarity = "Common", slot = "Neck", robux = 49, productId = 0 },
	{ id = "Beanie", title = "Beanie", coins = 300, rarity = "Common", slot = "Head", robux = 59, productId = 0 },
	{ id = "Cap", title = "Baseball Cap", coins = 300, rarity = "Common", slot = "Head", robux = 59, productId = 0 },
	{ id = "LeatherGloves", title = "Leather Gloves", coins = 400, rarity = "Common", slot = "Hands", robux = 79, productId = 0 },
	{ id = "Sunglasses", title = "Aviator Sunglasses", coins = 350, rarity = "Rare", slot = "Face", robux = 69, productId = 0 },
	{ id = "HikingBoots", title = "Hiking Boots", coins = 450, rarity = "Rare", slot = "Feet", robux = 89, productId = 0 },
	{ id = "Headlamp", title = "Headlamp", coins = 500, rarity = "Rare", slot = "Head", robux = 99, productId = 0 },
	{ id = "Backpack", title = "Hiking Backpack", coins = 600, rarity = "Rare", slot = "Back", robux = 119, productId = 0 },
	{ id = "RainJacket", title = "Yellow Rain Jacket", coins = 900, rarity = "Epic", slot = "Jacket", robux = 179, productId = 0 },
	{ id = "FlannelVest", title = "Flannel & Vest", coins = 1000, rarity = "Epic", slot = "Jacket", robux = 199, productId = 0 },
	{ id = "LeatherJacket", title = "Leather Jacket", coins = 1200, rarity = "Legendary", slot = "Jacket", robux = 229, productId = 0 },
	{ id = "DownJacket", title = "Down Jacket", coins = 1200, rarity = "Legendary", slot = "Jacket", robux = 229, productId = 0 },
}

-- Verbrauchsgegenstände (höchstens 3 pro Runde), Münzen ODER Robux
ShopCatalog.ITEMS = {
	{ id = "EnergyBar", title = "Energy Bar", description = "Run 20% faster for 20 seconds.", coins = 40, robux = 10, productId = 0 },
	{ id = "Coffee", title = "Coffee", description = "Endless sprint for 60 seconds.", coins = 50, robux = 10, productId = 0 },
	{ id = "MintGum", title = "Mint Gum", description = "Quiet steps for 60 seconds.", coins = 60, robux = 15, productId = 0 },
	{ id = "GummyBears", title = "Gummy Bears", description = "An arrow shows the way for 20 seconds.", coins = 200, robux = 40, productId = 0 },
	{ id = "XRayGlasses", title = "X-Ray Glasses", description = "See Sarp and every enemy through walls for 30 seconds.", coins = 400, robux = 75, productId = 0 },
}

-- Gamepässe (einmal kaufen, für immer)
ShopCatalog.GAMEPASSES = {
	{ id = "ThreeHearts", title = "3 Hearts", description = "Always start with 3 hearts instead of 2.", robux = 249, passId = 0 },
	{ id = "DoubleCoins", title = "2x Coins", description = "Earn double coins forever.", robux = 149, passId = 0 },
	{ id = "StrongFlashlight", title = "Strong Flashlight", description = "A much brighter, wider flashlight.", robux = 149, passId = 0 },
	{ id = "Supervision", title = "Supervision", description = "Items you can pick up glow through walls.", robux = 499, passId = 0 },
	{ id = "VipCar", title = "VIP Car", description = "Your own paint, radio and horn in the lobby car.", robux = 199, passId = 0 },
}

-- Münzpakete und Boost (Entwicklerprodukte)
ShopCatalog.COIN_PACKS = {
	{ id = "Coins200", coins = 200, robux = 49, productId = 0 },
	{ id = "Coins500", coins = 500, robux = 99, productId = 0 },
	{ id = "Coins1500", coins = 1500, robux = 249, productId = 0, tag = "POPULAR" },
	{ id = "Coins5000", coins = 5000, robux = 749, productId = 0, tag = "BEST VALUE" },
}
ShopCatalog.COIN_BOOST = { id = "CoinBoost", title = "Coin Boost", description = "Double coins for a while.", robux = 50, productId = 0 }

-- Skins (Rezepte in Skins.lua). `slot` = wer ihn trägt (Player: Fahrer UND Beifahrerin mit einem
-- gemeinsamen Modell, Spieler1). `preview` = Figur für Vorschau und Showroom.
local PLAYER_PREVIEW = { folder = "Spieler", name = "Spieler1", height = 5.9 }
local SARP_PREVIEW = { folder = "Sarp", name = "Sarp2", height = 6.9 }
ShopCatalog.SKINS = {
	{ id = "SilverSuit", title = "Silver Suit", description = "A silver tuxedo for driver and passenger.", slot = "Player", coins = 2500, robux = 249, productId = 0, rarity = "Epic", preview = PLAYER_PREVIEW },
	{ id = "GoldSuit", title = "Golden Suit", description = "Golden tuxedos for you and the whole Wagner family.", slot = "Player", pack = "GoldenPack", rarity = "Legendary", preview = PLAYER_PREVIEW, options = { tuxedo = true } },
	{ id = "GildedHorror", title = "Gilded Horror", description = "Antique gold, a crown of thorns and a burning ruby.", slot = "Sarp", pack = "SarpVip", rarity = "Legendary", preview = SARP_PREVIEW },
	{ id = "ShadowSarp", title = "Shadow Sarp", description = "Pitch black and smoking, like a living shadow.", slot = "Sarp", coins = 3500, robux = 399, productId = 0, rarity = "Epic", preview = SARP_PREVIEW },
}

-- Farbtexturen der KI-Figuren (aus den .rbxm-Dateien gelesen). Vorschaufenster zeigen keine
-- SurfaceAppearance, und Spielskripte dürfen deren ColorMap nicht lesen – darum stehen sie hier.
ShopCatalog.FIGURE_TEXTURES = {
	Spieler1 = "rbxassetid://95079040040670",
	Spieler2 = "rbxassetid://86513944236056",
	MrWagner = "rbxassetid://73846587221622",
	MrsWagner = "rbxassetid://134890354521895",
	Lucy = "rbxassetid://88450451044392",
	Tommy = "rbxassetid://109080654245888",
	Sarp1 = "rbxassetid://134843323285360",
	Sarp2 = "rbxassetid://122213498786655",
	Biest = "rbxassetid://134361443688539",
}

-- Golden Pack: so sieht die Familie aus (Showroom und Vorschau)
ShopCatalog.FAMILY_GOLD = {
	{ folder = "Wagners", name = "MrWagner", height = 5.9, options = { tuxedo = true }, title = "Richard" },
	{ folder = "Wagners", name = "MrsWagner", height = 5.3, options = { jewelry = true }, title = "Mrs. Wagner" },
	{ folder = "Wagners", name = "Lucy", height = 4.3, options = { jewelry = true, barefoot = true }, title = "Lucy" },
	{ folder = "Wagners", name = "Tommy", height = 3.6, options = { tuxedo = true }, title = "Tommy" },
}

ShopCatalog.SPORTS_CAR = { id = "SportsCar", title = "Sports Car", description = "Low, wide and black with gold. Drive to the guesthouse in style.", coins = 3000, robux = 399, productId = 0, rarity = "Legendary" }

-- Packs (nur Robux, besonders präsentiert)
ShopCatalog.PACKS = {
	{ id = "GoldenPack", title = "Golden Pack", description = "Golden suits for you and the whole Wagner family, a gold badge and the sports car.", robux = 999, badge = "Gold", productId = 0, grants = { "GoldSuit", "SportsCar" } },
	{ id = "SarpVip", title = "Sarp VIP Pack", description = "Sarp as the Gilded Horror, a VIP badge and the sports car.", robux = 499, badge = "SarpVip", productId = 0, grants = { "GildedHorror", "SportsCar" } },
	{ id = "Everything", title = "Everything Bundle", description = "Golden Pack and Sarp VIP Pack together.", robux = 1249, productId = 0, grants = { "GoldSuit", "GildedHorror", "SportsCar" }, tag = "Save 249 R$" },
}

-- Kleidungs-Sets: mehrere Teile zusammen, günstiger als einzeln (Münzen ODER Robux)
ShopCatalog.OUTFITS = {
	{ id = "HikerSet", title = "Hiker Set", description = "Beanie, hiking boots, backpack and the yellow rain jacket.", items = { "Beanie", "HikingBoots", "Backpack", "RainJacket" }, coins = 1800, robux = 349, productId = 0 },
	{ id = "NightWalkSet", title = "Night Walk Set", description = "Headlamp, wool scarf, leather gloves and the down jacket.", items = { "Headlamp", "Scarf", "LeatherGloves", "DownJacket" }, coins = 1900, robux = 369, productId = 0 },
	{ id = "RoadTripSet", title = "Road Trip Set", description = "Baseball cap, aviator sunglasses and the leather jacket.", items = { "Cap", "Sunglasses", "LeatherJacket" }, coins = 1500, robux = 289, productId = 0 },
}

ShopCatalog.STARTER_PACK = {
	title = "Starter Pack",
	description = "3 Energy Bars, 2 Coffee, 1 Mint Gum, 500 coins and a Beanie.",
	robux = 99,
	firstTimeRobux = 50,
	productId = 0,
	firstTimeProductId = 0,
}

-- Suchen: ShopCatalog.find(id) -> Eintrag, Art ("Skin", "Clothing", "Item", "Pass", "Pack", "Car")
function ShopCatalog.find(id)
	for kind, list in { Skin = ShopCatalog.SKINS, Clothing = ShopCatalog.CLOTHING, Item = ShopCatalog.ITEMS, Pass = ShopCatalog.GAMEPASSES, Pack = ShopCatalog.PACKS, CoinPack = ShopCatalog.COIN_PACKS, Outfit = ShopCatalog.OUTFITS } do
		for _, entry in list do
			if entry.id == id then
				return entry, kind
			end
		end
	end
	if id == ShopCatalog.SPORTS_CAR.id then
		return ShopCatalog.SPORTS_CAR, "Car"
	end
	return nil
end

return ShopCatalog
