//
//  NSString+Script.h
//  Xjournal
//
//  Created by Fraser Speirs on 29/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (XJScript)

- (NSString *)stringByRunningShellScript: (NSString *)scriptPath;

@end
