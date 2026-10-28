> Référence technique/recherche, non normative. État, priorités et règles : [sources actives](../active/EXECUTION_RULES.md). Travail : ANIM-001…006 ([MASTER_BACKLOG](../active/MASTER_BACKLOG.md)), décision [DEC-028](../active/DECISIONS.md).

# Animation craft for Ninja Duel — what I apply and why

Working notes of the animation-mastery mission (27/10/2026). Each principle is stated, measured against the real Ninja Duel rig and game numbers, then turned into a rule for the Blender authoring (`tools/blender/nd_ctrl.py`, `nd_shot.py`) or the runtime (`Client/VelmoraMotionEngine.luau`). The sources are listed at the end.

## 1. The rig and the game, in numbers

- Character: ~5.75 studs tall, so 1 stud ≈ 0.30 m. Hip to ankle: 2.05 studs (thigh 1.05, shin 1.0). Ankle 0.4 above the floor; the HumanoidRootPart is 3.0 above it.
- Reach of a planted foot from the hip at a given crouch (root y): horizontal max = √(2.05² − (hipHeight − 0.4)²). In the fighting crouch (y −0.5, hips at 1.95), a foot can be at most ~1.3 studs ahead of or behind the hip. Every planted foot position is checked against this. Feet authored beyond it make the leg go straight and the foot slides.
- Game speeds (Config.Movement): run 19 studs/s (≈ 5.8 m/s), sprint 45 (≈ 13.7 m/s, anime), acceleration 170 studs/s² (0 → run in 0.11 s), braking 290 (run → stop in 0.07 s, sprint → stop in 0.16 s), turn acceleration 360. Jump: 58 studs/s up at gravity 140, so about 12 studs high and 0.83 s in the air. Attack walk 12 studs/s.
- Consequence: the game's body changes speed faster than a human can. The animation cannot wait for physics. It has to show the intention in very few frames: 2–3 frames of anticipation, not 10.

## 2. Weight, balance, support

- The centre of mass (CoM) is the volume-weighted average of the parts, around the belly. When static, its vertical line falls inside the base of support (the hull of the planted soles). `nd_shot.check` reports every slow frame where it does not ("off_balance").
- Moving the CoM a few centimetres sideways moves the weight to the other leg. It shows in the pose (contrapposto): the hip rises on the support side and the shoulder drops on that side.
- In a dynamic action (a lunge, a fall), the CoM leaves the base on purpose. It must be caught by the next contact (a step, a landing). A body that leans out and recovers without a contact reads as floating.
- Rule: every key pose names its support foot. The hips (`cog`) move first toward the new support, and the chest follows a few frames later (`drag`).

## 3. Timing and spacing

- Timing is how many frames an action lasts. Spacing is how the distance is shared out between those frames (it lives in the F-curves, not in the keys).
- Slow in / slow out at extremes (flat tangents). A strike, however, arrives at full speed: no slow-in on the contact frame. The spacing widens all the way to the impact, then a slow out (overshoot and settle). This is the `impact` spacing of nd_shot: a short left handle aligned with the approach, and the key before eases out. Its mirror is `launch` (a push-off, a release).
- A fall accelerates: the spacing grows each frame (gravity). A landing absorbs: big spacing on the impact frame, then decreasing.
- Breakdowns (`pass`) decide the arc between two extremes. Without them the interpolation takes the shortest path, and limbs go straight through where they should swing.

## 4. Anticipation, action, follow-through, overlap

- Anticipation stores energy in the opposite direction: the knees load before a jump, the hips coil before a punch. In a fighting game it must be very short for responsiveness (Light1: 3 frames, Heavy: 8, a jump: what the legs show in the first air frames). The anticipation of a heavy action is longer and readable. That is its cost and its telegraph.
- Initiation: the force starts from the floor and the hips (kinetic chain, proximal to distal). Peak speeds go hips → chest → shoulder → elbow → fist. In nd_shot the arm keys arrive at full extension one or two frames after the hips have turned, never before.
- Follow-through and overlap: the parts do not all stop on the same frame. The head, the free arm and the chest settle 1–5 frames after the hips (`drag`). The striking limb overshoots and comes back.
- Settling: an action ends in a balanced pose that leads into the next one, not a dead stop.

## 5. Locomotion

- Walk: contact → down → passing → up. Run: contact → down → push → peak, with a flight phase where no foot touches the floor.
- A runner lands on the midfoot just ahead of the CoM (not far ahead: that brakes). The stance leg absorbs (lowest point 2–3 frames after contact), then extends behind. The free heel folds high behind and the knee drives through in front.
- Pelvis and chest twist against each other. The arms swing opposite to the legs, and the head stays level (it counters the bob).
- Acceleration: the trunk leans forward to direct the force horizontally, and stands up at top speed. Braking: the penultimate step brakes, the chest sits back, the hips drop. A change of direction plants a foot outside the line, leans into the new direction and pushes off from that plant. It is never a root rotating on the spot. Cutting studies give about 0.2 s on the penultimate contact and 0.3 s on the plant. In this game, half of that.
- Rule for cycles: authored pose-to-pose, half a cycle mirrored (`nd_shot.cycle`). The planted foot is not keyed: its world spot is computed from where it landed, so it cannot slide. The game then advances the cycle by distance / stride, so the feet stay on the floor at any speed.
- Stride from the rig: run 10 studs per cycle (32 frames at 19 studs/s, the foot on the floor 22%), sprint 14 studs (20 frames at 45 studs/s, 18%). The old clips used 7 and 12.5, which gave pattering feet.

## 6. Jumps and landings

- Take-off: anticipation, then extension (hips, knees, ankles), and the arms thrown up add vertical force. The CoM follows a parabola whatever the limbs do.
- Air: gather at the apex (compact, knees up), then open. The feet search for the floor before impact and the head looks at it.
- Landing: the front foot touches first, the hips keep falling. The knees absorb: deepest about 5 frames after contact, the chest folding over the knees so the CoM stays over the feet. Then release into the next action. A landing that stops dead reads as weightless. A landing that never compresses reads as weightless too.

## 7. Strikes

- Straight punch (jab, cross): the rear foot pushes and its heel lifts, the lead foot steps in and lands on the contact frame. The hips turn in, the shoulder drives, and the arm extends last, turning over at the end. The rear hand stays at the jaw. Retraction is faster than extension.
- Roundhouse: the support foot pivots on its ball (toes turning away, 90–135°), the knee chambers high toward the target, the hip turns over and the shin unfolds. The kicking-side arm drops behind, the other guards, and the chest drops to counterbalance. Retract to the chamber before setting the foot down.
- Push (front) kick: weight onto the support leg, chamber the knee high, hip thrust, the heel drives through. The chest leans back over the support foot.
- A missed strike carries the body past the contact point (the server's whiff carry). The animation must not snap back.

## 8. Hit reactions

- The impulse enters at the contact point and propagates. The struck part moves first (head for a jab, chest for a body blow), the hips are carried after, and the extremities (hands, free foot) lag and overshoot.
- Balance is lost in the direction of the force. Recovery uses a step in that direction (catching the CoM), then returns to guard.
- Direction comes from the hit angle. Strength scales the amplitude, not the timing of the onset.
- The other side is authored (`Hit.*.L`), not mirrored: a mirror swaps the lead foot, so the body ended a reaction in the wrong stance.
- The server slides a struck body ~0.9 stud. A reaction is authored with its feet still in place on the rig; at runtime the planted foot is locked on the real floor while the body slides, and the other foot steps to catch the weight (`clips_react2.py`, ANIM-005).

## 9. Continuity (runtime)

- A clip change must keep the body's pose and velocity. Inertialization: the new clip plays at its own spacing at once, and the difference with what was drawn decays on a critically damped spring (Bollo, SIGGRAPH 2017; half-lives of 0.05 s for a chained strike, 0.07 s for a strike out of movement, 0.12 s back to locomotion). It is implemented in `write()`/`apply()` of the motion engine (ANIM-002).
- A strike thrown on the move keeps the run's legs while the body travels (phase by distance). The upper body throws the blow. As the body slows, the strike's own footwork takes over.
- The feet of authored clips are locked on the real floor while the clip keeps them still. A lift starts from where the foot really was and arcs onto the clip's path. A foot carried out of reach steps.

- **Frame data first.** The server's startup is the game: a jab lands 3–5 frames after the press (Sasuke Light1: 0.081 s startup, minus the 0.03 s presentation lead). A clip's contact marker is mapped onto the server's contact. A wind-up authored longer than the startup plays at most 1.25× its speed; its slow start is skipped and the transition carries the body in. Author the anticipation inside the frames the game gives, and put the wind-up a heavy really needs into the heavy's own startup.
- Markers are written in seconds from the first key. Until 28/10 the export divided them by 60 a second time: every contact sat at ~0.002 s, the stance was held through the startup and the whole blow played after the server's hit (the "strikes thought alone" feeling). The export now refuses a marker outside its clip, and a test checks every strike.
- A kick goes out and back on the same line (chamber → extend → re-chamber → down). A leg swung straight from head height to behind the hip turns the IK knee over in one frame. The export reports any leg joint turning more than 45° in one sample (`FAST`) and more than 115° (`FLIP`).

## 10. The Graph Editor is part of the craft

What the curves must show for an important action: acceleration into the contact (`impact`), deceleration into holds (`ease`), overshoot and settle (an extra key past the target, then back), held contacts (identical values, flat tangents), and overlap (channels shifted by `drag`). The `.blend` files under `Documents/NinjaDuelBlender` keep the actions on the control rig. They can be opened and refined by hand in the Graph Editor. The export reads whatever is there.

## 11. Character research used so far

- Sasuke: the low, coiled fighting stance with the left lead. Chidori: formed crouched with the right arm low and the left hand gripping the wrist, carried running low with the arm trailing (sometimes cutting the ground), finished as a straight thrust with the whole body behind it. Katon: hand seals, then the inhale (chest rises, a slight lean back), then the projection forward over a wide stance with the hand ring at the mouth.
- Minato: an economical body, the three-pronged kunai in reverse grip, angle changes from the feet, arrival already oriented for the next decision. Rasengan: held in the palm and driven forward by the whole body.

## Sources

- Blender Studio, *Animation Fundamentals* (bouncing, drag and follow-through, jump, walking biped, body mechanics, weight shift): https://studio.blender.org/training/animation-fundamentals/5d69ada9bdd59b8da08f9f92
- Animator Island, *Principles of Animation Physics* (CoG, base of support, contrapposto, arcs): https://www.animatorisland.com/principles-of-animation-physics-part-4/
- AnimSchool, *The Key Poses of a Run Cycle*: https://blog.animschool.edu/?p=634
- Animation Mentor, *Animate a jump and land*: https://www.animationmentor.com/blog/tutorial-animate-a-jump-and-land/
- D. Bollo, *High Performance Animation in Gears of War 4*, SIGGRAPH 2017 (inertialization): https://history.siggraph.org/wp-content/uploads/2022/09/2017-Talks-Bollo_High-Performance-Animation-in-Gears-of-War-4.pdf
- *Biomechanics of sprint running* (trunk lean in acceleration, arm action): https://en.wikipedia.org/wiki/Biomechanics_of_sprint_running
- Dos'Santos et al. 2021, penultimate-contact braking in cutting: https://pmc.ncbi.nlm.nih.gov/articles/PMC8363537
- *Common errors in basic kicks: roundhouse kick* (pivot, chamber, retraction): https://stadionbooks.com/errors-in-basic-kicks-roundhouse-kick/
- Proximal-to-distal sequencing of straight punches (NTNU, Sports Biomechanics 2017): https://scholar.lib.ntnu.edu.tw/en/publications/kinematic-analysis-of-proximal-to-distal-and-simultaneous-motion-/
- Student work notes on attack combos (weight through the chain, staggered settles): https://yufeizheng.myblog.arts.ac.uk/?p=977
