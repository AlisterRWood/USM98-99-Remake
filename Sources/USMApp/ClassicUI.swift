import SwiftUI
import USMCore

let chrome=Color(red:0.68,green:0.70,blue:0.76)
let royal=Color(red:0.08,green:0.12,blue:0.56)
let crimson=Color(red:0.66,green:0.015,blue:0.025)
struct GameButton:ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var red=false
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(.system(size:12,weight:.bold)).foregroundStyle(.white)
            .padding(.horizontal,12).padding(.vertical,6).frame(minHeight:27)
            .background(LinearGradient(colors:[.black,red ? crimson:royal,red ? crimson:royal,.black],startPoint:.top,endPoint:.bottom),in:Capsule())
            .overlay(Capsule().stroke(chrome,lineWidth:1.5)).opacity(!isEnabled ? 0.38:(configuration.isPressed ? 0.65:1))
    }
}
struct GameChoice:View {
    var label:String
    @Binding var value:String
    var options:[String]
    @ViewState var open=false
    @ViewState var search=""
    var body:some View {
        HStack(spacing:5) {if !label.isEmpty {Text(label).foregroundStyle(mint)};Button("◀") {cycle(-1)};Button(value) {search="";open=true}.buttonStyle(.plain).font(.system(size:12,weight:.bold)).frame(maxWidth:.infinity).lineLimit(1).help(value).popover(isPresented:$open) {
                VStack(spacing:7) {if !label.isEmpty {Text(label).bold().foregroundStyle(mint)};if options.count>10 {TextField("Find…",text:$search).textFieldStyle(.plain).padding(6).background(.black.opacity(0.3))};ScrollView {LazyVStack(spacing:2){ForEach(options.filter{search.isEmpty || $0.localizedCaseInsensitiveContains(search)},id:\.self) {option in Button {value=option;open=false} label:{Text(option).frame(maxWidth:.infinity,alignment:.leading).padding(7).foregroundStyle(.white).background(value==option ? crimson:.black.opacity(0.25))}.buttonStyle(.plain)}}}.frame(height:min(230,CGFloat(options.count * 32)))}
                    .padding(10).frame(width:270).background(panel).classicSheet(label.isEmpty ? "Select":label)
            };Button("▶") {cycle(1)}}.buttonStyle(GameButton(red:true)).padding(4).background(.black.opacity(0.2),in:RoundedRectangle(cornerRadius:5))
    }
    func cycle(_ direction:Int){guard !options.isEmpty else{return};let i=options.firstIndex(of:value) ?? 0;value=options[(i+direction+options.count)%options.count]}
}
struct GameNumber:View {
    var label:String
    @Binding var value:Int
    var range:ClosedRange<Int>
    var step=1
    @ViewState var editing=false
    @ViewState var draft=""
    var body:some View {HStack {Text(label).foregroundStyle(mint);Spacer();Button("◀") {value=max(range.lowerBound,value-step)};Button(value.formatted()) {draft=String(value);editing=true}.buttonStyle(.plain).monospacedDigit().lineLimit(1).minimumScaleFactor(0.75).frame(width:85).padding(4).background(.black.opacity(0.35)).popover(isPresented:$editing) {VStack(spacing:9){Text(label).foregroundStyle(mint);TextField("Amount",text:$draft).textFieldStyle(.plain).padding(7).background(.black.opacity(0.4)).onSubmit{apply()};Button("Set value") {apply()}.disabled(Int(draft).map{range.contains($0)} != true)}.padding(15).frame(width:220).background(panel).buttonStyle(GameButton()).classicSheet("Set Value")};Button("▶") {value=min(range.upperBound,value+step)}}.font(.system(size:12,weight:.bold)).buttonStyle(GameButton(red:true))}
    func apply(){if let number=Int(draft),range.contains(number){value=number;editing=false}}
}
struct ClassicScreen<Content:View>:View {
    var title:String
    @ViewBuilder var content:Content
    @EnvironmentObject var store:GameStore
    var body:some View {
        VStack(spacing:5) {
            Text(title).font(.system(size:24,weight:.bold,design:.rounded)).frame(maxWidth:.infinity).padding(7).background(LinearGradient(colors:[.black,crimson,.black],startPoint:.top,endPoint:.bottom),in:Capsule()).overlay(Capsule().stroke(chrome,lineWidth:2))
            VStack(alignment:.leading,spacing:10) {content}.padding(12).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading).background(LinearGradient(colors:[panel,royal.opacity(0.65),panel],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(chrome,lineWidth:2))
            HStack {Text(store.career.club.name).font(.system(size:12,weight:.bold));Spacer();Text("Cash  "+money(store.career.cash)).foregroundStyle(mint);Spacer();Button("Exit") {store.page=store.room}}.padding(6).background(LinearGradient(colors:[.black,crimson,.black],startPoint:.top,endPoint:.bottom),in:Capsule())
        }.padding(10).buttonStyle(GameButton()).font(.system(size:13)).background(Color.black)
    }
}
struct StaffScreen:View {
    @EnvironmentObject var store:GameStore
    @ViewState var mode="Available"
    @ViewState var selected:String?
    var body:some View {
        ClassicScreen(title:"Coaches & Scouts") {
            HStack {GameChoice(label:"Show",value:$mode,options:["Available","Employed"]).frame(width:300);Spacer();Text("Coaches: \(store.career.managementState.staff.filter{$0.employed && $0.speciality != "Scout"}.count)/6").foregroundStyle(mint)}
            HStack {Text("Name").frame(maxWidth:.infinity,alignment:.leading);Text("Speciality").frame(width:140);Text("Ability").frame(width:70);Text("Weekly wage").frame(width:120);Text("Contract").frame(width:100)}.foregroundStyle(mint).padding(8).background(.black.opacity(0.3))
            ScrollView {LazyVStack(spacing:2) {ForEach(store.career.managementState.staff.filter{$0.employed == (mode=="Employed")}) {s in
                Button {selected=s.id} label:{HStack {Text(s.name).frame(maxWidth:.infinity,alignment:.leading);Text(s.speciality).frame(width:140);Text("\(s.quality)").frame(width:70);Text("£\(s.wage)").frame(width:120);Text("\(s.weeksRemaining) weeks").frame(width:100)}.padding(8).background(selected==s.id ? crimson:.black.opacity(0.2))}.buttonStyle(.plain)
            }}}
            HStack {Button("Hire selected") {if let id=selected {if !store.career.hireStaff(id){store.message="Cannot appoint: check funds and staff limit."};store.save()}}.disabled(mode != "Available" || !store.career.managementState.staff.contains{$0.id==selected && !$0.employed});Button("Renew · 2 years") {if let id=selected {_=store.career.renewStaff(id);store.save()}}.disabled(mode != "Employed" || selected==nil);Button("Dismiss · contract payoff") {if let id=selected {_=store.career.dismissStaff(id);store.save()}}.disabled(mode != "Employed" || selected==nil);Spacer();Text("Appointment fee: four weeks’ wages").foregroundStyle(muted)}
        }
    }
}
struct ProgrammeScreen:View {
    @EnvironmentObject var store:GameStore
    let activities=["Free time","Individual","Keeping","Defending","Passing","Attacking","Fitness","Set pieces"]
    @ViewState var camp="Leisure"
    @ViewState var duration=1
    var body:some View {
        ClassicScreen(title:"Team Training") {
            Text("Click a session to change its activity").foregroundStyle(mint)
            Grid(horizontalSpacing:8,verticalSpacing:12) {
                GridRow {Text("");ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"],id:\.self) {Text($0).font(.headline).foregroundStyle(mint)}}
                ForEach(0..<2,id:\.self) {time in GridRow {Text(time==0 ? "Morning":"Afternoon");ForEach(0..<7,id:\.self) {day in
                    let slot=day*2+time
                    Button(store.career.managementState.timetable[slot]) {let old=store.career.managementState.timetable[slot];store.career.setTraining(slot:slot,activity:activities[((activities.firstIndex(of:old) ?? 0)+1)%activities.count]);store.save()}.frame(maxWidth:.infinity,minHeight:65).disabled(day==5)
                }}}
            }.padding(12).background(.black.opacity(0.18),in:RoundedRectangle(cornerRadius:8))
            HStack {Button("Assistant programme") {store.career.initializeManagement();store.career.management!.timetable=ManagementState().timetable;store.save()};Button("Individual training") {store.page="Individual training"};Button("Coaching staff") {store.page="Coaching staff"}}
            Spacer()
            Text("Training Camp").font(.title2).foregroundStyle(mint)
            HStack {GameChoice(label:"Type",value:$camp,options:["Leisure","Intensive"]).frame(width:340);GameNumber(label:"Weeks",value:$duration,range:1...4).frame(width:220);Button("Book · "+money(store.career.squad.count*300*duration)) {if !store.career.bookCamp(kind:camp,weeks:duration){store.message="Check funds or finish the current camp first."};store.save()}}
            Text(store.career.managementState.campWeeks>0 ? "Camp in progress: \(store.career.managementState.campWeeks) weeks remaining":"Sessions influence development and recovery each week. Individual intensity adds fatigue and injury risk.").foregroundStyle(muted)
        }
    }
}
struct PersonalTrainingScreen:View {
    @EnvironmentObject var store:GameStore
    let skills=["Keeping","Tackling","Passing","Shooting","Pace","Heading","Stamina","Set pieces","Control"]
    var body:some View {
        ClassicScreen(title:"Individual Training") {
            Text("Choose a coach, skill and workload for each player. Coaches work best with ten or fewer assignments.").foregroundStyle(mint)
            ScrollView {LazyVStack(spacing:6) {ForEach(store.career.orderedSquad) {p in
                HStack {Text(p.name).frame(width:160,alignment:.leading)
                    GameChoice(label:"",value:Binding(get:{let id=store.career.managementState.assignments[p.id]?.coachID;return store.career.managementState.staff.first{$0.id==id}?.assignmentLabel ?? "Unassigned"},set:{name in let coach=store.career.managementState.staff.first{$0.assignmentLabel==name && $0.employed};let assignment=store.career.managementState.assignments[p.id];if store.career.setIndividualTraining(playerID:p.id,coachID:coach?.id,skill:assignment?.skill ?? 2,intensity:assignment?.intensity ?? 1) {store.save()}}),options:["Unassigned"]+store.career.managementState.staff.filter{$0.employed && $0.speciality != "Scout"}.map(\.assignmentLabel)).frame(minWidth:330).help("Assign or remove the coach responsible for this player")
                    GameChoice(label:"",value:Binding(get:{skills[store.career.managementState.assignments[p.id]?.skill ?? 2]},set:{value in let assignment=store.career.managementState.assignments[p.id];if store.career.setIndividualTraining(playerID:p.id,coachID:assignment?.coachID,skill:skills.firstIndex(of:value) ?? 2,intensity:assignment?.intensity ?? 1) {store.save()}}),options:skills).help("Choose the individual skill to develop")
                    GameNumber(label:"Intensity",value:Binding(get:{store.career.managementState.assignments[p.id]?.intensity ?? 1},set:{value in let assignment=store.career.managementState.assignments[p.id];if store.career.setIndividualTraining(playerID:p.id,coachID:assignment?.coachID,skill:assignment?.skill ?? 2,intensity:value) {store.save()}}),range:1...3).frame(width:240).help("Higher intensity improves development but increases fatigue and injury risk")
                }.padding(5).background(.black.opacity(0.2))
            }}}
            Button("Coaches & vacancies") {store.page="Coaching staff"}
        }
    }
}
struct CommercialScreen:View {
    @EnvironmentObject var store:GameStore
    var advertising=false
    var body:some View {
        ClassicScreen(title:advertising ? "Advertising Boards & Programme":"Club Sponsors") {
            Text("Select an offer to commit for its full term. Income is credited weekly.").foregroundStyle(mint)
            ScrollView {LazyVStack(spacing:7) {ForEach(store.career.managementState.deals.filter{advertising ? $0.kind != "Club sponsor":$0.kind=="Club sponsor"}) {d in
                let boardFull=advertising && d.kind=="Pitch boards" && !d.accepted && store.career.acceptedPitchBoardCount >= Career.pitchBoardCapacity
                HStack {VStack(alignment:.leading){Text(d.brand).font(.title3.bold());Text(d.kind).foregroundStyle(muted)};Spacer();Text(money(d.weekly)+" / week");Text("\(d.accepted ? d.remaining:d.term) weeks").frame(width:110);Button(d.accepted ? "Contract active":"Accept offer") {if !store.career.acceptDeal(d.id){store.message=boardFull ? "All \(Career.pitchBoardCapacity) pitch-board slots are occupied. Wait for a contract to expire.":"An existing sponsor contract must expire first."};store.save()}.disabled(d.accepted || boardFull)}.padding(15).background(.black.opacity(0.25),in:RoundedRectangle(cornerRadius:6))
            }}}
            Text(advertising ? "Pitch-board contracts and programme advertising are separate revenue sources. Active boards: \(store.career.acceptedPitchBoardCount)/\(Career.pitchBoardCapacity). Contracts expire after their stated term.":"Current partner: \(store.career.sponsor)").foregroundStyle(mint)
        }
    }
}
struct RetailScreen:View {
    @EnvironmentObject var store:GameStore
    var catering=false
    var body:some View {
        ClassicScreen(title:catering ? "Catering":"Merchandise") {
            HStack {Text("Item / outlet").frame(maxWidth:.infinity,alignment:.leading);Text("Cost").frame(width:70);Text("Price").frame(width:220);Text("Sold").frame(width:80);Text("Income").frame(width:100);Text("Profit").frame(width:100)}.foregroundStyle(mint)
            ForEach(store.career.managementState.products.filter{($0.outlet=="Catering")==catering}) {p in
                HStack {VStack(alignment:.leading){Text(p.name).bold();Text(p.outlet).foregroundStyle(muted)}.frame(maxWidth:.infinity,alignment:.leading);Text("£\(p.cost)").frame(width:70)
                    GameNumber(label:"£",value:Binding(get:{store.career.managementState.products.first{$0.id==p.id}?.price ?? p.price},set:{v in store.career.initializeManagement();if let i=store.career.management!.products.firstIndex(where:{$0.id==p.id}){store.career.management!.products[i].price=v;store.save()}}),range:0...100).frame(width:220)
                    Text("\(p.sold)").frame(width:80);Text(money(p.income)).frame(width:100);Text(money(p.profit)).frame(width:100)
                }.padding(8).background(.black.opacity(0.18))
            }
            Spacer();Text("Sales reflect attendance, open outlets and your prices. Figures show the last home match.").foregroundStyle(muted)
        }
    }
}
struct FinanceScreen:View {
    @EnvironmentObject var store:GameStore
    @ViewState var period="Previous period"
    var entries:[LedgerEntry] {store.career.ledger.filter{($0.season ?? store.career.season)==store.career.season && (period=="This season" || $0.week==(period=="Previous period" ? max(0,store.career.week-1):store.career.week))}}
    var operating:Int {entries.filter{e in !["Signed","Sold","Transfer","Loan","loan","interest","Deposit","deposit","flotation","grant"].contains(where:{e.description.contains($0)})}.reduce(0){$0+$1.amount}}
    var body:some View {
        ClassicScreen(title:"Finance & Accounts") {
            HStack {Text("Cash "+money(store.career.cash));Spacer();Text("Loans "+money(store.career.debt));Spacer();Text("Deposits "+money(store.career.managementState.deposit))}.foregroundStyle(mint).font(.title3)
            HStack {Button("Borrow £100,000") {result(store.career.bankBorrow(100000))};Button("Repay £100,000") {result(store.career.bankRepay(100000))};Button("Deposit £100,000") {result(store.career.bankDeposit(100000))};Button("Withdraw £100,000") {result(store.career.bankWithdraw(100000))}}
            HStack {Button("Arrange overdraft") {result(store.career.arrangeOverdraft())};Button("Apply for stadium grant") {result(store.career.applyForGrant())};Button("Go public") {result(store.career.floatCompany())}.disabled(store.career.financeState.publicCompany);Text("Overdraft: "+money(store.career.financeState.overdraftLimit)).foregroundStyle(mint)}
            HStack {GameChoice(label:"Accounts",value:$period,options:["Previous period","This period","This season"]);Text("Operating result: "+money(operating)).foregroundStyle(mint)}
            ScrollView {LazyVStack(spacing:2) {ForEach(entries) {e in HStack {Text("Week \(e.week+1)").frame(width:85);Text(e.description);Spacer();Text(money(e.amount)).foregroundStyle(e.amount<0 ? .white:mint)}.padding(7).background(.black.opacity(0.15))}}}
            Text("Loan limit depends on ground capacity and board confidence. Loan interest is charged weekly.").foregroundStyle(muted)
        }
    }
    func result(_ ok:Bool){if !ok {store.message="The bank cannot process this amount. Check funds, balances and borrowing limit."};store.save()}
}
struct TicketScreen:View {
    @EnvironmentObject var store:GameStore
    var body:some View {ClassicScreen(title:"Ticket Prices") {
        ForEach(["Terrace","Seats","Executive","Friendly","Cup","Season","School"],id:\.self) {kind in GameNumber(label:kind,value:Binding(get:{store.career.managementState.tickets[kind] ?? 20},set:{v in store.career.initializeManagement();store.career.management!.tickets[kind]=v;if kind=="Seats" {store.career.ticketPrice=v};store.save()}),range:1...1000).frame(maxWidth:650)}
        Spacer();Text("Prices affect demand and gate receipts. Season tickets are sold at the first league home match; cup and friendly admission is charged separately.").foregroundStyle(muted)
    }}}

struct FileFolderIcon:View {
    var body:some View {
        Canvas {context,size in
            let scale=min(size.width/64,size.height/40)
            context.translateBy(x:(size.width-64*scale)/2,y:(size.height-40*scale)/2)
            context.scaleBy(x:scale,y:scale)
            context.fill(Path(ellipseIn:CGRect(x:5,y:32,width:55,height:6)),with:.color(.black.opacity(0.5)))
            var back=Path()
            back.move(to:CGPoint(x:7,y:34))
            for point in [CGPoint(x:7,y:5),CGPoint(x:25,y:5),CGPoint(x:31,y:11),CGPoint(x:55,y:11),CGPoint(x:55,y:34)] {back.addLine(to:point)}
            back.closeSubpath()
            context.fill(back,with:.color(Color(red:0.87,green:0.57,blue:0.07)))
            context.stroke(back,with:.color(Color(red:1,green:0.86,blue:0.36)),lineWidth:1)
            var front=Path()
            front.move(to:CGPoint(x:7,y:34))
            for point in [CGPoint(x:12,y:15),CGPoint(x:60,y:15),CGPoint(x:54,y:34)] {front.addLine(to:point)}
            front.closeSubpath()
            context.fill(front,with:.linearGradient(Gradient(colors:[Color(red:1,green:0.9,blue:0.28),Color(red:0.96,green:0.66,blue:0.06)]),startPoint:CGPoint(x:0,y:15),endPoint:CGPoint(x:0,y:34)))
            context.stroke(front,with:.color(Color(red:1,green:0.92,blue:0.48)),lineWidth:1)
        }.background(.black.opacity(0.3)).overlay(Rectangle().stroke(chrome,lineWidth:1))
    }
}
struct GameDateTile:View {
    var season:Int,week:Int
    var date:Date {var calendar=Calendar(identifier:.gregorian);calendar.timeZone=TimeZone(secondsFromGMT:0)!;return calendar.date(byAdding:.day,value:week*7,to:calendar.date(from:DateComponents(year:1997+season,month:8,day:1))!)!}
    var month:String {let f=DateFormatter();f.locale=Locale(identifier:"en_US_POSIX");f.timeZone=TimeZone(secondsFromGMT:0);f.dateFormat="MMM";return f.string(from:date)}
    var day:String {let f=DateFormatter();f.timeZone=TimeZone(secondsFromGMT:0);f.dateFormat="dd";return f.string(from:date)}
    var body:some View {VStack(spacing:0){Text(month).textCase(.uppercase).foregroundStyle(crimson).font(.system(size:19,weight:.black,design:.serif));Text(day).font(.system(size:25,weight:.bold)).foregroundStyle(.black)}.frame(width:85,height:58).background(.white).overlay(Rectangle().stroke(chrome,lineWidth:2)).help("Season calendar: each current fixture round advances seven days")}
}
