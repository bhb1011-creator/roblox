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

-- Kleidung und Accessoires (Modelle: ReplicatedStorage.Shop.Kleidung.<id>), nur für Münzen
ShopCatalog.CLOTHING = {
	{ id = "Scarf", title = "Wool Scarf", coins = 250, rarity = "Common", slot = "Neck" },
	{ id = "Beanie", title = "Beanie", coins = 300, rarity = "Common", slot = "Head" },
	{ id = "Cap", title = "Baseball Cap", coins = 300, rarity = "Common", slot = "Head" },
	{ id = "LeatherGloves", title = "Leather Gloves", coins = 400, rarity = "Common", slot = "Hands" },
	{ id = "Sunglasses", title = "Aviator Sunglasses", coins = 350, rarity = "Rare", slot = "Face" },
	{ id = "HikingBoots", title = "Hiking Boots", coins = 450, rarity = "Rare", slot = "Feet" },
	{ id = "Headlamp", title = "Headlamp", coins = 500, rarity = "Rare", slot = "Head" },
	{ id = "Backpack", title = "Hiking Backpack", coins = 600, rarity = "Rare", slot = "Back" },
	{ id = "RainJacket", title = "Yellow Rain Jacket", coins = 900, rarity = "Epic", slot = "Jacket" },
	{ id = "FlannelVest", title = "Flannel & Vest", coins = 1000, rarity = "Epic", slot = "Jacket" },
	{ id = "LeatherJacket", title = "Leather Jacket", coins = 1200, rarity = "Legendary", slot = "Jacket" },
	{ id = "DownJacket", title = "Down Jacket", coins = 1200, rarity = "Legendary", slot = "Jacket" },
}

-- Verbrauchsgegenstände (höchstens 3 pro Runde), Münzen ODER Robux
ShopCatalog.ITEMS = {
	{ id = "EnergyBar", title = "Energy Bar", description = "Run 20% faster for 20 seconds.", coins = 40, robux = 10 },
	{ id = "Coffee", title = "Coffee", description = "Endless sprint for 60 seconds.", coins = 50, robux = 10 },
	{ id = "MintGum", title = "Mint Gum", description = "Quiet steps for 60 seconds.", coins = 60, robux = 15 },
	{ id = "GummyBears", title = "Gummy Bears", description = "An arrow shows the way for 20 seconds.", coins = 200, robux = 40 },
	{ id = "XRayGlasses", title = "X-Ray Glasses", description = "See Sarp and every enemy through walls for 30 seconds.", coins = 400, robux = 75 },
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
	{ coins = 200, robux = 49, productId = 0 },
	{ coins = 500, robux = 99, productId = 0 },
	{ coins = 1500, robux = 249, productId = 0 },
	{ coins = 5000, robux = 749, productId = 0 },
}
ShopCatalog.COIN_BOOST = { title = "Coin Boost", description = "Double coins for a while.", robux = 50, productId = 0 }

-- Skins (Rezepte in Skins.lua)
ShopCatalog.SKINS = {
	{ id = "SilverSuit", title = "Silver Suit", figures = "Player", coins = 2500, robux = 249 },
	{ id = "GoldSuit", title = "Golden Suit", figures = "Everyone", pack = "GoldenPack" },
	{ id = "GildedHorror", title = "Gilded Horror", figures = "Sarp", pack = "SarpVip" },
	{ id = "CrimsonCount", title = "Crimson Count", figures = "Sarp", pack = "SarpVip" },
	{ id = "ObsidianKing", title = "Obsidian King", figures = "Sarp", pack = "SarpVip" },
	{ id = "ShadowSarp", title = "Shadow Sarp", figures = "Sarp", coins = 3500, robux = 399 },
}

ShopCatalog.SPORTS_CAR = { title = "Sports Car", coins = 3000, robux = 399 }

-- Packs (nur Robux, besonders präsentiert)
ShopCatalog.PACKS = {
	{ id = "GoldenPack", title = "Golden Pack", description = "Golden suits for everyone, gold badge and the sports car.", robux = 999, badge = "Gold" },
	{ id = "SarpVip", title = "Sarp VIP Pack", description = "Three luxury Sarp skins, VIP badge and the sports car.", robux = 499, badge = "SarpVip" },
	{ id = "Everything", title = "Everything Bundle", description = "Golden Pack and Sarp VIP Pack together.", robux = 1249 },
}

ShopCatalog.STARTER_PACK = {
	title = "Starter Pack",
	description = "3 Energy Bars, 2 Coffee, 1 Mint Gum, 500 coins and a Beanie.",
	robux = 99,
	firstTimeRobux = 50,
}

return ShopCatalog
