//
//  XJMusic.m
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import "XJMusic.h"
#import "NSString+Templating.h"

@interface XJMusic (PrivateAPI)
+ (NSDictionary *)detectMusic;
+ (BOOL)iTunesIsRunning;
+ (BOOL)iTunesIsPlaying;

+ (NSString *)wrapIniTunesLink: (NSString *)str;
@end

@implementation XJMusic

+ (XJMusic *)currentMusic {

	XJMusic *music = nil;

	if([self iTunesIsRunning] && [self iTunesIsPlaying]) {
		NSDictionary *data = [self detectMusic];

		if(data) {
			music = [[XJMusic alloc] initWithName: [data objectForKey: @"name"]
											album: [data objectForKey: @"album"]
										   artist: [data objectForKey: @"artist"]
										   rating: [[data objectForKey: @"rating"] intValue]];
		}
	}
	return [music autorelease];
}

+ (XJMusic *)musicAsiTunesLink: (XJMusic *)aMusic {

	XJMusic *music = nil;

	if([self iTunesIsRunning] && [self iTunesIsPlaying]) {
		NSDictionary *data = [self detectMusic];

		if(data) {
			music = [[XJMusic alloc] initWithName: [self wrapIniTunesLink: [aMusic name]]
											album: [self wrapIniTunesLink: [aMusic album]]
										   artist: [self wrapIniTunesLink: [aMusic artist]]
										   rating: [aMusic rating]];	
		}
	}
	return [music autorelease];
}

- (id)initWithName: (NSString *)aName album: (NSString *)anAlbum artist: (NSString *)anArtist rating: (int)aRating {
	self = [super init];
	if(self) {
		[self setName: aName];
		[self setArtist: anArtist];
		[self setAlbum: anAlbum];
		[self setRating: aRating];
	}
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat: @"%@ by %@ from %@ (Rating: %d)", 
		[self name], [self artist], [self album], [self rating]];
}



// =========================================================== 
//  - dealloc:
// =========================================================== 
- (void)dealloc {
    [name release];
    [album release];
    [artist release];
	
    [super dealloc];
}


// =========================================================== 
// - name:
// =========================================================== 
- (NSString *)name {
	return name; 
}

// =========================================================== 
// - setName:
// =========================================================== 
- (void)setName:(NSString *)aName {
    if (name != aName) {
        [aName retain];
        [name release];
        name = aName;
    }
}




// =========================================================== 
// - album:
// =========================================================== 
- (NSString *)album {
    return album;
}

// =========================================================== 
// - setAlbum:
// =========================================================== 
- (void)setAlbum:(NSString *)anAlbum {
    if (album != anAlbum) {
        [anAlbum retain];
        [album release];
        album = anAlbum;
    }
}



// =========================================================== 
// - artist:
// =========================================================== 
- (NSString *)artist {
return artist; 
}

// =========================================================== 
// - setArtist:
// =========================================================== 
- (void)setArtist:(NSString *)anArtist {
    if (artist != anArtist) {
        [anArtist retain];
        [artist release];
        artist = anArtist;
    }
}

// =========================================================== 
// - rating:
// =========================================================== 
- (int)rating {
	
    return rating;
}

// =========================================================== 
// - setRating:
// =========================================================== 
- (void)setRating:(int)aRating {
	rating = aRating;
}

@end

@implementation XJMusic (PrivateAPI)
+ (NSDictionary *)detectMusic
{
    if([self iTunesIsRunning] && [self iTunesIsPlaying]) {
        NSString *getTrackScript = @"tell application \"iTunes\" to name of current track";
        NSString *getArtistScript = @"tell application \"iTunes\" to artist of current track";
        NSString *getAlbumScript = @"tell application \"iTunes\" to album of current track";
		NSString *getRatingScript = @"tell application \"iTunes\" to rating of current track";
        NSAppleEventDescriptor *result;
        NSAppleScript *script;
        NSDictionary *info;
        
        NSString *theArtist, *theAlbum, *theTrack;
        
        script = [[NSAppleScript alloc] initWithSource: getTrackScript];
        result = [script executeAndReturnError: &info];
        theTrack = [[result stringValue] copy];
        [script release];
        
        script = [[NSAppleScript alloc] initWithSource: getArtistScript];
        result = [script executeAndReturnError: &info];
        theArtist = [[result stringValue] copy];
        [script release];
        
        script = [[NSAppleScript alloc] initWithSource: getAlbumScript];
        result = [script executeAndReturnError: &info];
        theAlbum = [[result stringValue] copy];
        [script release];

		script = [[NSAppleScript alloc] initWithSource: getRatingScript];
        result = [script executeAndReturnError: &info];
        int theRating = [[result stringValue] intValue];
		theRating = theRating/20;
        [script release];
		
        [theArtist autorelease];
        [theAlbum autorelease];
        [theTrack autorelease];
		
        return [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: theArtist, theAlbum, theTrack, [NSNumber numberWithInt: theRating], nil] 
										   forKeys: [NSArray arrayWithObjects: @"artist", @"album", @"name", @"rating", nil]];
    }
    return nil;
}

+ (BOOL) iTunesIsRunning
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    NSEnumerator *allapps = [apps objectEnumerator];
    NSDictionary *thisApp;
    
    while(thisApp = [allapps nextObject]) {
        NSString *appName = [thisApp objectForKey: @"NSApplicationName"];
        if([appName isEqualToString: @"iTunes"]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)iTunesIsPlaying
{
    if([self iTunesIsRunning]) {
        NSAppleScript *script;
        NSAppleEventDescriptor *result;
        NSDictionary *dict;
        
        script = [[[NSAppleScript alloc] initWithSource: @"tell application \"iTunes\" to artist of current track"] autorelease];
        result = [script executeAndReturnError: &dict];
        if(!result) {
            return NO;
        }
        else {
            if([result stringValue] == nil)
                return NO;
            else
                return YES;
        }
    }
    else
        return NO;
}

+ (NSString *)wrapIniTunesLink: (NSString *)str {
	return [NSString stringWithFormat:@"<a href=\"itms://phobos.apple.com/WebObjects/MZSearch.woa/wa/search?term=%@\">%@</a>", str, str];
}
@end