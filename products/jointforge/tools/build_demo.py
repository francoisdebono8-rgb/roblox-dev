"""Build an original, script-free Studio demo using only Roblox primitives."""
from pathlib import Path
import math
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
doc = ET.Element("roblox", version="4")
counter = 0


def prop(item, kind, name, value):
    node = ET.SubElement(item.find("Properties"), kind, name=name)
    if isinstance(value, dict):
        for key, number in value.items():
            ET.SubElement(node, key).text = str(number)
    else:
        node.text = str(value)
    return node


def item(parent, cls, name):
    global counter
    counter += 1
    node = ET.SubElement(parent, "Item", {"class": cls, "referent": f"JF{counter}"})
    ET.SubElement(node, "Properties")
    prop(node, "string", "Name", name)
    return node


def vec(x, y, z):
    return dict(X=x, Y=y, Z=z)


def cf(position, rotation=None):
    values = vec(*position)
    r = rotation or (1, 0, 0, 0, 1, 0, 0, 0, 1)
    values.update({f"R{i}{j}": r[i * 3 + j] for i in range(3) for j in range(3)})
    return values


def ref(node, name, target):
    prop(node, "Ref", name, target.get("referent") if target is not None else "null")


def part(parent, name, position, size, color, anchored=True):
    p = item(parent, "Part", name)
    prop(p, "CoordinateFrame", "CFrame", cf(position))
    prop(p, "Vector3", "size", vec(*size))
    prop(p, "Color3", "Color", dict(R=color[0] / 255, G=color[1] / 255, B=color[2] / 255))
    prop(p, "bool", "Anchored", str(anchored).lower())
    prop(p, "token", "Material", 256)
    prop(p, "token", "TopSurface", 0)
    prop(p, "token", "BottomSurface", 0)
    return p


def attachment(parent, name, position, vertical=False):
    a = item(parent, "Attachment", name)
    rotation = (0, -1, 0, 1, 0, 0, 0, 0, 1) if vertical else None
    prop(a, "CoordinateFrame", "CFrame", cf(position, rotation))
    return a


world = item(doc, "Workspace", "Workspace")
lighting = item(doc, "Lighting", "Lighting")
prop(lighting, "token", "Technology", 3)
prop(lighting, "float", "ClockTime", 14)
prop(lighting, "float", "Brightness", 2)
prop(lighting, "Color3", "Ambient", dict(R=.5, G=.5, B=.5))
part(world, "StudioFloor", (0, -.5, 0), (80, 1, 45), (223, 227, 230))
teal, red, grey, yellow = (39, 157, 140), (225, 93, 79), (62, 67, 72), (245, 193, 70)


def drill(name, x, connected=False):
    model = item(world, "Model", name)
    part(model, "DisplayBase", (x, .25, 0), (12, .5, 10), (197, 205, 211))
    handle = part(model, "Handle", (x, 2.4, 0), (1.1, 3.2, 1.5), grey)
    body = part(model, "Body", (x + 1, 4.4, 0), (4.6, 2, 2.3), teal, False)
    battery = part(model, "Battery", (x, .9, 0), (2.5, .7, 2.4), grey, False)
    chuck = part(model, "Chuck", (x + 4, 4.4, 0), (1.3, 1.35, 1.35), yellow, False)
    trigger = part(model, "Trigger", (x + .9, 2.9, 0), (.65, 1, .8), red, False)
    if connected:
        for p in (body, battery):
            j = item(handle, "WeldConstraint", "Existing_" + p.find("Properties/string").text)
            ref(j, "Part0", handle); ref(j, "Part1", p)
        j = item(handle, "Motor6D", "Existing_ChuckMotor")
        ref(j, "Part0", handle); ref(j, "Part1", chuck)
        prop(j, "CoordinateFrame", "C0", cf((4, 2, 0)))
        j = item(handle, "Weld", "MissingEndpoint_InspectMe")
        ref(j, "Part0", trigger)
    ref(model, "PrimaryPart", handle)
    return model


drill("01_BatchTool", -18)
drill("02_ExistingGraph", 0, True)
door = item(world, "Model", "03_DoorHinge")
frame = part(door, "Frame", (13, 4, 0), (.7, 8, 1), grey)
panel = part(door, "Door", (16, 4, 0), (5.3, 7.6, .65), teal)
attachment(frame, "HingePivot0", (.35, 0, 0), True)
attachment(panel, "HingePivot1", (-2.65, 0, 0), True)
mechanic = item(world, "Model", "04_RopeSpring")
beam = part(mechanic, "Beam", (0, 9, -13), (13, .7, 1), grey)
for x, cls, color in ((-4, "RopeConstraint", yellow), (4, "SpringConstraint", red)):
    load = part(mechanic, cls + "Load", (x, 3, -13), (2.5, 2.5, 2.5), color)
    a = attachment(beam, cls + "Top", (x, 0, 0))
    b = attachment(load, cls + "Bottom", (0, 0, 0))
    joint = item(beam, cls, "Existing_" + cls)
    ref(joint, "Attachment0", a); ref(joint, "Attachment1", b)
    prop(joint, "bool", "Visible", "true")
    prop(joint, "float", "Length" if cls == "RopeConstraint" else "FreeLength", 6)

# Camera looks down toward the four demonstration assemblies.
camera = item(world, "Camera", "Camera")
angle = math.radians(25)
prop(camera, "CoordinateFrame", "CFrame", cf((0, 22, 40), (1, 0, 0, 0, math.cos(angle), math.sin(angle), 0, -math.sin(angle), math.cos(angle))))
prop(camera, "CoordinateFrame", "Focus", cf((0, 3, 0)))
prop(camera, "float", "FieldOfView", 55)
ref(world, "CurrentCamera", camera)
ET.indent(doc)
target = ROOT / "demo" / "JointForge-Demo.rbxlx"
target.parent.mkdir(parents=True, exist_ok=True)
ET.ElementTree(doc).write(target, encoding="utf-8", xml_declaration=True)
print(target.name)
