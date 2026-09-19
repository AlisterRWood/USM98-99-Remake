import Foundation
public extension Career {
    func topScorers(league:String)->[Player] {
        let clubIDs=Set(clubs.filter{$0.league==league}.map(\.id))
        return players.filter{clubIDs.contains($0.clubID) && (states[$0.id]?.goals ?? 0)>0}.sorted{a,b in let x=states[a.id]?.goals ?? 0,y=states[b.id]?.goals ?? 0;return x==y ? a.name<b.name:x>y}
    }
    func recentForm(clubID:String)->String {
        let recent=fixtures.filter{$0.played && $0.competition==nil && ($0.home==clubID || $0.away==clubID)}.sorted{$0.round<$1.round}.suffix(6)
        return recent.map{f in let scored=f.home==clubID ? f.homeGoals!:f.awayGoals!,conceded=f.home==clubID ? f.awayGoals!:f.homeGoals!;return scored==conceded ? "D":(scored>conceded ? "W":"L")}.joined(separator:" ")
    }
}
