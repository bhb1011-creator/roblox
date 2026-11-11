# Handoff – Horror-Spiel „Guesthouse“ (Roblox)

Stand: 10. November 2026, Branch `claude/optimistic-bardeen-4tmohk`, Version `K2-2026-11-11e`.
Ganz oben stehen die neuesten Abschnitte (0000 = 10. Nov., 000 = realistische Familie, 00 = 9. Nov., 0 = Kapitel 3 + Audio);
Abschnitte 2–8 beschreiben Kapitel 2 (Stand 6. Nov.).
Diese Datei ist für einen **neuen Chat** gedacht: erst den Prompt unten kopieren, der Rest ist Nachschlagewerk.

---

## 1. Prompt zum Einfügen in den neuen Chat

```text
Ich arbeite mit dir an meinem Roblox-Horrorspiel „Guesthouse“ (im Code auch „Die letzte Nacht“,
Fears-to-Fathom-Stil, allein oder zu zweit, gebaut mit Rojo). Das Spiel ist auf Englisch.
Ich bin Anfänger und nutze einen Mac – erkläre bitte alles in einfachem Deutsch, in kurzen Schritten.

Das Projekt liegt bei mir in `~/Documents/roblox-neu` (GitHub: bhb1011-creator/roblox).
Lies zuerst `handoff.md` im Repo (Stand, Dateien, Regeln, offene Punkte), danach
`docs/konzept/wagners.md` (Geschichte Kapitel 2).

Regeln:
- Arbeite NUR auf dem Branch `claude/optimistic-bardeen-4tmohk`, committe und pushe dort.
  Kein Pull Request, außer ich verlange ihn.
- Schick mir KEINE Screenshots, Bilder oder Dateien, außer ich verlange es.
- Zähle bei jeder Änderung `Config.BUILD` in `src/shared/Config.lua` hoch und nenne mir
  danach Version + Commit-Hash.
- Den ElevenLabs-Wasserzeichen-Ton NICHT entfernen.
- Keine DLC-Hintergrundgeschichte erzählen (Sarp wurde von der Familie erschaffen,
  Richard stand lange auf ihrer Seite – das kommt erst im DLC).
- Ich teste selbst: in `~/Documents/roblox-neu` `git pull`, dann
  `~/Downloads/rojo serve spiel.project.json --port 34872`, in Studio „Connect“ und „Play“.
  (Nur `rojo serve` ohne Datei startet die Lobby – das ist falsch.)
- Sei ehrlich: sag klar, was ungetestet ist.
  Arbeite gründlich und sag, wenn etwas fertig ist.

Stand: Version `K2-2026-11-11e`. Kapitel 1, 2 und 3 sind gebaut und laufen am Stück (`spiel.project.json`).
Alle Figuren sind realistische KI-Figuren: Familie Wagner (`assets/figuren`), Sarp in allen drei Stufen
(Fremder, Monster im Haus, Biest; `assets/sarp`) und feste Spielerfiguren (`assets/spieler`; in der Lobby
wird man beim Einsteigen ins Auto zur Figur). Im Testmenü (Taste O) gibt es eine „Charakterliste“.
Familie: Mund und Kopf bewegen sich beim Sprechen, natürlicher Blick, weiche Laufwege, detaillierte Kerze.
Animationen aller Figuren in Studio geprüft (10f). Offen: im echten Spielablauf testen (Kapitel-1-Szene mit Sarp,
Jagd im Haus, Biest-Jagd in Kapitel 3, Lobby, Duo). Danach Audio (ab 24. November kann ich wieder Sounds
hochladen; bis dahin viele kurze Sounds zu Sammeldateien zusammenfassen, im Spiel per `Sound.PlaybackRegion`).
Roblox Studio ist per MCP verbunden – du kannst Studio direkt steuern und testen.
Fang damit an, dass du die Dateien liest und mir in 5 Sätzen sagst, wo wir stehen.
```

---

## 00000000. NEU 11. November (Version K2-2026-11-11a): Echte Tannen in allen Kapiteln, dichterer Wald

- `ReplicatedStorage.Natur` jetzt in **allen** Projektdateien (`spiel`, `kapitel2`, `level`, `default`) → echte Tannen überall.
- **Dichter:** `Forest.treeFactor()` = 1,8, wenn echte Tannen da sind (sonst 1). Kapitel 1 (Straße + Waldweg), Kapitel 3
  (Fluchtweg: 5 statt 3 Baumreihen, enger; Hütte: 468 statt 260 Bäume) und die Lobby streuen damit mehr Bäume.
- **Leistung:** Durchsichtige Nadeln kosten Grafikkarte, wenn hunderte Bäume im offenen Blick sind. Gemessen in Studio
  (Mac, Grafikzeit pro Bild): Kapitel 3 alt 14,2/11,2 ms → neu 13,6/14,2 ms, 60 FPS (ok). Kapitel 1 mit überall echten
  Tannen: 41 FPS (alt 60) – darum stehen **weit entfernte Bäume** (Kapitel 1: 55–170 Studs von der Straße, Lobby: der
  Außenbereich) als einfache Klotz-Tannen (`Forest.builders.blockPine`, undurchsichtig, im Nebel kaum zu sehen).
  **Nach dieser Änderung ist Kapitel 1 nicht neu gemessen** (Studio drosselt auf 15 FPS, wenn das Fenster nicht vorne ist).
- **11b:** Lobby noch dichter: `LOBBY_EXTRA = 1,5` in `Forest.lua` (Tannen rund um den Parkplatz und an der Zufahrt:
  190→513 und 130→351 statt 342/234). Nicht in Studio getestet (weder Aussehen noch Bildrate).
- **11c (Lobby):** Dichter Waldring direkt hinter dem Zaun (`ring` in `Forest.build`, 468 echte Tannen 28–44 Studs + 260 Büsche):
  man sieht nicht mehr in die Ferne. **Berge:** `Environment.buildMountains` stellt 26 Berge in zwei Reihen (950–1650 Studs)
  rund um den Parkplatz – Vorlage `assets/natur/Berg.model.json` (kostenloses Creator-Store-Modell „Meshes/Mountain“,
  Asset 3121332379, MeshPart mit Textur). Schild „GRILLPLATZ“ → „CAMPFIRE“. In Studio angesehen (sieht gut aus);
  Bildrate nicht gemessen (Studio drosselt im Hintergrund auf 15 FPS).
- **11d (Lobby):** 420 große einfache Büsche (`buildBush(..., scale)` 1,4–2,2) im Band 15–90 Studs hinter dem Zaun:
  man sieht unter den Ästen nicht mehr durch. In Studio angesehen.
- **11e (Kapitel 1 + Auto):** Wald an der Straße wie in der Lobby: echte Tannen 300→380 (×1,8), dahinter 520 große
  Büsche (26–75 Studs) und 180 große Büsche am Waldweg, ferne Blocktannen 480→620 (×1,8). Keine Berge in Kapitel 1
  (der Nachtnebel verschluckt alles ab ~300 Studs, man würde sie nicht sehen). **Auto innen neu** (`CutsceneCar.lua`,
  außen gleich): Leder-/Stoffsitze mit Wangen, Nähten und runden Kopfstützen, Armaturenbrett mit Lederauflage,
  Holzleiste, Ambientelicht, Chrom-Lüftungsdüsen, Tacho mit echter Skala (Nadel dreht sich jetzt um die Uhrmitte),
  Infodisplay, Touchscreen-Radio, Klimabedienung, Lenkrad mit 32 Segmenten, Tasten und Airbag, Lenkstockhebel,
  Zündschlüssel, Türverkleidungen (Holz, Lautsprecher, Fensterschalter, Fächer mit Flasche/Karte), Dachkonsole,
  Sonnenblenden, Haltegriffe, Hutablage, Kaffeebecher, Parkschein, Duftbaum. Lenkrad sitzt etwas tiefer (3,92), damit
  man den Tacho darüber sieht. Radio heißt jetzt „PINE RADIO“. Fahrerblick in Studio angesehen (Testbau);
  Beifahrer-/Rückbank-Ansicht und Wald nicht angesehen, Bildrate nicht gemessen.
- Teile: Kapitel 1 22.838 → ~13.000, Kapitel 3 18.147 → ~13.000.
- Messen: in Studio beim Spielen **Shift+F5** (Bildrate) – unter 60 FPS am Straßenrand in Kapitel 1 → `Forest.MESH_DENSITY`
  in `src/shared/Forest.lua` senken (z. B. 1,4).

## 0000000. NEU 10. November (Version K2-2026-11-10i): Grafik-Probe Lobby (echte Tannen) + Lobby auf Englisch

- **Echte Tannen in der Lobby:** 8 Tannen-Modelle (MeshParts mit SurfaceAppearance) aus dem kostenlosen Creator-Store-Paket
  „Ponderosa Pine Tree Pack“ von Letaij (Asset 130515502281374). Datei: `assets/natur/Tannen.model.json`, erzeugt von
  `tools/make_tree_models.py` (dort stehen Asset-Nummern und Maße). Rojo → `ReplicatedStorage.Natur.Tannen`
  (**nur in `default.project.json`** eingebunden).
- `src/shared/Forest.lua`: `buildPine`/`buildSimplePine` nehmen die echten Tannen, wenn `ReplicatedStorage.Natur.Tannen` da ist
  (`buildMeshPine`), sonst die alten Klotz-Tannen. Kapitel 1–3 sind unverändert, solange ihre Projektdateien `Natur` nicht
  einbinden. Zum Umstellen: `"Natur": { "$path": "assets/natur" }` unter `ReplicatedStorage` in `spiel.project.json` /
  `kapitel2.project.json` / `level.project.json` eintragen (noch nicht gemacht, nicht getestet).
- Wald der Lobby: 13.688 → 3.425 Teile. In Studio geprüft (gebaute Datei, Play): Tannen stehen, keine Fehler.
  **Nicht gemessen:** Bildrate (FPS), vor allem auf Handys – die Nadeln sind durchsichtige Texturen.
- **Was nicht geht:** `SurfaceAppearance.ColorMap` lässt sich im laufenden Spiel nicht per Skript setzen – solche Modelle
  müssen als Datei (model.json/rbxm) über Rojo kommen. Die KI-Erzeugung (`generate_mesh`) taugt nicht für Bäume
  (Ergebnis: Comic-Klotzbaum); für Bäume den Creator Store nehmen.
- **Lobby-Texte Englisch:** Schilder, Kiosk/Kasse (jetzt „CHECKOUT“), Bestenliste („LEADERBOARD“), Auto-Anzeigen, Shop-Texte
  in `Config.lua` (`SOLO`/`DUO`, Revive, Snacks). `Config.GAME_TITLE` ist weiter „Die letzte Nacht“.
- Studio-Hinweis: Ist das Studio-Fenster minimiert, liefert `screen_capture` nur ein schwarzes Bild.

## 000000. NEU 10. November (Version K2-2026-11-10h): Spieltexte auf Englisch

- Alle Texte, die Spieler sehen (Hinweise, Aufgaben, Knöpfe, Tür-/Gegenstands-Beschriftungen, Kapitelkarten,
  Game Over, Inventar, Quick-Time-Events), sind jetzt Englisch – Kapitel 1, 2 und 3. **Neue Texte bitte gleich
  auf Englisch schreiben.** Untertitel stehen in englischen Anführungszeichen (“ ”).
- **Absichtlich Deutsch geblieben:** Testmenü (Taste O), Audio-Prüfung (Taste J), Meldungen im Output, interne
  Namen (Räume, Verstecke `name = "Schrank"` usw. – das sind Schlüssel im Code) und der Spieltitel `Config.GAME_TITLE = "Die letzte Nacht"` (steht auch auf der ENDE-Karte in Kapitel 3).
- In Studio geprüft: Texte in Kapitel 1 (Fahrt, Auswahl) und Kapitel 3 (Hütte). **Nicht geprüft:** jeder einzelne
  Hinweis in Kapitel 2 im Spiel, und ob „SPACE“ in den runden Quick-Time-Knopf passt (vorher „LEER“).

## 00000. NEU 10. November (Version K2-2026-11-10g): Prüfung in Studio, Leistung Kapitel 3

- Claude hat jetzt Zugriff auf Roblox Studio (MCP) und hat alle drei Kapitel im laufenden Spiel angesehen.
- **Leistung:** Beginnt Kapitel 3, wird die alte Welt (`workspace.Level1`: Straße, Wald, Haus) nach `ServerStorage`
  gelegt (`storeOldWorld` in `src/kapitel2/server/Kapitel3.lua`). Vorher ~44.000 Teile gleichzeitig, jetzt ~18.000.
  In Studio getestet mit den Teststarts „kapitel3“ und „huette“ (keine Fehler). **Nicht getestet:** der normale Weg
  durch die Tür hinter dem Regal und ein Durchlauf zu zweit.
- Übrige erzeugte Figur aus dem Workspace von Place1 nach `ServerStorage.KI_Spieler_Originale` verschoben
  (`Gen_Spieler1_Rest_aus_Workspace`). Der Studio-Ort muss dafür gespeichert werden.
- **Offen (gefunden, nicht behoben):**
  - Sprachaufnahmen `erzaehler_21`, `erzaehler_22`, `sarp_07_my_name` laden nicht („Asset is not approved“).
  - Meldung `rbxassetid://203785492 … Asset type does not match` beim Start: kommt weder im Code noch im Ort vor
    (vermutlich Studio/Plugin, nicht das Spiel).
  - Grafik: Die Welt besteht nur aus Klötzen (keine MeshParts außer den Figuren). Plan: Möbel/Bäume/Auto als
    erzeugte Modelle, eigene Oberflächen – Wohnzimmer als Probe.

## 0000. NEU 10. November (Version K2-2026-11-10f)

- **Animationen für die KI-Figuren geprüft und angepasst:**
  - Spielerfiguren: normale Roblox-Animationen (Animate-Skript) laufen, Arme hängen beim Stehen, schwingen beim Laufen.
  - Sarp1 (Kapitel 1): Gehanimation jetzt `913402848` (die alte `507777826` bewegt die Arme nicht, sie blieben
    abgespreizt). Kopf-Neigen am Autofenster geht jetzt auch bei der KI-Figur (über den Halsanker, `Cutscene.client.lua`).
  - Sarp2 (Haus, `Night.lua` → `sarpWalk`, auch für die Patrouille in `Escape.lua`): Gang mit Hüfte, Knien, pendelnden
    Armen und Ellbogen, Schritt passt zum Tempo (3,2 Studs pro Doppelschritt).
  - Biest: `Beast.pose` passt zu den neuen Gelenken (in Studio gemessen und angeschaut).

### Version K2-2026-11-10e

- **Sarp als KI-Figuren** (`assets/sarp`, Rojo → `ReplicatedStorage.Sarp`): `Sarp1` (der Fremde, Kapitel 1, `Stranger.lua`,
  behält Roblox-Gelenke für die Zwischensequenz-Animationen), `Sarp2` (das Monster im Haus, `SarpStage2.lua`, Motor6D,
  Fliegen, Glühen, verdrehter Hals), `Biest` (Kapitel 3/Kapitel 1, `Beast.lua`: 15,5 Studs, Gelenke unter den alten Namen,
  unsichtbare `Root` 0,5 über den Füßen, `Beast.HEAD` wird gesetzt, Maul über FaceControls). Gemeinsames Vorbereiten:
  `src/shared/RealFigure.lua`. Fehlt eine Datei → alte gebaute Figur.
- **Charakterliste** (Testmenü, `charaktere`): alle 9 Figuren mit Namensschild, Kamera fährt durch (`Figuren.runList`).
- **Lobby:** beim Einsteigen ins Auto wird man zur Spielerfigur (Fahrersitz = 1, sonst 2), beim Aussteigen wieder eigener
  Avatar (`CarQueue.lua`, `default.project.json` hat jetzt `ReplicatedStorage.Spieler`).
- **Wichtig:** Kommen neue .rbxm-Figuren dazu, während Rojo verbunden ist, fehlt ihnen die Form (MeshId) – einmal
  Disconnect/Connect, dann ist alles da.
- `Wagners.fromStudio`: Gegenstände in der Hand werden immer in der Welt angebracht (sonst sitzen sie schief).
- Kleid beim Laufen geprüft (Mrs. Wagner, Lucy): nichts sticht durch.
- In Studio getestet: Sarp2 und Biest mit echtem Code (Größe, Gelenke, Laufpose), Charakterliste im Play-Modus.
  Nicht getestet: Sarp1 in der echten Kapitel-1-Zwischensequenz, Biest-Jagd in Kapitel 3, Lobby-Einsteigen.

### Version K2-2026-11-10c

- **Feste Spielfiguren** statt eigenem Avatar: `assets/spieler/Spieler1.rbxm` (Fahrer: junger Mann, dunkelblaue Jeansjacke – seit 10e, vorher olivgrün wie Sarp) und
  `Spieler2.rbxm` (Beifahrerin: junge Frau, grauer Hoodie), KI-erzeugt, 5,6 bzw. 5,3 Studs. Rojo → `ReplicatedStorage.Spieler`
  (spiel, kapitel2, level). `src/shared/PlayerFigure.lua`: `load(player)` tauscht kurz `StarterPlayer.StarterCharacter`
  und ruft `LoadCharacter` (benutzt in `ForestWalk.spawnWalker`, `Figuren.lua`); `template(player)` für die Auto-Puppen in
  Kapitel 1 (`Main.server.lua` buildPuppet). Zuordnung: Attribut `Figur` (Beifahrer = 2, sonst nach Reihenfolge).
  Fehlt der Ordner → eigener Avatar wie früher.
- In Studio getestet: Figur lädt als Spielfigur, läuft mit Laufanimation (Beine schwingen, normales Tempo).
  Nicht getestet: im echten Spielablauf (Ich-Sicht, Auto-Puppe in Kapitel 1, Duo).
- Originale liegen in der neuen Studio-Baseplate unter ServerStorage.KI_Spieler_Originale (nur in dieser Sitzung, nicht gespeichert).

### Version K2-2026-11-10a

- **Blick natürlicher** (`Scene.lua` updateNecks): Ziel wird von der Körpermitte aus gemessen, Oberkörper (Waist)
  dreht 35 % mit (max. 35°), Kopf den Rest (max. 60°), Neigung max. 25°, ruhigeres Nachziehen. Bei „puppet“ (Kapitel 3)
  werden Hals und Taille einmal gerade gestellt.
- **Richard zeigt zur Treppe** (`actions.point` in `Kapitel2.lua`): Arm auf der Treppenseite, weich gehoben (Tween),
  wirklich in Treppenrichtung, nach ~4 s wieder runter.
- **Laufwege** (`walkPath` in `Kapitel2.lua`, gilt für alle Szenen über `ctx.walkPath`): Ecken als Bögen (max. 1,6 Studs),
  allmähliches Drehen, weiches Anlaufen/Abbremsen, Schritte nach Strecke, Knie beugen sich.
- **Kerze** neu und detailliert: `src/shared/CandleModel.lua` (Messingteller mit Rand und Fingerring, Tülle, Wachstropfen,
  Docht mit Glut, Flamme aus Hülle/Kern/blauem Fuß). Benutzt für die Kerze im eigenen Bild (`Scene.lua`), an der Spielerhand
  (`giveCandle`) und bei Mrs. Wagner (`holdCandle`). Die Flamme im eigenen Bild züngelt.
- **Nicht in Studio getestet** (Studio war nicht verbunden): alles aus diesem Abschnitt.
- Handy: kein sichtbares Handy, nur Handylicht (Taste F schaltet Kerze + Handylicht).

## 000. NEU: Realistische Familie (Version K2-2026-11-09j)

- **09i/09j:** Sprechen sichtbar: `Speech.onSay` (Speech.lua) meldet jeden Satz; `Scene.lua` (updateNecks) lässt den Kopf
  des Sprechers im Satzrhythmus nicken/neigen und bewegt den Mund (FaceControls `JawDrop`, `Left/RightLowerLipDepressor`).
  Die KI-Köpfe haben FaceControls, die das Gesicht direkt im Modell bewegen (ohne Gesichtsknochen) – Neu-Erzeugen war
  nicht nötig. Stimmen-Emitter für Lucy/Tommy waren falsch zugeordnet (behoben).

- **09h:** Lucy neu erzeugt (altes Nachthemd hatte fleckige beige-rosa Textur). Alte Version in Place1 unter
  ServerStorage.KI_Figuren_Originale.Gen_Lucy_alt_fleckig.

- **09g:** Figuren-Dateien verschlankt (ohne Kleidungs-Käfige/WrapTarget, Metall-Texturen, InitialPoses, Ragdoll-Teile;
  ~200 statt ~550 KB je Figur). Sie liegen jetzt in **ReplicatedStorage.Wagners** (nicht mehr ServerStorage), damit
  `src/kapitel2/client/FigurenVorladen.client.lua` sie schon beim Spielstart (während Kapitel 1) vorladen kann.
  Meldungen „Asset content representation is being generated“ = Roblox verarbeitet frisch hochgeladene Dateien noch;
  verschwinden von selbst. Originale (ungekürzt) liegen in Place1 unter ServerStorage.KI_Figuren_Originale.


- Mrs. Wagner, Mr. Wagner, Lucy und Tommy sind jetzt **KI-Avatare** (Roblox `generate_avatar` über das Studio-MCP),
  gespeichert als `assets/figuren/*.rbxm`. Rojo legt sie nach `ServerStorage.Wagners` (in `spiel.project.json`
  und `kapitel2.project.json`). `Wagners.build*` nimmt automatisch diese Figuren, sonst die alten Klotz-Figuren.
- `Wagners.fromStudio`: Größe angleichen (`FIGURE_HEIGHT`), Gelenke (AnimationConstraint an Knochen) → Motor6D,
  Rig-Attachments umbenannt (sonst löst der Humanoid Hals/Schultern), Arme aus der T-Haltung nach unten (`relaxArms`),
  Kerze/Puppe/Bild erst nach dem Einsetzen in die Welt anbringen.
- `FigurenMeshes.lua`: Modell-IDs aller Körperteile. Falls Rojo beim Live-Sync die MeshId nicht setzen darf,
  baut `repairMeshes` die Teile per `AssetService:CreateMeshPartAsync` neu.
- In Studio getestet (per MCP, Edit-Modus): Laden, Größe, Gelenke, Sitzen, Gegenstände in der Hand, Reparatur ohne MeshIds.
  **Nicht getestet:** echter Rojo-Live-Sync der .rbxm-Dateien und das Spiel im Play-Modus.
- Sarp ist noch die alte Figur (kommt als Nächstes).

## 00. NEU am 9. November (Version K2-2026-11-09e)

- **Ganzes Spiel am Stück:** `spiel.project.json` (beim User auf Port 34872). Kapitel 1 → 2 → 3 ohne Neustart.
  Kapitel 2 wartet auf das Ende von Kapitel 1 (`Cutscene.Finished`), räumt Kapitel 1 weg und startet.
- **Testmenü (nur Studio, Taste O, Knopf unten links):** `src/spiel/` + `src/shared/TestStarts.lua`. Startpunkte:
  Kapitel 1, Haustür, nach dem Verstecken, Flucht, Schlüssel, Ritual, Hütte, **Figuren ansehen** (Familie auf einer Bühne,
  Kamera fährt von Figur zu Figur; N = nächste, B = frei). `Config.TEST_AUTOSTART` = sofort dort starten (ohne Menü).
- **Inventarleiste** unten in der Mitte: `src/shared/Inventory.lua` (Kerze, Axt, Chemikalien, Pulver, Schlüssel, Handy).
- **Stimmung/Leistung:** `src/shared/Mood.lua` (Vignette, Schatten nur für die nächsten 8 Lichter, schaltet selten um),
  `Parts.optimize` (kleine Teile ohne Schatten, kein CanTouch), neues Licht in `World.lua` (kühler, Nebel sichtbar).
- **Figuren:** echte Katalog-Haare (`HAIR` in `Wagners.lua`, Sarp in `Stranger.lua`), Fallback = alte Klötze.
  Mrs. Wagner und Lucy: rote Mundwinkel, **bodenlanges Kleid/Nachthemd** (`longDress`), Beine schwingen nicht (`StepScale` 0),
  untere Stufen werden beim Sitzen/Knien ausgeblendet (`DressLower`).
- In Studio getestet (vom Claude-Agenten per Bildschirmsteuerung): Kapitel 1 (Ende „weiterfahren“) und Übergang zu Kapitel 2
  ohne Skriptfehler; Figuren-Ansicht. **Nicht** getestet: Laufen, Klopfen und alles danach (Tastatur ging nicht, Bildschirm gesperrt).

## 0. NEU seit 6. November: Kapitel 3 und Audio

### Wichtige Änderungen gegenüber unten
- Rojo liegt beim User jetzt in `~/Downloads/rojo`, Projektordner `~/Documents/roblox-neu`.
- Regeln: keine Screenshots/Dateien schicken; `Config.BUILD` bei jeder Änderung hochzählen;
  Sounds sind jetzt dran (die alte Regel „Audio ganz am Ende“ ist erledigt).
- Kapitel 2 ist fertig und geht nahtlos in Kapitel 3 über.
- `Config.TEST_START_KAPITEL2 = ""` (Anfang Kapitel 2) (weitere: `""`, `"nachVerstecken"`, `"tuer1"`, `"huette"` = direkt bei der Hütte).

### Änderungen 9. November (K2-2026-11-09a)
- Verfolgung: dichtere Atmosphäre (`brighten(true, "chase")`), zwei Nebel-Emitter ziehen mit dem Spieler mit, mehr Bodennebel am Weg (`ForestDressing.lua`).
- Ritual: Familie dreht die Köpfe nicht mehr (kein `rig.stare` mehr gesetzt), Köpfe bleiben gesenkt.
- Hütte: umgekippter Stuhl neu gebaut (lag schief halb im Boden), liegt jetzt flach auf der Lehne.
- Ab 24. November kann der User wieder Sounds hochladen; Sammeldateien bis dahin vorbereiten.

### Kapitel 3 – Ablauf
1. Karte „KAPITEL 3“, Ritual im Ritualraum (Familie flüstert im Chor, Kamerafahrt, Familie schaut auf einen Punkt, nicht in die Kamera).
2. Quick-Time-Events (dodge/struggle/timing, bewusst leicht), Partner wird ggf. getötet, Flucht.
3. Sarp verwandelt sich ins Biest → Verfolgung durch den Wald (`Data.OBSTACLES`): über Stämme springen (Leertaste),
   unter Stämmen rutschen (C), Schlamm/Bach bremsen, Biest rammt einen Baum, Hinterhalt aus dem Gebüsch (A/D),
   Atem im Nacken, Blitz/Donner, rotes Leuchten wirft den Schatten nach vorn. Biest bleibt sichtbar, aber mit Abstand (MAX_GAP 22).
4. Hängebrücke über eine Felsschlucht; das Biest stürzt in der Mitte ab.
5. Kurve → **Sarps Hütte** an einer Schotterstraße (`SarpHut.lua`, sehr detailliert, Tür auf/zu, dunkel).
6. Altes Telefon, Zettel „EMERGENCY 911“, Tasten in der Welt anklicken → Polizei-Anruf.
7. Optionale Halluzinations-Jumpscares am **Spiegel** und am **Foto**; mindestens einer muss gesehen werden, bevor das Bett geht.
8. Bett → „Etwas später …“, Blaulicht, Klopfen, Polizeiauto fährt weg, „ENDE“.

### Kapitel-3-Dateien
| Datei | Zweck |
|---|---|
| `src/kapitel2/server/Kapitel3.lua` | Server: Ablauf, Wald/Weg/Schlucht/Terrain, Brücke, Hütte, Telefon, Bett, Ende, Teststart `huette` |
| `src/kapitel2/client/Kapitel3.lua` (~4000 Z.) | Client: Kamera, Rig-Animationen, QTE, Verfolgung + Hindernisse, Telefon-UI, Jumpscares, Polizeiauto, Ende |
| `src/kapitel2/server/SarpHut.lua` | Die Hütte + Hof |
| `src/kapitel2/server/ForestDressing.lua` | Farne, Pilze, Steine, Nebel usw. am Weg |
| `src/shared/Kapitel3Data.lua` | Gemeinsame Werte (Weg, Hindernisse, QTE-Zeiten, Ende-Zeitplan) |
| `src/shared/Kapitel2Dialogue.lua` | Texte, auch `KAPITEL3` (Polizei-Anruf usw.) |
| `tools/make_kapitel3_audio.py` | Erzeugt die selbstgemachten Kapitel-3-Sounds nach `assets/audio/kapitel3` (numpy + ffmpeg) |

**Nichts davon wurde in echtem Studio getestet** – nur Syntax-Prüfung und eigene Mock-Tests.

### Audio – Stand 8. November
- IDs stehen in `Config.SOUNDS` (leer = Sound fällt weg). Listen von IDs = mehrere Ebenen gleichzeitig (Flüster-Chor).
- Sprachdateien Sarp (01–19) und Erzähler (01–29) sind hochgeladen und eingetragen (`Config.VOICE_LINES`).
  Die Kapitel-3-Sätze (`k3_*`, Polizei-Anruf usw.) haben noch **keine** Aufnahmen.
- Aus `assets/audio/kapitel3` (55 Dateien) ist **noch nichts hochgeladen**. Einige Slots nutzen Toolbox-IDs vom User.
- Aus `assets/audio` fehlen noch: knock, twig_snap, house_creak, forest_wind_loop, leaves_rustle, tree_creak,
  swing_creak_loop, shutter_rattle_loop, radio_voices, owl_hoot, wolf_howl, raven_caw, fox_scream,
  heartbeat_loop, scared_breath_loop, step_gravel, step_dirt, step_wood.
- **Upload-Grenze:** Uploads klappen gerade nicht („Hochladen fehlgeschlagen“). Der User hat sich mit Ausweis verifiziert.
  Erster Upload war am 24. Okt. Löschen gibt keinen Platz zurück.
- **Geplante Lösung (noch nicht gebaut):** viele kurze Sounds zu wenigen **Sammeldateien** zusammenschneiden und im Spiel
  per `Sound.PlaybackRegion` nur das passende Stück abspielen. Schleifen (Feuer, Sirene …) bleiben einzelne Dateien.
  Alternative: Sounds aus der Studio-Toolbox (ohne Schloss = öffentlich) – zählen nicht zur Grenze.

---

## 2. Ziel des Projekts

- Roblox-Horrorspiel „Die letzte Nacht“ (Arbeitstitel), Fears-to-Fathom-Stil, **Solo oder Duo**.
- Gebaut mit **Rojo** (Code in `src/`), Teile sind getrennt testbar:
  - Lobby: `default.project.json` (`rojo serve`)
  - Kapitel 1 „Die Fahrt“: `level.project.json` (Port 34873)
  - Kapitel 2 „Die Wagners“: `kapitel2.project.json` (Port 34872 beim User, README nennt 34874)
  - Am Ende sollen Lobby und Kapitel zusammengeführt werden (noch nicht gemacht).
- Der User ist Anfänger auf dem Mac, testet mit `~/Desktop/rojo serve kapitel2.project.json --port 34872`, dann in Studio **Connect** und **Play**.

### Geschichte (vom User festgelegt)
- Sarp ist ein Dämon, die Familie Wagner ist besessen. Anfangs wirkt Sarp böse, später stellt sich
  heraus, dass die Wagners böse sind. Am Ende muss man fliehen.
- **Für den DLC (NICHT in Kapitel 2 erzählen):** Sarp wurde von der Familie erschaffen. Richard war
  die ganze Zeit auf ihrer Seite, erkennt jetzt, dass es nicht mehr gut ist, und lässt die Spieler gehen.
- Kapitel 2 endet, wenn man aus dem Haus ausbricht (nur die Spieler selbst; über den Ritualraum).

### Regeln und Vorlieben des Users
- Nur auf Branch `claude/optimistic-bardeen-4tmohk` entwickeln und pushen. **Kein PR**, außer verlangt.
- Commits enden mit den Attribution-Zeilen, die die Umgebung vorgibt (`Co-Authored-By …` und
  `Claude-Session: https://claude.ai/code/session_01GviBXdi7ntk81fPhdjJLgL`). Keine Modell-IDs in Commit-Texten außerhalb dieser Zeilen.
- **Vorschau-Bilder nur auf Wunsch** (Ausnahme: Baupläne hat er ausdrücklich verlangt).
- **Audio kommt ganz am Ende**, erst Gameplay. Die Sound-Slots in `src/shared/Config.lua` (`Config.SOUNDS`) sind leer, Dateien liegen in `assets/audio`, ein paar Stimmen in `assets/voice`.
- Den ElevenLabs-Wasserzeichen-Ton soll ich **nicht** entfernen (wurde abgelehnt).
- Antworten auf Deutsch, einfach, mit konkreten Testschritten.

---

## 3. Status (was fertig und eingebaut ist)

### Kapitel 2 – Ablauf
1. **Ankunft:** Klopfen, Mrs. Wagner (Kerze), Mr. Wagner, Hereinbitten, Haus erkunden, Kerzen, Schlafen gehen (03:17).
2. **Erste Nacht** (`Night.lua`): Mrs. weckt euch, Abendessen (Familie sitzt am Tisch, Kinder Lucy und Tommy), Klopfen, Familie flieht, **Verstecken** (22 s; Schrank, Tisch, Vorhang), Sarp (zweite Gestalt) sucht, Jumpscare bei Fund, bis zu 5 Runden.
3. **Axt:** Richard schickt einen in den Keller; die Axt liegt jede Nacht an einem von **6 Plätzen** im Keller (Server-Output: `[Kapitel2] Die Axt liegt: …`). Damit **Tür 1** aufbrechen (jetzt: die Tür zu **Großmutters Zimmer** im langen Flur oben).
4. Währenddessen läuft Sarp patrouillierend, verfolgt (sieht Spieler mit Licht, 26 Studs), Schaden 25 / Treffer; F = Licht aus, dann sieht er einen nicht.
5. **Die Flucht** (`Escape.lua`, startet, wenn jemand Großmutters Zimmer betritt):
   - Richard am Pult erklärt (ohne Spoiler), jeder bekommt eine **rote Kerze**, keine Taschenlampe mehr.
   - Suchen: **Chemikalien** und **Schießpulver**, je 2 Stück an 2 von 6 möglichen Plätzen (auf Tischen/Kisten); nimmt man eins, verschwindet das andere. Zu zweit trägt jeder nur eins. Liste oben links.
   - **Sarp ist die Hauptgefahr:** läuft durchs ganze Haus (EG, Keller, langer Flur oben), bemerkt rotes Licht (26), im Dunkeln 12, schleichend 8, hört, wer nicht schleicht (16). Großmutters Zimmer ist sicher.
   - **Familie** (Mrs., Lucy, Tommy) taucht seltener auf (erst nach 45 s, dann alle 40–65 s), packt einen → **Quick-Time-Event** (10× tippen in 4 s: E, Leertaste oder Knopf). Misslingt es: −1 Herz. Packt sie einen, kommt Sarp zu dieser Stelle.
   - Am Pult ablegen → zusammenbauen → Ladung an den Safe → **Richard geht vorher raus** → Lunte mit der Kerze anzünden → 5 s verstecken → **Explosion** (Safetür fliegt weg, Kerzen weg, Sarp rennt hoch, läuft nur einmal durch das Zimmer).
   - Danach **11 rote Kerzen** als Weg, Schlüssel aus dem Safe, **Schleichen (C)**, Sarp tödlich im EG.
   - Schlüssel öffnet das **Regal vor dem Geheimgang** (Vorratskeller) → **Ritualraum** → Bild sofort schwarz („Der Ritualraum … Fortsetzung folgt“).
6. **Herzen:** 3 pro Spieler für das ganze Kapitel (Attribut `Hearts`, oben rechts ♥♥♥). −1 bei Sarp-Treffer/Gefundenwerden, Familie-Griff, Explosion ohne Versteck, Sterben. Bei 0: **Game Over** (Knopf „Nochmal versuchen“ → wieder 3 Herzen).
7. **Verstecke** überall im Haus (Schränke in Gästezimmer, langem Flur, Salon, Wohnzimmer, Waschkeller + Esszimmer + drei in Großmutters Zimmer). Raus: **E / Leertaste / Knopf „[E] Rauskommen“** (Remote `LeaveHide`). Versteckt man sich vor Sarps Augen, schaut er dort nach.

### Tasten
E = Aktion/Verstecken/Rauskommen/QTE, F = Kerze/Licht an/aus, C = Schleichen (nur Flucht), Leertaste = QTE/Rauskommen.

### Teststart
`Config.TEST_START_KAPITEL2` in `src/shared/Config.lua` – **steht gerade auf `"tuer1"`** (man erscheint direkt in Großmutters Zimmer bei Richard).
- `""` = normaler Start vor der Haustür
- `"nachVerstecken"` = direkt nach dem Verstecken im Esszimmer (Richard, Axt)
- `"tuer1"` = Flucht

### Wichtig: Nichts davon wurde in echtem Roblox Studio getestet
Alles lief nur in meiner Mock-Testumgebung (siehe Abschnitt 7). Der User testet gerade.

---

## 4. Aktive / wichtige Dateien

| Datei | Zweck |
|---|---|
| `src/kapitel2/server/Kapitel2.lua` (~1100 Zeilen) | Start, Remotes (`SceneEvent`, `SceneChoice`, `Light`, `Sneak`, `LeaveHide`, `Qte`, `Restart`), Spawn, Kerze (normal/rot/none), Herzen/Game Over, Türen, Betten, Szenen; Teststart |
| `src/kapitel2/server/Night.lua` (~1350) | Erste Nacht: Aufwachen, Essen, Verstecken, Axt, Tür 1 aufbrechen, Patrouille, Familie-Erscheinungen; ruft am Ende `Escape.run` |
| `src/kapitel2/server/Escape.lua` (~1320) | Die Flucht: Items, Pult/Safe/Bombe, Explosion, Sarp-Jagd/Suche, Familie + QTE, Kerzenweg, Schlüssel, Regal, Ritualraum |
| `src/kapitel2/server/Mansion.lua` (~1730) | Das Haus (Räume, Wände, Türen, Möbel), `Mansion.point`, `Mansion.escape` (Safe, Pult, Verstecke, Fundorte, Wege), `Mansion.axeSpots`, `Mansion.hideSpots` |
| `src/kapitel2/server/Furniture.lua`, `HouseInterior.lua` | Möbel (Bett, Schrank, Versteck-Schrank, Pult …), Treppe/Halle/Kerzen |
| `src/kapitel2/server/Wagners.lua` | NPCs (Mrs., Mr., Lucy, Tommy), Sitzen/Aufstehen, Laufen |
| `src/kapitel2/server/SarpStage2.lua` | Sarps zweite Gestalt (Modell + Kopfdrehung) |
| `src/kapitel2/client/Scene.lua` (~1240) | Anzeige: Kerze/Licht, Herzen, Game Over, QTE, Aufgabenliste, Schleichen, Jumpscare, Nachrichten vom Server |
| `src/shared/Kapitel2Dialogue.lua` | Alle Texte (Englisch gesprochen): Szenen, `NIGHT_*`, `ESCAPE_INTRO`, `ESCAPE`, `FAMILY_ANGRY`, `SARP_*` |
| `src/shared/Config.lua` | Sounds (leer), Stimmen, `TEST_START_KAPITEL2` |
| `src/level/server/House.lua`, `World.lua`, `ForestWalk.lua` | Von Kapitel 1 mitgenutzt (Hof, Welt, Spawn); `House.lua` hat ein Loch im Hof über der Kellertreppe |
| `docs/konzept/wagners.md` | Konzept: Geschichte, Nacht, Flucht, Balance |
| `docs/konzept/hausplan_flucht.png` | Bauplan: Fundorte (C = Chemikalien, P = Pulver), Verstecke (V), Kerzenweg, Großmutters Zimmer |
| `docs/konzept/hausplan_keller_axt.png`, `hausplan_nacht.png` | Axt-Plätze, Verstecke im Esszimmer |

Koordinaten im Haus: `Mansion.point(x, y, höhe)` mit Plan-Koordinaten; Stockwerke `Mansion.FLOORS` = `K` (-8.3), `E` (1.712), `O` (11.6).

---

## 5. Änderungen in dieser Session (grob chronologisch)

- Frühere Phasen (Kurzfassung): Haus gebaut und mehrfach auf Überlagerungen geprüft, Treppe neu (steiler, Platz vor der ersten Stufe), Kellergeländer, Türen/Betten/Schlafen, NPC-Figuren (wieder „blockig wie die Kinder“), Fehlerausgabe auf dem Ladebildschirm, Konversation robuster.
- **Erste Nacht** gebaut: Wecken, Essen, Klopfen, Verstecken (Schrank/Tisch/Vorhang), Sarp Stufe 2, Jumpscares, Axt, Tür 1 → schwarz.
- Sarp als Patrouille mit lauten Schritten, Verfolgung + Schaden, F = Licht aus, Familie erscheint komisch.
- Kerzenlicht heller, Teststart `"nachVerstecken"`.
- Familie sitzt richtig am Tisch (`Wagners.sit/stand`).
- **Überlagerungen** behoben: Rasenplatte schwebte in der Kellertreppe (`House.lua` Loch), schwebende Fußleiste, Betten/Schrank/Badewanne in Wänden, Tapete-Probleme, flackernde Flächen (26 → 1).
- **Axt** an 6 zufälligen Kellerplätzen; Bauplan dazu.
- **Familie** erscheint nur an geprüften freien Stellen, blendet ein/aus, dreht sich mit.
- **Flucht** komplett gebaut (`Escape.lua`), neue Texte, rote Kerzen, Schleichen (C), Bauplan `hausplan_flucht`.
- Teststart `"tuer1"` direkt in den Raum.
- **Raumtausch:** Tür 1 = Großmutters großes Zimmer (rot/gedämpft beleuchtet, Pult, Safe unter dem Bild, 3 Verstecke), kleines Galerie-Zimmer = abgeschlossene Kammer.
- Sarp = Hauptgefahr (ganzes Haus), Familie mit **QTE**, Verstecke per Taste verlassen.
- **Herzen/Game Over**, Familie seltener + Sarp kommt zur Griff-Stelle, Verstecke im ganzen Haus, Richard geht vor der Explosion, 2× jedes Item auf Möbeln, weniger Kerzen, sichtbarer E-Knopf.
- `/session-start-hook` wurde angefangen (Rojo und Luau als mögliche Abhängigkeiten geprüft), aber **vom User abgebrochen – es existiert kein Hook**.

---

## 6. Fehler, die passiert sind (und wie sie gelöst wurden)

Echte Roblox-Fehler (vom User gemeldet):
- `Tile` ist kein Material → `CeramicTiles`. Die Mock-Umgebung prüft Enums jetzt gegen `api.json`.
- „Infinite yield … Kapitel2“ → Remotes werden zuerst angelegt, Bau in `xpcall`, Status auf dem Ladebildschirm.
- TTS **FilteredText**: „You'll meet them tomorrow“ wurde gefiltert → umformuliert („You'll see them at breakfast“). **Risiko:** auch „black powder“ könnte gefiltert werden.
- Treppe: User meldete mehrfach „nicht behoben“; echte Ursache: kein Platz vor der ersten Stufe → neues Design (steiler, ab z -10.6, Rampe).
- Kellergeländer ragte in die Küche; Hügel-Terrain im Keller; schwebende Möbel/Bilder vor Fenstern → per Analyse-Skripten behoben.
- NPC-Look: „zu rund/natürlich“ → zurück zum früheren blockigen Stil.

Fehler in meinem Code / Tests:
- `if not completed or handleCatch()` kurzgeschlossen → `handleCatch()` vorher aufrufen.
- Endlosschleifen in der Mock-Umgebung (synchrones `task.spawn`) → `STOP_AT`.
- Sarp jagte trotz Licht aus → Dunkle Spieler werden nie erkannt.
- Neu in dieser Session: `enterEscape` war beim Aufruf noch `nil` (Wartschleife eingebaut); Schlüssel-Prompt war zu früh aktiv; Sarp-Rundgang wählte Punkte auf falschem Stockwerk (jetzt `nearestOnFloor`); Game-Over wurde durch „retry“-Nachricht überschrieben (jetzt `restart = true`); fehlendes `MaxHealth` im Mock.
- Teststart `"tuer1"` setzte erst in die Halle → jetzt direkt im Raum.

Bekannte Einschränkungen der Mock-Tests: `PivotTo` auf Modellen, `Humanoid.MoveDirection`, Raycasts und Pathfinding sind nicht echt.

---

## 7. Test- und Hilfswerkzeuge (WICHTIG: gehen mit der Sitzung verloren)

Die Werkzeuge lagen nur im Scratchpad dieser Sitzung (`/tmp/claude-0/…/scratchpad`) und sind im neuen Chat **weg**:
- `luau` / `luau-analyze` / `luau-compile` (aus `https://github.com/luau-lang/luau/releases/latest/download/luau-ubuntu.zip`)
- `rojo` (Linux-Binary, `https://github.com/rojo-rbx/rojo/releases/download/v7.4.4/rojo-7.4.4-linux-x86_64.zip`; `rokit.toml` nennt 7.7.1)
- `preview/` mit Mock-Roblox-API (`mock4–6.luau`), `build.py` (setzt Module + Test-Ende zusammen), Analyse-Skripte (`zfight`, `floating`, `checks`, `pierce`), `mansion.html` (three.js-Renderer), `plan_escape.py` (Bauplan → PNG)
- `api.json` (Roblox-API-Dump für Enum-Prüfung)

Was im neuen Chat ohne den Mock noch geht:
- Syntax prüfen: `luau-compile --null datei.lua`, `luau-analyze datei.lua`
- Bauen: `rojo build kapitel2.project.json -o k2.rbxl`
- Alles Spielerische nur noch **in Studio** testen (User) oder einen neuen Mock schreiben.
- Die Baupläne (`docs/konzept/*.html/png`) liegen im Repo; die Generator-Skripte (`plan_*.py`) nicht.

---

## 8. Nächste Schritte

- **Später: Grafik-Auswahl „Hoch / Niedrig“** (Wunsch des Users, 11. November). Spieler wählen im Menü: Hoch = dichter Wald
  mit echten Tannen wie jetzt, Niedrig = weniger Tannen (nur auf diesem Gerät ausblenden, z. B. per
  `LocalTransparencyModifier`) für schwache Handys. Die Bäume baut der Server – die Auswahl muss also auf dem Client wirken.

1. **User-Rückmeldung aus dem Studio-Test abwarten** und Fehler beheben. Besonders prüfen:
   - Laufen NPCs/Sarp mit `PathfindingService` sinnvoll (Türen, Treppen, nicht durch Wände)?
   - Funktioniert `Humanoid.MoveDirection` auf dem Server für „Sarp hört einen“?
   - Safe-Tür fliegt weg (Welds/Velocity), Rauch, Explosion sichtbar?
   - ProximityPrompts (Verstecke, Items, Pult, Safe, Regal), QTE, Herzen/Game Over, Sneak-Knopf.
   - Balance: Sarps Tempo (3.4 Patrouille, 7.2 Jagd), Familie-Häufigkeit, Sichtweiten.
   - TTS-Filter für neue Sätze.
2. **Fortsetzung** nach dem Ritualraum (User will das als Nächstes, Ideen vorher erfragen): mutierter Sarp, Ende von Kapitel 2 (nur Spieler brechen aus, Story-Wahrheit bleibt für DLC).
3. Später / offen:
   - **Audio** füllen (Slots in `Config.SOUNDS`, u. a. neu: `fuse`, `explosion`, `sarpRoar`, `scream`, `heavyKnock`, `doorBurst`, `sarpStep`, `sarpBreath`, `jumpscare`), ElevenLabs-Stimmen.
   - Herzen auch über **Kapitel 1 und Lobby** speichern (jetzt nur Kapitel 2, Attribut `Hearts`).
   - Lobby und Kapitel zusammenführen.
   - `Config.TEST_START_KAPITEL2` wieder auf `""` setzen, wenn Testphase vorbei ist.
   - `sarp_07` (offen aus früherer Planung).
   - Optional: SessionStart-Hook (`.claude/hooks/session-start.sh`) für Rojo/Luau – war angefangen, wurde abgebrochen.
