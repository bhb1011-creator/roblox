#!/usr/bin/env python3
"""Schreibt assets/natur/Tannen.model.json: echte Tannen-Modelle (MeshParts) für den Wald.

Die Formen stammen aus dem kostenlosen Creator-Store-Paket "Ponderosa Pine Tree Pack"
von Letaij (Asset 130515502281374). Hier stehen nur die Asset-Nummern und Maße; Rojo
baut daraus ReplicatedStorage.Natur.Tannen (siehe default.project.json).
Die Teile stehen mit dem Fuß des Stamms auf dem Ursprung (0, 0, 0).

Aufruf:  python3 tools/make_tree_models.py
"""
import json
import os

ORIENT = {
    "A": [[0.413, 0.911, 0], [0, 0, 1], [0.911, -0.413, 0]],
    "B": [[0.911, -0.413, 0], [0, 0, 1], [-0.413, -0.911, 0]],
    "C": [[-0.911, 0.413, 0], [0, 0, 1], [0.413, 0.911, 0]],
}
BARK = {  # ColorMap, NormalMap
    1: (139378529098819, 103170239355186),
    2: (78447927211856, 115307559967937),
    3: (84377568721955, 103405406141678),
    4: (93374260049097, 76864255573638),
    5: (93102187834720, 77118385805433),
}
NEEDLES = (122385008811017, 76300230289957)

# orient, Stamm: (mesh, size, initialSize, y, Rinde), Nadeln: (mesh, size, initialSize, position)
TREES = [
    ("A", (107431480752613, (7.839, 7.853, 23.789), None, 11.895, 1),
          (90116814867758, (8.725, 8.676, 22.109), None, (-0.211, 13.441, 0.225))),
    ("A", (74030110324292, (5.758, 5.739, 23.789), None, 11.895, 1),
          (135974560430452, (8.666, 8.693, 22.921), None, (0.234, 13.035, -0.255))),
    ("B", (87765311815033, (5.539, 3.588, 23.789), None, 11.895, 2),
          (98416655622270, (8.925, 9.114, 22.918), None, (-0.696, 13.037, -0.142))),
    ("A", (116882934598454, (9.294, 9.43, 26.021), (8.49, 8.615, 23.771), 13.011, 3),
          (98796039687733, (10.621, 10.141, 25.624), (9.703, 9.264, 23.408), (0.118, 13.97, 0.092))),
    ("B", (76178437725298, (6.096, 6.585, 25.434), (5.701, 6.16, 23.789), 12.717, 4),
          (74592415499646, (7.861, 7.898, 25.303), (7.352, 7.388, 23.667), (-0.072, 13.538, 0.352))),
    ("A", (110402428240877, (6.265, 6.195, 26.027), (5.723, 5.659, 23.776), 13.013, 3),
          (84353089448531, (8.335, 8.934, 25.687), (7.614, 8.162, 23.466), (0, 13.945, -0.414))),
    ("A", (81200861466286, (4.648, 4.663, 26.041), (4.246, 4.26, 23.789), 13.02, 3),
          (107129739355437, (6.505, 6.406, 26.309), (5.943, 5.852, 24.034), (-0.07, 13.66, 0.05))),
    ("C", (127163432661708, (1.784, 1.705, 22.996), (1.447, 1.383, 18.652), 11.498, 5),
          (138559907629675, (8.675, 8.801, 21.046), (7.036, 7.138, 17.07), (0.121, 13.082, 0.201))),
]


def asset(number):
    return "rbxassetid://%d" % number


def mesh_part(name, mesh, size, initial, position, orient, maps, alpha, shadow):
    return {
        "Name": name,
        "ClassName": "MeshPart",
        "Properties": {
            "MeshId": asset(mesh),
            "Size": {"Vector3": [float(v) for v in size]},
            "InitialSize": {"Vector3": [float(v) for v in (initial or size)]},
            "CFrame": {"CFrame": {"position": [float(v) for v in position], "orientation": [[float(v) for v in row] for row in ORIENT[orient]]}},
            "Anchored": True,
            "CanCollide": False,
            "CanTouch": False,
            "CanQuery": False,
            "DoubleSided": True,
            "CastShadow": shadow,
        },
        "Children": [
            {
                "Name": "SurfaceAppearance",
                "ClassName": "SurfaceAppearance",
                "Properties": {"ColorMap": asset(maps[0]), "NormalMap": asset(maps[1]), "AlphaMode": alpha},
            }
        ],
    }


def main():
    children = []
    for index, (orient, trunk, needles) in enumerate(TREES, 1):
        t_mesh, t_size, t_init, t_y, bark = trunk
        n_mesh, n_size, n_init, n_pos = needles
        children.append(
            {
                "Name": "Tanne%d" % index,
                "ClassName": "Model",
                "Children": [
                    mesh_part("Trunk", t_mesh, t_size, t_init, (0, t_y, 0), orient, BARK[bark], "Overlay", True),
                    mesh_part("Needles", n_mesh, n_size, n_init, n_pos, orient, NEEDLES, "Transparency", False),
                ],
            }
        )
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "natur")
    os.makedirs(root, exist_ok=True)
    path = os.path.join(root, "Tannen.model.json")
    with open(path, "w", encoding="utf-8") as handle:
        json.dump({"ClassName": "Folder", "Children": children}, handle, indent=1)
        handle.write("\n")
    print("geschrieben:", os.path.normpath(path), "-", len(children), "Tannen")


if __name__ == "__main__":
    main()
