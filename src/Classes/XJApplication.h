//
//  XJApplication.h
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJApplication : NSApplication {
	NSDate *exceptionDate;
    NSUInteger exceptions;
    
}
- (void)handleRunException:(NSException *)anException;
- (void)handleInitException:(NSException *)anException;
@end
