Original prompt: Update the business-office image and interaction so advertising offers open from the top LED board, remove the separate advertising poster, show a blank sponsor window when no shirt sponsor exists, and show the shirt sponsor's company mark when a sponsor is active.

## 2026-09-19

- Replaced `Sources/USMApp/Resources/Rooms/business-office.png` with a cleaned storefront image: removed the far-right advertising placard and replaced the Lotus poster with a blank framed sponsor panel.
- Moved the Business Office advertising hotspot onto the LED sign and renamed it `Advertising LED board`.
- Added runtime commercial overlays in `Sources/USMApp/Rooms.swift`: a pulsing LED indicator when advertising offers are available and a sponsor mark on the window only when an accepted `Club sponsor` deal exists.
- Verified with the rebuilt app: the LED opens Advertising, and an accepted Samsung sponsor renders on the window board. With no accepted club-sponsor deal, the base asset leaves the panel blank.
- `swift build` and `./tools/build-app.sh` completed successfully; only existing Command Line Tools framework search-path warnings were reported.

TODO: none for the requested storefront behavior.

## 2026-09-19

- Corrected stadium stand orientation in `Sources/USMApp/GroundScene.swift` with an explicit facing map for all four sides and four corners; each stand's rear now points away from the pitch.
- Locked the editable ground's camera to its fixed isometric view: dragging no longer orbits, while scroll-wheel and pinch zoom remain available. Updated the on-screen guidance accordingly.
- Verified with `swift test` (compiles successfully; the package currently exposes no discoverable tests) and `./tools/build-app.sh` (production app rebuilt successfully).

TODO: none for the stadium orientation and zoom-only controls.

## 2026-09-20

- Updated `tools/make-icon.swift` to generate the original red shield treatment with white USM and 98/99 lettering.
- Regenerated `Sources/USMApp/Resources/AppIcon.icns` and the local `dist/AppIcon.iconset` previews, then rebuilt the signed app.
- Verified the generated icon visually and confirmed the app bundle contains the regenerated ICNS.

- Synced the earlier match-engine and match-view changes from `USM98-99`, including calibrated scoring/save chances, the stadium return after full time, the original-style match controls, and the scoring-calibration verifier scenario.
## 2026-09-20

- Added the multi-agent coordination system: shared cross-worktree file claims, ownership map, workflow/handoff protocol, PR template, CODEOWNERS, macOS CI verification, and `tools/agent-check.sh`.
- Added repository hygiene rules for generated build output and binary assets.
- Smoke-tested claim collision/release and protected-branch rejection.
- Verification: `swift run -c release USMVerify` — 43 scenarios, 0 failures.

## 2026-09-20

- Added `BUILDING.md` with fresh-clone requirements, verifier/build commands, clean rebuild steps, optional asset-import guidance, and troubleshooting.
- Updated the README so normal builders do not try to access excluded original-game source dumps.

## 2026-09-20

- Implemented the first Phase 0–2 slice from `PROJECT_PLAN.md`.
- `tools/audit_original.py` now accepts explicit source/output paths and successfully generated a dated audit from `WindowsGameFiles/` without overwriting the baseline reports.
- Added contextual action tooltips to the title/File/training surfaces.
- Added validated core individual-training assignment mutations and a verifier scenario; `swift run -c release USMVerify` passes 45 scenarios with 0 failures.
- Removed Coach mode from the remaining delivery phases and prioritisation; it is explicitly out of scope for this roadmap.
- Started Phase 3 by adding first-team/reserve filters and per-skill maximum filters to Player Search, alongside the existing minimum filters.
- Added Phase 3 competitor-interest scout alerts, configurable loan wage contributions, and AI loan offers with fees and wage-share terms.
- Used three read-only review agents with different models to audit roster evidence, potential/youth visibility, and transfer edge cases. Integrated the resulting scout-gated potential display, weekly loan settlement, preserved loan contracts, and stale/duplicate transfer guards.
- Verification: `swift run -c release USMVerify` — 46 scenarios, 0 failures; `./tools/build-app.sh` completed successfully.

## 2026-09-20

- Audited the fixed 187-byte player records for Phase 3 nationality/position work.
- Documented the supported name, club-index, skill, and plausible birth-date offsets in `docs/RECONSTRUCTION.md`.
- Confirmed that nationality and preferred-position mappings remain unverified; no guessed gameplay fields or filters were added. The next Phase 3 implementation slice is free-agent handling and negotiation interest/patience.

## 2026-09-20

- Used three fresh read-only agents with different models to review roster evidence, free-agent design, and negotiation patience.
- Implemented stale-offer/ownership checks, bounded counteroffer patience, and borrowed-player exchange protection.
- Verification after this slice: `swift run -c release USMVerify` — 47 scenarios, 0 failures.

## 2026-09-20

- Started the Phase 6 match-engine depth slice after three independent audits using `gpt-6-astra`, `gpt-5.6-terra`, and `gpt-5.6-luna` routing.
- Implemented runtime execution for persisted advanced tactical actions (pass with target, dribble, wait, shoot), normalized named set-piece plan keys, and kept formation/custom-position plans authoritative where configured.
- Added pressure and defensive-skill effects to interception, shot accuracy, and save difficulty so tactics and player quality influence outcomes without removing random variance.
- Added action/target controls to the Advanced Tactics screen and a verifier scenario for set-piece aliases and targeted passing.
- Verification: `swift run -c release USMVerify` — 48 scenarios, 0 failures; `./tools/build-app.sh` completed successfully.

## 2026-09-20

- Fixed goalkeeper save/miss loops by adding an explicit delayed goal-kick state: opponents retreat, the keeper pauses, then `SetPieceRestart` controls the distribution.
- Fixed premature offside whistles: flagged passes now travel before the whistle, allow normal interception, and then create an offside restart at the target area.
- Reduced yellow/red card overlay duration to 1.8 seconds and made the match banner say `OFFSIDE · FREE KICK` during the restart.
- Improved the live pitch visuals with pixel-snapped player silhouettes, two-tone kits, heads/hair/limbs, pixel crowd figures, and neutral unbranded boards when no accepted pitch-board contract exists. Accepted board brands still come from active contracts.
- Audited supplied `ADBOARDS.SPR` and confirmed 28 recoverable board tiles, while documenting that its hash differs from the recorded CD reference; no unsupported original-art claim was made.
- Used three read-only agents with different models: Luna for match-state auditing, Terra for visual/presentation auditing, and Astra for original asset structure/provenance.
- Verification: `swift run -c release USMVerify` — 49 scenarios, 0 failures; `./tools/build-app.sh` completed successfully.

## 2026-09-20

- Added a maximum of 10 active pitch-board advertising contracts. Further board offers are blocked until an existing contract expires.
- Kept expiry save-compatible through the existing weekly `remaining` countdown and updated the commercial screen/room indicator with the active `n/10` count.
- Rotated the sponsorship-window overlay by 4.2° to match the slanted board perspective in the room artwork.
- Added a commercial verifier scenario covering capacity, rejection while full, expiry, and accepting a newly freed slot.
- Verification: `swift run -c release USMVerify` — 50 scenarios, 0 failures; `./tools/build-app.sh` completed successfully.

## 2026-09-20

- Rebalanced live scoring so shot selection is less conservative and 0-0/1-0 results are less dominant, while keeping defensive quality and randomness meaningful.
- Increased midfielder and defender shot participation with role-sensitive accuracy rather than making all positions finish like forwards.
- Confirmed managed Instant Result and Instant Remainder use the same `LiveMatch` engine as watched matches, and added a parity regression scenario.
- Used two read-only agents with different models: Luna (`gpt-5.6-luna`) for scoring calibration and Terra (`gpt-5.6-terra`) for instant-result path auditing.
- Verification: `swift run -c release USMVerify` — 51 scenarios, 0 failures; `./tools/build-app.sh` completed successfully.

## 2026-09-20

- Added the End of Season modal and archive: managed players' season summaries, titles, competition finish, prize money, and total award are shown before rollover and retained in the save.
- Replaced generic division labels with reconstructed 1998–99-era names such as FA Carling Premiership, Nationwide Football League First Division, Bundesliga, Serie A, Primera División, and Eredivisie.
- Added domestic cup naming plus UEFA Champions League, UEFA Cup Winners' Cup, and UEFA Cup qualification records; Data now has a Season recap view alongside existing tables, results, fixtures, scorers, trophies, and form.
- Historical naming references checked against UEFA's 1998/99 competition pages and DFB's 1998/99 competition data; prize formulas and European qualification are reconstructed game rules, not claims of original algorithm parity.
- Verification: `swift run -c release USMVerify` built and ran 52 scenarios with 0 failures; `./tools/build-app.sh` completed successfully.

## 2026-09-20

- Added richer defensive shape: formation-dependent compactness, ranked pressing and cover roles, retreat during keeper distribution, and mentality/tackling/offside-trap influence.
- Added explicit persisted set-piece routine variants for near/far/short corners, direct/whipped/layoff free kicks, and short/wide/long goal kicks, with legacy-safe defaults.
- Calibrated replay presentation with autoplay/pause, timeline and snapshot feedback, previous/next frame controls, synchronized clock/score state, and clean replay overlay state.
- Used three implementation agents with different models: Luna for defensive shape, Terra for set-piece routines, and Luna for replay/presentation.
- Verification: `swift run -c release USMVerify` — 52 scenarios, 0 failures; `./tools/build-app.sh` completed successfully.

## 2026-09-20

- Reduced unrealistic offside calls by requiring a clear margin beyond the second-last outfield defender, while preserving a tighter threshold for deliberate offside traps.
- Kept the delayed pass-flight whistle and legal offside restart behavior unchanged.
- Added `Offside requires clear line margin` coverage.
- Verification: `swift run -c release USMVerify` — 53 scenarios, 0 failures.

## 2026-09-20

- Reworked match players into crisp block-pixel silhouettes matching the supplied 1998 match reference rather than smooth modern miniatures.
- Added deterministic running stride frames, passing/shooting poses, sliding tackles, directional facing cues, and recolourable home/away/keeper kit bodies.
- The generated visual reference guided the style, while the shipped renderer remains native Canvas geometry so team colours and replay state stay deterministic.
- Verification: `swift run -c release USMVerify` — 53 scenarios, 0 failures; `./tools/build-app.sh` completed successfully.

## 2026-09-20

- Replaced the running player's mirrored front silhouette with explicit side-on profile frames facing left or right.
- Added a four-frame arm-and-leg cycle keyed to match time, with profile head, chest, kit, sponsor strip, socks, and directional stride; passing, shooting, and tackling poses remain available.
- Verification: `swift run -c release USMVerify` — 53 scenarios, 0 failures; `./tools/build-app.sh` and `./tools/agent-check.sh` completed successfully.

## 2026-09-20

- Reworked the side-running frames after visual QA showed they still read as front-facing at match scale.
- Profile sprites now have an asymmetric head and nose, single-profile chest, offset arms, and a wider four-frame stride so left/right travel is obvious in the live pitch.
- Verification: `swift run -c release USMVerify` — 54 scenarios, 0 failures; `./tools/build-app.sh` and `./tools/agent-check.sh` completed successfully.

## 2026-09-20

- Integrated the supplied 8×6 character sprite atlas into the live match Canvas instead of using procedural figures for the main player states.
- Normalized the baked checkerboard into alpha, generated red/blue/gold kit variants, and mapped the atlas rows to standing, running, kicking, and tackling poses.
- Retained explicit side-profile running frames as a complementary movement pass so the engine has both the supplied front/back artwork and side-on travel.
- Verification: `swift run -c release USMVerify` — 54 scenarios, 0 failures; `./tools/build-app.sh` and `./tools/agent-check.sh` completed successfully.
### 2026-09-20 — Match ball bounds and visible restart delay

- Audited and corrected live match restart ownership in `Sources/USMCore/LiveMatch.swift` and `Sources/USMCore/MatchRules.swift`.
- Added touchline exits and throw-ins, true goal-line misses and goal kicks, and goalkeeper saves that retain keeper possession instead of triggering a goal kick.
- Out-of-play balls now remain visibly outside the pitch for 0.35 physical seconds before spawning at the legal restart spot; pending restart state is Codable/save-compatible.
- Added `Ball boundaries and restart ownership` to `USMVerify`; 54 scenarios pass with 0 failures.

### 2026-09-20 — Goalkeeper parry rebounds

- Added a live rebound outcome for on-target shots in `LiveMatch`: the keeper can parry the ball loose instead of holding it.
- The rebound clears keeper possession/restart state and places the ball in front of goal so attackers can contest the follow-up.
- Expanded the ball-boundary verifier coverage; 54 scenarios pass with 0 failures.

## 2026-09-20

- Reworked the title screen into the original-style horizontal Manager / Coach / Load Game menu panel.
- Added the cleaned supplied-reference background at `Sources/USMApp/Resources/MainMenuBackground.png`, with the popup and shadow removed while retaining the football scene and Version 2.00 label.
- Verification: `swift run -c release USMVerify` — 54 scenarios, 0 failures; packaged app build pending.

## 2026-09-21 — Match visual repair

- Replaced the malformed sprite atlas/fallback mix with consistent pixel figures: true displacement determines front/back/left/right facing and leg stride; stationary players retain facing without cycling their legs.
- Rebuilt goal depth/net mesh, denser staggered cheering spectators, and roofed benches with seated substitutes and standing coaches; expanded the camera/runoff area without obscuring boards.
- Extended wide-shot/pass travel beyond the lines; preserve legal restart spots through reload and substitute replacement, with explicit throw-in/goal-kick/corner ownership.
- Files: `Sources/USMApp/MatchView.swift`, `Sources/USMCore/LiveMatch.swift`, `Sources/USMCore/MatchRules.swift`, `Tests/USMCoreTests/CareerTests.swift`, `Tests/USMCoreTests/Runner.swift`, `PROJECT_PLAN.md`, `AGENTS.md`, `docs/audit/implementation-progress.json`.
- Validation: 56 verifier scenarios; isolated native-renderer directional/idle/four-frame assertions and visual inspection at two pitch sizes/both goal cameras. Final release/signature and coordination gates recorded in PROJECT_PLAN.md. Main save and currently paused game left untouched.
- Limitation: renderer QA is not full live-window interaction verification; graphics remain reconstructed.

## 2026-09-21 — Follow-up match camera, pacing and tactics

- Tightened camera pan stops and increased pitch/player scale by approximately 19%; extended ball-runoff physics remains unchanged.
- Cards/goals now stop the simulation immediately and use 1.8/speed and 2.4/speed seconds respectively; manual pauses persist, and fast-step batches cannot continue behind overlays.
- Fixed offside detection to count the keeper/use the defending trap and keep default support onside. Goal-kick setup now uses formation rather than the free-kick wall branch.
- Added clear pre-match/in-match captain and set-piece taker selectors. Separate QA app confirmed visible controls, selections, Apply and persistence in active-match/career tactics.
- Files: App.swift, MatchView.swift, TacticalScreens.swift, LiveMatch.swift, MatchRules.swift, new MatchPlayback.swift and MatchPlaybackTests.swift, CareerTests.swift/Runner.swift, and progress/plan/audit docs.
- Verification: five new scenarios (61 total); focused popup/restart/taker tests and renderer checks pass. Post-change six-seed sample: 4 offsides/1,035 passes; earlier 48-seed baseline: 649/7,669. Samples are not matched. Full `USMVerify`: 61 scenarios, 0 failures; release app build, strict signature, coordination and diff checks pass. Main game/save untouched.
