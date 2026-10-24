-- Alle Texte von Level 1: Erzählung während der Fahrt, das Gespräch mit Sarp und
-- die beiden Enden. Gesprochen wird auf Englisch (Text-to-Speech), dazu Untertitel.
--
-- Ein Text ist entweder ein String oder eine Tabelle { solo = "...", duo = "..." },
-- wenn er allein anders lautet als zu zweit ("I" statt "we").
-- speaker: "narrator" (Erzähler), "sarp" (der Fremde) oder "player" (der Spieler,
-- der die Antwort ausgewählt hat).
local Dialogue = {}

-- Den passenden Text für allein oder zu zweit holen
function Dialogue.text(entry, duo)
	if type(entry) == "table" then
		return duo and entry.duo or entry.solo
	end
	return entry
end

-- Ungefähre Sprechdauer in Sekunden (danach kommt der nächste Satz)
function Dialogue.duration(text, speed)
	return (1 + #text * 0.068) / (speed or 1)
end

-- Erzählung während der Fahrt; `at` = Sekunden nach dem Start der Zwischensequenz
Dialogue.NARRATION = {
	{ at = 8.5, text = "October 14th. 11:52 PM." },
	{
		at = 12,
		text = {
			solo = "The camping trip was over. One more night with a host family, the Wagners. Then I could finally go home.",
			duo = "The camping trip was over. One more night with a host family, the Wagners. Then we could finally go home.",
		},
	},
	{ at = 21, text = "Mrs. Wagner's directions were strange. Take the old forest road. Don't stop. No matter what you see." },
	{
		at = 29.5,
		radioOff = true, -- ab hier rauscht das Radio nur noch
		text = {
			solo = "Then the radio lost its signal. And the navigation lost the road. I had to stop.",
			duo = "Then the radio lost its signal. And the navigation lost the road. We had to stop.",
		},
	},
	{
		at = 36.5,
		text = {
			solo = "That's when I saw him. A man, walking out of the forest. Straight towards me.",
			duo = "That's when we saw him. A man, walking out of the forest. Straight towards us.",
		},
	},
}

-- Das Gespräch am Fenster. `reveal` = ab diesem Satz kennt man Sarps Namen.
-- `action` lässt Sarp etwas tun, `wait` = zusätzliche Pause danach.
Dialogue.SCRIPT = {
	{ action = "knock", wait = 2 },
	{ speaker = "sarp", text = "Evening.", action = "lean", wait = 0.8 },
	{ speaker = "sarp", text = "You shouldn't stop here. Not on this road.", action = "tilt" },
	{
		choice = {
			{
				text = { solo = "I'm looking for the Wagners' house.", duo = "We're looking for the Wagners' house." },
				reply = {
					{ speaker = "sarp", text = "The Wagners...", wait = 1.2 },
					{ speaker = "sarp", text = "Yes. They told me you would come." },
					{ speaker = "sarp", text = "I'm Sarp. I live close to them.", reveal = true },
				},
			},
			{
				text = "Who are you?",
				reply = {
					{ speaker = "sarp", text = "Who am I?", action = "tilt", wait = 1 },
					{ speaker = "sarp", text = "My name is Sarp. I'm a neighbor of the Wagners.", reveal = true },
					{ speaker = "sarp", text = { solo = "I've been waiting for you.", duo = "I've been waiting for you two." } },
				},
			},
		},
	},
	{ speaker = "sarp", text = { solo = "You're the one from the campsite, aren't you?", duo = "You're the two from the campsite, aren't you?" } },
	{
		choice = {
			{
				text = "How do you know that?",
				reply = { { speaker = "sarp", text = "Small place. Word gets around." } },
			},
			{
				text = "...Yes.",
				reply = { { speaker = "sarp", text = "I know. I watched you pack up your tent this afternoon." } },
			},
		},
	},
	{ speaker = "sarp", text = "The house is just up that path. The beds are made. There's warm food.", action = "turnToPath" },
	{ speaker = "sarp", text = "Come. I'll take you.", action = "faceCar", wait = 0.5 },
	{
		choice = {
			{
				text = { solo = "I'll drive there myself.", duo = "We'll drive there ourselves." },
				reply = {
					{ speaker = "sarp", text = "There is no road to the house.", action = "stepBack", wait = 1.2 },
					{ speaker = "sarp", text = "But go ahead. I'll be waiting." },
				},
				ending = "drive",
			},
			{
				text = { solo = "...Okay. Show me the way.", duo = "...Okay. Show us the way." },
				reply = { { speaker = "sarp", text = "Good. Stay close. And don't look into the trees." } },
				ending = "follow",
			},
		},
	},
}

-- Die beiden Enden. `at` = Sekunden nach Beginn des Endes,
-- `arrive` = Sekunden nach der Ankunft am Haus. `finish` blendet aus.
Dialogue.ENDINGS = {
	-- Nicht folgen: weiterfahren, um die Kurve, die Einfahrt hoch. Sarp steht schon da.
	drive = {
		{
			at = 3,
			speaker = "narrator",
			text = {
				solo = "I drove on. In the mirror, he just stood there. Watching me go.",
				duo = "We drove on. In the mirror, he just stood there. Watching us go.",
			},
		},
		{ arrive = 1.5, speaker = "sarp", text = "You took the long way." },
		{
			arrive = 5,
			speaker = "narrator",
			text = {
				solo = "The house was dark. Not a single light. Nobody was waiting for me. Nobody but him.",
				duo = "The house was dark. Not a single light. Nobody was waiting for us. Nobody but him.",
			},
		},
		{ arrive = 12.5, finish = true },
	},
	-- Folgen: zu Fuß über den Waldweg bis zur Veranda, dort verschwindet Sarp.
	follow = {
		{ at = 4, speaker = "narrator", text = "He walked fast. He never once looked back." },
		{ at = 12, action = "crack" },
		{
			at = 13,
			speaker = "narrator",
			text = {
				solo = "Something moved between the trees. Something that kept pace with me.",
				duo = "Something moved between the trees. Something that kept pace with us.",
			},
		},
		{ arrive = 0.5, action = "faceGroup" },
		{ arrive = 1.2, speaker = "sarp", text = "This is where I leave you." },
		{ arrive = 4.5, speaker = "sarp", text = "Sleep well. And lock your door." },
		{ arrive = 8, action = "leave" },
		{
			arrive = 11,
			speaker = "narrator",
			text = {
				solo = "The house was dark. Not a single light. And I never heard him walk away.",
				duo = "The house was dark. Not a single light. And we never heard him walk away.",
			},
		},
		{ arrive = 18, finish = true },
	},
}

return Dialogue
