-- Kleine Helfer, um Bauteile und Schilder per Code zu erstellen.
local Parts = {}

-- Erstellt ein verankertes Bauteil. `props` setzt beliebige Eigenschaften.
function Parts.new(className, props)
	local part = Instance.new(className)
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "Parent" then
			part[key] = value
		end
	end
	part.Parent = props.Parent
	return part
end

-- Senkrechter Zylinder (Roblox-Zylinder liegen standardmäßig auf der Seite).
function Parts.column(props, height, diameter, baseCFrame)
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(height, diameter, diameter)
	props.CFrame = baseCFrame * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	return Parts.new("Part", props)
end

-- Schild-Oberfläche auf einer Seite eines Bauteils.
function Parts.surfaceGui(part, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.3
	gui.Parent = part
	return gui
end

function Parts.text(parent, props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Size = UDim2.fromScale(1, 1)
	for key, value in props do
		label[key] = value
	end
	label.Parent = parent
	return label
end

return Parts
