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
    exceptions = 0;
    exceptionDate = [[NSDate alloc] init];
    do {
        NS_DURING {
            [super run];
            NS_VOIDRETURN;
        } NS_HANDLER {
            if (++exceptions >= 300) {
                if ([exceptionDate timeIntervalSinceNow] >= -3.0) {
                    fprintf(stderr, "Too many errors!\n");
                    return;
                }
                [exceptionDate release];
                exceptionDate = [[NSDate alloc] init];
                exceptions = 0;
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
    NSLog(@"%@", [anException reason]);
	NSRunAlertPanel(nil, @"%@", nil, nil, nil, [anException reason]);
}

- (void)handleInitException:(NSException *)anException;
{
	NSLog(@"%@", [anException reason]);
}
@end
