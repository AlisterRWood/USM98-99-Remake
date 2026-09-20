# USM 98-99 Native Remake — Living Build Plan

Last reviewed: 2026-09-20

This is the persistent resume file for the reconstruction. It is a delivery plan, not a claim of original-algorithm parity. The per-topic audit evidence remains in `docs/audit/implementation-progress.json`; this file records sequencing, ownership, gates, and the next safe place to resume.

## How every agent uses this file

Before editing:

1. Read `AGENTS.md`, `coordination/WORKFLOW.md`, this file, and the source-of-truth audit document for the chosen area.
2. Choose one unblocked work item and update the current checkpoint below with the item, owner, files, and acceptance gate.
3. Claim every file before editing. Keep one writer on hotspot files.
4. Implement core behaviour first, then wire the UI. Add or update a `USMVerify` scenario for each new behaviour.

After editing:

1. Run the relevant focused checks, then `swift run -c release USMVerify`.
2. Run `./tools/build-app.sh` when app/UI or packaged-resource code changed.
3. Update this file: status, evidence, tests, unresolved risks, and the next checkpoint. Append a dated entry to the change log.
4. Update the matching topic in `docs/audit/implementation-progress.json` when the audit status or evidence changed, and update `progress.md` as required by `AGENTS.md`.
5. Release file claims. Leave the working tree and this plan understandable to the next agent.

Status vocabulary: `queued`, `active`, `blocked`, `done`, and `reconstructed / needs calibration`. “Done” means implemented and verified against the project acceptance gate; it does not mean historically identical.

## Current checkpoint

- Status: `active`
- Phase: 6 — tactics and match presentation
- Next work item: audit and stabilise live-match ball boundaries and restart ownership; touchline exits, goal-line misses, corners, goal kicks, and goalkeeper saves must resolve to distinct legal states before further Phase 6 presentation work.
- Active owner/files: Codex — `Sources/USMCore/LiveMatch.swift`, `Sources/USMCore/MatchRules.swift`, `Tests/USMCoreTests/CareerTests.swift`, `Tests/USMCoreTests/Runner.swift`.
- Acceptance gate: deterministic verifier scenarios cover throw-ins, true goal kicks, corners, and keeper saves; `swift run -c release USMVerify` passes; packaged app build remains successful.
- Status: `done` — out-of-play balls remain visibly outside the field for 0.35 physical seconds, then spawn at the legal restart spot; 54 verifier scenarios pass.
- Phase 0 evidence: `tools/audit_original.py --source WindowsGameFiles --out docs/audit/rebuild-2026-09-20` now produces a dated, separate inventory (6,021 files, 62 help sections, 195 coach candidates, 100 advertiser candidates, and 1,524 message records). Do not overwrite `docs/audit/screen-gaps.json`.
- Remaining Phase 0 limitation: the canonical `.work/original-cd/Executable-English` source is absent, and the equivalence of `WindowsGameFiles/` to that extracted tree still needs provenance confirmation.
- Last verification: `swift run -c release USMVerify` — 53 scenarios, 0 failures.
- Last app build: `./tools/build-app.sh` — successful; existing Command Line Tools framework-search warnings remain harmless.

### 2026-09-20 — Season recap and competition naming slice

- Added a save-compatible end-of-season recap modal with squad player goals/appearance summaries, titles, competition positions, and per-competition prize money before next-season rollover.
- Added historical-era league labels and domestic cup names, plus reconstructed UEFA Champions League, UEFA Cup Winners' Cup, and UEFA Cup qualification rows.
- Archived the recap after rollover and exposed it through the Data competition screen; existing fixture/result and scorer views remain available.
- Verification: `swift run -c release USMVerify` builds and runs 52 scenarios with one pre-existing scoring-calibration failure; `./tools/build-app.sh` completed successfully.

## Delivery phases

### Phase 0 — Evidence and audit reproducibility

- Restore/locate the original source tree and make the read-only audit reproducible.
- Decode `COACH.DAT`, `ADVERT.DAT`, `GAME.TXT`, remaining player fields, and original palette/panel evidence only where offsets and examples support the conclusion.
- Keep unknown or inferred fields explicitly labelled; do not invent historical rules or values.

Gate: the inventory and evidence reports can be regenerated without changing the baseline audit, and every newly decoded field has raw-source examples.

### Phase 1 — Screen foundation and usability

- Complete fixed-screen navigation and context help/tooltips for rooms, stadium objects, and menu actions.
- Finish File/menu flows: new game, descriptive save/load selection, import/export, quit, help, and legacy-save handling.
- Check the reconstructed classic red/chrome/blue/yellow theme at 1100×720 and 1440×900, including modal overlays, footer bars, and keyboard/right-click navigation.
- Remove placeholder destinations and verify all original menu controls have a deliberate destination or an explicitly documented limitation.

Gate: all 62 audited topics route to the intended reconstructed surface, controls do not disappear behind dialogs, and the app build plus 44+ verification scenarios pass.

### Phase 2 — Staff and training

- Verify staff record interpretation before further balancing.
- Complete named coach/scout markets, contracts, assignments, timetable editing, camps, fatigue, morale, workload, and reload/accounting behaviour.

Gate: hire, renew, fire, assign, schedule, camp, rollover, save, and reload scenarios reconcile staff and finance state.

### Phase 3 — Transfers and scouting

- Finish nationality/position/age evidence and player-history depth.
- Complete filters, shortlist, scout reports, youth/potential reports, competitor alerts, AI market activity, negotiation timing/rejection/delegation, sales, free agents, loans, wage splits, and all edge cases.

Gate: every negotiation state survives reload, settlement is atomic, loan returns are scheduled correctly, and no duplicate payment or player ownership is possible.

### Phase 4 — Business and finance

- Complete sponsor and advertising offers, physical-board rendering, ticket demand/history, merchandise/catering assortments, accounts, banking, finance calibration, and printing.

Gate: contract expiry, weekly income, sales margins, attendance, borrowing, and printed/exported summaries reconcile with the ledger after save/reload.

### Phase 5 — Stadium and ground commerce

- Finish multi-placement draft/preview/commit/cancel, corner and height constraints, capacity closures, condition/maintenance, complete building catalogue, dynamic advertising, and visual polish.

Gate: placement decisions are reversible before commit, persisted after reload, obey geometry/capacity rules, and render the selected building/brand consistently in the stadium and match views.

### Phase 6 — Tactics and match presentation

- Complete advanced move/pass/dribble/wait/shoot routines, named libraries, trails, man-marking/arrows, and original set-piece depth.
- Stabilise free-kick, corner, penalty, offside, wall, restart, substitution, foul, card, injury, direct-red, extra-time, and replay flows without visual teleporting.
- Continue camera, player-art, commentary/audio mapping, tunnel, full-time, and saved-replay fidelity work.

Gate: instructions alter play measurably, dead-ball restarts preserve legal ball/player state, offside does not move the ball unexpectedly, replay is deterministic, and match scenarios cover the new rules.

### Phase 7 — Career world and multiplayer

- Complete Europe, extra domestic cups, real-era calendar/deadlines/playoffs, trophies, manager/club/player histories, board/job rules, and messages/newspaper/scrapbook/Sierratext presentation.
- Implement the one currently `not_implemented` audit topic: shared-world alternating 1–8 local managers with coordinated time advance.

Gate: a multi-season career across all supported competitions survives save/reload, history and honours remain consistent, and multiplayer turns cannot advance another manager’s state accidentally.

### Phase 8 — Fidelity and release QA

- Interactively compare every original menu control and audited screen.
- Complete the 1100×720 and 1440×900 layout matrix, audio/visual checks, accessibility/input checks, performance checks, and historical roster validation.

Gate: the checklist is evidence-backed, no known release blocker remains, and any remaining reconstruction limits are documented rather than implied away.

## Prioritised queue

1. Phase 0 source-tree/audit reproducibility blocker.
2. Phase 1 foundation gaps that affect every screen: context help, navigation, file flows, and layout QA.
3. Competition/calendar and transfer data dependencies.
4. Phase 2 staff/training and Phase 3 transfers/scouting.
5. Phase 4 business/finance and Phase 5 stadium.
6. Phase 6 match/tactics stability and presentation depth.
7. Phase 7 histories, communications, and local multiplayer.
8. Phase 8 visual calibration and release QA.

## Workstream ownership

Use the ownership table in `AGENTS.md` §8. In particular, keep one writer at a time on `ContentView.swift`, `ClassicUI.swift`, `Management.swift`, `ClubScreens.swift`, `Simulation.swift`, `Models.swift`, `TacticalScreens.swift`, and other listed hotspots. If a task crosses workstreams, record the handoff in the checkpoint and `progress.md` before editing the second stream.

## Change log

### 2026-09-20 — Initial persistent roadmap

- Consolidated the existing nine parity backlog, eight rebuild phases, and 62-topic audit into an agent-readable delivery sequence.
- Recorded the current 44/44 verification state.
- Recorded the missing `.work/original-cd/Executable-English` source tree as the first reproducibility blocker instead of treating the old audit as freshly verified.
- Established the checkpoint/update protocol for future agents.

### 2026-09-20 — First Phase 0–2 implementation slice

- Made `tools/audit_original.py` accept an explicit source and output directory, including case-insensitive recovered filenames, so evidence can be regenerated without replacing the retained baseline.
- Added dated audit output under `docs/audit/rebuild-2026-09-20` from `WindowsGameFiles/`.
- Added native tooltip descriptions for title-screen actions, File actions, and individual-training controls.
- Added `Career.setIndividualTraining(...)` validation for player ownership, coach employment/speciality, skill range, and intensity range; rewired the training screen to use it.
- Added the `Validated training assignments` verifier scenario.
- Phase 0 is now reproducible with an explicit source, while Phases 1–2 remain active because their deeper fidelity/calibration items are not complete.

### 2026-09-20 — Phase 3 started

- Removed Coach mode from the delivery phases and prioritised queue; it is out of scope for this roadmap.
- Added Player Search filters for the user's first team/reserves and per-skill maximums, complementing the existing minimum filters.
- Advanced the resume checkpoint to transfer/scouting work.

### 2026-09-20 — Phase 3 transfer/scouting slice

- Added competitor-interest alerts to completed scout reports.
- Added optional, save-compatible loan wage-share terms and applied the contribution to both incoming and outgoing loan settlement.
- Expanded AI loan-market offers with fees and 50/75/100% wage-share proposals.
- Updated the per-topic audit tracker for Player Search, Shortlist, Current Negotiations, Loaning Players Out, and Buying Players.
- Added verifier coverage; the next Phase 3 checkpoint is nationality/position evidence and potential calibration.

### 2026-09-20 — Phase 3 settlement and scouting hardening

- Scout potential is now hidden for external players until a completed scout report exists; the reconstructed estimate remains visible for owned players.
- Loan wage contributions are settled weekly, permanent incoming-player wage/contract data is preserved through the loan, and return processing remains save-compatible.
- Final transfer acceptance now rejects expired agreements, stale ownership, duplicate active loans, and terms changed after final review.
- Added verifier coverage; 46 scenarios pass with 0 failures.
- Three read-only review agents were used: Luna for roster evidence, Terra for potential/youth flow, and Astra for transfer settlement risks. No review agent edited the repository.

### 2026-09-20 — Phase 3 roster evidence boundary

- Audited the accepted 187-byte player records and documented the supported offsets: names, team index, skills, and the plausible date bytes.
- No verified nationality or preferred-position encoding was found. The importer continues to label role as skill-derived reconstruction and country as the dataset's club country; no gameplay schema change was justified.
- Acceptance consequence: nationality/position evidence is documented but remains open; the next implementation slice is free-agent handling and negotiation interest/patience.

### 2026-09-20 — Phase 3 negotiation safeguards

- Added expiry and ownership checks to term submission, reply resolution, and transfer extras so stale negotiations cannot be revived.
- Added deterministic player patience limits for repeated counteroffers.
- Prevented borrowed players from being used as exchange players and kept departing-player cleanup atomic.
- Added verifier coverage; 47 scenarios pass with 0 failures.

### 2026-09-20 — Phase 6 match-engine depth slice

- Normalized live tactical-plan lookup so named set-piece states such as `Attacking left corner` are used by the runtime, including the existing goal-kick/free-kick aliases.
- Executed persisted advanced instructions for carriers: Pass can target a selected teammate, while Dribble, Wait, and Shoot alter the carrier decision path with legal fallbacks.
- Added defensive skill weighting to pass interceptions and nearby-pressure penalties to shot accuracy/save difficulty, preserving variance while making shape, tactics, and player quality matter.
- Added an advanced-tactics UI editor for the selected player's action and pass target.
- Added `Advanced tactical instructions and set-piece aliases` verification coverage; 48 scenarios pass and the packaged app builds successfully.
- Remaining risk: the engine still needs richer defensive assignments, injuries/direct reds, extra-time presentation, and broader multi-seed balance calibration before Phase 6 is complete.

### 2026-09-20 — Phase 6 restart and presentation polish

- Saved shots and misses now transition through a real delayed goal-kick restart: attacking players retreat, the goalkeeper pauses, then the restart setup releases the ball.
- Offside is now attached to the travelling pass and whistled only when the ball reaches the receiving point; the defender receives a legal offside restart afterward.
- Reduced card overlay duration to 1.8 seconds and made restart feedback explicitly label offside free kicks.
- Reworked match presentation primitives into sharper pixel-era player/crowd figures with distinct kits, and removed unaccepted sponsor/board fallbacks.
- Audited `ADBOARDS.SPR`: supplied boards contain 28 recoverable tiles, but the supplied hash differs from the recorded CD reference, so they remain documented as supplied assets rather than claimed original-CD artwork.
- Added verifier coverage; 49 scenarios pass and the signed app builds successfully.

### 2026-09-20 — Advertising capacity and sponsor-board alignment

- Added a save-compatible limit of 10 active pitch-board contracts, matching the visible matchday board capacity.
- Acceptance now fails while all board slots are occupied; weekly contract progression expires completed deals and makes slots available again.
- Updated the Advertising screen and business-room LED state to show active capacity and prevent misleading acceptance affordances.
- Rotated the sponsor panel overlay by 4.2° so the company name follows the angled physical board in the generated business-room artwork.
- Added `Advertising board capacity and expiry` verifier coverage; 50 scenarios pass and the signed app builds successfully.

### 2026-09-20 — Match scoring balance and instant-result parity

- Increased shot willingness for midfielders and defenders while retaining role-based accuracy differences, so goals are not concentrated exclusively among forwards.
- Rebalanced goalkeeper save probability and shot selection to reduce overly frequent 0-0/1-0 outcomes while preserving tactical and random variation.
- Confirmed managed Instant Result and Instant Remainder continue through the same `LiveMatch.finishInstantly()` engine used by watched matches.
- Added `Scoring roles and instant engine parity` verification coverage; 51 scenarios pass and the signed app builds successfully.
- Remaining risk: aggregate unmanaged fixtures still use their existing simulation path and should be unified only as a separate, explicitly scoped follow-up.

### 2026-09-20 — Defensive shape, set-piece routines, and replay calibration

- Added formation-aware defensive compactness, ranked pressing/cover roles, retreat behavior during goalkeeper distribution, and mentality/tackling/offside-trap effects in the live engine.
- Added save-compatible explicit corner, free-kick, and goal-kick routine variants with deterministic fallbacks for older careers.
- Added replay autoplay, pause, previous/next frame controls, timeline clock/snapshot feedback, correct half-state rendering, and suppression of stale live overlays during replay.
- Added `Defensive shape responds to formation and tactics` verifier coverage; the authoritative suite now passes 52 scenarios and the signed app builds successfully.
- Remaining risk: injuries/direct reds, extra-time presentation, and broader match-audio calibration remain in the Phase 6 backlog.

### 2026-09-20 — Pixel match-player presentation slice

- Replaced smooth miniature player figures in `MatchView.swift` with crisp block-pixel silhouettes inspired by the supplied 1998 match screenshot.
- Added deterministic running stride animation, passing and shooting poses, sliding tackles, directional facing cues, and runtime home/away/keeper kit colours.
- Kept the renderer native to Canvas so replay and save state remain deterministic without a new external dependency.
- Verification: `swift run -c release USMVerify` — 53 scenarios, 0 failures; `./tools/build-app.sh` completed successfully.

### 2026-09-20 — Offside frequency calibration

- Added a clear offside-line margin against normal positional movement noise; deliberate offside-trap tactics retain a tighter margin and remain meaningful.
- Continued delayed whistle/restart handling unchanged: the pass travels and is resolved at the receiver before the offside restart is shown.
- Added `Offside requires clear line margin` verifier coverage; the authoritative suite now passes 53 scenarios.

### 2026-09-20 — Side-on running sprite frames

- Added explicit left/right profile silhouettes for the common running state in `MatchView.swift`, including a four-frame arm-and-leg cycle, directional head/chest orientation, sponsor strip, socks, and recolourable kit.
- Passing, shooting, and tackling remain separate presentation poses; the running profile is selected only while players are in motion.
- Acceptance gate: `USMVerify`, signed app build, and `agent-check.sh`; presentation remains reconstructed Canvas geometry and needs interactive calibration at 1100×720 and 1440×900.

### 2026-09-20 — Ball bounds and visible out-of-play delay

- Audited `LiveMatch` and `MatchRules`: passes can now leave through the touchline, wide shots leave through the goal line, and keeper saves no longer become goal kicks.
- Added distinct throw-in, true goal-kick, corner, and keeper-possession paths. Out-of-play balls remain at their outside target for 0.35 physical seconds before the restart is placed, including save-compatible pending restart state.
- Added `Ball boundaries and restart ownership` verifier coverage; `USMVerify` now passes 54 scenarios with 0 failures.

### 2026-09-20 — Goalkeeper parry rebounds

- On-target shots now distinguish corner deflections, keeper parries, held saves, and goals. A parry leaves the ball live in front of the keeper for an attacking follow-up rather than creating a restart.
- Added deterministic verifier coverage to the ball-boundary scenario; `USMVerify` remains at 54 scenarios with 0 failures.

### 2026-09-20 — Side-running visual QA correction

- Visual QA of the packaged match screen showed the first profile pass was too symmetrical at the rendered scale.
- Increased the profile silhouette's asymmetry and stride width so the running state visibly faces left or right instead of reading as a front-facing idle block.
- Acceptance gate: rerun `USMVerify`, signed app build, and `agent-check.sh`.

### 2026-09-20 — Supplied sprite atlas integration

- Added the supplied 8×6 player atlas to app resources with transparent background cleanup and red/blue/gold runtime kit variants.
- Match rendering now crops real atlas frames for standing, running, kick, and tackle states; selected running frames fall through to the explicit side-profile renderer for left/right movement.
- Acceptance gate: `USMVerify`, signed app build, and `agent-check.sh`; the asset remains a reconstructed reference-based visual, not an original game extraction.

### 2026-09-20 — Original title menu layout and background

- Reworked `TitleScreen` so Manager, Coach, and Load Game appear as three horizontal choices inside a single red/chrome panel, matching the supplied original-menu composition.
- Added `Sources/USMApp/Resources/MainMenuBackground.png`, a cleaned background plate derived from the supplied screenshot with the popup and shadow removed.
- Verification: `swift run -c release USMVerify` — 54 scenarios, 0 failures; packaged app build pending.
