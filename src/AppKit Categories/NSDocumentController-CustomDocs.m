//
//  NSDocumentController-CustomDocs.m
//  Xjournal
//
//  Created by Fraser Speirs on Wed May 07 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "NSDocumentController-CustomDocs.h"
#import "XJDocument.h"

@implementation NSDocumentController (CustomDocs)
- (id)newDocumentWithData: (id)data
{
    NSLog(@"newDocumentWithData - %d documents", [[self documents] count]);
    XJDocument *newDocument = [[XJDocument alloc] initWithEntry: data];
    [self addDocument: newDocument];
    [newDocument showWindows];

    [newDocument release];
    NSLog(@"newDocumentWithData (end) - %d documents", [[self documents] count]);

}
@end
