import SwiftUI
import USMCore
struct PlayerRecord:View {
    @EnvironmentObject var store:GameStore
    @Environment(\.dismiss) var dismiss
    var player:Player
    @ViewState var market=false
    @ViewState var asking=0
    @ViewState var loanWeeks=12
    @ViewState var confirmSale=false
    @ViewState var marketNotice=""
    let labels=["Keeping","Tackling","Passing","Shooting","Pace","Heading","Stamina","Set pieces","Control"]
    var body:some View {
        VStack(spacing:15) {
            Text(player.name).font(.system(size:28,weight:.bold)).foregroundStyle(mint)
            Text(store.career.name(player.clubID)+" · "+player.position+" · Age "+(player.age(season:store.career.season).map(String.init) ?? "Unknown")).foregroundStyle(muted)
            Text("Born "+player.dateOfBirth+((player.development?.estimatedBirthDate ?? false) ? " (estimated)":"")+" · "+player.potentialDescription).font(.caption).foregroundStyle(mint)
            if !market {LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:3),spacing:15) {ForEach(0..<9,id:\.self) {i in VStack(alignment:.leading){HStack{Text(labels[i]);Spacer();Text("\(player.skills[i])").foregroundStyle(mint)};GeometryReader {g in ZStack(alignment:.leading){Rectangle().fill(.black.opacity(0.4));Rectangle().fill(crimson).frame(width:g.size.width*Double(player.skills[i])/100)}}.frame(height:8)}.padding(10).background(.black.opacity(0.15))}}
            } else {marketControls}
            let state=store.career.states[player.id]
            HStack {Text("Value "+money(player.value));Spacer();Text("Wage "+money(state?.wage ?? player.wage)+" / week");Spacer();Text("Contract \(state?.contractYears ?? 0) years")}
            HStack {Text("Fitness \(state?.fitness ?? 100)%");Spacer();Text("Morale \(state?.morale ?? 75)%");Spacer();Text("Goals \(state?.goals ?? 0)")}
            Spacer()
            HStack {if player.clubID==store.career.clubID {Button(market ? "Skills":"Transfer / loan") {market.toggle();asking=store.career.managementState.listed[player.id] ?? player.value};Button("Discuss new contract") {if store.career.enquireRenewal(player.id){store.save();store.page="Negotiations";dismiss()}}}else{Button(store.career.managementState.shortlist.contains(player.id) ? "Remove shortlist":"Shortlist") {store.career.toggleShortlist(player.id);store.save()};Button("Approach club") {if store.career.enquire(player.id){store.save();store.page="Negotiations";dismiss()}}};Spacer();Button("Return") {dismiss()}}
        }.padding(22).frame(width:760,height:470).background(panel).background(RightClickBack {dismiss()}).buttonStyle(GameButton()).classicSheet("Player Record")
    }
    var marketControls:some View {
        VStack(alignment:.leading,spacing:10) {
            Text("Transfer market · valuation "+money(player.value)).foregroundStyle(mint)
            HStack {GameNumber(label:"Asking price £",value:$asking,range:1...999_999_999,step:10000);Button("List for transfer") {if store.career.listPlayer(player.id,askingPrice:asking){marketNotice="Transfer listed at "+money(asking);store.save()}}}
            HStack {GameNumber(label:"Loan weeks",value:$loanWeeks,range:4...52,step:4);Button("List for loan") {if store.career.listPlayerForLoan(player.id,weeks:loanWeeks){marketNotice="Available for a \(loanWeeks)-week loan";store.save()}};Button("Remove listing") {store.career.unlistPlayer(player.id);marketNotice="Removed from the market";store.save()}}
            HStack {Text("Fast sale: "+money(store.career.fastSaleValue(player.id))+" now (60% of value)");Spacer();Button(confirmSale ? "Confirm sale":"Fast sell") {if confirmSale {if store.career.fastSell(player.id){store.save();dismiss()}}else{confirmSale=true}};if confirmSale{Button("Cancel"){confirmSale=false}}}
            Text(marketNotice.isEmpty ? listingDescription:marketNotice).font(.caption).foregroundStyle(mint)
            if !store.career.canRelease(player.id){Text("Cannot release during a match, sell a borrowed player, or leave fewer than 16 players.").font(.caption)}
        }.disabled(!store.career.canRelease(player.id))
    }
    var listingDescription:String {
        if let price=store.career.managementState.listed[player.id]{return "Transfer listed: "+money(price)}
        if let weeks=store.career.managementState.loanListed?[player.id]{return "Loan listed: \(weeks) weeks"}
        return "Not listed. Offers arrive in Current Negotiations; you decide whether to accept."
    }
}
