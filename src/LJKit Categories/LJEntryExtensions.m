//
//  LJEntryExtensions.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Mar 20 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "LJEntryExtensions.h"
#import <OmniFoundation/OmniFoundation.h>
#import "XJPreferences.h"
#import "XJAccountManager.h"

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
    [dictionary setObject: [self subject] forKey: kSubjectKey defaultObject: @""];

    // Encode Content
    [dictionary setObject: [self content] forKey: kContentKey defaultObject: @""];

    //if([self optionBackdated])
    [dictionary setObject: [self date] forKey: kDateKey];

    // Encode journal name
    [dictionary setObject: [[self journal] name] forKey: kJournalNameKey defaultObject: [[[[XJAccountManager defaultManager] loggedInAccount] defaultJournal] name]];

    // Encode security mode
    if([self securityMode] != LJPublicSecurityMode) {
        [dictionary setIntValue: [self securityMode] forKey: kSecurityModeKey defaultValue: LJPublicSecurityMode];
        [dictionary setIntValue: [self groupsAllowedAccessMask] forKey: kGroupAllowedMaskKey];
    }


    if(_properties)
        [dictionary setObject: _properties forKey: @"props"];
    if(_customInfo)
        [dictionary setObject: _customInfo forKey: @"info"];

    // Encode poster user name
    [dictionary setObject: _posterUsername forKey: kPosterUsernameKey defaultObject: @""];

    // Encode item ID
    [dictionary setIntValue: _itemID forKey: kItemIDKey];
    [dictionary setIntValue: _aNum forKey: kANumKey];
    
    // Tags
	if([self tags])
		[dictionary setObject: [self tags] forKey: @"Tags"];
	
    // Set the current version of the file
    [dictionary setIntValue: kCurrentFileFormatVersion forKey: kCurrentFileFormatVersionKey];

    return dictionary;
}

- (void)configureWithContentsOfFile: (NSString *)file
{
    NSMutableDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: file];
    [self configureFromPropertyListRepresentation: dict];
}

- (void)configureFromPropertyListRepresentation:(id)dict
{
    [self setSubject: [dict objectForKey: kSubjectKey defaultObject: @""]];
    [self setContent: [dict objectForKey: kContentKey defaultObject: @""]];

    _properties = [[self makeMutableDictionary: [dict objectForKey: @"props"]] retain];
    _customInfo = [[dict objectForKey: @"info" defaultObject: nil] retain];
    
    //if([self optionBackdated])
    [self setDate: [dict objectForKey: kDateKey]];

    LJJournal *journal = [[[XJAccountManager defaultManager] loggedInAccount] journalNamed: [dict objectForKey: kJournalNameKey]];
    if(journal)
        [self setJournal: journal];
    else
        [self setJournal: [[[XJAccountManager defaultManager] loggedInAccount] defaultJournal]];

    [self setSecurityMode: [dict intForKey: kSecurityModeKey defaultValue: LJPublicSecurityMode]];
    if([self securityMode] != LJPublicSecurityMode)
        [self setGroupsAllowedAccessMask: [dict intForKey: kGroupAllowedMaskKey]];

    // Decode poster user name
    _posterUsername = [[dict objectForKey: kPosterUsernameKey] retain];

    // Encode item ID
    _itemID = [dict intForKey: kItemIDKey];
    _aNum = [dict intForKey: kANumKey];
	
	// Tags
	[self setTags: [dict objectForKey: @"Tags"]];
}

- (NSString *)metadataHTML
{

    NSMutableString *meta = [[NSMutableString stringWithCapacity: 100] retain];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if([self subject]) {
        [meta appendString: [NSString stringWithFormat: @"<strong>Subject:</strong>&nbsp;%@<br>", [self subject]]];
    }
	
    [meta appendString: [NSString stringWithFormat: @"<strong>Date:</strong>&nbsp;%@<br>",
		[[self date] descriptionWithCalendarFormat:[NSString stringWithFormat:@"%@ %@ %%p", [defaults objectForKey: NSShortDateFormatString], [defaults objectForKey:NSTimeFormatString]] timeZone: nil locale: nil]]];

    if([self currentMood]) {
        [meta appendString: [NSString stringWithFormat: @"<strong>Mood:</strong>&nbsp;%@<br>", [self currentMood]]];
    }

    if([self currentMusic]) {
        [meta appendString: [NSString stringWithFormat: @"<strong>Music:</strong>&nbsp;%@<br>", [self currentMusic]]];
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