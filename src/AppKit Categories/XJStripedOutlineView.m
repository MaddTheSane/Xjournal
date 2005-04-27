//
//  XJStripedTableView.m
//  Xjournal
//
//  Created by Fraser Speirs on Tue Mar 18 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJStripedOutlineView.h"


@implementation XJStripedOutlineView

- (void)highlightSelectionInClipRect:(NSRect)clipRect
    /*
     Overridden to draw the proper background color on the rows.
     Sends tableView:stripeColorForRow: to the data source to get
     the color for each visible row. If the data source does not
     respond, it stripes odd rows.
     */
{
    //Get dims from self
    float rowHeight = [self rowHeight] + [self intercellSpacing].height;
    NSRect visibleRect = [self visibleRect];

    //Calculate the rect we should highlight
    NSRect highlightRect;
    highlightRect.origin = NSMakePoint(NSMinX(visibleRect), (int)(NSMinY(clipRect)/ rowHeight) * rowHeight);
    highlightRect.size = NSMakeSize(NSWidth(visibleRect), rowHeight );

    //Do the drawing
    while (NSMinY(highlightRect) < NSMaxY(clipRect))
    {
        NSColor *rowColor;
        NSRect clipedHighlightRect = NSIntersectionRect(highlightRect, clipRect);
        int row = (int)((NSMinY(highlightRect) + rowHeight / 2.0) / rowHeight);
        rowColor = (0 == row % 2) ? [NSColor colorWithCalibratedRed:0.929 green:0.953 blue:0.996 alpha:1.0] : [NSColor whiteColor];
        
        [rowColor set];
        NSRectFill(clipedHighlightRect);
        highlightRect.origin.y += rowHeight;
    }

    [super highlightSelectionInClipRect:clipRect];
}


@end
