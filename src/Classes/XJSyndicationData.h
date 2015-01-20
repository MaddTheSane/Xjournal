//
//  XJSyndicationData.h
//  Xjournal
//
//  Created by Fraser Speirs on 19/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJSyndicationData : NSObject {
	NSString *title;
	NSString *body;
	NSString *summary;
	NSString *link;
	NSString *permalink;
	NSString *commentsURL;
	NSString *sourceName;
	NSString *sourceHomeURL;
	NSString *sourceFeedURL;
}

+ (XJSyndicationData *)syndicationDataWithAppleEvent: (NSAppleEventDescriptor *)aeDesc;
- (id)initWithAppleEvent: (NSAppleEventDescriptor *)aeDesc;

// ---------------------------------
// Accessors
// ---------------------------------
- (NSString *)title;
- (void)setTitle:(NSString *)aTitle;

- (NSString *)body;
- (void)setBody:(NSString *)aBody;

- (NSString *)summary;
- (void)setSummary:(NSString *)aSummary;

- (NSString *)link;
- (void)setLink:(NSString *)aLink;

- (NSString *)permalink;
- (void)setPermalink:(NSString *)aPermalink;

- (NSString *)commentsURL;
- (void)setCommentsURL:(NSString *)aCommentsURL;

- (NSString *)sourceName;
- (void)setSourceName:(NSString *)aSourceName;

- (NSString *)sourceHomeURL;
- (void)setSourceHomeURL:(NSString *)aSourceHomeURL;

- (NSString *)sourceFeedURL;
- (void)setSourceFeedURL:(NSString *)aSourceFeedURL;


@end
