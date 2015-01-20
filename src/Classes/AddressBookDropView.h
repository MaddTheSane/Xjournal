/* AddressBookDropView */

#import <Cocoa/Cocoa.h>

#define kDragTypesArray [NSArray arrayWithObjects: @"ABPeopleUIDsPboardType", nil]

@interface AddressBookDropView : NSImageView
@property (nonatomic) BOOL acceptsDrags;

@end
