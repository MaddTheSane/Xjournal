//
//  GetMetadataForFile.m
//  XJImport
//
//  Created by C.W. Betts on 2/22/15.
//
//

#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#include "GetMetadataForFile.h"


//==============================================================================
//
//	Get metadata attributes from document files
//
//	The purpose of this function is to extract useful information from the
//	file formats for your document, and set the values into the attribute
//  dictionary for Spotlight to include.
//
//==============================================================================

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef CFattributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    // Pull any available metadata from the file at the specified path
    // Return the attribute keys and attribute values in the dict
    // Return TRUE if successful, FALSE if there was no data provided
	// The path could point to either a Core Data store file in which
	// case we import the store's metadata, or it could point to a Core
	// Data external record file for a specific record instances

    BOOL ok = NO;
	@autoreleasepool {
		NSMutableDictionary * attributes = (__bridge NSMutableDictionary *)(CFattributes);
		NSDictionary *ourDict = [[NSDictionary alloc] initWithContentsOfFile:(__bridge NSString *)(pathToFile)];

		if (ourDict) {
			attributes[(NSString*)kMDItemTitle] = ourDict[@"Subject"];
			attributes[(NSString*)kMDItemTimestamp] = ourDict[@"Date"];
			attributes[(NSString*)kMDItemAuthors] = @[ourDict[@"JournalName"]];
			
			NSString *htmlData = ourDict[@"Content"];
			
			//TODO: trim out HTML code
			attributes[(NSString*)kMDItemTextContent] = htmlData;
			ok = YES;
		}
	}
	
	// Return the status
	return ok? TRUE : FALSE;
}
