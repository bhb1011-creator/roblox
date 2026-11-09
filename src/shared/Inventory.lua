-- Inventarleiste (Client, Kapitel 1–3): unten in der Mitte sieht man, was man gerade dabei hat.
-- Sie liest einfach die Spielfigur: Kerze, rote Kerze, Axt, Chemikalien, Schießpulver,
-- Schlüssel und das Handy (Taschenlampe). Ist das Licht aus (Taste F), wird die Kerze grau.
local Players = game:GetService("Players")

local Inventory = {}

-- Name des Teils an der Spielfigur -> Anzeige
local ITEMS = {
	{ child = "PlayerCandle", icon = "🕯️", name = "Kerze", light = true },
	{ child = "PlayerAxe", icon = "🪓", name = "Axt" },
	{ child = "Carried_chemicals", icon = "🧪", name = "Chemikalien" },
	{ child = "Carried_powder", icon = "💥", name = "Schießpulver" },
	{ child = "Carried_key", icon = "🔑", name = "Schlüssel" },
	{ child = "PhoneLight", icon = "📱", name = "Handy", light = true, deep = true },
	{ child = "Flashlight", icon = "📱", name = "Handy", light = true, deep = true },
}
local SLOT = 64

local started = false

function Inventory.start()
	if started then
		return
	end
	started = true
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "InventoryBar"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -14)
	bar.Size = UDim2.fromOffset(0, SLOT)
	bar.AutomaticSize = Enum.AutomaticSize.X
	bar.BackgroundTransparency = 1
	bar.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar

	local slots = {}
	local function slotFor(item, order)
		local slot = slots[item.name]
		if slot then
			return slot
		end
		slot = Instance.new("Frame")
		slot.Name = item.name
		slot.LayoutOrder = order
		slot.Size = UDim2.fromOffset(SLOT, SLOT)
		slot.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
		slot.BackgroundTransparency = 0.3
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = slot
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(90, 80, 70)
		stroke.Transparency = 0.3
		stroke.Parent = slot
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.new(1, 0, 1, -18)
		icon.Font = Enum.Font.GothamBold
		icon.TextScaled = true
		icon.Text = item.icon
		icon.Parent = slot
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 2, 1, -18)
		label.Size = UDim2.new(1, -4, 0, 16)
		label.Font = Enum.Font.Gotham
		label.TextSize = 11
		label.TextColor3 = Color3.fromRGB(220, 214, 204)
		label.Text = item.name
		label.Parent = slot
		slot.Parent = bar
		slots[item.name] = slot
		return slot
	end

	local function refresh()
		local character = player.Character
		local seen = {}
		for order, item in ITEMS do
			local found = character and (item.deep and character:FindFirstChild(item.child, true) or character:FindFirstChild(item.child))
			if found and not seen[item.name] then
				seen[item.name] = true
				local slot = slotFor(item, order)
				local name = item.name
				if item.child == "PlayerCandle" and player:GetAttribute("CandleMode") == "red" then
					name = "Rote Kerze"
				end
				slot.Label.Text = name
				local off = item.light and player:GetAttribute("LightOff") == true
				slot.Icon.TextTransparency = off and 0.6 or 0
				slot.Label.Text = off and (name .. " (aus)") or name
			end
		end
		for name, slot in slots do
			if not seen[name] then
				slot:Destroy()
				slots[name] = nil
			end
		end
	end

	gui.Parent = player:WaitForChild("PlayerGui")
	-- regelmäßig nachschauen (billig: nur ein paar Suchen an der eigenen Figur)
	task.spawn(function()
		while true do
			pcall(refresh)
			task.wait(0.4)
		end
	end)
end

return Inventory
