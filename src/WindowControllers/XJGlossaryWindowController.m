//
//  XJGlossaryWindowController.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Jan 23 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJGlossaryWindowController.h"
#import "XJPreferences.h"

#define kGlossaryAutosaveName @"GlossaryAutosaveName"
#define kGlossaryFilePath [XJGetLocalAppSupportDir() stringByAppendingPathComponent: @"Glossary.plist"]
	
@implementation XJGlossaryWindowController
@synthesize glossary;
- (instancetype)init
{
	self = [super initWithWindowNibName: @"GlossaryWindow"];
    if(self) {
		if(![self fileExists: kGlossaryFilePath])
			[self writeExampleGlossaryFile];
			
		[self readGlossaryFile];
		[[self window] setFrameAutosaveName: kGlossaryAutosaveName];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name: NSApplicationWillTerminateNotification
                                                   object:nil];

    }
    return self;
}



- (void)applicationWillTerminate: (NSNotification *)note
{
	[self writeGlossaryFile];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: @([[self window] isVisible])
																		forKey: @"XJGlossaryWindowIsOpen"];
}

- (BOOL)fileExists:(NSString *)path
{
    BOOL isDir;
    NSFileManager *man = [NSFileManager defaultManager];
    BOOL exists = [man fileExistsAtPath: path isDirectory: &isDir];
	return exists;
}

- (void)readGlossaryFile {
	NSMutableArray *tempGloss = [NSMutableArray array];
	
	NSArray *file = [NSArray arrayWithContentsOfFile: kGlossaryFilePath];
	for (NSDictionary *item in file) {
		NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
		[tempDict addEntriesFromDictionary: item];
		[tempGloss addObject: tempDict];
	}
	
	[self setGlossary: tempGloss];
}

- (void)writeGlossaryFile {
	[[self glossary] writeToFile: kGlossaryFilePath atomically: YES];
}

#warning Still needs work!
- (void)writeExampleGlossaryFile
{
    NSString *exPath = [[NSBundle mainBundle] pathForResource: @"ExampleGlossary" ofType: @"plist"];
	NSFileManager *man = [NSFileManager defaultManager];
	[man copyItemAtPath:exPath toPath:kGlossaryFilePath error:nil];
}

@end
