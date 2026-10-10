# Public build

## Status

**Not published to a Roblox Experience yet.** The playable build is complete and in the repo:
`games/ninja-duel/dist/NinjaDuel.rbxlx` (version `0.12.0-final-playable`, branch `claude/minato-itachi-final`).

### Why it is not published

- Publishing a place to an Experience is a Roblox Studio menu action tied to the signed-in account
  (*File → Publish to Roblox*). The Studio tooling used in these passes (a local plugin bridge) cannot trigger
  it; the only scriptable route is the Open Cloud Place Publishing API, which needs an API key from the account
  owner.
- It would also create a public experience under the owner's account, which should be the owner's own action.

## Publish it yourself (about 2 minutes, Mac or PC)

1. Download `games/ninja-duel/dist/NinjaDuel.rbxlx` from GitHub (branch `claude/minato-itachi-final`) and open it
   in Roblox Studio.
2. *File → Publish to Roblox As…* → *Create new experience* → name it (e.g. "Ninja Duel — Prodigy Tournament")
   → *Create*.
3. *Home → Game Settings → Permissions*: set *Playability* to **Public** (or Friends / Private for testing).
   *Game Settings → Security*: leave *Allow HTTP Requests* off; nothing else is required.
4. Open the experience page from the Creator Dashboard (create.roblox.com → Creations); the URL looks like
   `https://www.roblox.com/games/<PLACE_ID>/...`. Paste it below so both PC and Mac open the same build.

After later builds: open the new `.rbxlx`, then *File → Publish to Roblox As…* → choose the existing
experience to overwrite its place.

## Experience link

- Place ID: _not published yet_
- URL: _not published yet_
