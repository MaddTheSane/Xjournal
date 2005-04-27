//
//  BLRoundedTableCell.m
//
//  Created by Fraser Speirs on Wed Mar 17 2004.
//  
//	This code is placed in the public domain.
//  It is based on ideas presented by Apple Computer 
//  in sample code via ADC, extended to suit the context of
//  NSTableViewCell

#import "XJRoundedTableCell.h"


@implementation XJRoundedTableCell
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	NSRect labelRect = [self drawingRectForBounds:cellFrame];
	float capRadius = NSHeight(labelRect) / 2.0;
	
	// Next, we hack up a slightly different rect for the superclass
	// to draw in.  This shifts the text to the right out of the 
	// highlight curve and makes sure the text doesn't jump around 
	// when the selection changes
	float cellIndent = 5.0;
	NSRect newRect = NSMakeRect(cellFrame.origin.x+cellIndent,
								cellFrame.origin.y,
								cellFrame.size.width-cellIndent,
								cellFrame.size.height);

	if([self isHighlighted]) {
		[super drawInteriorWithFrame: newRect inView: controlView];
	}
	else {			
		NSBezierPath *highlightPath = [[NSBezierPath alloc] init];
		
		NSPoint startPoint = NSMakePoint(labelRect.origin.x+capRadius,
										 labelRect.origin.y+capRadius);
										 
		NSPoint endPoint = NSMakePoint((labelRect.origin.x-capRadius)+(labelRect.size.width), 
										labelRect.origin.y+capRadius);
										
		[highlightPath appendBezierPathWithArcWithCenter: startPoint
												  radius: capRadius 
											  startAngle: 90.0f
												endAngle: 270.f
											   clockwise: NO];
											   
		[highlightPath appendBezierPathWithArcWithCenter: endPoint 
												  radius: capRadius
											  startAngle: 270.0f 
												endAngle: 90.f 
											   clockwise: NO];
		
		[highlightPath closePath];
		
		// Might want to change the text color here
		// NSColor *originalTextColor = [self textColor];
		
		if ([self drawsBackground] && highlightPath) {
			[[self backgroundColor] set];
			[highlightPath fill];
			[highlightPath release];
		}
		
		
		
		[self setDrawsBackground: NO];
		[super drawInteriorWithFrame: newRect inView: controlView];
		
		// And change it back here
		/*
		if (originalTextColor) {
			[self setTextColor:originalTextColor];
		}
		*/
	}
}
@end
