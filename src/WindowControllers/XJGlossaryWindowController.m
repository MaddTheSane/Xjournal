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
#define kGlossaryFilePath [@"~/Library/Application Support/Xjournal/Glossary.plist" stringByExpandingTildeInPath]
	
@implementation XJGlossaryWindowController
- (id)init
{
	self == [super initWithWindowNibName: @"Glossary"];
    if(self) {
		if([self fileExists: kGlossaryFilePath])
			[self readGlossaryFile];
		else {
			[self setGlossary: [NSMutableArray array]];
			[[self mutableArrayValueForKey: @"glossary"] addObject: [NSMutableDictionary dictionaryWithObject: @"hello world" forKey: @"text"]];
			[[self mutableArrayValueForKey: @"glossary"] addObject: [NSMutableDictionary dictionaryWithObject: @"hello world" forKey: @"text"]];
			[[self mutableArrayValueForKey: @"glossary"] addObject: [NSMutableDictionary dictionaryWithObject: @"hello world" forKey: @"text"]];
			[[self mutableArrayValueForKey: @"glossary"] addObject: [NSMutableDictionary dictionaryWithObject: @"hello world" forKey: @"text"]];
			[[self mutableArrayValueForKey: @"glossary"] addObject: [NSMutableDictionary dictionaryWithObject: @"hello world" forKey: @"text"]];
		}
        [[self window] setFrameAutosaveName: kGlossaryAutosaveName];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name: NSApplicationWillTerminateNotification
                                                   object:nil];

        return self;
    }
    return nil;
}

- (void)dealloc
{
    [glossary release];
    [super dealloc];
}


// =========================================================== 
// - glossary:
// =========================================================== 
- (NSMutableArray *)glossary {
    return glossary; 
}

// =========================================================== 
// - setGlossary:
// =========================================================== 
- (void)setGlossary:(NSMutableArray *)aGlossary {
    if (glossary != aGlossary) {
        [aGlossary retain];
        [glossary release];
        glossary = aGlossary;
    }
}


- (void)applicationWillTerminate: (NSNotification *)note
{
	[self writeGlossaryFile];
    [PREFS setBool: [[self window] isVisible] forKey: XJGlossaryWindowIsOpenPreference];
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
	NSLog([file description]);
	NSEnumerator *en = [file objectEnumerator];
	NSDictionary *item;
	while(item = [en nextObject]) {
		NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
		NSLog([tempDict description]);
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
    NSString *exPath = [[NSBundle mainBundle] pathForResource: @"SampleFile" ofType: @"txt"];
	NSFileManager *man = [NSFileManager defaultManager];
	[man copyPath: exPath toPath: kGlossaryFilePath handler: nil];
}
@end
