//
//  LJFriend-ABExtensions.m
//  Xjournal
//
//  Created by Fraser Speirs on Sun Apr 13 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJFriend-ABExtensions.h" 

#define kLJUsernameKey @"org.speirs.xjournal.livejournalusername"
#define kLJEmailLabel @"LJ Email"

@implementation LJFriend (ABExtensions)

- (void)associateABRecord: (ABRecord *)record
{
    // Add this username as a key to the given record
    ABAddressBook *book = [ABAddressBook sharedAddressBook];

    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:kABStringProperty],
        kLJUsernameKey,
        nil,
        nil];

    [ABPerson addPropertiesAndTypes: dict];

    [record setValue: [self username] forProperty: kLJUsernameKey];
    [book save];
    
}

- (void)unassociateABRecord
{
    ABRecord *rec = [self addressBookRecord];
    if(rec)
        [rec removeValueForProperty: kLJUsernameKey];    
}

- (ABRecord *)addressBookRecord
{
    ABAddressBook *book = [ABAddressBook sharedAddressBook];
    ABSearchElement *sElement = [ABPerson searchElementForProperty: kLJUsernameKey
                                                             label: nil
                                                               key: nil
                                                             value: [self username]
                                                        comparison: kABEqual];
    
    NSArray *foundRecords = [book recordsMatchingSearchElement: sElement];
    if([foundRecords count])
        return [foundRecords objectAtIndex: 0];
    else
        return nil;
}

- (NSImage *)abImage
{
    ABRecord *rec = [self addressBookRecord];
    if([rec isKindOfClass: [ABPerson class]]) {
        NSData *imageData = [(ABPerson *)rec imageData];
        NSImage *img = [[NSImage alloc] initWithData: imageData];
        return [img autorelease]; // May still be nil
    }
    return nil;
}

- (NSString *)uniqueId
{
    ABRecord *rec = [self addressBookRecord];
    if(rec)
        return [rec uniqueId];
    else
        return nil;
}

- (NSString *)chatURL
{
    NSString *uid = [self uniqueId];
    if(!uid) return nil;

    return [NSString stringWithFormat: @"iChat:compose?card=%@", uid];
}

- (NSString *)abName
{
    ABRecord *rec = [self addressBookRecord];
    if(!rec) return @"";

    NSString *first, *last;
    last = [rec valueForProperty: kABLastNameProperty];
    first = [rec valueForProperty: kABFirstNameProperty];

    if(first || last) {
        if(first && last) {
            return [NSString stringWithFormat: @"%@ %@", first, last];
        }
        else if(first) {
            return first;
        }
        else {
            return last;
        }
    }
    else {
        NSString *company = [rec valueForProperty: kABOrganizationProperty];
        if(company)
            return company;
        else
            return @"";
    }
}

- (BOOL)hasAddressCard
{
    return [self addressBookRecord] != nil;
}

- (void)addAddressCardAndEdit: (BOOL)shouldEdit
{
    ABPerson *person = [[ABPerson alloc] init];

    // Add the LJ Username prop
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:kABStringProperty],
        kLJUsernameKey,
        nil,
        nil];

    [ABPerson addPropertiesAndTypes: dict];
    [person setValue: [self username] forProperty: kLJUsernameKey];

    [person setValue: [[self recentEntriesHttpURL] absoluteString] forProperty: kABHomePageProperty];
    [person setValue: [self username] forProperty: kABFirstNameProperty];
    [person setValue: [self birthDate] forProperty: kABBirthdayProperty];

    // Set the email - tricky because this is a multi-value prop
    ABMutableMultiValue *emailList = [[ABMutableMultiValue alloc] init];
    [emailList addValue: [self email] withLabel: kLJEmailLabel];
    [person setValue: emailList forProperty: kABEmailProperty];
    [emailList release];
        
    [[ABAddressBook sharedAddressBook] addRecord: person];
    [[ABAddressBook sharedAddressBook] save];

    if(shouldEdit) {
        NSString *uniqueId = [person uniqueId];
        NSString *urlString = [NSString stringWithFormat:@"addressbook://%@?edit", uniqueId];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
    }
    [person release];
}

- (NSString *)email
{
    return [self emailWithDomain: @"livejournal.com"];
}

- (NSString *)emailWithDomain: (NSString *)domain
{
    return [NSString stringWithFormat: @"%@@%@", [self username], domain];
}
@end

// Birthday
@implementation LJFriend (Birthdays)
- (BOOL)birthdayIsToday
{
    return [self birthdayIsWithinAlertPeriod: 1];
}

- (BOOL)birthdayIsWithinAlertPeriod: (int)alertPeriod
{
    if(![self birthDate]) return NO;
    NSCalendarDate *today = [NSCalendarDate calendarDate];

    int thisMonth = [today monthOfYear];
    int thisDay = [today dayOfMonth];

    int bDayMonth = [[self birthDate] monthOfYear];
    int bDayDay = [[self birthDate] dayOfMonth];
    return bDayDay == thisDay && bDayMonth == thisMonth;
}

- (BOOL)birthdayIsThisMonth
{
    if(![self birthDate]) return NO;
    NSCalendarDate *today = [NSCalendarDate calendarDate];

    int thisMonth = [today monthOfYear];
    int bDayMonth = [[self birthDate] monthOfYear];

    return bDayMonth == thisMonth;
}

- (void)addBirthdayToCalendarNamed:(NSString *)calendarName
{
    NSCalendarDate *birthday = [self birthDate];
    if(!birthday) return; // <-- bail out
    
    NSString *scriptBody = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"make_event_ical" ofType:@"txt"]];
    NSMutableString *headerText = [NSMutableString string];
    NSString *eventTitle = [NSString stringWithFormat: @"%@'s birthday", [self username]];
    
    [headerText appendString:[NSString stringWithFormat:@"set calTitle to \"%@\"\r", calendarName]];
    
    [headerText appendString:[NSString stringWithFormat:@"set eventTitle to \"%@\"\r", eventTitle]];
     
    [headerText appendString:[NSString stringWithFormat:@"set eventDay to %d\r", [birthday dayOfMonth]]];
    [headerText appendString:[NSString stringWithFormat:@"set eventMonth to %@\r", [birthday descriptionWithCalendarFormat:@"%B"]]];
    [headerText appendString:[NSString stringWithFormat:@"set eventMonthNum to %d\r", [birthday monthOfYear]]];
    
    // We now create birthdays starting in the current year, to avoid lots of events in the past.
    // If you prefer the old behaviour, change "[NSCalendarDate calendarDate]" to "birthday" in the next line.
    [headerText appendString:[NSString stringWithFormat:@"set eventYear to %d\r", [[NSCalendarDate calendarDate] yearOfCommonEra]]];
    
    [headerText appendString:scriptBody];
    
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:headerText];
    NSDictionary *errorInfo = [NSDictionary dictionary];
    NSAppleEventDescriptor *descriptor = [script executeAndReturnError:&errorInfo];
    [script release];
    if (descriptor == nil) {
        NSBeep();
        return;
    }    
}
@end

@implementation LJFriend (Comparisons)
- (NSComparisonResult)compareUserCommunity: (id)otherFriend
{
    return [self compareUserCommunity: otherFriend descending: NO];
}

- (NSComparisonResult)compareUserCommunityDescending: (id)otherFriend
{
    return [self compareUserCommunity: otherFriend descending: YES];
}

- (NSComparisonResult)compareUserCommunity: (id)otherFriend descending: (BOOL)descending
{
    if(![otherFriend isKindOfClass: [LJFriend class]])
        return NSOrderedSame;

    BOOL otherIsCommunity = [[otherFriend accountType] isEqualToString: @"community"],
        selfIsCommunity = [[self accountType] isEqualToString: @"community"];

    if(selfIsCommunity) {
        if(otherIsCommunity)
            return [self compareUsername: otherFriend descending: descending];
        else // I'm a community and the other is a user, comm > user
            return descending ? NSOrderedAscending: NSOrderedDescending;
    }
    else {
        if(otherIsCommunity) // I'm a user and the other is a community, comm > user
            return descending ? NSOrderedDescending : NSOrderedAscending;
        else // I'm a user and other is a user
            return [self compareUsername: otherFriend descending: descending];            
    }

    return NSOrderedSame;
}

- (NSComparisonResult)compareUsername: (id)otherFriend
{
    return [self compareUsername: otherFriend descending: NO];
}

- (NSComparisonResult)compareUsernameDescending: (id)otherFriend
{
    return [self compareUsername: otherFriend descending: YES];
}

- (NSComparisonResult)compareUsername: (id)otherFriend descending: (BOOL)descending
{
    NSComparisonResult result = [[self username] caseInsensitiveCompare: [otherFriend username]];

    if(result == NSOrderedAscending)
        return descending ? NSOrderedDescending : NSOrderedAscending;
    else
        return descending ? NSOrderedAscending : NSOrderedDescending;

    return NSOrderedSame;
}

- (NSComparisonResult)compareFullName: (id)otherFriend
{
    return [self compareFullName: otherFriend descending: NO];
}

- (NSComparisonResult)compareFullNameDescending: (id)otherFriend
{
    return [self compareFullName: otherFriend descending: YES];
}

- (NSComparisonResult)compareFullName: (id)otherFriend descending: (BOOL)descending
{
    NSComparisonResult result = [[self fullname] caseInsensitiveCompare: [otherFriend fullname]];

    if(result == NSOrderedAscending)
        return descending ? NSOrderedDescending : NSOrderedAscending;
    else
        return descending ? NSOrderedAscending : NSOrderedDescending;

    return NSOrderedSame;
}

- (NSComparisonResult)compareRelationship: (id)otherFriend
{
    return [self compareRelationship: otherFriend descending: NO];
}

- (NSComparisonResult)compareRelationshipDescending: (id)otherFriend
{
    return [self compareRelationship: otherFriend descending: YES];
}

- (NSComparisonResult)compareRelationship: (id)otherFriend descending: (BOOL)descending
{
    int rel = [otherFriend friendship];

    if(rel > [self friendship])
        return descending ? NSOrderedAscending : NSOrderedDescending;
    else if(rel < [self friendship])
        return descending ? NSOrderedDescending : NSOrderedAscending;
    else
        return [self compareUsername: otherFriend descending: descending];
}
@end