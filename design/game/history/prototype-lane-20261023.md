# Base game and prototype lane, 2026-10-23 (archived 2026-10-25)

*Moved verbatim from [GAME_DESIGN.md](../../../GAME_DESIGN.md) when the workshop became one robot game.*


**Superseded on 2026-10-24:** the user asked for one launch command, with the base
foot build combined with M3. `./play.command` now opens the robot game: the
pads and pitch actuator are built in the hangar on a turning fixture at the left
foot's store, and the robot workshop continues in the same session.
`--stage=<name>` starts later. Like M3, the robot game has no saves yet. The
foot-only workshop below remains the `--profile=foot` development profile with
its save. The rest of this section is the 2026-10-23 decision as recorded.

The user decided that default `./play.command` launches only the supported-foot
workshop: the pads, the pitch actuator and its save. The actuator work is the
base game, and the detailed foot build continues there after the end-to-end
workflow has been outlined. The upright-hoist expanded workshop and the M1
layout trial are retired. Their saves (`user://leg-workshop-save.json`, M1
slots) are no longer read.

The M1–M4 milestones are a prototype lane, not a second game. Each trial runs
as a scenario profile on shared feature modules: layout data, equipment
(fixture, rail, lifts, crane, shelf), a single hand arbiter, motion sweeps and
a profile-parameterised session codec. The learnings and modules from M1–M4
will later be folded back into the base game and the trial profiles retired.
Reintegration should mean adding equipment and content to the foot profile, not
porting milestone-specific classes. The consolidation was intended to be
behaviour-neutral, and foot saves keep their recorded fingerprint.

The current prototype lane exposes the bounded M2 retaining-half and crane
examples, with supplied construction and independent saves. The complete
leg-to-robot M3 journey was authorized on 2026-10-23, with a prepared complete foot
at dispatch and player construction of the remaining structural leg. Its
[implementation and acceptance ledger](leg-workshop-m3-plan.md)
tracks the supported handoff, full construction, retention and holder release.
On 2026-10-24 the user removed full reverse-sequence verification from M3;
existing supported undo remains for correcting mistakes.
Shared assembly projection now handles heel hardware alongside other components;
the retained single/two-pad profiles verify that earlier loop. Architecture
checks do not establish player acceptance. On 2026-10-23 the user accepted the
revised M2 playtest: “m2 plays great. please commit.” This authorizes the
consolidation commit. The later “Implement the plan” request authorizes M3;
on 2026-10-24 the user described M3 as largely satisfying and requested better
measurement planning before expanding the workshop.

