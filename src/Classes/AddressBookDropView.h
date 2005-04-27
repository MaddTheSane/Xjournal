/* AddressBookDropView */

#import <Cocoa/Cocoa.h>

#define kDragTypesArray [NSArray arrayWithObjects: @"ABPeopleUIDsPboardType", nil]

@interface AddressBookDropView : NSImageView
{
	BOOL dragState;
}

- (void)setAcceptsDrags: (BOOL)accept;
- (BOOL)acceptsDrags;
@end
