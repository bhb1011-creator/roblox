# Plan: Tod, Robux-Shop, Münzen, Snacks, Skins, Abfahrt aus der Lobby

Stand: 11. November 2026, Wünsche des Users (noch **nichts davon gebaut**). Alle Spieltexte auf Englisch,
Erklärungen für den User auf Deutsch. Preise sind Vorschläge – echte Preise legt der User im Creator Hub fest,
die Kasse soll sie per `MarketplaceService:GetProductInfo` holen statt fest im Code.

---

## 1. Herzen und Tod (Wunsch des Users)

- **Herzen auf 2 senken** (jetzt `MAX_HEARTS = 3` in `src/kapitel2/server/Kapitel2.lua`). Gilt in **allen Kapiteln**
  (bisher gibt es Herzen nur in Kapitel 2).
- **Gamepass „3 Hearts“**: wer ihn hat, hat immer 3 Herzen statt 2. Kaufbar in der Lobby. 249 R$.
- **Alle Herzen weg = Game Over.** Dann zwei Möglichkeiten:
  1. **Zurück in die Lobby** und von vorne starten (kostenlos).
  2. **Revive für 30 R$**: weiterspielen genau dort, wo man gestorben ist, mit vollen Herzen.
- **Für den Freund bezahlen (Duo):** Der gestorbene Spieler drückt „Ask friend“. Beim Freund geht ein Fenster auf:
  „<Name> died. Revive them for 30 R$?“ mit „Revive“ / „No“. Bezahlt der Freund, wird der Gestorbene wiederbelebt.
  (Technisch: gleiches Entwicklerprodukt; der Server merkt sich, für wen der Kauf ist, und belebt den Freund.)
- Solange der Gestorbene wartet, **schaut er seinem Partner zu** (Kamera folgt dem Partner).
- **Im Spiel kann man nur Herzen kaufen** (Revive, evtl. „+1 Heart“). Alles andere (Snacks, Gamepässe, Skins,
  Münzen) gibt es **nur in der Lobby**.
- Kaufen im Spiel braucht eigenen Kauf-Code (`ProcessReceipt`) im Spiel-Place, nicht nur in der Lobby.
- Wichtig: Die jetzigen Lobby-Produkte „Revive“ / „3× Revive“ / „Rebirth“ werden ersetzt. Rebirth fällt weg
  (versprach einen Bonus, den es nicht gibt). Gekaufte, aber nie benutzte Revives aus Tests: auf Revive-Guthaben
  umrechnen oder verfallen lassen – vor Veröffentlichung klären (bisher hat niemand echt gekauft, IDs sind 0).

**Offene Frage:** Soll ein Revive auch vorher in der Lobby kaufbar sein (Vorrat), oder nur im Moment des Todes?
User sagte „im Spiel nur Herzen“ → Vorschlag: Revive nur im Game-Over-Bildschirm.

---

## 2. Münzen (Entscheidung des Users, 11. November)

- Münzen gibt es **nur, wenn man das ganze Spiel schafft: 150 Münzen**. Keine Münzen pro Kapitel.
- **Münz-Boni** (z. B. ohne Herz-Verlust, Sammelstücke, täglicher Bonus) kommen **später** dazu – noch offen.
- **Gamepass „2× Coins“**: 149 R$ (für immer doppelte Münzen). „3× Coins“ ist gestrichen.
- **Coin Boost**: 50 R$ (Entwicklerprodukt) für doppelte Münzen auf Zeit. **Offene Frage:** wie lange
  (Vorschlag: 1 Stunde oder die nächste geschaffte Runde).
- **Münzpakete für Robux** (Entwicklerprodukte):

| Paket | Robux |
|---|---|
| 200 Münzen | 49 |
| 500 Münzen | 99 |
| 1500 Münzen | 249 |
| 5000 Münzen | 749 |

- Münzen werden im DataStore gespeichert (gleiches Universum → Lobby und Spiel teilen die Daten).

---

## 3. Snacks und Items (Lobby-Kiosk, für Münzen ODER Robux) – Auswahl des Users

Der User hat entschieden (11. November): **nur diese Items erstmal**. Man nimmt höchstens 3 pro Runde mit
(Inventar). Kauf nur in der Lobby. Die alten Kiosk-Snacks in `Config.SNACKS` (Chocolate, Energy drink,
Batteries, Chips) fallen weg.

| Item | Wirkung | Münzen | Robux |
|---|---|---|---|
| **Energy Bar** | 20 s lang 20 % schneller rennen | 40 | 10 |
| **Coffee** | 60 s lang Ausdauer beim Sprinten unendlich | 50 | 10 |
| **Mint Gum** | 60 s lang leise Schritte: Sarp hört dich nur halb so weit | 60 | 15 |
| **Gummy Bears** (teuer, Wunsch des Users) | 20 s lang zeigt ein Pfeil den Weg zum nächsten Ziel | 200 | 40 |
| **X-Ray Glasses** (teuer, Wunsch des Users) | 30 s lang sieht man **Sarp und alle anderen Feinde** (Familie, Biest …) durch Wände (roter Umriss, nur beim Benutzer) | 400 | 75 |

Jedes Item ist **einmal benutzbar** (Verbrauchsgegenstand). Die Brille ist etwas anderes als der
**Supervision-Pass** (§4): Supervision zeigt dauerhaft **Gegenstände**, die Brille zeigt kurz **Feinde**.

Ideen, die der User (noch) nicht gewählt hat: Calm Tea, Glucose Tablets, Energy Drink, Batteries, Crisp Packet
und die Liste in §6.

---

## 4. Gamepässe (einmal kaufen, für immer – nur Lobby)

| Gamepass | Wirkung | Vorschlag |
|---|---|---|
| **3 Hearts** | immer 3 statt 2 Herzen | 249 R$ |
| **Supervision** | Gegenstände zum Einsammeln leuchten durch Wände (Umriss), an/aus schaltbar | 499 R$ |
| **2× Coins** | doppelte Münzen für immer | 149 R$ |
| **Strong Flashlight** (Wunsch des Users) | Handy-Taschenlampe dauerhaft deutlich heller und weiter (z. B. Reichweite 44 → 70, breiterer Kegel) | 149 R$ |
| **VIP Car** | eigene Lackfarbe, eigener Radiosender, Hupe im Lobby-Auto | 199 R$ |
| **Flashlight Skins** | Farbe/Lichtkegel der Taschenlampe (nur Aussehen) | 49–99 R$ |

**Supervision** genauer: Sammelbare Gegenstände (Kerze, Chemikalien, Pulver, Schlüssel, Sammelstücke …) bekommen
ein `Highlight` (nur beim Käufer, auf dem Client). Vorschlag: Reichweite 60 Studs, damit Suchen noch Spaß macht.

---

## 5. Skins, Packs, Abzeichen, Sportwagen (Entscheidung des Users, 11. November)

### Packs (nur Robux, im Shop besonders schön präsentiert)

| Pack | Inhalt | Robux |
|---|---|---|
| **Golden Pack** | **Goldener Anzug für alle** Figuren (Spieler, Familie Wagner, Sarp – offene Frage, ob Sarp auch) + **Gold-Abzeichen** + **Sportwagen** | 999 |
| **Sarp VIP Pack** | **3 Skins für Sarp** + **Sarp-VIP-Abzeichen** + **Sportwagen** | 499 |
| **Everything Bundle** | Golden Pack + Sarp VIP Pack (+ Sportwagen) | 1249 |

- Die **Familie Wagner** hat nur diesen einen Extra-Skin (golden, im Golden Pack). Familien-Skins kann man **nicht
  einzeln** kaufen. Sonst sieht die Familie normal aus.
- **Sarp-Skins** gibt es nur im Sarp VIP Pack (3 Stück). Aussehen: User entscheidet noch; Vorschläge für den
  dritten Skin siehe Chat/§5a.

### Abzeichen (statt besonderer Name)

- Nur mit Robux erhältlich (über die Packs). Gold-Abzeichen (Golden Pack), Sarp-VIP-Abzeichen (Sarp VIP Pack).
- **Offen: wie anzeigen.** Ideen: Namensschild über dem Kopf in der Lobby (BillboardGui mit Symbol), Symbol vor
  dem Namen im Chat (TextChatService-Tag), auf der Bestenliste in der Lobby, Profil-Karte beim Anklicken.
- Hinweis: Das sind eigene Spiel-Abzeichen, nicht die Roblox-„Badges“ (die sind gratis Erfolge).

### Sportwagen (Lobby-Auto)

- Gratis dazu bei **Golden Pack** oder **Sarp VIP Pack**.
- Einzeln: **3000 Münzen** oder **399 R$**.

### Spielfigur

- **Silberner Anzug**: **2500 Münzen** oder **249 R$** (erster Skin des Spielers).
- **Goldener Anzug**: im Golden Pack.
- **Kleidung und Accessoires für Münzen** (sehen deutlich besser aus als das normale Outfit; Preise von Claude
  vorgeschlagen, User kann ändern):

| Teil | Münzen |
|---|---|
| Beanie (Mütze) | 300 |
| Basecap | 300 |
| Schal | 250 |
| Sonnenbrille / Brille (nur Aussehen) | 350 |
| Lederhandschuhe | 400 |
| Wanderschuhe | 450 |
| Rucksack | 600 |
| Gelbe Regenjacke | 900 |
| Lederjacke | 1200 |
| Daunenjacke (Winter) | 1200 |
| Holzfällerhemd + Weste (Camping) | 1000 |
| Stirnlampe (nur Aussehen) | 500 |

- Gratis-Belohnungen (Idee, noch nicht entschieden): „Survivor“-Look fürs Durchspielen.

### 5a. Ideen für Sarp-Skins (User wählt noch aus)

- **Gewählt: Shadow Sarp** – fast ganz schwarz wie ein Schatten, glühende Augen, dunkler Rauch steigt auf.
  **Separat** (nicht im Sarp VIP Pack): **399 R$ oder 3500 Münzen**.
- **Sarp VIP Pack (luxuriös, aber gruselig – gebaut als Entwurf am 11.11.):** „Gilded Horror“ (altes Gold, Dornenkrone
  mit Rubinen, schwere Goldkette, rotes Glimmen), „Crimson Count“ (blutroter Samtmantel, goldene Knöpfe und
  Epauletten, langer Umhang), „Obsidian King“ (Körper aus schwarzem Glas, hohe Goldkrone, Goldschultern, violette Aura).
  Kann der User noch ändern. Ideen fürs Internet-Recherche: Gold-Akzente/Goldüberzug + leere/rote Augen (z. B.
  „Golden Boy“-Skins, „Luxury Halloween Monsters“).
- Keine Story-Hintergründe aus dem DLC verraten.

### 5c. Starter Pack (nur einmal kaufbar)

- Inhalt (Vorschlag): 3× Energy Bar, 2× Coffee, 1× Mint Gum, 500 Münzen, 1 Beanie.
- Normalpreis 99 R$; **beim ersten Spielen rabattiert auf 50 R$** (Angebot erscheint beim ersten Besuch in der Lobby).

### 5d. Gratis-Automat (nur einmal)

- Beim ersten Besuch steht in der Lobby ein **Automat**: einmal ziehen = **ein gratis Accessoire/Kleidungsstück**.
  Danach verschwindet er für diesen Spieler für immer (im DataStore gespeichert).
- Enthält **alle** Kleidungsstücke und Accessoires, aber mit unterschiedlicher Chance (am Automaten angezeigt):
  - Häufig (60 %): Schal, Beanie, Basecap, Lederhandschuhe
  - Selten (30 %): Sonnenbrille, Wanderschuhe, Stirnlampe, Rucksack
  - Sehr selten (9 %): Gelbe Regenjacke, Holzfällerhemd + Weste
  - Legendär (1 %): Lederjacke, Daunenjacke
- Gratis = keine Lootbox-Probleme (die Regeln gelten für bezahlte Zufallsdinge).

### 5e. „Owned“ und Angebote

- Alles, was man besitzt, zeigt im Shop **„OWNED“** (bzw. „EQUIPPED“ im Style-Modus); Gamepässe werden nicht
  nochmal angeboten.
- **Münz-Angebote:** jeden Tag ein „Daily Deal“ – ein Kleidungsstück/Accessoire 30 % billiger (wechselt täglich).
- **Robux-Angebote:** z. B. Wochenend-Angebot „1500 Münzen + Coin Boost“ für 249 statt 299 R$; zeitlich begrenzte
  Sarp-Skins (z. B. Blood Moon an Halloween) für später.

### 5b. Style-Modus im Shop

- Im Shop gibt es einen **Style-Modus** (Umkleide): Man sieht seine Figur groß, dreht sie, sieht, was man gerade
  anhat, und kann Kleidung/Anzüge/Accessoires an- und ausziehen.
- Vorschlag: Dinge, die man noch nicht hat, kann man dort **anprobieren** (Vorschau), bevor man kauft.
- Auch Sarp/Familie/Sportwagen in der Vorschau zeigen (für die Packs).

---

## 6. Weitere Item-Ideen (Vorschläge, noch nicht vom User gewählt)

- **Throwing Stones** (5 Stück): werfen → Geräusch → Sarp geht hin.
- **Alarm Clock**: hinlegen, klingelt nach 10 s → lockt Sarp weg.
- **Glow Sticks**: auf den Boden legen, markieren den Weg (gut im Duo).
- **Chalk**: Pfeile an Wände malen (Duo-Absprache).
- **Walkie-Talkie** (Duo): zeigt, wo der Partner gerade ist.
- **Compass**: zeigt Richtung zum Ausgang/Ziel.
- **Camera Flash**: blendet Sarp 3 s (1× pro Runde, eher teuer).
- **Lucky Charm**: der erste Treffer einer Runde kostet kein Herz (stark → nur 1× pro Runde, teuer).
- **First Aid Kit** = +1 Herz – **nur im Spiel** kaufbar (passt zur Regel „im Spiel nur Herzen“).
- Kosmetik: Emotes in der Lobby, Hupen-Sounds, Namensfarbe/Titel, Spuren beim Laufen in der Lobby.

Nicht empfohlen: Kapitel überspringen gegen Robux, Zufalls-Kisten (strenge Roblox-Regeln, in manchen Ländern
verboten), „Sarp sieht dich nie“ (nimmt den Grusel).

---

## 7. Abfahrt aus der Lobby (Teleport)

- **Solo-Auto:** einsteigen → sofort **schwarzer Bildschirm** mit „Leaving in 3 … [Cancel]“. Nach 3 s Teleport
  ins Spiel. „Cancel“ = aussteigen, man steht wieder neben dem Auto.
- **Duo-Auto:**
  - Der Erste steigt ein → **20 s warten** (Countdown sichtbar, man sieht noch den Innenraum). Danach fährt das
    Auto auch mit nur einem Spieler los (dann wieder 3 s schwarzer Bildschirm mit Cancel).
  - Sitzen **zwei** im Auto → **sofort** schwarzer Bildschirm mit 3 s und Cancel, dann Teleport beider zusammen.
  - Steigt einer per Cancel aus, läuft für den anderen wieder der 20-s-Countdown.
- Teleport: beide in **denselben reservierten Server** (`TeleportService:ReserveServer` + `TeleportAsync`), Modus
  (Solo/Duo) und Gruppe als TeleportData. `Config.GAME_PLACE_ID` muss dafür gesetzt werden (jetzt 0).
- Jetzt im Code: `Config.COUNTDOWN_SECONDS = 10`, Logik in `src/lobby/server/CarQueue.lua` → wird umgebaut.

**Parkplatz rund um die Autos sperren:** Der Bereich der Parkbucht um jedes Auto wird abgesperrt (unsichtbare Wand
oder niedrige Schranke), damit niemand um/durch das Auto läuft; einsteigen nur über den Sitz/Prompt.
**Offene Frage an den User:** „damit man da drin sein kann“ – gemeint ist vermutlich: man soll im Auto sitzen
können, ohne dass andere drumherum stehen/stören. Vor dem Bauen nachfragen.

---

## 8. Lobby-Auto mit dem Innenraum aus Kapitel 1

- Die Lobby-Autos (`src/lobby/server/Car.lua`) bekommen den detaillierten Innenraum aus
  `src/level/server/CutsceneCar.lua` (gemeinsames Modul nach `src/shared`, damit beide dasselbe benutzen).
- **Leistung:** 4 Autos × ~420 Teile. Darum:
  - Innenraum-Lichter (mit Schatten) nur an, wenn jemand im Auto sitzt.
  - Kleine Teile ohne Schatten (ist schon so), Innenraum ggf. nur beim Spieler im/nahe am Auto voll anzeigen.
  - Mit Shift+F5 in der Lobby messen.

---

## 9. Reihenfolge (Vorschlag)

1. Herzen auf 2 + Game-Over-Bildschirm (Lobby / Revive 30 R$ / Freund bitten) + Zuschauen im Duo.
2. Münzen (verdienen, speichern) + Kiosk mit Snacks + Inventar-Slots.
3. Abfahrt neu (3 s / 20 s, schwarzer Bildschirm, Cancel) + Parkplatz sperren + Teleport mit reserviertem Server.
4. Lobby-Auto mit Innenraum.
5. Gamepässe (3 Hearts, Supervision, Coins) + Skins.

Für echte Käufe muss der User im Creator Hub die Produkte/Gamepässe anlegen und die IDs geben; bis dahin
Platzhalter (ID 0 = „Not set up yet“) und Test in Studio.
