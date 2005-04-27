//
//  RSSManager.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Jul 24 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSS.h"

@interface RSSManager : NSObject {
    NSMutableDictionary *userHeadlines;
}

+ (RSSManager *)sharedManager;

- (RSS *)rssForUsername: (NSString *)username;
- (void)updateHeadlinesForUser:(NSString *)user;
@end
