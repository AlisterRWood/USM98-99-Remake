import SwiftUI
import USMCore
struct OppositionScreen:View {
    @EnvironmentObject var store:GameStore
    var body:some View {ClassicScreen(title:"View Opposition") {
        if let f=store.career.nextFixture {
            let id=f.home==store.career.clubID ? f.away:f.home
            Text(store.career.name(id)).font(.title.bold()).foregroundStyle(mint)
            Text("Next match: Week \(f.round+1) · \(f.home==id ? "Away":"Home")")
            ScrollView {LazyVStack {ForEach(store.career.players.filter{$0.clubID==id}.sorted{$0.rating>$1.rating}) {p in HStack {Text(p.name).frame(maxWidth:.infinity,alignment:.leading);Text(p.position).frame(width:80);Text("Ability \(p.rating)").frame(width:100);Text("Fitness \(store.career.states[p.id]?.fitness ?? 100)").frame(width:100);Button("Shortlist") {store.career.toggleShortlist(p.id);store.save()}.disabled(p.clubID==store.career.clubID)}.padding(6).background(.black.opacity(0.2))}}}
        }else{Text("No remaining fixtures this season.")}
    }}}
struct MedicalScreen:View {
    @EnvironmentObject var store:GameStore
    var body:some View {ClassicScreen(title:"Injuries & Fitness") {
        ScrollView {LazyVStack {ForEach(store.career.squad.sorted{(store.career.states[$0.id]?.injuryWeeks ?? 0)>(store.career.states[$1.id]?.injuryWeeks ?? 0)}) {p in
            let state=store.career.states[p.id]!
            HStack {Text(p.name).frame(maxWidth:.infinity,alignment:.leading);Text(state.injuryWeeks>0 ? "Unavailable · \(state.injuryWeeks) weeks":((state.suspendedMatches ?? 0)>0 ? "Suspended · \(state.suspendedMatches ?? 0) matches":"Available")).foregroundStyle(state.injuryWeeks>0 ? .orange:mint).frame(width:230);Text("Fitness \(state.fitness)%").frame(width:130)}.padding(9).background(.black.opacity(0.18))
        }}}
        Button("Training programme") {store.page="Team training"}
    }}}
struct EvaluationScreen:View {
    @EnvironmentObject var store:GameStore
    var body:some View {ClassicScreen(title:"Chairman’s Evaluation") {
        Text("\(store.career.manager), we expect a top-half finish.").font(.title2.bold()).foregroundStyle(mint)
        let last=store.career.worldState.evaluations.last
        HStack {rating("Chairman",last?.chairman ?? store.career.confidence);rating("Finances",last?.finances ?? 50);rating("Supporters",last?.fans ?? 50);rating("Players / staff",last?.dressingRoom ?? 75)}
        Canvas {context,size in
            let records=store.career.worldState.evaluations
            for source in 0..<4 {var path=Path();for (i,e) in records.enumerated(){let values=[e.chairman,e.finances,e.fans,e.dressingRoom];let p=CGPoint(x:Double(i)*size.width/Double(max(1,records.count-1)),y:size.height*(1-Double(values[source])/100));if i==0{path.move(to:p)}else{path.addLine(to:p)}};context.stroke(path,with:.color([Color.red,.yellow,.cyan,.white][source]),lineWidth:2)}
        }.background(.black.opacity(0.3)).overlay(alignment:.bottomLeading){Text("Weekly confidence history").font(.caption).padding(8)}
        HStack {Button("Accounts") {store.page="Club business"};Button("Job vacancies") {store.page="Jobs"};Button("Club history") {store.page="Archive"}}
    }}
    func rating(_ title:String,_ value:Int)->some View {VStack {Text(title);Text("\(value)%").font(.largeTitle.bold()).foregroundStyle(mint)}.frame(maxWidth:.infinity).padding(12).background(.black.opacity(0.2))}
}
struct PrivatePhoneScreen:View {
    @EnvironmentObject var store:GameStore
    @ViewState var kind="Match approach"
    @ViewState var target=""
    @ViewState var amount=10000
    var body:some View {ClassicScreen(title:"Private Telephone") {
        GameChoice(label:"Call",value:$kind,options:["Match approach","Transfer bung","Bookmaker"])
        GameChoice(label:"Club",value:$target,options:store.career.clubs.filter{$0.country==store.career.club.country && $0.id != store.career.clubID}.map(\.name))
        GameNumber(label:"Amount £",value:$amount,range:1000...500000,step:1000)
        Text(kind=="Bookmaker" ? "Stake on your team winning its next match. A win returns twice the stake.":"A private approach can be refused or reported. Your club pays the amount now; exposure can cause a fine and dismissal.").foregroundStyle(mint)
        Button("Make private call") {if let club=store.career.clubs.first(where:{$0.name==target}) {if !store.career.privateCall(kind:kind,target:club.id,amount:amount){store.message="Check funds. Match calls and wagers must concern your next opponent, with only one pending call of each type."};store.save()}}
        ScrollView {LazyVStack(alignment:.leading) {ForEach(store.career.worldState.calls.reversed()) {c in VStack(alignment:.leading){Text(c.kind+" · "+store.career.name(c.target)).bold();Text(c.reply).foregroundStyle(muted)}.padding(10)}}}
    }.onAppear {if let fixture=store.career.nextFixture {target=store.career.name(fixture.home==store.career.clubID ? fixture.away:fixture.home)}}}
}
struct JobsScreen:View {
    @EnvironmentObject var store:GameStore
    var body:some View {ClassicScreen(title:"Managerial Appointments") {Text("Clubs at your current level or below will consider an application.").foregroundStyle(mint);ScrollView {LazyVStack {ForEach(store.career.clubs.filter{$0.country==store.career.club.country && $0.id != store.career.clubID}) {c in HStack {Text(c.name);Spacer();Text(c.league);Button("Apply") {if store.career.applyForJob(c.id){store.save();store.enter("Stadium")}else{store.message="Your application was unsuccessful."}}}.padding(7)}}}}}
}
struct MessageScreen:View {
    @EnvironmentObject var store:GameStore
    @ViewState var filter="All messages"
    @ViewState var selected:String?
    var body:some View {ClassicScreen(title:"Messages") {
        GameChoice(label:"Folder",value:$filter,options:["All messages","Email","Voicemail","Newspaper","Scrapbook"])
        HStack {
            ScrollView {LazyVStack(alignment:.leading,spacing:3) {ForEach(store.career.news.filter{n in filter=="All messages" || (filter=="Email" && ["TRANSFER","NEGOTIATIONS","BUSINESS"].contains(n.category)) || (filter=="Voicemail" && ["BOARD","MEDICAL","STAFF","SCOUTING","PRIVATE"].contains(n.category)) || (filter=="Newspaper" && ["MATCH REPORT","SEASON"].contains(n.category)) || (filter=="Scrapbook" && store.career.worldState.scrapbook.contains(n.id.uuidString))}) {n in
                Button {selected=n.id.uuidString;store.career.initializeWorld();if !store.career.world!.readMessages.contains(n.id.uuidString){store.career.world!.readMessages.append(n.id.uuidString)};store.save()} label:{Text((store.career.worldState.readMessages.contains(n.id.uuidString) ? "":"● ")+n.title).frame(maxWidth:.infinity,alignment:.leading).padding(9).background(selected==n.id.uuidString ? crimson:.black.opacity(0.2))}.buttonStyle(.plain)
            }}}.frame(width:330)
            VStack(alignment:.leading,spacing:16){if let n=store.career.news.first(where:{$0.id.uuidString==selected}){Text(n.title).font(.title2.bold()).foregroundStyle(mint);Text("\(n.category) · Week \(n.week+1)").foregroundStyle(muted);Text(n.body);Button("Keep in scrapbook") {store.career.initializeWorld();if !store.career.world!.scrapbook.contains(n.id.uuidString){store.career.world!.scrapbook.append(n.id.uuidString)};store.save()};if n.category=="NEGOTIATIONS"{Button("Reply in negotiations") {store.page="Negotiations"}}}else{Text("Select a message").foregroundStyle(mint)};Spacer()}.frame(maxWidth:.infinity,alignment:.leading).padding(15)
        }
    }}
}

struct CompetitionScreen:View {
    var initialTab="League"
    @EnvironmentObject var store:GameStore
    @ViewState var tab="League"
    @ViewState var league=""
    @ViewState var opponent=""
    var body:some View {TeletextPanel(title:tab,league:league) {
        HStack {GameChoice(label:"View",value:$tab,options:["League","Results","Top scorers","Form","Fixtures","Cups","Trophies","Friendlies"]);GameChoice(label:"League",value:$league,options:Array(Set(store.career.clubs.map(\.league))).sorted())}
        if tab=="League" {
            HStack {Text("Club").frame(maxWidth:.infinity,alignment:.leading);ForEach(["P","W","D","L","GF","GA","Pts"],id:\.self){Text($0).frame(width:55)}}.foregroundStyle(mint)
            ScrollView {LazyVStack(spacing:1) {ForEach(Array(store.career.table(league:league).enumerated()),id:\.element.id) {i,r in HStack {Text("\(i+1)  "+store.career.name(r.id)).frame(maxWidth:.infinity,alignment:.leading);ForEach(Array([r.played,r.won,r.drawn,r.lost,r.scored,r.conceded,r.points].enumerated()),id:\.offset) {_,value in Text("\(value)").frame(width:55)}}.padding(6).background(r.id==store.career.clubID ? crimson:.black.opacity(0.2))}}}
        }else if tab=="Top scorers" {
            Text("SEASON GOALS · All competitions · Players currently in "+league).font(.caption).foregroundStyle(.cyan)
            let players=store.career.topScorers(league:league)
            HStack {Text("PLAYER").frame(maxWidth:.infinity,alignment:.leading);Text("CLUB").frame(width:240,alignment:.leading);Text("GOALS").frame(width:65)}.foregroundStyle(.yellow)
            if players.isEmpty {Text("No goals recorded yet this season.").foregroundStyle(.white);Spacer()}
            ScrollView {LazyVStack(spacing:4){ForEach(Array(players.enumerated()),id:\.element.id){i,p in HStack {Text("\(i+1) "+p.name).frame(maxWidth:.infinity,alignment:.leading);Text(store.career.name(p.clubID)).frame(width:240,alignment:.leading);Text("\(store.career.states[p.id]?.goals ?? 0)").frame(width:65).foregroundStyle(.yellow)}}}}
        }else if tab=="Results" {
            let fixtures=store.career.fixtures.filter{$0.played}.filter{f in store.career.clubs.contains{$0.id==f.home && $0.league==league}}.sorted{$0.round>$1.round}
            if fixtures.isEmpty {Text("No results yet.");Spacer()}
            ScrollView {LazyVStack{ForEach(fixtures){f in fixtureRow(f)}}}
        }else if tab=="Form" {
            Text("LAST SIX LEAGUE MATCHES · Oldest → newest").foregroundStyle(.cyan)
            ScrollView {LazyVStack{ForEach(store.career.table(league:league)){r in HStack{Text(store.career.name(r.id)).frame(maxWidth:.infinity,alignment:.leading);Text(store.career.recentForm(clubID:r.id)).foregroundStyle(.yellow).tracking(6)}.padding(5)}}}
        }else if tab=="Fixtures" {
            ScrollView {LazyVStack {ForEach(store.career.fixtures.filter{$0.home==store.career.clubID || $0.away==store.career.clubID}) {f in fixtureRow(f)}}}
        }else if tab=="Cups" {
            if store.career.cups==nil {Text("Add domestic cups to this existing career. Remaining league dates are preserved and moved around cup rounds.");Button("Enable domestic cups") {store.career.enableDomesticCups();store.save()}}
            ScrollView {LazyVStack(alignment:.leading) {ForEach(store.career.cups ?? []) {cup in Text(cup.name+" · Round \(cup.round)").font(.headline).foregroundStyle(mint);ForEach(store.career.fixtures.filter{cup.fixtureIDs.contains($0.id)}) {f in fixtureRow(f)}}}}
        }else if tab=="Trophies" {
            ScrollView {LazyVStack {ForEach(store.career.trophies ?? []) {t in HStack {Text("Season \(t.season) · "+t.competition);Spacer();Text(store.career.name(t.winner)).foregroundStyle(mint);Text("Runner-up: "+store.career.name(t.runnerUp)).foregroundStyle(muted)}.padding(8)}}}
        }else{
            GameChoice(label:"Opponent",value:$opponent,options:store.career.clubs.filter{$0.country==store.career.club.country && $0.id != store.career.clubID}.map(\.name))
            Text("Invite a club for a home friendly before the next scheduled fixture. Existing fixtures move to the following date.").foregroundStyle(mint)
            Button("Arrange friendly") {if let club=store.career.clubs.first(where:{$0.name==opponent}){_=store.career.arrangeFriendly(opponent:club.id);store.save();tab="Fixtures"}}
            Spacer()
        }
    }.onAppear {tab=initialTab;league=store.career.club.league;opponent=store.career.clubs.first{$0.country==store.career.club.country && $0.id != store.career.clubID}?.name ?? ""}}
    func fixtureRow(_ f:Fixture)->some View {HStack {Text("W\(f.round+1)").frame(width:45);Text(store.career.name(f.home)).frame(maxWidth:.infinity,alignment:.trailing);Text(f.played ? "\(f.homeGoals!)–\(f.awayGoals!)":"v").frame(width:50).foregroundStyle(mint);Text(store.career.name(f.away)).frame(maxWidth:.infinity,alignment:.leading);Text(f.competition==nil ? "League":(f.competition=="Friendly" ? "Friendly":"Cup")).frame(width:65)}.padding(6).background(.black.opacity(0.15))}
}
