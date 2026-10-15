"""Export recorded procedural geometry to an importable Roblox model and preview."""
import argparse
import base64
import json
import os
from pathlib import Path
import struct
import xml.etree.ElementTree as ET

import numpy as np
MATERIALS={"Plastic":256,"SmoothPlastic":272,"Neon":288,"Wood":512,"WoodPlanks":528,
 "Marble":784,"Slate":800,"Concrete":816,"Brick":848,"Cobblestone":880,"Rock":896,
 "DiamondPlate":1056,"Foil":1072,"Metal":1088,"Grass":1280,"Sand":1296,"Fabric":1312,
 "Ice":1536,"Glass":1568,"ForceField":1584}


def attributes(values):
    data = bytearray(struct.pack("<I", len(values)))
    def string(value):
        encoded = value.encode("utf-8")
        return struct.pack("<I", len(encoded)) + encoded
    for key, value in sorted(values.items()):
        data.extend(string(key))
        if isinstance(value, str):
            data.extend(b"\x02" + string(value))
        elif isinstance(value, bool):
            data.extend(b"\x03" + bytes([value]))
        elif isinstance(value, (int, float)):
            data.extend(b"\x06" + struct.pack("<d", value))
        else:
            raise ValueError("Unsupported attribute")
    return base64.b64encode(data).decode("ascii")


def value(parent, tag, name, text):
    ET.SubElement(parent, tag, name=name).text = str(text)


def vector(parent, tag, name, components):
    item = ET.SubElement(parent, tag, name=name)
    for key, component in zip(("X", "Y", "Z"), components):
        ET.SubElement(item, key).text = format(component, ".12g")


def export_xml(spec, target):
    root = ET.Element("roblox", version="4")
    ET.SubElement(root, "External").text = "null"
    ET.SubElement(root, "External").text = "nil"
    model = ET.SubElement(root, "Item", {"class": "Model", "referent": "RBXPuzzleModel"})
    props = ET.SubElement(model, "Properties")
    value(props, "string", "Name", spec["name"])
    primary = next(i for i, p in enumerate(spec["parts"]) if p["primary"])
    value(props, "Ref", "PrimaryPart", f"RBXPuzzlePart{primary}")
    value(props, "BinaryString", "AttributesSerialize", attributes(spec["attributes"]))
    for i, part in enumerate(spec["parts"]):
        node = ET.SubElement(model, "Item", {"class": part["class"], "referent": f"RBXPuzzlePart{i}"})
        props = ET.SubElement(node, "Properties")
        value(props, "string", "Name", part["name"])
        for key, state in {"Anchored": True, "CanCollide": part.get("canCollide",False),
                           "CanQuery": part["canQuery"], "CanTouch": part["canTouch"],
                           "CastShadow": part.get("castShadow",True)}.items():
            value(props, "bool", key, str(state).lower())
        value(props, "token", "Material", MATERIALS[part["material"]])
        if part["class"]=="Part":
            value(props, "token", "shape", {"Ball": 0, "Block": 1, "Cylinder": 2}[part["shape"]])
        value(props, "token", "TopSurface", 0)
        value(props, "token", "BottomSurface", 0)
        value(props, "float", "Transparency", part["transparency"])
        value(props, "float", "Reflectance", part.get("reflectance",0))
        color = [max(0, min(255, round(c * 255))) for c in part["color"]]
        value(props, "Color3uint8", "Color3uint8", (255 << 24) | (color[0] << 16) | (color[1] << 8) | color[2])
        vector(props, "Vector3", "size", part["size"])
        cf = ET.SubElement(props, "CoordinateFrame", name="CFrame")
        for key, number in zip(("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"), part["cf"]):
            ET.SubElement(cf, key).text = format(number, ".12g")
    ET.indent(root)
    ET.ElementTree(root).write(target, encoding="utf-8", xml_declaration=True)


def faces(part):
    size = np.array(part["size"]) / 2
    cf = np.array(part["cf"])
    rotation = cf[3:].reshape(3, 3)
    def world(points):
        return np.array(points) @ rotation.T + cf[:3]
    if part["class"]=="WedgePart":
        x,y,z=size
        corners=[(-x,-y,-z),(x,-y,-z),(-x,-y,z),(x,-y,z),(-x,y,z),(x,y,z)]
        for indices in ((0,2,3,1),(2,4,5,3),(0,1,5,4),(0,4,2),(1,3,5)):
            yield world([corners[i] for i in indices])
    elif part["shape"] == "Cylinder":
        x,y,z=size
        count=20
        left=[(-x,np.cos(i*2*np.pi/count)*y,np.sin(i*2*np.pi/count)*z) for i in range(count)]
        right=[(x,np.cos(i*2*np.pi/count)*y,np.sin(i*2*np.pi/count)*z) for i in range(count)]
        yield world(left[::-1]);yield world(right)
        for i in range(count):
            nxt=(i+1)%count
            yield world([left[i],right[i],right[nxt],left[nxt]])
    elif part["shape"] == "Ball":
        rows, columns = 8, 16
        def point(row, column):
            phi = np.pi * row / rows
            theta = 2 * np.pi * column / columns
            return size * [np.sin(phi) * np.cos(theta), np.cos(phi), np.sin(phi) * np.sin(theta)]
        for row in range(rows):
            for column in range(columns):
                yield world([point(row, column), point(row + 1, column), point(row + 1, column + 1), point(row, column + 1)])
    else:
        assert part["class"] == "Part" and part["shape"] == "Block"
        x, y, z = size
        corners = [(-x, -y, -z), (x, -y, -z), (x, y, -z), (-x, y, -z),
                   (-x, -y, z), (x, -y, z), (x, y, z), (-x, y, z)]
        for indices in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 4, 7, 3),
                        (1, 2, 6, 5), (3, 7, 6, 2), (0, 1, 5, 4)):
            yield world([corners[i] for i in indices])


def preview(spec, target, elev=12, azim=-76, figsize=(8,10)):
    os.environ.setdefault("MPLCONFIGDIR", "/tmp/opitem-matplotlib")
    os.environ.setdefault("XDG_CACHE_HOME", "/tmp/opitem-cache")
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from mpl_toolkits.mplot3d.art3d import Poly3DCollection
    polygons, colors = [], []
    light = np.array([-0.3, -0.7, 1.0])
    light /= np.linalg.norm(light)
    for part in spec["parts"]:
        if part["transparency"] >= 1:
            continue
        for face in faces(part):
            normal = np.cross(face[1] - face[0], face[2] - face[0])
            length = np.linalg.norm(normal)
            shade = .66 + .34 * max(0, np.dot(normal / length, light)) if length > 1e-10 else .75
            polygons.append(face[:, [0, 2, 1]])
            colors.append(np.clip(np.array(part["color"]) * shade, 0, 1))
    fig = plt.figure(figsize=figsize, facecolor="#171321")
    ax = fig.add_subplot(111, projection="3d", facecolor="#171321")
    ax.add_collection3d(Poly3DCollection(polygons, facecolors=colors, linewidths=0, zsort="average"))
    all_points = np.concatenate(polygons)
    lo, hi = all_points.min(axis=0), all_points.max(axis=0)
    pad = np.array([.25, .25, .12])
    ax.set_xlim(lo[0] - pad[0], hi[0] + pad[0])
    ax.set_ylim(lo[1] - pad[1], hi[1] + pad[1])
    ax.set_zlim(lo[2] - pad[2], hi[2] + pad[2])
    ax.set_box_aspect(hi - lo + 2 * pad)
    ax.view_init(elev=elev, azim=azim)
    ax.set_axis_off()
    fig.subplots_adjust(left=0, right=1, bottom=0, top=1)
    fig.savefig(target, dpi=150, facecolor=fig.get_facecolor())
    plt.close(fig)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("spec", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    spec = json.loads(args.spec.read_text())
    assert 0 < len(spec["parts"]) <= 180
    assert sum(p["primary"] for p in spec["parts"]) == 1
    for part in spec["parts"]:
        cf = np.array(part["cf"])
        assert np.isfinite(cf).all()
        rotation = cf[3:].reshape(3, 3)
        assert np.allclose(rotation.T @ rotation, np.eye(3), atol=1e-8)
        assert np.isclose(np.linalg.det(rotation), 1, atol=1e-8)
    args.output.mkdir(parents=True, exist_ok=True)
    export_xml(spec, args.output / "MillenniumPuzzle.rbxmx")
    builder = ET.Element("roblox", version="4")
    module = ET.SubElement(builder, "Item", {"class": "ModuleScript", "referent": "RBXPuzzleBuilder"})
    props = ET.SubElement(module, "Properties")
    value(props, "string", "Name", "MillenniumPuzzle")
    source = Path(__file__).resolve().parents[1] / "roblox/assets/MillenniumPuzzle.lua"
    value(props, "ProtectedString", "Source", source.read_text())
    ET.indent(builder)
    ET.ElementTree(builder).write(args.output / "MillenniumPuzzleBuilder.rbxmx", encoding="utf-8", xml_declaration=True)
    preview(spec, args.output / "MillenniumPuzzle-preview.png")
    print(f"Exported {len(spec['parts'])} parts, model, and geometry preview to {args.output}")
