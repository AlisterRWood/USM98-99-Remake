import Foundation

public struct FieldPoint: Codable, Equatable {
    public var x: Double
    public var y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    public func distance(to b: Self) -> Double { hypot(x-b.x, y-b.y) }
    public func moved(toward b: Self, distance: Double) -> Self {
        let d = self.distance(to: b)
        guard d > 0.0001 else { return self }
        let f = min(1, distance/d)
        return Self(x+(b.x-x)*f, y+(b.y-y)*f)
    }
    public func clamped() -> Self { Self(min(104.5,max(0.5,x)), min(67.5,max(0.5,y))) }
}
public struct MatchPlayer: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var role: String
    public var skills: [Int]
    public var number: Int
    public var side: Int
    public var slot: Int
    public var point: FieldPoint
    public var fitness: Double
    public var onPitch: Bool
    public var used: Bool = false
}
public enum LivePhase: String, Codable { case ready, firstHalf, halfTime, secondHalf, fullTime }
public struct LiveEvent: Codable, Identifiable, Equatable {
    public var id: Int
    public var minute: Int
    public var kind: String
    public var text: String
    public var side: Int?
    public var playerID: String?
    public var homeScore: Int
    public var awayScore: Int
}
public struct BallFlight: Codable, Equatable {
    public var from: FieldPoint
    public var target: FieldPoint
    public var progress: Double
    public var duration: Double
    public var kind: String
    public var kicker: String
    public var receiver: String?
    public var side: Int
    public var onTarget: Bool
}
/// Fixed-step, possession-based spatial simulation. No result is generated ahead of play.
public struct LiveMatch: Codable {
    public var fixtureID: String
    public var home: String
    public var away: String
    public var managedSide: Int
    public var players: [MatchPlayer]
    public var homeTactics: Tactics
    public var awayTactics: Tactics
    public var phase: LivePhase = .ready
    public var elapsed = 0.0
    public var ball = FieldPoint(52.5,34)
    public var owner: String?
    public var flight: BallFlight?
    public var homeGoals = 0
    public var awayGoals = 0
    public var homeShots = 0
    public var awayShots = 0
    public var homeShotsOnTarget:Int? = 0
    public var awayShotsOnTarget:Int? = 0
    public var homePasses = 0
    public var awayPasses = 0
    public var completedHomePasses = 0
    public var completedAwayPasses = 0
    public var homePossession = 0.0
    public var awayPossession = 0.0
    public var homeSubs = 0
    public var awaySubs = 0
    public var attendance: Int
    public var events: [LiveEvent] = []
    public var rng: RNG
    public var holdTime = 0.0
    public var restartDelay = 0.0
    public var restartSide = 0
    public var attackCount = 0
    public var lastTackle = 0.0
    public var physicsTime = 0.0
    public var setPieceRestart:SetPieceRestart?
    public var previousPasser:String?
    public var deadBallDelay:Double?
    public var yellowCards:[String:Int]?
    public var pendingSubstitutions:[PendingSubstitution]?
    public var replayFrames:[ReplayFrame]?
    public var knockout:Bool?
    public var activeSetPlay:String?
    public var homePenalties:Int?
    public var awayPenalties:Int?
    public var clockMinute: Int { min(90,Int(elapsed/60)) }
    public var isFinished: Bool { phase == .fullTime }
    public var homePossessionPercent: Int { homePossession+awayPossession == 0 ? 50:Int(100*homePossession/(homePossession+awayPossession)) }
    public var managedTactics: Tactics { managedSide == 0 ? homeTactics:awayTactics }
    public var substitutionsUsed: Int { managedSide == 0 ? homeSubs:awaySubs }
    public var activePlayers: [MatchPlayer] { players.filter(\.onPitch) }
    public var managedPlayers: [MatchPlayer] { players.filter{$0.side == managedSide && $0.onPitch}.sorted{$0.slot < $1.slot} }
    public var bench: [MatchPlayer] { players.filter{$0.side == managedSide && !$0.onPitch && !$0.used} }
    public init(career: Career, fixture: Fixture) {
        knockout=fixture.competition != nil && fixture.competition != "Friendly"
        fixtureID=fixture.id;home=fixture.home;away=fixture.away
        managedSide=fixture.home == career.clubID ? 0:1
        homeTactics=managedSide == 0 ? career.tactics:Tactics()
        awayTactics=managedSide == 1 ? career.tactics:Tactics()
        rng=RNG(seed:career.rng.state ^ UInt64(career.week+1)*9899)
        players=[]
        for side in 0...1 {
            let club=side == 0 ? home:away
            let squad=career.players.filter{$0.clubID == club && (career.states[$0.id]?.injuryWeeks ?? 0)==0 && (career.states[$0.id]?.suspendedMatches ?? 0)==0}
            var available=squad.sorted{$0.rating > $1.rating}
            var chosen:[Player]=[]
            let tactics=side == 0 ? homeTactics:awayTactics
            for slot in 0..<11 {
                available.removeAll {p in chosen.contains{$0.id==p.id}}
                if side==managedSide,slot<career.lineup.count,let requested=available.first(where:{$0.id==career.lineup[slot]}) {
                    chosen.append(requested);continue
                }
                available.sort {a,b in
                    (a.rating+(a.position==tactics.slots[slot] ? 50:0)) > (b.rating+(b.position==tactics.slots[slot] ? 50:0))
                }
                if let p=available.first {chosen.append(p)}
            }
            let selected=Set(chosen.map(\.id))
            var remaining=squad.filter{!selected.contains($0.id)}.sorted{$0.rating > $1.rating}
            var reserves:[Player]=[]
            // A usable match bench: one keeper and cover across the outfield lines.
            for role in ["GK","DEF","DEF","MID","MID","FWD","FWD"] {
                if let index=remaining.firstIndex(where:{$0.position==role}) {
                    reserves.append(remaining.remove(at:index))
                }
            }
            reserves += remaining.filter{$0.position != "GK"}.prefix(max(0,7-reserves.count))
            if side==managedSide {
                reserves=Array(career.orderedSquad.filter{!selected.contains($0.id) && (career.states[$0.id]?.injuryWeeks ?? 0)==0 && (career.states[$0.id]?.suspendedMatches ?? 0)==0}.prefix(7))
            }
            for (i,p) in (chosen+reserves).enumerated() {
                players.append(MatchPlayer(id:p.id,name:p.name,role:p.position,skills:p.skills,number:i+1,side:side,slot:i,point:FieldPoint(52.5,34),fitness:Double(career.states[p.id]?.fitness ?? 100)-(side != managedSide && career.hasPrivateAgreement("Match approach",club:club) ? 12:0),onPitch:i<11))
            }
        }
        let demand=managedSide == 0 ? max(0.3,min(1,1.18-Double(fixture.competition==nil ? career.effectiveTicketPrice:(career.managementState.tickets[fixture.competition=="Friendly" ? "Friendly":"Cup"] ?? career.ticketPrice))/80+Double(career.confidence)/350)):0.83
        attendance=Int(Double(managedSide == 0 ? career.availableCapacity:35000)*demand*(0.92+rng.unit()*0.07))
        resetPositions(kickingSide:0)
        record("ready","The teams are ready. Kick off when you are ready.")
    }
    public mutating func startHalf() {
        guard phase == .ready || phase == .halfTime else { return }
        let second=phase == .halfTime
        phase=second ? .secondHalf:.firstHalf
        resetPositions(kickingSide:second ? 1:0)
        record("whistle",second ? "The second half begins. The teams have changed ends.":"Kick-off! The first half is underway.")
    }
    public func direction(_ side:Int) -> Double {
        let first=phase != .secondHalf && phase != .fullTime
        return (side == 0) == first ? 1:-1
    }
    public func formationPoint(slot:Int,side:Int,withBall:Bool) -> FieldPoint {
        let t=side == 0 ? homeTactics:awayTactics
        if let setPlay=activeSetPlay,let instructions=t.plan?.states["\(withBall ? "Attacking":"Defending") \(setPlay)"],slot<instructions.count {let p=instructions[slot].point;return FieldPoint(direction(side)>0 ? p.x:105-p.x,p.y)}
        let zone=min(3,max(0,Int(ball.x/26.25)))*3+min(2,max(0,Int(ball.y/(68.0/3))))+1
        if let instructions=t.plan?.states["\(withBall ? "Attack":"Defend") zone \(zone)"],slot<instructions.count {
            let p=instructions[slot].point;return FieldPoint(direction(side)>0 ? p.x:105-p.x,p.y)
        }
        if let positions=t.customPositions,positions.count==11,slot<11 {
            let p=positions[slot];return FieldPoint(direction(side)>0 ? p.x:105-p.x,p.y)
        }
        let parts=t.formation.split(separator:"-").compactMap{Int($0)}
        if slot == 0 { return FieldPoint(direction(side)>0 ? 4:101,34) }
        var start=1, row=0, count=4, column=0
        for r in 0..<3 {
            if slot < start+parts[r] { row=r;count=parts[r];column=slot-start;break }
            start += parts[r]
        }
        let normalizedBall=direction(side)>0 ? ball.x:105-ball.x
        let trap=(t.offsideTrap ?? false) && !withBall && row==0 ? 5.0:0
        let mental=trap + (t.mentality == "Attacking" ? 7.0:(t.mentality == "Defensive" ? -7.0:0))
        let base=[25.0,45.0,65.0][row]
        let shift=(normalizedBall-52.5)*0.47+(withBall ? 10.0:-4.0)+mental
        let x=min(row == 0 ? 71:98,max(10,base+shift))
        let y=68*Double(column+1)/Double(count+1)+(ball.y-34)*0.12
        return FieldPoint(direction(side)>0 ? x:105-x,y).clamped()
    }
    mutating func resetPositions(kickingSide:Int) {
        activeSetPlay=nil;setPieceRestart=nil;previousPasser=nil
        activeSetPlay="kick off";flight=nil;owner=nil;holdTime=0;attackCount=0;ball=FieldPoint(52.5,34)
        for i in players.indices where players[i].onPitch {
            var p=formationPoint(slot:players[i].slot,side:players[i].side,withBall:players[i].side==kickingSide)
            let d=direction(players[i].side)
            if d>0 { p.x=min(49,p.x) } else { p.x=max(56,p.x) }
            players[i].point=p
        }
        if let index=players.indices.first(where:{players[$0].side == kickingSide && players[$0].onPitch && players[$0].slot==10}) {
            players[index].point=ball;owner=players[index].id
        }
    }
    mutating func record(_ kind:String,_ text:String,side:Int?=nil,player:String?=nil) {
        events.append(LiveEvent(id:events.count,minute:clockMinute,kind:kind,text:text,side:side,playerID:player,homeScore:homeGoals,awayScore:awayGoals))
    }
    public mutating func changeTactics(_ tactics:Tactics) {
        guard phase != .fullTime,["4-4-2","4-3-3","3-5-2","5-3-2"].contains(tactics.formation) else {return}
        if managedSide==0 { homeTactics=tactics } else { awayTactics=tactics }
        record("tactics","Tactical change: \(tactics.formation), \(tactics.mentality.lowercased()), \(tactics.passing.lowercased()) passing.",side:managedSide)
    }
    @discardableResult public mutating func substitute(out:String,in incoming:String) -> Bool {
        guard phase != .fullTime,substitutionsUsed<3,
              let a=players.firstIndex(where:{$0.id==out && $0.side==managedSide && $0.onPitch}),
              let b=players.firstIndex(where:{$0.id==incoming && $0.side==managedSide && !$0.onPitch && !$0.used}) else {return false}
        players[b].point=players[a].point;players[b].slot=players[a].slot
        players[a].onPitch=false;players[a].used=true;players[b].onPitch=true
        if owner==out {owner=incoming}
        if setPieceRestart?.taker==out {setPieceRestart?.taker=incoming}
        if flight?.receiver==out {flight?.receiver=incoming}
        if managedSide==0 {homeSubs += 1} else {awaySubs += 1}
        record("substitution","\(players[b].name) comes on for \(players[a].name).",side:managedSide,player:incoming)
        return true
    }
    /// dt is physical seconds; the match clock advances eight seconds per physical second.
    public mutating func step(_ dt:Double=0.1) {
        guard phase == .firstHalf || phase == .secondHalf else {return}
        let dt=min(0.1,max(0,dt));physicsTime += dt;elapsed += dt*8
        captureReplay()
        if setPieceRestart != nil {stepRestart(dt);return}
        if let delay=deadBallDelay,delay>0 {deadBallDelay=max(0,delay-dt);return}
        if phase == .firstHalf && elapsed>=2700 {
            elapsed=2700;phase = .halfTime;applyPendingSubstitutions();flight=nil;record("whistle","Half-time. Make your changes, then start the second half.");return
        }
        if elapsed>=5400 {if knockout==true && homeGoals==awayGoals {penaltyShootout()};elapsed=5400;phase = .fullTime;flight=nil;record("whistle","Full-time. \(homeGoals)–\(awayGoals). The referee ends the match.");return}
        if restartDelay>0 {
            applyPendingSubstitutions()
            restartDelay -= dt
            if restartDelay<=0 {resetPositions(kickingSide:restartSide);record("whistle","Play restarts from the centre spot.")}
            return
        }
        let owningSide=owner.flatMap{id in players.first{$0.id==id}?.side} ?? flight?.side ?? restartSide
        if owningSide==0 {homePossession += dt} else {awayPossession += dt}
        // Both teams move relative to possession and territory, never confined to their own half.
        let defending=players.indices.filter{players[$0].onPitch && players[$0].side != owningSide && players[$0].slot != 0}.sorted{players[$0].point.distance(to:ball)<players[$1].point.distance(to:ball)}
        for i in players.indices where players[i].onPitch {
            let p=players[i],owns=p.id==owner
            var target=formationPoint(slot:p.slot,side:p.side,withBall:p.side==owningSide)
            if owns {
                let d=direction(p.side),goalDistance=d>0 ? 105-p.point.x:p.point.x
                target=FieldPoint(p.point.x+d*12, p.point.y+(34-p.point.y)*0.12).clamped()
                if goalDistance<10 {target.y=34}
                if p.slot==0 {target=p.point}
            } else if p.side != owningSide {
                if p.slot==0 {target=FieldPoint(direction(p.side)>0 ? 3:102, min(40,max(28,34+(ball.y-34)*0.22)))}
                else if defending.prefix(2).contains(i) {target=ball}
            } else if flight?.receiver==p.id {target=flight!.target.clamped()}
            // Formations describe each player's starting reference, not a rail to stand on.
            // Away from the ball, players create passing angles, make late runs and recover
            // into the space that is actually under threat.
            if !owns && flight?.receiver != p.id && !(p.side != owningSide && defending.prefix(1).contains(i)) { target=openPlayTarget(for:p,base:target,owningSide:owningSide) }
            if p.slot==0 {target=goalkeeperTarget(p)}
            let pace=runningSpeed(p,carrying:owns)
            players[i].point=p.point.moved(toward:target,distance:pace*dt).clamped()
            players[i].fitness=max(30,p.fitness-dt*0.025)
        }
        if var f=flight {
            f.progress=min(1,f.progress+dt/f.duration)
            ball=FieldPoint(f.from.x+(f.target.x-f.from.x)*f.progress,f.from.y+(f.target.y-f.from.y)*f.progress)
            flight=f
            if f.kind=="pass" && f.progress>0.18 && f.progress<0.94,
               let defender=players.indices.filter({players[$0].onPitch && players[$0].side != f.side}).min(by:{players[$0].point.distance(to:ball)<players[$1].point.distance(to:ball)}),
               players[defender].point.distance(to:ball)<1.6 {
                owner=players[defender].id;flight=nil;ball=players[defender].point;holdTime=0;attackCount=0
                record("interception","\(players[defender].name) cuts out the pass.",side:players[defender].side,player:owner)
                return
            }
            if f.progress>=1 {resolveFlight(f)}
            return
        }
        guard let oi=players.firstIndex(where:{$0.id==owner && $0.onPitch}) else {
            if let nearest=players.indices.filter({players[$0].onPitch && (players[$0].slot != 0 || players[$0].point.distance(to:ball)<3)}).min(by:{players[$0].point.distance(to:ball)<players[$1].point.distance(to:ball)}) {
                players[nearest].point=players[nearest].point.moved(toward:ball,distance:runningSpeed(players[nearest],carrying:false)*dt)
                if players[nearest].point.distance(to:ball)<1.8 {owner=players[nearest].id;holdTime=0;activeSetPlay=nil}
            }
            return
        }
        ball=players[oi].point;holdTime += dt
        let carrier=players[oi],d=direction(carrier.side),distance=d>0 ? 105-ball.x:ball.x
        if physicsTime-lastTackle>1.2,holdTime>0.5,let di=defending.first,players[di].point.distance(to:ball)<1.7 {
            lastTackle=physicsTime
            let tackler=players[di]
            let t=tackler.side==0 ? homeTactics:awayTactics
            if rng.unit()<(t.tackling=="Hard" ? 0.20:(t.tackling=="Cautious" ? 0.035:0.08)) {awardFoul(offender:di,victim:oi);return}
            let chance=0.34+Double(tackler.skills[1]-carrier.skills[8])/180+(t.tackling=="Hard" ? 0.12:0)
            if rng.unit()<chance {owner=tackler.id;holdTime=0;attackCount=0;record("tackle","\(tackler.name) wins the ball.",side:tackler.side,player:tackler.id);return}
        }
        let pressure=defending.first.map{players[$0].point.distance(to:ball)} ?? 20
        let tactics=carrier.side==0 ? homeTactics:awayTactics
        let shotRange=carrier.role == "FWD" ? 29.0:(carrier.role == "MID" ? 27.0:24.0)
        let centralEnough=abs(ball.y-34) < (carrier.role == "DEF" ? 20:25)
        let roleWillingness=carrier.role == "FWD" ? 0.90:(carrier.role == "MID" ? 0.55:0.28)
        let earnedLook=attackCount>=2 && distance < shotRange-2
        if carrier.slot != 0 && distance<shotRange && centralEnough && holdTime>0.45 && (distance<13 || earnedLook || rng.unit()<dt*(roleWillingness+Double(carrier.skills[3])/90)) {
            shoot(oi);return
        }
        let wait=tactics.passing=="Short" ? 1.2:(tactics.passing=="Direct" ? 1.9:2.4)
        let runningLane=pressure>3.5 && carrier.slot != 0 && distance>15 && distance<48
        let carryLimit=tactics.passing=="Short" ? 1.2:(tactics.passing=="Direct" ? 1.8:2.5+Double(carrier.skills[4]+carrier.skills[8])/65)
        if runningLane && holdTime<carryLimit {if holdTime>1.5 && holdTime<1.5+dt {record("dribble","\(carrier.name) drives towards goal.",side:carrier.side,player:carrier.id)};return}
        if holdTime>wait || (pressure<3 && holdTime>0.9) || (carrier.slot==0 && holdTime>1.1) {pass(oi)}
    }
    mutating func pass(_ oi:Int) {
        activeSetPlay=nil
        let p=players[oi],d=direction(p.side),t=p.side==0 ? homeTactics:awayTactics
        let teammates=players.indices.filter{players[$0].onPitch && players[$0].side==p.side && $0 != oi && players[$0].point.distance(to:p.point)>4}
        guard !teammates.isEmpty else {return}
        var best=teammates[0],bestScore = -Double.infinity
        for i in teammates {
            let target=players[i],distance=p.point.distance(to:target.point)
            let forward=(target.point.x-p.point.x)*d
            let space=players.filter{$0.onPitch && $0.side != p.side}.map{$0.point.distance(to:target.point)}.min() ?? 20
            let optimal=t.passing=="Direct" ? 32.0:(t.passing=="Short" ? 12.0:21.0)
            let score=forward*(t.mentality=="Attacking" ? 0.9:(t.mentality=="Defensive" ? 0.2:0.5))+min(15,space)*1.3-abs(distance-optimal)*(t.passing=="Short" ? 1.8:0.9)+(rng.unit()*4)-(target.id==previousPasser ? 5:0)
            if score>bestScore {bestScore=score;best=i}
        }
        let receiver=players[best]
        let defence=players.filter{$0.onPitch && $0.side != p.side}.map{$0.point.x*d}.sorted(by:>)
        if defence.count>=2,receiver.point.x*d>defence[1],receiver.point.x*d>ball.x*d,receiver.point.x*d>(d>0 ? 52.5:-52.5) {
            let opponents=players.indices.filter{players[$0].onPitch && players[$0].side != p.side}
            if let nearest=opponents.min(by:{players[$0].point.distance(to:receiver.point)<players[$1].point.distance(to:receiver.point)}) {owner=players[nearest].id;ball=players[nearest].point;holdTime = -2;record("offside","Offside against \(receiver.name).",side:p.side,player:receiver.id);return}
        }
        let leadership=t.captain.flatMap{id in players.first{$0.id==id && $0.onPitch}}.map{Double($0.skills[8])/100} ?? 0
        let error=max(0,Double(100-p.skills[2])/35-leadership*0.2)
        let lead=receiver.slot==0 ? 0:3.0
        let target=FieldPoint(receiver.point.x+d*lead+(rng.unit()-0.5)*error,receiver.point.y+(rng.unit()-0.5)*error).clamped()
        flight=BallFlight(from:ball,target:target,progress:0,duration:max(0.25,ball.distance(to:target)/(t.passing=="Direct" ? 27:21)),kind:"pass",kicker:p.id,receiver:receiver.id,side:p.side,onTarget:false)
        previousPasser=p.id
        owner=nil;holdTime=0;attackCount += 1
        if p.side==0 {homePasses += 1} else {awayPasses += 1}
        record("pass","\(p.name) passes to \(receiver.name).",side:p.side,player:p.id)
    }
    mutating func shoot(_ i:Int) {
        let p=players[i],d=direction(p.side),dist=p.point.distance(to:FieldPoint(d>0 ? 105:0,34))
        let setPiece=activeSetPlay=="free kick" || activeSetPlay=="penalty"
        let skill=setPiece ? (p.skills[3]+p.skills[7])/2:p.skills[3]
        let accuracy=min(0.94,max(0.12,Double(skill)/105-dist/160))
        activeSetPlay=nil
        let onTarget=rng.unit()<accuracy
        if onTarget {
            if p.side==0,let count=homeShotsOnTarget {homeShotsOnTarget=count+1}
            else if p.side==1,let count=awayShotsOnTarget {awayShotsOnTarget=count+1}
        }
        let y=onTarget ? 34+(rng.unit()-0.5)*6.8 : 34+(rng.unit()<0.5 ? -1:1)*(4.5+rng.unit()*7)
        let target=FieldPoint(d>0 ? 105.8:-0.8,y)
        flight=BallFlight(from:ball,target:target,progress:0,duration:max(0.3,ball.distance(to:target)/29),kind:"shot",kicker:p.id,receiver:nil,side:p.side,onTarget:onTarget)
        owner=nil;holdTime=0
        if p.side==0 {homeShots += 1} else {awayShots += 1}
        record("shot","\(p.name) shoots!",side:p.side,player:p.id)
    }
    mutating func resolveFlight(_ f:BallFlight) {
        flight=nil
        if f.kind=="pass" {
            activeSetPlay=nil
            if let r=players.firstIndex(where:{$0.id==f.receiver && $0.onPitch}) {
                let distance=players[r].point.distance(to:ball)
                if distance<5 {
                    owner=players[r].id;ball=players[r].point
                    if f.side==0 {completedHomePasses += 1} else {completedAwayPasses += 1}
                } else {owner=nil}
            }
        } else {
            let keeper=players.firstIndex{$0.onPitch && $0.side != f.side && $0.slot==0}
            let shooter=players.first{$0.id==f.kicker}
            let distance=f.from.distance(to:FieldPoint(direction(f.side)>0 ? 105:0,34))
            let keeping=keeper.map{Double(players[$0].skills[0])} ?? 30
            let shooting=Double(shooter?.skills[3] ?? 60)
            let saveChance=min(0.91,max(0.25,0.42+keeping/220+distance/130-shooting/370))
            if f.onTarget && rng.unit()>saveChance {
                if f.side==0 {homeGoals += 1} else {awayGoals += 1}
                ball=f.target
                record("goal","GOAL! \(shooter?.name ?? "A superb finish")!",side:f.side,player:f.kicker)
                owner=nil;restartDelay=3.2;restartSide=1-f.side
            } else if f.onTarget && rng.unit()<0.25 {
                awardCorner(side:f.side,left:f.target.y<34)
            } else if let k=keeper {
                if !f.onTarget {activeSetPlay="goal kick";deadBallDelay=1;applyPendingSubstitutions()}
                owner=players[k].id;ball=players[k].point;holdTime=0;attackCount=0
                record(f.onTarget ? "save":"miss",f.onTarget ? "\(players[k].name) makes the save!":"The shot goes wide. Goal kick.",side:1-f.side,player:players[k].id)
            }
        }
        holdTime=0
    }
    public mutating func finishInstantly() {
        if phase == .ready {startHalf()}
        var safety=0
        while !isFinished && safety<60000 {
            if phase == .halfTime {startHalf()}
            step();safety += 1
        }
    }
    public func report() -> MatchReport {
        MatchReport(home:home,away:away,homeGoals:homeGoals,awayGoals:awayGoals,possession:homePossessionPercent,homeShots:homeShots,awayShots:awayShots,homePenalties:homePenalties,awayPenalties:awayPenalties,attendance:attendance,events:events.filter{$0.kind != "pass" && $0.kind != "tackle"}.map{MatchEvent(id:$0.id,minute:$0.minute,text:$0.text,homeScore:$0.homeScore,awayScore:$0.awayScore)})
    }
}
