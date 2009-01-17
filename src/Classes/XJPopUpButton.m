//
//  XJPopUpButton.m
//  testXJUI
//
//  Created by Alistair McMillan on 12/05/2008.
//  Copyright 2008 Alistair McMillan. All rights reserved.
//
//  Based on http://www.jimmcgowan.net/Site/Blog/Entries/2007/8/27_Adding_a_Menu_to_an_NSButton.html

#import "XJPopUpButton.h"

@implementation XJPopUpButton

- (void)awakeFromNib
{
	popUpCell = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:YES];
	[popUpCell setMenu:popUpMenu];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuClosed:) name:NSMenuDidEndTrackingNotification object:popUpMenu];
}

- (void)mouseDown:(NSEvent*)event
{
	[self highlight:YES];
	[popUpCell performClickWithFrame:[self bounds] inView:self];
}

- (void)menuClosed:(NSNotification*)note
{
	[self highlight:NO];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMenuDidEndTrackingNotification object:popUpMenu];
	[popUpCell release];
	[super dealloc];
}

@end
