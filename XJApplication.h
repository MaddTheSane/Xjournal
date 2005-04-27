//
//  XJApplication.h
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJApplication : NSApplication {
	NSDate *exceptionCheckpointDate;
    unsigned int exceptionCount;
    
}
- (void)handleRunException:(NSException *)anException;
- (void)handleInitException:(NSException *)anException;
@end
