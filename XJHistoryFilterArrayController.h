//
//  XJHistoryFilterArrayController.h
//  Xjournal
//
//  Created by Fraser Speirs on 12/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJHistoryFilterArrayController : NSArrayController {
	NSString *searchString;
}
- (IBAction)search:(id)sender;

- (NSString *)searchString;
- (void)setSearchString:(NSString *)aSearchString;

@end
