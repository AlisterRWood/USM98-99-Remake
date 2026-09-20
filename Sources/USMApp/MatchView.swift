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
                hotspot("Instant result",x:0.74,y:0.13,w:0.18,h:0.77,width:width,height:height) {store.beginMatch(watch:false)}
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
    @ViewState var replayPlaying=false
    @ViewState var optionsOpen=false
    @EnvironmentObject var store:GameStore
    var body:some View {
        if let m=store.career.activeMatch {
            let shown=replay ? replayMatch(m):m
            VStack(spacing:0) {
                LivePitch(match:shown,boardBrands:matchdayBoards,shirtSponsor:matchdayShirtSponsor)
                    .overlay(alignment:.top) {
                        if replay {
                            Text("REPLAY · \(replayClock(m))").font(.system(size:12,weight:.black,design:.rounded)).padding(8).background(royal,in:Capsule()).padding(16)
                        } else if let restart=m.setPieceRestart {
                            let title=restart.kind == "offside" ? "OFFSIDE · FREE KICK":restart.kind.uppercased()
                            Text(title+" · "+(m.players.first{$0.id==restart.taker}?.name ?? "Preparing restart")).font(.system(size:12,weight:.bold)).padding(8).background(crimson,in:Capsule()).padding(16)
                        }
                    }
                scoreboard(shown)
                matchInfoRibbon(shown)
                controls(m)
            }.background(ink).ignoresSafeArea(edges:.top)
            .overlay { matchOverlay(m) }
            .sheet(isPresented:$store.matchControls) {TouchlineControls().classicSheet("Team Talk & Substitutions").environmentObject(store)}
            .onReceive(Timer.publish(every:0.2,on:.main,in:.common).autoconnect()) {_ in advanceReplay(m)}
            .onDisappear {replayPlaying=false}
        } else {VStack {Text("No match in progress.");Button("Return to club") {store.screen="club"}}}
    }
    @ViewBuilder func matchOverlay(_ m:LiveMatch) -> some View {
        if !replay,let card=store.matchCard {
            ZStack {
                Color.black.opacity(0.3).ignoresSafeArea()
                ClassicDialog(title:card.kind=="red" ? "Red Card":"Yellow Card") {
                    let red=card.kind=="red"
                    ZStack {
                        RoundedRectangle(cornerRadius:6).fill(red ? Color(red:0.88,green:0.03,blue:0.02):Color(red:1,green:0.78,blue:0.02))
                        RoundedRectangle(cornerRadius:6).stroke(.black.opacity(0.75),lineWidth:3)
                        Text(red ? "RED":"YELLOW").font(.system(size:13,weight:.black,design:.rounded)).foregroundStyle(red ? .white:.black).rotationEffect(.degrees(-90))
                    }.frame(width:78,height:112).shadow(color:.black.opacity(0.35),radius:3,y:2)
                    Text(red ? "RED CARD":"YELLOW CARD").font(.system(size:28,weight:.black)).foregroundStyle(red ? Color.red:Color(red:0.72,green:0.52,blue:0))
                    Text(card.text).multilineTextAlignment(.center)
                    Text(red ? "Sent off. Suspended for the next 3 matches.":"Booking recorded.").font(.system(size:13,weight:.bold)).foregroundStyle(red ? Color.red:Color(red:0.62,green:0.45,blue:0))
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
        let frame=frames[min(frames.count-1,max(0,Int(replayIndex)))];var copy=match;copy.ball=frame.ball;copy.elapsed=frame.time;copy.homeGoals=frame.home;copy.awayGoals=frame.away;copy.flight=nil;copy.owner=nil;copy.restartDelay=0;copy.setPieceRestart=nil;copy.phase=frame.time < 2700 ? .firstHalf:.secondHalf
        for i in copy.players.indices {copy.players[i].onPitch=frame.points[copy.players[i].id] != nil;if let point=frame.points[copy.players[i].id]{copy.players[i].point=point}}
        return copy
    }
    func replayClock(_ match:LiveMatch)->String {
        guard let frames=match.replayFrames,!frames.isEmpty else {return "00′"}
        let time=frames[min(frames.count-1,max(0,Int(replayIndex)))].time
        return String(format:"%02d′",Int(time/60))
    }
    func advanceReplay(_ match:LiveMatch) {
        guard replay,replayPlaying,let frames=match.replayFrames,!frames.isEmpty else {return}
        if replayIndex >= Double(frames.count-1) {replayPlaying=false}
        else {replayIndex=min(Double(frames.count-1),replayIndex+1)}
    }
    // Boards only display contracts the player has actually sold. This preserves
    // the original game's commercial loop while making every accepted offer
    // visible on match day.
    var matchdayBoards:[String] {
        let sold=store.career.managementState.deals.filter{$0.accepted && $0.remaining>0 && $0.kind=="Pitch boards"}.map(\.brand)
        return sold.isEmpty ? [""]:sold
    }
    var matchdayShirtSponsor:String {
        let deal=store.career.managementState.deals.first{$0.accepted && $0.kind=="Club sponsor"}
        return deal?.brand ?? ""
    }
    func scoreboard(_ m:LiveMatch)->some View {
        HStack(spacing:0) {
            Text("›  \(store.career.name(m.home))").frame(maxWidth:.infinity,alignment:.leading).padding(.leading,18)
            scoreBox(m.homeGoals)
            scoreBox(m.awayGoals)
            Text("‹  \(store.career.name(m.away))").frame(maxWidth:.infinity,alignment:.leading).padding(.leading,12)
        }.font(.system(size:27,weight:.black,design:.rounded)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.5)
            .frame(height:42).classicRibbon()
    }
    func scoreBox(_ score:Int)->some View {
        Text("\(score)").font(.system(size:32,weight:.black,design:.rounded)).monospacedDigit()
            .frame(width:65,height:40).overlay(Rectangle().stroke(royal,lineWidth:2))
    }
    func matchInfoRibbon(_ m:LiveMatch)->some View {
        HStack(spacing:0) {
            Text("At \(fixtureStadium(m))").frame(maxWidth:.infinity,alignment:.leading).padding(.leading,20)
            Text("Time: \(Int(m.elapsed/60))").frame(width:130).overlay(Capsule().stroke(.gray,lineWidth:2))
            Text(fixtureCompetition(m)).frame(maxWidth:.infinity,alignment:.leading).padding(.leading,20)
        }.font(.system(size:15,weight:.bold)).lineLimit(1).minimumScaleFactor(0.7).foregroundStyle(.black)
            .frame(height:27).background(Color(white:0.82)).overlay(Capsule().stroke(.gray,lineWidth:2))
    }
    func fixtureStadium(_ m:LiveMatch)->String {store.career.clubs.first{$0.id==m.home}?.stadium ?? "Home Ground"}
    func fixtureCompetition(_ m:LiveMatch)->String {store.career.fixtures.first{$0.id==m.fixtureID}?.competition ?? "League Match"}
    func controls(_ m:LiveMatch)->some View {
        GeometryReader {geo in
            HStack(spacing:0) {
                VStack(spacing:0) {
                    if replay {
                        HStack(spacing:8) {
                            Text(replayClock(m)).font(.system(size:12,weight:.black,design:.monospaced)).foregroundStyle(.black).frame(width:42)
                            Slider(value:$replayIndex,in:0...Double(max(1,(m.replayFrames?.count ?? 1)-1)),step:1) {_ in replayPlaying=false}
                            Text("\(m.replayFrames?.count ?? 0) snapshots").font(.system(size:11,weight:.bold)).foregroundStyle(.black).frame(width:86,alignment:.trailing)
                        }.padding(.horizontal,12)
                    } else {Spacer(minLength:0)}
                    HStack(spacing:6) {
                        consoleButton(replay ? (replayPlaying ? "Pause":"Play"):(m.isFinished ? "Continue":(store.matchRunning ? "Pause":"Resume"))) {
                            if replay {replayPlaying.toggle()}
                            else if m.isFinished {store.finishMatch()} else {store.toggleMatch()}
                        }.keyboardShortcut(.space,modifiers:[]).disabled(replay ? (m.replayFrames?.count ?? 0)<2:m.phase == .ready)
                        consoleButton(replay ? "Live":"Replay") {
                            store.matchRunning=false;replayPlaying=false
                            if replay {replay=false;replayIndex=Double(max(0,(m.replayFrames?.count ?? 1)-1))}
                            else {replay=true;replayIndex=0}
                        }.disabled((m.replayFrames?.count ?? 0)<2)
                        if replay {
                            consoleButton("◀") {replayPlaying=false;replayIndex=max(0,replayIndex-1)}.disabled(replayIndex <= 0)
                            consoleButton("▶") {replayPlaying=false;replayIndex=min(Double(max(0,(m.replayFrames?.count ?? 1)-1)),replayIndex+1)}.disabled(replayIndex >= Double(max(0,(m.replayFrames?.count ?? 1)-1)))
                        }
                        consoleButton("Options") {optionsOpen=true}.popover(isPresented:$optionsOpen) {
                            ClassicDialog(title:"Match Options") {
                                Button("Tactics / Team Talk") {optionsOpen=false;openTouchline()}
                                Button("Instant remainder") {optionsOpen=false;replay=false;store.instantRemainder()}.disabled(m.isFinished)
                                Button(store.soundEnabled ? "Sound off":"Sound on") {store.toggleSound()}
                                Button("Return") {optionsOpen=false}
                            }.frame(width:310)
                        }
                        HStack(spacing:2) {
                            consoleButton("◀") {changeSpeed(-1)}
                            Text(store.matchSpeed==1 ? "Norm":String(format:"X%g",store.matchSpeed))
                                .font(.system(size:14,weight:.bold)).foregroundStyle(.yellow).frame(width:44,height:29)
                                .background(Color(white:0.25)).overlay(Rectangle().stroke(crimson,lineWidth:2))
                            consoleButton("▶") {changeSpeed(1)}
                        }.frame(width:132).disabled(m.isFinished)
                        consoleButton("Subs") {openTouchline()}.disabled(m.isFinished)
                    }.padding(5).overlay(Capsule().stroke(Color(white:0.95),lineWidth:2))
                }.frame(width:geo.size.width*0.56)
                Rectangle().fill(.gray).frame(width:2)
                if m.phase == .ready {
                    HStack(spacing:10) {
                        VStack(spacing:3) {
                            consoleButton("Kick Off") {store.toggleMatch()}
                            consoleButton("Instant") {store.instantRemainder()}
                            consoleButton("Cancel") {store.cancelMatchday()}
                        }.frame(maxWidth:.infinity)
                        VStack(spacing:4) {
                            Text("Individual Instructions").font(.system(size:13,weight:.bold)).foregroundStyle(.black)
                            consoleButton("Team Talk") {openTouchline()}
                            consoleButton("Match Instructions") {openTouchline()}
                        }.frame(maxWidth:.infinity)
                    }.padding(6)
                } else {commentaryBar(m).padding(.horizontal,12).frame(maxWidth:.infinity,alignment:.leading)}
            }
        }.frame(height:92).background(LinearGradient(colors:[Color(white:0.87),Color(white:0.62),Color(white:0.78)],startPoint:.topLeading,endPoint:.bottomTrailing))
            .overlay(Rectangle().stroke(Color(white:0.45),lineWidth:1))
    }
    func openTouchline() {store.matchRunning=false;store.matchControls=true;store.save()}
    func changeSpeed(_ delta:Int) {
        let speeds=[1.0,1.5,2,4,8,16]
        let index=speeds.firstIndex(of:store.matchSpeed) ?? 0
        store.matchSpeed=speeds[min(speeds.count-1,max(0,index+delta))]
    }
    func consoleButton(_ title:String,action:@escaping()->Void)->some View {
        Button(action:action) {Text(title).lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth:.infinity)}.buttonStyle(MatchConsoleButton())
    }
    func commentaryBar(_ m:LiveMatch)->some View {
        VStack(alignment:.leading,spacing:3) {
            ForEach(Array(m.events.suffix(4))) {event in
                HStack(alignment:.firstTextBaseline,spacing:7) {
                    Text("\(event.minute)").foregroundStyle(.black).monospacedDigit().frame(width:22,alignment:.trailing)
                    Text(event.text).foregroundStyle(event.side==0 ? Color(red:0.8,green:0.04,blue:0.01):event.side==1 ? royal:.black)
                        .lineLimit(1).truncationMode(.tail)
                }.font(.system(size:14,weight:.bold))
            }
        }.frame(maxWidth:.infinity,alignment:.leading)
    }
}
struct MatchConsoleButton:ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration:Configuration)->some View {configuration.label.font(.system(size:14,weight:.black,design:.rounded)).foregroundStyle(.yellow).padding(.horizontal,7).frame(height:26).classicRibbon().opacity(enabled ? (configuration.isPressed ? 0.65:1):0.4)}
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
            Canvas {context,size in draw(context:&context,size:size)}
                .frame(width:geo.size.width,height:geo.size.height).clipped()
        }
    }
    func draw(context:inout GraphicsContext,size:CGSize) {
        func point(_ p:FieldPoint)->CGPoint {
            let cameraX=min(67,max(38,match.ball.x))
            let depth=max(0,min(1,p.y/68))
            let scale=size.width/86*(0.78+0.22*depth)
            return CGPoint(x:size.width*0.5+(p.x-cameraX)*scale,
                           y:size.height*0.23+p.y*(size.height*0.58/68))
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
        // Terraced crowd behind the far touchline. Each supporter is a tiny
        // pixel-era figure rather than a single anonymous dot.
        for row in 0..<8 {for i in 0..<140 {
            let x=Double(i)*size.width/140,y=size.height*0.035+Double(row)*size.height*0.016
            let shirt:[Color]=[Color(red:0.58,green:0.12,blue:0.10),Color(red:0.12,green:0.26,blue:0.52),Color(white:0.72),Color(red:0.76,green:0.58,blue:0.12)]
            let c=shirt[(i*17+row*7)%shirt.count],pixel=max(1.2,size.width/1100)
            context.fill(Path(CGRect(x:x,y:y+pixel*1.5,width:pixel*2.2,height:pixel*3)),with:.color(c))
            context.fill(Path(CGRect(x:x+pixel*0.35,y:y,width:pixel*1.5,height:pixel*1.5)),with:.color(Color(red:0.68,green:0.46,blue:0.30)))
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
            if !brand.isEmpty {context.draw(Text(brand.uppercased()).font(.system(size:max(5.5,min(10,size.width/128)),weight:style.weight,design:style.design)).foregroundColor(style.foreground),at:CGPoint(x:r.midX,y:r.midY))}
        }
        context.fill(Path(CGRect(x:0,y:size.height*0.22,width:size.width,height:size.height*0.78)),with:.color(Color(red:0.10,green:0.34,blue:0.16)))
        context.fill(ground(-40,-3,185,180),with:.color(Color(red:0.10,green:0.34,blue:0.16)))
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
            let kit:Color=p.slot==0 ? Color(red:0.95,green:0.69,blue:0.16):(p.side==0 ? Color(red:0.85,green:0.15,blue:0.13):Color(red:0.24,green:0.53,blue:0.94))
            let pose=pixelPose(for:p,match:match)
            let forward=match.direction(p.side)>0
            if !drawSpritePlayer(context:&context,center:foot,scale:r,player:p,pose:pose,forward:forward,time:match.physicsTime) {
                drawPixelPlayer(context:&context,center:foot,scale:r,player:p,kit:kit,pose:pose,forward:forward,shirtSponsor:shirtSponsor,time:match.physicsTime)
            }
            if match.owner==p.id {
                context.stroke(Path(ellipseIn:CGRect(x:foot.x-r*1.5,y:foot.y-r*1.5,width:r*3,height:r*3)),with:.color(mint.opacity(0.85)),lineWidth:1.2)
                let name=p.name.components(separatedBy:" ").last ?? p.name
                context.draw(Text(name).font(.system(size:10,weight:.bold)).foregroundColor(.white),at:CGPoint(x:foot.x,y:foot.y-r*2.3))
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
    enum PixelPose { case standing, running, passing, shooting, tackling }
    func pixelPose(for player:MatchPlayer,match:LiveMatch)->PixelPose {
        if match.flight?.kicker == player.id { return match.flight?.kind == "shot" ? .shooting:.passing }
        if match.events.last(where:{$0.playerID == player.id && match.clockMinute-$0.minute <= 1})?.kind == "tackle" { return .tackling }
        if match.phase == .ready || match.phase == .halfTime || match.phase == .fullTime { return .standing }
        return .running
    }
    func drawSpritePlayer(context:inout GraphicsContext,center:CGPoint,scale:Double,player:MatchPlayer,pose:PixelPose,forward:Bool,time:Double)->Bool {
        let atlasName=player.slot==0 ? "MatchPlayerSpritesGold":(player.side==0 ? "MatchPlayerSpritesRed":"MatchPlayerSpritesBlue")
        guard let url=Bundle.module.url(forResource:atlasName,withExtension:"png",subdirectory:"Resources"),let source=NSImage(contentsOf:url),let cg=source.cgImage(forProposedRect:nil,context:nil,hints:nil) else {return false}
        let frame=max(0,Int(time*8+Double(player.number))%8),row:Int
        if pose == .running && frame % 4 == 0 { return false }
        switch pose {case .standing:row=forward ? 0:1;case .running:row=forward ? 2:3;case .passing,.shooting:row=4;case .tackling:row=5}
        let cell=181
        guard let crop=cg.cropping(to:CGRect(x:frame*cell,y:cg.height-(row+1)*cell,width:cell,height:cell)) else {return false}
        let image=Image(decorative:crop,scale:1)
        let height=max(38,scale*6.7),width=height
        context.draw(image,in:CGRect(x:center.x-width/2,y:center.y-height*0.94,width:width,height:height))
        return true
    }
    func drawPixelPlayer(context:inout GraphicsContext,center:CGPoint,scale:Double,player:MatchPlayer,kit:Color,pose:PixelPose,forward:Bool,shirtSponsor:String,time:Double) {
        let px=max(1,(scale/3.1).rounded()),x=center.x,y=center.y
        let dark=Color(red:0.04,green:0.035,blue:0.03),skin=Color(red:0.78,green:0.58,blue:0.39),socks=player.side==0 ? Color(white:0.94):Color(white:0.14)
        func block(_ bx:Double,_ by:Double,_ w:Double,_ h:Double,_ color:Color) {let rect=CGRect(x:(bx*px+x).rounded(),y:(by*px+y).rounded(),width:max(1,(w*px).rounded()),height:max(1,(h*px).rounded()));context.fill(Path(rect),with:.color(color))}
        let phase=Int(time*8+Double(player.number))
        block(-3,0,6,1,dark)
        switch pose {
        case .tackling:
            block(-4,-5,6,3,dark);block(-3,-4,5,2,kit);block(2,-2,5,1,skin);block(-4,-1,3,1,socks);block(1,-1,4,1,dark);block(3,0,3,1,dark)
        default:
            if pose == .running {
                drawSideRunner(context:&context,center:center,px:px,player:player,kit:kit,skin:skin,socks:socks,forward:forward,frame:phase%4,shirtSponsor:shirtSponsor,scale:scale)
                return
            }
            block(-1.5,-12,3,3,dark);block(-1,-11,2,2,skin);block(-2,-13,4,1,player.number%3==0 ? Color(white:0.12):Color(red:0.18,green:0.09,blue:0.04))
            block(-3,-9,6,6,dark);block(-2,-8,4,5,kit);block(-1,-8,2,1,Color.white.opacity(0.75))
            let stride=0.0
            block(-3,-4,6,2,dark);block(-2,-4,4,1,player.side==0 ? Color(white:0.92):Color(white:0.12))
            block(-2+stride,-2,1.5,2,socks);block(0.5-stride,-2,1.5,2,socks);block(-2+stride,-0.5,2,1,dark);block(0.5-stride,-0.5,2,1,dark)
            let arm=pose == .passing || pose == .shooting ? 2.5:1.5
            block(-4,-8,1,arm,kit);block(3,-8,1,arm,kit);block(-4,-8+arm,1,1,skin);block(3,-8+arm,1,1,skin)
            let face=forward ? 1.0:-1.0;block(face*0.8,-10,0.7,0.7,skin)
            if player.slot != 0 && !shirtSponsor.isEmpty && scale > 6 {context.draw(Text(shirtSponsor.uppercased()).font(.system(size:max(2.6,min(5.2,scale*0.42)),weight:.black,design:.rounded)).foregroundColor(.white.opacity(0.9)),at:CGPoint(x:x,y:y-6*px))}
        }
    }
    func drawSideRunner(context:inout GraphicsContext,center:CGPoint,px:Double,player:MatchPlayer,kit:Color,skin:Color,socks:Color,forward:Bool,frame:Int,shirtSponsor:String,scale:Double) {
        let x=center.x,y=center.y,dark=Color(red:0.04,green:0.035,blue:0.03),s=forward ? 1.0:-1.0
        func block(_ bx:Double,_ by:Double,_ w:Double,_ h:Double,_ color:Color) {let mx=forward ? bx : -bx-w;let rect=CGRect(x:(mx*px+x).rounded(),y:(by*px+y).rounded(),width:max(1,(w*px).rounded()),height:max(1,(h*px).rounded()));context.fill(Path(rect),with:.color(color))}
        let legSwing:[(Double,Double)]=[(2.8,-1.4),(-1.0,2.8),(-2.8,1.4),(1.0,-2.8)]
        let armSwing:[(Double,Double)]=[(2.2,-1.2),(0.8,-2.0),(-2.2,1.2),(-0.8,2.0)]
        let legs=legSwing[frame],arms=armSwing[frame]
        block(-0.8,-12,2.7,1,dark);block(-0.2,-11,2.2,2,skin);block(1.5,-10.4,1.3,1,skin);block(1.8,-10.1,0.9,0.7,dark);block(-1,-13,3.6,1,player.number%3==0 ? Color(white:0.12):Color(red:0.18,green:0.09,blue:0.04))
        block(-1.8,-9,4.7,6,dark);block(-1.1,-8,3.8,5,kit);block(-0.2,-8,2.4,1,Color.white.opacity(0.78));block(-2.2,-8,1.3,2.4,kit);block(-2.6+arms.0,-7.6,1.1,2.5,kit);block(-2.8+arms.0,-5.5,1,1,skin);block(1.9+arms.1,-7.1,1,2.2,kit);block(2.5+arms.1,-5.3,1,1,skin)
        block(-1.5,-4,3.8,2,dark);block(-0.9,-4,2.8,1,socks)
        block(-1.3+legs.0,-2,1.5,2,socks);block(0.4+legs.1,-2,1.5,2,socks);block(-1.8+legs.0,-0.5,2.8,1,dark);block(0.1+legs.1,-0.5,2.8,1,dark)
        if player.slot != 0 && !shirtSponsor.isEmpty && scale > 6 {context.draw(Text(shirtSponsor.uppercased()).font(.system(size:max(2.6,min(5.2,scale*0.42)),weight:.black,design:.rounded)).foregroundColor(.white.opacity(0.9)),at:CGPoint(x:x-s*0.1*px,y:y-6*px))}
    }
    struct BoardStyle {let background:Color;let foreground:Color;let weight:Font.Weight;let design:Font.Design}
    func brandStyle(_ brand:String)->BoardStyle {
        switch brand.lowercased() {
        case "": return .init(background:Color(red:0.20,green:0.22,blue:0.20),foreground:.clear,weight:.regular,design:.default)
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
    @ViewState var carried:String?
    @ViewState var highlighted:String?
    @ViewState var feedback="Right-click a starting player, then left-click a substitute to make the change."
    var body:some View {
        VStack(alignment:.leading,spacing:12) {
            HStack {Text("Team Talk & Substitutions").font(.system(size:30,weight:.bold,design:.serif));Spacer();Text("MATCH PAUSED").font(.system(size:10,weight:.bold)).foregroundStyle(mint)}
            if let m=store.career.activeMatch {MatchdayTacticsView(match:m,tactics:$tactics,carried:$carried,highlighted:$highlighted,feedback:$feedback)}
            HStack {Button("Stay paused") {store.matchControls=false};Spacer();Button(store.career.activeMatch?.phase == .halfTime ? "START SECOND HALF  →":"RETURN TO MATCH  →") {store.matchControls=false;if !store.matchRunning {store.toggleMatch()}}.buttonStyle(AccentButton())}
        }.padding(22).frame(width:1050,height:720).background(ink).onAppear {if let m=store.career.activeMatch {tactics=m.managedTactics}}
    }
}
struct MatchdayTacticsView:View {
    @EnvironmentObject var store:GameStore
    var match:LiveMatch
    @Binding var tactics:Tactics
    @Binding var carried:String?
    @Binding var highlighted:String?
    @Binding var feedback:String
    var roster:[MatchPlayer] {match.managedPlayers + Array(match.bench.prefix(5))}
    var body:some View {
        HStack(alignment:.top,spacing:18) {
            VStack(alignment:.leading,spacing:10) {
                Text("TEAM TALK").font(.system(size:11,weight:.bold)).tracking(2).foregroundStyle(muted)
                HStack(alignment:.top,spacing:14) {
                    TacticalPitch(lineup:match.managedPlayers.compactMap { player in store.career.players.first { $0.id == player.id } },formation:tactics.formation).frame(width:250,height:310)
                    VStack(alignment:.leading,spacing:8) {
                        GameChoice(label:"Formation",value:$tactics.formation,options:["4-4-2","4-3-3","3-5-2","5-3-2"])
                        GameChoice(label:"Mentality",value:$tactics.mentality,options:["Defensive","Balanced","Attacking"])
                        GameChoice(label:"Passing",value:$tactics.passing,options:["Short","Mixed","Direct"])
                        GameChoice(label:"Tackling",value:$tactics.tackling,options:["Cautious","Normal","Hard"])
                        Button((tactics.offsideTrap ?? false) ? "Offside trap: ON":"Offside trap: OFF") {tactics.offsideTrap = !(tactics.offsideTrap ?? false)}
                        Button("Apply team talk") {store.career.activeMatch?.changeTactics(tactics);store.career.tactics=tactics;store.save();store.audio.play("sq_chalk");feedback="Team talk and instructions applied."}
                        Text("The full team-talk controls remain available while the match is paused.").font(.system(size:11)).foregroundStyle(muted).fixedSize(horizontal:false,vertical:true)
                    }.frame(width:220)
                }
            }.frame(width:505,alignment:.leading)
            VStack(alignment:.leading,spacing:8) {
                HStack {Text("MATCH SQUAD").font(.system(size:11,weight:.bold)).tracking(2).foregroundStyle(muted);Spacer();Text("\(match.substitutionsUsed) / 3 USED").font(.system(size:11,weight:.bold)).foregroundStyle(mint)}
                MatchdaySquadTable(players:roster,carried:$carried,highlighted:$highlighted,onSwap:swap).frame(minWidth:475,maxWidth:.infinity,maxHeight:355)
                Text("Starting XI + five permitted substitutes. Right-click a player to pick them up, then left-click the substitute coming on. A used substitute cannot return.").font(.system(size:11)).foregroundStyle(muted).fixedSize(horizontal:false,vertical:true)
                Text(feedback).font(.system(size:12,weight:.semibold)).foregroundStyle(mint).fixedSize(horizontal:false,vertical:true)
            }.frame(maxWidth:.infinity,alignment:.leading)
        }
    }
    func swap(_ outgoing:String,_ incoming:String) {
        guard let m=store.career.activeMatch else{return}
        guard m.managedPlayers.contains(where:{$0.id==outgoing}),m.bench.prefix(5).contains(where:{$0.id==incoming}) else {feedback="Pick a starting player and one of the five unused substitutes.";return}
        if store.career.activeMatch?.requestSubstitution(out:outgoing,in:incoming)==true {store.save();feedback="Substitution registered. \(m.players.first{$0.id==incoming}?.name ?? "The substitute") comes on for \(m.players.first{$0.id==outgoing}?.name ?? "the outgoing player")."}
        else {feedback="That substitution is not available. Check the three-substitution limit and player status."}
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
