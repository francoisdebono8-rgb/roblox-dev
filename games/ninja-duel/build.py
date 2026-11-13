"""Build reviewed Ninja Duel sources plus explicitly extracted donor assets."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import xml.etree.ElementTree as ET
import shutil

ROOT = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--qa', action='store_true')
parser.add_argument('--debug', action='store_true', help='Separate Studio-only inspector place; no automatic native QA')
parser.add_argument('--capture', action='store_true', help='Filming place: the Debug place plus the capture tools (tools/capture/studio); never the release')
args = parser.parse_args()
if args.qa+args.debug+args.capture>1: parser.error('choose one profile: --debug, --qa or --capture')
# One source, four variants of the same commit (issue #45): release (GAME),
# debug (DEV), qa (QA) and capture (FILM). They all embed the same runtime
# sources; only the Studio-only tools differ. runtimeFingerprint (below) is the
# hash of what the release ships, identical in every profile of one commit.
PROFILE='qa' if args.qa else 'capture' if args.capture else 'debug' if args.debug else 'release'
STUDIO_ONLY=PROFILE!='release'
# Studio-only modules: Debug and QA places, never the normal build
# (tests/test_build_isolation.py). Inspector: DevHooks, CombatInspector,
# CombatDebug. Codex's dev tools (docs/tools/DEVTOOLS.md): F6 panel, setups,
# profiler, report, self-test, and the optional chakra lab (Chakra*).
DEBUG_SOURCES={'DevHooks.luau','CombatInspector.luau','CombatDebug.client.luau',
    'DevTools.luau','DevCommands.luau','DevScenarios.luau','DevProfiler.luau','DevReport.luau','DevQA.luau','DevMetrics.luau',
    'DevClient.luau','DevVolumes.luau','DevVisual.luau','ChakraLab.luau','ChakraDev.luau','ChakraStudioView.luau','ChakraStudioQA.luau','DevRosterCheck.luau','DevGateCheck.luau','DevFlight.luau','TutorialBot.luau','TutorialProbe.luau','Repro.luau'}
def included(p):
    return (args.qa or p.stem!='NativeQA') and (STUDIO_ONLY or p.name not in DEBUG_SOURCES)
def runtime(p):
    return p.stem!='NativeQA' and p.name not in DEBUG_SOURCES
# The capture tools (ported 07/11 from claude/ninja-duel-tutorial-v2
# tools/marketing/factory/studio, see tools/capture/README.md): where each one
# lives in the filming place, as the CLIPS factory's make_clip_place.py put them.
CAPTURE=ROOT/'tools/capture/studio'
CAPTURE_LAYOUT=[('ReplicatedStorage','ModuleScript','ClipKit','ClipKit.client.luau'),('ReplicatedStorage','ModuleScript','HiraishinKunai','HiraishinKunai.luau'),
    ('ServerStorage','ModuleScript','ShotRunner','ShotRunner.server.luau'),('ServerStorage','ModuleScript','Sets','Sets.luau'),('ServerStorage','ModuleScript','SetSnapshot','SetSnapshot.luau'),
    ('ServerScriptService','Script','NDFactoryBoot','NDFactoryBoot.server.luau'),
    # (13/11) the filming assistant (F4), loaded by Client/DevClient when present.
    ('ReplicatedStorage','ModuleScript','ClipAssist','ClipAssist.luau'),
    # (13/11) the CM's replay (FILM08) and its director, and the line of sight they share.
    ('ReplicatedStorage','ModuleScript','ClipSight','ClipSight.luau'),('ReplicatedStorage','ModuleScript','NDReplay','NDReplay.luau'),('ReplicatedStorage','ModuleScript','NDDirector','NDDirector.luau'),
    # (13/11 evening) what a viewer sees and what happens in a match, shared by F4, the replay and the director.
    ('ReplicatedStorage','ModuleScript','ClipJudge','ClipJudge.luau')]
capture_files=[CAPTURE/f for *_,f in CAPTURE_LAYOUT] if args.capture else []
import subprocess
def git(*a):
    try: return subprocess.run(['git',*a],cwd=ROOT,capture_output=True,text=True,timeout=20).stdout.strip()
    except Exception: return ''
# What goes into the place; dist/ is the build's own output.
INPUTS=('src','assets','build.py','vendor','tools/capture')
HEAD_COMMIT=git('rev-parse','HEAD') or 'unknown'
# sourceCommit: the last commit that changed those inputs, so a later commit that
# only adds dist/ or docs rebuilds the same bytes. (A --depth clone cannot see
# history: there it is HEAD; actualiser_places.sh clones with the history.)
SOURCE_COMMIT=(git('log','-1','--format=%H','--',*INPUTS) if git('rev-parse','--is-shallow-repository')=='false' else '') or HEAD_COMMIT
SOURCE_DIRTY=bool(git('status','--porcelain','--',*INPUTS))
xml = ET.Element('roblox', version='4')
serial = 0

def item(parent, cls, name, properties=None):
    global serial
    serial += 1
    node = ET.SubElement(parent, 'Item', {'class': cls, 'referent': f'ND{serial}'})
    props = ET.SubElement(node, 'Properties')
    ET.SubElement(props, 'string', name='Name').text = name
    for key, kind, value in properties or []:
        prop = ET.SubElement(props, kind, name=key)
        if isinstance(value, dict):
            for k, v in value.items(): ET.SubElement(prop, k).text = str(v)
        else: prop.text = str(value)
    return node

def sources(parent, directory):
    for source in sorted(directory.glob('*.luau')):
        if not included(source): continue
        cls = 'Script' if source.name.endswith('.server.luau') else 'LocalScript' if source.name.endswith('.client.luau') else 'ModuleScript'
        name = source.name.split('.')[0]
        item(parent, cls, name, [('Source','ProtectedString',source.read_text(encoding='utf-8'))])

workspace = item(xml,'Workspace','Workspace', [('Gravity','float',140),('FallenPartsDestroyHeight','float',-100)])
# Only the QA build sets the explicit Studio-only test attribute.
replicated = item(xml, 'ReplicatedStorage','ReplicatedStorage')
shared=item(replicated,'Folder','NinjaDuel')
sources(shared,ROOT/'src/Shared')
# Extracted data-only dependencies, never a merged donor place or unknown script.
asset_files=sorted((ROOT/'assets').glob('*.rbxmx'))
for asset_file in asset_files:
    donor_xml=ET.parse(asset_file).getroot()
    assert not any(n.get('class') in ('Script','LocalScript','ModuleScript') for n in donor_xml.iter('Item'))
    references={n.get('referent'):f'DONOR_{asset_file.stem}_{i}' for i,n in enumerate(donor_xml.iter('Item'))}
    for n in donor_xml.iter('Item'):
        n.set('referent',references[n.get('referent')])
    for ref in donor_xml.iter('Ref'):
        if ref.text in references: ref.text=references[ref.text]
    for node in donor_xml.findall('Item'): shared.append(node)
fingerprint=hashlib.sha256(b''.join(p.read_bytes() for p in sorted((ROOT/'src').rglob('*.luau')) if included(p))+b''.join(p.read_bytes() for p in asset_files)+b''.join(p.read_bytes() for p in capture_files)).hexdigest()
runtime_fingerprint=hashlib.sha256(b''.join(p.read_bytes() for p in sorted((ROOT/'src').rglob('*.luau')) if runtime(p))+b''.join(p.read_bytes() for p in asset_files)).hexdigest()
item(shared,'StringValue','BuildFingerprint',[('Value','string',fingerprint)])
# The build's identity, printed by Main and the capture tools: same runtime and
# commit in every profile of one commit.
item(shared,'StringValue','RuntimeFingerprint',[('Value','string',runtime_fingerprint)])
item(shared,'StringValue','BuildProfile',[('Value','string',PROFILE)])
item(shared,'StringValue','SourceCommit',[('Value','string',SOURCE_COMMIT[:12]+('-dirty' if SOURCE_DIRTY else ''))])
licenses=item(shared,'Folder','ThirdPartyLicenses')
for vendor in ('bangla','place1','velmora','lightningbeams'):
    item(licenses,'StringValue',vendor,[('Value','string',(ROOT/'vendor'/vendor/'LICENSE').read_text(encoding='utf-8'))])
server=item(xml,'ServerScriptService','ServerScriptService')
sources(item(server,'Folder','NinjaDuelServer'), ROOT/'src/Server')
starter=item(xml,'StarterPlayer','StarterPlayer', [('CameraMinZoomDistance','float',8),('CameraMaxZoomDistance','float',32)])
sources(item(item(starter,'StarterPlayerScripts','StarterPlayerScripts'),'Folder','NinjaDuelClient'),ROOT/'src/Client')
# (12/11) GlobalShadows written out: left out of the file it came up false (no
# shadow in the world); the client's look (Client/WorldLook) sets it too.
item(xml,'Lighting','Lighting', [('Technology','token',4),('LightingStyle','token',0),('PrioritizeLightingQuality','bool','true'),('GlobalShadows','bool','true'),('ClockTime','float',15),('Brightness','float',2.5),('Ambient','Color3',{'R':0.42,'G':0.48,'B':0.55}),('OutdoorAmbient','Color3',{'R':0.55,'G':0.58,'B':0.6})])
item(xml,'SoundService','SoundService')
if args.capture:
    folders={}
    for service,cls,name,filename in CAPTURE_LAYOUT:
        if service=='ServerScriptService': parent=server
        else:
            if service not in folders:
                holder=replicated if service=='ReplicatedStorage' else item(xml,'ServerStorage','ServerStorage')
                folders[service]=item(holder,'Folder','NDFactory')
            parent=folders[service]
        item(parent,cls,name,[('Source','ProtectedString',(CAPTURE/filename).read_text(encoding='utf-8'))])
if STUDIO_ONLY:
    prefix='workspace:SetAttribute("NinjaDuelDebug",true)\n'
    if args.qa: prefix+='workspace:SetAttribute("NinjaDuelQA",true)\n'
    for props in server.iter('Properties'):
        if props.findtext("string[@name='Name']") == 'Main':
            source = props.find("ProtectedString[@name='Source']")
            source.text = prefix+source.text
name={'release':'NinjaDuel.rbxlx','debug':'NinjaDuel-Debug.rbxlx','qa':'NinjaDuel-QA.rbxlx','capture':'NinjaDuel-Capture.rbxlx'}[PROFILE]
output=ROOT/'dist'/name
ET.indent(xml)
# Binary handle: identical LF bytes on macOS and Windows (text mode would emit CRLF).
with open(output,'wb') as handle: ET.ElementTree(xml).write(handle,encoding='utf-8',xml_declaration=True)
expected = [p.read_text(encoding='utf-8') for p in (ROOT/'src').rglob('*.luau') if included(p)]+[p.read_text(encoding='utf-8') for p in capture_files]
if STUDIO_ONLY:
    main_source=(ROOT/'src/Server/Main.server.luau').read_text(encoding='utf-8')
    expected[expected.index(main_source)]=prefix+main_source
embedded=[p.findtext("ProtectedString[@name='Source']") for p in xml.iter('Properties') if p.find("ProtectedString[@name='Source']") is not None]
assert sorted(embedded)==sorted(expected), 'Embedded sources differ from reviewed files'
external_ids={1778999,18342131933,18342045122,18341956985,18341905406,5835032207,8595980577,9117969717,656117400,656118852,656121766,656117878,656115606,656114359}
for asset_file in asset_files:
    external_ids.update(map(int,re.findall(r'rbxassetid://(\d+)',asset_file.read_text(encoding='utf-8'))))
import sys
# Automated gate: every headless spec must pass on the exact sources built here.
TEST_RUNNERS=[('lune','tests/Input.spec.luau'),('luau','tests/Rules.spec.luau'),('lune','tests/Combat.spec.luau'),('lune','tests/Sequences.spec.luau'),('lune','tests/Regression.spec.luau'),('lune','tests/Feedback.spec.luau'),('lune','tests/Animation.spec.luau'),('lune','tests/Branches.spec.luau'),('lune','tests/Phase4.spec.luau'),('lune','tests/Neji.spec.luau'),('lune','tests/Systems.spec.luau'),('lune','tests/Tools.spec.luau'),('lune','tests/Sasuke.spec.luau'),('lune','tests/Gaara.spec.luau'),('lune','tests/Lee.spec.luau'),('lune','tests/Online.spec.luau'),('lune','tests/Progression.spec.luau'),('lune','tests/Profiles.spec.luau'),('lune','tests/Preparation.spec.luau'),('lune','tests/DevInfra.spec.luau'),('lune','tests/ComboModel.spec.luau'),('lune','tests/Chakra.spec.luau'),('lune','tests/ChakraFlow.spec.luau'),('lune','tests/AirCombat.spec.luau')]
# CORE4 identity pass (Mirage, Read, Wind Cut, tenketsu, awakenings, jutsu flow).
TEST_RUNNERS.append(('lune','tests/Identity.spec.luau'))
# Roster wave: Naruto, several bodies (Server/Bodies, Server/Legion, BodyViews, NarutoFX).
TEST_RUNNERS.append(('lune','tests/Naruto.spec.luau'))
# Roster wave: Temari (wind zones, the fan, the zoner AI).
TEST_RUNNERS.append(('lune','tests/Temari.spec.luau'))
# Roster 20 breadth pass: the Tier A floor for every fighter of Shared/Roster.
TEST_RUNNERS.append(('lune','tests/Roster.spec.luau'))
TEST_RUNNERS.append(('lune','tests/Roster20.spec.luau'))
TEST_RUNNERS.append(('lune','tests/Convergence.spec.luau'))
# (Audit 29/10) Suites that existed but were outside the gate (CombatFeel had
# been failing unseen), the fluidity regressions, and the player-control gate.
TEST_RUNNERS.append(('lune','tests/Movement.spec.luau'))
TEST_RUNNERS.append(('lune','tests/Embodiment.spec.luau'))
TEST_RUNNERS.append(('lune','tests/CombatFeel.spec.luau'))
TEST_RUNNERS.append(('lune','tests/Fluidity.spec.luau'))
TEST_RUNNERS.append(('lune','tests/Control.spec.luau'))
# (Stage 6) the ultimates, the Tsukuyomi, Lee's gates, Kakashi's awake Sharingan.
TEST_RUNNERS.append(('lune','tests/Ultimates.spec.luau'))
TEST_RUNNERS.append(('lune','tests/Interactions.spec.luau'))
TEST_RUNNERS.append(('lune','tests/Prediction.spec.luau'))
def run_automated():
    tool={}
    import os
    # Tool locations: explicit env (LUAU / LUNE), a shared tools folder
    # (NINJA_DUEL_TOOLS, macOS /private/tmp default, Windows %LOCALAPPDATA%), then PATH.
    folders=[os.environ.get('NINJA_DUEL_TOOLS',''),'/private/tmp/ninja-duel-tools',os.path.join(os.environ.get('LOCALAPPDATA',''),'ninja-duel-tools')]
    for probe in ('luau','lune'):
        candidates=[os.environ.get(probe.upper(),'')]
        for folder in folders:
            if folder: candidates+=[os.path.join(folder,probe),os.path.join(folder,probe+'.exe')]
        candidates.append(probe)
        for candidate in candidates:
            if candidate and (shutil.which(candidate) or Path(candidate).is_file()):
                tool[probe]=candidate
                break
    results={}
    if len(tool)<2:
        return {'status':'SKIPPED','reason':'luau/lune not available in this environment','suites':{}}
    for engine,spec in TEST_RUNNERS:
        command=[tool[engine],'run',spec] if engine=='lune' else [tool[engine],spec]
        proc=subprocess.run(command,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
        tail=(proc.stdout or '').strip().splitlines()
        results[spec]={'exit':proc.returncode,'summary':tail[-1] if tail else ''}
    failed=[spec for spec,data in results.items() if data['exit']!=0]
    return {'status':'PASS' if not failed else 'FAIL','failed':failed,'suites':results}
automated=run_automated()
print('Automated suites:',automated['status'])
for spec,data in automated['suites'].items():
    print('  ',spec,data['exit'],data['summary'])
if automated['status']=='FAIL':
    sys.exit('Automated suites failed: '+', '.join(automated['failed']))

manifest={'version':'0.13.0-arena-combo','artifact':name,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'src').rglob('*.luau')) if included(p)},'sourceEquality':'PASS','debugOnly':STUDIO_ONLY,'buildFingerprint':fingerprint,
 'profile':PROFILE,'runtimeFingerprint':runtime_fingerprint,'sourceCommit':SOURCE_COMMIT,'headCommit':HEAD_COMMIT,'sourceDirty':SOURCE_DIRTY,
 'captureTools':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in capture_files},'donorAssets':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in asset_files},'externalAssets':sorted(external_ids),
 'automatedQA':automated,
 # Native (Roblox Studio) and human-feel gates are recorded separately and are
 # only moved off PENDING by an actual Studio run on this exact artifact.
 'nativeQA':'PENDING', 'visualAcceptance':'PENDING', 'controllerFeel':'PENDING', 'animationPermission':'PENDING'}
output.with_suffix('.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
print(output)
print(manifest['sha256'])
