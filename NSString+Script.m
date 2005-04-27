//
//  NSString+Script.m
//  Xjournal
//
//  Created by Fraser Speirs on 29/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSString+Script.h"
#include <unistd.h>

@implementation NSString (XJScript)
- (NSString *)stringByRunningShellScript: (NSString *)scriptPath {
	
	//NSData *templateBytes = [@"/tmp/xjshellscripting.XXXXXX" dataUsingEncoding: NSASCIIStringEncoding];
	//NSString *filePath  = [NSString stringWithCString: mktemp((char *)[templateBytes bytes])];
	
	NSString *filePath = nil;
	
	do { // Find a unique non-existing file name in /tmp
		CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
		NSString *uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
		CFRelease(uuid);
		filePath = [NSString stringWithFormat: @"/tmp/%@.txt", uuidString];
	} while([[NSFileManager defaultManager] fileExistsAtPath: filePath]);
		
	if(!filePath) 
		return [[self copy] autorelease];
	
	// Write self into that file
	[self writeToFile: filePath atomically: YES];
	
	// Create task and args.  The technique here is that
	// we write the file as above and then call the task
	// passing the path to the file as $1.
	NSPipe *outPipe = [NSPipe pipe];
	NSFileHandle *outFileHandle = [outPipe fileHandleForReading];
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: scriptPath];
	[task setArguments: [NSArray arrayWithObject: filePath]];
	[task setStandardOutput: outPipe];
	
	// Launch and do this synchronously
	NSLog(@"Launching: %@ %@", scriptPath, [[task arguments] description]);
	[task launch];
	
	NSData *data = [outFileHandle readDataToEndOfFile];
	
	[task waitUntilExit];
	[task release];
	task = nil;
	
	// Delete the temp file
	[[NSFileManager defaultManager] removeFileAtPath: filePath handler: nil];
	
	// Check for an error
	if([task terminationStatus] != 0) {
		// Problem with the script, so just return a copy of ourselves.
		// Maybe an NSException should be thrown instead.
		return [[self copy] autorelease];
	}
	else {
		// Success, so suck out the stdout and return it as an autoreleased string.
		NSString *str = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		NSLog(@"Output:\n%@", str);
		return [str autorelease];
	}
}


@end
