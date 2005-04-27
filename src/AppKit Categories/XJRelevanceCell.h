//
//  XJRelevanceCell.h
//  Xjournal
//
//  Created by Fraser Speirs on 16/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJRelevanceCell : NSCell {
	float relevance;
}

- (float)relevance;
- (void)setRelevance:(float)aRelevance;

@end
