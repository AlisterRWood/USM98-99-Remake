import Foundation

// Native reconstruction rules. Original labels/names are evidenced; economy and
// response probabilities are explicitly calibrated remake rules, not recovered code.
public struct StaffMember: Codable, Identifiable {
    public var id:String, name:String, speciality:String
    public var quality:Int, wage:Int, employed:Bool, weeksRemaining:Int
    public init(id:String,name:String,speciality:String,quality:Int,wage:Int) {
        self.id=id;self.name=name;self.speciality=speciality;self.quality=quality;self.wage=wage;employed=false;weeksRemaining=104
    }
}
public struct TrainingAssignment:Codable {public var coachID:String;public var skill:Int;public var intensity:Int;public init(coachID:String,skill:Int,intensity:Int=1){self.coachID=coachID;self.skill=skill;self.intensity=intensity}}
public struct ScoutReport:Codable,Identifiable {
    public var id:String {playerID}
    public var playerID:String, scoutID:String, text:String
    public var due:Int, low:Int, high:Int
}
public struct Negotiation:Codable,Identifiable {
    public var id=UUID().uuidString
    public var playerID:String, clubID:String, stage:String, reply:String
    public var fee:Int, wage:Int, signingFee:Int, years:Int, due:Int, expires:Int
    public var selling:Bool, loanWeeks:Int
    public var appearanceFee:Int?
    public var appearanceCount:Int?
    public var swapPlayer:String?
    public var bonuses:ContractBonuses?
    public var attempts:Int?
    /// The management-week in which a failed or withdrawn negotiation closed.
    /// Keeping this optional preserves compatibility with existing career saves.
    public var closedWeek:Int?
    public init(player:Player,week:Int,selling:Bool=false,loanWeeks:Int=0) {
        playerID=player.id;clubID=player.clubID;stage="Enquiry sent";reply="Awaiting club response";fee=loanWeeks>0 ? player.value/20:player.value;wage=player.wage;signingFee=player.wage*4;years=3;due=week+1;expires=week+6;self.selling=selling;self.loanWeeks=loanWeeks
    }
    public var closed:Bool {["Completed","Withdrawn","Rejected","Expired"].contains(stage)}
}
public struct PlayerLoan:Codable {public var playerID:String,ownerID:String;public var returnWeek:Int}
public struct CommercialDeal:Codable,Identifiable {
    public var id:String,brand:String,kind:String
    public var weekly:Int,term:Int,remaining:Int
    public var accepted:Bool
    public init(id:String,brand:String,kind:String,weekly:Int,term:Int){self.id=id;self.brand=brand;self.kind=kind;self.weekly=weekly;self.term=term;remaining=term;accepted=false}
}
public struct ShopProduct:Codable,Identifiable {
    public var id:String {name}
    public var name:String, outlet:String
    public var cost:Int,price:Int,sold:Int=0,income:Int=0,profit:Int=0
    public init(_ name:String,_ outlet:String,_ cost:Int,_ price:Int){self.name=name;self.outlet=outlet;self.cost=cost;self.price=price}
}
public struct ManagementState:Codable {
    public var schema=1
    public var staff:[StaffMember]=[]
    public var timetable=["Fitness","Passing","Defending","Attacking","Individual","Free time","Passing","Fitness","Set pieces","Individual","Match","Match","Free time","Free time"]
    public var assignments:[String:TrainingAssignment]=[:]
    public var shortlist:[String]=[]
    public var scouts:[ScoutReport]=[]
    public var negotiations:[Negotiation]=[]
    public var loans:[PlayerLoan]=[]
    public var obligations:[TransferObligation]?
    public var playerBonuses:[String:ContractBonuses]?
    public var listed:[String:Int]=[:]
    public var loanListed:[String:Int]?
    public var savedFormations:[SavedFormation]?
    // Source roster transcribed from the original CD's ADVERT.DAT.  The modern
    // renderer uses the names as crisp vector-style marks rather than scaling
    // the low-resolution DOS sprite sheet.
    public var deals:[CommercialDeal]=[
        .init(id:"s1",brand:"Samsung",kind:"Club sponsor",weekly:20000,term:52),
        .init(id:"s2",brand:"Nationwide",kind:"Club sponsor",weekly:32000,term:104),
        .init(id:"s3",brand:"Puma",kind:"Club sponsor",weekly:42000,term:156),
        .init(id:"a1",brand:"Lotus",kind:"Pitch boards",weekly:1200,term:26),
        .init(id:"a2",brand:"Avis",kind:"Pitch boards",weekly:1800,term:52),
        .init(id:"a3",brand:"Impressions",kind:"Programme",weekly:900,term:26),
        .init(id:"a4",brand:"Brother",kind:"Pitch boards",weekly:1500,term:26),
        .init(id:"a5",brand:"Budweiser",kind:"Pitch boards",weekly:2200,term:52),
        .init(id:"a6",brand:"Kappa",kind:"Pitch boards",weekly:1700,term:26),
        .init(id:"a7",brand:"Portakabin",kind:"Pitch boards",weekly:1300,term:26),
        .init(id:"a8",brand:"Lowenbräu",kind:"Pitch boards",weekly:1900,term:52),
        .init(id:"a9",brand:"Mitre",kind:"Pitch boards",weekly:1600,term:52),
        .init(id:"a10",brand:"Caterpillar",kind:"Pitch boards",weekly:1900,term:52),
        .init(id:"a11",brand:"Green Flag",kind:"Pitch boards",weekly:1400,term:26),
        .init(id:"a12",brand:"Greene King",kind:"Pitch boards",weekly:1800,term:52),
        .init(id:"a13",brand:"Canon",kind:"Pitch boards",weekly:2400,term:52),
        .init(id:"a14",brand:"Pentax",kind:"Pitch boards",weekly:1800,term:26),
        .init(id:"a15",brand:"Prudential",kind:"Pitch boards",weekly:2100,term:52),
        .init(id:"a16",brand:"Nikon",kind:"Pitch boards",weekly:2000,term:52),
        .init(id:"a17",brand:"Goal",kind:"Pitch boards",weekly:1100,term:26),
        .init(id:"a18",brand:"Sierra",kind:"Pitch boards",weekly:1200,term:26),
        .init(id:"a19",brand:"Dynamix",kind:"Pitch boards",weekly:1100,term:26),
        .init(id:"a20",brand:"Basics",kind:"Programme",weekly:800,term:26)]
    public var products:[ShopProduct]=[.init("Programmes","Stalls",1,2),.init("Badges","Stalls",1,2),.init("Pens","Stalls",1,2),.init("Flags","Shops",2,4),.init("Hats","Shops",3,6),.init("Shirts","Shops",12,25),.init("Burgers","Catering",1,3),.init("Tea","Catering",1,2),.init("Meals","Catering",3,7)]
    public var tickets:[String:Int]=["Terrace":12,"Seats":20,"Executive":55,"Friendly":10,"Cup":20,"Season":300,"School":5]
    public var deposit=0
    public var unread:[String]=[]
    public var scrapbook:[String]=[]
    public var captain:String?
    public var takers:[String:String]=[:]
    public var winBonus=0
    public var campWeeks=0
    public var campKind="Leisure"
    public var elapsed=0
    public init() {
        let names=["Page", "Edwards", "Brett", "Purple", "Ashby", "Muffett", "Long", "Snelling", "Thompson", "Powell", "Stringer", "Smith", "Pond", "Hume", "Spurr", "Quinton", "Johnson", "Dunnett", "Beale", "Harrison", "Fair", "Seaman", "Knowles", "Sanders", "Todd", "Wilson", "Ward", "Forster", "Clarke", "Hartley", "Almond", "Sutton", "Short", "Webb", "Elvin", "Stocker", "Buxton", "Mann", "Eales", "Proctor", "Lodge", "Carver", "Grant", "Vernon", "Jacobs", "Wibble", "Williams", "Blonde", "Roache", "Tunns", "Ross", "Coleman", "Taylor", "Church", "Lincoln", "Oxborough", "Reader", "Savage", "Trail", "Martin", "Hudson", "Irwin", "Tait", "Dowell", "Rouse", "Summers", "Bird", "Turner", "Richards", "Norman", "Cheney", "Daniels", "Evans", "Morris", "Rose", "Benson", "Lane", "Morley", "Pitman", "Tuck", "Watson", "Chisholm", "King", "Emmerson", "Eagle", "Franke", "Hammer", "March", "Ives", "Oldfield", "Major", "Perry", "Sayer", "Brown", "Staff", "Townsend", "Grice", "Herbert", "Leach", "Hood", "Carroll", "Tidman", "Spear", "Sexton", "Joyce", "Gillham", "Eaton", "Barth", "Ashton", "Payne", "Henman", "Smyth", "Watts", "Partridge", "Goodwin", "Filby", "Muir", "Craddock", "Hillier", "Stubbs", "White", "Knight", "Geary", "Copeland", "Boyle", "Christy", "Mead", "Glover", "Berry", "Allen", "Innes", "Lilley", "Frost", "Randell", "Thorne", "Jordon", "Hardy", "Bingham", "Barclay", "Skinner", "Wheeler", "Sansom", "Marshall", "Fuller", "Lister", "Crowe", "Nixon", "Hall", "Denton", "Whatling", "Lewis", "Boon", "Robins", "Tipple", "Dyson", "Dye", "Carey", "Wright", "Shreeve", "Adams", "Dixon", "Selley", "Reid", "Callow", "Snell", "Ellis", "Boast", "Stanton", "Jewell", "Towers", "Bidwell", "Fields", "Winters", "Cork", "Clough", "Bough", "Moss", "Mace", "Way", "Graves", "Oakley", "Hoskins", "Rye", "Beavis", "McCluskey", "Plant", "Southgate", "Kettle", "Riches"]
        let skills=["Keeping","Defending","Passing","Shooting","Fitness","Scout"]
        for (i,name) in names.enumerated(){staff.append(.init(id:"staff-\(i)",name:name,speciality:skills[i%6],quality:45+(i*13)%50,wage:150+(i*37)%650))}
    }
}
public extension Career {
    var managementState:ManagementState {management ?? ManagementState()}
    mutating func initializeManagement(){
        // Keep pre-commercial-overhaul saves compatible: new original-CD board
        // offers appear without disturbing an accepted contract or its term.
        if management != nil {
            let known=Set(management!.deals.map(\.id))
            management!.deals += ManagementState().deals.filter{!known.contains($0.id)}
            return
        }
        var value=ManagementState();value.tickets["Seats"]=ticketPrice
        if let i=value.products.firstIndex(where:{$0.name=="Shirts"}){value.products[i].price=merchandisePrice}
        let legacyCoaches=Array(value.staff.indices.filter{value.staff[$0].speciality != "Scout"}.prefix(min(6,coachingLevel ?? 0)))
        for i in legacyCoaches {value.staff[i].employed=true}
        let focuses=["Keeping":0,"Defending":1,"Passing":2,"Finishing":3,"Fitness":6]
        for (id,focus) in individualTraining ?? [:] {if let skill=focuses[focus]{value.assignments[id]=TrainingAssignment(coachID:legacyCoaches.first.map{value.staff[$0].id} ?? "",skill:skill,intensity:intensity=="Intense" ? 2:1)}}
        if training != "Balanced" {let activity=training=="Finishing" ? "Attacking":(training=="Recovery" ? "Free time":training);for slot in 0..<10 {value.timetable[slot]=activity}}
        management=value
    }
    @discardableResult mutating func hireStaff(_ id:String)->Bool {
        initializeManagement();guard let i=management!.staff.firstIndex(where:{$0.id==id}),!management!.staff[i].employed else{return false}
        let s=management!.staff[i];let group=management!.staff.filter{$0.employed && (($0.speciality=="Scout") == (s.speciality=="Scout"))}
        guard group.count<(s.speciality=="Scout" ? 3:6),cash>=s.wage*4 else{return false}
        management!.staff[i].employed=true;management!.staff[i].weeksRemaining=104
        transact("Appointment: \(s.name)",-s.wage*4);return true
    }
    @discardableResult mutating func dismissStaff(_ id:String)->Bool {
        initializeManagement();guard let i=management!.staff.firstIndex(where:{$0.id==id && $0.employed}) else{return false}
        let s=management!.staff[i],pay=s.wage*min(12,s.weeksRemaining);guard cash>=pay else{return false}
        transact("Contract settlement: \(s.name)",-pay);management!.staff[i].employed=false
        management!.assignments=management!.assignments.filter{$0.value.coachID != id};return true
    }
    @discardableResult mutating func renewStaff(_ id:String)->Bool {
        initializeManagement();guard let i=management!.staff.firstIndex(where:{$0.id==id && $0.employed}) else{return false}
        management!.staff[i].weeksRemaining=104;management!.staff[i].wage=management!.staff[i].wage*110/100;return true
    }
    mutating func setTraining(slot:Int,activity:String){initializeManagement();guard (0..<14).contains(slot),slot/2 != 5 else{return};management!.timetable[slot]=activity}
    @discardableResult mutating func bookCamp(kind:String,weeks:Int)->Bool {
        initializeManagement();let cost=squad.count*300*weeks;guard (1...4).contains(weeks),management!.campWeeks==0,cash>=cost else{return false}
        management!.campWeeks=weeks;management!.campKind=kind;transact("\(kind) training camp",-cost);return true
    }
    mutating func toggleShortlist(_ id:String){initializeManagement();if management!.shortlist.contains(id){management!.shortlist.removeAll{$0==id}}else if players.contains(where:{$0.id==id && $0.clubID != clubID}){management!.shortlist.append(id)}}
    @discardableResult mutating func scoutPlayer(_ id:String)->Bool {
        initializeManagement();guard let p=players.first(where:{$0.id==id}),let s=management!.staff.filter({$0.employed && $0.speciality=="Scout"}).min(by:{a,b in management!.scouts.filter{$0.scoutID==a.id && $0.due>management!.elapsed}.count<management!.scouts.filter{$0.scoutID==b.id && $0.due>management!.elapsed}.count}) else{return false}
        management!.scouts.removeAll{$0.playerID==id};management!.scouts.append(ScoutReport(playerID:id,scoutID:s.id,text:"Assignment in progress",due:management!.elapsed+2,low:max(0,p.rating-15),high:min(99,p.rating+15)));return true
    }
    @discardableResult mutating func enquire(_ id:String,loanWeeks:Int=0)->Bool {
        initializeManagement();guard let p=players.first(where:{$0.id==id}),p.clubID != clubID,!management!.negotiations.contains(where:{$0.playerID==id && !$0.closed}) else{return false}
        var n=Negotiation(player:p,week:management!.elapsed,loanWeeks:loanWeeks);n.fee=askingPrice(p,loan:loanWeeks>0);management!.negotiations.append(n);return true
    }
    @discardableResult mutating func submitTerms(_ id:String,fee:Int,wage:Int,bonus:Int,years:Int)->Bool {
        initializeManagement();guard let i=management!.negotiations.firstIndex(where:{$0.id==id}),["Club asking price","Club counter offer","Player terms","Player counter offer"].contains(management!.negotiations[i].stage),fee>=0,wage>0,bonus>=0,(1...5).contains(years) else{return false}
        let clubStage=management!.negotiations[i].stage.hasPrefix("Club")
        management!.negotiations[i].attempts=(management!.negotiations[i].attempts ?? 0)+1
        if clubStage {management!.negotiations[i].fee=fee};management!.negotiations[i].wage=wage;management!.negotiations[i].signingFee=bonus;management!.negotiations[i].years=years
        management!.negotiations[i].stage=clubStage ? "Club considering":"Player considering";management!.negotiations[i].reply="Offer submitted. Await a reply.";management!.negotiations[i].due=management!.elapsed+1;management!.negotiations[i].expires=management!.elapsed+6;return true
    }
    /// Resolve only this conversation; no fixtures, training or finances advance.
    @discardableResult mutating func reviewNegotiationReply(_ id:String,immediate:Bool=true)->Bool {
        initializeManagement();guard let i=management!.negotiations.firstIndex(where:{$0.id==id}),!management!.negotiations[i].closed else{return false}
        let n=management!.negotiations[i],now=management!.elapsed
        if n.expires<now {management!.negotiations[i].stage="Expired";management!.negotiations[i].closedWeek=now;return false}
        guard (immediate || n.due<=now),let p=players.first(where:{$0.id==n.playerID}),["Enquiry sent","Club considering","Player considering"].contains(n.stage) else{return false}
            var stage=n.stage,reply=n.reply
            switch stage {
            case "Enquiry sent":
                let ownQuality=squad.map(\.rating).reduce(0,+)/max(1,squad.count)
                if p.rating>ownQuality+25 {stage="Rejected";reply="The club will not discuss a move to your level.";break}
                stage="Club asking price";reply="The club will discuss a fee of £\(n.fee.formatted()). Submit your offer."
            case "Club considering":
                let swapValue=n.swapPlayer.flatMap{id in squad.first{$0.id==id}?.value} ?? 0
                let total=n.fee+(n.appearanceFee ?? 0)*80/100+swapValue*80/100
                if (n.attempts ?? 0)>5 {stage="Rejected";reply="Negotiations ended after repeated unsuccessful offers."}
                else if total >= askingPrice(p,loan:n.loanWeeks>0) {stage="Player terms";reply="Club agreement reached. The player seeks £\(p.wage.formatted()) per week and a signing fee of £\((p.wage*4).formatted())."}
                else {stage="Club counter offer";reply="Your fee is too low. The club asks £\(askingPrice(p,loan:n.loanWeeks>0).formatted())."}
            case "Player considering":
                if n.wage+(n.bonuses?.win ?? 0)/2>=p.wage && n.signingFee>=p.wage*2 {stage="Final review";reply="All parties agree. Review the full cost and accept or withdraw. No money moves until you accept."}
                else {stage="Player counter offer";reply="The player requests £\(p.wage.formatted()) per week and a signing fee of at least £\((p.wage*2).formatted())."}
            default:return false
            }
            management!.negotiations[i].stage=stage;management!.negotiations[i].reply=reply;management!.negotiations[i].due=now+1
            if ["Rejected","Expired","Withdrawn"].contains(stage) {management!.negotiations[i].closedWeek=now}
            post("NEGOTIATIONS",p.name+": "+stage,reply)
        management!.negotiations[i].expires=now+6
        return true
    }
    mutating func withdrawNegotiation(_ id:String){initializeManagement();guard let i=management!.negotiations.firstIndex(where:{$0.id==id && !$0.closed}) else{return};management!.negotiations[i].stage="Withdrawn";management!.negotiations[i].closedWeek=management!.elapsed}
    @discardableResult mutating func acceptTransfer(_ id:String)->Bool {
        initializeManagement();guard activeMatch==nil,let n=management!.negotiations.firstIndex(where:{$0.id==id}),management!.negotiations[n].stage=="Final review",let p=players.firstIndex(where:{$0.id==management!.negotiations[n].playerID}) else{return false}
        let offer=management!.negotiations[n],player=players[p]
        if offer.selling {
            guard canRelease(player.id) else{return false}
            if offer.loanWeeks>0 {management!.loans.append(PlayerLoan(playerID:player.id,ownerID:clubID,returnWeek:management!.elapsed+offer.loanWeeks))}
            players[p].clubID=offer.clubID;transact("\(offer.loanWeeks>0 ? "Loaned":"Sold") \(player.name)",offer.fee);clearDepartingPlayer(player.id);autoSelect()
        }else{
            guard player.clubID==offer.clubID,cash>=offer.fee+offer.signingFee else{return false}
            if let swap=offer.swapPlayer {
                guard let index=players.firstIndex(where:{$0.id==swap && $0.clubID==clubID}),squad.count>16,states[swap]?.injuryWeeks==0 else{return false}
                players[index].clubID=offer.clubID;lineup.removeAll{$0==swap};autoSelect()
            }
            if let fee=offer.appearanceFee,fee>0 {
                if management!.obligations==nil{management!.obligations=[]}
                management!.obligations!.append(TransferObligation(playerID:player.id,creditor:offer.clubID,appearances:0,threshold:offer.appearanceCount ?? 10,fee:fee))
            }
            if management!.playerBonuses==nil{management!.playerBonuses=[:]};management!.playerBonuses?[player.id]=offer.bonuses
            if offer.loanWeeks>0 {management!.loans.append(PlayerLoan(playerID:player.id,ownerID:player.clubID,returnWeek:management!.elapsed+offer.loanWeeks))}
            players[p].clubID=clubID;states[player.id]?.wage=offer.wage;states[player.id]?.contractYears=offer.years
            transact("Signed \(player.name)",-(offer.fee+offer.signingFee))
        }
        management!.shortlist.removeAll{$0==player.id};management!.negotiations[n].stage="Completed";management!.negotiations[n].reply="Agreement signed. The squad, contract and club accounts have been updated.";post("TRANSFER","Transfer completed: \(player.name)","The agreement has been signed following your final approval.");return true
    }
    @discardableResult mutating func acceptDeal(_ id:String)->Bool {
        initializeManagement();guard let i=management!.deals.firstIndex(where:{$0.id==id}),!management!.deals[i].accepted else{return false}
        let kind=management!.deals[i].kind
        guard kind != "Club sponsor" || !management!.deals.contains(where:{$0.kind==kind && $0.accepted}) else{return false}
        management!.deals[i].accepted=true;management!.deals[i].remaining=management!.deals[i].term
        if kind=="Club sponsor" {sponsor=management!.deals[i].brand;sponsorship=0}
        return true
    }
    @discardableResult mutating func bankDeposit(_ amount:Int)->Bool {initializeManagement();guard amount>0,cash>=amount else{return false};management!.deposit+=amount;transact("Deposit with bank",-amount);return true}
    @discardableResult mutating func bankWithdraw(_ amount:Int)->Bool {initializeManagement();guard amount>0,management!.deposit>=amount else{return false};management!.deposit-=amount;transact("Withdrawal from deposit",amount);return true}
    @discardableResult mutating func bankBorrow(_ amount:Int)->Bool {guard amount>0,amount<=max(0,capacity*100-debt),confidence>=35 else{return false};debt+=amount;transact("Bank loan",amount);return true}
    @discardableResult mutating func bankRepay(_ amount:Int)->Bool {guard amount>0,cash>=amount,debt>=amount else{return false};debt-=amount;transact("Loan repayment",-amount);return true}
    mutating func retailMatchday(attendance:Int){
        initializeManagement();for i in management!.products.indices {
            let product=management!.products[i];let outlets=groundBuildings.filter{!$0.isBuilding && (product.outlet=="Catering" ? ["Café","Burger bar","Restaurant"].contains($0.kind):["Shop","Small shop","Large shop","Programme stall"].contains($0.kind))}.reduce(0){$0+max(1,$1.level)}
            let demand=max(0.0,0.22-Double(max(0,product.price-product.cost*2))*0.015)
            let sold=Int(Double(attendance)*demand*Double(min(3,outlets))/3)
            management!.products[i].sold=sold;management!.products[i].income=sold*product.price;management!.products[i].profit=sold*(product.price-product.cost)
            if sold>0 {transact("\(product.name) sales",sold*product.price);transact("\(product.name) supplies",-sold*product.cost)}
        }
    }
    mutating func progressManagement(){
        initializeManagement();management!.elapsed+=1;let now=management!.elapsed
        // Failed and withdrawn negotiations are useful for the week in which
        // they close, but should not permanently clog the current list.
        // Older saves have no close week, so start their one-week grace period
        // the first time they are progressed.
        for i in management!.negotiations.indices where ["Withdrawn","Rejected","Expired"].contains(management!.negotiations[i].stage) && management!.negotiations[i].closedWeek==nil {management!.negotiations[i].closedWeek=now}
        management!.negotiations.removeAll { negotiation in
            guard ["Withdrawn","Rejected","Expired"].contains(negotiation.stage),let closedWeek=negotiation.closedWeek else{return false}
            return closedWeek<now
        }
        for i in management!.staff.indices where management!.staff[i].employed {
            let s=management!.staff[i];transact("Wages: \(s.name)",-s.wage);management!.staff[i].weeksRemaining-=1
            if management!.staff[i].weeksRemaining<=0 {management!.staff[i].employed=false;post("STAFF","\(s.name) contract expired","Visit coaching staff to offer a new contract.")}
        }
        for i in management!.deals.indices where management!.deals[i].accepted {
            let d=management!.deals[i];transact("\(d.kind): \(d.brand)",d.weekly);management!.deals[i].remaining-=1
            if management!.deals[i].remaining<=0 {management!.deals[i].accepted=false;post("BUSINESS","\(d.brand) contract expired","Review new commercial offers.")}
        }
        if management!.deposit>0 {let interest=management!.deposit/1000;management!.deposit+=interest}
        for i in management!.scouts.indices where management!.scouts[i].due==now {
            let report=management!.scouts[i];guard let p=players.first(where:{$0.id==report.playerID}),let s=management!.staff.first(where:{$0.id==report.scoutID && $0.employed}) else{continue}
            let error=max(2,(100-s.quality)/5);management!.scouts[i].low=max(0,p.rating-error);management!.scouts[i].high=min(99,p.rating+error);management!.scouts[i].text="\(s.name): estimated ability \(max(0,p.rating-error))–\(min(99,p.rating+error)). Strongest skill: \(p.skills.max() ?? 0)."
            if (p.age(season:season) ?? 27)<21,let d=p.development {let peak=d.ceilings.max() ?? p.rating;management!.scouts[i].text += " Youth assessment: strongest skill could reach \(max(p.skills.max() ?? 0,peak-error))–\(min(99,peak+error)) with sustained development; not guaranteed."}
            post("SCOUTING","Report on \(p.name)",management!.scouts[i].text)
        }
        for id in management!.negotiations.map(\.id) {_=reviewNegotiationReply(id,immediate:false)}
        for (id,price) in management!.listed.sorted(by:{$0.key<$1.key}) {
            guard let p=squad.first(where:{$0.id==id}),!management!.negotiations.contains(where:{$0.playerID==id && !$0.closed}),rng.unit()<0.35*min(1,Double(p.value)/Double(max(1,price))) else{continue}
            let buyers=clubs.filter{$0.id != clubID && $0.country==club.country};guard !buyers.isEmpty else{continue};let buyer=buyers[rng.int(0...buyers.count-1)]
            var offer=Negotiation(player:p,week:now,selling:true);offer.clubID=buyer.id;offer.fee=price;offer.stage="Final review";offer.reply="\(buyer.name) offer £\(offer.fee.formatted()). Player is willing to discuss the move. Accept or reject.";management!.negotiations.append(offer)
        }
        for (id,weeks) in (management!.loanListed ?? [:]).sorted(by:{$0.key<$1.key}) {
            guard let p=squad.first(where:{$0.id==id}),canRelease(id),!management!.negotiations.contains(where:{$0.playerID==id && !$0.closed}),rng.unit()<0.35 else{continue}
            let buyers=clubs.filter{$0.id != clubID && $0.country==club.country};guard !buyers.isEmpty else{continue}
            let buyer=buyers[rng.int(0...buyers.count-1)]
            var offer=Negotiation(player:p,week:now,selling:true,loanWeeks:weeks);offer.clubID=buyer.id;offer.fee=0;offer.signingFee=0;offer.stage="Final review";offer.reply="\(buyer.name) request a \(weeks)-week loan and will pay the player's wages. Accept or withdraw.";management!.negotiations.append(offer)
            post("NEGOTIATIONS","Loan offer: \(p.name)",offer.reply)
        }
        for loan in management!.loans where loan.returnWeek<=now {
            if let i=players.firstIndex(where:{$0.id==loan.playerID}) {players[i].clubID=loan.ownerID;lineup.removeAll{$0==loan.playerID};post("TRANSFER","Loan ended",players[i].name+" has returned to "+name(loan.ownerID))}
        }
        management!.loans.removeAll{$0.returnWeek<=now};if lineup.count<11 {autoSelect()}
        initializeGround()
        for i in ground!.indices where ground![i].kind=="Stand" && !ground![i].isBuilding {
            var spec=ground![i].specification ?? StandSpecification();spec.condition=max(0,spec.condition-1);ground![i].specification=spec
        }
        trainProgramme()
    }
    private mutating func trainProgramme(){
        guard let m=management else{return}
        let sessions=m.timetable.filter{$0 != "Match" && $0 != "Free time"}.count
        let focus=["Keeping":0,"Defending":1,"Passing":2,"Attacking":3,"Fitness":6,"Set pieces":7]
        for i in players.indices where players[i].clubID==clubID && states[players[i].id]?.injuryWeeks==0 {
            let id=players[i].id,assignment=m.assignments[id],coach=m.staff.first{$0.id==assignment?.coachID && $0.employed}
            let workload=m.assignments.values.filter{$0.coachID==coach?.id}.count
            let skill=assignment?.skill ?? focus[m.timetable[rng.int(0...13)]] ?? rng.int(1...8)
            let quality=(coach?.trainingEffectiveness(skill:skill) ?? 0.2)/max(1,Double(workload)/10)
            let amount=assignment?.intensity ?? 1
            let age=players[i].age(season:season) ?? 27
            let development=age<23 ? 1.4:(age>31 ? 0.5:1.0)
            if rng.unit()<(Double(sessions)*0.012+quality*0.15*Double(amount)+(m.campWeeks>0 && m.campKind=="Intensive" ? 0.15:0))*development {
                if (0..<9).contains(skill){developPlayer(at:i,skill:skill,effort:1.5)}
            }
            let fitness=states[id]?.fitness ?? 100
            states[id]?.fitness=min(100,max(20,fitness+((12-sessions)*2)-(amount-1)*5+(m.campWeeks>0 ? (m.campKind=="Leisure" ? 8:-4):0)))
            if amount==3 && rng.unit()<0.02 {states[id]?.injuryWeeks=1}
        }
        if management!.campWeeks>0 {management!.campWeeks-=1}
    }
}
