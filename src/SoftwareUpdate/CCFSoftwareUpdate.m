//
//  CCFSoftwareUpdate.m
//  Xjournal
//
//  Created by Fraser Speirs on Wed Jul 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CCFSoftwareUpdate.h"
#import "NetworkConfig.h"

static CCFSoftwareUpdate *singleton;

@interface CCFSoftwareUpdate (PrivateAPI)
- (BOOL)propertyListIsValidForCurrentBundle: (NSDictionary *)propList;
- (NSComparisonResult)orderingAgainstCurrentBundle: (NSDictionary *)propList;
- (void)runNewVersionDialog:(NSDictionary *)updateDictionary;
- (void)runNoNewVersionDialog;
- (void)scheduleNewSoftwareUpdateCheck;

- (NSDictionary *)currentBundlePropertyList;
- (NSString *) currentBundleIdentifier;
- (NSString *)currentBundleShortVersion;

- (BOOL)currentBundleIsOnBetaTrack;

- (BOOL)revisionVersionBumped;
- (BOOL)minorVersionBumped;
- (BOOL)majorVersionBumped;
- (BOOL)betaVersionBumped;

- (int)pointRevision: (int)rev fromAGVString: (NSString *)agvString;
- (int)betaRevisionFromAGVString: (NSString *)str;
@end

@implementation CCFSoftwareUpdate
/* Singleton pattern accessor */
+ (CCFSoftwareUpdate *)sharedUpdateChecker
{
    if(!singleton)
        singleton = [[CCFSoftwareUpdate alloc] init];
    return singleton;
}

/*
 * Runs a software update check
 */
- (void)runSoftwareUpdate:(BOOL)isScheduled {
	
	isScheduledSoftwareUpdateCheck = isScheduled;
	responseData = [[NSMutableData data] retain];
	
	NSURL *plistURL = [NSURL URLWithString: [[self currentBundlePropertyList] objectForKey: @"CCFSoftwareUpdateURL"]];
	
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL: plistURL
												  cachePolicy: NSURLRequestReloadIgnoringCacheData
											  timeoutInterval: 5.0];

	plistConnection = [[NSURLConnection alloc] initWithRequest: request delegate: self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[responseData appendData: data];	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[plistConnection release];
	plistConnection = nil;
	
	[responseData release];
	responseData = nil;
	
	[self scheduleNewSoftwareUpdateCheck];
}

- (void)connectionDidFinishLoading: (NSURLConnection *)conn {

	NSString *error;
	NSPropertyListFormat fmt = NSPropertyListXMLFormat_v1_0;
	NSDictionary *dict = [NSPropertyListSerialization propertyListFromData: responseData
														  mutabilityOption: NSPropertyListImmutable
																	format: &fmt
														  errorDescription: &error];
	
	NSLog([dict description]);
	if(!dict) {
        [self scheduleNewSoftwareUpdateCheck];
        return; // Failed!
    }
	
	[self processPropertyListDictionary: dict];
	[responseData release];
	responseData = nil;
}

- (void)processPropertyListDictionary:(NSDictionary *)propertyList {

    if(![self propertyListIsValidForCurrentBundle: propertyList]) return; // No info for this app
    NSDictionary *updateInfo = [propertyList objectForKey: [self currentBundleIdentifier]];
    
    if([self currentBundleIsOnBetaTrack]) {
        trackInfo = [updateInfo objectForKey: @"CCFBetaTrack"];
        downloadIsOnReleaseTrack = NO;
        
        if(!trackInfo) { 
            // If downloaded plist has no beta track information
            // use the Release track info, as we may have released the full version
            trackInfo = [updateInfo objectForKey: @"CCFReleaseTrack"];
            downloadIsOnReleaseTrack = YES;
        }
    }
    else {
        downloadIsOnReleaseTrack = YES;
        trackInfo = [updateInfo objectForKey: @"CCFReleaseTrack"];
    }
    
    
    
    if([self orderingAgainstCurrentBundle: propertyList] == NSOrderedAscending) {
        [self runNewVersionDialog: trackInfo];
    }
    else {
        if(!isScheduledSoftwareUpdateCheck)
            [self runNoNewVersionDialog];
    }
    
    [self scheduleNewSoftwareUpdateCheck];
}

- (void)runScheduledUpdateCheckIfRequired
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *nextCheck = [defaults objectForKey: @"CCFNextUpdateCheck"];
    if(!nextCheck) return;
    
    int offset = [nextCheck timeIntervalSinceNow];
    if(offset < 0) {
        [self runSoftwareUpdate: YES];
    }
    else {
        updateTimer = [[NSTimer scheduledTimerWithTimeInterval: offset
                                                      target: self
                                                    selector: @selector(runTimedSoftwareUpdate:)
                                                    userInfo: NULL
                                                     repeats: NO] retain];
    }
}

- (void)resetCheckTimer
{
    [self scheduleNewSoftwareUpdateCheck];
}

- (void)runTimedSoftwareUpdate: (NSTimer *)timer
{
    [timer invalidate];
    [timer release];
    updateTimer = nil;
    [self runSoftwareUpdate: YES];
}
@end

@implementation CCFSoftwareUpdate (PrivateAPI)

/* Returns YES if the provided plist contains information about the current bundle */
- (BOOL)propertyListIsValidForCurrentBundle: (NSDictionary *)propList
{
    NSString *bundleIdentifier = [self currentBundleIdentifier];
    return ([propList objectForKey: bundleIdentifier] != nil);
}

/* Compares the running version to the latest version in the bundle */
- (NSComparisonResult)orderingAgainstCurrentBundle: (NSDictionary *)propList
{
    // By the time this method is called, we've worked out if this is a beta
    // track app or not.  trackInfo is either the beta track or the release track
    //
    // If this app is beta, and trackInfo is the release track dictionary,
    // there is no current beta and we should consider that the betas have gone final
    if([self majorVersionBumped]) return NSOrderedAscending;
    if([self minorVersionBumped]) return NSOrderedAscending;
    if([self revisionVersionBumped]) return NSOrderedAscending;

    
    if([self currentBundleIsOnBetaTrack] && !downloadIsOnReleaseTrack) {
        if([self betaVersionBumped]) return NSOrderedAscending;
    }

	/*
	if([self currentBundleIsOnBetaTrack] && downloadIsOnReleaseTrack)
		return NSOrderedAscending;
	*/
    return NSOrderedSame;
}

/* Returns true if the dictionary contained in the trackInfo ivar has a newer beta release */
- (BOOL)betaVersionBumped
{
    int plistBetaVersion = [[trackInfo objectForKey: @"CCFBetaVersion"] intValue];
    int appBetaVersion = [self betaRevisionFromAGVString: [self currentBundleShortVersion]];
    return plistBetaVersion > appBetaVersion;
}

- (BOOL)revisionVersionBumped
{
    int plistRevision = [[trackInfo objectForKey: @"CCFRevisionVersion"] intValue];
    int appRevVersion = [self pointRevision:2 fromAGVString: [self currentBundleShortVersion]];
    return plistRevision > appRevVersion;
}

- (BOOL)minorVersionBumped
{
    int plistMinorVersion = [[trackInfo objectForKey: @"CCFMinorVersion"] intValue];
    int appMinorVersion = [self pointRevision:1 fromAGVString: [self currentBundleShortVersion]];
    return plistMinorVersion > appMinorVersion;
}

- (BOOL)majorVersionBumped
{
    int plistMajorVersion = [[trackInfo objectForKey: @"CCFMajorVersion"] intValue];
    int appMajorVersion = [self pointRevision:0 fromAGVString: [self currentBundleShortVersion]];
    return plistMajorVersion > appMajorVersion;
}

- (BOOL)currentBundleIsOnBetaTrack
{
    return [[[self currentBundlePropertyList] objectForKey: @"CCFBetaTrack"] boolValue];
}

- (NSString *) currentBundleIdentifier
{
    return [[self currentBundlePropertyList] objectForKey: @"CFBundleIdentifier"];   
}

- (NSDictionary *)currentBundlePropertyList
{
    return [[NSBundle mainBundle] infoDictionary];
}

- (NSString *)currentBundleShortVersion
{
    return [[self currentBundlePropertyList] objectForKey: @"CFBundleShortVersionString"];
}        

- (int)pointRevision: (int)rev fromAGVString: (NSString *)agvString
{
    NSScanner *scanner = [NSScanner scannerWithString:agvString];
    NSMutableArray *buffer = [[NSMutableArray alloc] init];
    for (;;) {
        int anInteger;
        if (![scanner scanInt:&anInteger])
            break;
        [buffer addObject:[NSNumber numberWithInt:anInteger]];
        if (![scanner scanString:@"." intoString:NULL])
            break;
    }
    
    if(![buffer count] || rev >= [buffer count]) return 0;
    
    return [[buffer objectAtIndex: rev] intValue];
}

- (int)betaRevisionFromAGVString: (NSString *)str
{
    NSArray *bits = [str componentsSeparatedByString: @"b"];
    NSAssert([bits count] == 2, @"Fewer bits than expected in AGV String");
    return [[bits objectAtIndex: 1] intValue];
}

- (void)runNewVersionDialog:(NSDictionary *)updateDictionary
{
    NSString *title = NSLocalizedString(@"New Version Available", @"");
    NSString *message = NSLocalizedString(@"A new version of Xjournal is available.  You may download the update now, read the release notes or check again later.", @"");
    NSString *OKButton = NSLocalizedString(@"Download Now", @"");
    NSString *AltButton = NSLocalizedString(@"Read Release Notes", @"");
    NSString *OtherButton = NSLocalizedString(@"Check Later", @"");
    
    int result = NSRunInformationalAlertPanel(title, message, OKButton, AltButton, OtherButton);
    
    switch(result) {
        case NSAlertDefaultReturn:
        {
            NSString *plistURL = [updateDictionary objectForKey: @"CCFDirectDownloadURL"];
            [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: plistURL]];
            break;
        }
        case NSAlertAlternateReturn:
        {
            NSString *plistURL = [updateDictionary objectForKey: @"CCFReleaseNotesURL"];
            [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: plistURL]];
            break;
        }
        case NSAlertOtherReturn:
            break;
        default:
            break;
    }
}

- (void)runNoNewVersionDialog
{
    NSRunInformationalAlertPanel(NSLocalizedString(@"Up to date", @""),
                                 NSLocalizedString(@"There is no new version of Xjournal available", @""),
                                 NSLocalizedString(@"OK", @""), nil, nil);
}

- (void)scheduleNewSoftwareUpdateCheck
{
    /*
     The idea here is to write into User Defaults the next timestamp
     for a check.  When we initialise this class, we read that timestamp,
     work out the difference from now, and if it's positive we create a timer
     to fire when that time comes.
     */
    int checkFrequency = [[NSUserDefaults standardUserDefaults] integerForKey: @"CCFSoftwareUpdateInterval"];
    int offset = 0;
    
    switch (checkFrequency) {
        case 0:
            offset = 24 * 60 * 60; // 1 day
            break;
        case 1:
            offset = 7 * 24 * 60 * 60; // 7 days
            break;
        case 2:
            offset = 30 * 24 * 60 * 60; // 30 days
            break;
        default:
            offset = 0;
            break;        
    }
    
    if(offset) {
        NSDate *nextCheck = [NSDate dateWithTimeIntervalSinceNow: offset];
        [[NSUserDefaults standardUserDefaults] setObject: nextCheck forKey: @"CCFNextUpdateCheck"];
        
        updateTimer = [[NSTimer scheduledTimerWithTimeInterval: offset
                                                       target: self
                                                     selector: @selector(runTimedSoftwareUpdate:)
                                                     userInfo: NULL
                                                      repeats: NO] retain];
    }
}
@end