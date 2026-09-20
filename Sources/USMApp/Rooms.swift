import SwiftUI
import AppKit
import USMCore

struct RoomHotspot:Identifiable {
    var id:String {title}
    let title:String
    let detail:String
    let rect:CGRect
    let target:String
    let sound:String
    var entersRoom=false
}

struct BusinessOfficeCommercialOverlay:View {
    @EnvironmentObject var store:GameStore
    let width:Double
    let height:Double
    let left:Double
    let top:Double

    var sponsor:String? {
        store.career.managementState.deals.first { $0.kind == "Club sponsor" && $0.accepted }?.brand
    }
    var advertisingAvailable:Bool {
        store.career.managementState.deals.contains { deal in
            guard !deal.accepted,deal.kind != "Club sponsor" else { return false }
            return deal.kind != "Pitch boards" || store.career.acceptedPitchBoardCount < Career.pitchBoardCapacity
        }
    }

    var body:some View {
        TimelineView(.animation(minimumInterval:0.55)) { timeline in
            let pulse = advertisingAvailable && Int(timeline.date.timeIntervalSince1970 * 2).isMultiple(of:2)
            ZStack(alignment:.topLeading) {
                if advertisingAvailable {
                    RoundedRectangle(cornerRadius:5)
                        .fill(Color(red:0.22,green:0.03,blue:0.035).opacity(0.9))
                        .overlay(RoundedRectangle(cornerRadius:5).stroke(Color.red.opacity(pulse ? 0.95:0.45),lineWidth:2))
                        .overlay {
                            HStack(spacing:5) {
                                ForEach(0..<11,id:\.self) { _ in
                                    Circle().fill(pulse ? Color.orange:.red).frame(width:5,height:5).shadow(color:.red,radius:pulse ? 5:1)
                                }
                            }
                        }
                        .frame(width:width*0.235,height:height*0.085)
                        .position(x:width*0.5025,y:height*0.3075)
                        .shadow(color:.red.opacity(pulse ? 0.42:0.15),radius:pulse ? 12:4)
                }
                if let sponsor {
                    SponsorWindowLogo(brand:sponsor)
                        .frame(width:width*0.115,height:height*0.135)
                        .rotationEffect(.degrees(-4.2))
                        .position(x:width*0.771,y:height*0.46)
                }
            }
            .frame(width:width,height:height)
            .position(x:left+width/2,y:top+height/2)
            .allowsHitTesting(false)
        }
    }
}

struct SponsorWindowLogo:View {
    let brand:String

    var colors:[Color] {
        switch brand.lowercased() {
        case "samsung": return [Color(red:0.02,green:0.16,blue:0.52),Color(red:0.07,green:0.38,blue:0.83)]
        case "nationwide": return [Color(red:0.02,green:0.25,blue:0.55),Color(red:0.08,green:0.48,blue:0.78)]
        case "puma": return [.black,Color(red:0.22,green:0.22,blue:0.24)]
        default: return [royal,crimson]
        }
    }

    var body:some View {
        VStack(spacing:5) {
            Circle().fill(.white.opacity(0.9)).frame(width:24,height:24).overlay {
                Image(systemName:"sportscourt.fill").font(.system(size:12,weight:.black)).foregroundStyle(colors[0])
            }
            Text(brand.uppercased()).font(.system(size:15,weight:.black,design:.rounded)).minimumScaleFactor(0.55).lineLimit(1)
            Text("OFFICIAL PARTNER").font(.system(size:5,weight:.bold,design:.monospaced)).tracking(0.8)
        }
        .foregroundStyle(.white)
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .background(LinearGradient(colors:colors,startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:3))
        .overlay(RoundedRectangle(cornerRadius:3).stroke(.white.opacity(0.85),lineWidth:1))
        .shadow(color:.black.opacity(0.35),radius:4,y:2)
    }
}

struct RoomView:View {
    @EnvironmentObject var store:GameStore
    @ViewState var hovered:String?
    var room:String {store.room}
    var art:String {
        switch room {
        case "Stadium":return "stadium-estate"
        case "Dressing room":return "locker-room"
        case "Boardroom":return "boardroom"
        case "Business office":return "business-office"
        case "Transfer office":return "transfer-office"
        case "Data":return "data-room"
        default:return "manager-office"
        }
    }
    func spot(_ title:String,_ detail:String,_ x:Double,_ y:Double,_ w:Double,_ h:Double,_ target:String,_ sound:String,_ enters:Bool=false)->RoomHotspot {
        RoomHotspot(title:title,detail:detail,rect:CGRect(x:x,y:y,width:w,height:h),target:target,sound:sound,entersRoom:enters)
    }
    var spots:[RoomHotspot] {
        switch room {
        case "Stadium":return [
            spot("Boardroom","Meet the chairman and review your objectives",0.07,0.075,0.20,0.17,"Boardroom","rm_chairman",true),
            spot("Manager’s office","Messages, fixtures and results",0.44,0.05,0.13,0.10,"Manager’s office","rm_manager",true),
            spot("Training ground","Set the team’s training programme",0.64,0.015,0.20,0.16,"Team training","sq_teamtraining"),
            spot("Dressing room","Meet the squad and prepare for matchday",0.81,0.34,0.11,0.18,"Dressing room","rm_squad",true),
            spot("Club shop","Merchandise pricing and matchday retail",0.025,0.52,0.15,0.15,"Merchandise","bs_merchandise"),
            spot("Business office","Accounts, ticket prices and sponsorship",0.04,0.30,0.12,0.19,"Business office","rm_business",true),
            spot("Club café","Catering and matchday business",0.83,0.58,0.16,0.17,"Catering","bs_catering"),
            spot("The pitch","Enter the dressing room",0.31,0.31,0.40,0.20,"Dressing room","rm_squad",true),
            spot("Stadium development","Expand the ground and club facilities",0.31,0.535,0.43,0.095,"Stadium development","st_stadium")]
        case "Dressing room":return [
            spot("Squad selection","Choose the eleven shirts for your next match",0.045,0.17,0.12,0.25,"Squad","sq_teamselect"),
            spot("Tactics blackboard","Formation, mentality, passing and tackling",0.195,0.16,0.215,0.285,"Tactics","sq_chalk"),
            spot("Individual training","Assign a personal development focus",0.495,0.53,0.115,0.41,"Individual training","sq_indtraining"),
            spot("Team training","Set the weekly programme for the squad",0.70,0.55,0.22,0.33,"Team training","sq_teamtraining"),
            spot("Coaching vacancies","Hire coaches to improve player development",0.155,0.53,0.18,0.22,"Coaching staff","sq_newspaper"),
            spot("Formation editor","Arrange player positions",0.72,0.23,0.15,0.20,"Formation editor","sq_chalk"),
            spot("Opposition report","Study the next opponents",0.83,0.025,0.15,0.19,"Opposition","sq_viewopposition"),
            spot("Advanced tactics","Edit positioning for each phase",0.23,0.46,0.16,0.065,"Advanced tactics","sq_chalk"),
            spot("Medical room","Check injuries and recovery",0.93,0.285,0.06,0.14,"Medical room","sq_firstaid"),
            spot("The tunnel","Choose to watch the match or take an instant result",0.455,0.205,0.19,0.29,"matchday","sq_tunnel")]
        case "Boardroom":return [
            spot("Performance graphs","Review manager ratings",0.09,0.05,0.22,0.31,"Board review","ch_averageprogress"),
            spot("Chairman’s objectives","Read the chairman’s expectations",0.325,0.09,0.13,0.24,"Board review","ch_averageprogress"),
            spot("Trophy cabinet","Competition honours and club history",0.845,0.07,0.15,0.60,"Trophies","ch_trophy"),
            spot("Accounts folder","Review club finances",0.35,0.51,0.105,0.06,"Club business","bs_accounts")]
        case "Business office":return [
            spot("Accounts","Open the club’s accounts",0.38,0.49,0.075,0.27,"Club business","bs_accounts"),
            spot("Tickets","Set admission prices",0.45,0.64,0.19,0.15,"Ticket office","bs_ticketprice"),
            spot("Sponsorship board","Negotiate a commercial partnership",0.70,0.36,0.145,0.22,"Sponsors","bs_sponsor"),
            spot("Advertising LED board","Sell pitch boards and programme advertising",0.385,0.265,0.235,0.085,"Advertising","bs_sponsor"),
            spot("Joe’s Burgers","Review food prices and takings",0.005,0.43,0.275,0.43,"Catering","bs_catering"),
            spot("Club shop","Price the club’s merchandise",0.475,0.465,0.15,0.15,"Merchandise","bs_merchandise")]
        case "Transfer office":return [
            spot("Team photo","Open squad team selection",0.535,0.125,0.16,0.17,"Squad","sq_teamselect"),
            spot("Binoculars","Search for players to buy or loan",0.58,0.43,0.12,0.23,"Transfers","tr_search"),
            spot("Current negotiations","Read replies and complete player deals",0.34,0.78,0.51,0.215,"Negotiations","tr_currentnegs"),
            spot("Short list","Track transfer targets and scouting reports",0.145,0.485,0.17,0.26,"Shortlist","tr_search"),
            spot("Sell players","Review your squad for transfer or fast sale",0.695,0.32,0.065,0.16,"Squad","tr_sell"),
            spot("Loan players out","View player records to set loan availability",0.315,0.34,0.15,0.11,"Squad","tr_sell")]
        case "Data":return [spot("Sierratext television","Tables, results, top scorers and fixtures",0.31,0.14,0.38,0.48,"Competitions","mg_fixturelist"),spot("Printer","Save and manage your career",0.005,0.37,0.205,0.32,"File","mg_fixturelist"),spot("Video recorder","Review the last match",0.34,0.70,0.33,0.14,"Matchreport","mg_fixturelist")]
        default:return [
            spot("Laptop · email","Read external correspondence",0.71,0.47,0.12,0.23,"Inbox","mg_email"),
            spot("Fixture list","Fixtures and results",0.205,0.008,0.125,0.28,"Competitions","mg_fixturelist"),
            spot("Telephone · voicemail","Read internal messages",0.245,0.68,0.145,0.12,"Inbox","mg_vmail"),
            spot("Private mobile","Private calls and bookmaker",0.22,0.845,0.105,0.085,"Private phone","mg_mobile"),
            spot("Sports pages","Read the latest match report",0.30,0.735,0.30,0.20,"Match report","mg_newspaper"),
            spot("Filing cabinet","Player records and club archive",0.017,0.265,0.185,0.54,"Archive","mg_filing"),
            spot("Sierratext TV","Tables, results and top scorers",0.40,0.29,0.135,0.17,"Competitions","mg_fixturelist"),
            spot("Team photo","Open squad team selection",0.625,0.04,0.125,0.17,"Squad","sq_teamselect"),
            spot("Scrapbook","Your club history",0.53,0.66,0.14,0.10,"Archive","mg_filing"),
            spot("Video player","Review the latest match",0.42,0.49,0.11,0.065,"Match report","mg_newspaper"),
            spot("Printer","File and print options",0.215,0.37,0.125,0.155,"File","mg_filing")]

        }
    }
    var body:some View {
        VStack(spacing:0) {
            GeometryReader { geo in
                let width=min(geo.size.width,geo.size.height*16/9)
                let height=width*9/16
                let left=(geo.size.width-width)/2,top=(geo.size.height-height)/2
                ZStack(alignment:.topLeading) {
                    Color.black
                    RoomArt(name:art).frame(width:width,height:height).position(x:geo.size.width/2,y:geo.size.height/2)
                    if room == "Business office" {
                        BusinessOfficeCommercialOverlay(width: width, height: height, left: left, top: top)
                    }
                    ForEach(spots) {s in
                        Button {if s.target=="matchday" {store.audio.play(s.sound);store.advance()} else if s.entersRoom {store.enter(s.target)} else {store.navigate(s.target,sound:s.sound)}} label: {
                            ZStack(alignment:.bottom) {
                                RoundedRectangle(cornerRadius:8).fill(mint.opacity(hovered==s.title ? 0.12:0.001)).overlay(RoundedRectangle(cornerRadius:8).stroke(mint.opacity(hovered==s.title ? 0.9:0),lineWidth:2))
                                if hovered==s.title {
                                    VStack(alignment:.leading,spacing:2) {
                                        Text(s.title).font(.system(size:12,weight:.bold))
                                        Text(s.detail).font(.system(size:10)).foregroundStyle(.white.opacity(0.82)).lineLimit(2)
                                    }.foregroundStyle(.white).padding(.horizontal,12).padding(.vertical,7).frame(maxWidth:240,alignment:.leading).background(Color(red:0.42,green:0.07,blue:0.055),in:RoundedRectangle(cornerRadius:4)).offset(y:9)
                                }
                            }.frame(width:s.rect.width*width,height:s.rect.height*height).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityLabel(s.title).help(s.detail)
                        .frame(width:s.rect.width*width,height:s.rect.height*height)
                        .onHover {inside in if inside {hovered=s.title;NSCursor.pointingHand.push()} else {if hovered==s.title {hovered=nil};NSCursor.pop()}}
                        .position(x:left+s.rect.midX*width,y:top+s.rect.midY*height)
                    }
                }
            }
        }
    }
}
