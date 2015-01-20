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

#import <AppKit/AppKit.h>

typedef struct __SFFlags
{
#ifdef __BIG_ENDIAN__
    unsigned int		showCancelButtons:1;
    unsigned int		displayGraySearchScope:1;
    unsigned int		displayFocus:1;
    unsigned int 		throbCancelButton:1;
    unsigned int 		exitFromTextDidEndEditing:1;
#else
    unsigned int 		exitFromTextDidEndEditing:1;
    unsigned int 		throbCancelButton:1;
    unsigned int		displayFocus:1;
    unsigned int		displayGraySearchScope:1;
    unsigned int		showCancelButtons:1;
#endif
} _SFFlags; 

@interface WBSearchTextField : NSTextField
{
    NSImage * _leftCapImage;
    NSImage * _middleImage;
    NSImage * _rightCapImage;
    NSImage * _completeImage;
    NSMutableArray * _stopImages;
    _SFFlags _flags;
}

- (BOOL)isDisplayingGraySearchScope;
- (void)displayGraySearchScopeIfAppropriate:(BOOL) aBool;
- (void)removeGraySearchScope;

- (void)_loadImagesIfNecessary;
- (NSImage *) backgroundImage;

- (void)resetCursorRects;

- (void)showCancelButton:(BOOL) aBool;
- (void)throbCancelButton:(BOOL) aBool;

- (void)setKeyboardFocusRingNeedsDisplayInRect:(NSRect) aFrame;
- (void)_setFocusNeedsDisplay;

@end

/*
    - (void)searchPopupChanged:(id) sender;
    - (void)clearSearch:(id) sender;
	- (void)performSearch:(id) sender;
*/
