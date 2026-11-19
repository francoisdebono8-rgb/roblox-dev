#!/usr/bin/env python3
"""`blender` command for cloud sessions, backed by the `bpy` Python module.

The SyphoDev skills call Blender headless, for example
    blender --background rig.blend --enable-autoexec --python anim_render.py -- spec.json out/
    blender -b -P make_meshes.py
    blender --version
A cloud session has no Blender app, but `pip install bpy==5.2.3` gives the same
Blender (5.2.3 LTS, the version on François's Mac) as a module. This shim reads
the same arguments, opens the .blend, then runs the script with sys.argv set the
way Blender sets it, so the skill scripts run unchanged.

Installed as `blender` on PATH by tools/syphodev/setup_cloud.sh.
"""
import os
import runpy
import sys


def main(argv):
    if "--version" in argv or "-v" in argv:
        import bpy
        print(f"Blender {bpy.app.version_string}")
        return 0
    blend = None
    scripts = []
    exit_code_on_error = 0
    i = 0
    rest = []
    while i < len(argv):
        a = argv[i]
        if a == "--":
            rest = argv[i + 1:]
            break
        if a in ("-b", "--background", "--enable-autoexec", "-y", "--factory-startup", "--disable-autoexec", "-noaudio"):
            pass
        elif a in ("-P", "--python"):
            i += 1
            scripts.append(argv[i])
        elif a == "--python-exit-code":
            i += 1
            exit_code_on_error = int(argv[i])
        elif a.endswith(".blend"):
            blend = a
        else:
            print(f"blender shim: ignoring argument {a!r}", file=sys.stderr)
        i += 1

    import bpy
    if blend:
        bpy.ops.wm.open_mainfile(filepath=os.path.abspath(blend), load_ui=False)
    for script in scripts:
        path = os.path.abspath(script)
        # Blender's own argv: the scripts look for "--" and read what follows.
        sys.argv = ["blender", "--background"] + ([blend] if blend else []) + ["--python", path, "--"] + rest
        sys.path.insert(0, os.path.dirname(path))
        try:
            runpy.run_path(path, run_name="__main__")
        except SystemExit as e:
            code = e.code if isinstance(e.code, int) else (0 if e.code is None else 1)
            if code:
                return code
        except Exception:
            import traceback
            traceback.print_exc()
            # Real Blender exits 0 after a Python error unless --python-exit-code is given
            # (SyphoDev trap 40). Keep that behaviour so the scripts' own guards stay honest.
            return exit_code_on_error
    return 0


if __name__ == "__main__":
    code = main(sys.argv[1:])
    sys.stdout.flush()
    os._exit(code)
