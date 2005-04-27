//
//  XJDocument.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>
#import <OmniAppKit/OmniAppKit.h>
#import <WebKit/WebKit.h>

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

@interface XJDocument : NSDocument
{
    // ----------------------------------------------------------------------------------------
    // Window outlets
    // ----------------------------------------------------------------------------------------
    IBOutlet NSTextView *theTextView;
    IBOutlet NSTextField *theSubjectField, *theMusicField, *statusField;
    IBOutlet NSPopUpButton *journalPop;
    IBOutlet NSComboBox *moods;
    IBOutlet NSProgressIndicator *spinner;

    // The entry associated with the window
    LJEntry *entry;

    // Cache thtoolbar items
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
    IBOutlet NSPopUpButton *security, *userpic;
    IBOutlet NSTableView *friendsTable;
    IBOutlet NSImageView *userPicView;
    IBOutlet NSButton *preformattedChk, *noCommentsChk, *backdatedChk, *noEmailChk;
    IBOutlet NSTextField *backdateField;

    // ----------------------------------------------------------------------------------------
    // Window title storage
    // ----------------------------------------------------------------------------------------
    NSString *originalWindowName;
    
    // ----------------------------------------------------------------------------------------
    // HTML Preview
    // ----------------------------------------------------------------------------------------
    IBOutlet NSWindow *htmlPreviewWindow;
    IBOutlet WebView *htmlPreview;
    
    // ----------------------------------------------------------------------------------------
    // iTunes Music Store
    // ----------------------------------------------------------------------------------------
    NSString *iTMSLinks;
    //IBOutlet NSImageView *iTMSIndicator;
}

- (id)initWithEntry: (LJEntry *)entry;

/* Accessors for the fields */
- (void)setSubjectField: (NSString *)newText;
- (void)setBodyText: (NSString *)newText;

/* Actions for posting */
- (BOOL)postEntryAndReturnStatus;
- (void)postEntryAndDiscardLocalCopy:(id)sender;

    // Popup targets
- (IBAction)setSelectedJournal:(id)sender;
- (IBAction)setSelectedMood:(id)sender;

/* Builder code */
- (void)buildJournalPopup;
- (void)buildMoodPopup;
- (IBAction)detectMusicNow:(id)sender;

- (void)setStatus: (NSString *)newStatus;


- (NSWindow *)window;
- (void)startSheet:(NSWindow *)sheet;

- (IBAction)saveWindowSize:(id)sender;

- (void)setEntryToEdit: (LJEntry *)entry;
- (void)initUI;

// ----------------------------------------------------------------------------------------
// Drawer handling
// ----------------------------------------------------------------------------------------
- (IBAction)setValueForSender:(id)sender;
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

- (IBAction)insertLJCut:(id)sender;
- (IBAction)insertLJUser:(id)sender;

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
@end
