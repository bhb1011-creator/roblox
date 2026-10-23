# Horror-Spiel (Arbeitstitel: „Die letzte Nacht“)

Ein Roblox-Horrorspiel nach wahren Begebenheiten – allein oder zu zweit.

## Aktueller Stand: Lobby (erster Entwurf)

- **Ego-Perspektive** mit sichtbarem Körper, leichtem Kopfwippen und Punkt in der Bildmitte
- Großer Waldparkplatz im **Sonnenuntergang** (die Zeit bleibt stehen), weiße Flutlichtmasten, Gelände mit Gras und Waldboden
- Hohe, detaillierte Tannen, tote Bäume, Büsche, Felsen und umgestürzte Stämme
- Waldstraße mit Kurve, Leitpfosten und Warnschildern, die im Dunkeln verschwindet
- Großer begehbarer **Kiosk** mit Verkäufer (Shop öffnen per **E**), Regalen, Getränkekühlschränken, Snackautomat und Eistruhe
- **Grillplatz** in der Mitte: Feuerstelle mit Schwenkgrill, Bänke und Biertische zum Hinsetzen, gemauerter Grill, Zelte, Lichterketten
- Große Bestenliste, Pinnwand mit Vermisst-Zetteln am Rand
- Holzzaun, Pfützen, Risse im Asphalt, verlassener Wohnwagen, Getränkeautomat
- **4 Autos:** 2× „Allein“ (1 Platz) und 2× „Zu zweit“ (2 Plätze)
  - Einsteigen mit der Taste **E** (oder Antippen am Handy)
  - Ist das Auto voll, läuft ein Countdown von 10 Sekunden
  - Aussteigen mit dem Knopf **„Aussteigen“** oder der Leertaste – dann wird der Countdown abgebrochen
  - Danach fährt das Auto über die Straße in den Wald und der Bildschirm wird schwarz
- Infotafel und Bestenliste (Shop-Inhalt und Bestenliste sind noch Platzhalter)

Solange es das Horror-Level noch nicht gibt, fährt das Auto nur eine Proberunde
und man landet wieder am Lagerfeuer.

## Testen in Roblox Studio

1. Roblox Studio öffnen → neues Spiel mit der Vorlage **„Baseplate“**.
2. In VS Code diesen Ordner öffnen.
3. Rojo starten: im Terminal `rojo serve` (nutzt automatisch `default.project.json`).
4. In Studio: **Plugins → Rojo → Connect**.
5. Auf **Play** drücken.

Die Lobby wird erst beim **Play** per Code gebaut. Im Bearbeiten-Modus siehst du nur die
Skripte (z. B. ServerScriptService › Lobby) und die leere Baseplate – das ist normal.
Die Baseplate wird beim Start automatisch entfernt.

## Ordner

| Ordner | Landet in Studio in | Inhalt |
|---|---|---|
| `src/shared` | ReplicatedStorage › Shared | `Config.lua` – Einstellungen (Titel, Countdown, Autos …) |
| `src/lobby/server` | ServerScriptService › Lobby | Bauen der Lobby (Environment, Forest, Road, ParkingLot, Camp, Buildings, Car) und Autos (CarQueue) |
| `src/lobby/client` | StarterPlayerScripts › Lobby | Knöpfe, Hinweise, Shop-Fenster, Lichteffekte |

## Später, wenn das Level fertig ist

1. Im Roblox-Spiel einen zweiten Ort (Place) für das Level anlegen und dessen **PlaceId** in
   `Config.GAME_PLACE_ID` eintragen.
2. In den Spieleinstellungen der Lobby **max. 20 Spieler** einstellen.
3. Teleport funktioniert nur im veröffentlichten Spiel, nicht in Studio.
