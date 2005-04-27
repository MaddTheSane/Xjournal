//
//  XJSearchResult.h
//  Xjournal
//
//  Created by Fraser Speirs on 15/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJSearchResult : NSObject {
	NSString *displayName;
	NSURL *fileURL;
	float relevance;
}
+ (id)resultWithDisplayName: (NSString *)theName url: (NSURL *)url relevance: (float)rel;
- (id)initWithDisplayName: (NSString *)theName url: (NSURL *)url relevance: (float)rel;

- (NSString *)displayName;
- (void)setDisplayName:(NSString *)aDisplayName;

- (NSURL *)fileURL;
- (void)setFileURL:(NSURL *)aFileURL;

- (float)relevance;
- (void)setRelevance:(float)aRelevance;


@end
