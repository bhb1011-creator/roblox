-- Start-Menü der Lobby: Holzschild „Play [P]“ (links, über dem Shop-Schild). Darin ein Zettel an
-- der Bretterwand: „Play alone“ oder einen Spieler aus dieser Lobby einladen. Der Eingeladene
-- bekommt oben eine Karte zum Annehmen. Gestartet wird auf dem Server (PlayMenu.lua).
-- Stil wie der Shop (Handelsposten): Bretter, vergilbtes Papier, Klebeband, Nägel, Messing.

-- Liegen im selben Studio-Ort auch die Skripte von Level 1, läuft nur das Level
if game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Level") then
	return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:WaitForChild("PlayMenu")
local player = Players.LocalPlayer

local INVITE_TIME = 30

local T = {
	wood = Color3.fromRGB(70, 48, 33),
	woodDark = Color3.fromRGB(38, 26, 19),
	woodLight = Color3.fromRGB(104, 72, 48),
	paper = Color3.fromRGB(233, 220, 194),
	paperShade = Color3.fromRGB(214, 198, 166),
	ink = Color3.fromRGB(46, 36, 29),
	inkMuted = Color3.fromRGB(110, 92, 74),
	stamp = Color3.fromRGB(168, 38, 34),
	brass = Color3.fromRGB(206, 162, 82),
	brassDark = Color3.fromRGB(120, 86, 38),
	tape = Color3.fromRGB(226, 214, 170),
	titleFont = Enum.Font.SpecialElite,
	bodyFont = Enum.Font.GothamMedium,
	boldFont = Enum.Font.GothamBold,
	touch = 48,
}

local function create(className, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

local function stroke(color, thickness)
	return create("UIStroke", { Color = color, Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(props)
	props.BackgroundTransparency = 1
	props.TextColor3 = props.TextColor3 or T.ink
	props.Font = props.Font or T.bodyFont
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

local function nail(parent, position)
	return create("Frame", { Name = "Nail", AnchorPoint = Vector2.new(0.5, 0.5), Position = position, Size = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.fromRGB(150, 146, 140), Parent = parent }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = Color3.fromRGB(40, 36, 32), Thickness = 1 }),
	})
end

local function tape(parent, position, rotation)
	return create("Frame", { Name = "Tape", AnchorPoint = Vector2.new(0.5, 0.5), Position = position, Size = UDim2.fromOffset(62, 18), Rotation = rotation, BackgroundColor3 = T.tape, BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = parent })
end

local function planks(parent, count)
	local holder = create("Frame", { Name = "Planks", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Parent = parent }, { corner(10) })
	local shades = { 0, 0.06, -0.04, 0.03, -0.07, 0.05, -0.02 }
	for i = 0, count - 1 do
		local k = shades[i % #shades + 1]
		local color = T.wood:Lerp(k > 0 and T.woodLight or T.woodDark, math.abs(k) * 4)
		create("Frame", { Name = "Plank", Position = UDim2.fromScale(i / count, 0), Size = UDim2.new(1 / count, -2, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = holder }, {
			create("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.92, 0.92, 0.92)), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.88, 0.88, 0.88)) }) }),
		})
	end
	return holder
end

-- Knopf, der beim Drüberfahren etwas größer wird und beim Drücken nachgibt
local function lively(button)
	local scale = create("UIScale", { Parent = button })
	local function to(value)
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		to(1.03)
	end)
	button.MouseLeave:Connect(function()
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.97)
	end)
	button.MouseButton1Up:Connect(function()
		to(1.03)
	end)
	return button
end

local function brassButton(props)
	props.BackgroundColor3 = props.BackgroundColor3 or T.brass
	props.AutoButtonColor = true
	props.Font = props.Font or T.titleFont
	props.TextColor3 = props.TextColor3 or T.ink
	local button = create("TextButton", props, {
		corner(6),
		stroke(T.brassDark, 2),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.8, 0.78, 0.72)) }),
	})
	return lively(button)
end

local function woodButton(props)
	props.BackgroundColor3 = props.BackgroundColor3 or T.wood
	props.AutoButtonColor = true
	props.Font = props.Font or T.titleFont
	props.TextColor3 = props.TextColor3 or T.paper
	local button = create("TextButton", props, { corner(6), stroke(T.woodDark, 2) })
	return lively(button)
end

local gui = create("ScreenGui", {
	Name = "PlayMenu",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 8,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

------------------------------------------------------------------ Schild „Play“ (immer sichtbar)
local sign = create("TextButton", {
	Name = "OpenPlay",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 18, 1, -126), -- über dem Shop-Schild
	Size = UDim2.fromOffset(170, 64),
	Rotation = 1.5,
	BackgroundColor3 = T.woodLight,
	AutoButtonColor = true,
	Text = "",
	Parent = gui,
}, {
	corner(6),
	stroke(T.woodDark, 3),
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.8, 0.8, 0.8)) }),
})
lively(sign)
nail(sign, UDim2.new(0, 10, 0.5, 0))
nail(sign, UDim2.new(1, -10, 0.5, 0))
text({ Name = "Label", Position = UDim2.fromOffset(22, 4), Size = UDim2.new(1, -44, 0, 36), TextXAlignment = Enum.TextXAlignment.Center, Font = T.titleFont, TextSize = 32, Text = "Play", TextColor3 = T.paper, TextStrokeColor3 = T.woodDark, TextStrokeTransparency = 0.3, Parent = sign })
text({ Name = "Hint", Position = UDim2.fromOffset(22, 38), Size = UDim2.new(1, -44, 0, 18), TextXAlignment = Enum.TextXAlignment.Center, Font = T.bodyFont, TextSize = 13, Text = UserInputService.KeyboardEnabled and "the whole game  [P]" or "the whole game", TextColor3 = T.paperShade, Parent = sign })

------------------------------------------------------------------ der Zettel an der Bretterwand
local overlay = create("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Visible = false, Parent = gui })
local board = create("Frame", {
	Name = "Board",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(540, 600),
	BackgroundColor3 = T.woodDark,
	Parent = overlay,
}, { corner(10), stroke(Color3.fromRGB(22, 15, 11), 4) })
local boardScale = create("UIScale", { Parent = board })
planks(board, 6)
create("Frame", { Name = "Vignette", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = board }, {
	corner(10),
	create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.75, 1), NumberSequenceKeypoint.new(1, 0.4) }) }),
})
for _, position in { UDim2.fromOffset(12, 12), UDim2.new(1, -12, 0, 12), UDim2.new(0, 12, 1, -12), UDim2.new(1, -12, 1, -12) } do
	nail(board, position)
end

local note = create("Frame", {
	Name = "Note",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 6),
	Size = UDim2.new(1, -64, 1, -70),
	Rotation = -1.2,
	BackgroundColor3 = T.paper,
	Parent = board,
}, {
	corner(3),
	create("UIGradient", { Rotation = 70, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.7, Color3.new(0.97, 0.95, 0.9)), ColorSequenceKeypoint.new(1, Color3.new(0.86, 0.82, 0.74)) }) }),
})
-- Kaffeefleck unten rechts und eine vergilbte Ecke
create("Frame", { Name = "CoffeeRing", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -46, 1, -44), Size = UDim2.fromOffset(62, 62), BackgroundTransparency = 1, Parent = note }, {
	create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	create("UIStroke", { Color = Color3.fromRGB(150, 108, 64), Thickness = 4, Transparency = 0.72 }),
})
tape(note, UDim2.new(0, 18, 0, 0), -32)
tape(note, UDim2.new(0.62, 0, 0, 0), 4)

local close = woodButton({
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 14),
	Size = UDim2.fromOffset(T.touch, T.touch),
	Text = "X",
	TextSize = 24,
	Modal = true, -- Maus frei, solange der Zettel offen ist (sonst Ich-Sicht-Sperre)
	ZIndex = 3,
	Parent = board,
})

local content = create("Frame", { Name = "Content", Position = UDim2.fromOffset(28, 26), Size = UDim2.new(1, -56, 1, -46), BackgroundTransparency = 1, Parent = note }, {
	create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
})
text({ Name = "Title", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 40), Font = T.titleFont, TextSize = 36, Text = Config.GAME_TITLE, Parent = content })
text({ Name = "Subtitle", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 20), Font = T.titleFont, TextSize = 17, TextColor3 = T.inkMuted, Text = "Chapter 1 to 3 – the whole night, from the start.", Parent = content })
local dashes = create("Frame", { Name = "Dashes", LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, ClipsDescendants = true, Parent = content }, {
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Center }),
})
for _ = 1, 32 do -- passt genau auf den Zettel (gedrehte Rahmen schneiden nicht ab)
	create("Frame", { Size = UDim2.fromOffset(8, 2), BackgroundColor3 = T.inkMuted, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = dashes })
end

local soloButton = brassButton({ Name = "PlayAlone", LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 66), Text = "", Parent = content })
text({ Position = UDim2.fromOffset(18, 6), Size = UDim2.new(1, -36, 0, 32), Font = T.titleFont, TextSize = 28, Text = "Play alone", Parent = soloButton })
text({ Position = UDim2.fromOffset(18, 38), Size = UDim2.new(1, -36, 0, 18), TextSize = 14, TextColor3 = T.inkMuted, Text = "Starts right away. Only you.", Parent = soloButton })

text({ Name = "Together", LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 30), Font = T.titleFont, TextSize = 22, Text = "…or together with a friend", Parent = content })
text({ Name = "TogetherHint", LayoutOrder = 6, Size = UDim2.new(1, 0, 0, 34), TextSize = 13, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = T.inkMuted, Text = "Your friend has to be in this lobby. Invite them here – they get a note and have " .. INVITE_TIME .. " seconds to say yes.", Parent = content })

local list = create("ScrollingFrame", {
	Name = "Players",
	LayoutOrder = 7,
	Size = UDim2.new(1, 0, 0, 188),
	BackgroundColor3 = T.paperShade,
	BackgroundTransparency = 0.55,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = T.inkMuted,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = content,
}, {
	corner(4),
	create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12) }),
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})

------------------------------------------------------------------ Spielerliste
local thumbnails = {}
local function headshot(userId, image)
	if thumbnails[userId] then
		image.Image = thumbnails[userId]
		return
	end
	task.spawn(function()
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		if ok and url then
			thumbnails[userId] = url
			if image.Parent then
				image.Image = url
			end
		end
	end)
end

local function canInviteToLobby()
	local ok, result = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
	return ok and result
end

local refreshing = false
local function refreshList()
	if refreshing then
		return
	end
	refreshing = true
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local others = {}
	for _, other in Players:GetPlayers() do
		if other ~= player then
			table.insert(others, other)
		end
	end
	table.sort(others, function(a, b)
		return a.DisplayName:lower() < b.DisplayName:lower()
	end)

	for index, other in others do
		local row = create("Frame", { Name = "Row", LayoutOrder = index, Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = T.paper, Parent = list }, { corner(4) })
		local image = create("ImageLabel", { Name = "Headshot", Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = T.paperShade, Parent = row }, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			create("UIStroke", { Color = T.inkMuted, Thickness = 1, Transparency = 0.4 }),
		})
		headshot(other.UserId, image)
		text({ Name = "Name", Position = UDim2.fromOffset(60, 8), Size = UDim2.new(1, -190, 0, 22), Font = T.boldFont, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Text = other.DisplayName, Parent = row })
		text({ Name = "User", Position = UDim2.fromOffset(60, 30), Size = UDim2.new(1, -190, 0, 16), TextSize = 12, TextColor3 = T.inkMuted, TextTruncate = Enum.TextTruncate.AtEnd, Text = "@" .. other.Name, Parent = row })
		local invite = woodButton({ Name = "Invite", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(118, T.touch), Text = "Invite", TextSize = 20, Parent = row })
		invite.Activated:Connect(function()
			remote:FireServer("invite", other.UserId)
			invite.Text = "Sent"
			invite.Active = false
			invite.AutoButtonColor = false
			invite.BackgroundColor3 = T.inkMuted
			task.delay(4, function()
				if invite.Parent then
					invite.Text = "Invite"
					invite.Active = true
					invite.AutoButtonColor = true
					invite.BackgroundColor3 = T.wood
				end
			end)
		end)
	end

	if #others == 0 then
		text({ Name = "Empty", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 40), TextSize = 14, TextWrapped = true, TextColor3 = T.inkMuted, Text = "No one else is here yet. Bring your friend into this lobby first:", Parent = list })
		local bring = woodButton({ Name = "BringFriend", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, T.touch), Text = "Invite a friend to this lobby", TextSize = 19, Parent = list })
		bring.Activated:Connect(function()
			if canInviteToLobby() then
				pcall(SocialService.PromptGameInvite, SocialService, player)
			else
				bring.Text = "Use the Roblox menu (top left) → Invite"
			end
		end)
	end
	refreshing = false
end

------------------------------------------------------------------ öffnen / schließen
local function fitBoard()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	boardScale.Scale = math.min(1, (viewport.Y - 24) / 600, (viewport.X - 24) / 540)
end

local busy = false
local function setOpen(open)
	if busy then
		return
	end
	if open then
		fitBoard()
		refreshList()
		overlay.Visible = true
		board.Position = UDim2.new(0.5, 0, 0.5, 30)
		TweenService:Create(board, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	else
		overlay.Visible = false
	end
end

sign.Activated:Connect(function()
	setOpen(not overlay.Visible)
end)
close.Activated:Connect(function()
	setOpen(false)
end)
soloButton.Activated:Connect(function()
	remote:FireServer("solo")
	setOpen(false)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or busy then
		return
	end
	if input.KeyCode == Enum.KeyCode.P then
		setOpen(not overlay.Visible)
	end
end)
Players.PlayerAdded:Connect(function()
	if overlay.Visible then
		refreshList()
	end
end)
Players.PlayerRemoving:Connect(function()
	task.defer(function()
		if overlay.Visible then
			refreshList()
		end
	end)
end)

------------------------------------------------------------------ Einladung (Karte oben in der Mitte)
local card = create("Frame", {
	Name = "InviteCard",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, -200),
	Size = UDim2.fromOffset(420, 176),
	Rotation = 1,
	BackgroundColor3 = T.paper,
	Visible = false,
	Parent = gui,
}, {
	corner(3),
	create("UIStroke", { Color = T.woodDark, Thickness = 2, Transparency = 0.3 }),
	create("UIGradient", { Rotation = 70, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.88, 0.84, 0.76)) }),
})
local cardScale = create("UIScale", { Parent = card })
tape(card, UDim2.new(0.5, 0, 0, 0), -3)
local cardImage = create("ImageLabel", { Name = "Headshot", Position = UDim2.fromOffset(18, 22), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = T.paperShade, Parent = card }, {
	create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	create("UIStroke", { Color = T.inkMuted, Thickness = 1, Transparency = 0.4 }),
})
local cardText = text({ Name = "Text", Position = UDim2.fromOffset(82, 18), Size = UDim2.new(1, -140, 0, 60), Font = T.titleFont, TextSize = 19, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Parent = card })
local cardTimer = text({ Name = "Timer", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 8), Size = UDim2.fromOffset(40, 16), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.stamp, Text = "", Parent = card })
local acceptButton = brassButton({ Name = "Accept", Position = UDim2.new(0, 18, 1, -66), Size = UDim2.new(0.55, -24, 0, 52), Text = "Play together", TextSize = 22, Modal = true, Parent = card })
local declineButton = woodButton({ Name = "Decline", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 1, -66), Size = UDim2.new(0.45, -18, 0, 52), Text = "No thanks", TextSize = 20, Parent = card })

local currentInvite -- { from = userId, token = n }
local inviteToken = 0

local function hideCard()
	currentInvite = nil
	TweenService:Create(card, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 0, -200) }):Play()
	task.delay(0.22, function()
		if not currentInvite then
			card.Visible = false
		end
	end)
end

local function showCard(fromUserId, fromName)
	inviteToken += 1
	local token = inviteToken
	currentInvite = { from = fromUserId, token = token }
	cardText.Text = fromName .. " wants to play the whole game with you."
	cardImage.Image = ""
	headshot(fromUserId, cardImage)
	local camera = workspace.CurrentCamera
	cardScale.Scale = math.min(1, ((camera and camera.ViewportSize.X or 1280) - 24) / 420)
	card.Visible = true
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 70) }):Play()
	task.spawn(function()
		for secondsLeft = INVITE_TIME, 1, -1 do
			if not currentInvite or currentInvite.token ~= token then
				return
			end
			cardTimer.Text = secondsLeft .. " s"
			task.wait(1)
		end
		if currentInvite and currentInvite.token == token then
			hideCard()
		end
	end)
end

acceptButton.Activated:Connect(function()
	if currentInvite then
		remote:FireServer("accept", currentInvite.from)
		hideCard()
	end
end)
declineButton.Activated:Connect(function()
	if currentInvite then
		remote:FireServer("decline", currentInvite.from)
		hideCard()
	end
end)

------------------------------------------------------------------ Abfahrt: schwarzer Bildschirm
local fade = create("Frame", { Name = "Fade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 20, Parent = gui })
local fadeText = text({ Name = "Text", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.8, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Center, Font = T.titleFont, TextSize = 30, TextColor3 = T.paper, TextTransparency = 1, Text = "", ZIndex = 21, Parent = fade })

remote.OnClientEvent:Connect(function(what, a, b)
	if what == "invited" then
		showCard(a, b)
	elseif what == "inviteGone" then
		if currentInvite and currentInvite.from == a then
			hideCard()
		end
	elseif what == "leaving" then
		busy = true
		overlay.Visible = false
		hideCard()
		fadeText.Text = a == "Duo" and "The two of you set off…" or "You set off…"
		fade.Visible = true
		TweenService:Create(fade, TweenInfo.new(1.8), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(fadeText, TweenInfo.new(1.8), { TextTransparency = 0 }):Play()
	elseif what == "failed" then
		busy = false
		TweenService:Create(fade, TweenInfo.new(1), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(fadeText, TweenInfo.new(1), { TextTransparency = 1 }):Play()
		task.delay(1.05, function()
			if not busy then
				fade.Visible = false
			end
		end)
	end
end)
