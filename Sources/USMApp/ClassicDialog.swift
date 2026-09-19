import SwiftUI
import USMCore

/// Shared raised-metal frame and inset red ribbons used by the original dialogs.
struct ClassicDialog<Content:View>:View {
    var title:String
    var subtitle:String = ""
    @ViewBuilder var content:Content
    var body:some View {
        VStack(spacing:12) {
            HStack {
                Text(title).font(.system(size:27,weight:.black,design:.rounded)).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                Text(subtitle).font(.system(size:14,weight:.bold))
            }.foregroundStyle(.white).padding(.horizontal,20).padding(.vertical,7).classicRibbon()
            content
        }.padding(12).foregroundStyle(.black)
            .background(LinearGradient(colors:[Color(white:0.92),Color(white:0.67),Color(white:0.86),Color(white:0.72)],startPoint:.topLeading,endPoint:.bottomTrailing))
            .overlay(Rectangle().strokeBorder(Color(white:0.22),lineWidth:2))
            .overlay(Rectangle().inset(by:3).strokeBorder(.white.opacity(0.9),lineWidth:2))
            .compositingGroup()
            .shadow(color:.black.opacity(0.65),radius:3,x:5,y:6)
            .buttonStyle(GameButton())
    }
}
extension View {
    func classicRibbon()->some View {
        background(LinearGradient(colors:[Color(white:0.06),Color(red:0.8,green:0.04,blue:0.01),Color(red:0.45,green:0,blue:0),Color(white:0.06)],startPoint:.top,endPoint:.bottom),in:Capsule())
            .overlay(Capsule().stroke(Color(white:0.3),lineWidth:3))
    }
    func classicSheet(_ title:String)->some View {
        ClassicDialog(title:title) {self.foregroundStyle(.white)}
    }
}

struct MatchIntervalDialog:View {
    @EnvironmentObject var store:GameStore
    var match:LiveMatch
    var competition:String
    var body:some View {
        ClassicDialog(title:match.isFinished ? "Full Time":"Half Time",subtitle:competition) {
            HStack {
                team(match.home,score:match.homeGoals,color:Color(red:0.88,green:0.08,blue:0))
                team(match.away,score:match.awayGoals,color:royal)
            }
            Divider().overlay(Color.gray)
            HStack(alignment:.top) {incidents(0);Image(systemName:"soccerball").foregroundStyle(.black);incidents(1)}.frame(minHeight:50,maxHeight:110)
            Divider().overlay(Color.gray)
            VStack(spacing:5) {
                row("Shots",String(match.homeShots),String(match.awayShots))
                row("Shots On Target",match.homeShotsOnTarget.map(String.init) ?? "—",match.awayShotsOnTarget.map(String.init) ?? "—")
                row("Free Kicks",String(count("free kick",0)),String(count("free kick",1)))
                row("Corners",String(count("corner",0)),String(count("corner",1)))
                row("Possession","\(match.homePossessionPercent)%","\(100-match.homePossessionPercent)%")
                row("Yellow Cards",String(bookings(0)),String(bookings(1)))
                row("Red Cards",String(count("red",0)),String(count("red",1)))
                if let home=match.homePenalties,let away=match.awayPenalties {row("Penalties",String(home),String(away))}
            }.padding(.vertical,6)
            HStack {
                if !match.isFinished {Button("Subs / Team Talk") {store.matchControls=true}.frame(maxWidth:.infinity)}
                Button(match.isFinished ? "Continue":"Resume Game") {if match.isFinished {store.finishMatch()} else {store.toggleMatch()}}.frame(maxWidth:.infinity)
            }.padding(8).classicRibbon()
        }.frame(maxWidth:940).padding(.horizontal,30)
    }
    func team(_ id:String,score:Int,color:Color)->some View {
        VStack(spacing:1) {Text(store.career.name(id)).lineLimit(1).minimumScaleFactor(0.6);Text("\(score)").monospacedDigit()}.font(.system(size:25,weight:.black,design:.rounded)).foregroundStyle(color).frame(maxWidth:.infinity)
    }
    func count(_ kind:String,_ side:Int)->Int {match.events.filter{$0.kind==kind && $0.side==side}.count}
    func bookings(_ side:Int)->Int {match.players.filter{$0.side==side}.reduce(0){$0+(match.yellowCards?[$1.id] ?? 0)}}
    func row(_ label:String,_ home:String,_ away:String)->some View {
        HStack {Text(home).foregroundStyle(royal).frame(maxWidth:.infinity);Text(label).frame(width:200);Text(away).foregroundStyle(royal).frame(maxWidth:.infinity)}.font(.system(size:16,weight:.bold)).monospacedDigit()
    }
    func incidents(_ side:Int)->some View {
        ScrollView {VStack(spacing:3) {ForEach(match.events.filter{$0.side==side && ["goal","yellow","red"].contains($0.kind)}) {event in
            Text("\(event.minute)′  \(match.players.first{$0.id==event.playerID}?.name ?? "")\(event.kind=="yellow" ? "  ▨":event.kind=="red" ? "  ■":"  ⚽")")
                .foregroundStyle(event.kind=="red" ? Color.red:event.kind=="yellow" ? Color(red:0.45,green:0.32,blue:0):royal)
        }}}.font(.system(size:13,weight:.bold)).frame(maxWidth:.infinity)
    }
}
