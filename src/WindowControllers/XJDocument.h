//
//  XJDocument.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>
#import <WebKit/WebKit.h>
#import <DisclosableView/DisclosableView.h>

#import "XJMusic.h"

#define kHTMLMenuTag 50
#define kPostMenuTag 100
#define kPostToolbarItemTag 100

#define kEditWindowToolbarIdentifier @"kEditWindowToolbarIdentifier"
#define kEditPostItemIdentifier @"kEditPostItemIdentifier"
#define kEditPostAndDiscardItemIdentifier @"kEditPostAndDiscardItemIdentifier"
#define kEditSaveItemIdentifier @"kEditSaveItemIdentifier"
#define kEditDetectMusicItemIdentifier @"kEditDetectMusicItemIdentifier"

#define kEditDrawerToggleItemIdentifier @"kEditDrawerToggleItemIdentifier"

#define kEditURLLinkItemIdentifier @"kEditURLLinkItemIdentifier"
#define kEditImageLinkItemIdentifier @"kEditImageLinkItemIdentifier"

#define kEditUserLinkItemIdentifier @"kEditUserLinkItemIdentifier"
#define kEditCommunityLinkItemIdentifier @"kEditCommunityLinkItemIdentifier"
#define kEditLJCutItemIdentifier @"kEditLJCutItemIdentifier"

#define kEditBlockquoteItemIdentifier @"kEditBlockquoteItemIdentifier"
#define kEditBoldItemIdentifier @"kEditBoldItemIdentifier"
#define kEditItalicItemIdentifier @"kEditItalicItemIdentifier"
#define kEditUnderlineItemIdentifier @"kEditUnderlineItemIdentifier"

@class XJAccountManager;
@class XJGroupAccessValueTransformer;
@class XJKeywordToImageValueTransformer;
@class XJHTMLEditView;

@interface XJDocument : NSDocument
{
    // ----------------------------------------------------------------------------------------
    // Window outlets
    // ----------------------------------------------------------------------------------------
    IBOutlet XJHTMLEditView *theTextView;
    IBOutlet NSTextField *theSubjectField, *theMusicField, *statusField;
    IBOutlet NSPopUpButton *journalPop;
    IBOutlet NSComboBox *moods;
    IBOutlet NSProgressIndicator *spinner;

    // The entry associated with the window
    LJEntry *entry;

	// The XJAccountManager, so we can bind the Account popup
	XJAccountManager *accountManager;
	
	// Value transformer
	XJGroupAccessValueTransformer *groupAccessVT;
	XJKeywordToImageValueTransformer *userpicTransformer;
    // Cache the toolbar items
    NSMutableDictionary *toolbarItemCache;


    // ----------------------------------------------------------------------------------------
    // HTML Tools Nib connections
    // ----------------------------------------------------------------------------------------
    IBOutlet NSWindow *hrefSheet, *imgSheet, *userSheet, *commSheet, *cutSheet;
    NSWindow *currentSheet;

    // ----------------------------------------------------------------------------------------
    // HTML Sheet
    // ----------------------------------------------------------------------------------------
    IBOutlet NSTextField *html_hrefField, *html_TitleField, *html_LinkTextField;
    IBOutlet NSComboBox *html_targetCombo;

    // ----------------------------------------------------------------------------------------
    // Image sheet connections
    // ----------------------------------------------------------------------------------------
    IBOutlet NSTextField *srcField, *altField, *sizeWidth, *sizeHeight, *spaceWidth, *spaceHeight, *borderSize;
    IBOutlet NSPopUpButton *alignPop;

    // ----------------------------------------------------------------------------------------
    // Community and User sheets
    // ----------------------------------------------------------------------------------------
    IBOutlet NSComboBox *comm_nameCombo, *user_nameCombo;
    IBOutlet NSButton *comm_OKButton, *user_OKButton;

    // ----------------------------------------------------------------------------------------
    // Cut sheet
    // ----------------------------------------------------------------------------------------
    IBOutlet NSTextField *cut_textField;
    IBOutlet NSTextView *cut_textView;

    // ----------------------------------------------------------------------------------------
    // Drawer
    // ----------------------------------------------------------------------------------------
    IBOutlet NSDrawer *drawer;
    IBOutlet NSTableView *friendsTable;
	IBOutlet NSPopUpButton *formatPopup;
	
    // ----------------------------------------------------------------------------------------
    // Window title storage
    // ----------------------------------------------------------------------------------------
    NSString *originalWindowName;
    
    // ----------------------------------------------------------------------------------------
    // HTML Preview
    // ----------------------------------------------------------------------------------------
    IBOutlet NSWindow *htmlPreviewWindow;
    IBOutlet WebView *htmlPreview;
    NSTimer *previewUpdateTimer;
	IBOutlet SNDisclosableView *disclosableView;
	IBOutlet NSProgressIndicator *markdownSpinner;
	
    // ----------------------------------------------------------------------------------------
    // Music
    // ----------------------------------------------------------------------------------------
    XJMusic *currentMusic;
}

- (id)initWithEntry: (LJEntry *)entry;

/* Actions for posting */
- (BOOL)postEntryAndReturnStatus;
- (void)postEntryAndDiscardLocalCopy:(id)sender;

/* Builder code */
- (IBAction)detectMusicNow:(id)sender;

- (NSWindow *)window;
- (void)startSheet:(NSWindow *)sheet;

- (IBAction)saveWindowSize:(id)sender;

- (void)initUI;

// ----------------------------------------------------------------------------------------
// Entry accessors
// ----------------------------------------------------------------------------------------
- (LJEntry *)entry;
- (void)setEntry:(LJEntry *)anEntry;

// ----------------------------------------------------------------------------------------
// Account Manager accessors
// ----------------------------------------------------------------------------------------
- (XJAccountManager *)accountManager;
- (void)setAccountManager:(XJAccountManager *)anAccountManager;

// ----------------------------------------------------------------------------------------
// Drawer handling
// ----------------------------------------------------------------------------------------
- (IBAction)toggleDrawer: (id)sender;

// ----------------------------------------------------------------------------------------
// HTML tools
// ----------------------------------------------------------------------------------------
- (void)genericTagWrapWithStart: (NSString *)tagStart andEnd: (NSString *)tagEnd;
- (void)insertStringAtSelection:(NSString *)newString;
- (IBAction)insertLink:(id)sender;
- (IBAction)insertImage:(id)sender;
- (IBAction)getImageDimensions:(id)sender;
- (IBAction)insertBlockquote:(id)sender;
- (IBAction)insertBold:(id)sender;
- (IBAction)insertItalic:(id)sender;
- (IBAction)insertUnderline:(id)sender;
- (IBAction)insertCenter:(id)sender;
- (IBAction)insertCode:(id)sender;
- (IBAction)insertTT:(id)sender;

- (IBAction)insertLJCut:(id)sender;
- (IBAction)insertLJUser:(id)sender;

- (IBAction)setEntryFormat:(id)sender;
- (void)setEntryFormatToValue: (int)formatType;

- (IBAction)closeSheet:(id)sender;
- (IBAction)commitSheet:(id)sender;

// Button enablers for User and comm sheets
- (IBAction)enableOKButton:(id)sender;

    // ----------------------------------------------------------------------------------------
    // HTML Preview
    // ----------------------------------------------------------------------------------------
- (NSWindow *)htmlPreviewWindow;
- (WebView *)htmlPreview;
- (void)setHTMLPreviewWindowTitle:(NSString *)title;
- (void)updatePreviewWindow: (NSString *)textContent;
- (IBAction)showPreviewWindow: (id)sender;
- (void)closeHTMLPreviewWindow;


// ----------------------------------------------------------------------------------------
// Music
// ----------------------------------------------------------------------------------------
- (XJMusic *)currentMusic;
- (void)setCurrentMusic:(XJMusic *)aCurrentMusic;

@end
