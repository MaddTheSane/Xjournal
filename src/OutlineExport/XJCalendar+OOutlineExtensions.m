//
//  XJCalendar+OOutlineExtensions.m
//  Xjournal
//
//  Created by Fraser Speirs on Fri Apr 04 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJCalendar+OOutlineExtensions.h"


@implementation XJCalendar (OOutlineExtensions)

- (NSString *)outlinerRepresentation
{
    NSString *outlineHeader = [NSString stringWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"OutlineHeaderFile" ofType:@"txt"]];
    NSString *outlineFooter = [NSString stringWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"OutlineFooterFile" ofType:@"txt"]];

    NSMutableString *string = [NSMutableString stringWithCapacity:1000];

    [string appendString:outlineHeader];

    [string appendString: @"<oo:root background-color='#ffffff' alternate-color='#edf3fe'>"];

    NSEnumerator *enumerator = [years objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        [string appendString: [object outlinerRepresentation]];
    }

    [string appendString: @"</oo:root>\n"];

    [string appendString: outlineFooter];

    return string;
}

@end
