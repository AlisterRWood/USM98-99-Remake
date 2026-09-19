# Player lifecycle validation — version 0.3.1

32 scenarios passed, 0 failures. Added DOB and annual ageing checks, old-player decline/retirement, free youth intake across all clubs, unique identities and valid saves after nine rollovers, varied growth ceilings, elite skill development above 92 and appearance-driven experience. Existing 29 scenarios continue to pass. Legacy DOB recovery is tested against matched player identities and rejects mismatched names. Native player-record inspection confirmed the date, age, estimated-date label and development assessment fit above the skill grid. Dates and development profiles persist in saves; approximate dates are labelled. Calendar ages currently use 1 August each season.

# Validation — 19 September 2026, version 0.3

`swift run -c release USMVerify`: **29 scenarios passed, 0 failures** against the combined Mega Update database and fidelity reconstruction.

The suite covers the earlier fixtures/selection/ground/live-match/save checks plus staff and scouting, training migration, staged negotiation/final veto, financial and contract obligations, stand capacity closure, custom tactics, replay/stoppage substitutions, discipline, and a complete domestic-cup season with rollover. It does not establish original algorithm parity.

Native UI checks used separate QA bundles and copies of an existing career, without replacing the user's main save. Confirmed:

- The custom captain selector opens and selecting Tony Adams changes the captain.
- The coaching hotspot opens the named candidate market. Hiring Purple removes him from available candidates, increases employed coaches from 0 to 1 and charges the appointment fee.
- The team-training hotspot opens a bounded screen with all camp and Exit controls visible. Clicking Monday morning changes Fitness to Set pieces.
- Player Search numeric entry accepted a £2,000,000 maximum and filtered the existing-career database from 9,795 to 3,743 players. Selecting Steve Agnew and Buy opened Current Negotiations with an Enquiry sent record and awaiting-club reply.
- A reduced-width negotiation window retained offer controls, navigation and Exit without page scrolling. The exact 1100×720 minimum and all other screens still require exhaustive checks.
- The ruby/chrome title and footer, blue room-thumbnail ribbon and indigo content panel render as one screen. Visual inspection found and fixed a SwiftUI container error which had separately framed child elements.

Every-screen minimum-window comparison remains outstanding. Native execution was tested on this Apple Silicon Mac only. Algorithms, wages and balancing remain reconstructed. See [implementation status](IMPLEMENTATION-STATUS.md) for the explicit fidelity boundary.

---

The following records are historical checks from earlier builds. Their feature-limit statements describe those builds, not version 0.3.

# Validation — 19 September 2026, version 0.2

## Automated

`swift run -c release USMVerify`: **18 scenarios passed, 0 failures** after the bench-selection correction.

Verified:
- Mega Update 1.2 record counts and reference players (412 clubs; 9,747 players).
- Round-robin fixtures/byes, injury exclusions, accounting, delayed/rejected transfers, full season and promotion/relegation.
- Ground placement, occupancy, cost and completion; relocation; save round-trip; stand expansion and demolition.
- Live movement into opposing territory, physical passes/shots, half-time freeze, three-substitution rules, tactical changes and balanced bench coverage.
- Fixed-step speed parity, live-match save/resume, protection against committing unfinished matches, completed result propagation.
- Native save validation and deterministic random-state preservation.

## Native app playtest

Built and ad-hoc signed the macOS release bundle. Checked the actual native UI:

- Launch shows New game / Load game / Import rather than entering a career.
- Four-step setup accepts a manager name, league, original-CD club and funds; starting Arsenal opens the dynamic ground.
- The top navigation opens the illustrated dressing room. Blackboard opens tactics with the Mega Update squad for the selected club.
- Construction editor shows vacant plots. Commissioning a shop at plot-3-6 deducted £400,000, displayed scaffolding and a three-week countdown, and saved the project.
- After three completed fixtures, the scaffold became an actual shop at the selected location; the saved ground contains its completed level-1 record.
- Watch/Instant selection appears before the fixture. Watched Arsenal–Tottenham produced moving play, shots, saves and goals, finishing 2–2 in this test.
- During play, substituting Ljungberg for Wreh updated the substitution count and commentary; applying 3-5-2 updated the live instructions.
- Returning to the title and loading restored the paused match at 32:51, score 1–1, with changes retained.
- Selecting 16× stopped at 45:00 for the half-time team talk. Starting the second half changed ends and continued to full-time.
- Continue to results advanced to Week 2 and showed the same 2–2 score, scorers, substitution, tactics event and statistics.
- Instant result also shows full-time and waits for Continue; it does not silently advance the week.
- Window sizing was corrected to use the available display area after an oversized initial window hid the bottom controls. Automatic bench selection was corrected to include one goalkeeper and outfield coverage; the updated regression check passes.

The playtest save is an Arsenal career as Alex Morgan at Week 4 with one completed new shop. Earlier saves are backed up automatically on new-career creation. New game is recommended to start your own untouched CD career.

## Limits

Tested on this Apple Silicon Mac, not Intel or older macOS hardware. Native indexed UI actions worked; the computer-use service's coordinate-click API returned `noWindowsAvailable`, so direct 3D mouse hit targets were not independently exercised by automation. Hit-testing is implemented in the SceneKit view; placement/completion were exercised through the accessible editor controls and inspected visually.

The live match engine and economics are reconstructed systems, not recovered original algorithms. Match balance, advanced tactical depth and complete feature parity remain unfinished. Ground geometry is functional and editable, but visually simpler than the generated room art. Original position flags, capacities, wages and age fields are not verified. No original Windows save compatibility, cups, offside/discipline systems, multiplayer or exhaustive long-run calibration is claimed.

## New-game wizard sizing fix

The wizard's `Group` forwarded `minHeight:245` to each child (individual paragraphs, fields and pickers), multiplying the sheet height and pushing navigation off-screen. Replaced it with a real `VStack` whose shared content region is 230 points high; the complete dialog is now 620 × 540 points. Back/Continue sit outside the club list's scrolling region.

Rebuilt and signed the app, relaunched it, and visually inspected all four steps at the new size. Verified name validation enables Continue, league navigation works, the club list scrolls independently, Begin Career is fully visible, and Back returns to the club step with the selection retained. No new career was committed during this layout-only check.

## Room, squad and match presentation refinements

- Fixed room-wide hover interception by attaching hover handlers before `.position` and explicitly sizing the button label's hit shape. In the running app, direct coordinate clicks on the dressing-room blackboard, cone and shirts opened Tactics, Individual training and Squad respectively; clicking the manager-office computer opened Inbox.
- Replaced top navigation symbols with the corresponding room image thumbnails.
- Added an elevated touchline projection of the existing metre-based simulation, with perspective grass/markings, upright players, raised goal frames, ball height, crowd terraces and advertising. Visually inspected the complete pitch before kickoff. Simulation rules remain independent of the projection.
- Replaced squad cards with a compact native table: ordered starters, substitutes and reserves, nine skill columns and position colours. Actual right-click on Adams followed by left-click on Keown swapped the rows and saved them. Escape cancellation was exercised. The final build uses a non-intercepting floating name label that follows mouse movement within the table; it was compiled, but final UI rechecking stopped when the user began interacting with the app.
- `swift run -c release USMVerify`: **19 scenarios, 0 failures**, including swaps between starters, starters/bench and bench/reserves; save persistence; the selected bench reaching the live match; and rejecting injured players entering the XI.
- Final release rebuilt and signature verified. A pre-playtest save was preserved in `.work/pre-refinement-playtest.json`. It was not restored over the user's actively running session. The UI playtest swapped Adams and Keown and opened the next fixture without committing its result.

## 0.3.4 usability update

37 verification scenarios pass; native app build and ad-hoc signature verification pass. Isolated native UI checks cover named formation save/load, coach speciality labels, right-click back and player pickup, own-player market controls, business sponsorship hotspot, and populated stadium zoom/orbit limits. See `USABILITY-UPDATE-0.3.4.md` for rules and evidence.
