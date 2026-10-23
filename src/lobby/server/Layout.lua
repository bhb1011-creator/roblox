-- Wo was in der Lobby steht. Boden des Parkplatzes liegt auf Höhe 0.2.
-- Norden ist -Z: dort verlässt die Straße den Parkplatz.
local Layout = {}

Layout.GROUND_Y = 0.2

Layout.LOT = { halfWidth = 60, minZ = -50, maxZ = 46, exitHalfWidth = 8 }
Layout.GATE_Z = -52

Layout.SPAWN = Vector3.new(0, 0.3, -8)
Layout.CAMPFIRE = Vector3.new(0, 0.2, 8)

Layout.SHOP = CFrame.new(-33, 0.2, 37) -- Vorderseite (Tür) zeigt nach Norden
Layout.BOOTH = CFrame.new(36, 0.2, 38)
Layout.CAMPER = CFrame.new(14, 0.2, 38)
Layout.INFO_BOARD = Vector3.new(-8, 0.2, 42)
Layout.VENDING_MACHINE = CFrame.new(-19.5, 0.2, 41)

Layout.LAMPS = {
	Vector3.new(-12, 0.2, -44),
	Vector3.new(12, 0.2, -44),
	Vector3.new(-52, 0.2, -12),
	Vector3.new(52, 0.2, -12),
	Vector3.new(-52, 0.2, 26),
	Vector3.new(52, 0.2, 26),
	Vector3.new(-14, 0.2, 32),
	Vector3.new(26, 0.2, 30),
}

return Layout
