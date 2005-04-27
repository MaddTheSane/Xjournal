//
//  XJRelevanceCell.m
//  Xjournal
//
//  Created by Fraser Speirs on 16/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJRelevanceCell.h"


@implementation XJRelevanceCell
- (void)drawWithFrame:(NSRect)rect inView:(NSView *)view {
	NSLog(@"Drawing relevance of %f", [self relevance]);
	
	float width = rect.size.width;
	width = width * [self relevance];
	float height = rect.size.height * 0.9;
	float y = rect.origin.y + (rect.size.height/10)/2.0;
	
	NSRect newRect = NSMakeRect(rect.origin.x, y, width, height);
	
	[view lockFocus];
	[[NSColor colorWithCalibratedRed: 51.0/255.0 green: 51.0/255.0 blue: 153.0/255.0 alpha: 1.0] set];
	[NSBezierPath fillRect: newRect];
	[view unlockFocus];
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

@end
