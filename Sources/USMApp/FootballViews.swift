import SwiftUI
import Combine
import USMCore

struct SquadView:View {
    @EnvironmentObject var store:GameStore
    @ViewState var selected:String?
    @ViewState var highlighted:String?
    @ViewState var carried:String?
    @ViewState var slot=0
    @ViewState var feedback="Right-click a player to pick them up, then left-click another player to swap. Escape cancels."
    var body:some View {
        VStack(spacing:0) {
            Text("TEAM SELECTION").font(.system(size:23,weight:.bold,design:.serif)).frame(maxWidth:.infinity).padding(12)
                .background(LinearGradient(colors:[Color(red:0.65,green:0.08,blue:0.06),Color(red:0.20,green:0.02,blue:0.025)],startPoint:.top,endPoint:.bottom))
            HStack(alignment:.top,spacing:0) {
                SquadTable(career:store.career,carried:$carried,highlighted:$highlighted,onSwap:{a,b in
                    if store.career.swapSquadPlayers(a,b) {store.save();feedback="Players swapped. Team selection saved."}
                    else {feedback="An injured player cannot enter the starting eleven."}
                },onRecord:{selected=$0}).frame(maxHeight:.infinity)
                VStack(spacing:16) {
                    Button(carried == nil ? "Swap position":"Cancel swap") {if carried != nil {carried=nil} else {carried=highlighted}}.disabled(highlighted==nil && carried==nil)
                    Button("Player record") {selected=highlighted}.disabled(highlighted==nil)
                    Button("Assistant: pick XI") {carried=nil;store.career.autoSelect();store.save()}
                    Button("Tactics / team talk") {store.page="Tactics"}
                    Spacer()
                    Button("Start match") {store.advance()}.buttonStyle(AccentButton())
                    Button("Exit to dressing room") {store.enter("Dressing room")}
                }.buttonStyle(GameButton(red:true)).padding(16).frame(width:190).frame(maxHeight:.infinity).background(Color(white:0.13))
            }.frame(maxHeight:.infinity)
            Text(carried.flatMap{id in store.career.squad.first{$0.id==id}}.map{"Moving \($0.name) — left-click the player to swap with; Escape cancels."} ?? feedback)
                .font(.system(size:12)).foregroundStyle(mint).frame(maxWidth:.infinity,alignment:.leading).padding(12).background(ink)
        }.clipShape(RoundedRectangle(cornerRadius:10))
        .onExitCommand {carried=nil}
        .sheet(isPresented:Binding(get:{selected != nil},set:{if !$0 {selected=nil}})) {if let p=store.career.players.first(where:{$0.id==selected}) {PlayerRecord(player:p)}}
    }
}

struct TacticalPitch:View {
    var lineup:[Player]
    var formation:String
    var body:some View {
        GeometryReader { geo in
            ZStack {
                PitchLines()
                ForEach(Array(lineup.enumerated()),id:\.element.id) { i,p in
                    let point=position(i,size:geo.size)
                    VStack(spacing:5) { Text("\(i+1)").font(.system(size:12,weight:.black)).foregroundStyle(.white).frame(width:35,height:35).background(i==0 ? Color.orange:crimson,in:Circle()).overlay(Circle().stroke(.white.opacity(0.5),lineWidth:2));Text(p.name.components(separatedBy:" ").last ?? p.name).font(.system(size:10,weight:.semibold)).padding(.horizontal,7).padding(.vertical,3).background(ink.opacity(0.8),in:Capsule()) }.position(point)
                }
            }
        }
    }
    func position(_ i:Int,size:CGSize)->CGPoint {
        if i==0 { return CGPoint(x:size.width*0.5,y:size.height*0.87) }
        let lines=formation.split(separator:"-").compactMap{Int($0)}
        var offset=1
        for row in 0..<lines.count {
            if i<offset+lines[row] { return CGPoint(x:size.width*CGFloat(i-offset+1)/CGFloat(lines[row]+1),y:size.height*(0.67-Double(row)*0.23)) }
            offset += lines[row]
        }
        return .zero
    }
}
struct PitchLines:View {
    var body:some View {
        Canvas { context,size in
            let w=size.width,h=size.height
            for i in 0..<12 { context.fill(Path(CGRect(x:0,y:h*Double(i)/12,width:w,height:h/12+1)),with:.color(Color(red:0.075,green:i%2==0 ? 0.25:0.28,blue:0.19))) }
            let margin:CGFloat=18,r=CGRect(x:margin,y:margin,width:w-2*margin,height:h-2*margin)
            var path=Path();path.addRect(r);path.move(to:CGPoint(x:margin,y:h/2));path.addLine(to:CGPoint(x:w-margin,y:h/2));path.addEllipse(in:CGRect(x:w/2-45,y:h/2-45,width:90,height:90))
            path.addRect(CGRect(x:w*0.23,y:margin,width:w*0.54,height:h*0.16));path.addRect(CGRect(x:w*0.23,y:h-margin-h*0.16,width:w*0.54,height:h*0.16))
            path.addRect(CGRect(x:w*0.36,y:margin,width:w*0.28,height:h*0.065));path.addRect(CGRect(x:w*0.36,y:h-margin-h*0.065,width:w*0.28,height:h*0.065))
            context.stroke(path,with:.color(.white.opacity(0.38)),lineWidth:1.4)
        }.clipShape(RoundedRectangle(cornerRadius:10))
    }
}
