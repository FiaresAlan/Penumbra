"""
Converte peças do Quaternius Medieval Village MegaKit (CC0) para o Roblox.

Problema: o importador do Roblox só aproveita UMA textura por malha (as outras materiais ficam vazios).
Solução: cada peça é separada em uma malha por material (um nó por material), sem texturas, e as
texturas são enviadas uma única vez por um "portador" (um GLB com um triângulo por material).
Depois o jogo aplica a SurfaceAppearance certa por nome do material (MI_Plaster, MI_WoodTrim etc.).

Uso (a partir da raiz do projeto):
    python tools/convert_megakit.py

Entrada: tools/assets/quaternius-village/zip/megakit-standard.zip (não vai para o Git)
Saída:   tools/assets/quaternius-village/glb/<peça>.glb e glb/_texturas.glb
"""
import io
import json
import os
import struct
import zipfile

from PIL import Image

ROOT = os.path.join("tools", "assets", "quaternius-village")
ZIP_PATH = os.path.join(ROOT, "zip", "megakit-standard.zip")
OUT = os.path.join(ROOT, "glb")
BASE = "Medieval Village MegaKit[Standard]/glTF/"
TEX_SIZE = 1024

# Subconjunto de peças para montar casas, lojas e a vila
PIECES = [
    # paredes
    "Wall_Plaster_Straight", "Wall_Plaster_Straight_Base", "Wall_Plaster_Straight_L", "Wall_Plaster_Straight_R",
    "Wall_Plaster_Door_Flat", "Wall_Plaster_Door_Round", "Wall_Plaster_Door_RoundInset",
    "Wall_Plaster_Window_Wide_Round", "Wall_Plaster_Window_Wide_Flat", "Wall_Plaster_Window_Thin_Round",
    "Wall_Plaster_WoodGrid", "Wall_UnevenBrick_Straight", "Wall_UnevenBrick_Door_Round",
    "Wall_UnevenBrick_Window_Wide_Round", "Wall_UnevenBrick_Window_Thin_Round", "Wall_Arch", "Wall_BottomCover",
    # cantos e pisos
    "Corner_Exterior_Wood", "Corner_Exterior_Brick", "Corner_ExteriorWide_Wood", "Corner_Interior_Big",
    "Floor_WoodDark", "Floor_Brick", "Floor_UnevenBrick", "Floor_WoodLight",
    # telhados
    "Roof_RoundTiles_4x4", "Roof_RoundTiles_6x6", "Roof_RoundTiles_6x8", "Roof_RoundTiles_8x8", "Roof_RoundTiles_6x10",
    "Roof_Front_Brick4", "Roof_Front_Brick6", "Roof_Front_Brick8", "Roof_Tower_RoundTiles", "Roof_Dormer_RoundTile",
    "Roof_Wooden_2x1", "Roof_Wooden_2x1_Corner", "Roof_Log", "Roof_Support2", "Roof_FrontSupports",
    # portas, janelas, venezianas
    "Door_1_Round", "Door_2_Round", "Door_1_Flat", "DoorFrame_Round_WoodDark", "DoorFrame_Flat_WoodDark",
    "Window_Wide_Round1", "Window_Thin_Round1", "Window_Wide_Flat1",
    "WindowShutters_Wide_Round_Open", "WindowShutters_Wide_Round_Closed", "WindowShutters_Thin_Round_Open",
    # sacadas, beirais, escadas
    "Balcony_Simple_Straight", "Balcony_Simple_Corner", "Balcony_Cross_Straight",
    "Overhang_Plaster_Long", "Overhang_Plaster_Short", "Overhang_Plaster_Corner",
    "Stairs_Exterior_Straight", "Stairs_Exterior_Platform", "Stair_Interior_Simple",
    # props
    "Prop_Chimney", "Prop_Chimney2", "Prop_Crate", "Prop_Wagon", "Prop_WoodenFence_Single",
    "Prop_WoodenFence_Extension1", "Prop_MetalFence_Simple", "Prop_Support", "Prop_ExteriorBorder_Straight1",
]

# Vine e WindowGlass ficam de fora: o jogo trata o vidro com cor e transparência
MATERIALS = ["Plaster", "WoodTrim", "RockTrim", "Brick", "UnevenBrick", "RoundTiles", "RedBrick", "MetalOrnaments"]


def pad(data, fill=b"\x00"):
    extra = (-len(data)) % 4
    return data + fill * extra


def write_glb(path, gltf, binary):
    js = pad(json.dumps(gltf, separators=(",", ":")).encode("utf-8"), b" ")
    bn = pad(binary)
    total = 12 + 8 + len(js) + 8 + len(bn)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack("<II", len(bn), 0x004E4942))
        f.write(bn)


def split_piece(z, name):
    gltf = json.loads(z.read(BASE + name + ".gltf"))
    binary = z.read(BASE + gltf["buffers"][0]["uri"])
    meshes = gltf["meshes"]
    mats = gltf["materials"]
    new_meshes, children = [], []
    for mesh in meshes:
        for prim in mesh["primitives"]:
            mat_name = mats[prim["material"]]["name"]
            new_meshes.append({"name": mat_name, "primitives": [prim]})
            children.append(len(new_meshes) - 1)
    root_src = gltf["nodes"][0]
    root = {k: v for k, v in root_src.items() if k in ("translation", "rotation", "scale", "matrix")}
    root["name"] = name
    nodes = [root]
    root["children"] = []
    for mesh_index in children:
        nodes.append({"name": new_meshes[mesh_index]["name"], "mesh": mesh_index})
        root["children"].append(len(nodes) - 1)
    out = {
        "asset": {"version": "2.0", "generator": "convert_megakit.py"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": nodes,
        "meshes": new_meshes,
        # materiais sem textura: só o nome importa
        "materials": [{"name": m["name"], "pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1], "metallicFactor": 0, "roughnessFactor": 1}} for m in mats],
        "accessors": gltf["accessors"],
        "bufferViews": gltf["bufferViews"],
        "buffers": [{"byteLength": len(binary)}],
    }
    write_glb(os.path.join(OUT, name + ".glb"), out, binary)
    return [m["name"] for m in new_meshes]


def texture_carrier(z):
    """Um triângulo por material, com as texturas embutidas: o importador envia cada imagem uma vez."""
    blob = bytearray()
    views, images, textures, materials, meshes, nodes, accessors = [], [], [], [], [], [], []

    def add_view(data):
        while len(blob) % 4:
            blob.append(0)
        views.append({"buffer": 0, "byteOffset": len(blob), "byteLength": len(data)})
        blob.extend(data)
        return len(views) - 1

    def add_image(name, kind):
        path = BASE + "T_%s_%s.png" % (name, kind)
        try:
            data = z.read(path)
        except KeyError:
            return None
        im = Image.open(io.BytesIO(data)).convert("RGBA" if kind == "BaseColor" else "RGB")
        im.thumbnail((TEX_SIZE, TEX_SIZE))
        buf = io.BytesIO()
        im.save(buf, "PNG", optimize=True)
        images.append({"bufferView": add_view(buf.getvalue()), "mimeType": "image/png", "name": "T_%s_%s" % (name, kind)})
        textures.append({"source": len(images) - 1})
        return len(textures) - 1

    pos = struct.pack("<9f", 0, 0, 0, 1, 0, 0, 0, 1, 0)
    nrm = struct.pack("<9f", 0, 0, 1, 0, 0, 1, 0, 0, 1)
    uv = struct.pack("<6f", 0, 0, 1, 0, 0, 1)
    pv, nv, uvv = add_view(pos), add_view(nrm), add_view(uv)
    accessors.extend([
        {"bufferView": pv, "componentType": 5126, "count": 3, "type": "VEC3", "min": [0, 0, 0], "max": [1, 1, 0]},
        {"bufferView": nv, "componentType": 5126, "count": 3, "type": "VEC3"},
        {"bufferView": uvv, "componentType": 5126, "count": 3, "type": "VEC2"},
    ])
    for index, name in enumerate(MATERIALS):
        color = add_image(name, "BaseColor")
        normal = add_image(name, "Normal")
        rough = add_image(name, "Roughness")
        if rough is None:
            rough = add_image(name, "ORM")
        pbr = {"metallicFactor": 0, "roughnessFactor": 1}
        if color is not None:
            pbr["baseColorTexture"] = {"index": color}
        if rough is not None:
            pbr["metallicRoughnessTexture"] = {"index": rough}
        mat = {"name": "MI_" + name, "pbrMetallicRoughness": pbr}
        if normal is not None:
            mat["normalTexture"] = {"index": normal}
        materials.append(mat)
        meshes.append({"name": "MI_" + name, "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "material": index}]})
        nodes.append({"name": "MI_" + name, "mesh": index, "translation": [index * 2.0, 0, 0]})
    gltf = {
        "asset": {"version": "2.0", "generator": "convert_megakit.py"},
        "scene": 0, "scenes": [{"nodes": list(range(len(nodes)))}], "nodes": nodes, "meshes": meshes,
        "materials": materials, "textures": textures, "images": images, "accessors": accessors,
        "bufferViews": views, "buffers": [{"byteLength": len(blob)}],
    }
    write_glb(os.path.join(OUT, "_texturas.glb"), gltf, bytes(blob))
    return len(images)


def main():
    os.makedirs(OUT, exist_ok=True)
    z = zipfile.ZipFile(ZIP_PATH)
    summary = {}
    for name in PIECES:
        try:
            summary[name] = split_piece(z, name)
        except KeyError as err:
            print("peça ausente:", name, err)
    print("%d peças convertidas" % len(summary))
    used = sorted({m for v in summary.values() for m in v})
    print("materiais usados:", used)
    print("texturas no portador:", texture_carrier(z))
    with open(os.path.join(OUT, "_resumo.json"), "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=1, ensure_ascii=False)


if __name__ == "__main__":
    main()
