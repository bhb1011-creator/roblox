"""Baut aus allen Sounds ohne ID (leere Plätze in Config.SOUNDS) fünf Sammeldateien.

Roblox erlaubt nur wenige Audio-Uploads. Darum liegen viele Sounds hintereinander in einer
Datei; das Spiel spielt per Sound.PlaybackRegion nur das passende Stück (SoundBank.lua).
Schleifen stehen dreimal hintereinander und das Spiel schleift im mittleren Stück – so bleibt
die Schleife nahtlos, auch wenn der MP3-Decoder den Anfang um ein paar Millisekunden verschiebt.

Aufruf:  python3 tools/make_sound_banks.py
Ergebnis: assets/audio/banks/sammel_1.mp3 … sammel_5.mp3 und src/shared/SoundPieces.lua
Braucht: ffmpeg (mit libmp3lame)
"""
import os, re, subprocess, wave

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
CONFIG = os.path.join(ROOT, "src", "shared", "Config.lua")
OUT_DIR = os.path.join(ROOT, "assets", "audio", "banks")
PIECES = os.path.join(ROOT, "src", "shared", "SoundPieces.lua")
SR = 44100
GAP = 0.6  # Stille zwischen den Stücken (Sekunden)

# Reihenfolge = Verteilung auf die Dateien (ungefähr nach Spielabschnitt)
BANKS = [
    ("Umgebung und Schritte", ["knock", "twig", "forestWind", "rustle", "treeCreak", "houseCreak", "swingCreak", "shutterRattle",
                               "radioVoices", "owl", "wolf", "raven", "foxScream", "heartbeat", "scaredBreath", "stepGravel",
                               "stepDirt", "stepWood"]),
    ("Kapitel 2: Nacht und Flucht", ["scream", "heavyKnock", "doorBurst", "sarpStep", "sarpBreath", "fuse", "explosion", "secretDoor",
                                     "neckCrack", "ritualSting", "clawSwipe", "clawHit", "bodyFall", "candleFall", "fireBurst",
                                     "puppetCollapse", "qteSuccess", "qteFail"]),
    ("Kapitel 3: Verfolgung", ["transformCrack", "runBreath", "bridgeCrack", "bridgeCollapse", "thunder", "treeCrash", "woodSplinter",
                               "stumble", "headHit", "jumpLand", "mudStep", "splash", "bushRustle"]),
    ("Kapitel 3: Hütte", ["cabinAmbience", "fireCrackle", "phoneKey", "phonePickup", "phoneRing", "phoneWrong", "phoneHangup",
                          "lightFlicker", "mirrorScare", "photoScare", "hallucinationFade"]),
    ("Kapitel 3: Ende", ["sirenFar", "policeKnock", "carDoor", "carEngine", "carDrive", "endingMusic"]),
]


def find_files():
    """Platz -> Datei (aus dem Kommentar hinter dem leeren Platz in Config.SOUNDS)"""
    text = open(CONFIG, encoding="utf-8").read()
    start = text.index("Config.SOUNDS = {")
    block = text[start: text.index("\n}", start)]
    files = {}
    for key, name in re.findall(r'^\t(\w+) = "", -- ([\w\.]+\.ogg)', block, re.M):
        files[key] = name
    have = {}
    for folder, _, names in os.walk(os.path.join(ROOT, "assets", "audio")):
        if "banks" in folder:
            continue
        for name in names:
            have.setdefault(name, os.path.join(folder, name))
    return {key: have.get(name) for key, name in files.items()}


def decode(path):
    """Datei -> rohe 16-Bit-Mono-Samples"""
    return subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "s16le", "-"],
                          capture_output=True, check=True).stdout


def main():
    files = find_files()
    planned = [key for _, keys in BANKS for key in keys]
    left = [key for key in files if key not in planned]
    if left:
        raise SystemExit("Diese leeren Plätze sind keiner Sammeldatei zugeordnet: " + ", ".join(left))
    os.makedirs(OUT_DIR, exist_ok=True)
    gap = b"\x00\x00" * int(GAP * SR)
    pieces = []
    for number, (title, keys) in enumerate(BANKS, 1):
        data = bytearray(gap)
        for key in keys:
            path = files.get(key)
            if not path:
                print(f"  fehlt: {key} (keine Datei)")
                continue
            raw = decode(path)
            length = len(raw) / 2 / SR
            loop = "_loop" in os.path.basename(path)
            if loop:
                start = len(data) / 2 / SR + length  # mittleres von drei Stücken
                data += raw * 3
            else:
                start = len(data) / 2 / SR
                data += raw
            data += gap
            pieces.append((key, number, start, length, loop))
        wav = os.path.join(OUT_DIR, f"sammel_{number}.wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(bytes(data))
        mp3 = os.path.join(OUT_DIR, f"sammel_{number}.mp3")
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", wav, "-c:a", "libmp3lame", "-b:a", "160k", mp3], check=True)
        os.remove(wav)
        size = os.path.getsize(mp3) / 1e6
        print(f"sammel_{number}.mp3  {len(data) / 2 / SR:6.1f} s  {size:4.1f} MB  ({title}, {len(keys)} Sounds)")

    lines = [
        "-- AUTOMATISCH ERZEUGT von tools/make_sound_banks.py – nicht von Hand ändern.",
        "-- Wo jeder Sound in den Sammeldateien liegt (Sekunden). Die IDs der hochgeladenen",
        "-- Sammeldateien stehen in Config.SOUND_BANKS (1 = sammel_1.mp3 usw.).",
        "return {",
    ]
    for key, number, start, length, loop in pieces:
        extra = ", loop = true" if loop else ""
        lines.append(f"\t{key} = {{ bank = {number}, start = {start:.4f}, length = {length:.4f}{extra} }},")
    lines.append("}")
    open(PIECES, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print(f"{len(pieces)} Sounds -> {os.path.relpath(PIECES, ROOT)}")


if __name__ == "__main__":
    main()
