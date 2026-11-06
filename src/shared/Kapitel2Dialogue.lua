-- Kapitel 2, Anfang: Ankunft bei den Wagners. Alle Texte und der Ablauf.
-- Gesprochen wird Englisch (erst mal mit den Roblox-Stimmen), dazu Untertitel.
--
-- speaker: "mrsWagner", "mrWagner" oder (bei Antworten) der Spieler.
-- Ein Text ist ein String oder { solo = "...", duo = "..." }.
-- `action` passiert vor dem Satz (siehe Kapitel2.lua auf dem Server):
--   knock       – Klopfen, alle bleiben stehen, Stille
--   stepsInside – Schritte im Haus kommen zur Tür
--   doorCrack   – die Tür geht einen Spalt auf (mit Kette)
--   doorClose   – Tür kurz zu
--   chain       – die Kette wird abgenommen, sie tritt zurück
--   doorOpen    – die Tür geht ganz auf
--   mrComes     – Mr. Wagner kommt aus der Küche durch den Flur zur Tür (man hört ihn)
--   mrAppears   – er steht hinter ihr, die Kerze flackert kurz
--   invite      – beide treten zur Seite, man geht selbst hinein, die Tür fällt zu
--   candles     – jeder Spieler bekommt eine Kerze in die Hand (mehr Licht im Haus)
--   point       – Mr. Wagner zeigt die Treppe hoch
--   leave       – die Wagners gehen durch die Tür hinter der Halle und schließen sie
--   finish      – Ende des Gesprächs: danach kann man sich frei im Haus umsehen und
--                 im Gästezimmer schlafen gehen
-- `look` = wohin der Sprecher schaut: "player", "down" oder "stairs".
-- `wait` = Pause danach (Sekunden).
local Kapitel2Dialogue = {}

Kapitel2Dialogue.NAMES = {
	mrsWagner = "Mrs. Wagner",
	mrWagner = "Mr. Wagner",
	sarpDemon = "Sarp",
	lucy = "Lucy",
	tommy = "Tommy",
	player = "Du", -- innere Stimme
	police = "Police",
}

Kapitel2Dialogue.SCRIPT = {
	{ action = "knock" },
	{ action = "stepsInside" },
	{ action = "doorCrack", wait = 0.9 },
	{ speaker = "mrsWagner", text = "Oh... There you are.", wait = 0.9 },
	{ speaker = "mrsWagner", text = "We were starting to think you got lost." },
	{ action = "doorClose", wait = 0.3 },
	{ action = "chain", wait = 0.8 },
	{ action = "doorOpen", wait = 0.8 },
	{
		choice = {
			{
				text = { solo = "Sorry I'm so late.", duo = "Sorry we're so late." },
				reply = { { speaker = "mrsWagner", text = "Late? No... You're right on time." } },
			},
			{
				text = "Why are all the lights off?",
				reply = { { speaker = "mrsWagner", text = "The power goes out a lot up here. We're used to the dark." } },
			},
		},
	},
	{ action = "mrComes" },
	{ speaker = "mrsWagner", text = "You met Sarp on the way, didn't you?", wait = 0.9 },
	{ speaker = "mrsWagner", text = "He always finds our guests first.", wait = 0.4 },
	{ action = "mrAppears", wait = 0.9 },
	{ speaker = "mrWagner", look = "player", text = "He shouldn't have.", wait = 0.7 },
	{ speaker = "mrsWagner", text = "...Richard.", wait = 1.3 },
	{ speaker = "mrWagner", look = "down", text = "...Welcome. You must be tired." },
	{
		choice = {
			{
				text = "Who is Sarp?",
				reply = { { speaker = "mrsWagner", text = "A good neighbor. He takes care of things." } },
			},
			{
				text = "He was... strange.",
				reply = {
					{ speaker = "mrWagner", look = "player", text = "Yes. He is.", wait = 0.5 },
					{ speaker = "mrsWagner", text = "Richard.", wait = 0.4 },
				},
			},
		},
	},
	{ speaker = "mrsWagner", text = "Come in. Don't let the cold in." },
	{ action = "invite", wait = 1.2 },
	{ speaker = "mrsWagner", text = "The children are already asleep. You'll see them at breakfast.", wait = 0.6 },
	{ speaker = "mrsWagner", action = "candles", text = { solo = "Here. Take this candle.", duo = "Here. Take these candles." }, wait = 0.4 },
	{ speaker = "mrsWagner", text = "The house gets very dark at night.", wait = 0.8 },
	{ speaker = "mrWagner", action = "point", look = "stairs", text = "Your room is upstairs. Second door on the left.", wait = 1.3 },
	{ speaker = "mrWagner", text = "Not the first one.", wait = 1 },
	{ speaker = "mrWagner", look = "player", text = "And whatever you hear tonight...", wait = 0.7 },
	{ speaker = "mrWagner", text = "...it's just the house.", wait = 1.5 },
	{ speaker = "mrsWagner", look = "player", text = "Good night. Sleep well.", wait = 0.4 },
	{ action = "leave", wait = 1 },
	{ action = "finish" },
}

-- Die erste Nacht (Night.lua): Man wacht von Schreien auf, Mrs. Wagner steht in der Tür
-- und holt einen mitten in der Nacht zum Essen. Aktionen:
--   followMrs – sie geht voraus ins Esszimmer, man folgt ihr
--   sitDown   – alle setzen sich an den Tisch
--   knock     – es klopft schwer an der Haustür, die Kerzen flackern
--   flee      – die Wagners rennen durch die Küche weg und schließen hinter sich ab
Kapitel2Dialogue.NIGHT_WAKE = {
	{ speaker = "mrsWagner", look = "player", text = "Oh. You're awake.", wait = 0.6 },
	{
		choice = {
			{
				text = "What was that scream?",
				reply = { { speaker = "mrsWagner", text = "Scream? I didn't hear anything.", wait = 0.6 } },
			},
			{
				text = "What time is it?",
				reply = { { speaker = "mrsWagner", text = "Time for dinner, of course.", wait = 0.6 } },
			},
		},
	},
	{ speaker = "mrsWagner", text = "Come downstairs. Dinner is ready.", wait = 0.4 },
	{ speaker = "mrsWagner", look = "down", text = "Richard is waiting.", wait = 0.6 },
	{ action = "followMrs" },
}

Kapitel2Dialogue.NIGHT_DINNER = {
	{ action = "sitDown", wait = 1 },
	{ speaker = "mrsWagner", look = "player", text = "Sit, sit. You must be starving.", wait = 0.8 },
	{ speaker = "lucy", look = "player", text = "We waited for you.", wait = 1 },
	{ speaker = "mrWagner", look = "down", text = "We don't get many guests anymore.", wait = 0.8 },
	{ speaker = "mrsWagner", text = "Sarp sends them to us. He always does.", wait = 0.6 },
	{ speaker = "tommy", look = "down", text = "He likes the new ones.", wait = 0.8 },
	{ speaker = "mrWagner", look = "player", text = "Margaret. Not now.", wait = 1 },
	{
		choice = {
			{
				text = "Why are we eating in the middle of the night?",
				reply = { { speaker = "mrWagner", text = "Because that's when it's safe.", wait = 0.8 } },
			},
			{
				text = "The plates are empty.",
				reply = { { speaker = "mrsWagner", text = "...Are they?", wait = 1.2 } },
			},
		},
	},
	{ action = "knock", wait = 1.5 },
	{ speaker = "mrsWagner", look = "down", text = "...He's early.", wait = 0.5 },
	{ speaker = "mrWagner", look = "player", text = "Hide. Now!", wait = 0.2 },
	{ speaker = "mrWagner", text = "And whatever you hear... don't make a sound." },
	{ action = "flee" },
}

-- Nachdem Sarp das Esszimmer verlassen hat: Richard kommt zurück
Kapitel2Dialogue.NIGHT_RICHARD = {
	{ action = "richardComes" },
	{ speaker = "mrWagner", look = "player", text = "It's safe. He's gone... for now.", wait = 0.8 },
	{ speaker = "mrWagner", text = "Listen to me. There's an axe in the cellar.", wait = 0.5 },
	{ speaker = "mrWagner", text = "Take it upstairs. Break open the first door. The one we nailed shut.", wait = 0.8 },
	{
		choice = {
			{
				text = "What's behind that door?",
				reply = { { speaker = "mrWagner", look = "down", text = "The reason you are here.", wait = 0.8 } },
			},
			{
				text = "Why should we trust you?",
				reply = { { speaker = "mrWagner", text = "Because I'm the only one left who still fights him.", wait = 0.8 } },
			},
		},
	},
	{ speaker = "mrWagner", look = "down", text = "Hurry. Before Margaret comes back.", wait = 0.4 },
	{ action = "richardLeaves" },
}

-- Was Sarp beim Suchen flüstert (zufällig)
Kapitel2Dialogue.SARP_WHISPERS = {
	"I know you're here.",
	"I can hear your heart.",
	"Come out... come out...",
	"You can't hide from me.",
}
Kapitel2Dialogue.SARP_LEAVES = "...Not yet. Soon."

-- Wenn nach dem Hereinbitten jemand draußen stehen bleibt
Kapitel2Dialogue.COME_INSIDE = { speaker = "mrsWagner", text = "Please. Come inside." }

-- Die Flucht (Escape.lua): Richard wartet im Raum hinter Tür 1. Er verrät nichts darüber,
-- was mit seiner Familie passiert ist (das kommt erst im DLC) – er sagt nur, was zu tun ist.
Kapitel2Dialogue.ESCAPE_INTRO = {
	{ speaker = "mrWagner", look = "player", text = "You made it in. Good.", wait = 0.6 },
	{ speaker = "mrWagner", text = "Don't ask me what this room is. Not tonight.", wait = 0.5 },
	{ speaker = "mrWagner", text = "That safe holds a key. It opens the way out of this house.", wait = 0.4 },
	{ speaker = "mrWagner", text = "Only Margaret knows the combination. So we open it another way.", wait = 0.4 },
	{ speaker = "mrWagner", text = "Somewhere in this house there are chemicals. And black powder.", wait = 0.3 },
	{ speaker = "mrWagner", text = "Find both. Bring them to this desk.", wait = 0.6 },
	{
		choice = {
			{
				text = "Why are you helping us?",
				reply = { { speaker = "mrWagner", look = "down", text = "Because somebody should have done this a long time ago.", wait = 0.8 } },
			},
			{
				text = "What happened to your family?",
				reply = { { speaker = "mrWagner", look = "down", text = "That is not your story. Not yet.", wait = 0.8 } },
			},
		},
	},
	{ speaker = "mrWagner", look = "player", text = "Take this. It's the only light I can give you.", wait = 0.2 },
	{ action = "redCandles", wait = 0.6 },
	{ speaker = "mrWagner", text = "And stay away from my family. They won't let you leave anymore.", wait = 0.2 },
	{ speaker = "mrWagner", text = "They will hurt you. Go. I'll wait here.", wait = 0.4 },
}
-- einzelne Sätze während der Flucht (Sprecher, Text)
Kapitel2Dialogue.ESCAPE = {
	splitUp = { "mrWagner", "There are two of you. Split up. It's faster." },
	gotChemicals = { "player", "Chemicals. This should do it." },
	gotPowder = { "player", "Black powder. Careful with that." },
	carryOne = { "player", "My hands are full. The other one has to carry that." },
	firstPlaced = { "mrWagner", "Good. Now the other one." },
	bothPlaced = { "mrWagner", "That's everything. Put it together, here on the desk." },
	built = { "mrWagner", "Now put it on the safe door." },
	onSafe = { "mrWagner", "Good. I will keep the others away. Light the fuse when I am gone, then hide." },
	lit = { "player", "It is lit. Hide! Now!" },
	candleLost = { "player", "My candle... it's gone. I can barely see anything." },
	heHeard = { "player", "He heard that. He's coming up here!" },
	afterSearch = { "player", "He's gone. Red candles... somebody lit a path. Downstairs." },
	takeKey = { "player", "The key. Now follow the candles. And keep quiet." },
	sneakHint = { "player", "If I walk slowly, he won't hear me." },
	shelfLocked = { "player", "There's a keyhole behind this shelf. I need the key from the safe." },
	shelfOpen = { "player", "It fits. There's a passage behind the shelf." },
	hurt = { "player", "Get away from me!" },
}
-- Die Familie greift jetzt an (sagt dabei etwas)
Kapitel2Dialogue.FAMILY_ANGRY = {
	mrsWagner = { "You're not leaving, dear.", "Where do you think you're going?", "Dinner isn't over." },
	lucy = { "Mommy says you have to stay!", "Don't go. Please don't go.", "Found you!" },
	tommy = { "You can't leave! You can't!", "I'll tell him where you are!", "Got you!" },
}
-- Nach Sarps Suche ist in Wahrheit niemand mehr da – man hört die Familie aber noch flüstern
Kapitel2Dialogue.FAMILY_PHANTOM = {
	mrsWagner = { "Dinner is getting cold, dear...", "Where did you go?" },
	lucy = { "I can hear you breathing...", "Mommy, they're downstairs." },
	tommy = { "Psst... over here...", "You can't leave. Nobody leaves." },
}
-- Kapitel 3 (Kapitel3.lua): was im Ritualraum gesagt wird. Bewusst ohne Erklärung, warum
-- die Familie so ist (das kommt erst im DLC).
Kapitel2Dialogue.KAPITEL3 = {
	-- die Familie flüstert im Chor (Untertitel auf dem Client, ohne Namen)
	whispers = { "...he is coming...", "...stay...", "...stay with us...", "...forever..." },
	sarpDoor = "You opened my door.",
	sarpNobody = "Nobody leaves this house.",
	sarpGrab = "Stay.",
	tunnel = "The tunnel! Go! Now!",
	-- das Ende: Sarps Hütte (voice = Name der Aufnahme in Config.VOICE_LINES)
	hutSeen = { text = "A cabin... There's light inside!", voice = "k3_cabin_light" },
	hutInside = { text = "Wait... that jacket. The name on the mailbox... This is Sarp's cabin.", voice = "k3_sarps_cabin" },
	hutPhone = {
		text = { solo = "There's a phone. I have to call the police!", duo = "There's a phone. We have to call the police!" },
		voice = { solo = "k3_phone_solo", duo = "k3_phone_duo" },
	},
	police1 = { text = "911, what's your emergency?", voice = "k3_police_01" },
	call1 = {
		text = {
			solo = "Please, you have to help me! I'm in a cabin by the old forest road. Something is hunting me!",
			duo = "Please, you have to help us! We're in a cabin by the old forest road. Something is hunting us!",
		},
		voice = { solo = "k3_call_01_solo", duo = "k3_call_01_duo" },
	},
	police2 = { text = "Stay calm. Stay inside and lock the door. A patrol car is on its way.", voice = "k3_police_02" },
	call2 = { text = "Please... hurry.", voice = "k3_call_02" },
	police3 = { text = "Ten minutes. Don't open the door for anyone but us.", voice = "k3_police_03" },
	-- (nur als Untertitel, wenn das Biest wieder weg ist)
	notReal = "It's not real... It's not real...",
	knock = { text = "Police! Is anyone in there?", voice = "k3_police_04" },
	comingOut = {
		text = { solo = "I'm here! I'm coming out!", duo = "We're here! We're coming out!" },
		voice = { solo = "k3_coming_out_solo", duo = "k3_coming_out_duo" },
	},
}
-- Sarp nach der Explosion
Kapitel2Dialogue.SARP_ALERT = { "Who opened my door?", "I smell you.", "Little thieves..." }

return Kapitel2Dialogue
