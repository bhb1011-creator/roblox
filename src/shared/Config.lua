-- Zentrale Einstellungen. Hier kannst du Namen, Zeiten und Autos anpassen.
local Config = {}

Config.GAME_TITLE = "Die letzte Nacht" -- Platzhalter-Titel, später ersetzen
Config.GAME_SUBTITLE = "Basierend auf wahren Begebenheiten"

-- PlaceId des Horror-Levels. Solange 0, fahren die Autos nur eine Proberunde.
Config.GAME_PLACE_ID = 0

-- Feste Uhrzeit in der Lobby (17.7 = Sonnenuntergang). Die Zeit läuft nicht weiter.
Config.LOBBY_CLOCK_TIME = 17.7

-- Sekunden, bis ein volles Auto losfährt
Config.COUNTDOWN_SECONDS = 10

-- Sekunden nach der Abfahrt, bis der Bildschirm schwarz wird
Config.FADE_DELAY = 7

Config.MODES = {
	Solo = { title = "ALLEIN", capacity = 1 },
	Duo = { title = "ZU ZWEIT", capacity = 2 },
}

-- Die vier Autos auf dem Parkplatz (Position = Mitte der Parkbucht)
Config.CARS = {
	{ mode = "Solo", position = Vector3.new(-58, 0.2, -56), color = Color3.fromRGB(110, 28, 30) },
	{ mode = "Solo", position = Vector3.new(-36, 0.2, -56), color = Color3.fromRGB(40, 60, 90) },
	{ mode = "Duo", position = Vector3.new(36, 0.2, -56), color = Color3.fromRGB(60, 70, 50) },
	{ mode = "Duo", position = Vector3.new(58, 0.2, -56), color = Color3.fromRGB(85, 85, 90) },
}

-- Robux-Produkte an der Kasse. Die IDs bekommst du, wenn du im Creator Hub unter
-- Monetarisierung → Entwicklerprodukte ein Produkt anlegst. Solange die ID 0 ist,
-- zeigt die Kasse "Noch nicht eingerichtet". Der Preis wird im Creator Hub festgelegt,
-- `robux` hier ist nur die Anzeige.
Config.PRODUCTS = {
	{
		id = 0,
		title = "Wiederbelebung",
		description = "Nach dem Tod sofort an Ort und Stelle weiterspielen.",
		field = "Revives",
		amount = 1,
		robux = 25,
	},
	{
		id = 0,
		title = "3× Wiederbelebung",
		description = "Drei Wiederbelebungen zum Sparpreis.",
		field = "Revives",
		amount = 3,
		robux = 60,
	},
	{
		id = 0,
		title = "Rebirth",
		description = "Starte neu mit einem dauerhaften Bonus.",
		field = "Rebirths",
		amount = 1,
		robux = 99,
	},
}

-- Snacks im Kiosk, die im Spiel helfen. Gekauft wird später mit Münzen aus dem Spiel.
Config.SNACKS = {
	{ title = "Energieriegel", description = "Kurz schneller laufen.", price = 25, color = Color3.fromRGB(200, 60, 40) },
	{ title = "Kaffee", description = "Länger sprinten, ohne müde zu werden.", price = 30, color = Color3.fromRGB(110, 70, 40) },
	{ title = "Schokolade", description = "Gibt ein bisschen Leben zurück.", price = 20, color = Color3.fromRGB(90, 50, 30) },
	{ title = "Energy-Drink", description = "Hört Geräusche früher.", price = 35, color = Color3.fromRGB(60, 160, 60) },
	{ title = "Batterien", description = "Die Taschenlampe hält länger.", price = 40, color = Color3.fromRGB(220, 180, 40) },
	{ title = "Chips", description = "Einfach lecker. Hilft gegen Hunger.", price = 15, color = Color3.fromRGB(230, 200, 60) },
}

-- Sounds für Level 1. Die Dateien liegen im Ordner assets/audio. Nach dem Hochladen bei
-- Roblox die ID hier eintragen, z. B. "rbxassetid://1234567890". Leer = Sound fällt weg.
Config.SOUNDS = {
	music = "rbxassetid://129799584506039", -- music_calm.ogg (oder ein ruhiges Lied aus der Toolbox)
	engine = "rbxassetid://121893718227351", -- engine_loop.ogg
	road = "rbxassetid://131705442552114", -- road_loop.ogg
	wind = "rbxassetid://133055757601743", -- wind_loop.ogg
	forest = "rbxassetid://117319242416734", -- forest_night_loop.ogg
	brake = "rbxassetid://114887694790169", -- brake.ogg
	gravel = "rbxassetid://107310869410051", -- gravel_loop.ogg
	footstep = "rbxassetid://91754085610268", -- footstep.ogg
	blinker = "rbxassetid://119651566230299", -- blinker_tick.ogg
	radioStatic = "rbxassetid://111802312351078", -- radio_static_loop.ogg
	lampBuzz = "rbxassetid://87539521921383", -- lamp_buzz_loop.ogg
	sting = "rbxassetid://94291824225136", -- sting.ogg
}

return Config
