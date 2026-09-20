import SwiftUI
import USMCore

struct ArchiveView:View {
    @EnvironmentObject var store:GameStore
    @ViewState var clubName=""
    var club:Club {store.career.clubs.first{$0.name==clubName} ?? store.career.club}
    var fixtures:[Fixture] {store.career.fixtures.filter{$0.played && ($0.home==club.id || $0.away==club.id)}}
    var body:some View {
        ClassicScreen(title:"Team Data") {
            GameChoice(label:"Club",value:$clubName,options:store.career.clubs.map(\.name).sorted())
            Grid(alignment:.leading,horizontalSpacing:25,verticalSpacing:14) {
                GridRow {Text("Club name").foregroundStyle(mint);Text(club.name);Text("League").foregroundStyle(mint);Text(club.league)}
                GridRow {Text("Nickname").foregroundStyle(mint);Text(club.nickname);Text("Position").foregroundStyle(mint);Text("\((store.career.table(league:club.league).firstIndex{$0.id==club.id} ?? 0)+1)")}
                GridRow {Text("Ground name").foregroundStyle(mint);Text(club.stadium);Text("Manager").foregroundStyle(mint);Text(club.id==store.career.clubID ? store.career.manager:club.manager)}
                GridRow {Text("Biggest win").foregroundStyle(mint);Text(bestResult(win:true));Text("Biggest defeat").foregroundStyle(mint);Text(bestResult(win:false))}
            }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(Color(red:0.08,green:0.27,blue:0.27))
            Text("Season record").font(.title3.bold()).foregroundStyle(mint)
            if let row=store.career.table(league:club.league).first(where:{$0.id==club.id}) {Text("Played \(row.played)     Won \(row.won)     Drawn \(row.drawn)     Lost \(row.lost)     For \(row.scored)     Against \(row.conceded)     Points \(row.points)").monospacedDigit()}
            Text("Recent league history").font(.title3.bold()).foregroundStyle(mint)
            ScrollView {LazyVStack(alignment:.leading){if club.id==store.career.clubID {ForEach(store.career.history,id:\.self){Text($0).padding(6)}}}}
            HStack {Button("Players") {store.page="Transfers"};Button("Fixtures / results") {store.page="Competitions"};Button("Season recap") {store.page="Season recap"};Button("Trophy cabinet") {store.page="Trophies"}}
        }.onAppear {clubName=store.career.club.name}
    }
    func bestResult(win:Bool)->String {
        guard let f=fixtures.sorted(by:{a,b in let ad=(a.homeGoals!-a.awayGoals!)*(a.home==club.id ? 1:-1),bd=(b.homeGoals!-b.awayGoals!)*(b.home==club.id ? 1:-1);return win ? ad>bd:ad<bd}).first else{return "N/A"}
        let difference=(f.homeGoals!-f.awayGoals!)*(f.home==club.id ? 1:-1);guard win ? difference>0:difference<0 else{return "N/A"}
        return "\(f.homeGoals!)–\(f.awayGoals!) v "+store.career.name(f.home==club.id ? f.away:f.home)
    }
}
