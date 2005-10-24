//
//  LJEntry+OOutlineExtensions.m
//  Xjournal
//
//  Created by Fraser Speirs on Fri Apr 04 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJEntry+OOutlineExtensions.h"

/*
 <oo:item>
 <oo:values>
 <oo:rich-text><oo:p>Subejct</oo:p></oo:rich-text>
 <oo:rich-text><oo:p>2003-03-02</oo:p></oo:rich-text>
 <oo:rich-text><oo:p>Alison Krauss</oo:p></oo:rich-text>
 <oo:rich-text><oo:p>Happy</oo:p></oo:rich-text>
 <oo:enum>Friends Only</oo:enum>
 </oo:values>
 <oo:note>
 <oo:rich-text><oo:p>The body of the post</oo:p></oo:rich-text>
 </oo:note>
 </oo:item>
*/

@implementation LJEntry (OOutlineExtensions)

- (NSString *)outlinerRepresentation
{
    NSMutableString *string = [NSMutableString stringWithCapacity:1000];

    [string appendString: @"<oo:item>\n"];
    [string appendString: @"\t<oo:values>\n"];

    [string appendString: [NSString stringWithFormat: @"\t\t<oo:rich-text><oo:p>%@</oo:p></oo:rich-text>\n", @"A"]]; //([self subject] ? [self subject] : @"Untitled")]];
    [string appendString: [NSString stringWithFormat: @"\t\t<oo:rich-text><oo:p>%@</oo:p></oo:rich-text>\n", @"B"]]; //[[self date] description]]];
    [string appendString: [NSString stringWithFormat: @"\t\t<oo:rich-text><oo:p>%@</oo:p></oo:rich-text>\n", @"C"]]; //([self currentMusic] ? [self currentMusic] : @"")]];
    [string appendString: [NSString stringWithFormat: @"\t\t<oo:rich-text><oo:p>%@</oo:p></oo:rich-text>\n", @"D"]]; //([self currentMood] ? [self currentMood] : @"")]];

    switch([self securityMode]) {
        case LJPublicSecurityMode:
            [string appendString: @"\t\t<oo:enum>Public</oo:enum>\n"];
            break;
        case LJPrivateSecurityMode:
            [string appendString: @"\t\t<oo:enum>Private</oo:enum>\n"];
            break;
        case LJFriendSecurityMode:
            [string appendString: @"\t\t<oo:enum>All Friends</oo:enum>\n"];
            break;
        case LJGroupSecurityMode:
            [string appendString: @"\t\t<oo:enum>Groups</oo:enum>\n"];
            break;
    }

    [string appendString: @"\t</oo:values>\n"];
    [string appendString: @"\t<oo:note>\n"];
    [string appendString: [NSString stringWithFormat: @"\t\t<oo:rich-text><oo:p>%@</oo:p></oo:rich-text>\n", @"aaaaaaaa" /*[[self content] htmlString]*/]];
    [string appendString: @"\t</oo:note>\n"];
    [string appendString: @"</oo:item>\n"];

    return string;
}

@end
