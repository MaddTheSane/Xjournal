//
//  LJEntryExtensions.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Mar 20 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "LJEntryExtensions.h"
#import "XJPreferences.h"
#import "XJAccountManager.h"
#import <LJKit/LJKit.h>

#define kSubjectKey @"Subject"
#define kContentKey @"Content"
#define kMoodKey @"Mood"
#define kDateKey @"Date"
#define kBackdatedKey @"Backdated"
#define kNoCommentsKey @"NoComments"
#define kNoEmailKey @"NoEmail"
#define kMusicKey @"Music"
#define kPreformattedKey @"Preformatted"
#define kPictureKeywordKey @"PictureKeyword"
#define kJournalNameKey @"JournalName"
#define kSecurityModeKey @"SecurityMode"
#define kGroupAllowedMaskKey @"GroupMask"
#define kItemIDKey @"ItemID"
#define kPosterUsernameKey @"PosterUsername"
#define kANumKey @"aNum"

#define kCurrentFileFormatVersion 1
#define kCurrentFileFormatVersionKey @"EntryFileVersion"

@implementation LJEntry (XJExtensions)
- (BOOL)writePropertyListToFile:(NSString *)path atomically:(BOOL)flag
{
    return [[self propertyListRepresentation] writeToFile: path atomically: flag];
}

- (NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	
    // Encode subject
	if([self subject])
		[dictionary setObject: [self subject] forKey: kSubjectKey];
	
    // Encode Content
	if([self content])
		[dictionary setObject: [self content] forKey: kContentKey];
	
	
    [dictionary setObject: [self date] forKey: kDateKey];
	
    // Encode journal name
	if([[self journal] name])
		[dictionary setObject: [[self journal] name] forKey: kJournalNameKey];
	
    // Encode security mode
    if([self securityMode] != LJPublicSecurityMode) {
        [dictionary setObject: [NSNumber numberWithInt: [self securityMode]] 
					   forKey: kSecurityModeKey];
		
        [dictionary setObject: [NSNumber numberWithInt: [self groupsAllowedAccessMask]]
					   forKey: kGroupAllowedMaskKey];
    }
	
	
    if(_properties)
        [dictionary setObject: _properties forKey: @"props"];
    if(_customInfo)
        [dictionary setObject: _customInfo forKey: @"info"];
	
    // Encode poster user name
	if(_posterUsername)
		[dictionary setObject: _posterUsername forKey: kPosterUsernameKey];
	
    // Encode item ID
    [dictionary setObject: [NSNumber numberWithInt: _itemID]
				   forKey: kItemIDKey];
    [dictionary setObject: [NSNumber numberWithInt: _aNum]
				   forKey: kANumKey];
    
    // Set the current version of the file
    [dictionary setObject: [NSNumber numberWithInt: kCurrentFileFormatVersion]
				   forKey: kCurrentFileFormatVersionKey];
	
    return dictionary;
}

- (void)configureWithContentsOfFile: (NSString *)file
{
    NSMutableDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: file];
    [self configureFromPropertyListRepresentation: dict];
}

- (void)configureFromPropertyListRepresentation:(id)dict
{
    [self setSubject: [dict objectForKey: kSubjectKey] ? [dict objectForKey: kSubjectKey] : @""];
	[self setContent: [dict objectForKey: kContentKey] ? [dict objectForKey: kContentKey] : @""];
	
    _properties = [[self makeMutableDictionary: [dict objectForKey: @"props"]] retain];
    _customInfo = [[dict objectForKey: @"info"] retain];
    
    //if([self optionBackdated])
    [self setDate: [dict objectForKey: kDateKey]];
	
    LJJournal *journal = [[[XJAccountManager defaultManager] loggedInAccount] journalNamed: [dict objectForKey: kJournalNameKey]];
    if(journal)
        [self setJournal: journal];
    else
        [self setJournal: [[[XJAccountManager defaultManager] loggedInAccount] defaultJournal]];
	
    [self setSecurityMode: [[dict objectForKey: kSecurityModeKey] intValue]];
    if([self securityMode] != LJPublicSecurityMode)
        [self setGroupsAllowedAccessMask: [[dict objectForKey: kGroupAllowedMaskKey] intValue]];
	
    // Decode poster user name
    _posterUsername = [[dict objectForKey: kPosterUsernameKey] retain];
	
    // Encode item ID
    _itemID = [[dict objectForKey: kItemIDKey] intValue];
    _aNum = [[dict objectForKey: kANumKey] intValue];
}

- (NSString *)metadataHTML
{
	
    NSMutableString *meta = [[NSMutableString stringWithCapacity: 100] retain];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    if([self subject]) {
        [meta appendString: [NSString stringWithFormat: @"<strong>Subject:</strong>&nbsp;%@<br>", [self subject]]];
    }
	
	[meta appendString: @"<strong>Date:</strong>&nbsp;"];
	
	switch([[[self date] dateWithCalendarFormat: nil timeZone: nil] dayOfWeek]) {
		case 0:
			[meta appendString: NSLocalizedString(@"Sunday", @"Sunday")];
			break;
		case 1:
			[meta appendString: NSLocalizedString(@"Monday", @"Monday")];
			break;
		case 2:
			[meta appendString: NSLocalizedString(@"Tuesday", @"Tuesday")];
			break;
		case 3:
			[meta appendString: NSLocalizedString(@"Wednesday", @"Wednesday")];
			break;
		case 4:
			[meta appendString: NSLocalizedString(@"Thursday", @"Thursday")];
			break;
		case 5:
			[meta appendString: NSLocalizedString(@"Friday", @"Friday")];
			break;
		case 6:
			[meta appendString: NSLocalizedString(@"Saturday", @"Saturday")];
			break;
	}
	
    [meta appendString: [NSString stringWithFormat: @" %@<br>",
		[[self date] descriptionWithCalendarFormat:[NSString stringWithFormat:@"%@ %@", [defaults objectForKey: NSShortDateFormatString], [defaults objectForKey:NSTimeFormatString]] timeZone: nil locale: nil]]];
	
    if([self currentMoodName]) {
        [meta appendString: [NSString stringWithFormat: @"<strong>Mood:</strong>&nbsp;%@<br>", [self currentMoodName]]];
    }
	
    if([self currentMusic]) {
        [meta appendString: [NSString stringWithFormat: @"<strong>Music:</strong>&nbsp;%@<br>", [self currentMusic]]];
    }
	
    if([self currentLocation]) {
        [meta appendString: [NSString stringWithFormat: @"<strong>Location:</strong>&nbsp;%@<br>", [self currentLocation]]];
    }
	
	if([self tags]) {
		[meta appendString: [NSString stringWithFormat: @"<strong>Tags: </strong>%@<br>", [self tags]]];
	}

    [meta appendString: @"<br>"];
	return [meta autorelease];
}

- (NSMutableDictionary *) makeMutableDictionary: (NSDictionary *)input
{
	NSMutableDictionary *muta = [[NSMutableDictionary dictionaryWithCapacity:[input count]] retain];
	NSEnumerator *enu = [[input allKeys] objectEnumerator];
	id key;
	while (key = [enu nextObject]) {
		[muta setObject: [input objectForKey:key] forKey: key];
	}
	
	return [muta autorelease];
}
@end