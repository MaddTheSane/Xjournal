//
//  XJCalendarProtocol.h
//  Xjournal
//
//  Created by C.W. Betts on 1/19/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, XJSearchType) {
    XJSearchSubjectOnly = 1,
    XJSearchBodyOnly = 2,
    XJSearchEntirePost = 3
};

@protocol XJCalendarProtocol <NSObject>
@property (readonly, copy) id propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (id) plistType;

- (NSArray *)entriesContainingString: (NSString *)target;
- (NSArray *)entriesContainingString: (NSString *)target searchType: (XJSearchType)type;
@end
