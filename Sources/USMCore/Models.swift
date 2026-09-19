import Foundation

public struct Database: Codable {
    public var schemaVersion: Int
    public var dataset: String
    public var clubs: [Club]
    public var players: [Player]
    public static func load(_ url: URL) throws -> Database { try JSONDecoder().decode(Database.self, from: Data(contentsOf: url)) }
}
public struct Club: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var manager: String
    public var nickname: String
    public var stadium: String
    public var country: String
    public var division: Int
    public var league: String { "\(country) · Division \(division + 1)" }
}
public struct Player: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var clubID: String
    public var position: String
    public var skills: [Int]
    public var birthYear:Int?
    public var birthMonth:Int?
    public var birthDay:Int?
    public var development:PlayerDevelopment?
    public func age(season:Int)->Int? {birthYear.map{1997+season-$0-((birthMonth ?? 1)>8 || ((birthMonth ?? 1)==8 && (birthDay ?? 1)>1) ? 1:0)}}
    public var rating: Int {
        switch position {
        case "GK": return (skills[0]*4 + skills[4] + skills[6])/6
        case "DEF": return (skills[1]*3 + skills[5] + skills[4] + skills[6])/6
        case "MID": return (skills[2]*3 + skills[8] + skills[4] + skills[6])/6
        default: return (skills[3]*3 + skills[4] + skills[5] + skills[8])/6
        }
    }
    public var value: Int { max(25_000, Int(pow(Double(rating)/30, 4)*90_000 * valueMultiplier)) }
    private var valueMultiplier:Double {guard let d=development else{return 1};let age=d.valuationAge;let room=Double(zip(d.ceilings,skills).map{max(0,$0-$1)}.reduce(0,+))/9;return age<24 ? 1+room/70:age>29 ? max(0.15,1-Double(age-29)*0.1):1}
    public var wage: Int { max(300, rating*rating*2) }
}
public struct PlayerState: Codable, Equatable {
    public var fitness = 100
    public var morale = 75
    public var injuryWeeks = 0
    public var suspendedMatches:Int?
    public var yellowCards:Int?
    public var contractYears = 3
    public var wage: Int
    public var goals = 0
    public init(wage: Int) { self.wage = wage }
}
public struct Tactics: Codable, Equatable {
    public var formation = "4-4-2"
    public var mentality = "Balanced"
    public var passing = "Mixed"
    public var tackling = "Normal"
    public var captain:String?
    public var takers:[String:String]?
    public var winBonus:Int?
    public var offsideTrap:Bool?
    public var customPositions:[FieldPoint]?
    public var plan:TacticalPlan?
    public init() {}
    public var slots: [String] {
        let parts = formation.split(separator: "-").compactMap { Int($0) }
        return ["GK"] + Array(repeating:"DEF",count:parts[0]) + Array(repeating:"MID",count:parts[1]) + Array(repeating:"FWD",count:parts[2])
    }
}
public struct Fixture: Codable, Identifiable, Equatable {
    public var id: String
    public var round: Int
    public var home: String
    public var away: String
    public var homeGoals: Int?
    public var awayGoals: Int?
    public var competition:String?
    public var qualified:String?
    public var played: Bool { homeGoals != nil }
}
public struct Standing: Identifiable, Equatable {
    public var id: String
    public var played = 0, won = 0, drawn = 0, lost = 0, scored = 0, conceded = 0
    public var points: Int { won*3 + drawn }
    public var difference: Int { scored-conceded }
}
public struct News: Codable, Identifiable {
    public var id: UUID = UUID()
    public var week: Int
    public var category: String
    public var title: String
    public var body: String
}
public struct LedgerEntry: Codable, Identifiable {
    public var id: UUID = UUID()
    public var season:Int?
    public var week: Int
    public var description: String
    public var amount: Int
}
public struct Offer: Codable, Identifiable {
    public var id: UUID = UUID()
    public var playerID: String
    public var fee: Int
    public var wage: Int
    public var dueWeek: Int
    public var selling: Bool
}
public struct Construction: Codable {
    public var kind: String
    public var dueWeek: Int
}
public struct MatchEvent: Codable, Identifiable, Equatable {
    public var id: Int
    public var minute: Int
    public var text: String
    public var homeScore: Int
    public var awayScore: Int
}
public struct MatchReport: Codable, Equatable {
    public var home: String
    public var away: String
    public var homeGoals: Int
    public var awayGoals: Int
    public var possession: Int
    public var homeShots: Int
    public var awayShots: Int
    public var homePenalties:Int?
    public var awayPenalties:Int?
    public var attendance: Int
    public var events: [MatchEvent]
}
public struct RNG: Codable {
    public var state: UInt64
    public init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    public mutating func unit() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64(1)<<53)
    }
    public mutating func int(_ range: ClosedRange<Int>) -> Int { range.lowerBound + Int(unit()*Double(range.upperBound-range.lowerBound+1)) }
}
public struct Career: Codable {
    public var version = 1
    public var manager: String
    public var clubID: String
    public var clubs: [Club]
    public var players: [Player]
    public var states: [String:PlayerState]
    public var season = 1
    public var week = 0
    public var fixtures: [Fixture]
    public var lineup: [String] = []
    public var tactics = Tactics()
    public var training = "Balanced"
    public var intensity = "Normal"
    public var cash = 8_000_000
    public var ticketPrice = 20
    public var merchandisePrice = 25
    public var capacity = 30_000
    public var facilities = 1
    public var shops = 1
    public var sponsor = "Local partnership"
    public var sponsorship = 85_000
    public var confidence = 65
    public var debt = 0
    public var news: [News] = []
    public var ledger: [LedgerEntry] = []
    public var offers: [Offer] = []
    public var construction: Construction?
    public var squadOrder: [String]?
    public var ground: [GroundBuilding]?
    public var datasetName: String?
    public var activeMatch: LiveMatch?
    public var individualTraining: [String:String]?
    public var coachingLevel: Int?
    public var management: ManagementState?
    public var world: ClubWorld?
    public var finance: FinanceState?
    public var accountingWeek:Int?
    public var cups:[CupCompetition]?
    public var trophies:[Trophy]?
    public var lastMatch: MatchReport?
    public var history: [String] = []
    public var rng: RNG
    public var club: Club { clubs.first { $0.id == clubID }! }
    public var squad: [Player] { players.filter { $0.clubID == clubID } }
    public var wageBill: Int { squad.reduce(0) { $0 + (states[$1.id]?.wage ?? $1.wage) } }
    public var nextFixture: Fixture? { fixtures.first { !$0.played && ($0.home == clubID || $0.away == clubID) } }
    public var seasonFinished: Bool { fixtures.allSatisfy(\.played) }
    public var dateLabel: String { "\(1997+season)/\(String(1998+season).suffix(2)) · Week \(week + 1)" }
    public init(database: Database, clubID: String, manager: String, cash: Int = 8_000_000, seed: UInt64 = 9899) {
        self.datasetName = database.dataset; self.manager = manager; self.clubID = clubID; clubs = database.clubs; players = database.players
        self.cash = cash; rng = RNG(seed: seed)
        states = Dictionary(uniqueKeysWithValues: database.players.map { ($0.id,PlayerState(wage:$0.wage)) })
        fixtures = Self.schedule(clubs:database.clubs,season:1)
        let quality = squad.map(\.rating).reduce(0,+)/max(1,squad.count)
        capacity = Int(Double(10_000 + quality*400)*(club.division==0 ? 1:(club.division==1 ? 0.6:0.35)))
        ground = GroundRules.initial(capacity:capacity)
        if club.division>=2 {for i in ground!.indices where ground![i].kind=="Stand" {var spec=StandSpecification();spec.seated=false;spec.covered=ground![i].plotID=="north";ground![i].specification=spec}}
        shops = 2
        initializePlayerDevelopment()
        autoSelect()
        post("BOARD", "Welcome to \(club.name)", "\(manager), build a competitive side and keep the club solvent. The board expects a top-half finish. Your squad uses the Mega Update 1.2 database. Make this club your own.")
        post("ASSISTANT", "Your first week starts here", "Review the starting XI, set your tactics, then play the next week. Negotiations take a week; construction takes several. Progress is saved automatically after each match week.")
    }
    public func name(_ id: String) -> String { clubs.first { $0.id == id }?.name ?? id }
    public mutating func post(_ category: String, _ title: String, _ body: String) {
        news.insert(News(week:week,category:category,title:title,body:body),at:0)
        if news.count>120 {let saved=Set(world?.scrapbook ?? []);news=news.enumerated().filter{$0.offset<120 || saved.contains($0.element.id.uuidString)}.map(\.element)}
    }
    public mutating func transact(_ description: String, _ amount: Int) {
        if amount<0 && (description.hasPrefix("Stand development") || description.hasPrefix("Build Stand") || description.hasPrefix("Upgrade") || description.hasPrefix("Stand maintenance")) {initializeFinance();finance!.grantSpent+=abs(amount)}
        cash += amount; ledger.insert(LedgerEntry(season:season,week:accountingWeek ?? week,description:description,amount:amount),at:0)
        if ledger.count>10000 { ledger.removeLast(ledger.count-10000) }
    }
    public static func schedule(clubs: [Club], season: Int) -> [Fixture] {
        var fixtures: [Fixture] = []
        let groups = Dictionary(grouping:clubs,by:\.league)
        for key in groups.keys.sorted() {
            var ring = groups[key]!.map(\.id).sorted()
            if ring.count%2==1 { ring.append("BYE") }
            guard ring.count>=2 else { continue }
            let rounds=ring.count-1
            for r in 0..<rounds {
                for i in 0..<ring.count/2 {
                    let a=ring[i], b=ring[ring.count-1-i]
                    if a=="BYE" || b=="BYE" { continue }
                    let home=r%2==0 ? a:b, away=r%2==0 ? b:a
                    fixtures.append(Fixture(id:"\(season)-\(home)-\(away)",round:r,home:home,away:away))
                    fixtures.append(Fixture(id:"\(season)-\(away)-\(home)",round:r+rounds,home:away,away:home))
                }
                ring.insert(ring.removeLast(),at:1)
            }
        }
        return fixtures.sorted { $0.round == $1.round ? $0.id < $1.id : $0.round < $1.round }
    }
    public func table(league: String? = nil) -> [Standing] {
        let ids=Set(clubs.filter { $0.league == (league ?? club.league) }.map(\.id))
        var rows=Dictionary(uniqueKeysWithValues: ids.map { ($0,Standing(id:$0)) })
        for f in fixtures where f.played && f.competition==nil && ids.contains(f.home) {
            let h=f.homeGoals!,a=f.awayGoals!
            rows[f.home]!.played += 1;rows[f.away]!.played += 1
            rows[f.home]!.scored += h;rows[f.home]!.conceded += a
            rows[f.away]!.scored += a;rows[f.away]!.conceded += h
            if h==a { rows[f.home]!.drawn += 1;rows[f.away]!.drawn += 1 }
            else { let win=h>a ? f.home:f.away,loss=h>a ? f.away:f.home;rows[win]!.won += 1;rows[loss]!.lost += 1 }
        }
        return rows.values.sorted {
            if $0.points != $1.points { return $0.points > $1.points }
            if $0.difference != $1.difference { return $0.difference > $1.difference }
            if $0.scored != $1.scored { return $0.scored > $1.scored }
            return name($0.id)<name($1.id)
        }
    }
    public mutating func autoSelect() {
        var available=squad.filter { states[$0.id]?.injuryWeeks == 0 && (states[$0.id]?.suspendedMatches ?? 0)==0 }
        lineup=[]
        for position in tactics.slots {
            available.sort { a,b in selectionScore(a,position)>selectionScore(b,position) }
            if !available.isEmpty { lineup.append(available.removeFirst().id) }
        }
    }
    private func selectionScore(_ p: Player,_ position: String) -> Int {
        p.rating + (p.position==position ? 45:0) + (states[p.id]?.fitness ?? 100)/4
    }
    public mutating func select(_ playerID: String, slot: Int) {
        guard slot>=0 && slot<lineup.count, squad.contains(where:{$0.id==playerID}),states[playerID]?.injuryWeeks==0,(states[playerID]?.suspendedMatches ?? 0)==0 else { return }
        if let old=lineup.firstIndex(of:playerID) { lineup.swapAt(slot,old) } else { lineup[slot]=playerID }
    }
    public mutating func bid(playerID: String, fee: Int, wage: Int, selling: Bool = false) -> Bool {
        guard let p=players.first(where:{$0.id==playerID}), !offers.contains(where:{$0.playerID==playerID}) else { return false }
        guard selling ? (p.clubID==clubID && squad.count>16) : (p.clubID != clubID && fee>0 && fee<=cash && wage>0) else { return false }
        offers.append(Offer(playerID:playerID,fee:fee,wage:wage,dueWeek:week+1,selling:selling))
        post("NEGOTIATIONS", selling ? "\(p.name) offered to clubs":"Offer sent for \(p.name)", "A response will arrive after the next match week.")
        return true
    }
    public mutating func build(_ kind: String) -> Bool {
        let cost = kind=="Stand" ? 1_500_000 : (kind=="Training" ? facilities*750_000:400_000)
        guard construction==nil, cash>=cost, ["Stand","Training","Shop"].contains(kind) else { return false }
        transact("\(kind) construction",-cost)
        construction=Construction(kind:kind,dueWeek:week+(kind=="Stand" ? 4:3))
        post("DEVELOPMENT","Work begins: \(kind)","Construction completes in \(kind=="Stand" ? 4:3) weeks.")
        return true
    }
    public mutating func renew(_ id: String) {
        guard let p=squad.first(where:{$0.id==id}) else { return }
        let wage=max(p.wage,Int(Double(states[id]!.wage)*1.1))
        guard cash>=wage*4 else { return }
        states[id]!.contractYears=3;states[id]!.wage=wage;transact("Signing bonus: \(p.name)",-wage*4)
        post("CONTRACT","\(p.name) signs for three seasons","New weekly wage: £\(wage.formatted()).")
    }
}

extension Career {
    public var orderedSquad:[Player] {
        let members=Dictionary(uniqueKeysWithValues:squad.map{($0.id,$0)})
        var remaining=squad.filter{!lineup.contains($0.id)}.sorted{$0.rating>$1.rating}
        var bench:[String]=[]
        for role in ["GK","DEF","DEF","MID","MID","FWD","FWD"] {
            if let i=remaining.firstIndex(where:{$0.position==role && (states[$0.id]?.injuryWeeks ?? 0)==0}) {bench.append(remaining.remove(at:i).id)}
        }
        var seen=Set<String>()
        return (lineup+(squadOrder ?? (bench+remaining.map(\.id)))+squad.sorted{$0.rating>$1.rating}.map(\.id)).compactMap {id in
            guard seen.insert(id).inserted else {return nil};return members[id]
        }
    }
    @discardableResult public mutating func swapSquadPlayers(_ first:String,_ second:String)->Bool {
        var order=orderedSquad.map(\.id)
        guard first != second,let a=order.firstIndex(of:first),let b=order.firstIndex(of:second) else {return false}
        if (a<11 && ((states[second]?.injuryWeeks ?? 0)>0 || (states[second]?.suspendedMatches ?? 0)>0)) || (b<11 && ((states[first]?.injuryWeeks ?? 0)>0 || (states[first]?.suspendedMatches ?? 0)>0)) {return false}
        order.swapAt(a,b);lineup=Array(order.prefix(11));squadOrder=order;return true
    }
}
