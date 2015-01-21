//
//  XJSyndicationData.m
//  Xjournal
//
//  Created by Fraser Speirs on 19/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import "XJSyndicationData.h"
#import "NSString+Templating.h"
#import "NNWConsts.h"

@implementation XJSyndicationData
@synthesize title;
@synthesize body;
@synthesize summary;
@synthesize link;
@synthesize permalink;
@synthesize commentsURL;
@synthesize sourceName;
@synthesize sourceHomeURL;
@synthesize sourceFeedURL;

+ (XJSyndicationData *)syndicationDataWithAppleEvent: (NSAppleEventDescriptor *)aeDesc {
	XJSyndicationData *data = [[XJSyndicationData alloc] initWithAppleEvent: aeDesc];
	return data;
}

- (instancetype)initWithAppleEvent: (NSAppleEventDescriptor *)aeDesc {
	self = [super init];
	if(self) {
		NSAppleEventDescriptor *recordDescriptor = [aeDesc descriptorForKeyword: keyDirectObject];
		
		[self setTitle: [[recordDescriptor descriptorForKeyword: NNWDataItemTitle] stringValue]];
		[self setBody: [[recordDescriptor descriptorForKeyword: NNWDataItemDescription] stringValue]];
		[self setSummary: [[recordDescriptor descriptorForKeyword: NNWDataItemSummary] stringValue]];
		[self setLink: [[recordDescriptor descriptorForKeyword: NNWDataItemLink] stringValue]];
		[self setPermalink: [[recordDescriptor descriptorForKeyword: NNWDataItemPermalink] stringValue]];
		[self setCommentsURL: [[recordDescriptor descriptorForKeyword: NNWDataItemCommentsURL] stringValue]];
		[self setSourceName: [[recordDescriptor descriptorForKeyword: NNWDataItemSourceName] stringValue]];
		[self setSourceHomeURL: [[recordDescriptor descriptorForKeyword: NNWDataItemSourceHomeURL] stringValue]];
		[self setSourceFeedURL: [[recordDescriptor descriptorForKeyword: NNWDataItemSourceFeedURL] stringValue]];
	}
	return self;
}

- (NSString *)description {
	return [@"Title: <$title/>\nBody:<$body/>\nURL: <$commentsURL/>" stringByParsingTagsWithStartDelimeter: @"<$" endDelimeter: @"/>" usingObject: self];
}

@end
