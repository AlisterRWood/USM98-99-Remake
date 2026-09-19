# Reconstruction notes and fidelity boundary

## Evidence and research

Inspected the supplied `WindowsGameFiles` without executing any `.exe` or loading the bundled compatibility tools. In-folder `HELP.TXT` is the most detailed local reference: squad selection, team talk, training, staff, transfers, ground construction, pricing, negotiation and match management are described there.

Online references consulted:

- [Original Sierra manual, preserved by Old Games Download](https://oldgamesdownload.com/manual/ultimate-soccer-manager-98-99-windows-manual-english/). Primary documentation for management responsibilities, tactics, match progression and save behavior.
- [Community USM 2020 repository](https://github.com/terence1990/usm-2020). Demonstrates the existence of updated databases and community editing tools. We did not download or execute its binaries and cannot prove the supplied files came from that repository.
- [USM Community history](https://usm.dynamic-mess.com/history-of-the-games/). Background on the series and editions.
- [Apple SwiftUI State documentation](https://developer.apple.com/documentation/SwiftUI/State). Used to resolve the installed SDK's new State macro / legacy property-wrapper ambiguity. An explicit typealias selects the stable wrapper without needing the absent SDK macro plugin.

No claim is made that the executable has been decompiled or its match algorithms recovered. The implementation follows the original game's broad management loop and applies explicitly reconstructed rules.

## Mega Update 1.2 roster update

`MegaUpdate/` supplies Mega Update 1.2's seven playable-league `TEAM*.DAT` and `PLAYER*.DAT` files. Its included notes date the squad data to 31 January 2001. The importer now uses those roster files by default, while `OriginalCD/data1.cab` remains the source for original audio and art assets. `original-cd-manifest.json` records both the CD asset source and the Mega Update roster source. No Windows program is executed.

## Asset inventory

The reproducible `asset-manifest.json` includes every supplied file's relative path, byte count and SHA-256. There are 5,649 WAV files, 65 PIC, 39 SPR, 29 BIT, 45 DAT, 20 FOR, 15 MOV, 15 SET, 7 ANM, 6 SMK and additional configuration, backup and executable files.

Implemented extraction:

- Fixed-width team and player records, including names, club linkage, country and league division.
- Nine player skill values. The JSON includes the source filename and byte offset for every imported record.
- `usme0000.lbm`: standard IFF `FORM`/`PBM `, uncompressed chunky 8-bit indexed pixels, `BMHD`, `CMAP`, `BODY`. Converted losslessly to PNG with a standard-library encoder.
- `MUSIC/music1.wav`: copied without transcoding; optional playback through AVFoundation.

Inventoried but not decoded: PAK2 graphics, sprite layouts, formation/set-piece binaries, Smacker video, original saved careers, original match commentary indexing. These files are not silently treated as modern-format assets.

## Recovered record layout

Offsets below are zero-based. All parsers only read the source directory.

### TEAM{N,S,F,G,I,P,D}.DAT

671 bytes per record. England N, Scotland S, France F, Germany G, Italy I, Spain P, Netherlands D.

| Offset | Length | Interpretation | Evidence |
|---|---:|---|---|
| 0 | 26 | Club name | Null-terminated strings aligned every 671 bytes |
| 26 | 26 | Manager | Readable names |
| 52 | 26 | Nickname | Readable nicknames |
| 78 | 26 | Stadium | Readable stadium names |
| 189 | 1 | Division (zero-based) | England distribution 20/24/24/24/22; recognizable clubs cluster together |

Import excludes empty/invalid records, and clubs with fewer than eleven usable associated players. Division mapping is inferred from structural evidence; original competition names and rules are not fully decoded. With Mega Update 1.2, 412 playable clubs are imported after filtering.

### PLAYER{N,S,F,G,I,P,D}.DAT

187 bytes per record.

| Offset | Length | Interpretation |
|---|---:|---|
| 0 | 14 | First name |
| 14 | 15 | Surname |
| 33 | 2 | Little-endian zero-based team record index |
| 144 | 1 | Keeping |
| 145 | 1 | Tackling |
| 146 | 1 | Passing |
| 147 | 1 | Shooting |
| 148 | 1 | Pace |
| 149 | 1 | Fitness-like value (not imported; predominantly 100) |
| 150 | 1 | Heading |
| 151 | 1 | Stamina |
| 152 | 1 | Set pieces |
| 153 | 1 | Ball control |

Mega Update reference checks: Dennis Bergkamp and Patrick Vieira link to Arsenal (N-0), while David Beckham links to Manchester United (N-60); Arsenal remains at Highbury. The later-era roster previously extracted from WindowsGameFiles is not the new-career source. Text exports supply matching skill vocabulary. Position is inferred from the strongest of keeping/tackling/passing/shooting; the exact original position flags remain unverified. Byte 31 is now imported as an inferred birth-year offset where plausible. Ages shown in the UI are approximate season-year differences, not verified full birth dates.

Import retains 9,747 Mega Update players; invalid, empty or unassigned records are excluded. Strings use Windows-1252. Non-playable/external-team pools are not yet imported.

## Initial reconstruction rules (historical baseline)

The rules below describe the initial build and have been superseded in several areas. For build 0.3, see [Implementation status](IMPLEMENTATION-STATUS.md) and the [topic tracker](audit/implementation-progress.json). In particular, staged bargaining replaces the basic transfer UI; named staff and scheduled training replace generic coaching; construction closes stand capacity; domestic cups, offside/discipline and dismissal now exist. Their formulas remain reconstructed.

- Every imported league runs a seeded double round robin. Odd league sizes receive byes. Fixtures are sorted by round and stable IDs.
- Ratings weight role-relevant skills. Wages, values and starting capacity are derived from ratings; they are **not original economic data**.
- Managed XI quality includes skills, fitness, morale and positional mismatch. Opponents select their strongest players. Mentality and passing alter chance creation and defence; tackling affects defence and injuries.
- Managed matches use a fixed-step spatial simulation: dynamic off-ball positioning, dribbling, timed passes, ball flight, interceptions, shots, saves and goal-line arrival. No result is generated ahead of watched play. Speed changes batch the same steps. Tactics and substitutions alter the running state. Instant result runs the same engine to completion. Other league fixtures retain a statistical simulation.
- Weekly recovery, training improvements and managed-team injuries; development scales with facility level. No verified original age-dependent development yet.
- Full fee and minimum wage offers succeed one week later if cash remains sufficient. Lower offers fail. Sales return 85% of estimated value and preserve minimum squad size. This is a simple negotiation model, not the original fax/agent bargaining algorithm.
- Home gate receipts depend on capacity, pricing, confidence and seeded demand. Merchandise, sponsorship, wages, staff, upkeep and loan interest are recorded in the ledger.
- Editable ground objects occupy four stand sites and perimeter plots. Stand projects add 5,000 seats after four weeks; other facilities take three weeks. Multiple projects, upgrades, rotation, relocation and demolition are supported; active upgrades leave the old facility operating. The SceneKit world rebuilds from saved ground state.
- At season end, two clubs exchange between each adjacent division. No playoffs. Prize money is awarded; pending contracts age. Expiring managed contracts receive automatic one-year extensions at a 15% wage increase, announced in the inbox.
- Confidence changes after results and debt pressure, but sacking/bankruptcy termination are not implemented.

## Initial fidelity backlog (historical)

Current completion and remaining requirements are maintained in [Implementation status](IMPLEMENTATION-STATUS.md), not this historical list.

This is an evolving native reconstruction, not completion of the requested full recreation. Significant outstanding work:

1. Further verify historical database fields beyond the recovered names, club assignments and skills. Mega Update 1.2's January 2001 roster is now imported.
2. Decode original positional flags, capacities, economy fields, nationality, age, staff data and remaining asset compression, using editor source or independently verified binary evidence.
3. Original competition structures: cups, European qualification, playoffs, scheduling and historical rules.
4. Tactical depth: custom formations, set pieces, individual instructions, captaincy, discipline, fouls/offside and deeper match AI. Live spatial play and substitutions are now implemented.
5. Detailed coaching/scouting staff, age-based growth, youth recruitment, negotiation stages, player desires and free agency.
6. Original stadium layout/stand types and broader businesses; media, job market, board ultimatums and special negotiation mechanics.
7. Original save import, multi-manager play, video and event-linked commentary.
8. Long-run economic/match calibration against recorded original behavior, accessibility and multi-Mac QA; universal distribution and notarization.

The new engine can be extended independently of the native UI. No Windows execution dependency exists.
