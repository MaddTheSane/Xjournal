//
//  XJMusic.h
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJMusic : NSObject {
	NSString *name;
	NSString *album;
	NSString *artist;
	int rating;
}

// If iTunes is playing, returns a configured XJMusic object
// If iTunes is not playing, returns nil;
+ (XJMusic *)currentMusic;
+ (XJMusic *)musicAsiTunesLink: (XJMusic *)aMusic;

- (id)initWithName: (NSString *)aName album: (NSString *)anAlbum artist: (NSString *)anArtist rating: (int)aRating;

- (NSString *)name;
- (void)setName:(NSString *)aName;

- (NSString *)album;
- (void)setAlbum:(NSString *)anAlbum;

- (NSString *)artist;
- (void)setArtist:(NSString *)anArtist;

- (int)rating;
- (void)setRating:(int)aRating;
@end
