import SwiftUI
import AppKit

// A local event monitor does not cover the view or swallow ordinary left-clicks.
struct RightClickBack:NSViewRepresentable {
    var back:()->Void
    final class Host:NSView {
        var back:(()->Void)?
        var monitor:Any?
        override func viewDidMoveToWindow(){
            super.viewDidMoveToWindow()
            if let monitor{NSEvent.removeMonitor(monitor);self.monitor=nil}
            guard window != nil else{return}
            monitor=NSEvent.addLocalMonitorForEvents(matching:.rightMouseDown){[weak self] event in
                guard let self,let window=self.window,event.window===window,window.attachedSheet==nil,let content=window.contentView else{return event}
                var hit=content.hitTest(content.convert(event.locationInWindow,from:nil))
                while let view=hit {
                    if let table=view as? SelectionTable {
                        let point=table.convert(event.locationInWindow,from:nil)
                        if table.row(at:point)>=0,table.column(at:point)==1{return event}
                        table.cancelPick?()
                    }
                    hit=view.superview
                }
                self.back?();return nil
            }
        }
        deinit {if let monitor{NSEvent.removeMonitor(monitor)}}
        override func hitTest(_ point:NSPoint)->NSView?{nil}
    }
    func makeNSView(context:Context)->Host{let view=Host();view.back=back;return view}
    func updateNSView(_ view:Host,context:Context){view.back=back}
    static func dismantleNSView(_ view:Host,coordinator:()){if let monitor=view.monitor{NSEvent.removeMonitor(monitor);view.monitor=nil}}
}
struct MatchTunnelIcon:View {
    private static let artwork = Bundle.module.url(forResource:"MatchTunnel",withExtension:"png",subdirectory:"Resources").flatMap {NSImage(contentsOf:$0)}
    var body:some View {
        GeometryReader {geo in
            if let image=Self.artwork {
                Image(nsImage:image).resizable().interpolation(.high).scaledToFill()
                    .frame(width:geo.size.width,height:geo.size.height).clipped()
            }
        }.background(.black)
    }
}
