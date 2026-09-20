import SwiftUI
import AppKit
import USMCore
struct FileScreen:View {
    @EnvironmentObject var store:GameStore
    @ViewState var slotName="My career"
    @ViewState var slots:[URL]=[]
    var body:some View {ClassicScreen(title:"File & Options") {
        HStack {Button("Save current career") {store.save();refresh()}.help("Save the current career to its native autosave");Button("New game") {store.newCareer=true}.help("Start another career");Button("Main menu") {store.title()}.help("Return to the title screen");Button("Quit") {store.quit()}.help("Save and close the application")}
        HStack {TextField("Save name",text:$slotName).textFieldStyle(.plain).padding(7).background(.black.opacity(0.3));Button("Save named slot") {saveSlot()}}
        Text("Saved careers").foregroundStyle(mint)
        ScrollView {LazyVStack {ForEach(slots,id:\.path) {url in HStack {Text(url.deletingPathExtension().lastPathComponent).lineLimit(1);Spacer();Button("Load") {do {let c=try SaveStore.load(from:url);store.career=c;store.restoreDatabaseMetadata();store.save();store.screen=c.activeMatch==nil ? "club":"match";store.page="Stadium";store.room="Stadium";store.matchRunning=false}catch{store.message=error.localizedDescription}}}.padding(7).background(.black.opacity(0.2))}}}
        HStack {Button(store.playingMusic ? "Music: ON":"Music: OFF") {store.toggleMusic()};Button(store.soundEnabled ? "Sound: ON":"Sound: OFF") {store.toggleSound()};Button("Manual") {store.page="Help"};Button("Print club summary") {printSummary()}}
    }.onAppear{refresh()}}
    func refresh(){slots=((try? FileManager.default.contentsOfDirectory(at:store.saveURL.deletingLastPathComponent(),includingPropertiesForKeys:nil)) ?? []).filter{$0.pathExtension=="json"}.sorted{$0.lastPathComponent<$1.lastPathComponent}}
    func saveSlot(){let safe=slotName.components(separatedBy:CharacterSet.alphanumerics.inverted).filter{!$0.isEmpty}.joined(separator:"-");guard !safe.isEmpty else{return};let url=store.saveURL.deletingLastPathComponent().appendingPathComponent(safe+"-"+String(UUID().uuidString.prefix(6))+".json");do{try SaveStore.save(store.career,to:url);refresh()}catch{store.message=error.localizedDescription}}
    func printSummary(){let text=NSTextView(frame:NSRect(x:0,y:0,width:550,height:700));text.string="\(store.career.club.name)\n\(store.career.manager) · \(store.career.dateLabel)\nCash: \(money(store.career.cash))\n\n"+store.career.orderedSquad.map{"\($0.name)  \($0.position)  \($0.rating)"}.joined(separator:"\n");text.font=NSFont.monospacedSystemFont(ofSize:12,weight:.regular);let printInfo=NSPrintInfo.shared;let op=NSPrintOperation(view:text,printInfo:printInfo);op.run()}
}
struct HelpScreen:View {
    @ViewState var topic="Getting started"
    let chapters=["Getting started","Rooms","Team selection","Training","Transfers","Commercial","Ground development","Matchday","Saving"]
    let text:[String:String]=[
        "Getting started":"Choose New game from the title screen. Enter your name, choose a country, division and club, then your starting funds. You control the whole club.",
        "Rooms":"Use the room thumbnails along the top or click buildings at your stadium. Hover over objects for a description. Show hotspots reveals every room destination.",
        "Team selection":"Right-click a player to carry their name. Left-click another player to swap their squad positions. Escape cancels. Double-click for their player record. The first eleven start, followed by the match bench and reserves.",
        "Training":"Click a morning or afternoon cell to change its session. Match sessions are locked. Hire named coaches and assign them to individual players and skills. Higher intensity increases development but also fatigue and injury risk. Scouts prepare reports after two periods.",
        "Transfers":"Search by name, position, league, division, age, value, contract and skill. Shortlist or scout a player, then enquire about a transfer or loan. Club and player replies arrive as time advances. Send terms, including wages, bonuses, appearance clauses and a player exchange. An agreement always requires your final acceptance.",
        "Commercial":"The business office has separate accounts, tickets, sponsors, advertising, catering and merchandise screens. Contracts credit income each period. Product prices influence demand and profit. Cash is needed to honour transfers, wages and construction commitments.",
        "Ground development":"Click a stand to inspect it. Choose capacity and boxes, review the cost, then commission construction. Closed stands cannot sell tickets. Corner stands need their adjacent stands. Place shops, catering and other facilities on vacant plots; completed buildings can be moved and rotated.",
        "Matchday":"Choose Watch match or Instant result. Both use the same match engine. Pause to adjust tactics and register substitutions. Changes enter at the next stoppage. Change speed at any time, including 1.5×. Replay uses recorded positions. Continue after full-time to commit the result and advance the calendar.",
        "Saving":"The game saves automatically after changes and matches. File offers named save slots and load. New careers back up your previous current save. You can save a match in progress and resume it paused."]
    var body:some View {VStack(spacing:15){Text("Ultimate Soccer Manager · Help").font(.title.bold()).foregroundStyle(mint);HStack {VStack {ForEach(chapters,id:\.self){c in Button(c){topic=c}.buttonStyle(GameButton(red:topic==c))};Spacer()}.frame(width:190);Text(text[topic] ?? "").font(.system(size:17)).lineSpacing(9).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading).padding(20).background(panel)} }.padding(25)}
}
