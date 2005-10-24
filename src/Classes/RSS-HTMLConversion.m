//
//  RSS-HTMLConversion.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Jul 24 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "RSS-HTMLConversion.h"


@implementation RSS (HTMLConversion)

- (NSString *)html
{
    NSMutableString *header = [NSMutableString stringWithCapacity: 1000];
    [header appendString: @"<html><head><style type=\"text/css\">.xjournalbanner { background-color: #CCFFFF; padding-top: 10px; padding-bottom: 10px }</style></head>\n\n<body>\n"];
    
    NSMutableString *html = [[NSMutableString stringWithCapacity: 1000] retain];
    [html appendString: header];
    
    NSEnumerator *enumerator = [[self newsItems] objectEnumerator];
    id obj;
    
    while(obj = [enumerator nextObject]) {
        [html appendString: [self newsItemToHTML: obj]];
    }
    
    [html appendString: @"\n</body></html>"];

    return [html autorelease];
}

- (NSString *)newsItemToHTML: (id)item
{
    NSString *html;
    NSString *url = [item objectForKey: @"link"];
    NSString *title = [item objectForKey: @"title"];
    NSString *description = [item objectForKey: @"description"];
    NSString *date = [item objectForKey: @"pubDate"];

    html = [[NSString stringWithFormat: @"<div class=\"xjournalbanner\"><a href=\"%@\"><b>%@</b></a> - %@</div><br><br>\n%@<br><br>\n\n", url, title, date, description] retain];

    return [html autorelease];
}
@end
