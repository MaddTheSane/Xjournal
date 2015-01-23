//
//  XJMusic.m
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import "XJMusic.h"
#import "NSString+Templating.h"

@interface XJMusic ()
+ (NSDictionary *)detectMusic;
+ (BOOL)iTunesIsRunning;
+ (BOOL)iTunesIsPlaying;

+ (NSString *)wrapIniTunesLink: (NSString *)str;
@end

@implementation XJMusic
@synthesize name;
@synthesize artist;
@synthesize album;
@synthesize rating;

+ (XJMusic *)currentMusic {

	XJMusic *music = nil;

	if([self iTunesIsRunning] && [self iTunesIsPlaying]) {
		NSDictionary *data = [self detectMusic];

		if(data) {
			music = [[XJMusic alloc] initWithName: data[@"name"]
											album: data[@"album"]
										   artist: data[@"artist"]
										   rating: [data[@"rating"] intValue]];
		}
	}
	return music;
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
	return music;
}

- (instancetype)initWithName: (NSString *)aName album: (NSString *)anAlbum artist: (NSString *)anArtist rating: (int)aRating {
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
        
        script = [[NSAppleScript alloc] initWithSource: getArtistScript];
        result = [script executeAndReturnError: &info];
        theArtist = [[result stringValue] copy];
        
        script = [[NSAppleScript alloc] initWithSource: getAlbumScript];
        result = [script executeAndReturnError: &info];
        theAlbum = [[result stringValue] copy];

		script = [[NSAppleScript alloc] initWithSource: getRatingScript];
        result = [script executeAndReturnError: &info];
        int theRating = [result int32Value];
		theRating = theRating / 20;
		
        return @{@"artist": theArtist, @"album": theAlbum, @"name": theTrack, @"rating": @(theRating)};
    }
    return nil;
}

+ (BOOL) iTunesIsRunning
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
	for (NSRunningApplication *thisApp in apps) {
		if ([thisApp.bundleIdentifier isEqualToString:@"com.apple.iTunes"]) {
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
        
        script = [[NSAppleScript alloc] initWithSource: @"tell application \"iTunes\" to artist of current track"];
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
