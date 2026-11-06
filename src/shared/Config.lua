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
	owl = "", -- owl_hoot.ogg (Waldkauz in der Ferne)
	wolf = "", -- wolf_howl.ogg (Wolf heult weit weg)
	raven = "", -- raven_caw.ogg (Rabe)
	foxScream = "", -- fox_scream.ogg (Fuchs-Schrei, klingt fast wie ein Mensch)
	birdFlyaway = "", -- bird_flyaway.ogg (Vogel fliegt erschrocken auf, ganz nah)
	-- Spieler
	heartbeat = "", -- heartbeat_loop.ogg (Herzschlag, wenn das Biest nah ist)
	scaredBreath = "", -- scared_breath_loop.ogg (panisches Atmen bei der Jagd)
	stepGravel = "", -- step_gravel.ogg (Schritt auf Schotter)
	stepDirt = "", -- step_dirt.ogg (Schritt auf Waldboden)
	stepWood = "", -- step_wood.ogg (Schritt auf Holz, z. B. Veranda)
	-- Kapitel 2: die Haustür der Wagners
	doorCreak = "", -- door_creak.ogg (Tür geht knarrend auf)
	doorSlam = "", -- door_slam.ogg (Tür fällt hinter einem zu)
	doorChain = "", -- door_chain.ogg (Türkette wird abgenommen)
	-- Kapitel 2, die erste Nacht
	scream = "", -- scream_distant.ogg (Schrei irgendwo im Haus, weckt einen auf)
	heavyKnock = "", -- heavy_knock.ogg (drei schwere Schläge gegen die Haustür)
	doorBurst = "", -- door_burst.ogg (Tür wird aufgerissen und knallt gegen die Wand)
	sarpStep = "", -- sarp_step.ogg (schwerer, schleifender Schritt)
	sarpBreath = "", -- sarp_breath.ogg (rasselndes Atmen ganz nah)
	jumpscare = "", -- jumpscare.ogg (lauter Schreck-Ton mit Schrei)
	-- Die Flucht (Kapitel 2)
	fuse = "", -- fuse.ogg (Zündschnur zischt, ca. 5 Sekunden)
	explosion = "", -- explosion.ogg (Explosion im Raum, dumpf und laut)
	sarpRoar = "", -- sarp_roar.ogg (Sarp brüllt wütend, durchs ganze Haus)
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
-- Antworten der Spieler mit der Roblox-Stimme sprechen? false = ohne eigene Aufnahme nur
-- als Untertitel (die Roblox-Stimme passt nicht zu den echten Aufnahmen).
Config.PLAYER_TTS = false

-- Zum schnellen Testen von Kapitel 2: wo man startet.
--   ""               = normal (vor der Haustür)
--   "nachVerstecken" = in der ersten Nacht direkt nach dem Verstecken im Esszimmer
--                      (Richard kommt, Axt holen, Sarp läuft herum)
--   "tuer1"          = gleich im Raum hinter Tür 1: die Flucht (Richard, Chemikalien und
--                      Schießpulver suchen, Safe sprengen, Sarp, rote Kerzen, Ritualraum)
Config.TEST_START_KAPITEL2 = "tuer1"
-- Versionsnummer: steht beim Laden auf dem Bildschirm und im Output. So sieht man sofort,
-- ob in Studio wirklich der neueste Stand läuft (nach "git pull").
Config.BUILD = "K2-2026-11-06d"
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
	-- die Kinder der Wagners
	lucy = { id = "2", pitch = 3, speed = 0.9, volume = 1.8 },
	tommy = { id = "3", pitch = 5, speed = 0.95, volume = 1.8 },
	-- Sarp in seiner zweiten Gestalt: tief, verzerrt, mit Hall
	sarpDemon = {
		id = "1",
		pitch = -7,
		speed = 0.72,
		volume = 2.2,
		effects = {
			{ "AudioEqualizer", { LowGain = 6, MidGain = -2, HighGain = -8 } },
			{ "AudioDistortion", { Level = 0.25 } },
			{ "AudioReverb", { DecayTime = 2.6, WetLevel = -4, DryLevel = 0, HighCutFrequency = 3000 } },
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
	-- Kapitel 2: Mrs. Wagner (übertrieben freundlich, langsam, ein bisschen zu süß)
	mrsWagner = {
		id = "4",
		pitch = -1,
		speed = 0.85,
		volume = 2.2,
		effects = {
			{ "AudioEqualizer", { LowGain = 0, MidGain = 2, HighGain = -2 } },
			{ "AudioReverb", { DecayTime = 1.1, WetLevel = -14, DryLevel = 0 } },
		},
	},
	-- Kapitel 2: Mr. Wagner (tief, müde, redet wenig und kurz)
	mrWagner = {
		id = "5",
		pitch = -3,
		speed = 0.8,
		volume = 2.4,
		effects = {
			{ "AudioEqualizer", { LowGain = 3, MidGain = 0, HighGain = -4 } },
			{ "AudioReverb", { DecayTime = 1.1, WetLevel = -14, DryLevel = 0 } },
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
	-- Erzähler
	erzaehler_01 = { id = "rbxassetid://93737549569107", length = 3.72 },
	erzaehler_02 = { id = "rbxassetid://132276630522078", length = 9.10 },
	erzaehler_03 = { id = "rbxassetid://90520234904603", length = 8.60 },
	erzaehler_04 = { id = "rbxassetid://107903093617992", length = 8.50 },
	erzaehler_05 = { id = "rbxassetid://120085164958511", length = 6.90 },
	erzaehler_06 = { id = "rbxassetid://120360295547441", length = 6.80 },
	erzaehler_07 = { id = "rbxassetid://74748751327018", length = 6.20 },
	erzaehler_08 = { id = "rbxassetid://90862106692307", length = 6.10 },
	erzaehler_09 = { id = "rbxassetid://72431318123495", length = 6.10 },
	erzaehler_10 = { id = "rbxassetid://86577496232151", length = 5.80 },
	erzaehler_11 = { id = "rbxassetid://82562714990955", length = 6.60 },
	erzaehler_12 = { id = "rbxassetid://117593661165193", length = 6.50 },
	erzaehler_13 = { id = "rbxassetid://94351496435172", length = 7.20 },
	erzaehler_14 = { id = "rbxassetid://118785241202544", length = 7.40 },
	erzaehler_15 = { id = "rbxassetid://140692047391561", length = 3.56 },
	erzaehler_16 = { id = "rbxassetid://116885040187661", length = 4.90 },
	erzaehler_17 = { id = "rbxassetid://135308872362481", length = 5.10 },
	erzaehler_18 = { id = "rbxassetid://73503305526717", length = 5.80 },
	erzaehler_19 = { id = "rbxassetid://106922355096569", length = 6.70 },
	erzaehler_20 = { id = "rbxassetid://86497146595639", length = 6.20 },
	-- Antworten der Spieler im Gespräch (gleiche Stimme wie der Erzähler, denn der Erzähler
	-- ist der Spieler).
	erzaehler_21 = { id = "rbxassetid://106878531684916", length = 2.93 }, -- I'm looking for the Wagners' house.
	erzaehler_22 = { id = "rbxassetid://75977898752243", length = 2.51 }, -- We're looking for the Wagners' house.
	erzaehler_23 = { id = "rbxassetid://118134773273906", length = 1.49 }, -- Who are you?
	erzaehler_24 = { id = "rbxassetid://102214339822434", length = 1.80 }, -- How do you know that?
	erzaehler_25 = { id = "rbxassetid://71566433596036", length = 1.72 }, -- ...Yes.
	erzaehler_26 = { id = "rbxassetid://122852232408061", length = 2.04 }, -- I'll drive there myself.
	erzaehler_27 = { id = "rbxassetid://129011583221839", length = 2.51 }, -- We'll drive there ourselves.
	erzaehler_28 = { id = "rbxassetid://124378973824781", length = 3.32 }, -- ...Okay. Show me the way.
	erzaehler_29 = { id = "rbxassetid://133511673604193", length = 2.59 }, -- ...Okay. Show us the way.
}

return Config
