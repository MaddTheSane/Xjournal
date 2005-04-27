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
#define kAccountUsernameKey @"AccountUsername"

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
    [dictionary setObject: [self subject] ? [self subject] : @""
				   forKey: kSubjectKey];

    // Encode Content
    [dictionary setObject: [self content] ? [self content] : @""
				   forKey: kContentKey];

    //if([self optionBackdated])
    [dictionary setObject: [self date] forKey: kDateKey];

	// Encode account name
	[dictionary setObject: [[self account] username] forKey: kAccountUsernameKey];
	
    // Encode journal name	
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
    [dictionary setObject: _posterUsername ? _posterUsername : @""
				   forKey: kPosterUsernameKey];

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
    [self setSubject: [dict objectForKey: kSubjectKey]];
    [self setContent: [dict objectForKey: kContentKey]];

    _properties = [[self makeMutableDictionary: [dict objectForKey: @"props"]] retain];
    _customInfo = [[dict objectForKey: @"info"] retain];
    
    //if([self optionBackdated])
    [self setDate: [dict objectForKey: kDateKey]];

	LJAccount *acct = [[XJAccountManager defaultManager] accountWithUsername: [dict objectForKey: kAccountUsernameKey]]; 
	[self setAccount: acct];
	
    LJJournal *journal = [acct journalNamed: [dict objectForKey: kJournalNameKey]];
    if(journal)
        [self setJournal: journal];
    else
        [self setJournal: [[[XJAccountManager defaultManager] defaultAccount] defaultJournal]];

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
        [meta appendString: @"<strong>Subject:</strong>&nbsp;&nbsp;"];
        [meta appendString: [self subject]];
        [meta appendString: @"<br>"];
    }
    [meta appendString: @"<strong>Date:</strong>&nbsp;&nbsp;"];
    [meta appendString: [[self date] descriptionWithCalendarFormat:[NSString stringWithFormat:@"%@ %@ %%p", [defaults objectForKey: NSShortDateFormatString], [defaults objectForKey:NSTimeFormatString]] timeZone: nil locale: nil]];

    if([self currentMood]) {
        [meta appendString: @"<br><strong>Mood:</strong>&nbsp;&nbsp;"];
        [meta appendString: [self currentMood]];
    }

    if([self currentMusic]) {
        [meta appendString: @"<br><strong>Music:</strong>&nbsp;&nbsp;"];
        [meta appendString: [self currentMusic]];
    }
    [meta appendString: @"<br><br>"];

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