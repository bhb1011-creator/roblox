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
	knock = "", -- knock.ogg (Klopfen ans Autofenster)
	twig = "", -- twig_snap.ogg (knackender Ast im Wald)
	growl = "", -- beast_growl.ogg (das Biest knurrt im Wald)
	roar = "", -- beast_roar.ogg (das Biest brüllt und jagt einen)
	beastBreath = "", -- beast_breath_loop.ogg (Atmen des Biests)
	beastStep = "", -- beast_step.ogg (schwere Schritte des Biests)
	-- Umgebung
	forestWind = "", -- forest_wind_loop.ogg (Wind in den Tannen)
	rustle = "", -- leaves_rustle.ogg (Rascheln im Laub, aus zufälligen Richtungen)
	treeCreak = "", -- tree_creak.ogg (knarrender Baum)
	houseCreak = "", -- house_creak.ogg (das Haus knarrt, als wäre jemand drin)
	swingCreak = "", -- swing_creak_loop.ogg (quietschende Reifenschaukel)
	shutterRattle = "", -- shutter_rattle_loop.ogg (klappernder Fensterladen)
	carTick = "", -- car_tick_loop.ogg (abkühlender Motor)
	radioVoices = "", -- radio_voices.ogg (verzerrte Stimmen im Radiorauschen)
	-- Spieler
	heartbeat = "", -- heartbeat_loop.ogg (Herzschlag, wenn das Biest nah ist)
	scaredBreath = "", -- scared_breath_loop.ogg (panisches Atmen bei der Jagd)
	stepGravel = "", -- step_gravel.ogg (Schritt auf Schotter)
	stepDirt = "", -- step_dirt.ogg (Schritt auf Waldboden)
	stepWood = "", -- step_wood.ogg (Schritt auf Holz, z. B. Veranda)
}

-- Sprachausgabe auf Englisch mit der Text-to-Speech-Funktion von Roblox.
-- `id` = Nummer der Roblox-Stimme:
--   "1" britisch, Mann     "2" britisch, Frau
--   "3" amerikanisch, Mann  "4" amerikanisch, Frau
--   "5" amerikanisch, Mann  "6" amerikanisch, Frau
--   "7" australisch, Mann   "8" australisch, Frau
-- `pitch` = Tonhöhe in Halbtönen (-12 bis 12, 0 = normal, minus = tiefer, plus = heller),
-- `speed` = Sprechtempo (0.5 bis 2, 1 = normal), `volume` = Lautstärke (0 bis 3).
-- `effects` = Klangeffekte, der Reihe nach: `equalizer` (Bass/Mitten/Höhen in dB) und
-- `reverb` (Hall). Funktioniert die Sprachausgabe nicht, erscheinen trotzdem die Untertitel.
Config.SPEECH_ENABLED = true
Config.VOICES = {
	-- Sarp: etwas tiefer, langsam, ruhig – mit Bass, weniger Höhen und dunklem Hall
	sarp = {
		id = "1",
		pitch = -2,
		speed = 0.85,
		volume = 1.6,
		effects = {
			{ "AudioEqualizer", { LowGain = 4, MidGain = 0, HighGain = -6 } },
			{ "AudioReverb", { DecayTime = 1.8, WetLevel = -8, DryLevel = 0, HighCutFrequency = 3500 } },
		},
	},
	-- Die Spieler (Antworten) und der Erzähler (das sind auch die Spieler: "we", "I"):
	-- eine hellere, jüngere Stimme
	player = {
		id = "3",
		pitch = 3,
		speed = 1.05,
		volume = 2.6,
		effects = {
			{ "AudioEqualizer", { LowGain = -2, MidGain = 2, HighGain = 3 } },
		},
	},
	narrator = {
		id = "3",
		pitch = 3,
		speed = 0.95,
		volume = 2.6,
		effects = {
			{ "AudioEqualizer", { LowGain = -2, MidGain = 2, HighGain = 3 } },
			{ "AudioReverb", { DecayTime = 0.6, WetLevel = -18, DryLevel = 0 } },
		},
	},
}

-- Eigene Sprachaufnahmen (statt Computerstimme). Die Dateien liegen in assets/voice
-- (fertig bearbeitet als .ogg). Nach dem Hochladen bei Roblox die ID bei `id` eintragen,
-- z. B. id = "rbxassetid://1234567890". Solange `id` leer ist, spricht die Roblox-Stimme.
-- `length` = Länge der Aufnahme in Sekunden (nicht ändern).
Config.VOICE_LINES = {
	sarp_01_evening = { id = "rbxassetid://97659892635696", length = 1.43 },
	sarp_02_shouldnt_stop = { id = "rbxassetid://139946265545194", length = 3.25 },
	sarp_03_the_wagners = { id = "rbxassetid://111461374894866", length = 1.63 },
	sarp_04_told_me = { id = "rbxassetid://74164423336774", length = 3.21 },
	sarp_05_im_sarp = { id = "rbxassetid://140087510979277", length = 4.20 },
	sarp_06_who_am_i = { id = "rbxassetid://103360762837678", length = 2.01 },
	sarp_07_my_name = { id = "rbxassetid://105058259374862", length = 3.52 },
	sarp_08_waiting_duo = { id = "rbxassetid://96890798469986", length = 3.13 },
	sarp_08_waiting_solo = { id = "rbxassetid://105997702791410", length = 3.84 },
	sarp_09_campsite_duo = { id = "rbxassetid://119675925404734", length = 3.41 },
	sarp_09_campsite_solo = { id = "rbxassetid://95922603160594", length = 3.32 },
	sarp_10_small_place = { id = "rbxassetid://128125354875387", length = 3.90 },
	sarp_11_watched_you = { id = "rbxassetid://137887916741474", length = 4.40 },
	sarp_12_house_up_path = { id = "rbxassetid://94140367037532", length = 5.50 },
	sarp_13_come = { id = "rbxassetid://88924388731575", length = 2.48 },
	sarp_14_no_road = { id = "rbxassetid://100681905164969", length = 2.29 },
	sarp_15_ill_be_waiting = { id = "rbxassetid://75728692898760", length = 3.76 },
	sarp_16_long_way = { id = "rbxassetid://98070203470985", length = 3.72 },
	sarp_17_stay_close = { id = "rbxassetid://118173417017559", length = 4.40 },
	sarp_18_leave_you = { id = "rbxassetid://88373461532940", length = 4.20 },
	sarp_19_sleep_well = { id = "rbxassetid://99466167069052", length = 3.20 },
}

return Config
