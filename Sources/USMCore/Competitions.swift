import Foundation

public enum CompetitionNames {
    public static func league(country: String, division: Int) -> String {
        let names: [String: [String]] = [
            "England": ["FA Carling Premiership", "Nationwide Football League First Division", "Football League Second Division", "Football League Third Division"],
            "Scotland": ["Scottish Premier League", "Scottish First Division", "Scottish Second Division", "Scottish Third Division"],
            "France": ["Division 1", "Division 2", "Championnat National"],
            "Germany": ["Bundesliga", "2. Bundesliga", "Regionalliga"],
            "Italy": ["Serie A", "Serie B", "Serie C1"],
            "Spain": ["Primera División", "Segunda División", "Segunda División B"],
            "Netherlands": ["Eredivisie", "Eerste Divisie", "Tweede Divisie"]
        ]
        return names[country]?[safe: division] ?? "\(country) · Division \(division + 1)"
    }

    public static let domesticCups: [String: [String]] = [
        "England": ["FA Cup", "Worthington Cup"],
        "Scotland": ["Scottish Cup", "Scottish League Cup"],
        "France": ["Coupe de France", "Coupe de la Ligue"],
        "Germany": ["DFB-Pokal", "DFB-Ligapokal"],
        "Italy": ["Coppa Italia", "Supercoppa Italiana"],
        "Spain": ["Copa del Rey", "Supercopa de España"],
        "Netherlands": ["KNVB Cup", "Johan Cruyff Shield"]
    ]

    public static let europeanCups = ["UEFA Champions League", "UEFA Cup Winners' Cup", "UEFA Cup"]
}

private extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}

public struct CupCompetition:Codable,Identifiable {
    public var id:String,country:String,name:String
    public var round=1
    public var byes:[String]=[]
    public var fixtureIDs:[String]=[]
    public var winner:String?
}

public struct SeasonCompetitionResult: Codable, Identifiable {
    public var id: String { "\(season)-\(name)" }
    public var season: Int
    public var name: String
    public var category: String
    public var position: String
    public var prize: Int
    public var result: String
}

public struct SeasonPlayerSummary: Codable, Identifiable {
    public var id: String
    public var name: String
    public var position: String
    public var appearances: Int
    public var goals: Int
}

public struct SeasonRecap: Codable, Identifiable {
    public var id: String { "season-\(season)" }
    public var season: Int
    public var club: String
    public var competitions: [SeasonCompetitionResult]
    public var players: [SeasonPlayerSummary]
    public var totalPrize: Int
    public var titles: [String]
}

public extension Career {
    var currentSeasonRecap: SeasonRecap {
        let standing = table()
        let rank = (standing.firstIndex { $0.id == clubID } ?? 0) + 1
        let leaguePrize = leaguePrizeMoney(rank: rank, fieldSize: standing.count)
        var competitions = [SeasonCompetitionResult(season: season, name: club.league, category: "League", position: "\(rank)", prize: leaguePrize, result: rank == 1 ? "Champions" : "Final table position")]
        for cup in cups ?? [] {
            let clubGames = fixtures.filter { cup.fixtureIDs.contains($0.id) && ($0.home == clubID || $0.away == clubID) }
            guard !clubGames.isEmpty || cup.winner == clubID else { continue }
            let won = cup.winner == clubID
            let played = clubGames.filter(\.played).count
            let position = won ? "Winners" : "Round reached: \(max(1, played))"
            let prize = won ? cupPrizeMoney(name: cup.name) : 0
            competitions.append(SeasonCompetitionResult(season: season, name: cup.name, category: "Cup", position: position, prize: prize, result: won ? "Champions" : "Eliminated"))
        }
        let cupWinner = (cups ?? []).contains { $0.winner == clubID }
        let europeanEntry: (String, String, Int)? = rank == 1 ? ("UEFA Champions League", "Qualified", 0) : rank == 2 ? ("UEFA Champions League", "Qualifying round", 0) : cupWinner ? ("UEFA Cup Winners' Cup", "Qualified", 0) : rank == 3 ? ("UEFA Cup", "Qualified", 0) : nil
        for european in CompetitionNames.europeanCups {
            if let entry = europeanEntry, entry.0 == european {
                competitions.append(SeasonCompetitionResult(season: season, name: european, category: "Europe", position: entry.1, prize: entry.2, result: "European qualification earned"))
            } else {
                competitions.append(SeasonCompetitionResult(season: season, name: european, category: "Europe", position: "Not entered", prize: 0, result: "No place earned this season"))
            }
        }
        let players = squad.compactMap { player -> SeasonPlayerSummary? in
            guard let state = states[player.id] else { return nil }
            return SeasonPlayerSummary(id: player.id, name: player.name, position: player.position, appearances: max(0, 38 - state.injuryWeeks), goals: state.goals)
        }.sorted { $0.goals == $1.goals ? $0.name < $1.name : $0.goals > $1.goals }
        return SeasonRecap(season: season, club: club.name, competitions: competitions, players: players, totalPrize: competitions.reduce(0) { $0 + $1.prize }, titles: competitions.filter { $0.result == "Champions" }.map(\.name))
    }

    func leaguePrizeMoney(rank: Int, fieldSize: Int) -> Int {
        let place = max(1, min(fieldSize, rank))
        return max(100_000, 1_500_000 - (place - 1) * 100_000)
    }

    func cupPrizeMoney(name: String) -> Int {
        if name == "FA Cup" || name == "Coupe de France" || name == "Copa del Rey" { return 1_000_000 }
        if name == "UEFA Champions League" { return 4_000_000 }
        if name == "UEFA Cup" || name == "UEFA Cup Winners' Cup" { return 2_000_000 }
        return 750_000
    }
}
public struct Trophy:Codable,Identifiable {
    public var id=UUID().uuidString
    public var season:Int,competition:String,winner:String,runnerUp:String
}
public extension Career {
    mutating func enableDomesticCups(){
        guard cups==nil else{return};cups=[]
        let round=week+3
        for i in fixtures.indices where !fixtures[i].played && fixtures[i].round>=round {fixtures[i].round+=1}
        let titles=["England":"FA Cup","Scotland":"Scottish Cup","France":"Coupe de France","Germany":"DFB-Pokal","Italy":"Coppa Italia","Spain":"Copa del Rey","Netherlands":"KNVB Cup"]
        for country in Set(clubs.map(\.country)).sorted() {
            let entrants=clubs.filter{$0.country==country}.map(\.id).sorted()
            var cup=CupCompetition(id:"\(season)-cup-\(country)",country:country,name:titles[country] ?? "\(country) Cup")
            cup.fixtureIDs=drawCup(cupID:cup.id,round:1,entrants:entrants,date:round,byes:&cup.byes)
            cups!.append(cup)
        }
        fixtures.sort{$0.round==$1.round ? $0.id<$1.id:$0.round<$1.round}
    }
    private mutating func drawCup(cupID:String,round:Int,entrants:[String],date:Int,byes:inout [String])->[String] {
        var teams=entrants;var ids:[String]=[];byes=[]
        // Reproducible draw using the career RNG; odd entrants receive a bye.
        for i in teams.indices {let j=rng.int(i...teams.count-1);teams.swapAt(i,j)}
        if teams.count%2==1 {byes.append(teams.removeLast())}
        for i in stride(from:0,to:teams.count,by:2) {
            let id="\(cupID)-r\(round)-\(i/2)";ids.append(id)
            var f=Fixture(id:id,round:date,home:teams[i],away:teams[i+1]);f.competition=cupID;fixtures.append(f)
        }
        return ids
    }
    mutating func progressCups(){
        guard var tournaments=cups else{return}
        var ready:[Int]=[]
        for i in tournaments.indices where tournaments[i].winner==nil {
            let games=fixtures.filter{tournaments[i].fixtureIDs.contains($0.id)}
            if !games.isEmpty && games.allSatisfy(\.played){ready.append(i)}
        }
        guard !ready.isEmpty else{return}
        let date=week+3
        let needsRound=ready.contains {i in tournaments[i].fixtureIDs.count+tournaments[i].byes.count>1}
        if needsRound {for i in fixtures.indices where !fixtures[i].played && fixtures[i].round>=date{fixtures[i].round+=1}}
        for i in ready {
            let games=fixtures.filter{tournaments[i].fixtureIDs.contains($0.id)}
            let qualified=games.map{$0.qualified ?? (($0.homeGoals ?? 0)>($0.awayGoals ?? 0) ? $0.home:$0.away)}+tournaments[i].byes
            if qualified.count==1 {
                tournaments[i].winner=qualified[0]
                if trophies==nil{trophies=[]}
                let final=games[0];trophies!.append(Trophy(season:season,competition:tournaments[i].name,winner:qualified[0],runnerUp:final.home==qualified[0] ? final.away:final.home))
                if final.home==clubID || final.away==clubID {let bonus=managementState.playerBonuses?.values.reduce(0){$0+$1.final+(qualified[0]==clubID ? $1.cup:0)} ?? 0;if bonus>0 {transact("Cup contract bonuses",-bonus)}}
                if qualified[0]==clubID {confidence=min(100,confidence+15)}
                post("COMPETITION",tournaments[i].name+" winners",name(qualified[0])+" lift the trophy.")
            }else{
                tournaments[i].round+=1
                tournaments[i].fixtureIDs=drawCup(cupID:tournaments[i].id,round:tournaments[i].round,entrants:qualified,date:date,byes:&tournaments[i].byes)
            }
        }
        cups=tournaments;fixtures.sort{$0.round==$1.round ? $0.id<$1.id:$0.round<$1.round}
    }
    @discardableResult mutating func arrangeFriendly(opponent:String)->Bool {
        guard opponent != clubID,clubs.contains(where:{$0.id==opponent}),activeMatch==nil else{return false}
        // A friendly occupies its own date, keeping every scheduled fixture intact.
        for i in fixtures.indices where !fixtures[i].played && fixtures[i].round>=week {fixtures[i].round+=1}
        var f=Fixture(id:"friendly-\(UUID().uuidString)",round:week,home:clubID,away:opponent);f.competition="Friendly";fixtures.append(f);fixtures.sort{$0.round<$1.round};return true
    }
}
