import SwiftUI
import AppKit
import USMCore

struct ContentView: View {
    @EnvironmentObject var store:GameStore
    @ViewState private var toolbarVisible=false
    var body:some View {
        Group {
            if store.screen=="title" {TitleScreen()}
            else if store.screen=="matchTunnel" {MatchTunnelView()}
            else if store.screen=="match" {MatchView()}
            else {clubShell}
        }
        .background(ink).foregroundStyle(.white).tint(mint).buttonStyle(GameButton())
        .onAppear { CloseHandler.shared.store = store }
        .sheet(isPresented:$store.newCareer) {CareerSetup().classicSheet("New Career").environmentObject(store)}
        .overlay {
            if let message=store.message {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ClassicDialog(title:"Ultimate Soccer Manager") {
                        Text(message).font(.system(size:15,weight:.semibold)).padding(12)
                        Button("OK") {store.message=nil}.keyboardShortcut(.defaultAction).frame(maxWidth:.infinity).padding(8).classicRibbon()
                    }.frame(width:570)
                }
            }
        }
    }
    var toolbar:some View {
            HStack(spacing:4) {
                ribbonTile("FILE",title:"File") {FileFolderIcon()} action:{store.navigate("File")}
                ForEach([("Stadium","STAD"),("Business office","BUSI"),("Boardroom","CHAIR"),("Data","DATA"),("Transfer office","TRANS"),("Manager’s office","MNGR"),("Dressing room","SQUAD")],id:\.0) { title,label in
                    ribbonTile(label,title:title) {RoomArt(name:roomThumbnail(title))} action:{if title=="Data" {store.enter("Data")}else{store.enter(title)}}
                }
                ribbonTile("MATCH",title:"Matchday") {MatchTunnelIcon()} action:{store.advance()}
                ribbonTile("HELP",title:"Help") {Text("?").font(.system(size:34,weight:.black)).foregroundStyle(.yellow).frame(maxWidth:.infinity,maxHeight:.infinity).background(crimson)} action:{store.navigate("Help")}
                GameDateTile(season:store.career.season,week:store.career.week).padding(.leading,3)
            }.padding(.horizontal,12).padding(.top,28).padding(.bottom,9).background(LinearGradient(colors:[royal,Color(red:0.025,green:0.025,blue:0.20)],startPoint:.top,endPoint:.bottom))
    }
    var clubShell:some View {
        ZStack(alignment:.top) {
            clubContent.frame(maxWidth:.infinity,maxHeight:.infinity)
            toolbar
                .offset(y:toolbarVisible ? 0:-120)
                .allowsHitTesting(toolbarVisible)
                .accessibilityHidden(!toolbarVisible)
        }
        .clipped()
        .contentShape(Rectangle())
        .onReceive(Timer.publish(every:0.08,on:.main,in:.common).autoconnect()) {_ in
            let distance:CGFloat?
            if let window=NSApp.keyWindow,let content=window.contentView {
                let point=window.convertPoint(fromScreen:NSEvent.mouseLocation)
                let rect=content.convert(content.bounds,to:nil)
                distance=rect.contains(point) ? rect.maxY-point.y:nil
            } else {distance=nil}
            let visible=distance.map {$0 <= (toolbarVisible ? 128:160)} ?? false
            if visible != toolbarVisible {withAnimation(.easeInOut(duration:0.22)) {toolbarVisible=visible}}
        }
        .background(RightClickBack {if store.page != store.room {store.page=store.room}else if store.room != "Stadium" {store.enter("Stadium")}})
        .onExitCommand {store.page=store.room}
        .onDisappear {toolbarVisible=false}
    }
    @ViewBuilder var clubContent:some View {
            if store.page=="Stadium" || store.page=="Stadium development" {
                GroundManagementView()
            } else if ["Dressing room","Manager’s office","Boardroom","Business office","Transfer office","Data"].contains(store.page) {
                RoomView()
            } else {
                GeometryReader {geo in
                    ZStack {
                        Group {if store.room=="Stadium" {GroundManagementView()}else{RoomView()}}.allowsHitTesting(false)
                        Color.black.opacity(0.12).allowsHitTesting(false)
                        pageContent.frame(width:min(panelWidth,geo.size.width-64),height:min(panelHeight,geo.size.height-48)).background(panel).clipShape(RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(chrome,lineWidth:2)).shadow(color:.black.opacity(0.65),radius:18,y:8)
                    }.frame(maxWidth:.infinity,maxHeight:.infinity)
                }

            }
    }
    // Gameplay surfaces sit over the room rather than replacing it.  Keep the
    // room visible around every panel and let lists, not the whole panel, scroll.
    var panelWidth:CGFloat {switch store.page {case "File":return 720;case "Negotiations":return 840;case "Competitions","Trophies":return 900;case "Private phone":return 720;default:return 900}}
    var panelHeight:CGFloat {switch store.page {case "File":return 360;case "Private phone":return 420;case "Negotiations":return 500;default:return 520}}
    func ribbonTile<Content:View>(_ label:String,title:String,@ViewBuilder image:()->Content,action:@escaping()->Void)->some View {
        Button(action:action) {VStack(spacing:4){Text(label).font(.system(size:12,weight:.black)).foregroundStyle(mint);image().frame(width:60,height:38).clipped().allowsHitTesting(false).overlay(Rectangle().stroke(chrome.opacity(0.7),lineWidth:1))}.frame(minWidth:0,maxWidth:.infinity).padding(5).background(store.page==title ? crimson:.white.opacity(0.035),in:RoundedRectangle(cornerRadius:3))}.buttonStyle(.plain).frame(minWidth:0,maxWidth:.infinity).help(title)
    }
    func roomThumbnail(_ title:String)->String {
        switch title {
        case "Stadium":return "stadium-estate"
        case "Dressing room":return "locker-room"
        case "Boardroom":return "boardroom"
        case "Business office":return "business-office"
        case "Transfer office":return "transfer-office"
        case "Data":return "data-room"
        default:return "manager-office"
        }
    }
    @ViewBuilder var pageContent:some View {
        switch store.page {
        case "File":FileScreen()
        case "Help":HelpScreen()
        case "Squad":SquadView()
        case "Tactics":TeamTalkScreen()
        case "Formation editor":FormationEditorScreen()
        case "Advanced tactics":FormationEditorScreen(advanced:true)
        case "Team training":ProgrammeScreen()
        case "Individual training":PersonalTrainingScreen()
        case "Coaching staff":StaffScreen()
        case "Transfers":PlayerSearchScreen()
        case "Shortlist":PlayerSearchScreen(shortlist:true)
        case "Negotiations":NegotiationScreen()
        case "Sponsors":CommercialScreen()
        case "Advertising":CommercialScreen(advertising:true)
        case "Competitions":CompetitionScreen()
        case "Club business":FinanceScreen()
        case "Ticket office":TicketScreen()
        case "Merchandise":RetailScreen()
        case "Catering":RetailScreen(catering:true)
        case "Stadium development":GroundManagementView()
        case "Inbox":MessageScreen()
        case "Opposition":OppositionScreen()
        case "Private phone":PrivatePhoneScreen()
        case "Jobs":JobsScreen()
        case "Match report":MatchReportView()
        case "Board review":EvaluationScreen()
        case "Medical room":MedicalScreen()
        case "Trophies":CompetitionScreen(initialTab:"Trophies")
        default:ArchiveView()
        }
    }
}
struct RoomArt:View {
    var name:String
    var body:some View {
        if let url=Bundle.module.url(forResource:name,withExtension:"png",subdirectory:"Resources/Rooms"),let image=NSImage(contentsOf:url) {Image(nsImage:image).resizable().interpolation(.high).scaledToFit()}
    }
}
struct TitleScreen:View {
    @EnvironmentObject var store:GameStore
    var body:some View {
        GeometryReader { geo in
            ZStack {
                RoomArt(name:"stadium-estate").frame(width:geo.size.width,height:geo.size.height).scaleEffect(1.14)
                LinearGradient(colors:[.black.opacity(0.85),.black.opacity(0.4),.black.opacity(0.16)],startPoint:.leading,endPoint:.trailing)
                VStack(alignment:.leading,spacing:24) {
                    Spacer()
                    Text("THE BEAUTIFUL GAME. YOUR CLUB.").font(.system(size:11,weight:.bold,design:.monospaced)).tracking(3).foregroundStyle(mint)
                    VStack(alignment:.leading,spacing:0) {Text("ULTIMATE").font(.system(size:54,weight:.black));Text("SOCCER MANAGER").font(.system(size:35,weight:.black));Text("98 / 99").font(.system(size:82,weight:.black,design:.rounded)).foregroundStyle(mint)}.shadow(color:.black.opacity(0.5),radius:12,y:4)
                    Text("A season to remember.").font(.system(size:23,weight:.medium,design:.serif)).foregroundStyle(.white.opacity(0.85))
                    VStack(spacing:10) {
                        titleButton("New game","Start your managerial career",icon:"plus") {store.newCareer=true}
                        titleButton("Load game",store.hasSave ? "Continue your saved career":"Choose a saved career file",icon:"folder") {if store.hasSave {store.loadCareer()} else {store.importSave()}}
                        titleButton("Import saved game","Open an exported native career",icon:"square.and.arrow.down") {store.importSave()}
                    }.frame(width:360).padding(.top,12)
                    HStack(spacing:24) {Button(store.playingMusic ? "♫  Music on":"♫  Music off") {store.toggleMusic()};Button("Quit") {NSApp.terminate(nil)}}.buttonStyle(.plain).font(.system(size:12)).foregroundStyle(.white.opacity(0.7)).padding(.top,8)
                    Spacer()
                    Text("MEGA UPDATE 1.2  •  31 JAN 2001 SQUADS  •  NATIVE macOS").font(.system(size:9,weight:.bold,design:.monospaced)).tracking(1.5).foregroundStyle(.white.opacity(0.55))
                }.padding(.leading,76).padding(.vertical,38).frame(maxWidth:.infinity,alignment:.leading)
            }.clipped()
        }
    }
    func titleButton(_ title:String,_ detail:String,icon:String,action:@escaping()->Void)->some View {
        Button(action:action) {HStack(spacing:17) {Image(systemName:icon).font(.system(size:20)).foregroundStyle(mint).frame(width:25);VStack(alignment:.leading,spacing:4) {Text(title).font(.system(size:18,weight:.semibold));Text(detail).font(.system(size:10)).foregroundStyle(.white.opacity(0.6))};Spacer();Image(systemName:"chevron.right").font(.system(size:10))}.padding(16).background(.black.opacity(0.45),in:RoundedRectangle(cornerRadius:6)).overlay(RoundedRectangle(cornerRadius:6).stroke(.white.opacity(0.2)))}.buttonStyle(.plain)
    }
}
struct CareerSetup:View {
    @EnvironmentObject var store:GameStore
    @ViewState var step=0
    @ViewState var manager=""
    @ViewState var country="England"
    @ViewState var division=0
    @ViewState var club=""
    @ViewState var cash=8_000_000
    @ViewState var mode="Manager"
    var choices:[Club] {store.database.clubs.filter{$0.country==country && $0.division==division}.sorted{$0.name<$1.name}}
    var selected:Club? {store.database.clubs.first{$0.id==club}}
    var body:some View {
        VStack(alignment:.leading,spacing:16) {
            HStack {Text("NEW GAME").font(.system(size:11,weight:.black)).tracking(2).foregroundStyle(mint);Spacer();Text("\(step+1) / 4").font(.system(size:12,design:.monospaced)).foregroundStyle(muted)}
            HStack(spacing:6) {ForEach(0..<4,id:\.self) {n in Rectangle().fill(n<=step ? mint:.white.opacity(0.12)).frame(height:3)}}
            Text(["Choose your database.","Welcome, manager.","Choose your league.","Take the hot seat.","Your season starts here."][step]).font(.system(size:32,weight:.bold,design:.serif))
            VStack(alignment:.leading,spacing:16) {
                switch step {
                case 0:
                    Text("Choose the player, team and transfer database for this career. A private working copy is created in the new save, so later changes stay inside this career.").foregroundStyle(muted)
                    ForEach(DatabaseOption.allCases) { option in
                        let db=store.databases[option]!
                        Button { store.selectedDatabase=option } label: {
                            HStack(spacing:14) {
                                Image(systemName: option == .originalCD ? "opticaldisc" : "arrow.down.doc").font(.system(size:22)).foregroundStyle(mint).frame(width:30)
                                VStack(alignment:.leading,spacing:4) { Text(option.title).font(.system(size:17,weight:.semibold)); Text(option.detail).font(.system(size:11)).foregroundStyle(muted); Text("\(db.clubs.count) clubs · \(db.players.count) players").font(.system(size:11,design:.monospaced)).foregroundStyle(.white.opacity(0.7)) }
                                Spacer(); if store.selectedDatabase == option { Image(systemName:"checkmark.circle.fill").foregroundStyle(mint) }
                            }.padding(14).background(store.selectedDatabase == option ? mint.opacity(0.13):.white.opacity(0.035),in:RoundedRectangle(cornerRadius:6))
                        }.buttonStyle(.plain)
                    }
                case 1:
                    Text("Enter your name. The chairman is expecting you.").foregroundStyle(muted)
                    TextField("First and last name",text:$manager).textFieldStyle(.roundedBorder).font(.system(size:18)).padding(.vertical,20)
                    Text("Full manager career: pick the team, shape the tactics, sign players and run the club.").font(.system(size:12)).foregroundStyle(muted)
                case 2:
                    GameChoice(label:"Country",value:$country,options:Array(Set(store.database.clubs.map(\.country))).sorted()).onChange(of:country) {_,_ in division=0;club=""}
                    GameChoice(label:"Division",value:Binding(get:{String(division+1)},set:{division=(Int($0) ?? 1)-1}),options:Array(Set(store.database.clubs.filter{$0.country==country}.map{String($0.division+1)})).sorted())
                    Text("All countries continue alongside your league. This career uses the \(store.selectedDatabase.title) database.").font(.system(size:12)).foregroundStyle(muted)
                case 3:
                    ScrollView {LazyVStack(spacing:5) {ForEach(choices) {c in Button {club=c.id} label: {HStack {Text(c.name).font(.system(size:15,weight:.semibold));Spacer();Text(c.stadium).font(.system(size:11)).foregroundStyle(muted);if club==c.id {Image(systemName:"checkmark.circle.fill").foregroundStyle(mint)}}.padding(13).background(club==c.id ? mint.opacity(0.13):.white.opacity(0.035),in:RoundedRectangle(cornerRadius:6))}.buttonStyle(.plain)}}}.frame(maxHeight:.infinity)
                default:
                    Text(selected?.name ?? "Your club").font(.system(size:25,weight:.bold)).foregroundStyle(mint)
                    Text("\(manager)\n\(selected?.stadium ?? "") · \(country), Division \(division+1)").font(.system(size:15)).lineSpacing(8)
                    GameChoice(label:"Starting funds",value:Binding(get:{String(cash/1_000_000)+" million"},set:{cash=(Int($0.components(separatedBy:" ")[0]) ?? 8)*1_000_000}),options:["2 million","8 million","20 million"])
                    GameChoice(label:"Role",value:$mode,options:["Manager","Coach"])
                    Text("The board wants a top-half finish. Your first stop is the stadium: enter the dressing room to meet the squad, then head down the tunnel for matchday.").font(.system(size:12)).foregroundStyle(muted)
                }
            }.frame(maxWidth:.infinity,alignment:.topLeading).frame(height:230,alignment:.topLeading)
            HStack {Button(step==0 ? "Cancel":"Back") {if step==0 {store.newCareer=false} else {step -= 1}};Spacer();Button(step==4 ? "BEGIN CAREER  →":"CONTINUE  →") {if step==4 {store.start(club:club,manager:manager.trimmingCharacters(in:.whitespaces),cash:cash,mode:mode)} else {step += 1;if step==3 {club=choices.first?.id ?? ""}}}.buttonStyle(AccentButton()).disabled((step==1 && manager.trimmingCharacters(in:.whitespaces).isEmpty) || (step==3 && selected==nil))}
        }.padding(24).frame(width:620,height:570).background(ink).preferredColorScheme(.dark)
    }
}
struct Metric:View {
    var title:String;var value:String;var note:String;var icon:String
    var body:some View {Card(title:title) {HStack {Text(value).font(.system(size:27,weight:.semibold,design:.rounded));Spacer();Image(systemName:icon).font(.system(size:19)).foregroundStyle(mint)};Text(note).font(.system(size:11)).foregroundStyle(muted)}}
}
struct InboxView:View {
    @EnvironmentObject var store:GameStore
    var body:some View {ForEach(store.career.news) {n in Card(title:"\(n.category) · WEEK \(n.week+1)") {Text(n.title).font(.system(size:20,weight:.semibold));Text(n.body).font(.system(size:13)).foregroundStyle(muted).fixedSize(horizontal:false,vertical:true)}}}
}

final class CloseHandler: NSObject, NSWindowDelegate {
    static let shared = CloseHandler()
    weak var store: GameStore?
    func observeWindow() {
        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            window.delegate = self
        }
    }
    func windowWillClose(_ notification: Notification) {
        store?.matchRunning = false
        store?.save()
        store?.audio.stop()
    }
}
