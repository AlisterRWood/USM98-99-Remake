import Foundation
import USMCore

final class CareerTests {
    func testKeeperAndDisciplineRegression() throws {
        let c=try career(),fixture=try XCTUnwrap(c.nextFixture)
        var m=LiveMatch(career:c,fixture:fixture);m.startHalf();m.activeSetPlay=nil
        for phase in [LivePhase.firstHalf,.secondHalf] {
            m.phase=phase
            for side in 0...1 {
                let k=try XCTUnwrap(m.players.first{$0.side==side && $0.slot==0 && $0.onPitch})
                for x in [5.0,52.5,100.0] {
                    m.ball=FieldPoint(x,60)
                    let target=m.openPlayTarget(for:k,base:FieldPoint(52,34),owningSide:1-side)
                    let depth=m.direction(side)>0 ? target.x:105-target.x
                    XCTAssertTrue(depth<=10 && depth>=2)
                }
            }
        }
        var counts=[String:Int]()
        for style in ["Normal","Hard"] {
            var cards=0
            for seed in 1...100 {
                var game=LiveMatch(career:c,fixture:fixture);game.startHalf();game.rng=RNG(seed:UInt64(seed));game.awayTactics.tackling=style
                let offender=game.players.firstIndex{$0.side==1 && $0.slot==2}!,victim=game.players.firstIndex{$0.side==0 && $0.slot==9}!
                game.ball=FieldPoint(65,34);game.awardFoul(offender:offender,victim:victim)
                if game.events.contains(where:{$0.kind=="red" || $0.kind=="yellow"}) {cards+=1}
                if game.events.contains(where:{$0.kind=="red"}) {XCTAssertFalse(game.players[offender].onPitch)}
            }
            counts[style]=cards
        }
        XCTAssertTrue(counts["Hard"]!>counts["Normal"]!)
        // A straight red has no yellow-card entry but must still create a ban.
        var career=c
        let id=m.players.first{$0.side==m.managedSide && $0.slot==2}!.id
        m.phase = .fullTime;m.yellowCards=[:]
        var event=m.events[0];event.kind="red";event.playerID=id;event.side=m.managedSide;m.events.append(event)
        career.advanceWeek(completedMatch:m)
        XCTAssertEqual(career.states[id]?.suspendedMatches,3)
        if let next=career.nextFixture {XCTAssertFalse(LiveMatch(career:career,fixture:next).players.contains{$0.id==id})}
    }
    func database() throws -> Database {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try Database.load(root.appendingPathComponent("Sources/USMApp/Resources/database.json"))
    }
    func career() throws -> Career { Career(database:try database(),clubID:"N-0",manager:"Test",seed:12345) }
    func testNegotiationRepliesWithoutCalendar() throws {
        var c=try career();c.cash=100_000_000
        let p=try XCTUnwrap(c.players.first{$0.clubID != c.clubID && $0.rating<60})
        let week=c.week;XCTAssertTrue(c.enquire(p.id));let id=c.management!.negotiations.last!.id
        XCTAssertTrue(c.reviewNegotiationReply(id));XCTAssertEqual(c.management!.negotiations.last!.stage,"Club asking price")
        XCTAssertFalse(c.acceptTransfer(id))
        XCTAssertTrue(c.submitTerms(id,fee:0,wage:p.wage,bonus:p.wage*4,years:3));XCTAssertTrue(c.reviewNegotiationReply(id));XCTAssertEqual(c.management!.negotiations.last!.stage,"Club counter offer")
        XCTAssertTrue(c.submitTerms(id,fee:p.value,wage:p.wage,bonus:p.wage*4,years:3));XCTAssertTrue(c.reviewNegotiationReply(id));XCTAssertEqual(c.management!.negotiations.last!.stage,"Player terms")
        // A later contract offer must not reset the agreed club fee.
        XCTAssertTrue(c.submitTerms(id,fee:0,wage:p.wage,bonus:p.wage*4,years:3));XCTAssertTrue(c.reviewNegotiationReply(id));XCTAssertEqual(c.management!.negotiations.last!.stage,"Final review")
        XCTAssertEqual(c.management!.negotiations.last!.fee,p.value);let before=c.cash
        XCTAssertTrue(c.acceptTransfer(id));XCTAssertEqual(c.cash,before-p.value-p.wage*4);XCTAssertEqual(c.week,week);XCTAssertEqual(c.management!.elapsed,0)
        XCTAssertFalse(c.acceptTransfer(id));XCTAssertEqual(c.management!.negotiations.last!.stage,"Completed")
        // A genuine sale finalises using the same explicit approval path.
        let own=c.squad.first{$0.id != p.id}!,buyer=c.clubs.first{$0.id != c.clubID}!.id
        var sale=Negotiation(player:own,week:0,selling:true);sale.clubID=buyer;sale.stage="Final review";c.management!.negotiations.append(sale)
        let cash=c.cash;XCTAssertTrue(c.acceptTransfer(sale.id));XCTAssertEqual(c.cash,cash+sale.fee);XCTAssertEqual(c.players.first{$0.id==own.id}?.clubID,buyer);XCTAssertFalse(c.acceptTransfer(sale.id))
    }
    func testClosedNegotiationsAreClearedTheFollowingWeek() throws {
        var c=try career();let player=try XCTUnwrap(c.players.first{$0.clubID != c.clubID})
        XCTAssertTrue(c.enquire(player.id));let withdrawnID=try XCTUnwrap(c.management?.negotiations.last?.id)
        c.withdrawNegotiation(withdrawnID)
        XCTAssertEqual(c.management?.negotiations.first{$0.id==withdrawnID}?.stage,"Withdrawn")
        c.progressManagement()
        XCTAssertFalse(c.management?.negotiations.contains{$0.id==withdrawnID} ?? true)

        var failed=Negotiation(player:player,week:c.managementState.elapsed,selling:true)
        failed.stage="Rejected";failed.closedWeek=c.managementState.elapsed
        c.management?.negotiations.append(failed)
        c.progressManagement()
        XCTAssertFalse(c.management?.negotiations.contains{$0.id==failed.id} ?? true)
    }
    func testStandAppearanceAndRoofPreviewRules() throws {
        XCTAssertEqual(StandAppearance(capacity:1000),StandAppearance(capacity:4999))
        XCTAssertNotEqual(StandAppearance(capacity:4999),StandAppearance(capacity:5000))
        XCTAssertEqual(StandAppearance(capacity:10000).decks,2);XCTAssertEqual(StandAppearance(capacity:15000).decks,3)
        var c=try career();c.cash=50_000_000;let b=c.groundBuildings.first{$0.kind=="Stand"}!
        XCTAssertTrue(c.standQuote(b.id,capacity:b.capacity,seated:true,covered:false,boxes:0) != nil)
        XCTAssertTrue(c.developStand(b.id,capacity:b.capacity,seated:true,covered:false,boxes:0));c.week=20;c.progressGround()
        XCTAssertEqual(c.groundBuildings.first{$0.id==b.id}?.specification?.covered,false)
        XCTAssertTrue(c.developStand(b.id,capacity:15000,seated:true,covered:true,boxes:2));c.week=50;c.progressGround()
        XCTAssertEqual(c.groundBuildings.first{$0.id==b.id}?.capacity,15000);XCTAssertEqual(c.groundBuildings.first{$0.id==b.id}?.specification?.covered,true)
    }
    func testTeletextScorersAndForm() throws {
        var c=try career();let a=c.squad[0],b=c.squad[1]
        XCTAssertTrue(c.topScorers(league:c.club.league).isEmpty)
        c.states[a.id]!.goals=3;c.states[b.id]!.goals=5
        XCTAssertEqual(c.topScorers(league:c.club.league).prefix(2).map(\.id),[b.id,a.id])
        XCTAssertTrue(c.topScorers(league:"Not a league").isEmpty)
        let index=c.fixtures.firstIndex{$0.home==c.clubID && $0.competition==nil}!
        c.fixtures[index].homeGoals=2;c.fixtures[index].awayGoals=0
        XCTAssertEqual(c.recentForm(clubID:c.clubID),"W")
        let data=try JSONEncoder().encode(c),loaded=try JSONDecoder().decode(Career.self,from:data)
        XCTAssertEqual(loaded.topScorers(league:c.club.league).first?.id,b.id)
    }
    func testNamedFormationLibrary() throws {
        var c=try career();let captain=c.lineup[0];c.tactics.captain=captain
        var positions=TacticalPlan.defaults(c.tactics).map(\.point);positions[9]=FieldPoint(80,22);c.tactics.customPositions=positions
        c.tactics.plan=TacticalPlan();c.tactics.plan?.states["Attack zone 1"]=positions.map{TacticalInstruction(point:$0)}
        XCTAssertFalse(c.saveFormation(named:"  "));XCTAssertTrue(c.saveFormation(named:"My attack"))
        c.tactics.customPositions=nil;c.tactics.plan=nil;c.tactics.formation="3-5-2"
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("usm-formations-test.json")
        try SaveStore.save(c,to:url);c=try SaveStore.load(from:url)
        XCTAssertTrue(c.loadFormation(named:"My attack"));XCTAssertEqual(c.tactics.formation,"4-4-2");XCTAssertEqual(c.tactics.customPositions,positions)
        XCTAssertEqual(c.tactics.plan?.states["Attack zone 1"]?.count,11);XCTAssertEqual(c.tactics.captain,captain)
        XCTAssertTrue(c.saveFormation(named:"my attack"));XCTAssertEqual(c.managementState.savedFormations?.count,1)
        c.deleteFormation(named:"my attack");XCTAssertFalse(c.loadFormation(named:"my attack"))
    }
    func testOwnPlayerMarketControls() throws {
        let coach=StaffMember(id:"test",name:"Test",speciality:"Shooting",quality:80,wage:200)
        XCTAssertTrue(coach.trainingEffectiveness(skill:3)>coach.trainingEffectiveness(skill:1));XCTAssertTrue(coach.assignmentLabel.contains("Shooting"))
        var c=try career();c.initializeManagement();let p=c.squad[0],count=c.players.count,cash=c.cash
        c.toggleShortlist(p.id);XCTAssertFalse(c.managementState.shortlist.contains(p.id))
        XCTAssertFalse(c.listPlayer(p.id,askingPrice:-1));XCTAssertTrue(c.listPlayer(p.id,askingPrice:p.value+10000));XCTAssertEqual(c.managementState.listed[p.id],p.value+10000)
        XCTAssertTrue(c.listPlayerForLoan(p.id,weeks:12));XCTAssertNil(c.managementState.listed[p.id]);XCTAssertEqual(c.managementState.loanListed?[p.id],12)
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("usm-market-test.json");try SaveStore.save(c,to:url);c=try SaveStore.load(from:url);XCTAssertEqual(c.managementState.loanListed?[p.id],12)
        let quote=c.fastSaleValue(p.id);XCTAssertTrue(c.fastSell(p.id));XCTAssertEqual(c.cash,cash+quote);XCTAssertEqual(c.players.count,count);XCTAssertFalse(c.lineup.contains(p.id));XCTAssertNil(c.managementState.loanListed?[p.id]);XCTAssertFalse(c.fastSell(p.id))
        let loan=c.squad[0],owner=c.clubID,buyer=c.clubs.first{$0.id != owner && $0.country==c.club.country}!.id
        XCTAssertTrue(c.listPlayerForLoan(loan.id,weeks:4))
        var offer=Negotiation(player:loan,week:c.managementState.elapsed,selling:true,loanWeeks:4);offer.clubID=buyer;offer.stage="Final review";offer.fee=0;c.management!.negotiations.append(offer)
        XCTAssertTrue(c.acceptTransfer(offer.id));XCTAssertEqual(c.players.first{$0.id==loan.id}?.clubID,buyer);XCTAssertNil(c.managementState.loanListed?[loan.id])
        for _ in 0..<4{c.progressManagement()}
        XCTAssertEqual(c.players.first{$0.id==loan.id}?.clubID,owner);XCTAssertFalse(c.managementState.loans.contains{$0.playerID==loan.id})
        // Borrowed players and minimum-size squads cannot be sold.
        let borrowed=c.players.first{$0.clubID != owner}!
        var incoming=Negotiation(player:borrowed,week:c.managementState.elapsed,loanWeeks:4);incoming.stage="Final review";incoming.fee=0;incoming.signingFee=0;c.management!.negotiations.append(incoming)
        XCTAssertTrue(c.acceptTransfer(incoming.id));XCTAssertFalse(c.listPlayer(borrowed.id,askingPrice:100));XCTAssertFalse(c.fastSell(borrowed.id))
        while c.squad.count>16 {let id=c.squad.first{$0.id != borrowed.id}!.id;XCTAssertTrue(c.fastSell(id))}
        XCTAssertFalse(c.fastSell(c.squad.first{$0.id != borrowed.id}!.id))
        try SaveStore.save(c,to:url);_=try SaveStore.load(from:url)
    }
    func testPlayerAgesAndYouthRollover() throws {
        var c=try career()
        let beckham=try XCTUnwrap(c.players.first{$0.name=="David Beckham"})
        XCTAssertEqual(beckham.dateOfBirth,"03/05/1975")
        let survivor=try XCTUnwrap(c.players.first{$0.name=="Michael Owen"})
        let oldAge=survivor.age(season:c.season)
        let retiring=c.lineup[0],ri=c.players.firstIndex{$0.id==retiring}!
        c.players[ri].birthYear=1940
        let veteran=c.lineup[1],vi=c.players.firstIndex{$0.id==veteran}!
        c.players[vi].birthYear=1965;c.players[vi].birthMonth=1;c.players[vi].development!.retirementAge=45
        let oldPace=c.players[vi].skills[4]
        // Leave fewer than 20 at two clubs to prove top-up is world-wide and not retirement-only.
        let other=c.clubs.first{$0.id != c.clubID}!.id
        let keep=Set(c.squad.prefix(18).map(\.id)+c.players.filter{$0.clubID==other}.prefix(18).map(\.id))
        let removed=Set(c.players.filter{($0.clubID==c.clubID || $0.clubID==other) && !keep.contains($0.id) && $0.id != veteran && $0.id != retiring}.map(\.id))
        c.players.removeAll{removed.contains($0.id)};for id in removed{c.states.removeValue(forKey:id)}
        c.fixtures=[];c.nextSeason()
        XCTAssertEqual(c.season,2);XCTAssertFalse(c.players.contains{$0.id==retiring})
        XCTAssertEqual(c.players.first{$0.id==survivor.id}?.age(season:2),oldAge.map{$0+1})
        XCTAssertTrue(c.players.first{$0.id==veteran}!.skills[4]<oldPace)
        XCTAssertTrue(c.clubs.allSatisfy{club in c.players.filter{$0.clubID==club.id}.count>=20})
        let youth=c.players.filter{$0.development?.generated==true}
        XCTAssertTrue(!youth.isEmpty);XCTAssertTrue(youth.allSatisfy{(16...18).contains($0.age(season:2) ?? 0)})
        XCTAssertEqual(Set(c.players.map(\.id)).count,c.players.count)
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("usm-youth-test.json")
        try SaveStore.save(c,to:url);let loaded=try SaveStore.load(from:url)
        XCTAssertEqual(loaded.players,c.players)
        // More seasons keep the world populated and identifiers unique.
        for _ in 0..<8 {c.fixtures=[];c.nextSeason()}
        XCTAssertTrue(c.clubs.allSatisfy{club in c.players.filter{$0.clubID==club.id}.count>=20})
        XCTAssertEqual(Set(c.players.map(\.id)).count,c.players.count)
        try SaveStore.save(c,to:url);_=try SaveStore.load(from:url)
    }
    func testCommentaryPacingAndNames() {
        var q=CommentarySchedule();let name=CommentaryClip(path:"bergkamp.wav",name:"dennis bergkamp")
        for speed in [1.5,2,4,8,16] {for event in ["shot","pass","corner","foul","save","penalty"] {XCTAssertFalse(q.allows(event,speed:speed,now:100))};XCTAssertTrue(q.allows("goal",speed:speed,now:100))}
        XCTAssertTrue(q.allows("shot",speed:1,now:0))
        _=q.enqueue("shot",now:0,name:name,phrase:"shot.wav");XCTAssertEqual(q.next(now:0),name)
        XCTAssertFalse(q.enqueue("goal",now:0.2,name:name,phrase:"goal.wav"))
        XCTAssertEqual(q.current,name);XCTAssertEqual(q.pending.map(\.path),["goal.wav"])
        XCTAssertEqual(q.next(now:1)?.path,"goal.wav");_=q.next(now:2)
        XCTAssertFalse(q.allows("shot",speed:1,now:5));XCTAssertTrue(q.allows("shot",speed:1,now:20))
        _=q.enqueue("shot",now:20,name:name,phrase:"shot.wav");_=q.next(now:20)
        XCTAssertTrue(q.changeSpeed(2));XCTAssertNil(q.current);XCTAssertTrue(q.pending.isEmpty)
        _=q.enqueue("goal",now:21,name:name,phrase:"goal.wav");_=q.next(now:21)
        XCTAssertFalse(q.changeSpeed(8));XCTAssertEqual(q.current?.path,"goal.wav")
        var sounds=CommentarySchedule();XCTAssertTrue(sounds.shotSound(speed:1,now:0))
        XCTAssertFalse(sounds.shotSound(speed:1,now:1));XCTAssertFalse(sounds.shotSound(speed:1,now:2));XCTAssertFalse(sounds.shotSound(speed:1,now:3));XCTAssertFalse(sounds.shotSound(speed:2,now:20))
    }
    func testVisibleSetPieceRestarts() throws {
        let c=try career();var m=LiveMatch(career:c,fixture:try XCTUnwrap(c.nextFixture));m.startHalf()
        let taker=m.players.firstIndex{$0.side==0 && $0.slot==10}!,defender=m.players.firstIndex{$0.side==1 && $0.slot==2}!
        m.homeTactics.takers=["Attacking free kick":m.players[taker].id,"Corner":m.players[taker].id]
        m.ball=FieldPoint(82,34);m.awardFoul(offender:defender,victim:taker)
        XCTAssertEqual(m.setPieceRestart?.kind,"free kick");let spot=m.ball
        for _ in 0..<10 {m.step()};XCTAssertEqual(m.ball,spot);XCTAssertNil(m.flight)
        for _ in 0..<25 {m.step()};XCTAssertTrue(m.events.contains{$0.kind=="shot"})
        m.awardCorner(side:0,left:true);XCTAssertEqual(m.setPieceRestart?.taker,m.players[taker].id)
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("usm-setpiece.json")
        var saved=c;saved.activeMatch=m;try SaveStore.save(saved,to:url);let loaded=try SaveStore.load(from:url)
        XCTAssertEqual(loaded.activeMatch?.setPieceRestart?.kind,"left corner")
        for _ in 0..<35 {m.step()};XCTAssertTrue(m.events.contains{$0.kind=="cross"});XCTAssertNil(m.setPieceRestart)
    }
    func testVisiblePaceAndShootingQuality() throws {
        let c=try career(),fixture=try XCTUnwrap(c.nextFixture)
        var reference=LiveMatch(career:c,fixture:fixture);var p=reference.players[0];p.skills[4]=20;let slow=reference.runningSpeed(p,carrying:false);p.skills[4]=90;XCTAssertTrue(reference.runningSpeed(p,carrying:false)>slow*1.7)
        func targets(_ ability:Int)->Int {
            var total=0
            for seed in 1...100 {
                var m=reference;m.rng=RNG(seed:UInt64(seed));m.startHalf()
                for i in m.players.indices {m.players[i].point=FieldPoint(20,3)}
                let i=m.players.firstIndex{$0.side==0 && $0.slot==10}!
                m.players[i].skills[3]=ability;m.players[i].point=FieldPoint(94,34);m.owner=m.players[i].id;m.ball=m.players[i].point;m.holdTime=1
                m.step();if m.flight?.onTarget==true{total+=1}
            }
            return total
        }
        XCTAssertTrue(targets(95)>targets(20)+30)
        reference.finishInstantly();XCTAssertTrue(reference.events.contains{$0.kind=="dribble"})
    }
    func testFluidMovementAndContestedCorners() throws {
        let c=try career();var m=LiveMatch(career:c,fixture:try XCTUnwrap(c.nextFixture));m.startHalf()
        m.activeSetPlay=nil;m.ball=FieldPoint(78,57)
        let midfielder=try XCTUnwrap(m.players.first{$0.side==0 && $0.role=="MID" && $0.onPitch})
        let base=m.formationPoint(slot:midfielder.slot,side:0,withBall:true)
        let run=m.openPlayTarget(for:midfielder,base:base,owningSide:0)
        XCTAssertTrue(run.x>base.x);XCTAssertNotEqual(run.y,base.y)

        m.awardCorner(side:0,left:true)
        for _ in 0..<25 {m.step()}
        let attackers=m.players.filter{$0.side==0 && $0.onPitch && $0.slot != 0 && $0.id != m.setPieceRestart?.taker}
        let defenders=m.players.filter{$0.side==1 && $0.onPitch && $0.slot != 0}
        XCTAssertTrue(Set(attackers.map{Int($0.point.y.rounded())}).count>4)
        // A corner should be a contested box: at least one defender is goal-side of a runner.
        XCTAssertTrue(attackers.contains{a in defenders.contains{d in d.point.distance(to:a.point)<5 && d.point.x>a.point.x}})
    }
    func testLegacyBirthDateRecovery() throws {
        var c=try career();let i=c.players.firstIndex{$0.name=="David Beckham"}!
        c.players[i].birthYear=nil;c.players[i].birthMonth=nil;c.players[i].birthDay=nil;c.players[i].development=nil
        c.initializePlayerDevelopment();XCTAssertTrue(c.players[i].development?.estimatedBirthYear==true)
        c.restorePlayerBirthDates(from:try database())
        XCTAssertEqual(c.players[i].dateOfBirth,"03/05/1975");XCTAssertFalse(c.players[i].development?.estimatedBirthDate ?? true)
        let snapshot=c.players;c.restorePlayerBirthDates(from:try database());XCTAssertEqual(snapshot,c.players)
        c.players[i].name="Different player";c.players[i].birthYear=nil;c.players[i].development=nil
        c.initializePlayerDevelopment();let estimated=c.players[i].dateOfBirth
        c.restorePlayerBirthDates(from:try database());XCTAssertEqual(c.players[i].dateOfBirth,estimated)
    }
    func testPotentialAndExperience() throws {
        var c=try career()
        let a=0,b=1,old=2
        for i in [a,b,old] {c.players[i].skills=Array(repeating:40,count:9);c.players[i].birthYear=i==old ? 1963:1980;c.players[i].birthMonth=1;c.players[i].development!.ceilings=Array(repeating:i==b ? 48:96,count:9);c.players[i].development!.aptitude=i==b ? 0.6:1.5;c.players[i].development!.progress=Array(repeating:0,count:9)}
        let value=c.players[a].value
        for _ in 0..<80 {for i in [a,b,old]{c.developPlayer(at:i,skill:3,effort:0.8)}}
        XCTAssertTrue(c.players[a].skills[3]>=92);XCTAssertTrue(c.players[b].skills[3]<=48)
        XCTAssertTrue(c.players[old].skills[3]<c.players[a].skills[3]);XCTAssertTrue(c.players[a].value>value || c.players[a].position != "FWD")
        let id=c.players[3].id;c.players[3].birthYear=1980;c.players[3].birthMonth=1
        let before=c.players[3].skills.reduce(0,+)
        for _ in 0..<50 {c.developFromMatch([id])}
        XCTAssertTrue(c.players[3].skills.reduce(0,+)>before)
        let snapshot=c.players;c.initializePlayerDevelopment();XCTAssertEqual(c.players.map{$0.development?.ceilings},snapshot.map{$0.development?.ceilings})
    }
    func testSquadSwapAndBenchPersistence() throws {
        var c=try career();let original=c.orderedSquad.map(\.id)
        XCTAssertTrue(c.swapSquadPlayers(original[1],original[5]))
        XCTAssertEqual(c.lineup[1],original[5]);XCTAssertEqual(c.lineup[5],original[1])
        XCTAssertTrue(c.swapSquadPlayers(original[10],original[12]))
        XCTAssertEqual(c.lineup[10],original[12]);XCTAssertEqual(c.orderedSquad[12].id,original[10])
        let order=c.orderedSquad.map(\.id)
        XCTAssertTrue(c.swapSquadPlayers(order[11],order[19]))
        let loaded=try JSONDecoder().decode(Career.self,from:JSONEncoder().encode(c))
        XCTAssertEqual(loaded.orderedSquad.map(\.id),c.orderedSquad.map(\.id))
        let m=LiveMatch(career:loaded,fixture:try XCTUnwrap(loaded.nextFixture))
        XCTAssertTrue(m.bench.contains{$0.id==order[19]})
        XCTAssertFalse(m.bench.contains{$0.id==order[11]})
        c.states[order[20]]!.injuryWeeks=2
        XCTAssertFalse(c.swapSquadPlayers(c.lineup[1],order[20]))
        XCTAssertEqual(Set(c.lineup).count,11)
    }
    func testRecoveredDatabase() throws {
        let d=try database()
        XCTAssertEqual(d.clubs.count,412);XCTAssertEqual(d.players.count,9747)
        XCTAssertEqual(Set(d.clubs.map(\.country)).count,7)
        let bergkamp=try XCTUnwrap(d.players.first{$0.name=="Dennis Bergkamp"})
        XCTAssertEqual(bergkamp.clubID,"N-0");XCTAssertEqual(bergkamp.skills[3],96)
        XCTAssertEqual(d.players.first{$0.name=="David Beckham"}?.clubID,"N-60")
        XCTAssertEqual(d.players.first{$0.name=="Patrick Vieira"}?.clubID,"N-0")
        XCTAssertEqual(d.clubs.first{$0.id=="N-0"}?.stadium,"Highbury")
        XCTAssertFalse(d.players.contains{$0.name=="Harry Kane"})
        XCTAssertTrue(d.players.allSatisfy{$0.skills.count==9 && $0.skills.allSatisfy{0...100 ~= $0}})
    }
    func testScheduleEveryPairHomeAndAway() throws {
        let c=try career();let ids=Set(c.clubs.filter{$0.league==c.club.league}.map(\.id))
        let fs=c.fixtures.filter{ids.contains($0.home)}
        XCTAssertEqual(fs.count,ids.count*(ids.count-1))
        XCTAssertEqual(Set(fs.map(\.id)).count,fs.count)
        for id in ids {
            XCTAssertEqual(fs.filter{$0.home==id}.count,ids.count-1)
            XCTAssertEqual(fs.filter{$0.away==id}.count,ids.count-1)
        }
        for round in Set(fs.map(\.round)) { let day=fs.filter{$0.round==round};XCTAssertEqual(Set(day.flatMap{[$0.home,$0.away]}).count,day.count*2) }
    }
    func testOddSizedLeagueHasByesWithoutDuplicateMatches() throws {
        let clubs=Array(try database().clubs.filter{$0.country=="England" && $0.division==0}.prefix(5))
        let fixtures=Career.schedule(clubs:clubs,season:1)
        XCTAssertEqual(fixtures.count,20)
        for round in 0..<10 { XCTAssertEqual(fixtures.filter{$0.round==round}.count,2) }
    }
    func testLineupExcludesInjuredAndHasKeeper() throws {
        var c=try career();let id=c.lineup[0];c.states[id]!.injuryWeeks=3;c.autoSelect()
        XCTAssertFalse(c.lineup.contains(id));XCTAssertEqual(Set(c.lineup).count,11)
        XCTAssertEqual(c.players.first{$0.id==c.lineup[0]}?.position,"GK")
    }
    func testDeterministicSimulationAndAccounting() throws {
        var a=try career(),b=try career();let initial=a.cash
        a.advanceWeek();b.advanceWeek()
        XCTAssertEqual(a.fixtures,b.fixtures);XCTAssertEqual(a.lastMatch,b.lastMatch)
        XCTAssertEqual(a.cash,initial+a.ledger.reduce(0){$0+$1.amount})
        XCTAssertEqual(a.table().reduce(0){$0+$1.scored},a.table().reduce(0){$0+$1.conceded})
        XCTAssertEqual(a.week,1);XCTAssertTrue(a.fixtures.filter{$0.round==0}.allSatisfy(\.played))
    }
    func testTransferIsDelayedAndConservesPlayers() throws {
        var c=try career();let p=try XCTUnwrap(c.players.first{$0.clubID != c.clubID && $0.value<c.cash})
        let oldCount=c.players.count
        XCTAssertTrue(c.bid(playerID:p.id,fee:p.value,wage:p.wage))
        XCTAssertFalse(c.bid(playerID:p.id,fee:p.value,wage:p.wage))
        XCTAssertNotEqual(c.players.first{$0.id==p.id}!.clubID,c.clubID)
        c.advanceWeek();XCTAssertEqual(c.players.first{$0.id==p.id}!.clubID,c.clubID)
        XCTAssertEqual(c.players.count,oldCount);XCTAssertTrue(c.offers.isEmpty)
    }
    func testLowOfferRejected() throws {
        var c=try career();let p=try XCTUnwrap(c.players.first{$0.clubID != c.clubID})
        XCTAssertTrue(c.bid(playerID:p.id,fee:1,wage:1));c.advanceWeek()
        XCTAssertNotEqual(c.players.first{$0.id==p.id}!.clubID,c.clubID)
    }
    func testConstructionAndLoanFreeAccounting() throws {
        var c=try career();let cap=c.capacity,initial=c.cash
        XCTAssertTrue(c.build("Stand"));XCTAssertEqual(c.cash,initial-1_500_000)
        XCTAssertFalse(c.build("Shop"));XCTAssertFalse(c.build("Unknown"))
        for _ in 0..<3 { c.advanceWeek() };XCTAssertEqual(c.capacity,cap)
        c.advanceWeek();XCTAssertEqual(c.capacity,cap+5000);XCTAssertNil(c.construction)
    }
    func testSaveRoundTripPreservesRNGAndPendingOffer() throws {
        var a=try career();a.advanceWeek()
        let p=try XCTUnwrap(a.players.first{$0.clubID != a.clubID && $0.value<a.cash})
        _=a.bid(playerID:p.id,fee:p.value,wage:p.wage)
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".json")
        defer { try? FileManager.default.removeItem(at:url) }
        try SaveStore.save(a,to:url);var b=try SaveStore.load(from:url)
        XCTAssertEqual(a.offers.count,b.offers.count);a.advanceWeek();b.advanceWeek()
        XCTAssertEqual(a.fixtures,b.fixtures);XCTAssertEqual(a.cash,b.cash);XCTAssertEqual(a.lineup,b.lineup)
    }
    func testInvalidSaveRejected() throws {
        var a=try career();a.lineup=["missing-player"]
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".json")
        defer { try? FileManager.default.removeItem(at:url) }
        try SaveStore.save(a,to:url);XCTAssertThrowsError(try SaveStore.load(from:url))
    }
    func testFullSeasonAndPromotion() throws {
        var c=try career();let counts=Dictionary(grouping:c.clubs,by:\.league).mapValues(\.count)
        let maxRound=try XCTUnwrap(c.fixtures.map(\.round).max())
        for _ in 0...maxRound { c.advanceWeek() }
        XCTAssertTrue(c.seasonFinished)
        let table=c.table();XCTAssertTrue(table.allSatisfy{$0.played==(table.count-1)*2})
        let winner=table[0].id,oldBottom=Set(table.suffix(2).map(\.id))
        c.cash = 10_000_000
        XCTAssertTrue(c.build("Stand"))
        c.nextSeason()
        XCTAssertEqual(c.construction?.dueWeek,4)
        XCTAssertEqual(c.season,2);XCTAssertEqual(c.week,0);XCTAssertFalse(c.seasonFinished)
        XCTAssertEqual(c.clubs.first{$0.id==winner}?.division,0)
        XCTAssertTrue(c.clubs.filter{oldBottom.contains($0.id)}.allSatisfy{$0.division==1})
        XCTAssertEqual(Dictionary(grouping:c.clubs,by:\.league).mapValues(\.count),counts)
        XCTAssertEqual(c.history.count,1)
    }
    func testTacticsInfluenceResults() throws {
        var a=try career(),b=try career();a.tactics.mentality="Attacking";b.tactics.mentality="Defensive"
        a.advanceWeek();b.advanceWeek()
        XCTAssertNotEqual(a.lastMatch,b.lastMatch)
    }
    func testLiveMatchPossessionAndHalfTime() throws {
        let c=try career();let f=try XCTUnwrap(c.nextFixture)
        var m=LiveMatch(career:c,fixture:f)
        XCTAssertEqual(m.homeGoals,0);XCTAssertEqual(m.awayGoals,0)
        m.step();XCTAssertEqual(m.elapsed,0)
        m.startHalf()
        var crossed=false,flightSeen=false
        for _ in 0..<3400 {
            m.step()
            if m.flight != nil {flightSeen=true}
            if m.players.contains(where:{$0.onPitch && $0.side==0 && $0.point.x>60}) {crossed=true}
        }
        XCTAssertEqual(m.phase,.halfTime);XCTAssertEqual(m.elapsed,2700)
        XCTAssertTrue(flightSeen);XCTAssertTrue(crossed)
        XCTAssertTrue(m.homePasses+m.awayPasses>20)
        let frozen=m.elapsed;m.step();XCTAssertEqual(m.elapsed,frozen)
        m.startHalf();m.finishInstantly()
        XCTAssertEqual(m.phase,.fullTime);XCTAssertEqual(m.elapsed,5400)
        XCTAssertTrue(m.homeShots+m.awayShots>0)
        print("LIVE: \(m.homeGoals)-\(m.awayGoals), shots \(m.homeShots)/\(m.awayShots), passes \(m.homePasses)/\(m.awayPasses)")
    }
    func testLiveSubstitutionsAndTactics() throws {
        let c=try career();var m=LiveMatch(career:c,fixture:try XCTUnwrap(c.nextFixture));m.startHalf()
        for _ in 0..<100 {m.step()}
        XCTAssertEqual(m.bench.count,7)
        XCTAssertEqual(m.managedPlayers.filter{$0.role=="GK"}.count,1)
        XCTAssertTrue(m.bench.contains{$0.role=="FWD"})
        let before=m.managedPlayers[4],sub=m.bench[1]
        XCTAssertTrue(m.substitute(out:before.id,in:sub.id))
        XCTAssertFalse(m.managedPlayers.contains{$0.id==before.id})
        XCTAssertTrue(m.managedPlayers.contains{$0.id==sub.id})
        XCTAssertFalse(m.substitute(out:sub.id,in:before.id))
        XCTAssertEqual(m.substitutionsUsed,1)
        var t=Tactics();t.formation="3-5-2";t.mentality="Attacking"
        m.changeTactics(t);XCTAssertEqual(m.managedTactics,t)
        XCTAssertEqual(Set(m.activePlayers.map(\.id)).count,22)
    }
    func testLiveSaveResumeAndSpeedParity() throws {
        var c=try career();var match=LiveMatch(career:c,fixture:try XCTUnwrap(c.nextFixture));match.startHalf()
        for _ in 0..<200 {match.step()};c.activeMatch=match
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".json")
        defer {try? FileManager.default.removeItem(at:url)}
        try SaveStore.save(c,to:url);var restored=try XCTUnwrap(try SaveStore.load(from:url).activeMatch)
        for _ in 0..<100 {match.step()}
        for _ in 0..<10 {for _ in 0..<10 {restored.step()}}
        XCTAssertEqual(match.ball,restored.ball);XCTAssertEqual(match.players,restored.players)
        XCTAssertEqual(match.events,restored.events);XCTAssertEqual(match.elapsed,restored.elapsed)
    }

    func testGroundConstructionPlacementAndPersistence() throws {
        var c=try career();let initial=c.cash,shops=c.shops
        let empty=try XCTUnwrap(GroundPlot.all.first{p in !p.stand && !c.groundBuildings.contains{$0.plotID==p.id}})
        XCTAssertTrue(c.placeBuilding(kind:"Shop",plotID:empty.id))
        XCTAssertEqual(c.cash,initial-400000)
        XCTAssertFalse(c.placeBuilding(kind:"Shop",plotID:empty.id))
        XCTAssertFalse(c.placeBuilding(kind:"Stand",plotID:"plot-0-1"))
        let building=try XCTUnwrap(c.groundBuildings.first{$0.plotID==empty.id})
        XCTAssertTrue(building.isBuilding);XCTAssertEqual(c.shops,shops)
        c.week += 3;c.progressGround()
        XCTAssertEqual(c.shops,shops+1);XCTAssertFalse(c.groundBuildings.first{$0.id==building.id}!.isBuilding)
        c.rotateBuilding(building.id);XCTAssertEqual(c.groundBuildings.first{$0.id==building.id}!.rotation,1)
        let destination=try XCTUnwrap(GroundPlot.all.first{p in !p.stand && !c.groundBuildings.contains{$0.plotID==p.id}})
        XCTAssertTrue(c.moveBuilding(building.id,to:destination.id))
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".json")
        defer {try? FileManager.default.removeItem(at:url)}
        try SaveStore.save(c,to:url);let saved=try SaveStore.load(from:url)
        XCTAssertEqual(c.groundBuildings,saved.groundBuildings)
        XCTAssertTrue(c.demolishBuilding(building.id));XCTAssertEqual(c.shops,shops)
    }
    func testStandUpgradeAndDemolition() throws {
        var c=try career();let capacity=c.capacity
        XCTAssertTrue(c.upgradeBuilding("north"));XCTAssertFalse(c.upgradeBuilding("north"))
        c.week += 4;c.progressGround();XCTAssertEqual(c.capacity,capacity+5000)
        XCTAssertEqual(c.groundBuildings.first{$0.id=="north"}!.level,2)
        let removedCapacity=c.groundBuildings.first{$0.id=="north"}!.capacity
        XCTAssertTrue(c.demolishBuilding("north"));XCTAssertEqual(c.capacity,capacity+5000-removedCapacity)
        XCTAssertTrue(c.placeBuilding(kind:"Stand",plotID:"north"))
        XCTAssertFalse(c.demolishBuilding("manager"))
    }

    func testUnfinishedMatchCannotCommitAndMidMatchChangesMatter() throws {
        var c=try career();var match=LiveMatch(career:c,fixture:try XCTUnwrap(c.nextFixture));match.startHalf()
        for _ in 0..<500 {match.step()}
        c.activeMatch=match;let cash=c.cash
        c.advanceWeek();XCTAssertEqual(c.week,0);XCTAssertEqual(c.cash,cash)
        c.advanceWeek(completedMatch:match);XCTAssertEqual(c.week,0)
        var changed=match;var tactics=changed.managedTactics;tactics.formation="3-5-2";tactics.mentality="Attacking";changed.changeTactics(tactics)
        for _ in 0..<300 {match.step();changed.step()}
        XCTAssertNotEqual(match.players,changed.players)
        XCTAssertEqual(match.elapsed,changed.elapsed)
        match.finishInstantly();c.advanceWeek(completedMatch:match)
        XCTAssertEqual(c.week,1);XCTAssertNil(c.activeMatch)
        XCTAssertEqual(c.lastMatch?.homeGoals,match.homeGoals);XCTAssertEqual(c.lastMatch?.awayGoals,match.awayGoals)
    }

}

extension CareerTests {
    func testNegotiationStagesAndFinalVeto() throws {
        var c=try career();c.cash=100_000_000
        let p=try XCTUnwrap(c.players.first{$0.clubID != c.clubID})
        XCTAssertTrue(c.enquire(p.id));XCTAssertFalse(c.enquire(p.id));let id=c.management!.negotiations[0].id
        c.progressManagement();XCTAssertEqual(c.management!.negotiations[0].stage,"Club asking price")
        XCTAssertTrue(c.submitTerms(id,fee:p.value,wage:p.wage,bonus:p.wage*4,years:3))
        c.progressManagement();XCTAssertEqual(c.management!.negotiations[0].stage,"Player terms")
        XCTAssertTrue(c.submitTerms(id,fee:p.value,wage:p.wage,bonus:p.wage*4,years:3))
        c.progressManagement();XCTAssertEqual(c.management!.negotiations[0].stage,"Final review")
        XCTAssertEqual(c.players.first{$0.id==p.id}?.clubID,p.clubID)
        let cash=c.cash;XCTAssertTrue(c.acceptTransfer(id));XCTAssertEqual(c.cash,cash-p.value-p.wage*4)
        XCTAssertFalse(c.acceptTransfer(id));XCTAssertEqual(c.players.first{$0.id==p.id}?.clubID,c.clubID)
        let loaded=try JSONDecoder().decode(Career.self,from:JSONEncoder().encode(c));XCTAssertEqual(loaded.management?.negotiations[0].stage,"Completed")
    }
    func testStaffTrainingScoutingAndCommercial() throws {
        var c=try career();c.initializeManagement();let staff=c.management!.staff[0]
        let cash=c.cash;XCTAssertTrue(c.hireStaff(staff.id));XCTAssertFalse(c.hireStaff(staff.id));XCTAssertEqual(c.cash,cash-staff.wage*4)
        c.setTraining(slot:10,activity:"Passing");XCTAssertEqual(c.management!.timetable[10],"Match")
        c.setTraining(slot:0,activity:"Free time");XCTAssertEqual(c.management!.timetable[0],"Free time")
        XCTAssertTrue(c.hireStaff("staff-5"));let p=try XCTUnwrap(c.players.first{$0.clubID != c.clubID})
        XCTAssertTrue(c.scoutPlayer(p.id));c.progressManagement();XCTAssertEqual(c.management!.scouts[0].text,"Assignment in progress")
        c.progressManagement();XCTAssertNotEqual(c.management!.scouts[0].text,"Assignment in progress")
        XCTAssertTrue(c.acceptDeal("s1"));XCTAssertFalse(c.acceptDeal("s2"));let before=c.cash;c.progressManagement();XCTAssertTrue(c.cash>before)
        XCTAssertTrue(c.bankDeposit(10000));XCTAssertFalse(c.bankWithdraw(10001));XCTAssertTrue(c.bankWithdraw(10000))
        let count=c.players.count;c.retailMatchday(attendance:20000);XCTAssertTrue(c.management!.products.contains{$0.sold>0});XCTAssertEqual(c.players.count,count)
    }
}

extension CareerTests {
    func testStandClosureAndSpecification() throws {
        var c=try career();c.cash=20_000_000
        let b=try XCTUnwrap(c.groundBuildings.first{$0.kind=="Stand"});let old=c.capacity
        XCTAssertNil(c.standQuote(b.id,capacity:b.capacity-100,seated:true,covered:true,boxes:0))
        XCTAssertTrue(c.developStand(b.id,capacity:b.capacity+3000,seated:true,covered:true,boxes:2))
        XCTAssertEqual(c.availableCapacity,old-b.capacity)
        XCTAssertFalse(c.developStand(b.id,capacity:b.capacity+3000,seated:true,covered:true,boxes:2))
        c.week=10;c.progressGround();XCTAssertEqual(c.capacity,old+3000);XCTAssertEqual(c.availableCapacity,c.capacity)
        XCTAssertEqual(c.groundBuildings.first{$0.id==b.id}?.specification?.boxes,2)
    }
    func testCustomTacticsAndMigration() throws {
        var c=try career();var positions=TacticalPlan.defaults(c.tactics).map(\.point);positions[1]=FieldPoint(31,11);c.tactics.customPositions=positions
        var m=LiveMatch(career:c,fixture:try XCTUnwrap(c.nextFixture));m.startHalf()
        let expected=m.direction(m.managedSide)>0 ? 31.0:74.0
        XCTAssertEqual(m.formationPoint(slot:1,side:m.managedSide,withBall:true).x,expected)
        c.initializeManagement();c.initializeWorld()
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("usm-migration-\(UUID()).json")
        try SaveStore.save(c,to:url);let loaded=try SaveStore.load(from:url);XCTAssertEqual(loaded.tactics.customPositions,positions);try? FileManager.default.removeItem(at:url)
    }
}

extension CareerTests {
    func testCupCalendarAndTrophies() throws {
        var c=try career();let leagueCount=c.fixtures.count;c.enableDomesticCups()
        XCTAssertEqual(c.cups?.count,7);XCTAssertEqual(c.fixtures.filter{$0.competition==nil}.count,leagueCount)
        for _ in 0..<10 {
            for i in c.fixtures.indices where c.fixtures[i].competition != nil && !c.fixtures[i].played {c.fixtures[i].homeGoals=1;c.fixtures[i].awayGoals=0;c.fixtures[i].qualified=c.fixtures[i].home}
            c.week+=4;c.progressCups()
        }
        XCTAssertEqual(c.trophies?.count,7);XCTAssertTrue(c.cups!.allSatisfy{$0.winner != nil})
        XCTAssertTrue(c.table().allSatisfy{$0.played==0})
        let original=c.fixtures.count;let opponent=c.clubs.first{$0.id != c.clubID}!.id
        XCTAssertTrue(c.arrangeFriendly(opponent:opponent));XCTAssertEqual(c.fixtures.count,original+1)
    }
    func testReplayCardsAndQueuedChanges() throws {
        let c=try career();var m=LiveMatch(career:c,fixture:try XCTUnwrap(c.nextFixture));m.startHalf()
        let outgoing=m.managedPlayers[1].id,incoming=m.bench[0].id
        XCTAssertTrue(m.requestSubstitution(out:outgoing,in:incoming));XCTAssertEqual(m.substitutionsUsed,0)
        m.applyPendingSubstitutions();XCTAssertEqual(m.substitutionsUsed,1)
        for _ in 0..<100{m.step()};XCTAssertTrue((m.replayFrames?.count ?? 0)>2)
        XCTAssertEqual(m.replayFrames?.first?.points.count,22)
        m.homeGoals=1;m.awayGoals=1;m.penaltyShootout();XCTAssertNotEqual(m.homePenalties,m.awayPenalties)
        let encoded=try JSONEncoder().encode(m);let copy=try JSONDecoder().decode(LiveMatch.self,from:encoded);XCTAssertEqual(copy.replayFrames?.count,m.replayFrames?.count)
    }
}

extension CareerTests {
    func testTransferClausesAndFinance() throws {
        var c=try career();c.cash=100_000_000
        let player=c.players.first{$0.clubID != c.clubID}!
        XCTAssertTrue(c.enquire(player.id));c.progressManagement();let id=c.management!.negotiations[0].id
        let swap=c.squad.last!;var bonuses=ContractBonuses();bonuses.win=100;bonuses.goal=50
        c.updateTransferExtras(id,appearanceFee:500000,appearanceCount:1,swap:swap.id,bonuses:bonuses)
        XCTAssertTrue(c.submitTerms(id,fee:player.value,wage:player.wage,bonus:player.wage*4,years:3));c.progressManagement()
        XCTAssertTrue(c.submitTerms(id,fee:player.value,wage:player.wage,bonus:player.wage*4,years:3));c.progressManagement()
        let count=c.players.count;XCTAssertTrue(c.acceptTransfer(id));XCTAssertEqual(c.players.count,count)
        XCTAssertEqual(c.players.first{$0.id==swap.id}?.clubID,player.clubID);XCTAssertEqual(c.management?.obligations?.first?.fee,500000)
        XCTAssertTrue(c.arrangeOverdraft());XCTAssertFalse(c.arrangeOverdraft())
        c.confidence=70;XCTAssertTrue(c.floatCompany());XCTAssertFalse(c.floatCompany())
        XCTAssertEqual(c.players.first{$0.name=="David Beckham"}?.birthYear,1975)
    }
    func testNewStateSaveValidation() throws {
        var c=try career();c.initializeManagement();c.management!.assignments[c.lineup[0]]=TrainingAssignment(coachID:"staff-0",skill:99)
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("usm-invalid-management-\(UUID()).json")
        try SaveStore.save(c,to:url);XCTAssertThrowsError(try SaveStore.load(from:url));try? FileManager.default.removeItem(at:url)
        c=try career()
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(c)) as! [String:Any]
        for field in ["management","world","finance","cups","trophies"] {json.removeValue(forKey:field)}
        try JSONSerialization.data(withJSONObject:json).write(to:url)
        let loaded=try SaveStore.load(from:url);XCTAssertNil(loaded.management);XCTAssertEqual(loaded.lineup,c.lineup);try? FileManager.default.removeItem(at:url)
    }
}

extension CareerTests {
    func testCompleteCupCareer() throws {
        var c=try career();c.enableDomesticCups();c.cash=100_000_000
        var steps=0
        while !c.seasonFinished && steps<100 {c.advanceWeek();steps+=1}
        XCTAssertTrue(c.seasonFinished);XCTAssertEqual(c.trophies?.count,7)
        XCTAssertEqual(c.table().first{$0.id==c.clubID}?.played,38)
        XCTAssertEqual(Set(c.players.map(\.id)).count,c.players.count)
        c.nextSeason();XCTAssertEqual(c.season,2);XCTAssertEqual(c.cups?.count,7);XCTAssertFalse(c.seasonFinished)
    }
    func testLegacyTrainingMigrationAndDiscipline() throws {
        var c=try career();c.ticketPrice=31;c.coachingLevel=2;c.training="Finishing";c.individualTraining=[c.lineup[0]:"Keeping"]
        c.initializeManagement();XCTAssertEqual(c.management?.tickets["Seats"],31);XCTAssertEqual(c.management?.staff.filter{$0.employed}.count,2)
        XCTAssertEqual(c.management?.timetable[0],"Attacking");XCTAssertEqual(c.management?.assignments[c.lineup[0]]?.skill,0)
        let suspended=c.lineup[1];c.states[suspended]?.suspendedMatches=2;c.autoSelect();XCTAssertFalse(c.lineup.contains(suspended))
        let m=LiveMatch(career:c,fixture:try XCTUnwrap(c.nextFixture));XCTAssertFalse(m.players.contains{$0.id==suspended})
    }
}
