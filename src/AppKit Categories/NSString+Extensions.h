#import <Cocoa/Cocoa.h>

@interface NSString (LJCutConversions)
@property (readonly, copy) NSString *translateNewLines;
@property (readonly, copy) NSString *translateLJUser;
@property (readonly, copy) NSString *translateLJComm;
@property (readonly, copy) NSString *translateLJCutOpenTagWithText;
@property (readonly, copy) NSString *translateBasicLJCutOpenTag;
@property (readonly, copy) NSString *translateLJCutCloseTag;
@property (readonly, copy) NSString *translateLJPoll;
- (NSString *)translateLJPhonePostWithItemURL:(NSString *)url userName: (NSString *)user;
@property (readonly, copy) NSString *translateNewLinesOutsideTables;
@end

// Moved from NSString+extras.h from Ranchero.com's RSS class
@interface NSString (extras)
@property (readonly, copy) NSString *trimWhiteSpace;
+ (BOOL) stringIsEmpty: (NSString *) s;
@end
