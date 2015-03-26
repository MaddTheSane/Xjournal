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

class AddressBookDropView: NSImageView, NSDraggingDestination {

    var acceptsDrags: Bool = false {
        willSet {
            if newValue {
                if !acceptsDrags {
                    registerForDraggedTypes(kDragTypes)
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
        
        registerForDraggedTypes(kDragTypes)
        acceptsDrags = true
    }
    
    override func prepareForDragOperation(sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return .Copy
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pb = sender.draggingPasteboard()
        if let uidArrays = pb.propertyListForType(kABDragType) as? NSArray {
            NSNotificationCenter.defaultCenter().postNotificationName(XJAddressCardDroppedNotification, object: uidArrays)
        }
        
        return true
    }
    
    override func concludeDragOperation(sender: NSDraggingInfo?) {
        
    }
}
