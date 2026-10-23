-- Wo was in der Lobby steht. Boden des Parkplatzes liegt auf Höhe 0.2.
-- Norden ist -Z: dort verlässt die Straße den Parkplatz.
local Layout = {}

Layout.GROUND_Y = 0.2 -- Oberkante des Bodens innerhalb des Zauns (Asphalt und Waldboden)

Layout.LOT = { halfWidth = 80, minZ = -70, maxZ = 70, exitHalfWidth = 10 }
Layout.GATE_Z = -73
Layout.CAR_TURN_Z = -40 -- hier biegen die Autos zur Mitte ab

-- Asphalt nur im Norden (Autos, Ausfahrt, Spawn). Der Rest innerhalb des Zauns ist
-- flacher Waldboden auf derselben Höhe, mit dem Grillplatz und den Gebäuden.
Layout.ASPHALT = { minZ = -70, maxZ = -16 }

Layout.SPAWN = Vector3.new(0, 0.3, -26)
Layout.CAMPFIRE = Vector3.new(0, 0.2, 6)

Layout.SHOP = CFrame.new(-50, 0.2, 57) -- Vorderseite (Tür) zeigt nach Norden
Layout.INFO_BOARD = Vector3.new(-14, 0.2, 64)
Layout.CAMPER = CFrame.new(12, 0.2, 60)
Layout.BOOTH = CFrame.new(40, 0.2, 61)
Layout.LEADERBOARD = CFrame.new(63, 0.2, 60)
Layout.NOTICE_BOARD = CFrame.lookAt(Vector3.new(-77, 0.2, 4), Vector3.new(0, 0.2, 4))

-- Weiße Flutlichtmasten: { Position, Ziel des Lichts }
Layout.FLOODLIGHTS = {
	{ Vector3.new(-30, 0.2, -68), Vector3.new(-47, 0, -52) },
	{ Vector3.new(30, 0.2, -68), Vector3.new(47, 0, -52) },
	{ Vector3.new(-78, 0.2, -20), Vector3.new(-40, 0, -20) },
	{ Vector3.new(78, 0.2, -20), Vector3.new(40, 0, -20) },
	{ Vector3.new(-78, 0.2, 32), Vector3.new(-45, 0, 40) },
	{ Vector3.new(78, 0.2, 32), Vector3.new(45, 0, 40) },
}

-- Klassische Laternen (warm, flackern manchmal) – nur am Rand
Layout.LAMPS = {
	Vector3.new(-15, 0.2, -66),
	Vector3.new(15, 0.2, -66),
	Vector3.new(-28, 0.2, 44),
	Vector3.new(28, 0.2, 46),
}

return Layout
