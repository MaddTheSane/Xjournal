/* AddressBookDropView */

#import <Cocoa/Cocoa.h>

#define kDragTypesArray [NSArray arrayWithObjects: @"ABPeopleUIDsPboardType", nil]

@interface AddressBookDropView : NSImageView
{
	BOOL dragState;
}

@property (nonatomic) BOOL acceptsDrags;
@end
