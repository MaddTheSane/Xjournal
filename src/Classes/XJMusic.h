//
//  XJMusic.h
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJMusic : NSObject

@property (copy) NSString *name;
@property (copy) NSString *album;
@property (copy) NSString *artist;
@property int rating;

// If iTunes is playing, returns a configured XJMusic object
// If iTunes is not playing, returns nil;
+ (XJMusic *)currentMusic;
+ (XJMusic *)musicAsiTunesLink: (XJMusic *)aMusic;

- (instancetype)initWithName: (NSString *)aName album: (NSString *)anAlbum artist: (NSString *)anArtist rating: (int)aRating NS_DESIGNATED_INITIALIZER;

@end
