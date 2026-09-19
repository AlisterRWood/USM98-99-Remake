import Foundation

/// Reconstructed development profile; original potential bytes are not decoded.
public struct PlayerDevelopment:Codable,Equatable {
    public var ceilings:[Int]
    public var progress:[Double]
    public var aptitude:Double
    public var retirementAge:Int
    public var valuationAge:Int
    public var generated:Bool
    public var estimatedBirthDate:Bool
    public var estimatedBirthYear:Bool?
}
extension Player {
    public var dateOfBirth:String {guard let year=birthYear else{return "Unknown"};return String(format:"%02d/%02d/%04d",birthDay ?? 1,birthMonth ?? 1,year)}
    public var potentialDescription:String {
        guard let d=development else{return "Unassessed"}
        let gain=zip(d.ceilings,skills).map{$0-$1}.max() ?? 0
        return gain>25 ? "Exceptional room to develop":gain>15 ? "Strong development prospects":gain>5 ? "Some improvement possible":"Close to current ceiling"
    }
}
extension Career {
    public mutating func restorePlayerBirthDates(from database:Database) {
        let records=Dictionary(uniqueKeysWithValues:database.players.map{($0.id,$0)})
        for i in players.indices where players[i].birthYear==nil || players[i].development?.estimatedBirthDate==true {
            guard let record=records[players[i].id],record.name==players[i].name,
                  record.birthYear==players[i].birthYear || players[i].birthYear==nil || players[i].development?.estimatedBirthYear==true else {continue}
            if players[i].development?.estimatedBirthYear==true && record.birthYear != nil {players[i].development=nil}
            players[i].birthYear=record.birthYear;players[i].birthMonth=record.birthMonth;players[i].birthDay=record.birthDay
            players[i].development?.estimatedBirthDate=record.birthDay==nil || record.birthMonth==nil
        }
        initializePlayerDevelopment()
    }
    /// Stable per-player migration does not consume match RNG or reroll on load.
    public mutating func initializePlayerDevelopment() {
        for i in players.indices {
            let hash=players[i].id.utf8.reduce(UInt64(1469598103934665603)){($0 ^ UInt64($1)) &* 1099511628211}
            let estimatedYear=players[i].birthYear==nil
            let estimated=players[i].birthDay==nil || players[i].birthMonth==nil || players[i].birthYear==nil
            if players[i].birthYear==nil {players[i].birthYear=1998-Int(19+hash%15)}
            if players[i].birthMonth==nil {players[i].birthMonth=1}
            if players[i].birthDay==nil {players[i].birthDay=1}
            let age=players[i].age(season:season) ?? 27
            if players[i].development==nil {
                let talent=Int(hash%100),headroom=age<23 ? (talent>89 ? 38:talent>59 ? 24:10):max(2,32-age)
                players[i].development=PlayerDevelopment(ceilings:players[i].skills.enumerated().map{min(99,$0.element+max(0,headroom-Int((hash >> ($0.offset*3))%8)))},progress:Array(repeating:0,count:9),aptitude:0.55+Double(talent)/100,retirementAge:(players[i].position=="GK" ? 37:34)+Int((hash>>8)%6),valuationAge:age,generated:false,estimatedBirthDate:estimated,estimatedBirthYear:estimatedYear)
            }
            players[i].development?.valuationAge=age
        }
    }
    public mutating func developPlayer(at index:Int,skill:Int,effort:Double) {
        guard players.indices.contains(index),(0..<9).contains(skill),effort>0,effort.isFinite,var d=players[index].development else{return}
        let age=players[index].age(season:season) ?? 27
        let ageFactor=age<21 ? 1.6:age<25 ? 1.0:age<29 ? 0.45:0.12
        guard players[index].skills[skill]<d.ceilings[skill] else{return}
        let room=Double(d.ceilings[skill]-players[index].skills[skill])
        d.progress[skill]+=effort*d.aptitude*ageFactor*min(1,0.3+room/20)
        let points=Int(d.progress[skill]);d.progress[skill]-=Double(points)
        players[index].skills[skill]=min(d.ceilings[skill],players[index].skills[skill]+points)
        players[index].development=d
    }
    /// Experience for both human and AI clubs; only players selected for a fixture benefit.
    public mutating func developFromMatch(_ ids:Set<String>) {
        for i in players.indices where ids.contains(players[i].id) {
            let skill=players[i].position=="GK" ? 0:players[i].position=="DEF" ? 1:players[i].position=="MID" ? 2:3
            developPlayer(at:i,skill:skill,effort:0.22)
        }
    }
    public mutating func rollOverPlayers() {
        initializePlayerDevelopment()
        let namePool=players.map(\.name)
        var retired=Set<String>()
        for i in players.indices {
            let age=players[i].age(season:season) ?? 27
            if age >= (players[i].development?.retirementAge ?? 39) {
                retired.insert(players[i].id)
                if players[i].clubID==clubID {post("RETIREMENT","\(players[i].name) retires","Age \(age). The club thanks him for his service. Youth recruits will fill any places below a squad of 20.")}
            } else if age >= (players[i].position=="GK" ? 34:30) {
                for skill in 0..<9 {
                    let physical=[4,6].contains(skill),loss=physical ? max(1,(age-28)/2):max(0,(age-31)/3)
                    players[i].skills[skill]=max(1,players[i].skills[skill]-loss)
                }
            }
        }
        players.removeAll{retired.contains($0.id)}
        for id in retired {states.removeValue(forKey:id)}
        lineup.removeAll{retired.contains($0)}
        squadOrder?.removeAll{retired.contains($0)}
        individualTraining=individualTraining?.filter{!retired.contains($0.key)}
        if management != nil {
            management!.assignments=management!.assignments.filter{!retired.contains($0.key)}
            management!.negotiations.removeAll{retired.contains($0.playerID)}
            management!.loans.removeAll{retired.contains($0.playerID)}
            management!.shortlist.removeAll{retired.contains($0)}
            management!.scouts.removeAll{retired.contains($0.playerID)}
            management!.listed=management!.listed.filter{!retired.contains($0.key)}
            management!.loanListed=management!.loanListed?.filter{!retired.contains($0.key)}
            management!.playerBonuses=management!.playerBonuses?.filter{!retired.contains($0.key)}
            management!.obligations?.removeAll{retired.contains($0.playerID)}
        }
        if let captain=tactics.captain,retired.contains(captain){tactics.captain=nil}
        tactics.takers=tactics.takers?.filter{!retired.contains($0.value)}
        let firsts=namePool.compactMap{$0.split(separator:" ").first.map(String.init)}
        let lasts=namePool.compactMap{$0.split(separator:" ").last.map(String.init)}
        for team in clubs {
            let teamPlayers=players.filter{$0.clubID==team.id}
            let count=max(0,20-teamPlayers.count)
            for slot in 0..<count {
                let position=slot==0 && !teamPlayers.contains(where:{$0.position=="GK"}) ? "GK":["GK","DEF","MID","FWD"][rng.int(0...3)]
                let age=rng.int(16...18),month=rng.int(1...12),day=rng.int(1...28)
                let year=1997+season-age-((month>8 || (month==8 && day>1)) ? 1:0)
                var skills=(0..<9).map{_ in rng.int(20...48)}
                let main=position=="GK" ? 0:position=="DEF" ? 1:position=="MID" ? 2:3
                skills[main]=rng.int(42...66)
                let name=(firsts.isEmpty ? "Alex":firsts[rng.int(0...firsts.count-1)])+" "+(lasts.isEmpty ? "Smith":lasts[rng.int(0...lasts.count-1)])
                let id="youth-\(season)-\(team.id)-\(slot)"
                let p=Player(id:id,name:name,clubID:team.id,position:position,skills:skills,birthYear:year,birthMonth:month,birthDay:day)
                players.append(p);states[id]=PlayerState(wage:max(100,p.wage/5))
                if team.id==clubID {post("YOUTH","\(name) joins the senior squad","\(age)-year-old \(position), promoted free of charge. Weekly wage £\(states[id]!.wage). Assess his training and development over time.")}
            }
        }
        initializePlayerDevelopment()
        for i in players.indices where players[i].id.hasPrefix("youth-\(season)-") {players[i].development?.generated=true;players[i].development?.estimatedBirthDate=false}
    }
}
