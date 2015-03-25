//
//  XJMusic.h
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJMusic : NSObject
@property (copy, nullable) NSString *name;
@property (copy, nullable) NSString *album;
@property (copy, nullable) NSString *artist;
@property int rating;

// If iTunes is playing, returns a configured XJMusic object
// If iTunes is not playing, returns nil;
+ (nonnull XJMusic *)currentMusic;
+ (nonnull XJMusic *)musicAsiTunesLink: (nonnull XJMusic *)aMusic;

- (nullable instancetype)initWithName: (nullable NSString *)aName album: (nullable NSString *)anAlbum artist: (nullable NSString *)anArtist rating: (int)aRating NS_DESIGNATED_INITIALIZER;

@end
