# Screen-by-screen fidelity matrix

Every non-empty topic in the original CD help is mapped below. “Partial” means a related function exists; it does **not** mean original behaviour is reproduced. “Missing” includes misleading aliases and placeholders that do not implement that system. Source: `help-sections.json`, keyed by help ID. Code paths are under `Sources/USMApp` or `Sources/USMCore`.

| Help ID | Original screen | Current status | Implementation inspected | Work required |
|---|---|---|---|---|
| 0 | STADIUM SCREEN | Partial | GroundManagement.swift / GroundScene.swift | Editable ground exists; recover original stand/building types, layout density, upkeep and original room links. |
| 1 | MESSAGES PANEL | Missing | ContentView.swift: InboxView | One generic inbox replaces the end-period panel; add separate email, voicemail, newspaper, private phone and negotiations queues, unread states, Return/Exit. |
| 2 | BUSINESS ROOM | Partial | Rooms.swift / ClubViews.swift: BusinessView | Room exists but several objects alias one generic page; provide six distinct commercial screens. |
| 3 | ACCOUNTS | Partial | ClubViews.swift: BusinessView | Ledger exists; add weekly/yearly income and cost categories, operating profit excluding transfers/interest, finances link and print. |
| 4 | FINANCE | Partial | ClubViews.swift: BusinessView | Flat £1m borrowing is a substitute; add assessed loans, repayments, overdrafts, grants with obligations, flotation and shareholder distributions. |
| 5 | SQUAD ROOM | Partial | Rooms.swift | Correct TV to opposition, green board to formation editor, folders to advanced tactics; restore complete object map. |
| 6 | TEAM SELECTION | Partial | SquadTable.swift / FootballViews.swift | Swaps and skill columns exist; add temporary stat views versus permanent reserve sorting, skill bars, performance-record toggle, injury sorting, competition-specific bench size, last match/meeting. |
| 11 | TEAM TALK | Partial | Models.swift: Tactics / FootballViews.swift | Add captain, four set-piece takers, win bonus, individual arrows/man marking, offside trap, custom formation, selected move and set piece; wire each into match rules. |
| 18 | VIEW OPPOSITION | Missing | Rooms.swift currently routes to Competitions | Dedicated upcoming opponent squad/form, previous/next fixture and player drill-down required. |
| 19 | CHAIRMAN'S OFFICE | Partial | Rooms.swift: BoardView | Replace fixed top-half text and one confidence score with match/season objectives, four evaluation sources, graphs and trophies. |
| 20 | SPONSORS | Partial | ClubViews.swift: BusinessView | Three immediately replaceable tiers are a substitute; generate timed offers with acceptance/rejection, current contract, expiry and reputation-sensitive availability. |
| 21 | ADVERTISING | Missing | No advertising model | Separate stadium-board and programme/magazine inventory, offers/current contracts, league-season versus home-cup terms, assistant delegation, visible accepted brands. |
| 22 | TICKET PRICING | Partial | BusinessView / Simulation.swift | One price only; add stand-type league/friendly, cup and season-ticket tariffs, school tickets, stand/whole-ground attendance and revenue charts. |
| 23 | STADIUM IMPROVEMENT | Partial | Ground.swift / GroundManagement.swift | Add selected-stand close-up, capacity choice, terrace/seated, cover, boxes, corner prerequisites, maintenance, condition, project preview and reduced available capacity. |
| 25 | IMPROVE BUILDINGS | Partial | Ground.swift / GroundManagement.swift | Placement exists; restore building catalogue, multiple placement preview/right-click confirm/cancel, original types and building statistics. |
| 28 | TROPHY CABINET | Missing | ArchiveView is generic season history | Competition winners/runners-up and accumulated trophy history. |
| 29 | EVALUATION | Partial | BoardView / Models.swift | Chairman, financial, fans and player/staff ratings with explanatory evaluations; coach-mode exceptions. |
| 30 | EVALUATION GRAPHS | Missing | No evaluation timeline UI | Toggleable historical lines for all evaluation sources. |
| 33 | MERCHANDISING | Partial | BusinessView / Simulation.swift | One merchandise price; add SKU assortment by outlet, unit costs/prices, quantity/revenue/profit, all/type filters, item graphs and inflation. |
| 34 | CATERING | Missing | Catering routes to BusinessView | Distinct food/drink catalogue, outlet-type views, per-item prices/costs, sales and profit histories. |
| 36 | INDIVIDUAL TRAINING | Partial | Rooms.swift: IndividualTrainingView | Per-player focus is a substitute; assign named coach to player skill cells, per-player intensity, workloads, boredom, age development and recovery rules. |
| 37 | TEAM TRAINING | Partial | FootballViews.swift: TrainingView | Decorative week and global focus only; editable day/time grid, activity palette, locked match slots, individual/free-time periods, assistant proposals and training camps. |
| 41 | COACHES/SCOUTS | Missing | Rooms.swift: CoachingView | Anonymous upgrade levels are not staff; implement named available/employed coaches and scouts, quality, specialty, wages, term, morale, hire/renew/fire/payout; six coach cap. |
| 45 | INJURIES | Partial | TrainingView / Simulation.swift | Weeks-only injuries; add diagnosis, major/minor classification, unavailable recovery phase and fitness rehabilitation. |
| 46 | ARRANGE FRIENDLIES | Missing | No friendly scheduler | Up to four pre-season friendlies, date/home-away/opponent selection and same-division restriction. |
| 47 | MOBILE PHONE | Missing | Phone currently routes to transfer office | Private mobile: rig offer, transfer bung, simulated bet and bookmaker messages; fictional random acceptance, costs, consequences and uncertain outcome. |
| 48 | FIXTURE LIST | Partial | ClubViews.swift: CompetitionsView | Fixtures list exists; add opponent drill-down, past reports, league-position/nationality indicators, other teams, friendlies and print. |
| 56 | MANAGER'S OFFICE | Partial | Rooms.swift | Restore distinct filing, voicemail, email, newspaper, Sierratext, video, printer, fixtures, mobile and scrapbook routes. |
| 57 | PLAYER FILE | Partial | SquadTable.swift / playerDetail | Separate Contract, Skills, Appearances and Discipline views, including listing state, weeks remaining, assists, awards, ratings, bans. |
| 58 | PLAYER INFORMATION | Partial | FootballViews.swift: playerDetail | Add verified positions/age/nationality, aspirations, bonuses, competition history, transfer history, negotiated renewal, listing/fee, not-for-sale and fast sale. |
| 61 | CLUB FILE | Partial | CompetitionsView / ArchiveView | Club data, current and historic records, progression graph, transfer records and other clubs. |
| 63 | MANAGER FILE | Missing | Only manager name and season summary | Manager career record across clubs and seasons. |
| 64 | HISTORY FILE | Partial | ArchiveView | Full club records and honours, updated by competition and season. |
| 66 | PLAYER SEARCH | Partial | FootballViews.swift: TransfersView | Only name/role/own-player filters, top 100; add league/division, contracts/listed/short, squad status, age/value ranges, each skill range, scout suitability, sorting, full paging, reset and detail/skill views. |
| 69 | CURRENT NEGOTIATIONS | Partial | TransfersView / Models.swift: Offer | Pending rows only; separate in/out lists with negotiation status, Reply/Drop, readable history and club/player responses. |
| 70 | SELLING PLAYERS | Partial | Models.swift: bid / Simulation.swift | 85%-value delayed sale is a substitute; listing/unlisting/asking fee, unsolicited bids, no-sale flag, counters, player refusal and final confirmation. |
| 71 | LOANING PLAYERS OUT | Missing | No loan model | Loan listing, incoming requests, agreed duration, wage payer, experience/morale and scheduled return. |
| 72 | SHORTLIST | Missing | Search heading says shortlist but no saved shortlist | Persistent shortlist, comparison to own squad, skill charts/sorting, competitor alerts, named scout assignment/removal, reports after time and uncertain recommendations. |
| 73 | NEWSPAPER | Missing | Generic inbox/report only | Newspaper sections with unread article markers; reports, transfers, supporters, other news; direct results/tables. |
| 74 | NEWSPAPER ARTICLES | Missing | No article reader | Next article and Add to scrapbook. |
| 75 | SCRAPBOOK | Missing | No scrapbook | Saved articles, reread and delete. |
| 78 | EMAIL | Partial | InboxView | Dedicated external email queue, unread/next/return, archive/save/delete. |
| 80 | VOICEMAIL | Partial | InboxView | Dedicated internal voicemail queue with action links and return to period panel. |
| 81 | VIDEO HIGHLIGHTS | Missing | No match recording model | Recorded match highlights, playback and deletion; replay must use recorded simulation state. |
| 82 | START MATCH TUNNEL | Partial | MatchView: MatchChoice | Watch/instant/cancel exist as sheet; restore an illustrated tunnel with the three exits. |
| 85 | ADVANCED TACTICS | Missing | LiveMatch formation heuristics only | Attack/defend positions for 12 zones plus five restarts (34 states), trails, copy/paste, move/set-piece sequences, pass/dribble/move/wait/shoot, undo, save/load and opposition overlay. |
| 87 | FORMATION EDITOR | Missing | Four fixed formation choices | Move individual slots, no overlap, new/load/save-as, protected stock formations, undo/all, preferred-role comparison. |
| 89 | FILE | Partial | App.swift / ContentView.swift | Native save/import and sound controls exist; add file room, configuration, commentary/tooltips/messages toggles, autosave cadence, save browser, resign/restart/player control. |
| 90 | TRANSFERS ROOM | Partial | Rooms.swift | Three aliases replace full transfer room; binoculars search, current-negotiation folder, shortlist/scouting, selling bin and loan trays must be distinct. |
| 91 | SIERRATEXT | Partial | CompetitionsView | Add paged Sierratext: domestic/European fixtures, results, all/home/away tables, form, awards, national squads, transfers, attendance, referees, scorers/assists/discipline. |
| 92 | SELECT OPTION | Partial | ContentView.swift: TitleScreen | New/load exist; add Manager/Coach modes with real business automation. |
| 93 | HOW MANY PLAYERS | Missing | Single Career manager | Local alternating turns for 1–8 managers; coordinated time advance and matches. |
| 94 | STARTING CASH | Partial | CareerSetup | Starting cash exists; confirm original difficulty amounts instead of invented presets. |
| 96 | SELECT LEAGUE | Partial | CareerSetup / database.json | Seven-country CD data is used; recover named competition definitions and verify all original clubs/external player pools. |
| 97 | SELECT TEAM | Partial | CareerSetup | Club/division choice exists; add multiplayer repetition and competition names. |
| 98 | MANAGERS NAME | Partial | CareerSetup | Name entry exists; prior-name history absent. |
| 103 | END OF SEASON | Partial | Simulation.swift | Season rollover/promotion exists; add full competition awards, other-league summaries, job applications, dismissal and manager contract logic. |
| 104 | SAVE | Partial | App.swift: SaveStore | Native saves exist; named in-game save slots with date/team/multiplayer metadata and delete. |
| 105 | LOAD | Partial | App.swift: importSave | Native file picker works; replace with skinned save browser, preserving system picker only for optional external import. |
| 110 | PRINTING | Missing | No print routes | Team lists, other teams, fixtures, shortlist, accounts; macOS print/PDF is appropriate after in-game selection. |
| 111 | BUYING PLAYERS | Partial | Models.swift: Offer / Simulation.swift | Replace one-week fee/wage threshold with enquiry, club counters, player interest/terms, bonuses, swaps and appearance clauses, deadlines/timeouts plus README final veto. |
| 112 | MATCH SCREEN | Partial | LiveMatch.swift / MatchView.swift | Live watch/speed/pause/substitution exists; add 1.5x, normal/overhead toggle, names/numbers/team scope, individual match instructions, dead-ball subs, replay/store, fouls/offside/cards/injuries/ratings and full-time statistics. |
