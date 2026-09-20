import Foundation

extension Career {
    public mutating func advanceWeek(completedMatch: LiveMatch? = nil) {
        guard !seasonFinished else { return }
        if activeMatch != nil && completedMatch == nil {return}
        if let completedMatch=completedMatch,!completedMatch.isFinished {return}
        accountingWeek=week
        let suspendedBefore=states.filter{($0.value.suspendedMatches ?? 0)>0}.map(\.key)
        var playedClubs=Set<String>()
        let rosters=Dictionary(grouping:players,by:\.clubID)
        // Recover before kickoff; injured players never take part in this week's match.
        for p in players {
            states[p.id]!.fitness=min(100,states[p.id]!.fitness+12)
            if states[p.id]!.injuryWeeks>0 { states[p.id]!.injuryWeeks -= 1 }
        }
        if lineup.count != 11 || lineup.contains(where:{states[$0]?.injuryWeeks != 0 || (states[$0]?.suspendedMatches ?? 0)>0}) { autoSelect() }
        let invalid=lineup.contains { id in !squad.contains { $0.id==id } }
        if invalid { autoSelect() }
        lastMatch=nil
        for index in fixtures.indices where fixtures[index].round == week && !fixtures[index].played {
            let f=fixtures[index]
            playedClubs.insert(f.home);playedClubs.insert(f.away)
            let homeSquad=(rosters[f.home] ?? []).filter{(states[$0.id]?.suspendedMatches ?? 0)==0 && states[$0.id]?.injuryWeeks==0}
            let awaySquad=(rosters[f.away] ?? []).filter{(states[$0.id]?.suspendedMatches ?? 0)==0 && states[$0.id]?.injuryWeeks==0}
            let own=f.home==clubID || f.away==clubID
            let h=teamStrength(homeSquad,isManaged:f.home==clubID)
            let a=teamStrength(awaySquad,isManaged:f.away==clubID)
            var report: MatchReport
            if own {
                var match: LiveMatch
                if let completed=completedMatch, completed.fixtureID==f.id, completed.isFinished { match=completed }
                else { match=LiveMatch(career:self,fixture:f);match.finishInstantly() }
                report=match.report();rng=match.rng
                developFromMatch(Set(match.players.filter{$0.onPitch || $0.used}.map(\.id)))
                for (id,cards) in match.yellowCards ?? [:] {
                    let old=states[id]?.yellowCards ?? 0;states[id]?.yellowCards=old+cards
                    if cards>=2 {states[id]?.suspendedMatches=3}
                    else if (old+cards)/5>old/5 {states[id]?.suspendedMatches=1}
                }
                for event in match.events where event.kind=="red" {
                    if let id=event.playerID {let ban=max(3,states[id]?.suspendedMatches ?? 0);states[id]?.suspendedMatches=ban}
                }
                for event in match.events where event.kind=="goal" {
                    if let id=event.playerID {states[id]?.goals += 1}
                }
                if own {payAppearanceAndMatchBonuses(match);lineup=match.managedPlayers.map(\.id)
                if lineup.count<11 {autoSelect()}
                tactics=match.managedTactics}
            } else {
                report=simulate(f,h:h,a:a,homeSquad:homeSquad,awaySquad:awaySquad)
                developFromMatch(Set((Array(homeSquad.filter{states[$0.id]?.injuryWeeks==0}.sorted{$0.rating>$1.rating}.prefix(11))+Array(awaySquad.filter{states[$0.id]?.injuryWeeks==0}.sorted{$0.rating>$1.rating}.prefix(11))).map(\.id)))
                if f.competition != nil && f.competition != "Friendly" && report.homeGoals==report.awayGoals {let h=rng.int(2...5);report.homePenalties=h;report.awayPenalties=rng.unit()<0.5 ? h+1:h-1}
            }
            fixtures[index].homeGoals=report.homeGoals;fixtures[index].awayGoals=report.awayGoals
            if f.competition != nil && f.competition != "Friendly" {fixtures[index].qualified=report.homeGoals==report.awayGoals ? ((report.homePenalties ?? 0)>(report.awayPenalties ?? 0) ? f.home:f.away):(report.homeGoals>report.awayGoals ? f.home:f.away)}
            if own {
                lastMatch=report
                let gf=f.home==clubID ? report.homeGoals:report.awayGoals,ga=f.home==clubID ? report.awayGoals:report.homeGoals
                if gf>ga,let bonus=tactics.winBonus,bonus>0 {transact("Match win bonuses",-bonus*lineup.count)}
                confidence=min(100,max(0,confidence+(gf>ga ? 3:(gf==ga ? 0:-3))))
                post("MATCH REPORT","\(name(f.home)) \(report.homeGoals) – \(report.awayGoals) \(name(f.away))","\(report.attendance.formatted()) supporters watched the match. Board confidence: \(confidence)%.")
                for id in lineup {
                    states[id]!.fitness=max(25,states[id]!.fitness-(tactics.mentality=="Attacking" ? 25:20))
                    states[id]!.morale=min(100,max(20,states[id]!.morale+(gf>ga ? 5:-2)))
                    let risk=tactics.tackling=="Hard" ? 0.055:0.025
                    if rng.unit()<risk {
                        states[id]!.injuryWeeks=rng.int(1...4)
                        post("MEDICAL","\(players.first{$0.id==id}!.name) injured","Unavailable for \(states[id]!.injuryWeeks) weeks. Your assistant will replace unavailable players before kickoff.")
                    }
                }
                if f.home==clubID {
                    collectGate(report,fixture:f)
                    retailMatchday(attendance:report.attendance)
                }
            }
        }
        for id in suspendedBefore where players.first(where:{$0.id==id}).map({playedClubs.contains($0.clubID)}) == true {let remaining=states[id]?.suspendedMatches ?? 0;states[id]?.suspendedMatches=max(0,remaining-1)}
        activeMatch=nil
        week += 1
        transact("Weekly sponsorship",sponsorship)
        transact("Player wages",-wageBill)
        transact("Stadium & staff",-(capacity*2+facilities*12_000+shops*4_000))
        if debt>0 { transact("Loan interest",-debt/1000) }
        progressManagement()
        progressFinance()
        progressClubWorld()
        progressCups()
        resolveOffers()
        progressGround()
        if let project=construction,project.dueWeek<=week {
            if project.kind=="Stand" { capacity += 5_000 }
            if project.kind=="Training" { facilities += 1 }
            if project.kind=="Shop" { shops += 1 }
            construction=nil
            post("DEVELOPMENT","\(project.kind) now open","The development is complete and its benefits are now active.")
        }
        if cash < -financeState.overdraftLimit { confidence=max(0,confidence-5);post("BOARD","Cash reserves exhausted","Sell players, reduce costs or arrange a loan. The board is losing confidence in your financial management.") }
        if seasonFinished { post("SEASON","The final whistle on season \(season)","You finished \((table().firstIndex{$0.id==clubID} ?? 0)+1) in \(club.league). Start the next season to receive prize money and process promotion and relegation.") }
        accountingWeek=nil
    }
    private func teamStrength(_ roster: [Player],isManaged: Bool) -> (Double,Double,Double) {
        let chosen=isManaged ? lineup.compactMap { id in roster.first{$0.id==id} } : Array(roster.sorted{$0.rating>$1.rating}.prefix(11))
        guard !chosen.isEmpty else { return (30,30,30) }
        var attack=0.0,defence=0.0,midfield=0.0
        for (i,p) in chosen.enumerated() {
            let st=states[p.id]!
            let fitness=0.65+Double(st.fitness)/285, morale=0.9+Double(st.morale)/750
            let fit=isManaged && tactics.slots[i] != p.position ? 0.8:1.0
            let weight=fitness*morale*fit
            attack += Double(p.skills[3]*2+p.skills[4]+p.skills[8])*weight/4
            defence += Double(p.position=="GK" ? p.skills[0]*3:p.skills[1]*2+p.skills[5])*weight/3
            midfield += Double(p.skills[2]+p.skills[8])*weight/2
        }
        let count=Double(chosen.count)
        attack /= count;defence /= count;midfield /= count
        if isManaged {
            if tactics.mentality=="Attacking" { attack *= 1.17;defence *= 0.88 }
            if tactics.mentality=="Defensive" { attack *= 0.85;defence *= 1.15 }
            if tactics.passing=="Short" { attack *= 0.8+midfield/250 }
            if tactics.passing=="Direct" { attack *= 1.08;midfield *= 0.9 }
            if tactics.tackling=="Hard" { defence *= 1.07 }
            if tactics.tackling=="Cautious" { defence *= 0.97 }
        }
        return (attack,defence,midfield)
    }
    private mutating func simulate(_ f: Fixture,h:(Double,Double,Double),a:(Double,Double,Double),homeSquad:[Player],awaySquad:[Player]) -> MatchReport {
        let homeRate=min(2.35,max(0.40,1.18+(h.0-a.1)/48))
        let awayRate=min(2.15,max(0.35,0.95+(a.0-h.1)/48))
        var hg=0,ag=0,hs=0,as_=0
        var events=[MatchEvent(id:0,minute:0,text:"Kick-off. \(name(f.home)) get us underway.",homeScore:0,awayScore:0)]
        let homeChosen=f.home==clubID ? homeSquad.filter{lineup.contains($0.id)} : Array(homeSquad.sorted{$0.rating>$1.rating}.prefix(11))
        let awayChosen=f.away==clubID ? awaySquad.filter{lineup.contains($0.id)} : Array(awaySquad.sorted{$0.rating>$1.rating}.prefix(11))
        for minute in 1...90 {
            for home in [true,false] {
                let rate=home ? homeRate:awayRate
                if rng.unit()<rate/13 {
                    if home { hs += 1 } else { as_ += 1 }
                    let chanceQuality=home ? max(-0.02,min(0.025,(h.0-a.1)/900)) : max(-0.02,min(0.025,(a.0-h.1)/900))
                    let goal=rng.unit() < 0.055+chanceQuality
                    let side=home ? homeChosen:awayChosen
                    let scorers=side.filter{$0.position != "GK"}.sorted{$0.skills[3]>$1.skills[3]}
                    let scorer=scorers.isEmpty ? nil:scorers[rng.int(0...min(4,scorers.count-1))]
                    if goal {
                        if home { hg += 1 } else { ag += 1 }
                        if let p=scorer { states[p.id]!.goals += 1 }
                        events.append(MatchEvent(id:events.count,minute:minute,text:"GOAL! \(scorer?.name ?? "A superb finish") for \(name(home ? f.home:f.away)).",homeScore:hg,awayScore:ag))
                    } else if minute%3==0 {
                        let line=rng.unit()<0.5 ? "A fine save denies":"Just wide from"
                        events.append(MatchEvent(id:events.count,minute:minute,text:"\(line) \(scorer?.name ?? "the attack").",homeScore:hg,awayScore:ag))
                    }
                }
            }
            if minute==45 { events.append(MatchEvent(id:events.count,minute:45,text:"Half-time. The teams head down the tunnel.",homeScore:hg,awayScore:ag)) }
        }
        events.append(MatchEvent(id:events.count,minute:90,text:"Full-time. \(name(f.home)) \(hg)–\(ag) \(name(f.away)).",homeScore:hg,awayScore:ag))
        let cap=f.home==clubID ? capacity:35_000
        let demand=f.home==clubID ? max(0.3,min(1.0,1.18-Double(ticketPrice)/80+Double(confidence)/350)):0.83
        let attendance=Int(Double(cap)*min(1,demand*(0.9+rng.unit()*0.16)))
        return MatchReport(home:f.home,away:f.away,homeGoals:hg,awayGoals:ag,possession:Int(min(70,max(30,50+(h.2-a.2)/2))),homeShots:hs,awayShots:as_,attendance:attendance,events:events)
    }
    private mutating func train() {
        let focus=["Keeping":0,"Defending":1,"Passing":2,"Finishing":3,"Fitness":6][training]
        for i in players.indices where players[i].clubID==clubID && states[players[i].id]!.injuryWeeks==0 {
            let id=players[i].id
            if training=="Recovery" { states[id]!.fitness=min(100,states[id]!.fitness+15);continue }
            let chance=Double(facilities+(coachingLevel ?? 0))*0.12*(intensity=="Intense" ? 1.6:1)
            if rng.unit()<chance {
                let personal=["Keeping":0,"Defending":1,"Passing":2,"Finishing":3,"Fitness":6][individualTraining?[id] ?? ""]
                let skill=personal ?? focus ?? rng.int(1...8)
                players[i].skills[skill]=min(99,players[i].skills[skill]+1)
            }
            if intensity=="Intense" {
                states[id]!.fitness=max(25,states[id]!.fitness-7)
                if rng.unit()<0.025 { states[id]!.injuryWeeks=1 }
            }
        }
    }
    private mutating func resolveOffers() {
        let due=offers.filter{$0.dueWeek<=week};offers.removeAll{$0.dueWeek<=week}
        for offer in due {
            guard let i=players.firstIndex(where:{$0.id==offer.playerID}) else { continue }
            let p=players[i]
            if offer.selling {
                guard p.clubID==clubID,squad.count>16 else { continue }
                let buyers=clubs.filter{$0.id != clubID && $0.country==club.country}
                guard !buyers.isEmpty else { continue }
                players[i].clubID=buyers[rng.int(0...buyers.count-1)].id
                transact("Sold \(p.name)",p.value*85/100)
                lineup.removeAll{$0==p.id};autoSelect()
                post("TRANSFER","\(p.name) leaves the club","The club received £\((p.value*85/100).formatted()).")
            } else if p.clubID != clubID && offer.fee>=p.value && offer.wage>=p.wage && cash>=offer.fee {
                players[i].clubID=clubID;states[p.id]!.wage=offer.wage;states[p.id]!.contractYears=3
                transact("Signed \(p.name)",-offer.fee)
                post("TRANSFER","\(p.name) joins \(club.name)","Three-season contract signed. He is available for team selection.")
            } else { post("NEGOTIATIONS","Offer for \(p.name) unsuccessful","The club expects at least £\(p.value.formatted()) and the player £\(p.wage.formatted()) per week. Your available cash must also cover the fee on completion.") }
        }
    }
    public mutating func nextSeason() {
        guard seasonFinished else { return }
        let finishedWeek=week
        let recap=currentSeasonRecap
        if seasonRecaps == nil { seasonRecaps=[] }
        seasonRecaps!.removeAll { $0.season == recap.season }
        seasonRecaps!.insert(recap, at: 0)
        let standing=table(),rank=(standing.firstIndex{$0.id==clubID} ?? 0)+1
        history.insert("Season \(season): \(club.league), position \(rank), \(standing.first{$0.id==clubID}?.points ?? 0) points",at:0)
        if let terms=management?.playerBonuses {
            let amount=terms.values.reduce(0){$0+(rank==1 ? $1.league:0)+(rank<=2 ? $1.promotion:0)}
            if amount>0 {transact("Season contract bonuses",-amount)}
        }
        if recap.totalPrize > 0 { transact("Season prize money",recap.totalPrize) }
        var moves:[String:Int]=[:]
        for country in Set(clubs.map(\.country)).sorted() {
            let divisions=Set(clubs.filter{$0.country==country}.map(\.division)).sorted()
            for (upper,lower) in zip(divisions,divisions.dropFirst()) {
                let up=table(league:CompetitionNames.league(country:country,division:upper))
                let down=table(league:CompetitionNames.league(country:country,division:lower))
                for c in up.suffix(2) { moves[c.id]=lower }
                for c in down.prefix(2) { moves[c.id]=upper }
            }
        }
        for i in clubs.indices { if let d=moves[clubs[i].id] { clubs[i].division=d } }
        if ground != nil {for i in ground!.indices {if let due=ground![i].dueWeek {ground![i].dueWeek=max(1,due-finishedWeek)}}}
        season += 1;week=0;fixtures=Self.schedule(clubs:clubs,season:season);lastMatch=nil;offers=[]
        rollOverPlayers()
        if let p=construction { construction=Construction(kind:p.kind,dueWeek:max(1,p.dueWeek-finishedWeek)) }
        for id in states.keys.sorted() {
            states[id]!.goals=0;states[id]!.fitness=100;states[id]!.injuryWeeks=0
            states[id]!.contractYears=max(0,states[id]!.contractYears-1)
        }
        // Expiring contracts are automatically renewed with a pay rise to keep squads viable.
        for p in squad where states[p.id]!.contractYears==0 {
            states[p.id]!.contractYears=1;states[p.id]!.wage=Int(Double(states[p.id]!.wage)*1.15)
            post("CONTRACT","\(p.name): automatic one-year extension","The assistant renewed an expiring contract with a 15% wage increase. Renew earlier to control costs.")
        }
        if cups != nil {cups=nil;enableDomesticCups()}
        autoSelect();post("BOARD","A new season begins","You will compete in \(club.league). The board expects a top-half finish.")
    }
}

public enum SaveError: Error, LocalizedError {
    case incompatible
    public var errorDescription: String? { "This save is incompatible or has invalid career data." }
}
public enum SaveStore {
    public static func save(_ career: Career,to url: URL) throws {
        try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
        let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys]
        try encoder.encode(career).write(to:url,options:.atomic)
    }
    public static func load(from url: URL) throws -> Career {
        var c=try JSONDecoder().decode(Career.self,from:Data(contentsOf:url))
        let ids=Set(c.players.map(\.id)),clubIDs=Set(c.clubs.map(\.id))
        guard c.version==1,clubIDs.contains(c.clubID),ids.count==c.players.count,clubIDs.count==c.clubs.count,
              c.players.allSatisfy({$0.skills.count==9 && $0.skills.allSatisfy{0...100 ~= $0} && c.states[$0.id] != nil && clubIDs.contains($0.clubID)}),
              c.fixtures.allSatisfy({clubIDs.contains($0.home) && clubIDs.contains($0.away) && ($0.homeGoals==nil)==($0.awayGoals==nil)}),
              ["4-4-2","4-3-3","3-5-2","5-3-2"].contains(c.tactics.formation),
              c.lineup.count<=11,Set(c.lineup).count==c.lineup.count,c.lineup.allSatisfy({ids.contains($0)}),c.week>=0 else { throw SaveError.incompatible }
        for player in c.players {
            if let month=player.birthMonth,!(1...12).contains(month){throw SaveError.incompatible}
            if let day=player.birthDay,!(1...31).contains(day){throw SaveError.incompatible}
            if let d=player.development {
                guard d.ceilings.count==9,d.progress.count==9,d.ceilings.allSatisfy({(0...100).contains($0)}),d.progress.allSatisfy({$0.isFinite && $0>=0 && $0<1}),d.aptitude.isFinite,(0.1...3).contains(d.aptitude),(32...48).contains(d.retirementAge) else {throw SaveError.incompatible}
            }
        }
        if let m=c.management {
            guard m.schema==1,m.timetable.count==14,m.deposit>=0,
                Set(m.staff.map(\.id)).count==m.staff.count,
                m.staff.allSatisfy({$0.wage>=0 && (0...100).contains($0.quality)}),
                m.assignments.allSatisfy({ids.contains($0.key) && (0..<9).contains($0.value.skill) && (1...3).contains($0.value.intensity)}),
                m.negotiations.allSatisfy({ids.contains($0.playerID) && clubIDs.contains($0.clubID) && $0.fee>=0 && $0.wage>=0 && $0.signingFee>=0}),
                m.loans.allSatisfy({ids.contains($0.playerID) && clubIDs.contains($0.ownerID)}) else {throw SaveError.incompatible}
        }
        if let m=c.management {
            guard (m.loanListed ?? [:]).allSatisfy({ids.contains($0.key) && (4...52).contains($0.value)}),m.listed.allSatisfy({ids.contains($0.key) && $0.value>=0}) else{throw SaveError.incompatible}
            for saved in m.savedFormations ?? [] {
                guard !saved.name.isEmpty,["4-4-2","4-3-3","3-5-2","5-3-2"].contains(saved.formation) else{throw SaveError.incompatible}
                if let positions=saved.positions {guard positions.count==11,positions.allSatisfy({$0.x.isFinite && $0.y.isFinite && (0...105).contains($0.x) && (0...68).contains($0.y)}) else{throw SaveError.incompatible}}
                if let plan=saved.plan {guard plan.states.values.allSatisfy({$0.count==11 && $0.allSatisfy{$0.point.x.isFinite && $0.point.y.isFinite && (0...105).contains($0.point.x) && (0...68).contains($0.point.y)}}) else{throw SaveError.incompatible}}
            }
        }
        if let positions=c.tactics.customPositions {guard positions.count==11,positions.allSatisfy({$0.x.isFinite && $0.y.isFinite && (0...105).contains($0.x) && (0...68).contains($0.y)}) else {throw SaveError.incompatible}}
        if let plan=c.tactics.plan {guard plan.states.values.allSatisfy({$0.count==11 && $0.allSatisfy{$0.point.x.isFinite && $0.point.y.isFinite}}) else {throw SaveError.incompatible}}
        if let ground=c.ground {
            let valid=Set(GroundPlot.all.map(\.id))
            guard Set(ground.map(\.id)).count==ground.count,Set(ground.map(\.plotID)).count==ground.count,
                  ground.allSatisfy({valid.contains($0.plotID) && $0.level>=0 && $0.capacity>=0}) else {throw SaveError.incompatible}
        }
        if let match=c.activeMatch {
            if let restart=match.setPieceRestart {guard restart.remaining.isFinite,(0...4).contains(restart.remaining),(0...1).contains(restart.side),ids.contains(restart.taker) else{throw SaveError.incompatible}}

            guard c.fixtures.contains(where:{$0.id==match.fixtureID && !$0.played}),
                  match.elapsed>=0 && match.elapsed<=5400,match.managedSide==0 || match.managedSide==1,
                  Set(match.players.map(\.id)).count==match.players.count,
                  match.players.allSatisfy({ids.contains($0.id) && $0.skills.count==9 && (0...1).contains($0.side)}),
                  (14...22).contains(match.activePlayers.count),
                  ["4-4-2","4-3-3","3-5-2","5-3-2"].contains(match.homeTactics.formation),
                  ["4-4-2","4-3-3","3-5-2","5-3-2"].contains(match.awayTactics.formation)
            else {throw SaveError.incompatible}
        }
        c.initializePlayerDevelopment()
        return c
    }
}
