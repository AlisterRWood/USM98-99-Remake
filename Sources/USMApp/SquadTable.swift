import SwiftUI
import AppKit
import USMCore

final class CarryLabel:NSTextField {
    override func hitTest(_ point:NSPoint)->NSView? {nil}
}
final class SelectionTable:NSTableView {
    let ghost=CarryLabel(labelWithString:"")
    var carriedName:String? {
        didSet {
            if ghost.superview==nil {ghost.font = .boldSystemFont(ofSize:13);ghost.textColor = .systemYellow;ghost.backgroundColor = NSColor(calibratedWhite:0.06,alpha:0.95);ghost.drawsBackground=true;ghost.wantsLayer=true;ghost.layer?.cornerRadius=4;addSubview(ghost,positioned:.above,relativeTo:nil)}
            ghost.stringValue=carriedName.map{"  \($0)  "} ?? "";ghost.sizeToFit();ghost.isHidden=carriedName==nil
        }
    }
    func moveGhost(_ event:NSEvent) {
        guard carriedName != nil else{return}
        let p=convert(event.locationInWindow,from:nil)
        ghost.setFrameOrigin(NSPoint(x:min(p.x+16,visibleRect.maxX-ghost.frame.width),y:min(p.y+16,visibleRect.maxY-ghost.frame.height)))
        ghost.isHidden=false
    }

    var pickUp:((Int)->Void)?
    var putDown:((Int)->Bool)?
    var cancelPick:(()->Void)?
    var record:((Int)->Void)?
    private var tracking:NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking=tracking {removeTrackingArea(tracking)}
        tracking=NSTrackingArea(rect:bounds,options:[.activeInKeyWindow,.mouseMoved,.mouseEnteredAndExited,.inVisibleRect],owner:self,userInfo:nil)
        addTrackingArea(tracking!)
    }
    override func mouseMoved(with event:NSEvent) {moveGhost(event)}
    override func mouseEntered(with event:NSEvent) {moveGhost(event)}
    override func mouseExited(with event:NSEvent) {ghost.isHidden=true;NSCursor.arrow.set()}
    override func rightMouseDown(with event:NSEvent) {
        let point=convert(event.locationInWindow,from:nil);let row=row(at:point);guard row>=0,column(at:point)==1 else {return}
        window?.makeFirstResponder(self);selectRowIndexes(IndexSet(integer:row),byExtendingSelection:false);pickUp?(row);moveGhost(event)
    }
    override func mouseDown(with event:NSEvent) {
        let row=row(at:convert(event.locationInWindow,from:nil))
        if row>=0,putDown?(row)==true {return}
        super.mouseDown(with:event)
        if event.clickCount==2,row>=0 {record?(row)}
    }
    override func keyDown(with event:NSEvent) {
        if event.keyCode==53 {cancelPick?();return};super.keyDown(with:event)
    }

}
struct SquadTable:NSViewRepresentable {
    var career:Career
    @Binding var carried:String?
    @Binding var highlighted:String?
    var onSwap:(String,String)->Void
    var onRecord:(String)->Void
    func makeCoordinator()->Coordinator {Coordinator(self)}
    func makeNSView(context:Context)->NSScrollView {
        let scroll=NSScrollView();scroll.hasVerticalScroller=true;scroll.hasHorizontalScroller=true
        let table=SelectionTable();table.rowHeight=25;table.intercellSpacing=NSSize(width:0,height:1)
        table.backgroundColor=NSColor(calibratedRed:0.07,green:0.10,blue:0.25,alpha:1)
        table.headerView=NSTableHeaderView();table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        let columns:[(String,String,CGFloat)]=[("number","No.",34),("name","Player",205),("role","Pos",44),("0","KP",36),("1","TA",36),("2","PS",36),("3","SH",36),("4","PC",36),("5","HE",36),("6","ST",36),("7","SP",36),("8","BC",36),("fitness","FIT",42),("goals","G",30)]
        for (id,title,width) in columns {let col=NSTableColumn(identifier:NSUserInterfaceItemIdentifier(id));col.title=title;col.width=width;col.minWidth=width;col.maxWidth=id=="name" ? 400:65;table.addTableColumn(col)}
        table.delegate=context.coordinator;table.dataSource=context.coordinator
        scroll.documentView=table;context.coordinator.table=table
        table.pickUp={row in let c=context.coordinator;guard row<c.rows.count else{return};c.parent.carried=c.rows[row].id;c.parent.highlighted=c.rows[row].id;c.setCursor()}
        table.putDown={row in let c=context.coordinator;guard let source=c.parent.carried,row<c.rows.count else{return false};c.parent.onSwap(source,c.rows[row].id);c.parent.carried=nil;c.setCursor();return true}
        table.cancelPick={let c=context.coordinator;c.parent.carried=nil;c.setCursor()}
        table.record={row in let c=context.coordinator;if row<c.rows.count {c.parent.onRecord(c.rows[row].id)}}
        return scroll
    }
    func updateNSView(_ view:NSScrollView,context:Context) {
        let c=context.coordinator;c.parent=self;c.rows=career.orderedSquad;c.table?.reloadData();c.setCursor()
    }
    class Coordinator:NSObject,NSTableViewDataSource,NSTableViewDelegate {
        var parent:SquadTable
        var rows:[Player]
        weak var table:SelectionTable?
        var cursorID:String?
        init(_ parent:SquadTable) {self.parent=parent;rows=parent.career.orderedSquad}
        func setCursor() {
            guard cursorID != parent.carried else{return};cursorID=parent.carried
            table?.carriedName=rows.first{$0.id==parent.carried}?.name
            NSCursor.arrow.set()
        }
        func numberOfRows(in tableView:NSTableView)->Int {rows.count}
        func tableViewSelectionDidChange(_ notification:Notification) {
            guard let t=table,t.selectedRow>=0,t.selectedRow<rows.count else{return}
            parent.highlighted=rows[t.selectedRow].id
        }
        func tableView(_ tableView:NSTableView,viewFor tableColumn:NSTableColumn?,row:Int)->NSView? {
            let p=rows[row],id=tableColumn!.identifier.rawValue,state=parent.career.states[p.id]
            let text:String
            switch id {
            case "number":text=row<18 ? String(row+1):"R"
            case "name":text=p.name+(state?.injuryWeeks ?? 0>0 ? "  [inj]":"")
            case "role":text=p.position
            case "fitness":text=String(state?.fitness ?? 100)
            case "goals":text=String(state?.goals ?? 0)
            default:text=String(p.skills[Int(id)!])
            }
            let cell=NSTextField(labelWithString:text);cell.font = .monospacedSystemFont(ofSize:12,weight:id=="name" ? .semibold:.regular)
            cell.textColor=(state?.injuryWeeks ?? 0)>0 ? .systemRed:(row>=18 ? .cyan:(row>=11 ? .systemOrange:(p.position=="DEF" ? .systemYellow:(p.position=="MID" ? .systemGreen:.white))))
            cell.alignment=id=="name" ? .left:.center;cell.lineBreakMode = .byTruncatingTail
            cell.toolTip=id=="name" ? "Right-click to move; left-click another player to swap. Double-click for record.":tableColumn?.title
            return cell
        }
    }
}
