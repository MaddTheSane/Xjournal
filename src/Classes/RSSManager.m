//
//  RSSManager.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Jul 24 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "RSSManager.h"

static RSSManager *shared;

@implementation RSSManager
+ (RSSManager *)sharedManager
{
    if(!shared)
        shared = [[RSSManager alloc] init];
    return shared;
}

- (id)init
{
    if(self = [super init]) {
        userHeadlines = [[NSMutableDictionary dictionaryWithCapacity: 100] retain];
    }
    return self;
}

- (RSS *)rssForUsername: (NSString *)username
{
    if(![userHeadlines objectForKey: username]) {
        [self updateHeadlinesForUser: username];
    }
    return [userHeadlines objectForKey: username];
}

- (void)updateHeadlinesForUser:(NSString *)user
{
    RSS *data = nil;
    NS_DURING
        data = [[RSS alloc] initWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"http://www.livejournal.com/users/%@/data/rss", user]] normalize: YES];
    NS_HANDLER
        NSLog(@"Download failed for user %@", user);
    NS_ENDHANDLER
    
    if(data) {
        [userHeadlines setObject: data forKey: user];
        [data release];
    }
}
@end
