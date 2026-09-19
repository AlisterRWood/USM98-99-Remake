# Coordination ownership map

This is the stable, reviewable map of broad ownership. It is not a substitute
for an active claim: an agent must still claim exact files before editing.

| Area | Primary files | Workstream |
|---|---|---|
| Core simulation and career rules | `Sources/USMCore/Simulation.swift`, `Sources/USMCore/ClubWorld.swift`, `Sources/USMCore/Models.swift` | H |
| Match and rules | `Sources/USMCore/LiveMatch.swift`, `Sources/USMCore/MatchRules.swift`, `Sources/USMApp/MatchView.swift` | G |
| Staff, training, scouting | `Sources/USMCore/Management.swift`, `Sources/USMApp/FootballViews.swift` | C |
| Transfers | `Sources/USMCore/ContractTerms.swift`, `Sources/USMApp/TransferScreens.swift` | D |
| Business and finance | `Sources/USMCore/Finance.swift`, commercial views | E |
| Stadium and ground | `Sources/USMCore/Ground.swift`, `StandDevelopment.swift`, `Sources/USMApp/Ground*` | F |
| Tactics | `Sources/USMCore/TacticalPlans.swift`, `Sources/USMApp/TacticalScreens.swift` | G |
| Shared UI/navigation | `Sources/USMApp/ClassicUI.swift`, `ContentView.swift`, `ClubScreens.swift` | B |
| Evidence and decoding | `tools/`, `docs/` | A |

Files not listed here are still subject to claims. Hotspot files require one
active writer at a time; a reviewer may inspect them without claiming them.
