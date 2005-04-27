//
//  XJKeywordToImageValueTransformer.m
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJKeywordToImageValueTransformer.h"


@implementation XJKeywordToImageValueTransformer
+ (Class)transformedValueClass { return [NSData self]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)init {
	self = [super init];
	if(self) {
		cache = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (id)transformedValue:(id)value {
	id data = [cache objectForKey: value];
	if(!data) {
		NSURL *imgURL = [[[self account] userPicturesDictionary] objectForKey: value];
		if(imgURL) {
			NSLog(@"Userpic path: %@", [imgURL absoluteString]);
			NSImage *img = [[NSImage alloc] initWithContentsOfURL: imgURL];
			
			data = [img TIFFRepresentation];
			[cache setObject: data forKey: value];
		}
	}
	return data;
}



// =========================================================== 
// - account:
// =========================================================== 
- (LJAccount *)account {
    return account; 
}

// =========================================================== 
// - setAccount:
// =========================================================== 
- (void)setAccount:(LJAccount *)anAccount {
    if (account != anAccount) {
        [anAccount retain];
        [account release];
        account = anAccount;
    }
}
@end
