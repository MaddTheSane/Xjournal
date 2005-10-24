//
//  RSS-HTMLConversion.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Jul 24 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSS.h"

@interface RSS (HTMLConversion)
- (NSString *)html;
- (NSString *)newsItemToHTML: (id)item;
@end
