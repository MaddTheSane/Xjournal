//
//  XJMonth+OOutlineExtensions.m
//  Xjournal
//
//  Created by Fraser Speirs on Fri Apr 04 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJMonth+OOutlineExtensions.h"


@implementation XJMonth (OOutlineExtensions)

- (NSString *)outlinerRepresentation
{
    NSMutableString *string = [NSMutableString stringWithCapacity:1000];

    [string appendString: @"<oo:item expanded=\"no\">\n"];
    [string appendString: @"<oo:values>\n"];
    [string appendString: @"<oo:rich-text><oo:p>"];
    [string appendString: [NSString stringWithFormat: @"%d", [self monthName]]];
    [string appendString: @"</oo:p></oo:rich-text>\n"]; // outline column
    [string appendString: @"<oo:rich-text><oo:p></oo:p></oo:rich-text>\n"]; // date column
    [string appendString: @"<oo:rich-text><oo:p></oo:p></oo:rich-text>\n"]; // music column
    [string appendString: @"<oo:rich-text><oo:p></oo:p></oo:rich-text>\n"]; // mood column
    [string appendString: @"<oo:enum/>\n"]; // security
    [string appendString: @"</oo:values>\n"];

    [string appendString: @"<oo:children>\n"];

    NSEnumerator *enumerator = [days objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        [string appendString: [object outlinerRepresentation]];
    }

    //[string appendString: [[days objectAtIndex: 0] outlinerRepresentation]];
    
    [string appendString: @"</oo:children>\n"];
    [string appendString: @"</oo:item>\n"];
    return string;
}

@end
