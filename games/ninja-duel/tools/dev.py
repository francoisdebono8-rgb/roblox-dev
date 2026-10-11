"""Local tooling only. Never edits active movesets or enables online."""
from pathlib import Path
import argparse, hashlib, json, os, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
CORE=["Shared/Config","Shared/Fighters","Shared/Attacks","Shared/MoveGraphs","Server/Combat","Server/Brawler","Server/Motor","Server/Matches","Server/Techniques","Server/AI","Server/World","Client/Camera","Client/VelmoraMotionEngine","Client/Presentation","Client/UI","Client/Input"]
def run(*cmd):
    subprocess.run(cmd,cwd=ROOT,check=True)
def tool(name):
    for p in (os.getenv(name.upper()),str(Path(os.getenv("NINJA_DUEL_TOOLS","/private/tmp/ninja-duel-tools"))/name),shutil.which(name)):
        if p and (Path(p).is_file() or shutil.which(p)): return p
    raise SystemExit(f"Missing {name}; configure NINJA_DUEL_TOOLS or {name.upper()}")
def audit(baseline):
    rows=[]
    for name in CORE:
        path="src/"+name+".luau"
        proc=subprocess.run(["git","show",f"{baseline}:games/ninja-duel/{path}"],cwd=ROOT,capture_output=True,check=True)
        data=(ROOT/path).read_bytes();rows.append({"path":path,"unchanged":data==proc.stdout,"sha256":hashlib.sha256(data).hexdigest()})
    result={"baseline":baseline,"allUnchanged":all(r["unchanged"] for r in rows),"files":rows}
    print(json.dumps(result,indent=2));return result
def verify():
    compiler=tool("luau-compile")
    for p in sorted((ROOT/"src").rglob("*.luau")):
        proc=subprocess.run([compiler,str(p)],capture_output=True,text=True)
        if proc.returncode: raise SystemExit(f"Syntax failure {p}\n{proc.stderr}")
    validate_catalogue();run(sys.executable,"tests/BuildTools.spec.py");run(sys.executable,"tests/ProgressionTools.spec.py");run("bash","tests/run.sh")
def validate_catalogue():
    data=json.loads((ROOT/"lab/combat-library.json").read_text());ids=set();archetypes=set(data["archetypes"])
    for e in data["entries"]:
        assert e["id"] not in ids;ids.add(e["id"])
        assert e["status"]=="proposal_only" and set(e["archetypes"])<=archetypes
        for key in ("usage","context","technicalDifficulty","conflictRisk","integrationNotes","sequence","acceptance"):
            assert e[key],(e["id"],key)
        assert e["value"]["visual"] and e["value"]["gameplay"]
    for variant in data["characterVariants"].values(): assert set(variant)<=ids
    for p in (ROOT/"lab/templates").glob("*.json"): assert json.loads(p.read_text())["status"]=="draft_not_runtime"
    return data
def compare(out):
    p=subprocess.run([tool("lune"),"run","tools/inspect.luau"],cwd=ROOT,capture_output=True,text=True,check=True)
    data=json.loads(p.stdout);graphs=data["graphs"];table=[]
    for id,f in data["fighters"].items():
        g=graphs.get(id,{})
        table.append({"id":id,"name":f["Name"],"routes":g.get("routes",{}),"heavyAfterOne":g.get("heavyAfterOne"),"disengage":g.get("disengage"),"tool":f.get("ToolMastery"),"awakening":f.get("Awakening"),"techniques":[t["Id"] for t in f["Techniques"]],"attackOverrides":f.get("AttackProfile",{})})
    report={"source":"active shared tables (read-only)","comparison":table,"definitions":data}
    out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    for row in table: print(row["id"],row["name"],json.dumps(row["routes"],ensure_ascii=False))
    print(out)
def read_reports(log,fingerprint):
    runs={};qa=[];parse_errors=[]
    for line in log.read_text(errors="replace").splitlines():
        for marker,target in (("[NinjaDuelPerf] ","perf"),("[NinjaDuelDevQA] RESULT ","qa")):
            if marker not in line: continue
            try: row=json.loads(line.split(marker,1)[1])
            except json.JSONDecodeError: parse_errors.append(marker);continue
            if row.get("build")!=fingerprint: continue
            if target=="qa": qa.append(row);continue
            id=row.get("id");entry=runs.setdefault(id,{"build":fingerprint,"server":{"stats":{},"counters":{},"events":[]},"client":{"stats":{},"counters":{},"events":[]},"rows":0,"complete":False})
            kind=row["kind"]
            if kind=="begin":entry["clientPresent"]=row["clientPresent"]
            elif kind=="end":entry["complete"]=entry["rows"]==row["rows"]
            else:
                entry["rows"]+=1;side=entry[row["side"]]
                if kind=="meta":side.update(seconds=row["seconds"],enabled=row["enabled"])
                elif kind=="metric":side["stats"][row["name"]]=row["value"]
                elif kind=="counter":side["counters"][row["name"]]=row["value"]
                elif kind=="event":side["events"].append(row["value"])
    complete=[r for r in runs.values() if r["complete"]]
    if not complete:raise SystemExit("No complete report for this exact fingerprint. Activate measurements then Report in Studio. Truncated legacy rows are not accepted.")
    return {"log":log.name,"buildFingerprint":fingerprint,"report":complete[-1],"devQA":qa[-1] if qa else None,"malformedRows":len(parse_errors)}
p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest="command",required=True)
sub.add_parser("verify");sub.add_parser("release",help="verify + all three builds; no publish, push or auto-commit")
b=sub.add_parser("build");b.add_argument("--kind",choices=["main","qa","dev-qa"],default="main")
c=sub.add_parser("catalogue");c.add_argument("--family");c.add_argument("--archetype")
a=sub.add_parser("audit");a.add_argument("--baseline",default="ad8247c")
c=sub.add_parser("compare");c.add_argument("--out",type=Path,default=ROOT/"reports/movesets.json")
a=sub.add_parser("report");a.add_argument("--log",type=Path,required=True);a.add_argument("--manifest",type=Path,default=ROOT/"dist/NinjaDuel-DevQA.json");a.add_argument("--out",type=Path,default=ROOT/"reports/native-devtools.json")
args=p.parse_args()
if args.command=="verify": verify()
elif args.command=="audit": sys.exit(0 if audit(args.baseline)["allUnchanged"] else 1)
elif args.command=="build": run(sys.executable,"build.py",*([] if args.kind=="main" else ["--"+args.kind]))
elif args.command=="release":
    verify()
    for kind in ("main","qa","dev-qa"):run(sys.executable,"build.py",*([] if kind=="main" else ["--"+kind]))
elif args.command=="catalogue":
    data=validate_catalogue()
    for e in data["entries"]:
        if args.family and e["family"]!=args.family:continue
        if args.archetype and args.archetype not in e["archetypes"]:continue
        print(f"{e['id']:24} {e['title']} | risque {e['conflictRisk']} | {e['integrationNotes']}")
elif args.command=="compare": compare(args.out)
elif args.command=="report":
    manifest=json.loads(args.manifest.read_text());result=read_reports(args.log,manifest["buildFingerprint"])
    artifact=args.manifest.with_suffix(".rbxlx")
    assert hashlib.sha256(artifact.read_bytes()).hexdigest()==manifest["sha256"],"Artifact differs from manifest"
    result["artifactSHA256"]=manifest["sha256"];args.out.parent.mkdir(parents=True,exist_ok=True);args.out.write_text(json.dumps(result,indent=2)+"\n")
    print(args.out)
