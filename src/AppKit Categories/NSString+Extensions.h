#import <Cocoa/Cocoa.h>

@interface NSString (LJCutConversions)
- (NSString *)translateNewLines;
- (NSString *)translateLJUser;
- (NSString *)translateLJComm;
- (NSString *)translateLJCutOpenTagWithText;
- (NSString *)translateBasicLJCutOpenTag;
- (NSString *)translateLJCutCloseTag;
- (NSString *)translateLJPoll;
- (NSString *)translateLJPhonePostWithItemURL:(NSString *)url userName: (NSString *)user;
@end

// Moved from NSString+extras.h from Ranchero.com's RSS class
@interface NSString (extras)
- (NSString *) trimWhiteSpace;
+ (BOOL) stringIsEmpty: (NSString *) s;
@end
