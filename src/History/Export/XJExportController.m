//
//  XJExportController.m
//  Xjournal
//
//  Created by Fraser Speirs on 09/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJExportController.h"
#import "XJExportManager.h"
#import "XJExportPluginProtocol.h"
#import <LJKit/LJKit.h>

@interface XJExportController (Private)
- (void)loadPluginAtPath: (NSString *)path;
- (void)loadExportBundles;
@end

@implementation XJExportController
- (void)exportFromAccount: (LJAccount *)acct {
	[exportMgr release];
	exportMgr = [[XJExportManager alloc] initWithAccount: acct];

	if(![self window]) {
		[NSBundle loadNibNamed: @"ExportManager" owner: self];
		[self loadExportBundles];
	}
	
	[self showWindow: self];
}

- (IBAction)cancelExport:(id)sender {
	[[self window] orderOut: self];
}

- (IBAction)startExport:(id)sender {
	NSString *ident = [[tabs selectedTabViewItem] identifier];
	id selectedPlugin = [plugins objectForKey: ident];
	
	[selectedPlugin export];
}

- (void)showWindow: (id)sender {
	while([tabs numberOfTabViewItems] != 0) {
		[tabs removeTabViewItem: [tabs tabViewItemAtIndex:0]];
	}
	
	int i;
	for(i=0; i < [[plugins allKeys] count]; i++) {
		NSString *key = [[plugins allKeys] objectAtIndex: i];
		id <XJExportPluginProtocol> plugin = [plugins objectForKey: key];
		
		NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier: [plugin identifier]];
		[item setLabel: [plugin visibleName]];
		[item setView: [plugin pluginView]];
		[tabs addTabViewItem: [item autorelease]];
	}
	
	[super showWindow: sender];
}
@end 

@implementation XJExportController (Private)
- (void)loadExportBundles {
	plugins = [[NSMutableDictionary dictionary] retain];
	
	NSString *pluginPath = [[NSBundle mainBundle] builtInPlugInsPath];
	NSLog(@"Looking in %@ for plugins", pluginPath);
	
	NSEnumerator *fileEnum = [[[NSFileManager defaultManager] directoryContentsAtPath: pluginPath] objectEnumerator];
	NSString *aPlugPath;
	while(aPlugPath = [fileEnum nextObject]) {
		NSLog(@"Looking at %@ (%@)", aPlugPath, [aPlugPath lastPathComponent]);
		if([[aPlugPath lastPathComponent] hasSuffix: @"xjhistoryexporter"]) {
			NSLog(@"Loading bundle: %@", [NSString stringWithFormat: @"%@/%@", pluginPath, aPlugPath]);
			[self loadPluginAtPath: [NSString stringWithFormat: @"%@/%@", pluginPath, aPlugPath]];
		}
	}
}

- (void)loadPluginAtPath: (NSString *)path {
	NSBundle *plugBundle = [NSBundle bundleWithPath: path];
	NSDictionary *plugDict = [plugBundle infoDictionary];
	NSString *plugName = [plugDict objectForKey: @"NSPrincipalClass"];
	if(plugName) {
		NSLog(@"Loading %@", plugName);
		Class plugClass = NSClassFromString(plugName);
		if(!plugClass) {
			plugClass = [plugBundle principalClass];
		}
		
		if([plugClass conformsToProtocol: @protocol(XJExportPluginProtocol)] &&
		   [plugClass isKindOfClass: [NSObject class]])
		{
			id obj = [[plugClass alloc] initWithExportManager: exportMgr bundle: plugBundle];
			[plugins setObject: obj forKey: [obj identifier]];
			NSLog(@"Added object");
		}
		else {
			NSLog(@"%@ doesn't conform to the protocol", plugName);
		}
	}
}
@end
