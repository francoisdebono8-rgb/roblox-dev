# Observation of a real match (28/10, 16:55–17:02)

The user played Sasuke against the Itachi bot, at the controller, in `ND-Observation.rbxlx` (full Partie 1–9 build). Claude recorded the client the whole time: inputs, every change of state for both fighters (state, move, reaction, airborne, position, vertical speed) and slow frames, plus screenshots every 2 to 4 s.

## What the recording shows

| # | Observation | Measure | Probable cause |
|---|---|---|---|
| 1 | The same move over and over: the flying kick | 23 of 81 player moves (28%), up to 5 in a row; 17 Light1 against 2 Light3 | On the controller, the sprint (L3) is a toggle and stays on. Out of a sprint, every Light becomes the running strike (`Brawler`, `runStrike`). That strike knocks back, so the string never gets past the first hit. |
| 2 | Jump + attack = slam, three times in a row | 71–74 s: Slam, Slam, Slam | The jump-in strike goes straight to the slam |
| 3 | Floaty, very high jumps | 0.8–1.1 s of flight, 12–15 studs high | `JumpVelocity 58`, Gravity 140 (designed as a ~12-stud "ninja" jump) |
| 4 | Airborne flickers on the ground | 15 phases of 0.1–0.2 s at 0.2–0.6 studs, and one 1.5 s phase at 0 studs | The airborne state comes and goes (unevenness, landing). Probable cause of the jumps "buggés" |
| 5 | The bot repeats itself too | 7 DashAttack, 5 CounterPalm, 4 StepBackStrike | AI weights |
| 6 | Bodies overlap and the camera sits inside the player's body | Screenshots | Close camera, contact distances |
| 7 | Debug build: the debug panel covers 40% of the screen | Screenshots | Every file handed over was a Debug build (F8 hides it) |
| 8 | Image | 15 fps only while Studio was not the focused window (35–41 s, then the end); elsewhere fine | Not a game problem |

## Consequence for the method

Clip quality in Blender is not what the user feels. In real play he feels the input language: the toggled sprint, which moves come out, jumps and landings, the camera. From now on, every part is judged on a recorded match like this one, not only on contact sheets.
