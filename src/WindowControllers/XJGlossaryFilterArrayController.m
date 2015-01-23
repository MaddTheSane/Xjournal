//
//  XJGlossaryFilterArrayController.m
//  Xjournal
//
//  Created by Fraser Speirs on 09/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import "XJGlossaryFilterArrayController.h"

NSString *MovedRowsType = @"MOVED_ROWS_TYPE";

@implementation XJGlossaryFilterArrayController
@synthesize searchString;

- (void)search:(id)sender
{
    [self setSearchString:[sender stringValue]];
    [self rearrangeObjects];    
}


// Set default values, and keep reference to new object -- see arrangeObjects:
- (id)newObject
{
    newObj = [super newObject];
    [newObj setValue:@"New Entry" forKey:@"text"];
    return newObj;
}



- (NSArray *)arrangeObjects:(NSArray *)objects
{
	
    if ((searchString == nil) ||
		([searchString isEqualToString:@""]))
	{
		newObj = nil;
		return [super arrangeObjects:objects];   
	}
	
	/*
	 Create array of objects that match search string.
	 Also add any newly-created object unconditionally:
	 (a) You'll get an error if a newly-added object isn't added to
	 arrangedObjects.
	 (b) The user will see newly-added objects even if they don't
	 match the search term.
	 */
	
    NSMutableArray *matchedObjects = [NSMutableArray arrayWithCapacity:[objects count]];
    // case-insensitive search
    NSString *lowerSearch = [searchString lowercaseString];
    
	NSEnumerator *oEnum = [objects objectEnumerator];
    id item;	
    while (item = [oEnum nextObject])
	{
		// if the item has just been created, add it unconditionally
		if (item == newObj)
		{
            [matchedObjects addObject:item];
			newObj = nil;
		}
		else
		{
			// Use of local autorelease pool here is probably overkill,
			// but may be useful in a larger-scale application.
			@autoreleasepool {
				NSString *lowerName = [[item valueForKeyPath:@"text"] lowercaseString];
				if ([lowerName rangeOfString:lowerSearch].location != NSNotFound)
				{
					[matchedObjects addObject:item];
				}
			}
		}
    }
    return [super arrangeObjects:matchedObjects];
}


// -----------------
// DND
// -----------------
- (void)awakeFromNib
{
    // register for drag and drop
    [tableView registerForDraggedTypes:
		@[MovedRowsType, NSStringPboardType]];
    [tableView setAllowsMultipleSelection:YES];
}


- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // declare our own pasteboard types
    NSArray *typesArray = @[MovedRowsType,	NSStringPboardType];
    [pboard declareTypes:typesArray owner:self];
    
    // Try to create an string
    // If we can, add NSStringPboardType to the declared types and write
    //the String to the pasteboard; otherwise declare existing types
    NSMutableArray *strings = [NSMutableArray array];
    NSMutableArray *movedRows = [NSMutableArray array];
    
    NSInteger i = rowIndexes.firstIndex;
    while (i != NSNotFound) {
        NSDictionary *rowContent = [self arrangedObjects][i];
        NSString *string = [rowContent valueForKey:@"text"];
        [strings addObject: string];
        [movedRows addObject: rowContent];
        i = [rowIndexes indexGreaterThanIndex:i];
    }
    
    [pboard setString: [strings componentsJoinedByString: @"\n"] forType: NSStringPboardType];
    [pboard setPropertyList: movedRows forType: MovedRowsType];

    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
    
    NSDragOperation dragOp = NSDragOperationCopy;
    
    // if drag source is self, it's a move
    if ([info draggingSource] == tableView)
	{
		dragOp =  NSDragOperationMove;
    }
    // we want to put the object at, not over,
    // the current row (contrast NSTableViewDropOn) 
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
}



- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)op
{
    if (row < 0)
	{
		row = 0;
	}
    
    // if drag source is self, it's a move
    if ([info draggingSource] == tableView)
    {
		NSArray *rows = [[info draggingPasteboard] propertyListForType: MovedRowsType];
		NSIndexSet  *indexSet = [self indexSetFromRows:rows];
		
		[self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
		
		// set selected rows to those that were just moved
		// Need to work out what moved where to determine proper selection...
		NSInteger rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];
		
		NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
		indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
		[self setSelectionIndexes:indexSet];
		
		return YES;
    }
	
	else {
		// Try to get a string
		NSString *dropString = [[info draggingPasteboard] stringForType: NSStringPboardType];
		if(dropString) {
			[self addObject: [NSMutableDictionary dictionaryWithObject: dropString forKey: @"text"]];
			return YES;
		}
	}

    return NO;
}



-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet
										toIndex:(NSUInteger)insertIndex
{
	
    NSArray		*objects = [self arrangedObjects];
	NSInteger	index = [indexSet lastIndex];
	
    NSInteger	aboveInsertIndexCount = 0;
    id			object;
    NSInteger   removeIndex;
	
    while (NSNotFound != index)
	{
		if (index >= insertIndex) {
			removeIndex = index + aboveInsertIndexCount;
			aboveInsertIndexCount += 1;
		}
		else
		{
			removeIndex = index;
			insertIndex -= 1;
		}
		object = objects[removeIndex];
		[self removeObjectAtArrangedObjectIndex:removeIndex];
		[self insertObject:object atArrangedObjectIndex:insertIndex];
		
		index = [indexSet indexLessThanIndex:index];
    }
}


- (NSIndexSet *)indexSetFromRows:(NSArray *)rows
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSEnumerator *rowEnumerator = [rows objectEnumerator];
    NSNumber *idx;
    while (idx = [rowEnumerator nextObject])
    {
		[indexSet addIndex:[idx integerValue]];
    }
    return indexSet;
}


- (NSInteger)rowsAboveRow:(NSInteger)row inIndexSet:(NSIndexSet *)indexSet
{
    NSUInteger currentIndex = [indexSet firstIndex];
    NSInteger i = 0;
    while (currentIndex != NSNotFound)
    {
		if (currentIndex < row) { i++; }
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}
@end
