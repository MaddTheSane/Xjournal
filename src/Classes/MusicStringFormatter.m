/*
 * $Id: MusicStringFormatter.m,v 1.1.1.1 2004/08/05 21:21:48 fspeirs Exp $
 *
 * Copyright (c) 2001, 2002 William J. Coldwell
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 *  * Neither the name of the author nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 */

//
//  MusicStringFormatter.m
//  LiveJournal
//
//  Created by Fraser Speirs on Wed Apr 03 2002.
//  Copyright (c) 2001 Fraser Speirs. All rights reserved.
//

#import "MusicStringFormatter.h"
#import "XJPreferences.h"

#define ARTIST [NSNumber numberWithInt: 0]
#define ALBUM [NSNumber numberWithInt: 1]
#define TRACK [NSNumber numberWithInt: 2]

@interface MusicStringFormatter (Private)
+ (NSArray *) orderingForOrderingType: (int)type withArtist: (NSString *)artist album:(NSString *)album track: (NSString *)track;
+ (BOOL)iTunesIsRunning;
+ (BOOL)iTunesIsPlaying;
@end

@implementation MusicStringFormatter
+ (NSString *)musicStringWithArtist: (NSString *)artist
                              album: (NSString *)album
                              track: (NSString *)track
                       artistPrefix: (NSString *)artistPrefix
                       artistSuffix: (NSString *)artistSuffix
                        trackPrefix: (NSString *)trackPrefix
                        trackSuffix: (NSString *)trackSuffix
                        albumPrefix: (NSString *)albumPrefix
                        albumSuffix: (NSString *)albumSuffix
                              order: (int)ordering
                       includeEmpty: (BOOL)includeEmpty
                          separator: (NSString *)separator
                           iTMSLink: (BOOL)iTMSLink
{
    NSString *iTMSPrefix = @"<a href=\"itms://phobos.apple.com/WebObjects/MZSearch.woa/wa/com.apple.jingle.search.DirectAction/search?term=";
    NSString *iTMSSuffix = @"</a>";
    
    NSMutableString *data = [[NSMutableString stringWithCapacity: 30] retain];
    NSArray *orderingArray;
    NSMutableString *completedArtist = [NSMutableString stringWithCapacity: 30];
    NSMutableString *completedAlbum = [NSMutableString stringWithCapacity: 30];
    NSMutableString *completedTrack = [NSMutableString stringWithCapacity: 30];
    int i;
    NSNumber *item;

    if([artist length] == 0) artist = nil;
    if([album length] == 0) album = nil;
    if([track length] == 0) track = nil;
    
    // Build artist
    if(includeEmpty || artist) {
        if(artistPrefix)
            [completedArtist appendString: artistPrefix];
        if(artist) {
            if(iTMSLink) {
                NSString *storeLink = [NSString stringWithFormat: @"%@%@\">%@%@", iTMSPrefix, artist, artist, iTMSSuffix];
                [completedArtist appendString: storeLink];
            }
            else {
                [completedArtist appendString: artist];
            }
        }
        if(artistSuffix)
            [completedArtist appendString: artistSuffix];
    }
    
    if(includeEmpty || album) {
        if(albumPrefix)
            [completedAlbum appendString: albumPrefix];
        if(album) {
            if(iTMSLink) {
                NSString *storeLink = [NSString stringWithFormat: @"%@%@\">%@%@", iTMSPrefix, album, album, iTMSSuffix];
                [completedAlbum appendString: storeLink];
            }
            else {
                [completedAlbum appendString: album];
            }
        }
        if(albumSuffix)
            [completedAlbum appendString: albumSuffix];
    }
    
    if(includeEmpty || track) {
        if(trackPrefix)
            [completedTrack appendString: trackPrefix];
        if(track) {
            if(iTMSLink) {
                NSString *storeLink = [NSString stringWithFormat: @"%@%@\">%@%@", iTMSPrefix, track, track, iTMSSuffix];
                [completedTrack appendString: storeLink];
            }
            else {
                [completedTrack appendString: track];
            }
        }
        if(trackSuffix)
            [completedTrack appendString: trackSuffix];
    }
    
    if([completedAlbum length] == 0) completedAlbum = nil;
    if([completedArtist length] == 0) completedArtist = nil;
    if([completedTrack length] == 0) completedTrack = nil;
    
    orderingArray = [self orderingForOrderingType: ordering
                                       withArtist: completedArtist
                                            album: completedAlbum
                                            track: completedTrack];

    for(i = 0; i < [orderingArray count]; i++) {
        item = [orderingArray objectAtIndex: i];
        if([item isEqualToNumber: ARTIST]) {
            [data appendString: completedArtist];
            if(i+1 < [orderingArray count]) {
                [data appendString: separator];
            }
        }
        else if([item isEqualToNumber: ALBUM]) {
            [data appendString: completedAlbum];
            if(i+1 < [orderingArray count]) {
                [data appendString: separator];
            }
        }
        else if([item isEqualToNumber: TRACK]) {
            [data appendString: completedTrack];
            if(i+1 < [orderingArray count]) {
                [data appendString: separator];
            }
        }
    }
    if(!iTMSLink)
        return [data autorelease];
    else 
        //return [NSString stringWithFormat: @"<img src=\"http://ax.phobos.apple.com.edgesuite.net/images/iTunes.gif\"> - %@", [data autorelease]];
        return [NSString stringWithFormat: @"%@%@%@", [XJPreferences iTMSLinkPrefix], [data autorelease], [XJPreferences iTMSLinkSuffix]];
}

+ (NSString *)musicStringWithUserDefaultsForArtist: (NSString *)artist
                                             album: (NSString *)album
                                             track: (NSString *)track
                                          iTMSLink: (BOOL)itms
{
    NSString *result;
    result =  [[MusicStringFormatter musicStringWithArtist: artist
                                                               album: album
                                                               track: track
                                                        artistPrefix: [PREFS stringForKey: PREFS_MUSIC_ARTIST_PREFIX]
                                                        artistSuffix: [PREFS stringForKey: PREFS_MUSIC_ARTIST_SUFFIX]
                                                         trackPrefix: [PREFS stringForKey: PREFS_MUSIC_TRACK_PREFIX]
                                                         trackSuffix: [PREFS stringForKey: PREFS_MUSIC_TRACK_SUFFIX]
                                                         albumPrefix: [PREFS stringForKey: PREFS_MUSIC_ALBUM_PREFIX]
                                                         albumSuffix: [PREFS stringForKey: PREFS_MUSIC_ALBUM_SUFFIX]
                                                               order: [PREFS integerForKey: PREFS_MUSIC_ORDERING]
                                                        includeEmpty: [PREFS boolForKey: PREFS_MUSIC_INCLUDE_EMPTY]
                                                           separator: [PREFS objectForKey: PREFS_MUSIC_SEPARATOR]
                                                  iTMSLink: itms] retain];
    return [result autorelease];
}

+ (NSString *)detectMusicAndFormat: (BOOL)withITMSLink
{
    NSDictionary *data = [self detectMusic];
    NSString
        *artist = [data objectForKey: @"artist"], 
        *album = [data objectForKey: @"album"],
        *track = [data objectForKey: @"track"];
    
    if(artist || album || track)
        return [self musicStringWithUserDefaultsForArtist: artist album: album track: track iTMSLink: withITMSLink];
    else
        return nil;
}

// Returns {artist, ablum, track}
+ (NSDictionary *)detectMusic
{
    if([self iTunesIsRunning] && [self iTunesIsPlaying]) {
        NSString *getTrackScript = @"tell application \"iTunes\" to name of current track";
        NSString *getArtistScript = @"tell application \"iTunes\" to artist of current track";
        NSString *getAlbumScript = @"tell application \"iTunes\" to album of current track";
        NSAppleEventDescriptor *result;
        NSAppleScript *script;
        NSDictionary *info;
        
        NSString *artist, *album, *track;
        
        script = [[NSAppleScript alloc] initWithSource: getTrackScript];
        result = [script executeAndReturnError: &info];
        track = [[result stringValue] copy];
        [script release];
        
        script = [[NSAppleScript alloc] initWithSource: getArtistScript];
        result = [script executeAndReturnError: &info];
        artist = [[result stringValue] copy];
        [script release];
        
        script = [[NSAppleScript alloc] initWithSource: getAlbumScript];
        result = [script executeAndReturnError: &info];
        album = [[result stringValue] copy];
        [script release];

        return [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: artist, album, track, nil] forKeys: [NSArray arrayWithObjects: @"artist", @"album", @"track", nil]];
    }
    return nil;
}
@end

@implementation MusicStringFormatter (Private)
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

+ (NSArray *) orderingForOrderingType: (int)type withArtist: (NSString *)artist album:(NSString *)album track: (NSString *)track
{
    NSMutableArray * ordering = [NSMutableArray arrayWithCapacity: 3];
    switch(type) {
        case 0:
            if(track) { [ordering addObject: TRACK]; }
            break;
        case 1:
            if(artist) { [ordering addObject: ARTIST]; }
            break;
        case 2:
            if(album) { [ordering addObject: ALBUM]; }
            break;
        case 3:
            if(track) { [ordering addObject: TRACK]; }
            if(album) { [ordering addObject: ALBUM]; }
            break;
        case 4:
            if(album) { [ordering addObject: ALBUM]; }
            if(track) { [ordering addObject: TRACK]; }
            break;
        case 5:
            if(track) { [ordering addObject: TRACK]; }
            if(artist) { [ordering addObject: ARTIST]; }
            break;
        case 6:
            if(artist) { [ordering addObject: ARTIST]; }
            if(track) { [ordering addObject: TRACK]; }
            break;
        case 7:
            if(artist) { [ordering addObject: ARTIST]; }
            if(album) { [ordering addObject: ALBUM]; }
            break;
        case 8:
            if(album) { [ordering addObject: ALBUM]; }
            if(artist) { [ordering addObject: ARTIST]; }
            break;
        case 9:
            if(album) { [ordering addObject: ALBUM]; }
            if(artist) { [ordering addObject: ARTIST]; }
            if(track) { [ordering addObject: TRACK]; }
            break;
        case 10:
            if(album) { [ordering addObject: ALBUM]; }
            if(track) { [ordering addObject: TRACK]; }
            if(artist) { [ordering addObject: ARTIST]; }
            break;
        case 11:
            if(artist) { [ordering addObject: ARTIST]; }
            if(album) { [ordering addObject: ALBUM]; }
            if(track) { [ordering addObject: TRACK]; }
            break;
        case 12:
            if(artist) { [ordering addObject: ARTIST]; }
            if(track) { [ordering addObject: TRACK]; }
            if(album) { [ordering addObject: ALBUM]; }
            break;
        case 13:
            if(track) { [ordering addObject: TRACK]; }
            if(album) { [ordering addObject: ALBUM]; }
            if(artist) { [ordering addObject: ARTIST]; }
            break;
        case 14:
            if(track) { [ordering addObject: TRACK]; }
            if(artist) { [ordering addObject: ARTIST]; }
            if(album) { [ordering addObject: ALBUM]; }
            break;
        default:
            return nil;
    }
    return ordering;
}
@end