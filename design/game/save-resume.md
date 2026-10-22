# Local workshop save/resume

Prepared: 2026-10-22

[Game design](../../GAME_DESIGN.md) · [Prototype plan](foot-prototype-plan.md) · [Playable workshop](../../game/workshop/README.md)

The user accepted the current workshop playtest after the pickup-only cached outlines, performance fixes and broad yellow workpiece discovery refinements: “ok im happy with the current playtest!” The next request, “Plan and implement saving then!”, authorizes this increment. Keep the accepted collection, preparation, supported-foot and installation loop intact while making a longer session resumable.

**Status:** implemented and verified headlessly for the default supported-foot pitch workshop. All 28 regression suites pass with unchanged code/asset fingerprints, including 430 save-specific checks. No new rendered review or human playtest of saving is claimed.

## Scope and player flow

Use one local slot at `user://workshop-save.json`. The project uses the normal Godot application name **Gundam Build Simulator**, without a custom user directory. On macOS the default location is `~/Library/Application Support/Godot/app_userdata/Gundam Build Simulator/workshop-save.json`.

Autosave every 30 seconds of active play, on pause and on quit. Loading at startup restores into the pause menu, with **Resume** as the primary action. Equipment remains paused until play resumes. Opening the manual browser also pauses play through the existing pause behavior.

The pause menu provides **Save**, **Reload save**, **New workshop** and **Save & quit**. Reload requires confirmation because changes since the last save will be lost. New workshop requires confirmation that it replaces the current saved workshop. Resume cancels a pending confirmation. Status text reports the last save/resume or an error. If saving on quit fails, retain the running session and offer the explicit **Quit without saving** action.

Only the default supported-foot workshop uses the normal slot. Headless tests, automated scenarios, review/capture paths and legacy CLI scenarios remain session-only. They must not read or write the human profile. Persistence tests opt into isolated temporary paths and control automatic saving explicitly.

## Snapshot contract

Save authoritative state and rebuild derived presentation from it. Do not serialize the scene tree or duplicate physical identities to recreate visible objects.

| State | Required preservation |
| --- | --- |
| Assembly model | Every physical item's identity, type, location and owner; actual slot occupants and parent/child identities; independent assembly locations and build histories |
| Pockets | All ten pocket types, their item identities/counts and selected pocket |
| World objects | Loose and held component/assembly transforms, linear/angular velocities and carrying state |
| Preparation | Station transforms/rotation, actual occupants and active build |
| Supported foot | Current working/rail position, destination and motion state; mounted children remain attached to their actual parent throughout resume |
| Player | Position/orientation, velocity, camera pitch/height, zoom and crouch state |
| Manuals | Selected assembly, remembered pages, manual visibility and Suggested only filter |

Completion, mesh visibility, collisions, storage counts, previews and manual progress follow the restored model. Mounted children are reconstructed from actual ownership, rather than inferred from the currently selected manual or original receiving suggestion. Undo must continue to return the same physical identities after a reload.

## Storage and recovery

Version 1 uses a JSON envelope with a save timestamp, payload checksum and fingerprint of the recipes, scenario, supported-world version and source mesh. Write to a temporary sibling file, then atomically replace the primary. Keep the previous valid primary as `workshop-save.json.bak`; a damaged primary must not overwrite a good backup during recovery or a confirmed reset.

Validate the entire candidate before replacing any live model or world state: envelope/version/fingerprint/checksum, exact identities and fields, types and finite transforms/velocities, pocket capacity, ownership and slot compatibility, prerequisite/history consistency, station occupancy and supported-fixture state. A rejected load leaves the existing live session untouched.

If the primary is corrupt and the compatible backup is valid, recover the backup and report that recovery. Unsupported/newer versions or changed content are protected from automatic overwrite and fallback that would silently downgrade them. If no usable snapshot remains, keep the session open with saving blocked until the player explicitly confirms New workshop. A write failure leaves the current workshop available and reports the error; quitting without a successful save requires the explicit discard action.

No schema migration, cloud synchronization, account integration or multiple named slots are included. A future content revision needs an explicit compatibility/migration decision rather than assuming that equal-looking meshes imply compatible saved ownership.

## Implementation boundaries

| File | Responsibility |
| --- | --- |
| `game/workshop/scripts/save_store.gd` | Versioned JSON envelope, checksum, size/depth limits, atomic replacement and backup file operations |
| `game/workshop/scripts/save_model.gd` | Capture and detached validation of assembly identities, locations, ownership, pockets and history |
| `game/workshop/scripts/workshop_save.gd` | Scenario/content fingerprint, world snapshot validation/restoration, autosave, startup recovery and quit behavior |
| `game/workshop/scripts/workshop.gd` | Coordinator lifecycle, pause/reset integration and reconstruction of live workshop objects |
| `game/workshop/scripts/hud.gd` | Status, Save/Reload/New workshop confirmations and explicit quit-without-saving recovery |

## Validation matrix

Run these without opening a product window and use temporary directories for every save fixture. Existing construction, carrying and supported-foot regressions remain relevant; a serialized dictionary round trip alone is insufficient.

| Check | Evidence required |
| --- | --- |
| Store round trip | Version, fingerprint and checksum accepted; valid JSON numbers survive normalization; primary and last-good backup remain readable |
| Invalid input | Malformed/truncated JSON, bad checksum, unknown version/content, unexpected fields, non-finite or invalid poses and invalid identities are rejected without partial live replacement |
| Ownership and history | Unfinished builds and pockets restore exactly; real mounted child identities and retention remain intact; subsequent parent/child undo preserves inventory and constraints |
| Physical state | Loose and held objects, stations and player pose/view restore; no duplicate bodies or stale carried roots remain after repeated reloads |
| Equipment in motion | Save during supported rotation and rail movement; restore current and target state into pause, resume to the same endpoint, and keep mounted children aligned |
| Manual state | Selected build/page, remembered pages, visibility and suggestion filter survive interruption independently of station occupancy |
| Recovery | Corrupt primary restores compatible backup; incompatible/newer saves remain protected; confirmed New workshop replaces the slot while preserving the last good backup |
| Failure and menu | Failed write keeps the session open; quit exposes explicit discard; reload/new-workshop confirmations cancel on Resume; restoration selects Resume |
| Triggers and isolation | Active-play timer, pause and quit save; headless/test/capture/legacy scenarios leave the normal human profile untouched |

## Verification record — 2026-10-22

`python3 game/workshop/tools/run_regressions.py` passed all 28 suites on Godot 4.7.2, with unchanged inputs. The save model passed 151 checks, storage passed 27, and the native workshop save/resume suite passed 252. The existing assembly, manual, carrying, outline, geometry, jump, supported-fixture and desktop scenarios also passed. Logs and fingerprints are retained locally in [results.json](../../game/workshop/verification/regressions-20261022T053553.860019Z/results.json); verification artifacts are ignored by Git.

The scene suite exercises three simultaneous unfinished builds, a fresh-scene resume, both kinds of carrying, loose body motion, player/camera and manual state, mounted rotation, full-foot dispatch and return, all 135 physical identities, native physics attachment through movement, continued parent/child undo, backup recovery, rejected loads, failed quit/window-close handling and browser/menu lifecycle. Headless layout assertions check that the pause card and controls fit the 1440×900 viewport. No product windows were opened, and persistence fixtures used temporary files.

A later human session should assess whether reopening restores a comfortable view and clear sense of what to do next; automated correctness does not establish that feel.
