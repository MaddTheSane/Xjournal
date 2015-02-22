//
//  XJSyndicationData.h
//  Xjournal
//
//  Created by Fraser Speirs on 19/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJSyndicationData : NSObject

+ (instancetype)syndicationDataWithAppleEvent: (NSAppleEventDescriptor *)aeDesc;
- (instancetype)initWithAppleEvent: (NSAppleEventDescriptor *)aeDesc NS_DESIGNATED_INITIALIZER;

// ---------------------------------
// Accessors
// ---------------------------------
@property (copy) NSString *title;
@property (copy) NSString *body;
@property (copy) NSString *summary;
@property (copy) NSString *link;
@property (copy) NSString *permalink;
@property (copy) NSString *commentsURL;
@property (copy) NSString *sourceName;
@property (copy) NSString *sourceHomeURL;
@property (copy) NSString *sourceFeedURL;


@end
