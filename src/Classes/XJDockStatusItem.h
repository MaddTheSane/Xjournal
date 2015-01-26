// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/XJDockStatusItem.h,v 1.7 2003/01/15 22:51:43 kc Exp $

#import <Foundation/NSObject.h>

@class NSColor, NSImage;

#import <Foundation/NSGeometry.h>

@interface XJDockStatusItem : NSObject 
{
    NSImage *icon;
    NSUInteger count;
    BOOL isHidden;
}

- (instancetype)initWithIcon:(NSImage *)newIcon;

// API
@property (nonatomic) NSUInteger count;
- (void)setNoCount;

- (void)hide;
- (void)show;
@property (readonly, getter=isHidden) BOOL hidden;

@end
