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

return Config
