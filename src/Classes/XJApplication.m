//
//  XJApplication.m
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJApplication.h"
#import "XJPreferencesController.h"

@implementation XJApplication
- (void)run;
{	
    exceptionCount = 0;
    exceptionCheckpointDate = [[NSDate alloc] init];
    do {
        NS_DURING {
            [super run];
            NS_VOIDRETURN;
        } NS_HANDLER {
            if (++exceptionCount >= 300) {
                if ([exceptionCheckpointDate timeIntervalSinceNow] >= -3.0) {
                    // 300 unhandled exceptions in 3 seconds: abort
                    fprintf(stderr, "Caught 300 unhandled exceptions in 3 seconds, aborting\n");
                    return;
                }
                [exceptionCheckpointDate release];
                exceptionCheckpointDate = [[NSDate alloc] init];
                exceptionCount = 0;
            }
            if (localException) {
                if (_appFlags._hasBeenRun)
                    [self handleRunException:localException];
                else
                    [self handleInitException:localException];
            }
        } NS_ENDHANDLER;
    } while (_appFlags._hasBeenRun);
}

- (void)handleRunException:(NSException *)anException;
{
    id delegate;
	
    delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(handleRunException:)]) {
        [delegate handleRunException:anException];
    } else {
        NSLog(@"%@", [anException reason]);
        NSRunAlertPanel(nil, @"%@", nil, nil, nil, [anException reason]);
    }
}

- (void)handleInitException:(NSException *)anException;
{
    id delegate;
	
    delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(handleInitException:)]) {
        [delegate handleInitException:anException];
    } else {
        NSLog(@"%@", [anException reason]);
    }
}
@end
