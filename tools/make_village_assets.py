"""
Lê tools/assets/village_ids.json (enviado pelo Studio depois da importação dos GLB do MegaKit)
e escreve src/shared/VillageAssets.lua com os IDs de malhas e texturas.

Uso (a partir da raiz do projeto):
    python tools/make_village_assets.py
"""
import json
import os

SRC = os.path.join("tools", "assets", "village_ids.json")
OUT = os.path.join("src", "shared", "VillageAssets.lua")


def num(value):
    text = ("%.5f" % value).rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def main():
    data = json.load(open(SRC, encoding="utf-8"))
    lines = [
        "--!strict",
        "-- IDs do Quaternius Medieval Village MegaKit (CC0, quaternius.com), importados como GLB separados por material.",
        "-- Gerado por tools/make_village_assets.py a partir de tools/assets/village_ids.json. Não edite à mão.",
        "-- Medidas em metros do kit: o jogo multiplica por Scale. O pivô de cada peça é o centro da base.",
        "export type Part = { material: string, mesh: string, size: Vector3, offset: CFrame }",
        "export type Texture = { color: string, normal: string, roughness: string, metalness: string }",
        "",
        "local VillageAssets = {}",
        "",
        "VillageAssets.Scale = 3",
        "",
        "VillageAssets.Textures = {",
    ]
    for name, t in sorted(data["textures"].items()):
        lines.append('    %s = { color = "%s", normal = "%s", roughness = "%s", metalness = "%s" },' % (name, t["c"], t["n"], t["r"], t["m"]))
    lines += ["} :: { [string]: Texture }", "", "VillageAssets.Pieces = {"]
    for name, parts in sorted(data["pieces"].items()):
        lines.append("    %s = {" % name)
        for p in parts:
            size = "Vector3.new(%s, %s, %s)" % tuple(num(x) for x in p["size"])
            cf = "CFrame.new(%s)" % ", ".join(num(x) for x in p["cf"])
            lines.append('        { material = "%s", mesh = "%s", size = %s, offset = %s },' % (p["m"], p["mesh"], size, cf))
        lines.append("    },")
    lines += ["} :: { [string]: { Part } }", "", "return VillageAssets", ""]
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("escrito", OUT, len(data["pieces"]), "peças,", len(data["textures"]), "texturas")


if __name__ == "__main__":
    main()
