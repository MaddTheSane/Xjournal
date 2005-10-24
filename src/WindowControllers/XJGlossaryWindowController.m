//
//  XJGlossaryWindowController.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Jan 23 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJGlossaryWindowController.h"
#import "XJPreferences.h"
#import "XJFileSystemFolder.h"
#import "XJFileSystemFile.h"

#define kGlossaryAutosaveName @"GlossaryAutosaveName"

#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (254.0 / 255.0)

@implementation XJGlossaryWindowController
- (id)init
{
    if(self == [super initWithWindowNibName: @"Glossary"]) {
        [[self window] setFrameAutosaveName: kGlossaryAutosaveName];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name: NSApplicationWillTerminateNotification
                                                   object:nil];
        [self checkForAndCreateGlossaryDirectory];
        rootItem = [[XJFileSystemFolder alloc] initWithPath: LOCAL_GLOSSARY];
        return self;
    }
    return nil;
}

- (void)dealloc
{
    [rootItem release];
    [super dealloc];
}

- (void)applicationWillTerminate: (NSNotification *)note
{
    [PREFS setBool: [[self window] isVisible] forKey: kGlossaryWindowOpen];
}

- (void)windowDidLoad
{
    // Set up NSToolbar
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: kGlossaryWindowToolbarIdentifier];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDelegate: self];
    [[self window] setToolbar: toolbar];
    [toolbar release];
    
    [outline registerForDraggedTypes: [NSArray arrayWithObjects: NSStringPboardType, nil]];
    [outline setDoubleAction: @selector(insertSelection:)];
    [outline setTarget: self];
    [self refresh: self];
}

- (IBAction)refresh:(id)sender
{
    [rootItem release];
    rootItem = [[XJFileSystemFolder alloc] initWithPath: LOCAL_GLOSSARY];
    [outline reloadData];
}

- (IBAction)showWindow:(id)sender
{
	/* Not a good idea?
	 if([[self window] isVisible]) {
		[[self window] orderOut:self];
	}
	else {
		*/
		[outline reloadData];
		[super showWindow: sender];
	//}
}

/*
 - (void)loadGlobalGlossary
 {
     NSString *globalDir = [self globalGlossaryPath];
     if([self directoryExists: globalDir]) {
         [self loadStringsFromDirectory: globalDir];
     }
 }
 
 - (void)loadLocalGlossary
 {
     NSString *localDir = [self localGlossaryPath];
     if([self directoryExists: localDir]) {
         [self loadStringsFromDirectory: localDir];
     }
 }

 - (void)loadStringsFromDirectory: (NSString *)dir
 {
     NSFileManager *man = [NSFileManager defaultManager];
     NSDirectoryEnumerator *e = [man enumeratorAtPath: dir];
     NSString *file;
     while(file = [e nextObject]) {
         if(![file hasPrefix: @"."]) {
             NSString *filePath = [NSString stringWithFormat: @"%@/%@", dir, file];
             NSString *contents = [NSString stringWithContentsOfFile: filePath];
             if(contents)
                 [entries setObject: [NSArray arrayWithObjects: contents, file, nil] forKey: filePath];
         }
     }
 }
*/

- (BOOL)directoryExists:(NSString *)path
{
    BOOL isDir;
    NSFileManager *man = [NSFileManager defaultManager];
    return [man fileExistsAtPath: path isDirectory: &isDir];
}

- (NSString *)localGlossaryPath {
    NSString *path = [LOCAL_APPSUPPORT stringByAppendingString: @"/Glossary"];
    return path;
}

- (NSString *)globalGlossaryPath {
    NSString *path = [GLOBAL_APPSUPPORT stringByAppendingString: @"/Glossary"];
    return path;
}

- (IBAction)copySelectionToClipboard:(id)sender
{
    //if([outline selectedRow] != -1)
        //[self outlineView: outline writeRows: [NSArray arrayWithObjects: [NSNumber numberWithInt: [outline selectedRow]], nil] toPasteboard: [NSPasteboard generalPasteboard]];
}

- (IBAction)openLocalGlossary:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile: [self localGlossaryPath]];
}

- (IBAction)insertSelection:(id)sender
{
    if([outline selectedRow] != -1) {
        id item = [outline itemAtRow: [outline selectedRow]];
        NSData *contentData = [[NSFileManager defaultManager] contentsAtPath: [item path]];
        if(contentData) {
            NSString *contents = [[NSString alloc] initWithData:contentData encoding: NSUTF8StringEncoding];
            if(contents)            
                [[NSNotificationCenter defaultCenter] postNotificationName:XJGlossaryInsertEvent object: contents];
        }
    }
}

- (void)checkForAndCreateGlossaryDirectory
{
    BOOL isDir;
    NSFileManager *man = [NSFileManager defaultManager];
    if(![man fileExistsAtPath: LOCAL_GLOSSARY isDirectory: &isDir]) {
        [man createDirectoryAtPath: LOCAL_GLOSSARY attributes: nil];
        [self writeExampleGlossaryFile];
        [self refresh: self];
    }

    if(![man fileExistsAtPath: GLOBAL_GLOSSARY isDirectory: &isDir]) {
        [man createDirectoryAtPath: GLOBAL_GLOSSARY attributes: nil];
    }
}

- (void)writeExampleGlossaryFile
{
    NSString *exPath = [[NSBundle mainBundle] pathForResource: @"SampleFile" ofType: @"txt"];
    NSString *srcDirectory = [exPath stringByDeletingLastPathComponent];
        
    [[NSWorkspace sharedWorkspace] performFileOperation: NSWorkspaceCopyOperation
                                                 source: srcDirectory
                                            destination: LOCAL_GLOSSARY
                                                  files: [NSArray arrayWithObjects: @"SampleFile.txt", nil]
                                                    tag: 0];
}

// Outline Delegate Stuff
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item) {
        if([item isKindOfClass: [XJFileSystemFolder class]])
            return [item numberOfChildren];
        else
            return 0;
    }
    else {
        return [(XJFileSystemFolder *)rootItem numberOfChildren];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
    if([[tableColumn identifier] isEqualToString:@"file"]) {
        NSString *path = [item path];
        return [[NSFileManager defaultManager] displayNameAtPath:path];
    }
    else {
        return @"File contents";
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn*)tableColumn item:(id)item
{
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item) {
        if([item isKindOfClass: [XJFileSystemFolder class]]) {
            return [item childAtIndex: index];
        }
        else
        {
            return nil;
        }
    }
    else {
        return [(XJFileSystemFolder *)rootItem childAtIndex: index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [item isKindOfClass: [XJFileSystemFolder class]];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    int row = [outline selectedRow];
    id item = [outline itemAtRow: row];
    if([item isKindOfClass: [XJFileSystemFile class]]) {
        NSData *contentData = [[NSFileManager defaultManager] contentsAtPath: [item path]];
        if(contentData) {
            NSString *contents = [[NSString alloc] initWithData:contentData encoding: NSUTF8StringEncoding];
            if(contents)
                [textView setString: contents];
        }
    }
}

// Drag and drop
- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
    id item;
    NSMutableString *data = [[NSMutableString alloc] init];
    int i;    
    for(i=0; i < [items count]; i++) {
        item = [items objectAtIndex:i];
        NSData *dataContent = [[NSFileManager defaultManager] contentsAtPath:[item path]];
        if(dataContent) {
            NSString *fileContent = [[NSString alloc] initWithData: dataContent encoding: NSUTF8StringEncoding];
            if(fileContent) {
                [data appendString: fileContent];
            }
            [fileContent release];
        }
    }
    
    [pboard declareTypes: [NSArray arrayWithObjects: NSStringPboardType, nil] owner:self];
    NSString *final = [[NSString alloc] initWithString: data];
    return [pboard setString: [final autorelease] forType: NSStringPboardType];
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return NSDragOperationEvery;
}

@end
