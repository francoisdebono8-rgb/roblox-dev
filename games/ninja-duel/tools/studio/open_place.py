"""Open a place in Roblox Studio (restarting Studio), wait for the MCP bridge to see it,
start Play, then bring the Studio window to the foreground (an unfocused Studio renders
at ~15-20 fps, which invalidates smoothness measurements).

  python open_place.py <place.rbxlx>
"""
import glob, json, os, subprocess, sys, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mcp import post  # noqa: E402

place = os.path.abspath(sys.argv[1])
VERSIONS = os.path.expandvars(r'%LOCALAPPDATA%\Roblox\Versions')
studio_exe = sorted(glob.glob(os.path.join(VERSIONS, '*', 'RobloxStudioBeta.exe')), key=os.path.getmtime)[-1]


def call(tool, args, timeout=60):
    return post({'tool': tool, 'args': args, 'timeout': timeout}, timeout)


def foreground():
    script = ("$s='[DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(IntPtr h);';"
              "Add-Type -MemberDefinition $s -Name F -Namespace NinjaDuelOpen -ErrorAction SilentlyContinue;"
              "$p=Get-Process RobloxStudioBeta | ?{$_.MainWindowHandle -ne 0} | select -First 1;"
              "if($p){[NinjaDuelOpen.F]::SetForegroundWindow($p.MainWindowHandle)}")
    subprocess.run(['powershell', '-NoProfile', '-Command', script], capture_output=True)


if __name__ == '__main__':
    subprocess.run(['taskkill', '/F', '/IM', 'RobloxStudioBeta.exe'], capture_output=True)
    time.sleep(2)
    subprocess.Popen([studio_exe, place], cwd=os.path.dirname(studio_exe))
    sid = None
    for _ in range(60):
        try:
            text = call('list_roblox_studios', {}, 20)['text']
            studios = json.loads(text).get('studios', []) if text.startswith('{') else []
        except Exception:
            studios = []
        hit = [s for s in studios if os.path.basename(place) in (s.get('name') or '')]
        if hit:
            sid = hit[0]['id']
            break
        time.sleep(3)
    if not sid:
        sys.exit('Studio never connected to the MCP bridge')
    time.sleep(3)
    print(call('start_stop_play', {'is_start': True, 'studio_id': sid}, 60)['text'][:200])
    for _ in range(30):
        if 'Server' in call('get_studio_state', {'studio_id': sid}, 20)['text']:
            break
        time.sleep(2)
    foreground()
    print('ready', sid)
