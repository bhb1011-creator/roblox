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
	{ speaker = "mrsWagner", look = "player", text = "Sit, sit. You must be starving.", wait = 1.2 },
	{ speaker = "mrWagner", look = "down", text = "We don't get many guests anymore.", wait = 0.8 },
	{ speaker = "mrsWagner", text = "Sarp sends them to us. He always does.", wait = 0.6 },
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

return Kapitel2Dialogue
