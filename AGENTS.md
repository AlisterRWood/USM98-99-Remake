# USM 98-99 Native Remake — AI Agent Coordination & Status

Living document for humans and AI agents. It consolidates **current progress**, the **outstanding backlog**, **file ownership**, and **working conventions** so multiple agents can work in parallel without conflicting. Keep it in sync after every piece of work.

Last verified build state: **2026-09-21** — `swift run -c release USMVerify` → **56 scenarios, 0 failures**.

# Agent instructions

## Model routing

Use subagents proactively.

For each subtask, use the lowest-cost currently available model that can reliably complete the work. Do not hard-code model names or assume the parent model is the correct model.

Escalate to stronger models only when complexity, ambiguity, repeated failures, architecture decisions, or risk justify the additional cost.

For complex tasks:
1. Determine the best implementation approach.
2. Break the work into independent subtasks.
3. Delegate each subtask to the cheapest capable model.
4. Run independent work in parallel where useful.
5. Review and integrate results.
6. Build and test before considering the task complete.

## Project-specific routing

This is a SwiftUI game.

Prefer inexpensive agents for:
- repository exploration
- locating Swift types/views
- straightforward SwiftUI implementation
- repetitive UI work
- test creation
- documentation
- asset/reference investigation

Escalate when necessary for:
- game architecture
- simulation architecture
- complex state management
- concurrency problems
- difficult SwiftUI bugs
- persistence/data-model changes affecting multiple systems
- major refactoring

Preserve existing architecture and coding conventions.

Do not redesign working systems unless the requested change requires it.

## 1. What this project is

A native **macOS** (SwiftUI + SceneKit) recreation of the 1998 Windows game *Ultimate Soccer Manager 98-99*. Swift 5.9+, macOS 14+, **no Wine/emulation, no web view, no downloaded Swift package dependencies**. It uses recovered original CD data, room art and audio. It is a **reconstruction** — not a decompilation, and **original-algorithm parity is not claimed anywhere**.

- Current app version: **0.3.6** (bundle build 9), ad-hoc signed Apple Silicon build at `dist/Ultimate Soccer Manager.app`.
- Requirement: Apple Command Line Tools or Xcode, Swift 5.9+, Python 3. `unshield` only needed to re-extract the CD cabinet from scratch (do not re-run casually).
- Git is initialised and tracks the project remote. Parallel work uses isolated `codex/*` branches or worktrees, explicit file claims, and pull requests. Read [`coordination/WORKFLOW.md`](coordination/WORKFLOW.md) before editing.

## 2. Build, run, verify (mandatory for every agent before claiming done)

```sh
python3 tools/extract_assets.py    # re-import roster source + refresh CD audio/art (only when data changes)
swift run -c release USMVerify    # authoritative verification suite
./tools/build-app.sh               # release build + ad-hoc codesign -> dist app
open "dist/Ultimate Soccer Manager.app"
```

- Run **`swift run -c release USMVerify`** as the final gate. It uses a dependency-free harness (works with Command Line Tools only).
- Run a subset with `USM_TEST_FILTER=<substring> name`.
- `swift test` compiles but exposes no discoverable tests — do not rely on it.
- Pre-existing harmless `swift build` warnings: Command Line Tools framework search-path warnings.
- Add a new scenario to `Tests/USMCoreTests/Runner.swift` for each new behaviour; keep the total count and the countable claim in sync (docs have drifted: VALIDATION.md says 32/37/40 at various points; the runner currently defines 43).

## 3. Data & runtime facts

| Item | Value |
|---|---|
| Start databases | **Original CD 2.00** (416 clubs, 9,795 players, 15 Oct 1998) and **Mega Update 1.2 (default)** (412 clubs, 9,747 players, to 31 Jan 2001). Each career owns its selected database. |
| Save | `~/Library/Application Support/USM98Native/career.json` — JSON, format version 1, additive optional fields, auto-backup on new career. Export/import supported. Original Windows saves are NOT supported. |
| Audio | 5,583 original CD speech files + music + SFX bundled; manifests in `docs/` (commentary-manifest.json, audio-manifest.json, asset-manifest.json). |
| Bundled database | `Sources/USMApp/Resources/database.json` (written by `tools/extract_assets.py`). |
| Recovered binary formats | `TEAM*.DAT` 671 B/record (name/manager/nickname/stadium/division), `PLAYER*.DAT` 187 B/record (names, club index, 9 skills, inferred birth-year at byte 31). See `docs/RECONSTRUCTION.md` — many fields are **still inferred**, not verified. |

## 4. Architecture and file ownership

Pure game logic lives in **`Sources/USMCore`** (no view-layer imports). All UI/presentation lives in **`Sources/USMApp`**. Never let view code mutate cash/state directly — route through core methods.

Core files:

| File | Responsibility |
|---|---|
| `Models.swift` | Core domain types (clubs, players, offers, tactics) |
| `Simulation.swift` | Weekly advance, fixtures, promotions, rollover, economics |
| `LiveMatch.swift` | Live spatial match engine (watch + instant share this engine) |
| `MatchRules.swift` | Referee/discipline, restarts, lineups, substitutions, rules |
| `Management.swift` | Staff, training, scouting, commerce, negotiations, finance flows |
| `ClubWorld.swift` | Career state, evaluations, private phone, communications |
| `Competitions.swift` + `CompetitionData.swift` | Cups, fixtures, friendlies, competition definitions |
| `Finance.swift` | Ledger, banking, tickets, merchandising accounting |
| `Ground.swift` + `StandDevelopment.swift` | Ground model, plots, projects, stand specs |
| `PlayerLifecycle.swift` | DOB/ageing, development, retirement, youth intake |
| `TacticalPlans.swift` | Formation/position-map persistence |
| `ContractTerms.swift` | Contract/transfer clause types |
| `CommentarySchedule.swift` | Speech scheduling/pacing rules |
| `ClubUsability.swift` | UI-facing helpers (pickup, right-click back) |

App files:

| File | Responsibility |
|---|---|
| `App.swift` | App lifecycle, menus, save store, audio wiring |
| `ContentView.swift` | Navigation shell, room routing, ribbon, club shell |
| `Rooms.swift` | Room artwork + hotspot definitions |
| `ClassicUI.swift` | Shared classic styling (buttons, dialogs, screens, tables) |
| `ClassicDialog.swift` | Skinned dialog/panel components |
| `ClubScreens.swift` + `ClubViews.swift` | Board, forecasts, competitions, communications, opposition |
| `FootballViews.swift` | Training/team-talk/selection assistants |
| `SquadTable.swift` | Compact squad selection table |
| `PlayerRecord.swift` | Player record panel |
| `TransferScreens.swift` | Search, negotiations, own-player market UI |
| `TacticalScreens.swift` | Formation editor + advanced tactics UI |
| `GroundScene.swift` | SceneKit stadium world |
| `GroundManagement.swift` | Stand/estate management editor |
| `Stadium.swift` | Stadium estate screen |
| `MatchView.swift` | Match presentation canvas + controls |
| `FileScreens.swift` | Save/load/import/export |
| `TeletextPanel.swift` | CRT/teletext competition presentation |
| `RightClickBack.swift` | Navigation gesture helpers |

Tools (`tools/`): `extract_assets.py` (importer), `import_commentary.py`, `audit_original.py` (read-only CD inventory + audit outputs), `build-app.sh`, `verify-match-audio.swift`, `make-icon.swift`.

## 5. Current progress snapshot (what is implemented)

Implemented and persisted (details in `docs/IMPLEMENTATION-STATUS.md` — dated 19 Sep 2026, version 0.3):

- **Screen framework:** ruby/chrome title bars, cobalt controls, yellow labels, indigo/teal panels, compact FILE/STAD/BUSI/CHAIR/DATA/TRANS/MNGR/SQUAD/MATCH/HELP ribbon, calendar tile, bounded fixed screens (no outer page scroll).
- **Rooms:** distinct screens for sponsorship, advertising, accounts, tickets, merchandise, catering, scouting, negotiation, medical, opposition, formation, advanced positions; object-specific hotspots; original room artwork (business concourse from the reference, manager/transfer/chairman/data rooms regenerated to original layouts; tunnel artwork; stadium estate).
- **Staff:** named available/employed coaches + scouts, specialty/ability, wages, two-year contracts, hire/renew/fire payoffs, six-coach cap, scout assignments.
- **Training:** editable morning/afternoon timetable with locked match cells, coach/skill/intensity assignments, workload, age-sensitive development, fatigue/injury risk, assistant defaults, paid leisure/intensive camps. Individual training shows coach name/specialty/ability; matching specialties give 1.25× quality.
- **Search/scouting:** full-database pagination (no 100 cap), filters (name, role, country, division, contract/listing, age, value, nine skill minimums), sorting, persistent shortlist, delayed scout reports, player records.
- **Negotiations/transfers:** persistent staged state machine (enquiry → club terms → player terms → final veto), club/player counteroffers, fees/wages/signing/bonuses/exchange/appearance clauses, atomic completion, own-contract renewal, incoming bids on listed players, loans with scheduled return, fast sale (60% of valuation), minimum squad-size and no-sale-during-match protections.
- **Commerce/finance:** separate sponsor and pitch-board/programme contracts with weekly income + expiry; per-item merchandise and catering costs/prices/sales/profit; ticket classes (terrace/seat/cup/friendly/season/box/school); period/season accounts, interest, overdrafts, borrowing, flotation/shareholders, conditional stadium grants.
- **Ground:** fully editable SceneKit stadium — plots, four stand positions + corners, stands (capacity bands, two/three-tier, seats/roof/boxes), construction with capacity closure during works, maintenance/condition, building catalogue (shops/cafés/car park etc.), placement/rotation/movement/demolition, paved surround, fixed isometric camera, surrounding town.
- **Tactics:** captain, set-piece takers, win bonus, offside trap, draggable custom formation, 34 attack/defence situation maps + free-kick maps, copy/paste/reset/undo, named formation library saved in career.
- **Match presentation (2026-09-21):** displacement-driven directional pixel players with frozen idle legs; mesh goals, animated pixel spectators, dugouts/coaches/substitutes, and extended out-of-play flight with saved legal restart locations. Reconstructed; not original-animation parity.
- **Match:** reconstructed live spatial engine (possession, movement, passing, interceptions, shots, saves, goals), tactical action execution, delayed goalkeeper goal-kick distribution with opponent retreat, post-flight offside restarts, fouls, bookings, second-yellow dismissals, suspensions, corners/free kicks/penalties with visible setup + walls, held-ball takers, queued dead-ball substitutions, replay from recorded frames, 1×–16× speed, save/resume mid-match, full-time report, original CD commentary/player-name speech with pacing rules, whistle effects.
- **Career/world:** seeded round-robin leagues across 7 countries, domestic knockout cups with draws/byes/shoot-outs, trophies, friendlies, promotion/relegation, rollover, board evaluations + history graphs, dismissal/job applications, Coach-mode financial delegation, fictional private phone (rig/bung/bet) with consequences, message folders (email/voicemail/newspaper), scrapbook, native save slots + import/export + club-summary printing.
- **Player lifecycle (0.3.1):** imported/estimated DOB, annual ageing at 1 August, individual development ceilings/profiles, training/appearance growth, late-career decline, retirement, guaranteed minimum-20-squad youth intake at rollover with unique generated IDs.

## 6. Fidelity status — the single source of truth

- The baseline audit (unchanged, in `docs/audit/screen-gaps.json`) found **42 partially represented and 20 missing** across all **62 non-empty** original CD help topics.
- `docs/audit/implementation-progress.json` tracks all 62 topics: implemented work, remaining work, and evidence file paths. **No topic is certified as original-algorithm parity.** The only `not_implemented` topic is help 93 (shared-world alternating **1–8 local managers** / multiplayer).
- `docs/audit/SCREEN-MATRIX.md` maps every help topic → current status → inspected code → work required.
- Read-only original-file inventory reproducible with `python3 tools/audit_original.py`. **Do not overwrite the audit baseline outputs** when re-running.

## 7. Outstanding work — backlog

### 7a. The nine items still required before claiming parity (from `docs/IMPLEMENTATION-STATUS.md`)

| # | Area | What is missing | Files most affected |
|---|---|---|---|
| 1 | Advanced tactics | Original multi-step Move/Pass/Dribble/Wait/Shoot routines, named move/set-piece libraries, trails, individual man-marking/arrows | `TacticalPlans.swift`, `TacticalScreens.swift`, `LiveMatch.swift`, `MatchView.swift` |
| 2 | Competitions/calendar | Europe, extra domestic cups, era entry rules, real calendar dates, extra time/replays, transfer deadlines, bench limits, promotion/playoffs | `Competitions.swift`, `CompetitionData.swift`, `Simulation.swift` |
| 3 | Local multiplayer | Shared-world alternating 1–8 managers (help 93), coordinated time advance | `ContentView.swift`, `Simulation.swift`, career setup |
| 4 | Transfers/scouting | Nationality/position decoding, exact ages, per-skill max ranges, first/reserve filters, AI market activity, youth/potential reports, competitor alerts, varied reply timing, loan term/wage split, full edge cases | `Management.swift`, `ContractTerms.swift`, `TransferScreens.swift` |
| 5 | Ground/commercial | Multi-placement draft + right-click confirm, corner/height constraints, per-outlet assortments, attendance histories, dynamic ad brands in match/ground, varied sponsor offers, cup-vs-league ad terms, building polish | `Ground.swift`, `StandDevelopment.swift`, `GroundScene.swift`, `GroundManagement.swift`, `Rooms.swift` (adverts) |
| 6 | Staff/training | Verify original staff bytes/wage units/morale/specialty/scout cap, detailed original activities, workload/boredom/age curves, camp squad scoping | `Management.swift`, decode `COACH.DAT` |
| 7 | Match/presentation | Original camera fidelity, richer player art, in-play injuries, direct reds, officiating/restarts, extra time, ratings, name/number options, saved replay library, full audio/commentary mapping | `LiveMatch.swift`, `MatchRules.swift`, `MatchView.swift`, `Audio.swift`, `CommentarySchedule.swift` |
| 8 | World/UI | Message-panel return/exit + fax/video presentation, manager/player/club histories, trophies from all competitions, full help coverage, finance printing, and board/job rules | `ClubWorld.swift`, `ClubScreens.swift`, `FileScreens.swift`, `ContentView.swift` |
| 9 | Fidelity verification | Interactive comparison of every original menu control; historical roster validation beyond binary checks | across the board; QA documentation |

### 7b. Rebuild phases (from `docs/FIDELITY-AUDIT-AND-REBUILD-PLAN.md`)

The intended sequence is **phases 0–1 next (evidence/data → screen foundation), then the staff/training slice**. Each phase is a playable vertical slice with an acceptance gate:

- **0 — Evidence/data:** decode staff (`COACH.DAT`), advertising (`ADVERT.DAT`), remaining player fields (nationality, position, ages), original palette/panels. Unknowns stay labelled; no source changes.
- **1 — Screen foundation:** new-game controls, red/chrome/blue theme, all original navigation destinations, bounded fixed-screen layout, context help; remove scrolling pages; 1280×720 reference canvas.
- **2 — Staff/training:** named market, wage/term handling, individual coach assignments, editable timetable, camps.
- **3 — Transfers/scouting:** full filters, persistent shortlist, reports, staged club/player faxes, sales/loans, final veto.
- **4 — Business:** separate ad/sponsor contracts, tickets, product/outlet data, accounts, banking.
- **5 — Stadium:** stand detail editor, cover/boxes/corners, construction closure, upkeep/condition, full catalogue/placement.
- **6 — Tactics/match:** Team Talk completeness, formations, advanced moves, offside/fouls/cards, stoppage subs, deterministic replay, match options incl. 1.5×.
- **7 — Career parity:** Chairman/jobs, private-phone fiction, communications, Sierratext, records, cups/Europe, and local multiplayer.
- **8 — Fidelity calibration:** asset polish, match/economy balancing, accessibility, performance.

Target screen composition for each fixed screen (Player Search, Negotiation fax, Team Training, Staff market, Individual Training, Stand inspection, Merchandise/Catering, Advertising, Team Talk, Team Data) is specified in the plan's resolution contract. Design tokens (ruby/cobalt/yellow variants) are proposed there for matching — **no lime-green accent** is the current target.

### 7c. Undecoded / research items (never present as facts)

- `COACH.DAT`: 195 candidate 26-byte records (name +10 specialty 1–7, +11 40–55, +12 32-bit 143–847, +19 0–2) — fields NOT verified.
- `ADVERT.DAT`: 100 candidate 150-byte records (advertiser names incl. repeats) — categories/prices/logos undecoded.
- `GAME.TXT`: 1,524 indexed messages behind a binary offset table — template/control tokens undecoded (could source original tone).
- Player nationality, exact position flags, full birth dates, original wages/values/capacities.
- PAK2 graphics, `.PNL/.PIC/.SPR/.BIT` layouts, `.FOR/.MOV/.SET` + `FORM.DAT` + `STADIUMS.MAP` tactics data.
- Match probabilities, negotiation patience, rig/bung/bet odds, economic formulas, commentary event indexing.
- Original Windows save format (native JSON saves do not read them).

## 8. Recommended parallel work streams (for simultaneous agents)

Central files (lower overlap): `LiveMatch.swift`, `MatchRules.swift`, `Ground.swift`, `Finance.swift`, `PlayerLifecycle.swift`, `Competitions.swift`.

**Hotspot files (high collision risk — coordinate ownership, one agent at a time):** `Management.swift`, `ClassicUI.swift`, `ContentView.swift`, `ClubScreens.swift`, `Simulation.swift`, `Models.swift`, `TacticalScreens.swift`. Do not have two agents edit the same file concurrently.

| Stream | Scope | Primary files | Acceptance gate |
|---|---|---|---|
| A — Evidence/decode (no Swift edits) | Decode COACH.DAT/ADVERT.DAT/GAME.TXT, player nationality/positions; write findings into docs + fixtures | `tools/*.py`, `docs/`, new layout notes | Verified offsets + examples; unknowns labelled; no gameplay changes |
| B — Screen foundation | Theme tokens, fixed layouts, shared components, ribbon polish, remove outer scrolling | `ClassicUI.swift`, `ClassicDialog.swift`, `ContentView.swift`, `App.swift` | All screens fit 1100×720–1440×900; only lists scroll; 43 scenarios still pass |
| C — Staff & training | Named staff market, contracts, individual assignments, timetable, camps | `Management.swift` (staff/training parts), new views | Hire/pay/assign/schedule/renew/fire + reload correctly; ledger settles |
| D — Transfers & scouting | Search filters, shortlist, scout reports, negotiations, sales/loans | `ContractTerms.swift`, `TransferScreens.swift`, parts of `Management.swift` | Constrained search, staged offers, atomic settlement, loan return, reload at every state |
| E — Business & finance | Ad/sponsor contracts, tickets, products/outlets, accounts, banking | `Finance.swift`, parts of `Management.swift`, `ClassicUI.swift` (commercial screens) | Contract expiry, brands rendered, margins reconcile | 
| F — Stadium | Stand editor, cover/boxes/corners, closure, condition, catalogue, placement draft | `Ground.swift`, `StandDevelopment.swift`, `GroundScene.swift`, `GroundManagement.swift` | Preview/commit, availability, geometry matches choices, saved layouts |
| G — Tactics & match | Advanced routines, formation editor, discipline, injur、 replay library, 1.5× speed | `LiveMatch.swift`, `MatchRules.swift`, `TacticalPlans.swift`, `TacticalScreens.swift`, `MatchView.swift` | Instructions change play; deterministic replay; legal restarts/subs |
| H — Career world | Chairnan/manager history, communications presentation, record files, competitions/calendar, prints | `ClubWorld.swift`, `ClubScreens.swift`, `Competitions.swift`, `Simulation.swift`, `FileScreens.swift` | Full season across modes; queued obligations survive rollover; no drift |

Stream A touches only tools/docs; streams B–H touch app code — assign B/G and C/D to separate agents and keep one writer per hotspot file. Each new behaviour must add/update a USMVerify scenario and follow the checklist in §11.

## 9. Conventions and rules agents MUST follow

1. **Claim before editing.** Use `python3 tools/agent-coordination.py claim` for every file you will edit. Do not edit a file with an active claim owned by another agent. Release claims after merge or abandonment. See `coordination/WORKFLOW.md`.
2. **Never push directly to `main`.** Use a `codex/<task>` branch or isolated worktree and a pull request. A reviewer may object to a proposed change before merge; unresolved concrete objections block the handoff.
3. **Verify before claiming done.** Final gate: `./tools/agent-check.sh` and `swift run -c release USMVerify` (currently 43/43). Then update this document's snapshot and append a dated entry to `progress.md` with what changed, files touched, and the new scenario count.
4. **Never claim original parity.** Everything reconstructed must stay labelled (docs consistently use "reconstructed/not verified"). **Do not invent historical facts** (names, wages, positions, dates, formulas) to make UI appear functional — mark unknown fields as unknown.
5. **Data provenance.** Importer and audit scripts must stay reproducible and read-only over source folders. Don't silently replace squads or invent staff histories; declare legacy-migration decisions explicitly.
6. **Save compatibility.** Keep save format v1 (additive optional fields). Migrate old saves on load. Back up a save before changing its structure; never break an existing career silently. QA runs must use a separate Application Support directory and never touch the user's main career.
7. **No new dependencies** (SPM/external) without explicit approval. Stay Swift 5.9+ / Command Line Tools compatible.
8. **No comments** in code unless asked; match surrounding style; use `file:line` references when describing code.
9. **Keep USMCore view-independent** — UI must not reach into simulation state directly.
10. **Keep docs in sync.** Source-of-truth docs: `IMPLEMENTATION-STATUS.md` (implemented), `SCREEN-MATRIX.md` + `audit/implementation-progress.json` (fidelity tracker), `FIDELITY-AUDIT-AND-REBUILD-PLAN.md` (plan), `RECONSTRUCTION.md` (format evidence), feature docs (`USABILITY-UPDATE-0.3.4.md`, `INTERFACE-AND-TRANSFERS-0.3.5.md`, `MATCH-AUDIO-UPDATE.md`). Do not edit the baseline audit (screen-gaps.json) as part of new work.
11. **Coordinate writes.** Only one agent edits a hotspot file at a time; announce intent in this file or progress.md when a large multi-file change starts.
12. **Use the living resume plan.** Read `PROJECT_PLAN.md` before starting work. It is the authoritative sequencing/checkpoint file for agents: update its current checkpoint before editing, and update its status, evidence, tests, unresolved risks, next step, and dated change log before releasing claims. `implementation-progress.json` remains the per-topic evidence tracker; `PROJECT_PLAN.md` remains the cross-cutting resume plan.

## 10. Documentation map

| Doc | Content | Freshness |
|---|---|---|
| `AGENTS.md` (this) | Consolidated status + backlog + coordination | Maintain continuously |
| `PROJECT_PLAN.md` | Living agent resume plan, phases, gates, ownership, and change log | Read before work; update after every work item |
| `progress.md` | Chronological change log | Latest entries 2026-09-19 (storefront LED, stadium orientation) |
| `README.md` | User-facing play/building guide | Current |
| `docs/IMPLEMENTATION-STATUS.md` | Implemented work + 9 remaining items | 0.3 line (19 Sep 2026) |
| `docs/FIDELITY-AUDIT-AND-REBUILD-PLAN.md` | Baseline audit + phase plan 0–8 | Stable baseline |
| `docs/audit/SCREEN-MATRIX.md` | 62-topic screen matrix | Baseline, cross-check with implementation-progress.json |
| `docs/audit/implementation-progress.json` | Per-topic implemented/remaining/evidence | Update as topics advance |
| `docs/RECONSTRUCTION.md` | Binary-format evidence + fidelity boundary | Evolving |
| `docs/VALIDATION.md` | Verification history (drifted counts — trust runner, not this) | Partial |
| `docs/MATCH-AUDIO-UPDATE.md`, `docs/USABILITY-UPDATE-0.3.4.md`, `docs/INTERFACE-AND-TRANSFERS-0.3.5.md`, `docs/GENERATED-ART.md`, `docs/tunnel-artwork.md`, `docs/match-crash-fix.md` | Feature/art notes | 0.3.x |
| `docs/*-manifest.json`, `docs/audit/*.json` | Inventory/hash/audit outputs | Machine-generated |

## 11. Per-task verification checklist

- [ ] Read the owning doc §5/§6 for the area before editing.
- [ ] Identify the file owner(s) from §4; announce if it is a hotspot file.
- [ ] Implement in `USMCore` first (logic) → wire UI in `USMApp`.
- [ ] Add/update a USMVerify scenario in `Tests/USMCoreTests/CareerTests.swift` + register it in `Runner.swift`.
- [ ] Run `swift run -c release USMVerify` — 43+ scenarios, 0 failures.
- [ ] Run `./tools/build-app.sh` — app builds and ad-hoc signature verifies.
- [ ] Spot-check the new screen/flow in the app at 1100×720 and 1440×900 (footer and controls visible).
- [ ] Update this file (§5/§7) + append a dated `progress.md` entry + touch the relevant `implementation-progress.json` topics.
- [ ] Do not claim original parity; label reconstructions.
