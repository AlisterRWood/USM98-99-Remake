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
        } else if !replay,let event=store.matchGoal {
            let scorer = event.playerID.flatMap { id in m.players.first(where: {$0.id==id})?.name } ?? "A superb finish"
            MatchEventPopup(title:"GOAL!",subtitle:scorer,detail:"\(event.minute)′  \(store.career.name(m.home))  \(event.homeScore) – \(event.awayScore)  \(store.career.name(m.away))",icon:"soccerball")
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
        let frame=frames[min(frames.count-1,max(0,Int(replayIndex)))];var copy=match;copy.ball=frame.ball;copy.elapsed=frame.time;copy.physicsTime=frame.time/8;copy.homeGoals=frame.home;copy.awayGoals=frame.away;copy.flight=nil;copy.owner=nil;copy.restartDelay=0;copy.setPieceRestart=nil;copy.pendingRestart=nil;copy.deadBallDelay=nil;copy.goalkeeperResetDelay=nil;copy.phase=frame.time < 2700 ? .firstHalf:.secondHalf
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
    enum PlayerFacing: Equatable {
        case front, back, left, right
    }
    struct PlayerMotion: Equatable {
        var facing: PlayerFacing = .front
        var isMoving = false
        var stride = 0
        var gaitDistance = 0.0
    }
    struct MotionTracker: Equatable {
        private(set) var positions: [String: FieldPoint] = [:]
        private(set) var motions: [String: PlayerMotion] = [:]
        mutating func reset(with players: [MatchPlayer]) {
            positions = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0.point) })
            motions = Dictionary(uniqueKeysWithValues: players.map { ($0.id, PlayerMotion()) })
        }
        mutating func capture(_ players: [MatchPlayer]) {
            let visible = Set(players.map(\.id))
            positions = positions.filter { visible.contains($0.key) }
            motions = motions.filter { visible.contains($0.key) }
            for player in players {
                var motion = motions[player.id] ?? PlayerMotion()
                if let previous = positions[player.id] {
                    let dx = player.point.x - previous.x
                    let dy = player.point.y - previous.y
                    let distance = hypot(dx, dy)
                    motion.isMoving = distance > 0.018 && distance < 8
                    if motion.isMoving {
                        if abs(dx) > abs(dy) { motion.facing = dx < 0 ? .left : .right }
                        else { motion.facing = dy < 0 ? .back : .front }
                        motion.gaitDistance += distance
                        motion.stride = Int(motion.gaitDistance / 0.7) % 4
                    }
                }
                motions[player.id] = motion
                positions[player.id] = player.point
            }
        }
        func motion(for player: MatchPlayer) -> PlayerMotion { motions[player.id] ?? PlayerMotion() }
    }
    var match:LiveMatch
    var boardBrands:[String]
    var shirtSponsor:String
    var injectedMotion: [String: PlayerMotion] = [:]
    @ViewState private var motionTracker = MotionTracker()
    var body:some View {
        GeometryReader { geo in
            Canvas {context,size in draw(context:&context,size:size)}
                .frame(width:geo.size.width,height:geo.size.height).clipped()
        }.onAppear { motionTracker.reset(with: match.activePlayers) }
            .onChange(of: match.fixtureID) { motionTracker.reset(with: match.activePlayers) }
            .onChange(of: match.physicsTime) { motionTracker.capture(match.activePlayers) }
    }
    func draw(context:inout GraphicsContext,size:CGSize) {
        func point(_ p:FieldPoint)->CGPoint {
            let cameraX=min(77,max(28,match.ball.x))
            let depth=max(0,min(1,p.y/68))
            let scale=size.width/72*(0.78+0.22*depth)
            return CGPoint(x:size.width*0.5+(p.x-cameraX)*scale,
                           y:size.height*0.27+p.y*(size.height*0.57/68))
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
        context.fill(Path(CGRect(x:0,y:size.height*0.22,width:size.width,height:size.height*0.78)),with:.color(Color(red:0.10,green:0.34,blue:0.16)))
        drawCrowd(context:&context,size:size,time:match.physicsTime)
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
        for i in 0..<15 {context.fill(ground(Double(i)*7,0,7,68),with:.color(Color(red:0.10,green:i%2==0 ? 0.38:0.34,blue:0.16)))}
        var lines=ground(0,0,105,68)
        lines.move(to:point(FieldPoint(52.5,0)));lines.addLine(to:point(FieldPoint(52.5,68)))
        lines.addPath(circle(52.5,34,9.15))
        for x in [0.0,88.5] {lines.addPath(ground(x,13.84,16.5,40.32))}
        for x in [0.0,99.5] {lines.addPath(ground(x,24.84,5.5,18.32))}
        context.stroke(lines,with:.color(.white.opacity(0.8)),lineWidth:1.3)
        for x in [11.0,94.0,52.5] {context.fill(circle(x,34,0.2),with:.color(.white))}
        drawGoal(context:&context,at:0,point:point,size:size)
        drawGoal(context:&context,at:105,point:point,size:size)
        drawTechnicalArea(context:&context,point:point,time:match.physicsTime)
        if let f=match.flight {
            var path=Path();path.move(to:point(f.from));path.addLine(to:point(match.ball))
            context.stroke(path,with:.color(.white.opacity(0.28)),style:StrokeStyle(lineWidth:1,dash:[4,5]))
        }
        for p in match.activePlayers.sorted(by:{$0.point.y<$1.point.y}) {
            let foot=point(p.point),r=max(4.25,size.width/148)*(0.75+0.35*p.point.y/68)
            let kit:Color=p.slot==0 ? Color(red:0.95,green:0.69,blue:0.16):(p.side==0 ? Color(red:0.85,green:0.15,blue:0.13):Color(red:0.24,green:0.53,blue:0.94))
            let motion=injectedMotion[p.id] ?? motionTracker.motion(for:p)
            let pose=pixelPose(for:p,match:match,motion:motion)
            drawPixelPlayer(context:&context,center:foot,scale:r,player:p,kit:kit,pose:pose,motion:motion)
            if match.owner==p.id {
                context.stroke(Path(ellipseIn:CGRect(x:foot.x-r*1.5,y:foot.y-r*1.5,width:r*3,height:r*3)),with:.color(mint.opacity(0.85)),lineWidth:1.2)
                let name=p.name.components(separatedBy:" ").last ?? p.name
                context.draw(Text(name).font(.system(size:10,weight:.bold)).foregroundColor(.white),at:CGPoint(x:foot.x,y:foot.y-r*2.3))
            }
        }
        let b=point(match.ball),br=max(3.15,size.width/199)
        let rise=match.flight.map{sin($0.progress * .pi)*($0.kind=="shot" ? 20:10)} ?? 0
        context.fill(Path(ellipseIn:CGRect(x:b.x-br+2,y:b.y-br+3,width:br*2,height:br*1.4)),with:.color(.black.opacity(0.45)))
        context.fill(Path(ellipseIn:CGRect(x:b.x-br,y:b.y-br-rise,width:br*2,height:br*2)),with:.color(.white))
        context.fill(Path(ellipseIn:CGRect(x:b.x-br/2,y:b.y-br/2-rise,width:br,height:br)),with:.color(Color(white:0.2)))
        if match.phase == .ready || match.phase == .halfTime || match.phase == .fullTime {
            context.draw(Text(match.phase == .ready ? "READY FOR KICK-OFF":(match.phase == .halfTime ? "HALF-TIME":"FULL-TIME")).font(.system(size:24,weight:.black,design:.rounded)).foregroundColor(.white),at:CGPoint(x:size.width/2,y:size.height/2-32))
        }
    }
    func drawCrowd(context:inout GraphicsContext,size:CGSize,time:Double) {
        let terrace=CGRect(x:0,y:0,width:size.width,height:size.height*0.205)
        context.fill(Path(terrace),with:.linearGradient(Gradient(colors:[Color(red:0.055,green:0.07,blue:0.09),Color(red:0.12,green:0.15,blue:0.17)]),startPoint:.zero,endPoint:CGPoint(x:0,y:terrace.maxY)))
        for row in 0..<6 {
            let y=size.height*(0.024+Double(row)*0.026)
            context.fill(Path(CGRect(x:0,y:y+size.height*0.022,width:size.width,height:max(1,size.height*0.004))),with:.color(.black.opacity(0.32)))
            for seat in 0..<116 {
                let spacing=size.width/116
                let x=Double(seat)*spacing + Double((row*11+seat*5)%3)*0.45
                let pixel=max(1.9,size.width/1050) * (1+Double(row)*0.045)
                let shirts:[Color]=[Color(red:0.73,green:0.11,blue:0.10),Color(red:0.11,green:0.28,blue:0.62),Color(red:0.92,green:0.86,blue:0.61),Color(red:0.18,green:0.48,blue:0.25),Color(white:0.78)]
                let shirt=shirts[(seat*13+row*7)%shirts.count]
                let skin=Color(red:0.72,green:0.49,blue:0.31)
                let wave=(seat+row*3)%5 == 0 && Int(time*3+Double(seat))%2 == 0
                context.fill(Path(CGRect(x:x+pixel*0.55,y:y,width:pixel*1.5,height:pixel*1.55)),with:.color(skin))
                context.fill(Path(CGRect(x:x,y:y+pixel*1.5,width:pixel*2.6,height:pixel*3.2)),with:.color(shirt))
                context.fill(Path(CGRect(x:x+pixel*0.25,y:y+pixel*4.5,width:pixel*0.8,height:pixel*1.4)),with:.color(Color(white:0.12)))
                context.fill(Path(CGRect(x:x+pixel*1.55,y:y+pixel*4.5,width:pixel*0.8,height:pixel*1.4)),with:.color(Color(white:0.12)))
                let armY=wave ? y-pixel*0.8:y+pixel*2.1
                context.fill(Path(CGRect(x:x-pixel*0.65,y:armY,width:pixel,height:pixel*2.5)),with:.color(shirt))
                context.fill(Path(CGRect(x:x+pixel*2.3,y:wave ? y-pixel*1.45:y+pixel*2.1,width:pixel,height:pixel*2.5)),with:.color(shirt))
            }
        }
    }
    func drawGoal(context:inout GraphicsContext,at x:Double,point:@escaping (FieldPoint)->CGPoint,size:CGSize) {
        let back=x == 0 ? -3.4:108.4
        let nearTopLeft=point(FieldPoint(x,30.34)),nearBottomLeft=point(FieldPoint(x,37.66))
        let farTopLeft=point(FieldPoint(back,30.34)),farBottomLeft=point(FieldPoint(back,37.66))
        let lift=size.height*0.064
        let nTL=CGPoint(x:nearTopLeft.x,y:nearTopLeft.y-lift),nBL=nearTopLeft
        let nTR=CGPoint(x:nearBottomLeft.x,y:nearBottomLeft.y-lift),nBR=nearBottomLeft
        let fTL=CGPoint(x:farTopLeft.x,y:farTopLeft.y-lift),fBL=farTopLeft
        let fTR=CGPoint(x:farBottomLeft.x,y:farBottomLeft.y-lift),fBR=farBottomLeft
        var net=Path();net.move(to:nTL);net.addLine(to:nTR);net.addLine(to:fTR);net.addLine(to:fTL);net.closeSubpath()
        net.move(to:nTL);net.addLine(to:nBL);net.addLine(to:fBL);net.addLine(to:fTL);net.closeSubpath()
        net.move(to:nTR);net.addLine(to:nBR);net.addLine(to:fBR);net.addLine(to:fTR);net.closeSubpath()
        context.fill(net,with:.color(.white.opacity(0.10)))
        context.stroke(net,with:.color(.white.opacity(0.72)),lineWidth:1.1)
        var backNet=Path();backNet.move(to:fTL);backNet.addLine(to:fTR);backNet.addLine(to:fBR);backNet.addLine(to:fBL);backNet.closeSubpath()
        context.fill(backNet,with:.color(.white.opacity(0.14)))
        context.stroke(backNet,with:.color(.white.opacity(0.58)),lineWidth:0.8)
        func between(_ a:CGPoint,_ b:CGPoint,_ t:Double)->CGPoint { CGPoint(x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t) }
        for t in stride(from:0.12,through:0.88,by:0.13) {
            var depth=Path();depth.move(to:between(nTL,fTL,t));depth.addLine(to:between(nTR,fTR,t));context.stroke(depth,with:.color(.white.opacity(0.35)),lineWidth:0.55)
            var side=Path();side.move(to:between(nTL,nBL,t));side.addLine(to:between(fTL,fBL,t));context.stroke(side,with:.color(.white.opacity(0.28)),lineWidth:0.55)
            var backHorizontal=Path();backHorizontal.move(to:between(fTL,fBL,t));backHorizontal.addLine(to:between(fTR,fBR,t));context.stroke(backHorizontal,with:.color(.white.opacity(0.35)),lineWidth:0.55)
            var backVertical=Path();backVertical.move(to:between(fTL,fTR,t));backVertical.addLine(to:between(fBL,fBR,t));context.stroke(backVertical,with:.color(.white.opacity(0.35)),lineWidth:0.55)
        }
        var posts=Path();posts.move(to:nBL);posts.addLine(to:nTL);posts.addLine(to:nTR);posts.addLine(to:nBR);posts.move(to:nTL);posts.addLine(to:fTL);posts.move(to:nTR);posts.addLine(to:fTR)
        context.stroke(posts,with:.color(.white),lineWidth:2.5)
        context.stroke(posts,with:.color(.black.opacity(0.32)),lineWidth:0.8)
    }
    func drawTechnicalArea(context:inout GraphicsContext,point:@escaping (FieldPoint)->CGPoint,time:Double) {
        for (bench,kit) in [(35.0,Color(red:0.85,green:0.15,blue:0.13)),(68.0,Color(red:0.24,green:0.53,blue:0.94))] {
            let anchor=point(FieldPoint(bench,78)),width=116.0,height=17.0
            let shelter=CGRect(x:anchor.x-width/2,y:anchor.y-height/2,width:width,height:height)
            context.fill(Path(roundedRect:shelter,cornerRadius:2),with:.color(Color(red:0.13,green:0.16,blue:0.18)))
            context.stroke(Path(roundedRect:shelter,cornerRadius:2),with:.color(Color(white:0.78)),lineWidth:1.3)
            context.fill(Path(CGRect(x:anchor.x-width/2-5,y:anchor.y-height/2-5,width:width+10,height:3)),with:.color(Color(white:0.82)))
            context.fill(Path(CGRect(x:anchor.x-width/2+4,y:anchor.y+height/2-4,width:width-8,height:3)),with:.color(Color(red:0.32,green:0.18,blue:0.08)))
            for seat in 0..<7 {
                let x=anchor.x-width/2+8+Double(seat)*15
                let wave=(seat+Int(time*2))%3 == 0
                let coach=seat == 0
                context.fill(Path(CGRect(x:x+2,y:anchor.y-14,width:4,height:4)),with:.color(Color(red:0.72,green:0.49,blue:0.31)))
                context.fill(Path(CGRect(x:x,y:anchor.y-10,width:8,height:7)),with:.color(coach ? Color(white:0.12):kit))
                context.fill(Path(CGRect(x:x+1,y:anchor.y-3,width:2.2,height:4)),with:.color(Color(white:0.14)))
                context.fill(Path(CGRect(x:x+5,y:anchor.y-3,width:2.2,height:4)),with:.color(Color(white:0.14)))
                context.fill(Path(CGRect(x:x-2,y:wave ? anchor.y-15:anchor.y-8,width:2,height:6)),with:.color(coach ? Color(white:0.12):kit))
            }
            let coachX=shelter.minX-9
            context.fill(Path(CGRect(x:coachX+2,y:anchor.y-21,width:4,height:4)),with:.color(Color(red:0.72,green:0.49,blue:0.31)))
            context.fill(Path(CGRect(x:coachX,y:anchor.y-17,width:8,height:10)),with:.color(Color(white:0.08)))
            context.fill(Path(CGRect(x:coachX+1,y:anchor.y-7,width:2.4,height:8)),with:.color(Color(white:0.10)))
            context.fill(Path(CGRect(x:coachX+5,y:anchor.y-7,width:2.4,height:8)),with:.color(Color(white:0.10)))
        }
    }
    enum PixelPose { case standing, running, passing, shooting, tackling }
    func pixelPose(for player:MatchPlayer,match:LiveMatch,motion:PlayerMotion)->PixelPose {
        if match.flight?.kicker == player.id { return match.flight?.kind == "shot" ? .shooting:.passing }
        if match.physicsTime-match.lastTackle < 0.35, match.events.last?.playerID == player.id, match.events.last?.kind == "tackle" { return .tackling }
        if match.phase == .ready || match.phase == .halfTime || match.phase == .fullTime { return .standing }
        return motion.isMoving ? .running:.standing
    }
    func drawPixelPlayer(context:inout GraphicsContext,center:CGPoint,scale:Double,player:MatchPlayer,kit:Color,pose:PixelPose,motion:PlayerMotion) {
        let px=max(1,scale/4.7),x=center.x,y=center.y
        let dark=Color(red:0.04,green:0.035,blue:0.03),skin=Color(red:0.78,green:0.58,blue:0.39),socks=player.side==0 ? Color(white:0.94):Color(white:0.14)
        func block(_ bx:Double,_ by:Double,_ w:Double,_ h:Double,_ color:Color) {let rect=CGRect(x:(bx*px+x).rounded(),y:(by*px+y).rounded(),width:max(1,(w*px).rounded()),height:max(1,(h*px).rounded()));context.fill(Path(rect),with:.color(color))}
        block(-3,0,6,1,dark)
        if (pose == .running || pose == .standing) && (motion.facing == .left || motion.facing == .right) {
            drawSideRunner(context:&context,center:center,px:px,player:player,kit:kit,skin:skin,socks:socks,right:motion.facing == .right,frame:motion.stride,moving:pose == .running)
            return
        }
        switch pose {
        case .tackling:
            block(-4,-5,6,3,dark);block(-3,-4,5,2,kit);block(2,-2,5,1,skin);block(-4,-1,3,1,socks);block(1,-1,4,1,dark);block(3,0,3,1,dark)
        default:
            let back=motion.facing == .back
            let stride=pose == .running ? [(-1.7,1.7),(-0.7,0.7),(1.7,-1.7),(0.7,-0.7)][motion.stride]:(0,0)
            block(-1.5,-12,3,3,dark)
            block(-1,-11,2,2,skin)
            block(-2,-13,4,1,player.number%3 == 0 ? Color(white:0.12):Color(red:0.18,green:0.09,blue:0.04))
            if back { block(-1.3,-12,2.6,1.4,dark) }
            else { block(-0.7,-10.5,0.45,0.45,dark);block(0.35,-10.5,0.45,0.45,dark) }
            block(-3,-9,6,6,dark);block(-2,-8,4,5,kit)
            if back { context.draw(Text("\(player.number)").font(.system(size:max(3,px*2.1),weight:.black,design:.monospaced)).foregroundColor(.white.opacity(0.9)),at:CGPoint(x:x,y:y-6.1*px)) }
            else { block(-1,-8,2,1,Color.white.opacity(0.75)) }
            block(-3,-4,6,2,dark);block(-2,-4,4,1,player.side==0 ? Color(white:0.92):Color(white:0.12))
            block(-2+stride.0,-2,1.5,2,socks);block(0.5+stride.1,-2,1.5,2,socks);block(-2+stride.0,-0.5,2,1,dark);block(0.5+stride.1,-0.5,2,1,dark)
            let arm=pose == .passing || pose == .shooting ? 2.6:1.5
            let swing=pose == .running ? [-1.2,-0.4,1.2,0.4][motion.stride]:0
            block(-4+swing,-8,1,arm,kit);block(3-swing,-8,1,arm,kit);block(-4+swing,-8+arm,1,1,skin);block(3-swing,-8+arm,1,1,skin)
        }
    }
    func drawSideRunner(context:inout GraphicsContext,center:CGPoint,px:Double,player:MatchPlayer,kit:Color,skin:Color,socks:Color,right:Bool,frame:Int,moving:Bool) {
        let x=center.x,y=center.y,dark=Color(red:0.04,green:0.035,blue:0.03)
        func block(_ bx:Double,_ by:Double,_ w:Double,_ h:Double,_ color:Color) {let mx=right ? bx : -bx-w;let rect=CGRect(x:(mx*px+x).rounded(),y:(by*px+y).rounded(),width:max(1,(w*px).rounded()),height:max(1,(h*px).rounded()));context.fill(Path(rect),with:.color(color))}
        let legSwing:[(Double,Double)]=[(2.8,-1.4),(-1.0,2.8),(-2.8,1.4),(1.0,-2.8)]
        let armSwing:[(Double,Double)]=[(2.2,-1.2),(0.8,-2.0),(-2.2,1.2),(-0.8,2.0)]
        let legs=moving ? legSwing[frame]:(0,0),arms=moving ? armSwing[frame]:(0,0)
        block(-0.8,-12,2.7,1,dark);block(-0.2,-11,2.2,2,skin);block(1.5,-10.4,1.3,1,skin);block(1.8,-10.1,0.9,0.7,dark);block(-1,-13,3.6,1,player.number%3==0 ? Color(white:0.12):Color(red:0.18,green:0.09,blue:0.04))
        block(-1.8,-9,4.7,6,dark);block(-1.1,-8,3.8,5,kit);block(-0.2,-8,2.4,1,Color.white.opacity(0.78));block(-2.2,-8,1.3,2.4,kit);block(-2.6+arms.0,-7.6,1.1,2.5,kit);block(-2.8+arms.0,-5.5,1,1,skin);block(1.9+arms.1,-7.1,1,2.2,kit);block(2.5+arms.1,-5.3,1,1,skin)
        block(-1.5,-4,3.8,2,dark);block(-0.9,-4,2.8,1,socks)
        block(-1.3+legs.0,-2,1.5,2,socks);block(0.4+legs.1,-2,1.5,2,socks);block(-1.8+legs.0,-0.5,2.8,1,dark);block(0.1+legs.1,-0.5,2.8,1,dark)
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
                    }.frame(width:220)
                }
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:6) {
                    setPieceChoice("Captain")
                    setPieceChoice("Defensive free kick")
                    setPieceChoice("Attacking free kick")
                    setPieceChoice("Corner")
                    setPieceChoice("Penalty")
                }
                HStack {
                    Button((tactics.offsideTrap ?? false) ? "Offside trap: ON":"Offside trap: OFF") {tactics.offsideTrap = !(tactics.offsideTrap ?? false)}
                    Button("Apply team talk") {store.career.activeMatch?.changeTactics(tactics);store.career.tactics=tactics;store.save();store.audio.play("sq_chalk");feedback="Team talk and instructions applied."}
                }
                Text("Choose set-piece takers, then apply the team talk while the match is paused.").font(.system(size:11)).foregroundStyle(muted).fixedSize(horizontal:false,vertical:true)
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
    func setPieceChoice(_ title:String)->some View {
        let players=match.managedPlayers.map {TacticsPlayerOption(id:$0.id,label:"\($0.name) · #\($0.number)")}
        return TacticsPlayerChoice(title:title,takerKey:title=="Captain" ? nil:title,players:players,tactics:$tactics)
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
