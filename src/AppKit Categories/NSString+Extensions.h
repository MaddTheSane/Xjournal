#import <Cocoa/Cocoa.h>

@interface NSString (LJCutConversions)
@property (readonly, copy, nonnull) NSString *translateNewLines;
@property (readonly, copy, nonnull) NSString *translateLJUser;
@property (readonly, copy, nonnull) NSString *translateLJComm;
@property (readonly, copy, nonnull) NSString *translateLJCutOpenTagWithText;
@property (readonly, copy, nonnull) NSString *translateBasicLJCutOpenTag;
@property (readonly, copy, nonnull) NSString *translateLJCutCloseTag;
@property (readonly, copy, nonnull) NSString *translateLJPoll;
- (nonnull NSString *)translateLJPhonePostWithItemURL:(nonnull NSString *)url userName: (nonnull NSString *)user;
@property (readonly, copy, nonnull) NSString *translateNewLinesOutsideTables;
@end

// Moved from NSString+extras.h from Ranchero.com's RSS class
@interface NSString (extras)
@property (readonly, copy, nonnull) NSString *trimWhiteSpace;
+ (BOOL) stringIsEmpty: (nullable NSString *) s;
@end
