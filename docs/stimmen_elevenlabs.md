# ElevenLabs-Stimmen (gesichert)

Automatisch gesichert von `tools/elevenlabs_voices.py stimmen`. Damit kann man die Stimmen
auf einem anderen Account nachbauen (Voice Design: Beschreibung einfügen).

## Spieler(Guesthouse
- voice_id: `8VtXgmiX3boSyZjQvsTX`
- Art: generated
- Merkmale: {"language": "en"}
- Einstellungen: {"stability": 0.5, "use_speaker_boost": true, "similarity_boost": 0.75, "style": 0.0, "speed": 1.0}
- Beschreibung:

```
Young adult in their early 20s, slightly bright voice. Telling a true story about a night they barely survived. Quiet, personal and tense, sometimes a little shaky, as if the memory still scares them. Natural and close to the mic, not a polished audiobook narrator.
```

## Sarp (Guesthouse)
- voice_id: `go0uLgQhb2vymcgvcYvx`
- Art: generated
- Merkmale: {"language": "en"}
- Einstellungen: {"stability": 0.5, "use_speaker_boost": true, "similarity_boost": 0.75, "style": 0.0, "speed": 1.0}
- Beschreibung:

```
Real man in his 40s talking face to face through a car window, not a narrator. Conversational, natural and full of energy, with sudden shifts: friendly and eager one moment, then tense and intense the next. Something is wrong with him: his voice is slightly unstable, with a rough gravelly edge, wet heavy breaths, small cracks and an occasional deep, strained growl underneath, as if something inside him is trying to break out. Restless and unpredictable, a bit too excited, unsettling and dangerou
```
(ElevenLabs schneidet die Beschreibung hier ab. Sinngemäß endet sie mit „…unsettling and dangerous.“)

## Für einen anderen Account
- Modell für die Sätze: **Eleven v3** (nur damit gehen die Emotions-Tags wie `[whispers]`).
- Stimme nachbauen: Voice Design → Beschreibung oben einfügen → Vorschau wählen, die am besten passt.
- Einstellungen wie oben (Stability 0.5 = „Natural“).
- Sarp als Monster (`sarp2_*`): dieselbe Sarp-Stimme, danach im Programm tiefer gesetzt
  (ffmpeg `asetrate=44100*0.88,aresample=44100,atempo=1.1364`).
- Alle Sätze mit Tags stehen in `tools/elevenlabs_voices.py` (SARP und ERZAEHLER).

