-- Antwortauswahl im Gespräch: zwei Knöpfe unten im Bild. Antworten darf nur der
-- Fahrer (mit Maus, Finger oder den Tasten 1 und 2); der Mitfahrer sieht, wer gerade
-- entscheidet.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Choices = {}

local holder, info, buttons = nil, nil, {}
local onPick
local active = false
local closeToken = 0

function Choices.init(gui)
	holder = Instance.new("Frame")
	holder.Name = "Choices"
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.fromScale(0.5, 0.78)
	holder.Size = UDim2.new(0.6, 0, 0, 140)
	holder.BackgroundTransparency = 1
	holder.Visible = false
	holder.ZIndex = 7
	holder.Parent = gui

	info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, 0, 0, 24)
	info.BackgroundTransparency = 1
	info.Font = Enum.Font.SpecialElite
	info.TextSize = 18
	info.TextColor3 = Color3.fromRGB(190, 185, 175)
	info.ZIndex = 7
	info.Parent = holder

	for index = 1, 2 do
		local button = Instance.new("TextButton")
		button.Name = "Option" .. index
		button.Position = UDim2.new(0, 0, 0, 30 + (index - 1) * 55)
		button.Size = UDim2.new(1, 0, 0, 48)
		button.BackgroundColor3 = Color3.fromRGB(15, 14, 13)
		button.BackgroundTransparency = 0.25
		button.AutoButtonColor = true
		button.Font = Enum.Font.SpecialElite
		button.TextSize = 22
		button.TextColor3 = Color3.fromRGB(235, 228, 215)
		button.ZIndex = 7
		button.Parent = holder
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = Color3.fromRGB(120, 105, 90)
		stroke.Thickness = 1.5
		stroke.Parent = button
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button
		button.Activated:Connect(function()
			if active and onPick then
				onPick(index)
			end
		end)
		buttons[index] = button
	end

	UserInputService.InputBegan:Connect(function(input)
		if not active or not onPick then
			return
		end
		if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
			onPick(1)
		elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo then
			onPick(2)
		end
	end)
end

-- options: Texte; canChoose: ob dieser Spieler antworten darf; pick(index) schickt die Wahl
function Choices.show(options, canChoose, chooserName, timeout, pick)
	closeToken += 1
	active = canChoose
	onPick = canChoose and function(index)
		active = false
		pick(index)
	end or nil
	info.Text = canChoose and "Wähle deine Antwort (1 / 2)" or (chooserName .. " antwortet …")
	for index, button in buttons do
		button.Visible = options[index] ~= nil
		button.Text = string.format("%d   %s", index, options[index] or "")
		button.Active = canChoose
		button.TextTransparency = 0
		button.BackgroundTransparency = 0.25
	end
	holder.Visible = true
	-- Restzeit anzeigen
	local token = closeToken
	task.spawn(function()
		local deadline = os.clock() + timeout
		while holder.Visible and closeToken == token do
			local left = math.ceil(deadline - os.clock())
			if left <= 10 and left >= 0 then
				info.Text = (canChoose and "Wähle deine Antwort (1 / 2)" or (chooserName .. " antwortet …")) .. "   " .. left
			end
			task.wait(0.25)
		end
	end)
end

-- Die gewählte Antwort kurz hervorheben, dann ausblenden
function Choices.chosen(index)
	active = false
	onPick = nil
	closeToken += 1
	local token = closeToken
	for other, button in buttons do
		if other ~= index then
			TweenService:Create(button, TweenInfo.new(0.3), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		end
	end
	task.delay(0.8, function()
		if closeToken == token then
			holder.Visible = false
		end
	end)
end

-- Darf dieser Spieler gerade wählen? Dann braucht er einen freien Mauszeiger.
function Choices.isChoosing()
	return active
end

return Choices
