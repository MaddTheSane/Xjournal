#import "AddressBookDropView.h"
#import "XJPreferences.h"

@implementation AddressBookDropView

- (void)awakeFromNib
{
    [self registerForDraggedTypes: kDragTypesArray];
	dragState = YES;
}

- (void)setAcceptsDrags: (BOOL)accept
{
	if(accept) {
		if(!dragState)
			[self registerForDraggedTypes: kDragTypesArray];
	}
	else {
		if(dragState)
			[self unregisterDraggedTypes];
	}
	dragState = accept;
}
- (BOOL)acceptsDrags { return dragState; }

- (NSDragOperation)draggingEntered: (id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)prepareForDragOperation: (id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation: (id <NSDraggingInfo>)sender
{
    NSPasteboard *pb = [sender draggingPasteboard];
    NSArray *uidArrays;

    NSString *pbString = [pb stringForType: @"ABPeopleUIDsPboardType"];

    uidArrays = (NSArray *)[pbString propertyList];

    [[NSNotificationCenter defaultCenter] postNotificationName: XJAddressCardDroppedNotification
                                                        object: uidArrays];
    
    return YES;
}

- (void)concludeDragOperation: (id <NSDraggingInfo>)sender
{

}
@end
