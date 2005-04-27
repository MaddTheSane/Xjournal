//
//  XJEditToolsController.m
//  Xjournal
//
//  Created by Fraser Speirs on 06/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJEditToolsController.h"


@implementation XJEditToolsController
- (id)init {
	self = [super init];
	if(self) {
		[NSBundle loadNibNamed: @"EditTools" owner: self];
	}
	return self;
}
@end
