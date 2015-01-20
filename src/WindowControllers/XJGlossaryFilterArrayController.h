//
//  XJGlossaryFilterArrayController.h
//  Xjournal
//
//  Created by Fraser Speirs on 09/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJGlossaryFilterArrayController : NSArrayController <NSTableViewDataSource, NSTableViewDelegate> {
    NSString *searchString;
	id newObj;
	
	IBOutlet NSTableView *tableView;
}

- (IBAction)search:(id)sender;
@property (copy) NSString *searchString;

- (NSIndexSet *)indexSetFromRows:(NSArray *)rows;
- (NSInteger)rowsAboveRow:(NSInteger)row inIndexSet:(NSIndexSet *)indexSet;
-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet
										toIndex:(NSUInteger)insertIndex;
@end
