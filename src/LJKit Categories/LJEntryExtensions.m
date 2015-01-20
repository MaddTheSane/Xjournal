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
- (BOOL)writePropertyListToURL:(NSURL *)url atomically:(BOOL)flag
{
    return [[self propertyListRepresentation] writeToURL:url atomically:flag];
}

- (BOOL)writePropertyListToFile:(NSString *)path atomically:(BOOL)flag
{
    return [[self propertyListRepresentation] writeToFile: path atomically: flag];
}

- (NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	
    // Encode subject
	if([self subject])
		dictionary[kSubjectKey] = [self subject];
	
    // Encode Content
	if([self content])
		dictionary[kContentKey] = [self content];
	
	
    dictionary[kDateKey] = [self date];
	
    // Encode journal name
	if([[self journal] name])
		dictionary[kJournalNameKey] = [[self journal] name];
	
    // Encode security mode
    if([self securityMode] != LJSecurityModePublic) {
        dictionary[kSecurityModeKey] = @([self securityMode]);
		
        dictionary[kGroupAllowedMaskKey] = @([self groupsAllowedAccessMask]);
    }
	
	
    if(_properties)
        dictionary[@"props"] = _properties;
    if(_customInfo)
        dictionary[@"info"] = _customInfo;
	
    // Encode poster user name
	if(_posterUsername)
		dictionary[kPosterUsernameKey] = _posterUsername;
	
    // Encode item ID
    dictionary[kItemIDKey] = @(_itemID);
    dictionary[kANumKey] = @(_aNum);
    
    // Set the current version of the file
    dictionary[kCurrentFileFormatVersionKey] = @kCurrentFileFormatVersion;
	
    return dictionary;
}

- (void)configureWithContentsOfFile: (NSString *)file
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: file];
    [self configureFromPropertyListRepresentation: dict];
}

- (void)configureFromPropertyListRepresentation:(id)dict
{
    [self setSubject: dict[kSubjectKey] ? dict[kSubjectKey] : @""];
	[self setContent: dict[kContentKey] ? dict[kContentKey] : @""];
	
    _properties = [self makeMutableDictionary: dict[@"props"]];
    _customInfo = dict[@"info"];
    
    //if([self optionBackdated])
    [self setDate: dict[kDateKey]];
	
    LJJournal *journal = [[[XJAccountManager defaultManager] loggedInAccount] journalNamed: dict[kJournalNameKey]];
    if(journal)
        [self setJournal: journal];
    else
        [self setJournal: [[[XJAccountManager defaultManager] loggedInAccount] defaultJournal]];
	
    [self setSecurityMode: [dict[kSecurityModeKey] intValue]];
    if([self securityMode] != LJSecurityModePublic)
        [self setGroupsAllowedAccessMask: [dict[kGroupAllowedMaskKey] intValue]];
	
    // Decode poster user name
    _posterUsername = dict[kPosterUsernameKey];
	
    // Encode item ID
    _itemID = [dict[kItemIDKey] intValue];
    _aNum = [dict[kANumKey] intValue];
}

- (NSString *)metadataHTML
{
	
    NSMutableString *meta = [[NSMutableString alloc] initWithCapacity: 100];
	
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
	
	[meta appendFormat: @" %@<br>", [NSDateFormatter localizedStringFromDate: self.date dateStyle: NSDateFormatterShortStyle timeStyle: NSDateFormatterMediumStyle]];
	
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
	return meta;
}

- (NSMutableDictionary *) makeMutableDictionary: (NSDictionary *)input
{
	NSMutableDictionary *muta = [NSMutableDictionary dictionaryWithCapacity:[input count]];
	NSEnumerator *enu = [[input allKeys] objectEnumerator];
	id key;
	while (key = [enu nextObject]) {
		muta[key] = input[key];
	}
	
	return muta;
}
@end
