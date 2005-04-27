//
//  XJSearchResult.m
//  Xjournal
//
//  Created by Fraser Speirs on 15/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJSearchResult.h"


@implementation XJSearchResult

+ (id)resultWithDisplayName: (NSString *)theName
						url: (NSURL *)url
				  relevance: (float)rel
{
	XJSearchResult *result = [[XJSearchResult alloc] initWithDisplayName: theName
																	 url: url
															   relevance:rel];
	return [result autorelease];
}

- (id)initWithDisplayName: (NSString *)theName
					  url: (NSURL *)url
				relevance: (float)rel
{
	self = [super init];
	if(self) {
		[self setDisplayName: theName];
		[self setRelevance: rel];
		[self setFileURL: url];
	}
	return self;
}

// =========================================================== 
// - displayName:
// =========================================================== 
- (NSString *)displayName {
    return displayName; 
}

// =========================================================== 
// - setDisplayName:
// =========================================================== 
- (void)setDisplayName:(NSString *)aDisplayName {
    if (displayName != aDisplayName) {
        [aDisplayName retain];
        [displayName release];
        displayName = aDisplayName;
    }
}

// =========================================================== 
// - fileURL:
// =========================================================== 
- (NSURL *)fileURL {
    return fileURL; 
}

// =========================================================== 
// - setFileURL:
// =========================================================== 
- (void)setFileURL:(NSURL *)aFileURL {
    if (fileURL != aFileURL) {
        [aFileURL retain];
        [fileURL release];
        fileURL = aFileURL;
    }
}

// =========================================================== 
// - relevance:
// =========================================================== 
- (float)relevance {
	
    return relevance;
}

// =========================================================== 
// - setRelevance:
// =========================================================== 
- (void)setRelevance:(float)aRelevance {
	relevance = aRelevance;
}

- (NSString *)description {
	return [NSString stringWithFormat: @"%@ (%f) @ %@", [self displayName], [self relevance], [[self fileURL] absoluteString]];	
}
@end
