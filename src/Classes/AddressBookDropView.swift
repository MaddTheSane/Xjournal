//
//  AddressBookDropView.swift
//  Xjournal
//
//  Created by C.W. Betts on 3/26/15.
//
//

import Cocoa

private let kABDragType = "ABPeopleUIDsPboardType"
private let kDragTypes = [kABDragType]

class AddressBookDropView: NSImageView {

    var acceptsDrags: Bool = false {
        willSet {
            if newValue {
                if !acceptsDrags {
                    register(forDraggedTypes: kDragTypes)
                }
            } else {
                if acceptsDrags {
                    unregisterDraggedTypes()
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        register(forDraggedTypes: kDragTypes)
        acceptsDrags = true
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pb = sender.draggingPasteboard()
        if let uidArrays = pb.propertyList(forType: kABDragType) as? NSArray {
            NotificationCenter.default.post(name: .XJAddressCardDropped, object: uidArrays)
        }
        
        return true
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        
    }
}
