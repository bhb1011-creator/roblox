"""Schreibt die KI-erzeugten Kleidungsstücke/Accessoires als Rojo-Dateien (assets/shop/Kleidung).
Die IDs stammen vom Studio-Mesh-Generator (dauerhaft hochgeladene Assets, 11. November 2026)."""
import json, os

ITEMS = [
    # name, meshId, textureId, size (Studs), display scale
    ("Beanie", 117598350254985, 95078549611130, (0.722, 0.800, 0.786), 1.0),
    ("Cap", 114126935378497, 135307617619861, (0.672, 0.600, 0.998), 1.0),
    ("Scarf", 77556489909970, 115006412898732, (1.009, 1.600, 0.536), 1.0),
    ("Sunglasses", 127909022577928, 100518288117686, (0.931, 0.350, 0.785), 1.0),
    ("LeatherGloves", 97995723069332, 75078588012245, (0.277, 0.400, 0.176), 2.5),
    ("HikingBoots", 121540436531644, 84027630181093, (1.073, 1.000, 1.223), 1.0),
    ("Headlamp", 124193334722309, 83977617396610, (0.584, 0.500, 0.621), 1.0),
    ("Backpack", 96262128200282, 111276755351536, (1.156, 1.301, 0.900), 1.3),
    ("RainJacket", 106912071799840, 98861263621712, (2.200, 2.312, 1.004), 1.0),
    ("FlannelVest", 93791586893476, 113181535121534, (1.984, 2.166, 1.100), 1.0),
    ("LeatherJacket", 78091319304776, 96668215509541, (2.174, 2.094, 1.100), 1.0),
    ("DownJacket", 94424002930330, 83517070313017, (2.072, 2.400, 1.154), 1.0),
]

out = os.path.join(os.path.dirname(__file__), "..", "assets", "shop", "Kleidung")
for name, mesh, tex, size, scale in ITEMS:
    scaled = [round(v * scale, 3) for v in size]
    data = {
        "ClassName": "MeshPart",
        "Properties": {
            "MeshId": f"rbxassetid://{mesh}",
            "TextureID": f"rbxassetid://{tex}",
            "Size": {"Vector3": scaled},
            "InitialSize": {"Vector3": list(size)},
            "Anchored": True,
            "CanCollide": False,
            "CanTouch": False,
            "CanQuery": False,
        },
    }
    with open(os.path.join(out, name + ".model.json"), "w") as f:
        json.dump(data, f, indent=2)
print("ok", len(ITEMS))
