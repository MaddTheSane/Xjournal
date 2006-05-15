//
//  XJGlossaryFilterArrayController.h
//  Xjournal
//
//  Created by Fraser Speirs on 09/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJGlossaryFilterArrayController : NSArrayController {
    NSString *searchString;
	id newObj;
	
	IBOutlet NSTableView *tableView;
}

- (void)search:(id)sender;
- (NSString *)searchString;
- (void)setSearchString:(NSString *)newSearchString;


- (NSIndexSet *)indexSetFromRows:(NSArray *)rows;
- (int)rowsAboveRow:(int)row inIndexSet:(NSIndexSet *)indexSet;
-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet
										toIndex:(unsigned int)insertIndex;
@end
