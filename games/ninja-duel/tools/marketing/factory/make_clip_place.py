"""Make the filming place from the latest delivered Labo build:
    python3 make_clip_place.py [vNN]
reads   Documents/Roblox/ND-Test-vNN.rbxlx (the highest vNN if none given): the
        Debug build (dev hooks, no automatic native QA; ND-Labo is the QA build,
        which starts its test battery on Play)
writes  Documents/NinjaDuelMedia/ND-Clips-vNN.rbxlx
with the factory's Studio modules inside (ReplicatedStorage.NDFactory.ClipKit,
ServerStorage.NDFactory.ShotRunner / Sets). The sets themselves are built in
Studio from code: require(game.ServerStorage.NDFactory.Sets).all(), then save."""
import glob, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.join(os.path.expanduser("~"), "mnt", "Documents")
builds = {int(m.group(1)): f for f in glob.glob(os.path.join(DOCS, "Roblox", "ND-Test-v*.rbxlx")) for m in [re.search(r"-v(\d+)\.rbxlx$", f)] if m}
v = int(sys.argv[1].lstrip("v")) if len(sys.argv) > 1 else max(builds)
src = builds[v]
xml = open(src, encoding="utf-8").read()
assert "NDFactory" not in xml, "already has the factory"

def module(name, path, ref):
    code = open(path, encoding="utf-8").read()
    assert "]]>" not in code
    return (f'<Item class="ModuleScript" referent="{ref}"><Properties><string name="Name">{name}</string>'
            f'<ProtectedString name="Source"><![CDATA[{code}]]></ProtectedString></Properties></Item>')

def folder(ref, kids):
    return f'<Item class="Folder" referent="{ref}"><Properties><string name="Name">NDFactory</string></Properties>{"".join(kids)}</Item>'

st = os.path.join(HERE, "studio")
rep = folder("NDF1", [module("ClipKit", os.path.join(st, "ClipKit.client.luau"), "NDF2"),
                      module("HiraishinKunai", os.path.join(st, "HiraishinKunai.luau"), "NDF7")])
srv = folder("NDF3", [module("ShotRunner", os.path.join(st, "ShotRunner.server.luau"), "NDF4"),
                      module("Sets", os.path.join(st, "Sets.luau"), "NDF5"),
                      module("SetSnapshot", os.path.join(st, "SetSnapshot.luau"), "NDF6")])
# inside ReplicatedStorage: find its own closing tag by nesting depth
start = xml.index('<Item class="ReplicatedStorage"')
depth, i = 0, start
for m in re.finditer(r"<Item\b|</Item>", xml[start:]):
    depth += 1 if m.group(0) == "<Item" else -1
    if depth == 0:
        i = start + m.start(); break
xml = xml[:i] + rep + xml[i:]
if '<Item class="ServerStorage"' in xml:
    s = xml.index('<Item class="ServerStorage"'); j = xml.index("</Properties>", s) + len("</Properties>")
    xml = xml[:j] + srv + xml[j:]
else:
    k = xml.rindex("</roblox>")
    xml = xml[:k] + f'<Item class="ServerStorage" referent="NDF0"><Properties><string name="Name">ServerStorage</string></Properties>{srv}</Item>\n' + xml[k:]
out = os.path.join(DOCS, "NinjaDuelMedia", f"ND-Clips-v{v}.rbxlx")
open(out, "w", encoding="utf-8").write(xml)
print(out, os.path.getsize(out), "from", os.path.basename(src))
