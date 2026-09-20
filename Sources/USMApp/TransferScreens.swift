import SwiftUI
import USMCore

struct PlayerSearchScreen:View {
    @EnvironmentObject var store:GameStore
    @ViewState var query=""
    @ViewState var role="All positions"
    @ViewState var country="All leagues"
    @ViewState var contract="All contracts"
    @ViewState var sort="Value"
    @ViewState var minimum=0
    @ViewState var maximum=100_000_000
    @ViewState var skill="Any skill"
    @ViewState var skillMin=0
    @ViewState var ageMin=16
    @ViewState var ageMax=45
    @ViewState var division="All divisions"
    @ViewState var skillMinimums=Array(repeating:0,count:9)
    @ViewState var skillMaximums=Array(repeating:99,count:9)
    @ViewState var squadFilter="All players"
    @ViewState var showSkills=false
    @ViewState var record=false
    @ViewState var page=0
    @ViewState var selected:String?
    var shortlist=false
    let skillNames=["Keeping","Tackling","Passing","Shooting","Pace","Heading","Stamina","Set pieces","Control"]
    var results:[Player] {
        let clubMap=Dictionary(uniqueKeysWithValues:store.career.clubs.map{($0.id,$0)})
        let m=store.career.managementState
        return store.career.players.filter {p in
            (query.isEmpty || p.name.localizedCaseInsensitiveContains(query)) && (p.age(season:store.career.season).map{$0>=ageMin && $0<=ageMax} ?? (ageMin==16 && ageMax==45)) && (division=="All divisions" || clubMap[p.clubID]?.division==Int(division)) && (0..<9).allSatisfy{p.skills[$0]>=skillMinimums[$0] && p.skills[$0]<=skillMaximums[$0]} && (role=="All positions" || p.position==role) &&
            (squadFilter=="All players" || (squadFilter=="My first team" && p.clubID==store.career.clubID && store.career.lineup.contains(p.id)) || (squadFilter=="My reserves" && p.clubID==store.career.clubID && !store.career.lineup.contains(p.id))) &&
            (country=="All leagues" || clubMap[p.clubID]?.country==country) && p.value>=minimum && p.value<=maximum &&
            (contract=="All contracts" || (contract=="Expiring" && (store.career.states[p.id]?.contractYears ?? 3)<=1) || (contract=="My players" && p.clubID==store.career.clubID) || (contract=="Transfer listed" && m.listed[p.id] != nil)) &&
            (!shortlist || (m.shortlist.contains(p.id) && p.clubID != store.career.clubID)) && (skill=="Any skill" || p.skills[skillNames.firstIndex(of:skill) ?? 0]>=skillMin)
        }.sorted{a,b in sort=="Name" ? a.name<b.name:sort=="Wage" ? a.wage<b.wage:sort=="Ability" ? a.rating>b.rating:a.value>b.value}
    }
    var chosen:Player? {store.career.players.first{$0.id==selected}}
    var body:some View {
        ClassicScreen(title:shortlist ? "Shortlist & Scouting":"Player Search") {
            HStack(alignment:.top,spacing:7) {
                VStack(spacing:3) {
                    GameChoice(label:"",value:$role,options:["All positions","GK","DEF","MID","FWD"])
                    GameChoice(label:"",value:$country,options:["All leagues"]+Array(Set(store.career.clubs.map(\.country))).sorted())
                    GameChoice(label:"",value:$division,options:["All divisions"]+Array(Set(store.career.clubs.map{String($0.division)})).sorted())
                }
                VStack(spacing:3) {
                    GameChoice(label:"",value:$sort,options:["Value","Ability","Name","Wage"])
                    GameChoice(label:"",value:$contract,options:["All contracts","Expiring","Transfer listed","My players"])
                    GameChoice(label:"",value:$squadFilter,options:["All players","My first team","My reserves"]).help("Filter your club's starting eleven or reserve players")
                }
                VStack(spacing:3) {
                    Button("Scout Suggestions") {skill="Any skill";skillMin=0;sort="Ability"}.frame(maxWidth:.infinity)
                    Button(showSkills ? "Hide Skills":"Skills") {showSkills.toggle()}.frame(maxWidth:.infinity)
                    HStack(spacing:3) {GameNumber(label:"Age from",value:$ageMin,range:16...45);GameNumber(label:"To",value:$ageMax,range:16...45)}
                    HStack(spacing:3) {GameNumber(label:"Value from",value:$minimum,range:0...100_000_000,step:100000);GameNumber(label:"To",value:$maximum,range:0...100_000_000,step:100000)}
                }.frame(maxWidth:.infinity)
                VStack(spacing:5) {
                    Button("Reset") {resetFilters()}
                    TextField("Player name",text:$query).textFieldStyle(.plain).padding(6).background(.black.opacity(0.4),in:RoundedRectangle(cornerRadius:4))
                }.frame(width:130)
            }
            if showSkills {LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:3),spacing:2) {ForEach(0..<9,id:\.self) {i in HStack(spacing:2) {Text(skillNames[i]).font(.system(size:10,weight:.bold)).foregroundStyle(mint);GameNumber(label:"Min",value:$skillMinimums[i],range:0...99);GameNumber(label:"Max",value:$skillMaximums[i],range:0...99)}}}}
            HStack(spacing:0) {searchHeader("Name",width:nil);searchHeader("Club",width:190);searchHeader("Age",width:38);searchHeader("Pos",width:38);searchHeader("Contract",width:72);searchHeader("Nationality",width:100);searchHeader("Wages",width:82);searchHeader("Valuation",width:88)}.foregroundStyle(.white).background(.black.opacity(0.75),in:RoundedRectangle(cornerRadius:4))
            let list=results
            ScrollView {LazyVStack(spacing:1) {ForEach(Array(list.dropFirst(min(page,max(0,(list.count-1)/50))*50).prefix(50))) {p in
                let club=store.career.clubs.first{$0.id==p.clubID}
                let age=p.age(season:store.career.season).map(String.init) ?? "-"
                let months=(store.career.states[p.id]?.contractYears ?? 0)*12
                Button {selected=p.id} label:{HStack(spacing:0) {searchCell(p.name);searchCell(store.career.name(p.clubID),width:190);searchCell(age,width:38);searchCell(p.position,width:38);searchCell("\(months) Mths",width:72);searchCell(club?.country ?? "Unknown",width:100);searchCell(searchMoney(store.career.states[p.id]?.wage ?? p.wage),width:82);searchCell(searchMoney(p.value),width:88)}.font(.system(size:11,weight:.semibold)).padding(.vertical,3).background(p.id==selected ? crimson:Color(red:0.08,green:0.28,blue:0.25))}.buttonStyle(.plain)
            }}}
            HStack(spacing:5) {Button("Buy") {approach(0)}.disabled(chosen==nil || chosen?.clubID==store.career.clubID);Button("Loan") {approach(12)}.disabled(chosen==nil || chosen?.clubID==store.career.clubID);Button("View") {record=true}.disabled(chosen==nil);Button("ShortList") {if let p=chosen {store.career.toggleShortlist(p.id);store.save()}}.disabled(chosen==nil || chosen?.clubID==store.career.clubID);Button("Skills") {record=true}.disabled(chosen==nil);Spacer();Button("◆") {page=max(0,page-1)};Button("◆") {page=min(max(0,(list.count-1)/50),page+1)};Button("Exit") {store.page=store.room}}
            if shortlist,let p=chosen {Text(store.career.managementState.scouts.first{$0.playerID==p.id}?.text ?? "No scout report. Assign a scout to investigate this player.").foregroundStyle(mint).frame(height:35)}
        }.sheet(isPresented:$record) {if let chosen {PlayerRecord(player:chosen)}}
    }
    func resetFilters(){query="";role="All positions";country="All leagues";contract="All contracts";minimum=0;maximum=100_000_000;skill="Any skill";skillMin=0;page=0;ageMin=16;ageMax=45;division="All divisions";skillMinimums=Array(repeating:0,count:9);skillMaximums=Array(repeating:99,count:9);squadFilter="All players";sort="Value"}
    @ViewBuilder func searchHeader(_ title:String,width:CGFloat?)->some View {Group {if let width {Text(title).frame(width:width,alignment:.leading)} else {Text(title).frame(maxWidth:.infinity,alignment:.leading)}}.padding(.horizontal,4).padding(.vertical,3).font(.system(size:11,weight:.bold))}
    @ViewBuilder func searchCell(_ value:String,width:CGFloat?=nil)->some View {Group {if let width {Text(value).lineLimit(1).minimumScaleFactor(0.7).frame(width:width,alignment:.leading)} else {Text(value).lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth:.infinity,alignment:.leading)}}.padding(.horizontal,4)}
    func searchMoney(_ value:Int)->String {value >= 1_000_000 ? "\(value/1_000_000)M" : value >= 1_000 ? "\(value/1_000)K" : "\(value)"}
    func approach(_ weeks:Int){if let p=chosen {if store.career.enquire(p.id,loanWeeks:weeks){store.save();store.page="Negotiations"}else{store.message="A negotiation is already open for this player."}}}
}
struct NegotiationScreen:View {
    @EnvironmentObject var store:GameStore
    @ViewState var selected:String?
    @ViewState var fee=0
    @ViewState var wage=0
    @ViewState var bonus=0
    @ViewState var years=3
    @ViewState var loanShare=100
    @ViewState var extras=false
    @ViewState var appearanceFee=0
    @ViewState var appearanceCount=10
    @ViewState var swap="None"
    @ViewState var bonuses=ContractBonuses()
    var chosen:Negotiation? {store.career.managementState.negotiations.first{$0.id==selected}}
    var body:some View {
        ClassicScreen(title:"Current Negotiations") {
            HStack(alignment:.top,spacing:14) {
                ScrollView {LazyVStack(spacing:5) {ForEach(store.career.managementState.negotiations.reversed()) {n in
                    Button {selected=n.id;sync(n)} label:{VStack(alignment:.leading,spacing:4) {Text(store.career.players.first{$0.id==n.playerID}?.name ?? "Player").bold();Text((n.selling ? "SELL / LOAN OUT · ":"BUY / LOAN IN · ")+n.stage).font(.caption).foregroundStyle(mint)}.frame(maxWidth:.infinity,alignment:.leading).padding(8).background(selected==n.id ? crimson:.black.opacity(0.3))}.buttonStyle(.plain)
                }}}.frame(width:215)
                VStack(alignment:.leading,spacing:8) {
                    if let n=chosen {
                        Text(n.stage.uppercased()).font(.headline).foregroundStyle(mint)
                        Text(n.reply).font(.system(size:12)).fixedSize(horizontal:false,vertical:true)
                        Text("Club: "+store.career.name(n.clubID)).font(.caption).foregroundStyle(muted)
                        if !n.selling && ["Club asking price","Club counter offer","Player terms","Player counter offer"].contains(n.stage) {
                            if n.stage.hasPrefix("Club") {GameNumber(label:"Club offer £",value:$fee,range:0...999_999_999,step:50000)}
                            else {
                                Text("Agreed club fee: "+money(n.fee)).foregroundStyle(mint)
                                GameNumber(label:"Weekly wage £",value:$wage,range:1...500000,step:500)
                                GameNumber(label:"Signing fee £",value:$bonus,range:0...100_000_000,step:1000)
                                GameNumber(label:"Contract years",value:$years,range:1...5)
                            }
                            Button("Clauses & bonuses") {extras=true}
                        }else {
                            Text((n.selling ? "Club receives: ":"Club fee: ")+money(n.fee)).font(.title3.bold())
                            if !n.selling {Text("Wage "+money(n.wage)+" / week · Signing fee "+money(n.signingFee)+" · \(n.years) years")}
                            if n.loanWeeks>0 {Text("Loan duration: \(n.loanWeeks) weeks · Wage contribution: \(n.loanWageShare ?? 100)%")}
                        }
                        Spacer(minLength:4)
                        if n.stage=="Final review" {
                            Text(n.selling ? "Accept to transfer the player and credit the agreed payment.":"Total payable now: "+money(n.fee+n.signingFee)).foregroundStyle(mint)
                            Button(n.selling ? (n.loanWeeks>0 ? "Accept loan out":"Accept sale & receive payment"):(n.clubID==store.career.clubID ? "Sign new contract":"Complete signing & pay")) {
                                if !store.career.acceptTransfer(n.id){store.message="Cannot complete: check funds, ownership, squad size, and finish any active match."};store.save()
                            }.buttonStyle(GameButton(red:true))
                        }else if ["Enquiry sent","Club considering","Player considering"].contains(n.stage) {
                            Button(n.stage=="Player considering" ? "Read agent’s reply":"Read club’s reply") {_=store.career.reviewNegotiationReply(n.id);if let updated=chosen{sync(updated)};store.save()}.buttonStyle(GameButton(red:true))
                            Text("Replies can be reviewed here without advancing your next fixture.").font(.caption).foregroundStyle(muted)
                        }else if ["Club asking price","Club counter offer","Player terms","Player counter offer"].contains(n.stage) {
                            Button(n.stage.hasPrefix("Club") ? "Offer club fee":"Offer player contract") {
                                store.career.updateTransferExtras(n.id,appearanceFee:appearanceFee,appearanceCount:appearanceCount,swap:store.career.squad.first{$0.name==swap}?.id,bonuses:bonuses)
                                if n.loanWeeks>0 {_=store.career.setLoanWageShare(n.id,share:loanShare)}
                                if !store.career.submitTerms(n.id,fee:fee,wage:wage,bonus:bonus,years:years){store.message="These terms are no longer available. Review the latest reply."};store.save()
                            }.buttonStyle(GameButton(red:true))
                        }else if n.stage=="Completed" {Text("AGREEMENT SIGNED · Squad and finances updated").foregroundStyle(.cyan)}
                        HStack {if !n.closed {Button("Withdraw") {store.career.withdrawNegotiation(n.id);store.save()}};Spacer();Button("Player search") {store.page="Transfers"}}
                    }else {Text("Select a player to read the reply. Agreed deals have an explicit signing or sale button.").foregroundStyle(mint);Spacer();Button("Player search") {store.page="Transfers"}}
                }.frame(maxWidth:.infinity,alignment:.leading)
            }
        }.onAppear {if selected==nil,let n=store.career.managementState.negotiations.last(where:{!$0.closed}) ?? store.career.managementState.negotiations.last {selected=n.id;sync(n)}}.onChange(of:chosen?.stage){_,_ in if let n=chosen{sync(n)}}.sheet(isPresented:$extras) {
            VStack(spacing:12) {
                Text("Additional Terms").font(.title2.bold()).foregroundStyle(mint)
                GameNumber(label:"Appearance payment £",value:$appearanceFee,range:0...10_000_000,step:50000).disabled(!(chosen?.stage.hasPrefix("Club") ?? false))
                GameNumber(label:"After appearances",value:$appearanceCount,range:1...100).disabled(!(chosen?.stage.hasPrefix("Club") ?? false))
                if chosen?.loanWeeks ?? 0 > 0 {GameNumber(label:"Loan wage %",value:$loanShare,range:0...100,step:25).help("Percentage of the player's wages paid by the borrowing club")}
                GameChoice(label:"Player exchange",value:$swap,options:["None"]+store.career.squad.map(\.name)).disabled(!(chosen?.stage.hasPrefix("Club") ?? false))
                HStack {VStack {GameNumber(label:"League title £",value:$bonuses.league,range:0...1000000,step:10000);GameNumber(label:"Cup win £",value:$bonuses.cup,range:0...1000000,step:10000);GameNumber(label:"Promotion £",value:$bonuses.promotion,range:0...1000000,step:10000)};VStack {GameNumber(label:"Cup final £",value:$bonuses.final,range:0...1000000,step:10000);GameNumber(label:"Match win £",value:$bonuses.win,range:0...10000,step:100);GameNumber(label:"Goal £",value:$bonuses.goal,range:0...10000,step:100)}}
                Text("Terms are sent with your next offer. Appearance clauses and performance bonuses are paid when triggered.").foregroundStyle(muted)
                Button("Return to offer") {extras=false}
            }.padding(20).frame(width:720,height:410).background(panel).buttonStyle(GameButton()).classicSheet("Additional Terms")
        }
    }
    func sync(_ n:Negotiation){fee=n.fee;wage=n.wage;bonus=n.signingFee;years=n.years;loanShare=n.loanWageShare ?? 100;appearanceFee=n.appearanceFee ?? 0;appearanceCount=n.appearanceCount ?? 10;swap=n.swapPlayer.flatMap{id in store.career.squad.first{$0.id==id}?.name} ?? "None";bonuses=n.bonuses ?? ContractBonuses()}

}
