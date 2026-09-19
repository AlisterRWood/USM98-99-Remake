import Foundation
public struct PendingSubstitution:Codable {public var outgoing:String,incoming:String}
public struct ReplayFrame:Codable {
    public var time:Double,ball:FieldPoint,points:[String:FieldPoint],home:Int,away:Int
}
public extension LiveMatch {
    @discardableResult mutating func requestSubstitution(out:String,in incoming:String)->Bool {
        guard !isFinished,substitutionsUsed+(pendingSubstitutions?.count ?? 0)<3,
            managedPlayers.contains(where:{$0.id==out}),bench.contains(where:{$0.id==incoming}),
            !(pendingSubstitutions ?? []).contains(where:{$0.outgoing==out || $0.incoming==incoming}) else{return false}
        if phase == .ready || phase == .halfTime || setPieceRestart != nil || restartDelay>0 || (deadBallDelay ?? 0)>0 {return substitute(out:out,in:incoming)}
        if pendingSubstitutions==nil {pendingSubstitutions=[]};pendingSubstitutions!.append(PendingSubstitution(outgoing:out,incoming:incoming));return true
    }
    mutating func applyPendingSubstitutions(){let pending=pendingSubstitutions ?? [];pendingSubstitutions=[];for sub in pending{_=substitute(out:sub.outgoing,in:sub.incoming)}}
    mutating func captureReplay(){
        if replayFrames==nil{replayFrames=[]}
        if let last=replayFrames!.last,elapsed-last.time<4{return}
        replayFrames!.append(ReplayFrame(time:elapsed,ball:ball,points:Dictionary(uniqueKeysWithValues:activePlayers.map{($0.id,$0.point)}),home:homeGoals,away:awayGoals))
        if replayFrames!.count>1500 {replayFrames!.removeFirst()}
    }
    mutating func awardFoul(offender:Int,victim:Int){
        let side=players[victim].side;let t=side==0 ? homeTactics:awayTactics
        record("foul","Foul by \(players[offender].name).",side:players[offender].side,player:players[offender].id)
        if yellowCards==nil{yellowCards=[:]}
        let tackling=(players[offender].side==0 ? homeTactics:awayTactics).tackling
        let severity=rng.unit()
        if severity < (tackling=="Hard" ? 0.055:0.012) {
            players[offender].onPitch=false;players[offender].used=true
            record("red","Straight red: \(players[offender].name) is sent off for a dangerous challenge.",side:players[offender].side,player:players[offender].id)
        } else if severity < (tackling=="Hard" ? 0.48:(tackling=="Cautious" ? 0.12:0.25)) {
            let id=players[offender].id;yellowCards![id,default:0]+=1
            if yellowCards![id]!>=2 {players[offender].onPitch=false;players[offender].used=true;record("red","Second yellow: \(players[offender].name) is sent off.",side:players[offender].side,player:id)}else{record("yellow","\(players[offender].name) is booked.",side:players[offender].side,player:id)}
        }
        let penalty=(direction(side)>0 ? ball.x>88.5:ball.x<16.5) && abs(ball.y-34)<20.15
        let key=penalty ? "Penalty":((direction(side)>0 ? ball.x>70:ball.x<35) ? "Attacking free kick":"Defensive free kick")
        let taker=players.firstIndex{$0.id==t.takers?[key] && $0.onPitch} ?? victim
        let spot=penalty ? FieldPoint(direction(side)>0 ? 94:11,34):ball
        prepareRestart(kind:penalty ? "penalty":"free kick",side:side,taker:taker,spot:spot)
        record(penalty ? "penalty":"free kick",penalty ? "Penalty awarded! \(players[taker].name) prepares to take it.":"Free kick awarded. \(players[taker].name) waits for the referee.",side:side,player:players[taker].id)

    }
}

public extension LiveMatch {
    mutating func penaltyShootout(){
        guard homePenalties==nil else{return}
        var score=[0,0];var round=0
        repeat {
            for side in 0...1 {
                let shooters=players.filter{$0.side==side && $0.onPitch}.sorted{$0.skills[3]>$1.skills[3]}
                guard !shooters.isEmpty else{continue}
                let p=shooters[round%shooters.count]
                let goal=rng.unit()<0.58+Double(p.skills[3])/400
                if goal{score[side]+=1}
                record("penalty",p.name+(goal ? " scores in the shoot-out.":" misses in the shoot-out."),side:side,player:p.id)
            }
            round+=1
        }while round<5 || (score[0]==score[1] && round<30)
        if score[0]==score[1] {score[rng.int(0...1)]+=1}
        homePenalties=score[0];awayPenalties=score[1];record("shootout","Shoot-out: \(score[0])–\(score[1]).")
    }
}

public struct SetPieceRestart:Codable {
    public var kind:String,side:Int,taker:String
    public var remaining:Double
}
public extension LiveMatch {
    /// Adds the movement a player makes around their formation reference during open play.
    /// Tactical-plan coordinates remain authoritative; this is only used for the native
    /// fallback engine when a player is not carrying or receiving the ball.
    func openPlayTarget(for player:MatchPlayer,base:FieldPoint,owningSide:Int) -> FieldPoint {
        if player.slot==0 {return goalkeeperTarget(player)}
        guard activeSetPlay == nil else { return base }
        let tactics=player.side==0 ? homeTactics:awayTactics
        let zone=min(3,max(0,Int(ball.x/26.25)))*3+min(2,max(0,Int(ball.y/(68.0/3))))+1
        if tactics.plan?.states["\(player.side==owningSide ? "Attack":"Defend") zone \(zone)"] != nil {return base}
        let d=direction(player.side)
        let attacking=player.side == owningSide
        let forwardBall=(ball.x-52.5)*d
        let wideBall=ball.y-34
        var x=base.x,y=base.y
        if attacking {
            switch player.role {
            case "MID":
                // Midfielders arrive beyond the ball instead of preserving a flat second line.
                let lateRun=max(0,forwardBall)*0.18+5
                x += d*lateRun
                y += (wideBall-y+34)*0.16
            case "DEF":
                // Only the wide defender on the ball side overlaps; the other holds cover.
                let isBallSide=(wideBall < 0) == (base.y < 34)
                let overlap=isBallSide && forwardBall>0 ? min(17,4+forwardBall*0.20):max(-3,forwardBall*0.05)
                x += d*overlap
                y += (wideBall-y+34)*0.12
            case "FWD":
                // Split forwards and create a near/far-post option rather than stacking.
                x += d*(forwardBall > 0 ? 5:1)
                y += (wideBall > 0 ? -1:1) * (player.slot % 2 == 0 ? 7:-7)
            default: break
            }
        } else {
            switch player.role {
            case "MID":
                x += d*min(10,max(-5,forwardBall*0.16-2))
                y += (wideBall-y+34)*0.18
            case "DEF":
                // Defenders tuck in toward the ball, while still retaining line depth.
                x += d*min(8,max(-6,forwardBall*0.12-2))
                y += (wideBall-y+34)*0.26
            case "FWD":
                // The nearest forward screens the outlet; the other stays available to break.
                x += d*(player.slot % 2 == 0 ? 3:-4)
            default: break
            }
        }
        // Choose individual support jobs from proximity, not a shared line shift.
        let teammates=players.filter{$0.onPitch && $0.side==player.side && $0.slot != 0 && $0.id != owner}.sorted {
            let a=$0.point.distance(to:ball),b=$1.point.distance(to:ball)
            return a==b ? $0.slot<$1.slot:a<b
        }
        let rank=teammates.firstIndex(where:{$0.id==player.id}) ?? 9
        let role=tactics.slots[min(10,player.slot)]
        if attacking {
            let ambition=tactics.mentality=="Attacking" ? 1.0:(tactics.mentality=="Defensive" ? 0.35:0.65)
            let flank=base.y<34 ? -1.0:1.0
            if rank<2 {
                let reach=tactics.passing=="Short" ? 10.0:18.0
                x=ball.x+d*(rank==0 ? -reach*0.55:reach*0.65)
                y=ball.y+flank*reach
            } else if role != "DEF" && rank<6 {
                x=base.x+d*(8+12*ambition)
                y=34+flank*(rank%2==0 ? 10:20)
            } else if role=="DEF" {
                x=base.x+d*(abs(base.y-34)>17 ? 7*ambition:0)
            }
            // Separate passing lanes using opponents' actual positions.
            for opponent in players where opponent.onPitch && opponent.side != player.side && opponent.point.distance(to:FieldPoint(x,y))<5 {
                y += opponent.point.y<y ? 4:-4
            }
        } else if let threat=players.filter({$0.onPitch && $0.side != player.side && $0.slot != 0 && $0.id != owner}).min(by:{$0.point.distance(to:base)<$1.point.distance(to:base)}),base.distance(to:threat.point)<22 {
            x=base.x*0.35+(threat.point.x-d*3)*0.65
            y=base.y*0.35+threat.point.y*0.65
        }
        let attackingLimit=attacking ? 99.0:96.0
        let defendingLimit=attacking ? 8.0:19.0
        if d>0 { x=min(attackingLimit,max(defendingLimit,x)) } else { x=max(105-attackingLimit,min(105-defendingLimit,x)) }
        return FieldPoint(x,min(64,max(4,y)))
    }
    func goalkeeperTarget(_ player:MatchPlayer)->FieldPoint {
        let d=direction(player.side),territory=d>0 ? ball.x:105-ball.x
        let depth=min(10,max(2,territory*0.10))
        return FieldPoint(d>0 ? depth:105-depth,min(41,max(27,34+(ball.y-34)*0.18)))
    }
    func runningSpeed(_ player:MatchPlayer,carrying:Bool)->Double {
        (2.8+Double(player.skills[4])*0.065)*(0.65+player.fitness/285)*(carrying ? 0.84:1)
    }
    mutating func prepareRestart(kind:String,side:Int,taker:Int,spot:FieldPoint) {
        ball=spot;flight=nil;owner=players[taker].id;players[taker].point=spot;holdTime=0
        activeSetPlay=kind;deadBallDelay=nil
        setPieceRestart=SetPieceRestart(kind:kind,side:side,taker:players[taker].id,remaining:3)
        applyPendingSubstitutions()
    }
    mutating func awardCorner(side:Int,left:Bool) {
        let t=side==0 ? homeTactics:awayTactics
        guard let i=players.firstIndex(where:{$0.id==t.takers?["Corner"] && $0.onPitch && $0.side==side}) ?? players.firstIndex(where:{$0.side==side && $0.onPitch && $0.slot != 0}) else{return}
        prepareRestart(kind:left ? "left corner":"right corner",side:side,taker:i,spot:FieldPoint(direction(side)>0 ? 104.5:0.5,left ? 0.5:67.5))
        record("corner","Corner awarded. \(players[i].name) places the ball; players move into position.",side:side,player:players[i].id)
    }
    mutating func stepRestart(_ dt:Double) {
        guard var restart=setPieceRestart else{return}
        let side=restart.side,d=direction(side),spot=ball
        let t=side==0 ? homeTactics:awayTactics
        let cornerAttackers=restart.kind.contains("corner") ? players.indices.filter { players[$0].onPitch && players[$0].side==side && players[$0].id != restart.taker && players[$0].slot != 0 } : []
        let cornerTargets=Dictionary(uniqueKeysWithValues:cornerAttackers.enumerated().map { offset,index in
            // Near post, penalty spot, far post and edge-of-box runs.  The pattern varies
            // by player rather than placing both teams in one unmarked horizontal queue.
            let lanes:[(Double,Double)]=[(96,23),(92,31),(95,39),(89,46),(84,34),(78,25),(79,43)]
            let lane=lanes[offset % lanes.count]
            return (index,FieldPoint(d>0 ? lane.0:105-lane.0,lane.1))
        })
        for i in players.indices where players[i].onPitch && players[i].id != restart.taker {
            let p=players[i];let attacking=p.side==side
            var target=formationPoint(slot:p.slot,side:p.side,withBall:attacking)
            let ownTactics=attacking ? t:(side==0 ? awayTactics:homeTactics)
            let custom=ownTactics.plan?.states["\(attacking ? "Attacking":"Defending") \(restart.kind)"] != nil
            if !custom && p.slot != 0 {
                if restart.kind.contains("corner") {
                    if attacking {
                        target=cornerTargets[i] ?? target
                    } else if let mark=cornerAttackers.min(by:{
                        let a=cornerTargets[$0] ?? players[$0].point, b=cornerTargets[$1] ?? players[$1].point
                        return p.point.distance(to:a) < p.point.distance(to:b)
                    }) {
                        // Goal-side marking puts defenders among the runners, not beside them.
                        let runner=cornerTargets[mark] ?? players[mark].point
                        target=FieldPoint(runner.x+d*1.7,runner.y+(Double((p.slot+mark)%3)-1)*1.3).clamped()
                    }
                }
                else if restart.kind=="penalty" {target=FieldPoint(d>0 ? 84:21,15+Double(p.slot%8)*5)}
                else if !attacking && p.slot<5 {target=FieldPoint(spot.x+d*9.5,spot.y+Double(p.slot-2)*1.2).clamped()}
            }
            if p.slot==0 {target=goalkeeperTarget(p)}
            else if !attacking && target.distance(to:spot)<9.15 {target=FieldPoint(spot.x-d*10,target.y).clamped()}
            let setupSpeed=restart.kind.contains("corner") ? 1.9:1.4
            players[i].point=p.point.moved(toward:target,distance:runningSpeed(p,carrying:false)*dt*setupSpeed).clamped()
        }
        restart.remaining-=dt;setPieceRestart=restart
        guard restart.remaining<=0 else{return}
        setPieceRestart=nil
        guard let i=players.firstIndex(where:{$0.id==restart.taker && $0.onPitch}) else{owner=nil;activeSetPlay=nil;return}
        owner=players[i].id;players[i].point=spot
        let distance=spot.distance(to:FieldPoint(d>0 ? 105:0,34))
        if restart.kind=="penalty" || (restart.kind=="free kick" && distance<30) {shoot(i);return}
        if restart.kind.contains("corner") {
            let candidates=players.indices.filter{players[$0].side==side && players[$0].onPitch && $0 != i && players[$0].slot != 0}
            guard let receiver=candidates.max(by:{players[$0].skills[5]<players[$1].skills[5]}) else{return}
            let error=Double(100-players[i].skills[7])/45
            let target=FieldPoint(players[receiver].point.x+(rng.unit()-0.5)*error,players[receiver].point.y+(rng.unit()-0.5)*error).clamped()
            flight=BallFlight(from:spot,target:target,progress:0,duration:max(0.6,spot.distance(to:target)/19),kind:"pass",kicker:players[i].id,receiver:players[receiver].id,side:side,onTarget:false)
            owner=nil;attackCount=3
            record("cross","\(players[i].name) delivers the corner into the penalty area.",side:side,player:players[i].id)
        }else{pass(i)}
    }
}
