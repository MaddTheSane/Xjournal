//
//  LJFriend-FOAF.h
//  Xjournal
//
//  Created by Fraser on Tue Feb 24 2004.
//  Copyright (c) 2004 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LJKit/LJKit.h>

@interface LJFriend (FOAF)
- (NSString *)foafXML;
- (NSString *)foafPropertyForDescriptor: (NSString *)descriptor;
@end
