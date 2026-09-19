import SwiftUI
import USMCore

struct TeletextPanel<Content:View>:View {
    var title:String
    var league:String
    @ViewBuilder var content:Content
    @EnvironmentObject var store:GameStore
    var body:some View {
        VStack(spacing:10) {
            HStack {Text("P\(100+(["League","Results","Top scorers","Form","Fixtures","Cups","Trophies","Friendlies"].firstIndex(of:title) ?? 0))").foregroundStyle(.yellow);Spacer();Text("SIERRATEXT").font(.system(size:25,weight:.black,design:.monospaced)).foregroundStyle(.cyan);Spacer();Text("W\(store.career.week+1)").foregroundStyle(.white)}
            Text(title.uppercased()).font(.system(size:18,weight:.bold,design:.monospaced)).foregroundStyle(.yellow).frame(maxWidth:.infinity).padding(6).background(Color.blue)
            VStack(alignment:.leading,spacing:8){content}.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)
            HStack {Text("FOOTBALL SERVICE").foregroundStyle(.cyan);Spacer();Button("EXIT") {store.page=store.room}.foregroundStyle(.yellow)}
        }.font(.system(size:13,weight:.bold,design:.monospaced)).foregroundStyle(.white).padding(18).background(.black,in:RoundedRectangle(cornerRadius:18)).padding(17).background(LinearGradient(colors:[Color(white:0.30),Color(white:0.08),Color(white:0.22)],startPoint:.topLeading,endPoint:.bottomTrailing)).overlay(RoundedRectangle(cornerRadius:12).stroke(.gray,lineWidth:3))
    }
}
