//
//  XJSyndicationData.m
//  Xjournal
//
//  Created by Fraser Speirs on 19/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
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
	return [@"Title: <$title/>\nBody:<$body/>\nURL: <$commentsURL/>" stringByParsingTagsWithStartDelimeter: @"<$" endDelimeter: @"/>" usingObject: self];
}

@end
