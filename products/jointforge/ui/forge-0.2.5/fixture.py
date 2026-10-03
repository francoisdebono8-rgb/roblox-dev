"""Deterministic real-instance fixture, shared by the QA import and demo place."""
import xml.etree.ElementTree as ET


def build_fixture():
    doc = ET.Element("roblox", version="4")
    refs = {}

    def item(class_name, name, parent):
        node = ET.SubElement(parent, "Item", {"class": class_name, "referent": name})
        ET.SubElement(node, "Properties")
        prop(node, "string", "Name", name)
        refs[name] = node
        return node

    def prop(node, kind, name, value):
        value_node = ET.SubElement(node.find("Properties"), kind, name=name)
        value_node.text = str(value)

    def vector(node, kind, name, xyz):
        value = ET.SubElement(node.find("Properties"), kind, name=name)
        for axis, number in zip(("R", "G", "B") if kind == "Color3" else ("X", "Y", "Z"), xyz):
            ET.SubElement(value, axis).text = str(number)

    def frame(node, xyz, rotate=False):
        value = ET.SubElement(node.find("Properties"), "CoordinateFrame", name="CFrame")
        rotation = (0, -1, 0, 1, 0, 0, 0, 0, 1) if rotate else (1, 0, 0, 0, 1, 0, 0, 0, 1)
        for key, number in zip(("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"), (*xyz, *rotation)):
            ET.SubElement(value, key).text = str(number)

    model = item("Model", "JointForgeIssueAssembly", doc)

    def part(name, x, z, anchored=False):
        node = item("Part", name, model)
        frame(node, (x, 6, z))
        vector(node, "Vector3", "size", (3, 2, 3))
        vector(node, "Color3", "Color", (0.43, 0.48, 0.52))
        prop(node, "bool", "Anchored", str(anchored).lower())
        return node

    def joint(class_name, name, a, b, attachments=False):
        node = item(class_name, name, model)
        prop(node, "Ref", "Attachment0" if attachments else "Part0", a or "null")
        prop(node, "Ref", "Attachment1" if attachments else "Part1", b or "null")
        return node

    for row, prefix in enumerate(("Broken", "Duplicate", "Path", "Ancestry", "Hinge", "Anchored", "Unsupported", "Clean", "Same", "Create", "Batch")):
        for col, suffix in enumerate(("A", "B", "C")):
            part(prefix + suffix, col * 7, row * 7, prefix == "Anchored")
    joint("WeldConstraint", "BrokenConnection", "BrokenA", None)
    joint("WeldConstraint", "DuplicateOne", "DuplicateA", "DuplicateB")
    joint("Weld", "DuplicateTwo", "DuplicateA", "DuplicateB")
    joint("WeldConstraint", "PathAB", "PathA", "PathB")
    joint("WeldConstraint", "PathBC", "PathB", "PathC")
    joint("WeldConstraint", "PathCA", "PathC", "PathA")
    nested = item("Folder", "NestedAttachmentFolder", refs["AncestryA"])
    item("Attachment", "NestedAttachment", nested)
    item("Attachment", "DirectAttachment", refs["AncestryB"])
    joint("RopeConstraint", "InvalidAttachmentAncestry", "NestedAttachment", "DirectAttachment", True)
    item("Attachment", "HingeAttachment0", refs["HingeA"])
    hinge1 = item("Attachment", "HingeAttachment1", refs["HingeB"])
    frame(hinge1, (0, 0, 0), True)
    joint("HingeConstraint", "SeparatedMisalignedHinge", "HingeAttachment0", "HingeAttachment1", True)
    joint("WeldConstraint", "AnchoredWarning", "AnchoredA", "AnchoredB")
    item("Attachment", "RigidAttachment0", refs["UnsupportedA"])
    item("Attachment", "RigidAttachment1", refs["UnsupportedB"])
    joint("RigidConstraint", "InspectOnlyRigid", "RigidAttachment0", "RigidAttachment1", True)
    joint("WeldConstraint", "CleanConnection", "CleanA", "CleanB")
    joint("WeldConstraint", "SameEndpoint", "SameA", "SameA")
    # Duplicate names deliberately share a path; the UI's session identity and
    # real Selection action must still distinguish them.
    for key in ("BrokenA", "BrokenB"):
        refs[key].find("Properties/string[@name='Name']").text = "Endpoint"
    return ET.ElementTree(doc)
