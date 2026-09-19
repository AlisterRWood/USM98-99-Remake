# Ultimate Soccer Manager — Native macOS reconstruction

> **For AI agents / contributors working on the code:** start with [`AGENTS.md`](AGENTS.md) — current progress, the outstanding backlog, file ownership, and parallel-work coordination rules.

Parallel work is guarded by the claim-and-verify workflow in
[`coordination/WORKFLOW.md`](coordination/WORKFLOW.md). Agents must claim files
before editing, work on `codex/*` branches, and pass `./tools/agent-check.sh`
plus the verifier before opening a pull request.

Native SwiftUI / SceneKit development build, macOS 14+. No Wine, Windows executable, emulation or web view. This is a newly written game using recovered original data and audio, not a decompilation or yet a complete recreation of USM 98–99.

## Play

Open `dist/Ultimate Soccer Manager.app`. **New game** first lets you choose between the **Original CD 2.00** database (416 clubs and 9,795 players, 15 October 1998) and **Mega Update 1.2** (412 clubs and 9,747 players, updated through 31 January 2001), then walks through manager name, league, club and starting funds. Each career stores its selected database in the save and owns its own mutable copy, so separate careers can use different starting worlds. The previous save is backed up automatically.

The top row takes you between rooms. In the dressing room, click the shirts for the squad, blackboard for tactics, cone for individual training, balls for team training, or newspaper for coaching. The other rooms have clickable desks, phones, papers and computers.

**The stadium is an editable 3D world.** Click buildings to enter, drag to orbit, scroll to zoom. Choose **Develop the ground** to select plots, construct shops/cafés/training facilities, upgrade stands, move and rotate buildings, or demolish eligible structures. Construction costs money, takes game weeks and changes the visible ground. Completed stands increase capacity; businesses and training facilities affect the career. Layouts and projects are saved. Four stand positions surround the pitch; other facilities use perimeter plots. The static estate artwork is used only on the title screen.

**Matchday** offers Watch match or Instant result. Watched matches simulate possession, movement, passing, interceptions, shots, saves and goals as play unfolds. Change speed from 1× to 16×, pause for tactics and up to three substitutions, and start the second half after the half-time team talk. Instant result uses the same live engine. Continue after full-time to commit the result and advance the week. In-progress matches save and reload paused.

Original CD music and sound effects play through native audio. Music/effects have separate controls.

## Build and verify

See [`BUILDING.md`](BUILDING.md) for the complete fresh-clone build guide.
In short, macOS 14+, Apple Command Line Tools or Xcode, and Swift 5.9+ are
required. No downloaded Swift package dependencies are used.

```sh
swift run -c release USMVerify
./tools/build-app.sh
open "dist/Ultimate Soccer Manager.app"
```

The checked-in bundle resources are sufficient; the excluded old-game source
dumps are not needed at runtime. Asset extraction is a maintainer-only task
when separate local source data is available. This local build is ad-hoc
signed, not notarized for distribution.

## Saves and project files

Native JSON saves live at `~/Library/Application Support/USM98Native/career.json`. Save with ⌘S; construction, match pauses and weekly progression save automatically. Export/import are available from the game and macOS menus. Original Windows save files are not supported.

- `Sources/USMCore`: database, careers, live simulation, ground rules and persistence.
- `Sources/USMApp`: native room UI, SceneKit ground, match canvas and original audio.
- `tools/extract_assets.py`: reproducible binary importer.
- `docs/RECONSTRUCTION.md`: decoded fields, evidence, assumptions and fidelity limits.
- `docs/VALIDATION.md`: automated and native app checks.
- `docs/GENERATED-ART.md`: room artwork provenance and prompt descriptions.
- `docs/original-cd-manifest.json`: CD source and extracted-file hashes.

Build 0.3 adds named coaches/scouts, scheduled training, staged negotiations with contract clauses, sponsors and advertising, item pricing, banking, stand specifications, custom tactical positions, disciplinary events, replay, domestic cups and board consequences. These systems have working career logic and persistent state. The [implementation status](docs/IMPLEMENTATION-STATUS.md) records the verified work and the substantial gaps still remaining; complete original-game parity is not claimed.

## Room and selection refinements

Room navigation now uses miniature room images. Hotspots track only their own object area. Match presentation uses an elevated side-on perspective while retaining the live simulation. Team Selection uses a compact, colour-coded squad table: right-click to pick up a player, left-click another to swap, or press Escape to cancel. The name follows the pointer inside the list. Double-click a player for their record; numbered rows 1–11 are starters, 12–18 the bench, and R rows the remaining reserves. Selection and bench ordering are saved and used by the match engine.

## Fidelity audit and rebuild roadmap

The [September 2026 fidelity audit](docs/FIDELITY-AUDIT-AND-REBUILD-PLAN.md) maps all 62 non-empty original CD help topics against this implementation and defines the remaining functional and visual rebuild. See the [screen matrix](docs/audit/SCREEN-MATRIX.md) for individual gaps. The original audit remains an unchanged baseline. The [62-topic implementation tracker](docs/audit/implementation-progress.json) links current code and unresolved requirements; no topic is certified as original-algorithm parity. Reproduce the read-only original-file inventory with `python3 tools/audit_original.py`.

## Player careers and youth intake (0.3.1)

Players now retain dates of birth and age each season. Player records show the birth date and identify estimated dates. Ages use 1 August of the current season because the current calendar is round-based. Individual saved potential ceilings and development rates make youth growth variable; training and appearances improve skills, and late-career physical decline reduces ability and value. Original date bytes are imported where valid; hidden potential and retirement formulas are reconstructed.

At rollover, players retire at individual ages (goalkeepers generally later). Every club below 20 players receives free 16–18-year-old recruits with unique IDs and names assembled from the database's first names and surnames. Their wages are paid normally. Existing saves migrate on load without resetting squads or rerolling established development profiles. There is no separate playable youth-team competition.

## Commentary and match update (0.3.2)

Original spoken names and match-event phrases now accompany live matches. Free kicks and corners visibly set up before delivery, attackers run into space and shoot earlier, and pace differences are stronger. The top ribbon includes the FILE car and HELP/date tiles. See [verification and limitations](docs/MATCH-AUDIO-UPDATE.md).
