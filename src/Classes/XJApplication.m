//
//  XJApplication.m
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import "XJApplication.h"
#import "XJPreferencesController.h"

@implementation XJApplication
- (void)run;
{	
    exceptions = 0;
    exceptionDate = [[NSDate alloc] init];
    do {
        @try {
            [super run];
            return;
        } @catch (NSException *localException) {
            if (++exceptions >= 300) {
                if ([exceptionDate timeIntervalSinceNow] >= -3.0) {
                    fprintf(stderr, "Too many errors!\n");
                    return;
                }
                exceptionDate = [[NSDate alloc] init];
                exceptions = 0;
            }
            if (localException) {
                if (_appFlags._hasBeenRun)
                    [self handleRunException:localException];
                else
                    [self handleInitException:localException];
            }
        };
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
