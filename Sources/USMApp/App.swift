import SwiftUI
import Combine
import AppKit
import AVFoundation
import USMCore

struct CareerSaveSummary:Identifiable {
    let id:String
    let url:URL
    let career:Career
}

enum DatabaseOption: String, CaseIterable, Identifiable {
    case originalCD
    case megaUpdate

    var id: String { rawValue }
    var title: String {
        switch self {
        case .originalCD: return "Original CD"
        case .megaUpdate: return "Mega Update 1.2"
        }
    }
    var detail: String {
        switch self {
        case .originalCD: return "Version 2.00 · 15 October 1998"
        case .megaUpdate: return "Squads through 31 January 2001"
        }
    }
    var resource: String { self == .originalCD ? "original-cd-database.json" : "database.json" }
}

@MainActor final class GameStore: ObservableObject {
    @Published var career: Career
    @Published var page = "Stadium"
    @Published var room = "Stadium"
    @Published var screen = "title"
    @Published var message: String?
    @Published var newCareer = false
    @Published var playingMusic = true
    @Published var soundEnabled = true
    @Published var matchRunning = false
    @Published var matchSpeed = 1.0
    var matchStepAccumulator=0.0
    @Published var matchChoice = false
    @Published var matchControls = false
    @Published var endOfSeasonShown = false
    @Published var matchCard:LiveEvent?
    private var matchCardExpiresAt=0.0
    @Published var hasSave = false
    let databases: [DatabaseOption: Database]
    @Published var selectedDatabase: DatabaseOption = .megaUpdate
    var database: Database { databases[selectedDatabase]! }
    let audio=GameAudio()
    let saveURL: URL
    var saveTicks=0
    var timer: Timer?
    init() {
        let resources=Bundle.module.url(forResource:"Resources",withExtension:nil)!
        do {
            databases=[
                .megaUpdate: try Database.load(resources.appendingPathComponent(DatabaseOption.megaUpdate.resource)),
                .originalCD: try Database.load(resources.appendingPathComponent(DatabaseOption.originalCD.resource))
            ]
        }
        catch { fatalError("Bundled database could not be loaded: \(error)") }
        let startingDatabase=databases[.megaUpdate]!
        let initial=startingDatabase.clubs.first{$0.name=="Arsenal"} ?? startingDatabase.clubs[0]
        career=Career(database:startingDatabase,clubID:initial.id,manager:"Manager")
        let qaProfile=Bundle.main.bundleIdentifier?.hasSuffix(".qa") == true ? Bundle.main.object(forInfoDictionaryKey:"QAProfile") as? String:nil
        saveURL=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent(qaProfile.map{"USM98Native-QA/\($0)/career.json"} ?? (Bundle.main.bundleIdentifier?.hasSuffix(".usability.layout.qa") == true ? "USM98Native-UsabilityQA/career.json":Bundle.main.bundleIdentifier?.hasSuffix(".audio.layout.qa") == true ? "USM98Native-AudioQA/career.json":(Bundle.main.bundleIdentifier?.hasSuffix(".layout.qa") == true ? "USM98Native-LayoutQA/career.json":(Bundle.main.bundleIdentifier?.hasSuffix(".qa") == true ? "USM98Native-QA/career.json":"USM98Native/career.json"))))
        hasSave = !savedCareerSummaries().isEmpty
        timer=Timer.scheduledTimer(withTimeInterval:1.0/30,repeats:true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        if Bundle.main.bundleIdentifier?.hasSuffix(".layout.qa") == true,let initialPage=Bundle.main.object(forInfoDictionaryKey:"QAInitialPage") as? String {
            if let saved=try? SaveStore.load(from:saveURL){career=saved;restoreDatabaseMetadata()}
            screen="club";room="Dressing room";page=initialPage;playingMusic=false;audio.musicEnabled=false
        }
        audio.startMusic()
    }
    func save() {
        do { try SaveStore.save(career,to:saveURL);hasSave=true }
        catch { message="Could not save: \(error.localizedDescription)" }
    }
    func savedCareerSummaries()->[CareerSaveSummary] {
        let urls=((try? FileManager.default.contentsOfDirectory(at:saveURL.deletingLastPathComponent(),includingPropertiesForKeys:nil)) ?? [])
            .filter{$0.pathExtension=="json"}
        return urls.compactMap { url in
            guard let career=try? SaveStore.load(from:url) else {return nil}
            return CareerSaveSummary(id:url.path,url:url,career:career)
        }.sorted { a,b in
            if a.career.season != b.career.season {return a.career.season > b.career.season}
            if a.career.week != b.career.week {return a.career.week > b.career.week}
            return a.url.lastPathComponent < b.url.lastPathComponent
        }
    }
    func loadCareer() {
        loadCareer(from:saveURL)
    }
    func loadCareer(from url:URL) {
        do { career=try SaveStore.load(from:url);restoreDatabaseMetadata();endOfSeasonShown=career.seasonFinished;save();screen=career.activeMatch == nil ? "club":"match";room="Stadium";page="Stadium";matchRunning=false;audio.play("fl_load");audio.matchAmbience(career.activeMatch != nil) }
        catch { message="Could not load career: \(error.localizedDescription)" }
    }
    func restoreDatabaseMetadata() {
        selectedDatabase = DatabaseOption.allCases.first { databases[$0]?.dataset == career.datasetName } ?? .megaUpdate
        career.initializeManagement()
        career.restorePlayerBirthDates(from:databases[selectedDatabase]!)
    }

    func navigate(_ target:String,sound:String?=nil) {
        if career.worldState.mode=="Coach" && ["Club business","Ticket office","Merchandise","Catering","Sponsors","Advertising","Stadium development"].contains(target) {message="The board handles club finances and development in Coach mode.";return}
        if let sound=sound {audio.play(sound)}
        page=target
    }
    func enter(_ destination:String) {
        room=destination;page=destination
        let sounds=["Stadium":"rm_stadium","Dressing room":"rm_squad","Manager’s office":"rm_manager","Boardroom":"rm_chairman","Business office":"rm_business","Transfer office":"rm_transfers"]
        if let name=sounds[destination] {audio.play(name,volume:0.35)}
    }
    func advance() {
        if career.worldState.dismissed {screen="club";room="Manager’s office";page="Jobs";message="The board has dismissed you. Apply for a new appointment to continue your career.";return}
        guard career.activeMatch == nil else {screen="match";return}
        if career.seasonFinished {endOfSeasonShown=true;return}
        if career.fixtures.contains(where:{!$0.played && $0.round==career.week && ($0.home==career.clubID || $0.away==career.clubID)}) {screen="matchTunnel"}
        else {career.advanceWeek();save();page="Inbox"}
    }

    func continueFromSeasonRecap() {
        career.nextSeason()
        endOfSeasonShown=false
        save()
    }
    func cancelMatchday() {
        matchChoice=false
        matchRunning=false
        // A match that has not kicked off is only a preview.  Do not leave it
        // suspended in the save when the manager cancels from the match console.
        if career.activeMatch?.phase == .ready { career.activeMatch=nil;audio.matchAmbience(false) }
        screen="club"
        enter("Dressing room")
    }
    func beginMatch(watch:Bool) {
        matchCard=nil
        guard let fixture=career.fixtures.first(where:{!$0.played && $0.round==career.week && ($0.home==career.clubID || $0.away==career.clubID)}) else {return}
        career.activeMatch=LiveMatch(career:career,fixture:fixture)
        matchChoice=false;screen="match";matchRunning=false;audio.matchAmbience(true)
        if !watch {career.activeMatch?.finishInstantly();audio.event("whistle")}
        save()
    }
    func toggleMatch() {
        guard var live=career.activeMatch,!live.isFinished else {return}
        if live.phase == .ready || live.phase == .halfTime {live.startHalf();career.activeMatch=live;audio.event("whistle");matchRunning=true}
        else {matchRunning.toggle()}
        if !matchRunning {audio.stopSpeech();save()}
    }
    func tick() {
        audio.setPlaybackSpeed(matchSpeed)
        audio.serviceCommentary()
        if matchCard != nil && ProcessInfo.processInfo.systemUptime>=matchCardExpiresAt {matchCard=nil}
        guard screen=="match",matchRunning,var live=career.activeMatch else {return}
        let count=live.events.count
        // 1x: 90 minutes in about four minutes. All speeds use identical 0.1 s steps.
        matchStepAccumulator += matchSpeed
        while matchStepAccumulator>=1 {
            let before=live.events.count
            live.step(0.1);matchStepAccumulator -= 1
            if let card=live.events.dropFirst(before).last(where:{$0.kind=="yellow" || $0.kind=="red"}) {
                matchCard=card;matchCardExpiresAt=ProcessInfo.processInfo.systemUptime+1.8
            }
        }
        for event in live.events.dropFirst(count) {audio.event(event.kind=="whistle" && (live.phase == .halfTime || live.isFinished) ? "end whistle":event.kind);audio.commentary(event.kind,name:event.playerID.flatMap{id in live.players.first{$0.id==id}?.name})}
        career.activeMatch=live
        if live.restartDelay>0 || live.phase == .halfTime || live.isFinished {matchCard=nil}
        if live.phase == .halfTime || live.isFinished {matchRunning=false;save()}
        saveTicks += 1
        if saveTicks>=450 {saveTicks=0;save()}
    }
    func finishMatch() {
        guard let live=career.activeMatch,live.isFinished,
              career.fixtures.contains(where:{$0.id==live.fixtureID && !$0.played}) else {return}
        career.advanceWeek(completedMatch:live);save();screen="club";room="Stadium";page="Stadium";matchRunning=false;audio.matchAmbience(false)
    }
    func instantRemainder() {
        guard career.activeMatch != nil else {return}
        matchRunning=false;audio.stopSpeech();career.activeMatch?.finishInstantly();audio.event("end whistle");save()
    }
    func title() {matchRunning=false;if screen != "title" {save()};screen="title";audio.matchAmbience(false)}
    func start(club:String,manager:String,cash:Int,mode:String="Manager") {
        if FileManager.default.fileExists(atPath:saveURL.path) {
            let backup=saveURL.deletingLastPathComponent().appendingPathComponent("career-\(UUID().uuidString).json")
            do {try FileManager.default.copyItem(at:saveURL,to:backup)} catch {message="Could not back up career: \(error.localizedDescription)";return}
        }
        career=Career(database:database,clubID:club,manager:manager,cash:cash,seed:UInt64.random(in:1...UInt64.max))
        career.initializeWorld();career.world!.mode=mode
        career.enableDomesticCups()
        newCareer=false;room="Stadium";page="Stadium";screen="club";save();audio.play("rm_stadium");audio.matchAmbience(false)
    }
    func toggleMusic() {playingMusic.toggle();audio.musicEnabled=playingMusic;if playingMusic {audio.startMusic()} else {audio.music?.stop()}}
    func toggleSound() {soundEnabled.toggle();audio.enabled=soundEnabled;if !soundEnabled {audio.stopSpeech();audio.crowd?.pause()}else if screen=="match" {audio.matchAmbience(true)}}
    func quit() {
        matchRunning=false
        if screen != "title" {save()}
        audio.stop()
        NSApp.terminate(nil)
    }
}
@main struct USMApp: App {
    @StateObject private var store=GameStore()
    var body: some Scene {
        WindowGroup("Ultimate Soccer Manager") {
            ContentView().environmentObject(store).frame(minWidth:1100,minHeight:720).preferredColorScheme(.dark)
        }.defaultSize(width:min(1440,NSScreen.main?.visibleFrame.width ?? 1440),height:min(920,NSScreen.main?.visibleFrame.height ?? 920)).windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing:.newItem) { Button("New Career…") { store.matchRunning=false;store.newCareer=true }.keyboardShortcut("n") }
            CommandGroup(after:.newItem) {
                Button("Save Career") { store.save() }.keyboardShortcut("s").disabled(store.screen == "title")
            }
        }
    }
}
let ink=Color(red:0.025,green:0.025,blue:0.08)
let panel=Color(red:0.16,green:0.16,blue:0.36)
let muted=Color(red:0.74,green:0.77,blue:0.85)
let mint=Color(red:1.0,green:0.88,blue:0.12)
func money(_ n:Int)->String { let v=abs(n);let sign=n<0 ? "−":"";return v>=1_000_000 ? String(format:"%@£%.2fm",sign,Double(v)/1_000_000):"\(sign)£\(v.formatted())" }
struct Card<Content:View>: View {
    var title: String
    @ViewBuilder var content: Content
    var body: some View { VStack(alignment:.leading,spacing:18) { if !title.isEmpty { Text(title.uppercased()).font(.system(size:11,weight:.bold,design:.monospaced)).tracking(1.5).foregroundStyle(muted) };content }.padding(12).frame(maxWidth:.infinity,alignment:.leading).background(panel,in:RoundedRectangle(cornerRadius:7)).overlay(RoundedRectangle(cornerRadius:7).stroke(.white.opacity(0.055))) }
}
struct AccentButton: ButtonStyle {
    func makeBody(configuration:Configuration)->some View {GameButton(red:true).makeBody(configuration:configuration)}
}
struct ClubMark: View {
    var name:String
    var large=false
    var body: some View { ZStack { RoundedRectangle(cornerRadius:large ? 18:8).fill(mint.opacity(0.12));Image(systemName:"shield.lefthalf.filled").font(.system(size:large ? 48:22)).foregroundStyle(mint);Text(String(name.prefix(1))).font(.system(size:large ? 20:10,weight:.black)).foregroundStyle(ink).offset(x:large ? -7:-3) }.frame(width:large ? 88:38,height:large ? 96:42) }
}

// Explicit alias selects the stable property wrapper on SDKs that also export a State macro.
typealias ViewState<Value> = SwiftUI.State<Value>
