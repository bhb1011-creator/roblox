# Plan: Tod, Robux-Shop, Münzen, Snacks, Skins, Abfahrt aus der Lobby

Stand: 11. November 2026, Wünsche des Users (noch **nichts davon gebaut**). Alle Spieltexte auf Englisch,
Erklärungen für den User auf Deutsch. Preise sind Vorschläge – echte Preise legt der User im Creator Hub fest,
die Kasse soll sie per `MarketplaceService:GetProductInfo` holen statt fest im Code.

---

## 1. Herzen und Tod (Wunsch des Users)

- **Herzen auf 2 senken** (jetzt `MAX_HEARTS = 3` in `src/kapitel2/server/Kapitel2.lua`). Gilt in **allen Kapiteln**
  (bisher gibt es Herzen nur in Kapitel 2).
- **Gamepass „3 Hearts“**: wer ihn hat, hat immer 3 Herzen statt 2. Kaufbar in der Lobby. Vorschlag: 149 R$.
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

## 2. Münzen

- Man **verdient Münzen langsam** durch Spielen, oder kauft einen **Münz-Multiplikator** mit Robux.
- Vorschlag Verdienst:
  - Kapitel 1 geschafft: 30 · Kapitel 2: 80 · Kapitel 3: 120
  - Kapitel ohne Herz-Verlust: +50 %
  - versteckte Sammelstücke in den Kapiteln (Fotos, Zeitungsausschnitte, Tagebuchseiten): je 10
  - täglicher Bonus beim ersten Spiel des Tages: 20
- **Münz-Multiplikator (Robux):**
  - Gamepass „2× Coins“ für immer: ca. 149 R$
  - Gamepass „3× Coins“ für immer: ca. 299 R$ (ersetzt 2×, nicht stapeln)
  - optional Entwicklerprodukt „Coin Boost 30 min, 2×“: ca. 25 R$
- Optional Münzpakete für Robux (100 / 500 / 1500 Münzen).
- Münzen werden im DataStore gespeichert (gleiches Universum → Lobby und Spiel teilen die Daten).

---

## 3. Snacks (Lobby-Kiosk, für Münzen ODER Robux)

Regeln: Man nimmt **höchstens 3 Snacks pro Runde** mit (Inventar). Wirkung nur, wo die Mechanik existiert.
Kauf nur in der Lobby. Der jetzige Snack „Chips“ (bringt nichts) wird ersetzt.

| Snack | Wirkung | Münzen | Robux |
|---|---|---|---|
| **Energy Bar** | 20 s lang 20 % schneller rennen | 40 | 10 |
| **Coffee** | 60 s lang Ausdauer beim Sprinten unendlich (Wald-Jagd Kapitel 1/3) | 50 | 10 |
| **Mint Gum** | 60 s lang leise Schritte: Sarp hört dich nur halb so weit | 60 | 15 |
| **Calm Tea** | im Versteck ruhiger Atem: Sarp findet dich **einmal** nicht im Versteck | 80 | 20 |
| **Glucose Tablets** | nächstes Quick-Time-Event: doppelt so viel Zeit | 50 | 10 |
| **Energy Drink** | 45 s lang Warnung (Herzschlag + Pfeil), wenn Sarp/Biest in der Nähe ist | 60 | 15 |
| **Gummy Bears** | 20 s lang zeigt ein Pfeil den Weg zum nächsten Ziel | 70 | 15 |
| **Batteries** | Handy-Taschenlampe ein ganzes Kapitel heller und weiter | 40 | 10 |
| **Crisp Packet** | werfen: knistert laut, Sarp läuft zum Geräusch (Ablenkung) | 60 | 15 |

---

## 4. Gamepässe (einmal kaufen, für immer – nur Lobby)

| Gamepass | Wirkung | Vorschlag |
|---|---|---|
| **3 Hearts** | immer 3 statt 2 Herzen | 149 R$ |
| **Supervision** | Gegenstände zum Einsammeln leuchten durch Wände (Umriss), an/aus schaltbar | 199 R$ |
| **2× Coins** (Wunsch des Users: auf jeden Fall) / optional **3× Coins** | Münz-Multiplikator | 149 / 299 R$ |
| **Strong Flashlight** (Wunsch des Users) | Handy-Taschenlampe dauerhaft deutlich heller und weiter (z. B. Reichweite 44 → 70, breiterer Kegel) | 149 R$ |
| **VIP Car** | eigene Lackfarbe, eigener Radiosender, Hupe im Lobby-Auto | 99 R$ |
| **Flashlight Skins** | Farbe/Lichtkegel der Taschenlampe (nur Aussehen) | 49–99 R$ |

**Supervision** genauer: Sammelbare Gegenstände (Kerze, Chemikalien, Pulver, Schlüssel, Sammelstücke …) bekommen
ein `Highlight` (nur beim Käufer, auf dem Client). Vorschlag: Reichweite 60 Studs, damit Suchen noch Spaß macht.

---

## 5. Skins für die Spielfigur in der Story

- Freischalten mit Münzen (dauert lange) oder durch Erfolge; ausgewählt in der Lobby, sichtbar in allen Kapiteln.
- Ideen:
  - **Rain Jacket** (gelbe Regenjacke) – 500 Münzen
  - **Camping Outfit** (Fleece, Rucksack) – 800 Münzen
  - **Night Hiker** (Stirnlampe, dunkle Jacke) – 1200 Münzen
  - **Winter Coat** – 1500 Münzen
  - **Survivor** (zerrissene, schmutzige Kleidung) – gratis, wenn man das Spiel einmal durchgespielt hat
  - **Golden Flashlight** – gratis, wenn man alle Sammelstücke gefunden hat
  - **Ohne-Tod-Abzeichen / Titel in der Lobby** („Untouched“) – gratis, Kapitel ohne Herz-Verlust

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
