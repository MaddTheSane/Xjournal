//
//  LJEntryExtensions.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Mar 20 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LJKit/LJKit.h>

@interface LJEntry (XJExtensions)

- (BOOL)writePropertyListToFile:(NSString *)path atomically:(BOOL)flag;
- (void)configureWithContentsOfFile: (NSString *)file;
- (NSDictionary *)propertyListRepresentation;
- (void)configureFromPropertyListRepresentation:(id)plist;

- (NSString *)metadataHTML;
- (NSMutableDictionary *) makeMutableDictionary: (NSDictionary *)input;
@end