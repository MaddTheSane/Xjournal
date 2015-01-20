/*
    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

	Redistributions of source code must retain this list of conditions and the following disclaimer.

	The names of its contributors may not be used to endorse or promote products derived from this
    software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE CONTRIBUTORS "AS IS" AND ANY 
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
    OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT 
    SHALL THE CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
    OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WBSearchTextField.h"

#define WBSEARCHTEXTFIELD_MIN_WIDTH			34
#define WBSEARCHTEXTFIELD_CANCEL_OFFSET		44
#define WBSEARCHTEXTFIELD_MAGNIFY_OFFSET	25
#define WBSEARCHTEXTFIELD_WIDTH_OFFSET		33

static NSImage * _leftCapImage_=nil;
static NSImage * _middleImage_=nil;
static NSImage * _rightCapImage_=nil;
static NSMutableArray * _stopImages_=nil;

@implementation WBSearchTextField

- (BOOL)isDisplayingGraySearchScope
{
    return _flags.displayGraySearchScope;
    
}
- (void)displayGraySearchScopeIfAppropriate:(BOOL) aBool
{
    if (aBool==YES)
    {
        NSMenu * tMenu;
    
        tMenu=[self menu];
        
        if (tMenu!=nil && _flags.displayFocus==NO)
        {
            /*
                Only display the Gray Search scope if the text is empty and the control is not
                the first responder
            */
            
            NSMenuItem * tMenuItem;
            NSArray * tArray;
            int i,tCount;
            
            tArray=[tMenu itemArray];
            
            tCount=[tArray count];
            
            for(i=0;i<tCount;i++)
            {
                tMenuItem=(NSMenuItem *) [tArray objectAtIndex:i];
                
                if ([tMenuItem isEnabled]==YES && [tMenuItem state]==NSOnState)
                {
                    if ([tMenuItem action]==@selector(searchPopupChanged:))
                    {
                        NSMutableString * tString;
                        
                        tString=[[NSMutableString alloc] initWithString:[tMenuItem title]];
                        
                        CFStringTrimWhitespace((CFMutableStringRef) tString);
                        
                        [self setTextColor:[NSColor lightGrayColor]];
                        
                        [self setStringValue:tString];
                        
                        [tString release];
                        
                        break;
                    }
                }
            }
            
        }
        else
        {
            return;
        }
    }
    else
    {
        if (_flags.displayGraySearchScope==YES)
        {
            [self removeGraySearchScope];
        }
    }
    
    _flags.displayGraySearchScope=aBool;
}

- (void)removeGraySearchScope
{
    [self setStringValue:@""];
    
    [self setTextColor:[NSColor blackColor]];

    _flags.displayGraySearchScope=NO;
}

- (BOOL) becomeFirstResponder
{
    if ([self acceptsFirstResponder])
    {
        [self displayGraySearchScopeIfAppropriate:NO];
        
        [self selectText:self];
    
        [self _setFocusNeedsDisplay];
    
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)selectText:(id)sender
{
    NSText *t = [_window fieldEditor: YES
                           forObject: self];
    
    if ([t superview] == nil)
	{
        NSText *tObject;
        NSRect tBounds=[self bounds];
        int length;
        float tOffset;
        id tCell=[self cell];
        
        length = [[self stringValue] length];
        
        tObject = [tCell setUpFieldEditorAttributes: t];
        
        _flags.displayFocus=YES;
        
        tOffset=(_flags.showCancelButtons==NO) ? WBSEARCHTEXTFIELD_WIDTH_OFFSET : WBSEARCHTEXTFIELD_CANCEL_OFFSET;
        
        [tCell setDrawsBackground:YES];
        
        [tCell selectWithFrame: NSMakeRect(WBSEARCHTEXTFIELD_MAGNIFY_OFFSET,4,NSWidth(tBounds)-tOffset,NSHeight(tBounds)-6)
                            inView: self
                            editor: tObject
                            delegate: self
                            start: 0
                            length: length];
        [tCell setDrawsBackground:NO];
    }
}

- (void)awakeFromNib
{
    [self _loadImagesIfNecessary];
    
    [self setDrawsBackground:NO];
    
    [self setBordered:NO];
    
    [self setBezeled:NO];
    
    // Build the image
    
    _completeImage=[self backgroundImage];
    
    [self displayGraySearchScopeIfAppropriate:YES];
}

- (void)_loadImagesIfNecessary
{
    if (_leftCapImage_==nil)
    {
        _leftCapImage_=[[NSImage imageNamed:@"LeftSearchCap"] retain];
    }
    
    if (_middleImage_==nil)
    {
        _middleImage_=[[NSImage imageNamed:@"MiddleSearch"] retain];
    }
    
    if (_rightCapImage_==nil)
    {
        _rightCapImage_=[[NSImage imageNamed:@"RightSearchCap"] retain];
    }
    
    if (_stopImages_==nil)
    {
        _stopImages_=[[NSMutableArray alloc] initWithObjects:[NSImage imageNamed:@"stop.-3"],
                                                             [NSImage imageNamed:@"stop.-2"],
                                                             [NSImage imageNamed:@"stop.-1"],
                                                             [NSImage imageNamed:@"stop.0"],
                                                             [NSImage imageNamed:@"stop.1"],
                                                             [NSImage imageNamed:@"stop.2"],
                                                             nil];
    }
    
    _leftCapImage=_leftCapImage_;
    
    _middleImage=_middleImage_;
    
    _rightCapImage=_rightCapImage_;
    
    _stopImages=_stopImages_;
    
}

- (void)dealloc
{
    [_completeImage release];
    
    [super dealloc];
}

- (NSImage *) backgroundImage
{
    NSRect tBounds;
    float tWidth;
    
    NSImage * tImage; 

    tBounds=[self bounds];
    
    tImage=[[NSImage alloc] initWithSize:tBounds.size];
    
    tWidth=tBounds.size.width;
    
    if (tImage!=nil)
    {
        NSSize tSize;
        float tStartPointX;
        float tEndPointX;
        
        [tImage setFlipped:NO];
        
        [tImage lockFocus];
        
        // Left cap
        
        tSize=[_leftCapImage size];
        
        tStartPointX=tSize.width;
        
        tWidth-=tSize.width;
        
        [_leftCapImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
        
        // Right cap
        
        tSize=[_rightCapImage size];
        
        tWidth-=tSize.width;
        
        tEndPointX=tBounds.size.width-tSize.width;
        
        [_rightCapImage compositeToPoint:NSMakePoint(NSWidth(tBounds)-tSize.width,0) operation:NSCompositeSourceOver];
        
        // Middle section
        
        if (tEndPointX>=tStartPointX)
        {
            tSize=[_middleImage size];
        
            [NSBezierPath clipRect:NSMakeRect(tStartPointX,0,tWidth,NSHeight(tBounds))];
            
            for(;tStartPointX<tEndPointX;tStartPointX+=tSize.width)
            {
                [_middleImage compositeToPoint:NSMakePoint(tStartPointX,0) operation:NSCompositeSourceOver];
            }
        }
        
        [tImage unlockFocus];
    }
    
    return tImage;
}

- (void)setFrameSize:(NSSize) newSize
{
    [super setFrameSize:newSize];
        
    if (_completeImage!=nil)
    {
        [_completeImage release];
    }
    else
    {
        [self _loadImagesIfNecessary];
    
        [self setDrawsBackground:NO];
        
        [self setBordered:NO];
        
        [self setBezeled:NO];
        
        [self displayGraySearchScopeIfAppropriate:YES];
    }
    
    _completeImage=[self backgroundImage];
}

- (void)drawRect:(NSRect) aFrame
{
    NSRect tBounds;
    float tOffset;
    
    tBounds=[self bounds];
    
    // Draw background
    
    if (_completeImage!=nil)
    {
        [_completeImage compositeToPoint:NSMakePoint(0,NSHeight(tBounds)) operation:NSCompositeSourceOver];
    }
    
    // Draw the halo if needed
    
    if ([_window isKeyWindow])
    {
        if (_flags.displayFocus==YES)
        {
            NSRect tRect = [self bounds];
            NSBezierPath * tBezierPath;
            float tRadius;
            
            tRadius=(NSHeight(tRect)-1)*0.5;
            
            tBezierPath=[NSBezierPath bezierPath];
            
            [tBezierPath moveToPoint:NSMakePoint(tRadius,NSHeight(tRect))];
            
            [tBezierPath lineToPoint:NSMakePoint(NSWidth(tRect)-tRadius,NSHeight(tRect))];
            
            [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(NSWidth(tRect)-tRadius,tRadius+1)
                                                    radius:tRadius
                                                startAngle:90
                                                  endAngle:-90
                                                 clockwise:YES];
                                                
            [tBezierPath lineToPoint:NSMakePoint(tRadius,1)];
            
            [tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tRadius,tRadius+1)
                                                    radius:tRadius
                                                startAngle:-90
                                                  endAngle:90
                                                 clockwise:YES];
            
            [NSGraphicsContext saveGraphicsState]; 
            
            NSSetFocusRingStyle(NSFocusRingOnly); 
            
            [tBezierPath fill];
            
            [tBezierPath removeAllPoints];
            
            [NSGraphicsContext restoreGraphicsState]; 
        }
    }
    
    tOffset=(_flags.showCancelButtons==NO) ? WBSEARCHTEXTFIELD_WIDTH_OFFSET : WBSEARCHTEXTFIELD_CANCEL_OFFSET;
    
    [[self cell] drawWithFrame:NSMakeRect(WBSEARCHTEXTFIELD_MAGNIFY_OFFSET,4,NSWidth(tBounds)-tOffset,NSHeight(tBounds)-6) inView:self];
    
    if (_flags.showCancelButtons==YES)
    {
        // Draw the cancel buttons
        
        [[_stopImages objectAtIndex:3] compositeToPoint:NSMakePoint(NSWidth(tBounds)-18,NSHeight(tBounds)-2.5) operation:NSCompositeSourceOver];
    }
}

- (void)mouseDown:(NSEvent *) theEvent
{
    NSPoint tMouseLoc=[self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect tRect;
    NSRect tBounds=[self bounds];
    NSRect tCancelRect;
    
    // Check if the click is on the PopUp
    
    tRect=NSMakeRect(0,0,WBSEARCHTEXTFIELD_MAGNIFY_OFFSET-2,NSHeight(tBounds));
    
    tCancelRect=NSMakeRect(NSWidth(tBounds)-20,0,20,NSHeight(tBounds));
    
    if (NSMouseInRect(tMouseLoc,tRect,[self isFlipped])==YES)
    {
        NSEvent * tEvent;
        
        [self selectText:self];
        
        tRect=[self bounds];
        
        tMouseLoc=[self convertPoint:NSMakePoint(NSMinX(tRect)+5,NSHeight(tRect)+4) toView:nil];
        
        tEvent=[NSEvent mouseEventWithType:[theEvent type]
                                  location:tMouseLoc
                             modifierFlags:[theEvent modifierFlags]
                                 timestamp:[theEvent timestamp]
                              windowNumber:[theEvent windowNumber]
                                   context:[theEvent context]
                               eventNumber:[theEvent eventNumber]
                                clickCount:[theEvent clickCount]
                                  pressure:[theEvent pressure]];
        
        [NSMenu popUpContextMenu:[self menu]
                       withEvent:tEvent
                         forView:self];
    
        
    }
    else if (_flags.showCancelButtons==YES &&
             NSMouseInRect(tMouseLoc,tCancelRect,[self isFlipped])==YES)
    {
        [self showCancelButton:NO];
        
        [self setStringValue:@""];
    
        // Or send a selection
        
        if ([[self target] respondsToSelector:@selector(clearSearch:)])
        {
            [[self target] performSelector:@selector(clearSearch:) withObject:self];
        }
    }
    else
    {
        NSText* t = [_window fieldEditor: YES forObject: self];
        NSText * tObject;
        float tOffset=(_flags.showCancelButtons==NO) ? WBSEARCHTEXTFIELD_WIDTH_OFFSET : WBSEARCHTEXTFIELD_CANCEL_OFFSET;
        
        if ([t superview] != nil)
        {
            return;
        }
                
        tObject=[[self cell] setUpFieldEditorAttributes: t];
                
        _flags.displayFocus=YES;
        
        [[self cell] setDrawsBackground:YES];
        
        [[self cell] editWithFrame:NSMakeRect(WBSEARCHTEXTFIELD_MAGNIFY_OFFSET,4,NSWidth(tBounds)-tOffset,NSHeight(tBounds)-6)
                            inView:self
                            editor:tObject
                          delegate:self
                             event:theEvent];
        [[self cell] setDrawsBackground:NO];
    }
}

//- (void)_cancelKey:fp12;

- (void)resetCursorRects
{
    NSRect tBounds=[self bounds];
    
    
    [self addCursorRect:NSMakeRect(0,0,WBSEARCHTEXTFIELD_MAGNIFY_OFFSET-2,NSHeight(tBounds))
                 cursor:[NSCursor arrowCursor]];
    
    if ( _flags.showCancelButtons==NO)
    {
        [self addCursorRect:NSMakeRect(WBSEARCHTEXTFIELD_MAGNIFY_OFFSET-1,0,NSWidth(tBounds)-(WBSEARCHTEXTFIELD_MAGNIFY_OFFSET-2),NSHeight(tBounds))
                     cursor:[NSCursor IBeamCursor]];
    }
    else
    {
        [self addCursorRect:NSMakeRect(WBSEARCHTEXTFIELD_MAGNIFY_OFFSET-1,0,NSWidth(tBounds)-WBSEARCHTEXTFIELD_CANCEL_OFFSET,NSHeight(tBounds))
                     cursor:[NSCursor IBeamCursor]];
        
        [self addCursorRect:NSMakeRect(NSWidth(tBounds)-20,0,20,NSHeight(tBounds))
                     cursor:[NSCursor arrowCursor]];
    }
}

- (void)showCancelButton:(BOOL) aBool
{
    if (aBool!=_flags.showCancelButtons)
    {
        _flags.showCancelButtons=aBool;
        
        if (_flags.displayFocus)
        {
            NSText *tObject;
            NSRect tBounds=[self bounds];
            float tOffset;
            NSText *t = [_window fieldEditor: YES forObject: self];
            NSRange tRange;
            NSString * tString;
            id tCell=[self cell];
            
            tRange=[t selectedRange];
            
            _flags.exitFromTextDidEndEditing=YES;	// There must be a better solution
            
            tString = [[[t string] copy] autorelease];
            
            [tCell setStringValue: tString];
            
            [_window endEditingFor:t];
            
            tObject = [tCell setUpFieldEditorAttributes: t];
            
            tOffset=(_flags.showCancelButtons==NO) ? WBSEARCHTEXTFIELD_WIDTH_OFFSET : WBSEARCHTEXTFIELD_CANCEL_OFFSET;
            
            [tCell setDrawsBackground:YES];
            
            [tCell selectWithFrame: NSMakeRect(WBSEARCHTEXTFIELD_MAGNIFY_OFFSET,4,NSWidth(tBounds)-tOffset,NSHeight(tBounds)-6)
                                inView: self
                                editor: tObject
                                delegate: self
                                start: tRange.location
                                length: tRange.length];
            
            [tCell setDrawsBackground:NO];
        }
        
        [self resetCursorRects];
        
        [self setNeedsDisplay:YES];
    }
}

- (void)throbCancelButton:(BOOL) aBool
{
    _flags.throbCancelButton=aBool;
}

/*- (void)heartBeat:(void *)fp12
{
    if (_flags.showCancelButtons==YES && _flags.throbCancelButton==YES)
    {
        // The day Apple decides to make this API public, it will get implemented
    }
}*/

- (void)setNeedsDisplay:(BOOL) aBool
{
    
    [super setNeedsDisplay:aBool];
}

- (void)setKeyboardFocusRingNeedsDisplayInRect:(NSRect) aFrame
{
    
    [super setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
    if (_flags.exitFromTextDidEndEditing==NO)
    {
        NSMutableDictionary *d;
        id textMovement;
        NSFormatter *formatter;
        NSString *string;
        id tCell=[self cell];
        
        formatter = [tCell formatter];
        
        string = [[[[_window fieldEditor: YES
                            forObject: self] string] copy] autorelease];
    
        if (formatter == nil)
        {
            [tCell setStringValue: string];
        }
        else
        {
            id newObjectValue;
            NSString *error;
    
            if ([formatter getObjectValue: &newObjectValue 
                                forString: string 
                        errorDescription: &error] == YES)
            {
                [tCell setObjectValue: newObjectValue];
            }
            else
            {
                if ([_delegate respondsToSelector:@selector(control:didFailToFormatString:errorDescription:)]==YES)
                {
                    if ([_delegate control: self didFailToFormatString: string 
                                                    errorDescription: error] == YES)
                    {
                        [tCell setStringValue: string];
                    }
                }
            }
        }
        
        _flags.displayFocus=NO;
        
        [tCell endEditing:[notification object]];
        
        d = [[NSMutableDictionary alloc] initWithDictionary: [notification userInfo]];
        [d setObject: [notification object] forKey: @"NSFieldEditor"];
        [[NSNotificationCenter defaultCenter] postNotificationName: NSControlTextDidEndEditingNotification
                                                            object: self
                                                        userInfo: d];
        [d release];
        
        textMovement = [[notification userInfo] objectForKey: @"NSTextMovement"];
    
        if (textMovement)
        {
            switch ([(NSNumber *)textMovement intValue])
            {
                case NSReturnTextMovement:
                    if ([self sendAction: [self action] to: [self target]] == NO)
                    {
                        NSEvent *event = [_window currentEvent];
    
                        if ([self performKeyEquivalent: event] == NO &&
                            [_window performKeyEquivalent: event] == NO)
                        {
                            [self selectText: self];
                            return;
                        }
                    }
                    break;
                case NSTabTextMovement:
            
                    [_window selectKeyViewFollowingView: self];
    
                    if ([_window firstResponder] == _window)
                    {
                        [self selectText: self];
                        return;
                    }
                    break;
                case NSBacktabTextMovement:
                    
                    [_window selectKeyViewPrecedingView: self];
    
                    if ([_window firstResponder] == _window)
                    {
                        [self selectText: self];
                        return;
                    }
                    break;
            }
        }
        
        if ([[self stringValue] length]==0)
        {
            [self displayGraySearchScopeIfAppropriate:YES];
        }
    }
    else
    {
        _flags.exitFromTextDidEndEditing=NO;
    }
}

- (void)_setFocusNeedsDisplay
{
    _flags.displayFocus=YES;
    
    [self setNeedsDisplay:YES];
}

@end
