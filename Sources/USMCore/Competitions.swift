import Foundation
public struct CupCompetition:Codable,Identifiable {
    public var id:String,country:String,name:String
    public var round=1
    public var byes:[String]=[]
    public var fixtureIDs:[String]=[]
    public var winner:String?
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
        let titles=["England":"FA Cup","Scotland":"Scottish Cup","France":"Coupe de France","Germany":"DFB Cup","Italy":"Coppa Italia","Spain":"Copa del Rey","Netherlands":"Dutch Cup"]
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
                if qualified[0]==clubID {transact("Cup winners prize",1_000_000);confidence=min(100,confidence+15)}
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
