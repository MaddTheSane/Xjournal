//
//  XJMusicPrefClient.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Feb 13 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJMusicPrefClient.h"
#import <OmniAppKit/OmniAppKit.h>
#import "XJPreferences.h"
#import "MusicStringFormatter.h"

@interface XJMusicPrefClient (PrivateAPI)
- (void)updateExample;
- (NSString *)nullCheck:(NSString *)test;
@end

@implementation XJMusicPrefClient
- (void)setValueForSender:(id)sender
{
    if([sender isEqualTo: artistPrefix])
        [defaults setObject: [sender stringValue] forKey: PREFS_MUSIC_ARTIST_PREFIX];

    else if([sender isEqualTo: artistSuffix])
        [defaults setObject: [sender stringValue] forKey: PREFS_MUSIC_ARTIST_SUFFIX];

    else if([sender isEqualTo: albumPrefix])
        [defaults setObject: [sender stringValue] forKey: PREFS_MUSIC_ALBUM_PREFIX];

    else if([sender isEqualTo: albumSuffix])
        [defaults setObject: [sender stringValue] forKey: PREFS_MUSIC_ALBUM_SUFFIX];
    
    else if([sender isEqualTo: trackPrefix])
        [defaults setObject: [sender stringValue] forKey: PREFS_MUSIC_TRACK_PREFIX];

    else if([sender isEqualTo: trackSuffix])
        [defaults setObject: [sender stringValue] forKey: PREFS_MUSIC_TRACK_SUFFIX];
    
    else if([sender isEqualTo: fieldSeparator])
        [defaults setObject: [sender stringValue] forKey: PREFS_MUSIC_SEPARATOR];

    else if([sender isEqualTo: includeMissing])
        [defaults setBool: [sender state] forKey: PREFS_MUSIC_INCLUDE_EMPTY];

    else if([sender isEqualTo: ordering])
        [defaults setInteger: [[sender selectedItem] tag] forKey: PREFS_MUSIC_ORDERING];

    else if([sender isEqualTo: iTMSPrefix])
        [defaults setObject: [sender stringValue] forKey: ITMS_LINK_PREFIX];
    
	else if([sender isEqualTo: iTMSSuffix])
        [defaults setObject: [sender stringValue] forKey: ITMS_LINK_SUFFIX];
	
    else {
        int tag = [[sender selectedCell] tag];
        [defaults setBool: tag forKey: LINK_MUSIC_TO_STORE];
    }
    [self updateExample];
}

- (void)updateUI
{
    [artistPrefix setStringValue: [self nullCheck: [defaults stringForKey: PREFS_MUSIC_ARTIST_PREFIX]]];
    [artistSuffix setStringValue: [self nullCheck: [defaults stringForKey: PREFS_MUSIC_ARTIST_SUFFIX]]];

    [albumPrefix setStringValue: [self nullCheck: [defaults stringForKey: PREFS_MUSIC_ALBUM_PREFIX]]];
    [albumSuffix setStringValue: [self nullCheck: [defaults stringForKey: PREFS_MUSIC_ALBUM_SUFFIX]]];

    [trackPrefix setStringValue: [self nullCheck: [defaults stringForKey: PREFS_MUSIC_TRACK_PREFIX]]];
    [trackSuffix setStringValue: [self nullCheck: [defaults stringForKey: PREFS_MUSIC_TRACK_SUFFIX]]];

    [ordering selectItemWithTag: [defaults integerForKey: PREFS_MUSIC_ORDERING]];

    [fieldSeparator setStringValue: [self nullCheck: [defaults stringForKey: PREFS_MUSIC_SEPARATOR]]];

    [iTMSPrefix setStringValue: [self nullCheck: [defaults stringForKey: ITMS_LINK_PREFIX]]];
    [iTMSSuffix setStringValue: [self nullCheck: [defaults stringForKey: ITMS_LINK_SUFFIX]]];
	
    [iTMSMatrix selectCellWithTag: [defaults boolForKey: LINK_MUSIC_TO_STORE]];
    
    [self updateExample];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    [self updateExample];
}

@end

@implementation XJMusicPrefClient (PrivateAPI)
- (NSString *)nullCheck:(NSString *)test
{
    if(test != nil)
        return test;
    else
        return @"";
}

- (void)updateExample
{
    NSString *exampleString = [MusicStringFormatter musicStringWithArtist: @"TheArtist"
                                                              album: @"TheAlbum"
                                                              track: @"TheTrack"
                                                       artistPrefix: [artistPrefix stringValue]
                                                       artistSuffix: [artistSuffix stringValue]
                                                        trackPrefix: [trackPrefix stringValue]
                                                        trackSuffix: [trackSuffix stringValue]
                                                        albumPrefix: [albumPrefix stringValue]
                                                        albumSuffix: [albumSuffix stringValue]
                                                              order: [[ordering selectedItem] tag]
                                                       includeEmpty: [includeMissing state]
                                                          separator: [fieldSeparator stringValue]
                                                                 iTMSLink: NO];
    [example setStringValue: exampleString];
}
@end