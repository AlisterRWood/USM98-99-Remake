import SwiftUI
import USMCore

struct MatchTunnelView:View {
    @EnvironmentObject var store:GameStore
    var fixture:Fixture? {store.career.fixtures.first{!$0.played && $0.round==store.career.week && ($0.home==store.career.clubID || $0.away==store.career.clubID)}}
    var homeName:String { fixture.map { store.career.name($0.home) } ?? "Home" }
    var awayName:String { fixture.map { store.career.name($0.away) } ?? "Away" }
    var competition:String { fixture?.competition ?? "League Match" }
    var stadium:String { guard let f=fixture else { return "Home Ground" }; return store.career.clubs.first{$0.id==f.home}?.stadium ?? "Home Ground" }
    var referee:String { ["P Alcock","J Durkin","A Wilkie","M Riley"][max(0,store.career.week) % 4] }
    private static let artwork: NSImage? = Bundle.module.url(forResource:"MatchTunnel",withExtension:"png",subdirectory:"Resources").flatMap {NSImage(contentsOf:$0)}
    var body:some View {
        GeometryReader { geo in
            // Fit both artwork and hotspots into the same 3:2 coordinate space.
            // Letterboxing preserves the doors at every window aspect ratio.
            let width=min(geo.size.width,geo.size.height*1.5)
            let height=width/1.5
            ZStack {
                if let image=Self.artwork {Image(nsImage:image).resizable().interpolation(.high)}
                hotspot("Cancel — return to changing room",x:0.08,y:0.13,w:0.18,h:0.77,width:width,height:height) {store.cancelMatchday()}
                // The original console offers the watch/instant decision once the
                // teams are on the pitch, rather than committing it at the tunnel.
                hotspot("Enter pitch",x:0.74,y:0.13,w:0.18,h:0.77,width:width,height:height) {store.beginMatch(watch:true)}
                hotspot("Enter pitch — watch match",x:0.34,y:0.25,w:0.32,h:0.44,width:width,height:height) {store.beginMatch(watch:true)}
                VStack(spacing:0) {
                    Text("\(homeName)   Vs   \(awayName)").font(.system(size:width*0.025,weight:.black,design:.rounded)).lineLimit(1).minimumScaleFactor(0.6).frame(maxWidth:.infinity).padding(.vertical,7).background(LinearGradient(colors:[.black,crimson,.black],startPoint:.top,endPoint:.bottom),in:Capsule()).overlay(Capsule().stroke(chrome,lineWidth:2))
                    HStack {Text("At \(stadium)");Spacer();Text("In the \(competition)")}.font(.system(size:width*0.015,weight:.bold)).padding(.top,5)
                    HStack {Text("Today's Referee is \(referee)");Spacer();Text("Pitch Quality : \(store.career.facilities > 2 ? "Excellent" : "Good")")}.font(.system(size:width*0.014,weight:.semibold)).padding(.top,4)
                    Spacer()
                }.padding(.horizontal,16).padding(.top,10).shadow(color:.black,radius:2).allowsHitTesting(false)
            }.frame(width:width,height:height).position(x:geo.size.width/2,y:geo.size.height/2)
        }.background(.black).onExitCommand {store.cancelMatchday()}.onAppear {store.audio.play("sq_tunnel")}
    }
    func hotspot(_ label:String,x:CGFloat,y:CGFloat,w:CGFloat,h:CGFloat,width:CGFloat,height:CGFloat,action:@escaping()->Void)->some View {
        Button(action:action) {Color.clear.contentShape(Rectangle())}
            .buttonStyle(.plain).accessibilityLabel(label).help(label)
            .frame(width:w*width,height:h*height).position(x:(x+w/2)*width,y:(y+h/2)*height)
    }
}
typealias MatchChoice = MatchTunnelView
struct MatchView:View {
    @ViewState var replay=false
    @ViewState var replayIndex=0.0
    @EnvironmentObject var store:GameStore
    var body:some View {
        if let m=store.career.activeMatch {
            VStack(spacing:0) {
                LivePitch(match:replay ? replayMatch(m):m,boardBrands:matchdayBoards,shirtSponsor:matchdayShirtSponsor)
                    .overlay(alignment:.top) {if let restart=m.setPieceRestart,!replay {Text(restart.kind.uppercased()+" · "+(m.players.first{$0.id==restart.taker}?.name ?? "Preparing restart")).font(.system(size:12,weight:.bold)).padding(8).background(crimson,in:Capsule()).padding(16)}}
                scoreboard(m)
                matchInfoRibbon(m)
                controls(m)
            }.background(ink).ignoresSafeArea(edges:.top)
            .overlay { matchOverlay(m) }
            .sheet(isPresented:$store.matchControls) {TouchlineControls().classicSheet("Team Talk & Substitutions").environmentObject(store)}
        } else {VStack {Text("No match in progress.");Button("Return to club") {store.screen="club"}}}
    }
    @ViewBuilder func matchOverlay(_ m:LiveMatch) -> some View {
        if let card=store.matchCard {
            ZStack {
                Color.black.opacity(0.3).ignoresSafeArea()
                ClassicDialog(title:card.kind=="red" ? "Red Card":"Yellow Card") {
                    RoundedRectangle(cornerRadius:4).fill(card.kind=="red" ? Color.red:Color.yellow).frame(width:65,height:94)
                    Text(card.kind=="red" ? "RED CARD":"YELLOW CARD").font(.system(size:28,weight:.black))
                    Text(card.text).multilineTextAlignment(.center)
                    if card.kind=="red" {Text("Sent off. Suspended for the next 3 matches.").font(.system(size:13))}
                }.frame(width:500)
            }.allowsHitTesting(false)
        } else if let event=m.events.last, event.kind=="goal", m.restartDelay>0 {
            let scorer = event.playerID.flatMap { id in m.players.first(where: {$0.id==id})?.name } ?? "A superb finish"
            MatchEventPopup(title:"GOAL!",subtitle:scorer,detail:"\(event.minute)′  \(store.career.name(m.home))  \(m.homeGoals) – \(m.awayGoals)  \(store.career.name(m.away))",icon:"soccerball")
        } else if m.phase == .halfTime {
            MatchIntervalDialog(match:m,competition:fixtureCompetition(m))
        } else if m.phase == .fullTime {
            MatchIntervalDialog(match:m,competition:fixtureCompetition(m))
        } else if m.phase == .ready {
            MatchStartPopup(home:store.career.name(m.home),away:store.career.name(m.away),competition:fixtureCompetition(m),stadium:fixtureStadium(m))
        }
    }
    func replayMatch(_ match:LiveMatch)->LiveMatch {
        guard let frames=match.replayFrames,!frames.isEmpty else{return match}
        let frame=frames[min(frames.count-1,Int(replayIndex))];var copy=match;copy.ball=frame.ball;copy.elapsed=frame.time;copy.homeGoals=frame.home;copy.awayGoals=frame.away;copy.flight=nil
        for i in copy.players.indices {copy.players[i].onPitch=frame.points[copy.players[i].id] != nil;if let point=frame.points[copy.players[i].id]{copy.players[i].point=point}}
        return copy
    }
    // Boards only display contracts the player has actually sold. This preserves
    // the original game's commercial loop while making every accepted offer
    // visible on match day.
    var matchdayBoards:[String] {
        let sold=store.career.managementState.deals.filter{$0.accepted && $0.kind=="Pitch boards"}.map(\.brand)
        return sold.isEmpty ? ["USM 98/99","THE BEAUTIFUL GAME","MATCHDAY"]:sold
    }
    var matchdayShirtSponsor:String {
        let deal=store.career.managementState.deals.first{$0.accepted && $0.kind=="Club sponsor"}
        return deal?.brand ?? store.career.sponsor
    }
    func scoreboard(_ m:LiveMatch)->some View {
        HStack(spacing:5) {
            Text("›  \(store.career.name(m.home))").frame(maxWidth:.infinity,alignment:.leading)
            scoreBox(m.homeGoals)
            scoreBox(m.awayGoals)
            Text("\(store.career.name(m.away))  ‹").frame(maxWidth:.infinity,alignment:.trailing)
        }.font(.system(size:24,weight:.black,design:.rounded)).lineLimit(1).minimumScaleFactor(0.55)
            .padding(.horizontal,18).padding(.vertical,7)
            .background(LinearGradient(colors:[Color(red:0.22,green:0.01,blue:0.01),crimson,Color(red:0.22,green:0.01,blue:0.01)],startPoint:.top,endPoint:.bottom))
            .overlay(Rectangle().stroke(chrome,lineWidth:2))
    }
    func scoreBox(_ score:Int)->some View {Text("\(score)").font(.system(size:31,weight:.black,design:.rounded)).monospacedDigit().frame(width:72,height:43).background(royal.opacity(0.82)).overlay(RoundedRectangle(cornerRadius:3).stroke(.black,lineWidth:2))}
    func matchInfoRibbon(_ m:LiveMatch)->some View {
        HStack {
            Text("At \(fixtureStadium(m))").frame(maxWidth:.infinity,alignment:.leading)
            Text("Time: \(Int(m.elapsed/60))").padding(.horizontal,24).padding(.vertical,3).background(.white.opacity(0.18),in:Capsule())
            Text(fixtureCompetition(m)).frame(maxWidth:.infinity,alignment:.trailing)
        }.font(.system(size:15,weight:.bold,design:.serif)).foregroundStyle(.black).padding(.horizontal,22).padding(.vertical,5).background(LinearGradient(colors:[.white.opacity(0.92),Color(white:0.58),.white.opacity(0.9)],startPoint:.top,endPoint:.bottom))
    }
    func fixtureStadium(_ m:LiveMatch)->String {store.career.clubs.first{$0.id==m.home}?.stadium ?? "Home Ground"}
    func fixtureCompetition(_ m:LiveMatch)->String {store.career.fixtures.first{$0.id==m.fixtureID}?.competition ?? "League Match"}
    func phaseLabel(_ m:LiveMatch)->String {
        switch m.phase {case .ready:return "BEFORE KICK-OFF";case .halfTime:return "HALF-TIME";case .fullTime:return "FULL-TIME";default:return store.matchRunning ? "LIVE":"PAUSED"}
    }
    func controls(_ m:LiveMatch)->some View {
        HStack(spacing:0) {
            HStack(spacing:10) {
                if m.isFinished {consoleButton("Continue") {store.finishMatch()}}
                else if m.phase != .ready {consoleButton(m.phase == .halfTime ? "Second half":"\(store.matchRunning ? "Pause":"Resume")") {store.toggleMatch()}.keyboardShortcut(.space,modifiers:[])}
                consoleButton(replay ? "Live":"Replay") {store.matchRunning=false;replay.toggle();replayIndex=Double(max(0,(m.replayFrames?.count ?? 1)-1))}.disabled((m.replayFrames?.count ?? 0)<2)
                consoleButton("Options") {store.matchRunning=false;store.matchControls=true;store.save()}.disabled(m.isFinished || m.phase == .ready)
                if !m.isFinished && m.phase != .ready {consoleButton("Instant") {store.instantRemainder()}}
                VStack(spacing:1) {Text("SPEED").font(.system(size:8,weight:.black));MatchSpeedControl().frame(width:112).disabled(m.isFinished)}
            }.padding(10).frame(maxWidth:.infinity)
            Divider().background(.black)
            commentaryBar(m).frame(width:330).padding(.horizontal,12).padding(.vertical,7)
        }.frame(minHeight:84).background(LinearGradient(colors:[Color(white:0.85),Color(white:0.48)],startPoint:.top,endPoint:.bottom)).foregroundStyle(.black)
    }
    func consoleButton(_ title:String,action:@escaping()->Void)->some View {Button(title,action:action).buttonStyle(MatchConsoleButton())}
    func commentaryBar(_ m:LiveMatch)->some View {
        VStack(alignment:.leading,spacing:3) {
            HStack {Text("COMMENTARY").font(.system(size:9,weight:.black)).tracking(1);Spacer();Text("\(m.homeShots) shots  ·  \(m.homePossessionPercent)% possession").font(.system(size:8,weight:.bold))}
            Text(m.events.last?.text ?? "Waiting for kick-off.").font(.system(size:12,weight:.bold)).lineLimit(2).frame(maxWidth:.infinity,alignment:.leading)
        }
    }
}
struct MatchConsoleButton:ButtonStyle {
    func makeBody(configuration:Configuration)->some View {configuration.label.font(.system(size:15,weight:.black,design:.rounded)).foregroundStyle(.yellow).padding(.horizontal,17).padding(.vertical,6).background(LinearGradient(colors:[Color.red.opacity(configuration.isPressed ? 0.62:0.95),Color(red:0.28,green:0.01,blue:0.01)],startPoint:.top,endPoint:.bottom),in:Capsule()).overlay(Capsule().stroke(.black,lineWidth:2))}
}
struct MatchStartPopup:View {
    @EnvironmentObject var store:GameStore
    var home:String;var away:String;var competition:String;var stadium:String
    var body:some View {
        ClassicDialog(title:"Match Ready",subtitle:competition) {
            Text("\(home)  v  \(away)").font(.system(size:22,weight:.black)).foregroundStyle(royal)
            Text("At \(stadium)").font(.system(size:14,weight:.bold))
            HStack(spacing:18) {
                Button("Kick Off") {store.toggleMatch()}
                Button("Instant") {store.instantRemainder()}
                Button("Cancel") {store.cancelMatchday()}
            }.frame(maxWidth:.infinity).padding(8).classicRibbon()
        }.frame(width:600)
    }
}
struct MatchEventPopup:View {
    var title:String; var subtitle:String; var detail:String; var icon:String
    var body:some View {
        ClassicDialog(title:title) {
            Image(systemName:icon).font(.system(size:82,weight:.black)).foregroundStyle(.white,.gray).padding(.vertical,26)
            Text(subtitle.uppercased()).font(.system(size:28,weight:.black,design:.rounded)).foregroundStyle(royal)
            Text(detail).font(.system(size:15,weight:.bold,design:.monospaced)).padding(.top,8)
        }.frame(width:600).allowsHitTesting(false)
    }
}
struct LivePitch:View {
    var match:LiveMatch
    var boardBrands:[String]
    var shirtSponsor:String
    var body:some View {
        GeometryReader { geo in
            let width=min(geo.size.width,geo.size.height*1.85)
            let height=width/1.85
            Canvas {context,size in draw(context:&context,size:size)}
                .frame(width:width,height:height).position(x:geo.size.width/2,y:geo.size.height/2)
                .overlay(alignment:.topLeading) {HStack {Circle().fill(match.isFinished ? muted:Color.red).frame(width:6,height:6);Text(match.phase == .halfTime ? "HALF-TIME · TEAM TALK":"\(match.attendance.formatted()) SUPPORTERS").font(.system(size:9,weight:.bold,design:.monospaced)).tracking(1)}.padding(11).background(.black.opacity(0.45),in:Capsule()).padding(20)}
        }
    }
    func draw(context:inout GraphicsContext,size:CGSize) {
        // Elevated touchline camera. Simulation remains in metres; only projection changes.
        func point(_ p:FieldPoint)->CGPoint {
            let depth=p.y/68,scale=0.66+0.29*depth
            return CGPoint(x:size.width*(0.5+(p.x/105-0.5)*scale+0.06*(1-depth)),
                           y:size.height*(0.23+depth*0.66))
        }
        func ground(_ x:Double,_ y:Double,_ w:Double,_ h:Double)->Path {
            var path=Path();path.move(to:point(FieldPoint(x,y)))
            for p in [FieldPoint(x+w,y),FieldPoint(x+w,y+h),FieldPoint(x,y+h)] {path.addLine(to:point(p))}
            path.closeSubpath();return path
        }
        func circle(_ x:Double,_ y:Double,_ radius:Double)->Path {
            var path=Path()
            for i in 0...64 {let angle=Double(i)/64*2*Double.pi;let p=point(FieldPoint(x+cos(angle)*radius,y+sin(angle)*radius));if i==0 {path.move(to:p)} else {path.addLine(to:p)}}
            return path
        }
        context.fill(Path(CGRect(origin:.zero,size:size)),with:.linearGradient(Gradient(colors:[Color(white:0.12),Color(red:0.12,green:0.21,blue:0.13)]),startPoint:.zero,endPoint:CGPoint(x:0,y:size.height)))
        // Terraced crowd behind the far touchline. The colour noise retains the
        // dense look of the original match sprites, with antialiased geometry.
        for row in 0..<8 {for i in 0..<140 {
            let x=Double(i)*size.width/140,y=size.height*0.035+Double(row)*size.height*0.016
            let c:Color=(i*17+row*7)%9<4 ? Color(red:0.58,green:0.12,blue:0.10):Color(white:Double((i+row)%4)*0.12+0.32)
            context.fill(Path(ellipseIn:CGRect(x:x,y:y,width:3,height:4)),with:.color(c))
        }}
        // Original boards were a dedicated ADBOARDS.SPR sheet.  We retain the
        // original commercial inventory but redraw each mark at device scale so
        // it stays sharp at modern window sizes.
        for i in 0..<10 {
            let r=CGRect(x:Double(i)*size.width/10,y:size.height*0.17,width:size.width/10-2,height:size.height*0.045)
            let brand=boardBrands[i%boardBrands.count]
            let style=brandStyle(brand)
            context.fill(Path(roundedRect:r,cornerRadius:1.5),with:.color(style.background))
            context.stroke(Path(roundedRect:r,cornerRadius:1.5),with:.color(.white.opacity(0.32)),lineWidth:0.7)
            context.draw(Text(brand.uppercased()).font(.system(size:max(5.5,min(10,size.width/128)),weight:style.weight,design:style.design)).foregroundColor(style.foreground),at:CGPoint(x:r.midX,y:r.midY))
        }
        context.fill(ground(-5,-3,115,77),with:.color(Color(red:0.16,green:0.30,blue:0.12)))
        for i in 0..<15 {context.fill(ground(Double(i)*7,0,7,68),with:.color(Color(red:0.10,green:i%2==0 ? 0.38:0.34,blue:0.16)))}
        var lines=ground(0,0,105,68)
        lines.move(to:point(FieldPoint(52.5,0)));lines.addLine(to:point(FieldPoint(52.5,68)))
        lines.addPath(circle(52.5,34,9.15))
        for x in [0.0,88.5] {lines.addPath(ground(x,13.84,16.5,40.32))}
        for x in [0.0,99.5] {lines.addPath(ground(x,24.84,5.5,18.32))}
        context.stroke(lines,with:.color(.white.opacity(0.8)),lineWidth:1.3)
        for x in [11.0,94.0,52.5] {context.fill(circle(x,34,0.2),with:.color(.white))}
        for x in [0.0,105.0] {
            let back=x==0 ? -2.5:107.5
            let a=point(FieldPoint(x,30.34)),b=point(FieldPoint(x,37.66)),c=point(FieldPoint(back,37.66)),d=point(FieldPoint(back,30.34))
            let lift=size.height*0.052
            var net=Path();net.move(to:a);net.addLine(to:CGPoint(x:a.x,y:a.y-lift));net.addLine(to:CGPoint(x:b.x,y:b.y-lift));net.addLine(to:b);net.addLine(to:c);net.addLine(to:CGPoint(x:c.x,y:c.y-lift));net.addLine(to:CGPoint(x:d.x,y:d.y-lift));net.addLine(to:CGPoint(x:a.x,y:a.y-lift))
            context.stroke(net,with:.color(.white.opacity(0.9)),lineWidth:2)
            for t in stride(from:0.0,through:1.0,by:0.15) {var mesh=Path();let y=30.34+7.32*t;let f=point(FieldPoint(x,y)),r=point(FieldPoint(back,y));mesh.move(to:CGPoint(x:f.x,y:f.y-lift));mesh.addLine(to:CGPoint(x:r.x,y:r.y-lift));mesh.addLine(to:r);context.stroke(mesh,with:.color(.white.opacity(0.4)),lineWidth:0.6)}
        }
        if let f=match.flight {
            var path=Path();path.move(to:point(f.from));path.addLine(to:point(match.ball))
            context.stroke(path,with:.color(.white.opacity(0.28)),style:StrokeStyle(lineWidth:1,dash:[4,5]))
        }
        for p in match.activePlayers.sorted(by:{$0.point.y<$1.point.y}) {
            let foot=point(p.point),r=max(4.5,size.width/125)*(0.75+0.35*p.point.y/68)
            let at=CGPoint(x:foot.x,y:foot.y-r*1.1)
            let kit:Color=p.slot==0 ? Color(red:0.95,green:0.69,blue:0.16):(p.side==0 ? Color(red:0.85,green:0.15,blue:0.13):Color(red:0.24,green:0.53,blue:0.94))
            context.fill(Path(ellipseIn:CGRect(x:at.x-r,y:foot.y-r*0.2,width:r*2.4,height:r*1.2)),with:.color(.black.opacity(0.35)))
            let gait=sin(match.physicsTime*8+Double(p.number))*r*0.55
            for sign in [-1.0,1.0] {var leg=Path();leg.move(to:CGPoint(x:at.x+sign*r*0.38,y:at.y+r*0.4));leg.addLine(to:CGPoint(x:at.x+sign*r*0.50,y:at.y+r*1.1+sign*gait));context.stroke(leg,with:.color(p.side==0 ? .white:Color(white:0.15)),style:StrokeStyle(lineWidth:r*0.42,lineCap:.round))}
            let body=CGRect(x:at.x-r*0.85,y:at.y-r*0.7,width:r*1.7,height:r*1.6)
            context.fill(Path(roundedRect:body,cornerRadius:2),with:.color(kit))
            // Shirt details turn the old dot players into readable miniatures:
            // collar, sleeve trim, sponsor wordmark and a number panel.
            context.stroke(Path(roundedRect:body,cornerRadius:2),with:.color(.white.opacity(0.33)),lineWidth:max(0.45,r*0.09))
            context.stroke(Path(ellipseIn:CGRect(x:at.x-r*0.28,y:at.y-r*0.72,width:r*0.56,height:r*0.28)),with:.color(.white.opacity(0.8)),lineWidth:max(0.45,r*0.08))
            if p.slot != 0 {
                let sponsor=shirtSponsor.uppercased()
                context.draw(Text(sponsor).font(.system(size:max(2.6,min(5.2,r*0.46)),weight:.black,design:.rounded)).foregroundColor(.white.opacity(0.94)),at:CGPoint(x:at.x,y:at.y-r*0.02))
            }
            for sign in [-1.0,1.0] {var arm=Path();arm.move(to:CGPoint(x:at.x+sign*r*0.72,y:at.y-r*0.42));arm.addLine(to:CGPoint(x:at.x+sign*r*1.04,y:at.y+r*0.18));context.stroke(arm,with:.color(kit),style:StrokeStyle(lineWidth:r*0.34,lineCap:.round))}
            context.fill(Path(ellipseIn:CGRect(x:at.x-r*0.45,y:at.y-r*1.36,width:r*0.9,height:r*0.9)),with:.color(Color(red:0.78,green:0.58,blue:0.39)))
            context.fill(Path(ellipseIn:CGRect(x:at.x-r*0.47,y:at.y-r*1.43,width:r*0.94,height:r*0.39)),with:.color(p.number%3==0 ? Color(white:0.12):Color(red:0.18,green:0.09,blue:0.04)))
            context.draw(Text("\(p.number)").font(.system(size:max(6,r*0.85),weight:.heavy)).foregroundColor(.white),at:CGPoint(x:at.x,y:at.y+r*0.05))
            if match.owner==p.id {
                context.stroke(Path(ellipseIn:CGRect(x:at.x-r*1.5,y:at.y-r*1.5,width:r*3,height:r*3)),with:.color(mint.opacity(0.85)),lineWidth:1.2)
                let name=p.name.components(separatedBy:" ").last ?? p.name
                context.draw(Text(name).font(.system(size:10,weight:.bold)).foregroundColor(.white),at:CGPoint(x:at.x,y:at.y-r*2.3))
            }
        }
        let b=point(match.ball),br=max(2.7,size.width/235)
        let rise=match.flight.map{sin($0.progress * .pi)*($0.kind=="shot" ? 20:10)} ?? 0
        context.fill(Path(ellipseIn:CGRect(x:b.x-br+2,y:b.y-br+3,width:br*2,height:br*1.4)),with:.color(.black.opacity(0.45)))
        context.fill(Path(ellipseIn:CGRect(x:b.x-br,y:b.y-br-rise,width:br*2,height:br*2)),with:.color(.white))
        context.fill(Path(ellipseIn:CGRect(x:b.x-br/2,y:b.y-br/2-rise,width:br,height:br)),with:.color(Color(white:0.2)))
        if match.restartDelay>0 {context.draw(Text("GOAL!").font(.system(size:44,weight:.black,design:.rounded)).foregroundColor(.white),at:CGPoint(x:size.width/2,y:size.height/2))}
        if match.phase == .ready || match.phase == .halfTime || match.phase == .fullTime {
            context.draw(Text(match.phase == .ready ? "READY FOR KICK-OFF":(match.phase == .halfTime ? "HALF-TIME":"FULL-TIME")).font(.system(size:24,weight:.black,design:.rounded)).foregroundColor(.white),at:CGPoint(x:size.width/2,y:size.height/2-32))
        }
    }
    struct BoardStyle {let background:Color;let foreground:Color;let weight:Font.Weight;let design:Font.Design}
    func brandStyle(_ brand:String)->BoardStyle {
        switch brand.lowercased() {
        case "budweiser", "coca-cola": return .init(background:Color(red:0.72,green:0.04,blue:0.04),foreground:.white,weight:.black,design:.serif)
        case "canon", "pentax", "nikon", "brother": return .init(background:.white,foreground:.black,weight:.black,design:.default)
        case "caterpillar", "lotus": return .init(background:Color(red:0.93,green:0.72,blue:0.05),foreground:.black,weight:.black,design:.rounded)
        case "nationwide", "green flag": return .init(background:Color(red:0.03,green:0.23,blue:0.57),foreground:.white,weight:.bold,design:.rounded)
        case "puma", "kappa", "mitre": return .init(background:Color(white:0.08),foreground:.white,weight:.black,design:.rounded)
        case "lowenbräu", "greene king": return .init(background:Color(red:0.10,green:0.34,blue:0.17),foreground:Color(red:0.98,green:0.86,blue:0.25),weight:.black,design:.serif)
        default: return .init(background:Color(red:0.48,green:0.05,blue:0.08),foreground:.white,weight:.black,design:.rounded)
        }
    }
}
struct TouchlineControls:View {
    @EnvironmentObject var store:GameStore
    @ViewState var tactics=Tactics()
    @ViewState var outgoing=""
    @ViewState var incoming=""
    @ViewState var feedback=""
    var body:some View {
        VStack(alignment:.leading,spacing:22) {
            HStack {Text("Team talk").font(.system(size:30,weight:.bold,design:.serif));Spacer();Text("MATCH PAUSED").font(.system(size:10,weight:.bold)).foregroundStyle(mint)}
            if let m=store.career.activeMatch {
                HStack(alignment:.top,spacing:30) {
                    VStack(alignment:.leading,spacing:17) {
                        Text("INSTRUCTIONS").font(.system(size:10,weight:.bold)).tracking(2).foregroundStyle(muted)
                        GameChoice(label:"Formation",value:$tactics.formation,options:["4-4-2","4-3-3","3-5-2","5-3-2"])
                        GameChoice(label:"Mentality",value:$tactics.mentality,options:["Defensive","Balanced","Attacking"])
                        GameChoice(label:"Passing",value:$tactics.passing,options:["Short","Mixed","Direct"])
                        GameChoice(label:"Tackling",value:$tactics.tackling,options:["Cautious","Normal","Hard"])
                        Button("Apply instructions") {store.career.activeMatch?.changeTactics(tactics);store.career.tactics=tactics;store.save();store.audio.play("sq_chalk");feedback="Instructions changed. They take effect when play resumes."}
                    }.frame(width:290)
                    VStack(alignment:.leading,spacing:17) {
                        Text("SUBSTITUTIONS · \(m.substitutionsUsed) / 3 USED").font(.system(size:10,weight:.bold)).tracking(1).foregroundStyle(muted)
                        GameChoice(label:"Off",value:Binding(get:{m.managedPlayers.first{$0.id==outgoing}?.name ?? "Choose player"},set:{name in outgoing=m.managedPlayers.first{$0.name==name}?.id ?? ""}),options:["Choose player"]+m.managedPlayers.map(\.name))
                        GameChoice(label:"On",value:Binding(get:{m.bench.first{$0.id==incoming}?.name ?? "Choose substitute"},set:{name in incoming=m.bench.first{$0.name==name}?.id ?? ""}),options:["Choose substitute"]+m.bench.map(\.name))
                        Button("Make substitution") {
                            if store.career.activeMatch?.requestSubstitution(out:outgoing,in:incoming)==true {store.save();feedback="Change registered; it takes effect at the next stoppage.";outgoing="";incoming=""}
                            else {feedback="Choose an active player and an unused substitute. Three substitutions are permitted."}
                        }.disabled(outgoing.isEmpty || incoming.isEmpty || m.substitutionsUsed>=3)
                        Text("A substituted player cannot return. Your new player takes the outgoing player’s position.").font(.system(size:11)).foregroundStyle(muted)
                    }.frame(width:340)
                }
                Divider()
                Text(feedback.isEmpty ? "Change your plan while the clock is stopped.":feedback).font(.system(size:12)).foregroundStyle(mint)
                HStack {Button("Stay paused") {store.matchControls=false};Spacer();Button(m.phase == .halfTime ? "START SECOND HALF  →":"RETURN TO MATCH  →") {store.matchControls=false;if !store.matchRunning {store.toggleMatch()}}.buttonStyle(AccentButton())}
            }
        }.padding(26).frame(width:650).background(ink).onAppear {if let m=store.career.activeMatch {tactics=m.managedTactics}}
    }
}
struct MatchReportView:View {
    @EnvironmentObject var store:GameStore
    var body:some View {
        ClassicScreen(title:"Full-time Report") {
            if let m=store.career.lastMatch {
                Text("\(store.career.name(m.home))  \(m.homeGoals) – \(m.awayGoals)  \(store.career.name(m.away))").font(.system(size:25,weight:.bold)).frame(maxWidth:.infinity)
                if let home=m.homePenalties,let away=m.awayPenalties {Text("Penalties  \(home) – \(away)").foregroundStyle(mint).frame(maxWidth:.infinity)}
                HStack {Text("Attendance  \(m.attendance.formatted())");Spacer();Text("Shots  \(m.homeShots) / \(m.awayShots)");Spacer();Text("Possession  \(m.possession)% / \(100-m.possession)%")}.foregroundStyle(mint).padding(8).background(.black.opacity(0.25))
                ScrollView {LazyVStack(alignment:.leading,spacing:6) {ForEach(m.events) {e in HStack(alignment:.top) {Text("\(e.minute)′").monospacedDigit().frame(width:40,alignment:.trailing);Text(e.text).frame(maxWidth:.infinity,alignment:.leading)}.padding(6).background(.black.opacity(0.18))}}}
                HStack {Button("League table & results") {store.page="Competitions"};Button("Team selection") {store.page="Squad"};Spacer()}
            } else {Text("Your first match is ahead of you. Use Matchday or enter the tunnel from the dressing room.").foregroundStyle(muted);Spacer()}
        }
    }
}

struct MatchSpeedControl:View {
    @EnvironmentObject var store:GameStore
    var body:some View {GameChoice(label:"Speed",value:Binding(get:{String(format:"%g×",store.matchSpeed)},set:{value in store.matchSpeed=Double(value.replacingOccurrences(of:"×",with:"")) ?? 1}),options:["1×","1.5×","2×","4×","8×","16×"])}
}
