# Sarp – Konzept

Sarp ist „der Fremde“ und die zentrale Figur des Spiels. Bild der Stufen:
`docs/konzept/der_fremde_stufen.png`.

## Wer er ist

- Er wirkt zuerst wie ein ganz normaler Mann aus der Gegend, ein „Nachbar der Wagners“.
- Man merkt aber sofort, dass etwas nicht stimmt: Er weiß zu viel (er hat euch beim
  Zeltabbauen beobachtet), er wartet schon auf euch, und er will euch unbedingt selbst
  zum Haus bringen.
- Er stellt sich erst im Gespräch vor. Bis dahin steht in den Untertiteln **„???“**,
  danach **„Sarp“**.
- In Wahrheit verwandelt er sich im Laufe der Geschichte in ein Monster. Das Biest im
  Wald ist seine letzte Gestalt.
- Der Spieler hat noch einen eigenen Plan dafür, wie Sarp und das Biest in der Story
  zusammenhängen. Nichts daran ändern, ohne vorher zu fragen.

## Die drei Stufen

| Stufe | Aussehen | Im Spiel |
|---|---|---|
| **1 · Anfang** | Ganz normaler Mann, um die 40: kurze dunkle Haare, olivgrüne Jacke, Jeans, Schlamm an den Schuhen, ein dunkler Fleck am Ärmel. Normales Gesicht, starrender Blick, leichtes Lächeln. Sein Schatten fällt falsch. | Kapitel 1: am Autofenster und auf dem Waldweg (`src/level/server/Stranger.lua`) |
| **2 · Verändert** | Verdrehter Hals, Schimmel, schwarzer Schleim, Fliegen, kaputte Jacke, Knochenfinger. | noch nicht gebaut |
| **3 · Übernatürlich** | Riesig (~16 Studs) und dürr, ovaler, langer Kopf mit einem Maul vom Scheitel bis zum Kinn voller Zähne, rot glühende Flecken und Adern, verfaulter Körper mit Fetzen der olivgrünen Jacke, Rippen, Knochenfinger, Knochensporne an den Schultern, rotes Glühen um den Kopf. | Kapitel 1: „das Biest“, das jagt, wer Sarp nicht folgt (`src/shared/Beast.lua`) |

## Verhalten in Kapitel 1

- Er kommt kurz vor dem Anhalten aus dem Wald und läuft langsam zum Beifahrerfenster.
- Er starrt etwa 5 Sekunden stumm herein, klopft dann ans Fenster, beugt sich vor und
  legt den Kopf schief.
- Gespräch mit 3 Antworten (wählt der Fahrer), danach zwei Enden:
  - **Nicht folgen:** „There is no road to the house. But go ahead. I'll be waiting.“
    Er schaut dem Auto nach und steht dann plötzlich im Scheinwerferlicht vor der Garage:
    „You took the long way.“ Dann geht er an der Garage vorbei in den Wald und löst sich
    auf. Die Spieler steigen aus und stehen vor der Haustür.
  - **Folgen:** Er geht gleichmäßig voraus, dreht sich nicht um und wartet nicht. Wer
    zurückbleibt, hört das Biest und wird gejagt. An der Veranda dreht er sich um:
    „This is where I leave you. Sleep well. And lock your door.“ Dann geht er in den
    Wald und löst sich auf.
- Alle Texte stehen in `src/shared/Dialogue.lua`.

## Stimme

- **Gewünscht:** mysteriös und gruselig, aber lebendig, mit Energie. Er soll nicht wie
  ein Erzähler oder Vorleser klingen, nicht müde oder flach. Man soll sich unwohl fühlen.
  Eine echte Person, mit der etwas nicht stimmt, ein Mensch, in dem das Monster
  durchschimmert.
- **Nicht** zu freundlich, **nicht** zu tief, **kein** Psycho-Stil. Den Psycho-Stil
  heben wir uns für später auf (z. B. Stufe 2).
- **ElevenLabs-Stimmenprompt** (der zuletzt passende):

  ```
  Real man in his 30s talking through a car window, not a narrator. Medium-high, slightly nasal voice, conversational and full of energy. Friendly one moment, tense the next. Something is wrong with him: rough edge, heavy breaths, small cracks and a faint strained growl underneath. Restless, unpredictable, unsettling. Raw, close to the mic.
  ```

- **Audio-Tags (Eleven v3):** gruselig und lebendig, aber kontrolliert, z. B.
  `[eagerly]`, `[sudden shift]`, `[cold]`, `[low voice]`, `[sinister whisper]`,
  `[quiet laugh]`, `[heavy breathing]`, `[ominous]`, `[eerie]`, `[curious]`.
  Wichtig: Tags, die die Lautstärke stark ändern (`[quietly]`, `[whispers]`), sparsam
  benutzen, weil der Unterschied sehr stark ist.
- **Satz 16** („You took the long way.“) klingt anders als am Fenster: Er steht draußen
  vor dem Auto, gedämpft wie durch die Windschutzscheibe, mit etwas Wald-Hall.
- **Aufnahmen:** 21 Dateien `sarp_01_evening` bis `sarp_19_sleep_well` (mit `_solo`/`_duo`
  bei 08 und 09). Roh in `assets/voice/raw`, bearbeitet (.ogg) in `assets/voice`.
  IDs in `Config.VOICE_LINES` (`src/shared/Config.lua`). Im Spiel kommt seine Stimme aus
  seiner Richtung (Kopf), mit leichtem Hall.

## Stand beim Leeren des Verlaufs (Nov 2026)

- Problem offen: Die eigenen Sprachaufnahmen (Sarp und Erzähler) laden in Studio nicht
  zuverlässig. Eingebaut: Vorladen, Ersatz durch die Roblox-Stimme, Meldung im Output und
  in Studio eine Prüf-Anzeige (Taste **J** = Liste mit Zustand, Taste **K** = alle
  nacheinander anhören). Der Spieler sollte einen Screenshot der Liste und die
  Output-Meldung schicken, damit die Ursache gefunden werden kann (Berechtigung,
  Roblox-Prüfung oder Abspiel-Code).
- Noch ohne IDs: 13 Umgebungsgeräusche, 5 Tiere, 4 Biest-Geräusche (siehe
  `Config.SOUNDS` und README).
- Nächstes großes Thema: Kapitel 2. Der Spieler erzählt die Geschichte, dann wird erst
  geplant und nach seiner Zustimmung gebaut.
