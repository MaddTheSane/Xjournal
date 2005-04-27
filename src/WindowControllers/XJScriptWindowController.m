#import "XJScriptWindowController.h"

@interface XJScriptWindowController (Private)
- (void)loadScripts;
@end

@implementation XJScriptWindowController
- (id)initWithWindowNibName: (NSString *)name {
	self = [super initWithWindowNibName: name];
	if(self) { 
		[self setScripts: [NSMutableArray array]];
		[self loadScripts];
	}
	return self;
}

- (void)windowDidLoad {
	NSLog(@"WindowDidLoad");

	[table setTarget: self];
	[table setDoubleAction: @selector(runSelectedScript:)];
}

- (IBAction)runSelectedScript: (id)sender {
	NSDictionary *scriptPath = [[tableArrayController selectedObjects] objectAtIndex: 0];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"XJRunScriptNotification"
														object: [scriptPath objectForKey:@"path"]];
}

// =========================================================== 
// - scripts:
// =========================================================== 
- (NSMutableArray *)scripts {
    return scripts; 
}

// =========================================================== 
// - setScripts:
// =========================================================== 
- (void)setScripts:(NSMutableArray *)aScripts {
    [aScripts retain];
    [scripts release];
    scripts = aScripts;
}

- (NSString *)directory {
	return [@"~/Library/Application Support/Xjournal/Scripts" stringByExpandingTildeInPath];
}
@end

@implementation XJScriptWindowController (Private)
- (void)loadScripts {
	NSString *root = [self directory];
	NSEnumerator *en = [[NSFileManager defaultManager] enumeratorAtPath: root];
	NSString *path;

	while(path = [en nextObject]) {
		NSString *fullPath = [NSString stringWithFormat: @"%@/%@", root, path];
		NSLog(@"Found Script: %@", fullPath);
		[[self mutableArrayValueForKey: @"scripts"] addObject: [NSDictionary dictionaryWithObject: fullPath 
																						   forKey: @"path"]];
	}
}
@end