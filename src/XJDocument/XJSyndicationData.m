//
//  XJSyndicationData.m
//  Xjournal
//
//  Created by Fraser Speirs on 19/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJSyndicationData.h"
#import "NSString+Templating.h"

const AEKeyword EditDataItemAppleEventClass = 'EBlg';
const AEKeyword EditDataItemAppleEventID = 'oitm';
const AEKeyword DataItemTitle = 'titl';
const AEKeyword DataItemDescription = 'desc';
const AEKeyword DataItemSummary = 'summ';
const AEKeyword DataItemLink = 'link';
const AEKeyword DataItemPermalink = 'plnk';
const AEKeyword DataItemSubject = 'subj';
const AEKeyword DataItemCreator = 'crtr';
const AEKeyword DataItemCommentsURL = 'curl';
const AEKeyword DataItemGUID = 'guid';
const AEKeyword DataItemSourceName = 'snam';
const AEKeyword DataItemSourceHomeURL = 'hurl';
const AEKeyword DataItemSourceFeedURL = 'furl';

@implementation XJSyndicationData
+ (XJSyndicationData *)syndicationDataWithAppleEvent: (NSAppleEventDescriptor *)aeDesc {
	XJSyndicationData *data = [[XJSyndicationData alloc] initWithAppleEvent: aeDesc];
	return [data autorelease];
}

- (id)initWithAppleEvent: (NSAppleEventDescriptor *)aeDesc {
	self = [super init];
	if(self) {
		NSAppleEventDescriptor *recordDescriptor = [aeDesc descriptorForKeyword: keyDirectObject];
		
		[self setTitle: [[recordDescriptor descriptorForKeyword: DataItemTitle] stringValue]];
		[self setBody: [[recordDescriptor descriptorForKeyword: DataItemDescription] stringValue]];
		[self setSummary: [[recordDescriptor descriptorForKeyword: DataItemSummary] stringValue]];
		[self setLink: [[recordDescriptor descriptorForKeyword: DataItemLink] stringValue]];
		[self setPermalink: [[recordDescriptor descriptorForKeyword: DataItemPermalink] stringValue]];
		[self setCommentsURL: [[recordDescriptor descriptorForKeyword: DataItemCommentsURL] stringValue]];
		[self setSourceName: [[recordDescriptor descriptorForKeyword: DataItemSourceName] stringValue]];
		[self setSourceHomeURL: [[recordDescriptor descriptorForKeyword: DataItemSourceHomeURL] stringValue]];
		[self setSourceFeedURL: [[recordDescriptor descriptorForKeyword: DataItemSourceFeedURL] stringValue]];
	}
	return self;
}

- (NSString *)description {
	return [@"Title: <%title/>\nBody:<$body/>\nURL: <$commentsURL/>" stringByParsingTagsWithStartDelimeter: @"<$" endDelimeter: @"/>" usingObject: self];
}

// =========================================================== 
// - title:
// =========================================================== 
- (NSString *)title {
    return title; 
}

// =========================================================== 
// - setTitle:
// =========================================================== 
- (void)setTitle:(NSString *)aTitle {
    if (title != aTitle) {
        [aTitle retain];
        [title release];
        title = aTitle;
    }
}

// =========================================================== 
// - body:
// =========================================================== 
- (NSString *)body {
    return body; 
}

// =========================================================== 
// - setBody:
// =========================================================== 
- (void)setBody:(NSString *)aBody {
    if (body != aBody) {
        [aBody retain];
        [body release];
        body = aBody;
    }
}

// =========================================================== 
// - summary:
// =========================================================== 
- (NSString *)summary {
    return summary; 
}

// =========================================================== 
// - setSummary:
// =========================================================== 
- (void)setSummary:(NSString *)aSummary {
    if (summary != aSummary) {
        [aSummary retain];
        [summary release];
        summary = aSummary;
    }
}

// =========================================================== 
// - link:
// =========================================================== 
- (NSString *)link {
    return link; 
}

// =========================================================== 
// - setLink:
// =========================================================== 
- (void)setLink:(NSString *)aLink {
    if (link != aLink) {
        [aLink retain];
        [link release];
        link = aLink;
    }
}

// =========================================================== 
// - permalink:
// =========================================================== 
- (NSString *)permalink {
    return permalink; 
}

// =========================================================== 
// - setPermalink:
// =========================================================== 
- (void)setPermalink:(NSString *)aPermalink {
    if (permalink != aPermalink) {
        [aPermalink retain];
        [permalink release];
        permalink = aPermalink;
    }
}

// =========================================================== 
// - commentsURL:
// =========================================================== 
- (NSString *)commentsURL {
    return commentsURL; 
}

// =========================================================== 
// - setCommentsURL:
// =========================================================== 
- (void)setCommentsURL:(NSString *)aCommentsURL {
    if (commentsURL != aCommentsURL) {
        [aCommentsURL retain];
        [commentsURL release];
        commentsURL = aCommentsURL;
    }
}

// =========================================================== 
// - sourceName:
// =========================================================== 
- (NSString *)sourceName {
    return sourceName; 
}

// =========================================================== 
// - setSourceName:
// =========================================================== 
- (void)setSourceName:(NSString *)aSourceName {
    if (sourceName != aSourceName) {
        [aSourceName retain];
        [sourceName release];
        sourceName = aSourceName;
    }
}

// =========================================================== 
// - sourceHomeURL:
// =========================================================== 
- (NSString *)sourceHomeURL {
    return sourceHomeURL; 
}

// =========================================================== 
// - setSourceHomeURL:
// =========================================================== 
- (void)setSourceHomeURL:(NSString *)aSourceHomeURL {
    if (sourceHomeURL != aSourceHomeURL) {
        [aSourceHomeURL retain];
        [sourceHomeURL release];
        sourceHomeURL = aSourceHomeURL;
    }
}

// =========================================================== 
// - sourceFeedURL:
// =========================================================== 
- (NSString *)sourceFeedURL {
    return sourceFeedURL; 
}

// =========================================================== 
// - setSourceFeedURL:
// =========================================================== 
- (void)setSourceFeedURL:(NSString *)aSourceFeedURL {
    if (sourceFeedURL != aSourceFeedURL) {
        [aSourceFeedURL retain];
        [sourceFeedURL release];
        sourceFeedURL = aSourceFeedURL;
    }
}


// =========================================================== 
//  - dealloc:
// =========================================================== 
- (void)dealloc {
    [title release];
    [body release];
    [summary release];
    [link release];
    [permalink release];
    [commentsURL release];
    [sourceName release];
    [sourceHomeURL release];
    [sourceFeedURL release];
	
    [super dealloc];
}

@end
