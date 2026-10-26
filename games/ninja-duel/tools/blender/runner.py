# Ninja Duel — Blender job runner (run once inside a Blender session:
#   exec(open("/Users/<you>/Documents/NinjaDuelBlender/runner.py").read())
# It polls <root>/jobs and runs each *.py job in a SEPARATE background
# Blender process (blender -b --factory-startup --python job.py), so the file
# open in the interface is never touched. Output: <root>/out/<job>.log.
import bpy, os, sys, subprocess, time
ROOT = os.path.join(os.path.expanduser("~"), "Documents", "NinjaDuelBlender")
JOBS = os.path.join(ROOT, "jobs")
OUT = os.path.join(ROOT, "out")
LIB = os.path.join(ROOT, "lib")
for d in (JOBS, OUT, LIB):
    os.makedirs(d, exist_ok=True)
ND_RUNNER = {"proc": None, "job": None, "log": None, "t0": 0}

def _nd_tick2():
    st = ND_RUNNER
    if st["proc"] is not None:
        if st["proc"].poll() is None:
            if time.time() - st["t0"] > 900:
                st["proc"].kill()
            return 0.5
        st["log"].write("\nEXIT %s %.1fs\n" % (st["proc"].returncode, time.time() - st["t0"]))
        st["log"].close()
        try:
            os.replace(st["job"] + ".running", st["job"] + ".done")
        except Exception:
            pass
        st["proc"] = None
    try:
        names = sorted(f for f in os.listdir(JOBS) if f.endswith(".py"))
    except Exception:
        return 1.0
    if not names:
        return 0.5
    path = os.path.join(JOBS, names[0])
    run = path + ".running"
    os.replace(path, run)
    log = open(os.path.join(OUT, names[0][:-3] + ".log"), "w")
    env = dict(os.environ, ND_ROOT=ROOT, ND_OUT=OUT, ND_LIB=LIB)
    st["proc"] = subprocess.Popen([bpy.app.binary_path, "-b", "--factory-startup", "--python", run],
                                  stdout=log, stderr=subprocess.STDOUT, env=env, cwd=ROOT)
    st["job"], st["log"], st["t0"] = path, log, time.time()
    return 0.5

# Replace any earlier runner (v1 ran jobs in-process) — deferred, so it is
# never done from inside that runner's own timer callback.
def _nd_swap():
    import gc
    for f in gc.get_objects():
        if callable(f) and getattr(f, "__name__", "") in ("_nd_tick", "_nd_tick2") and f is not _nd_tick2:
            try:
                if bpy.app.timers.is_registered(f):
                    bpy.app.timers.unregister(f)
            except Exception:
                pass
    if not bpy.app.timers.is_registered(_nd_tick2):
        bpy.app.timers.register(_nd_tick2, persistent=True)
    print("NinjaDuel runner v2 (background processes) watching", JOBS)
    return None
bpy.app.timers.register(_nd_swap, first_interval=0.2)
