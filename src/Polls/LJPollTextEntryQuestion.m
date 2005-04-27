//
//  LJPollTextEntryQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollTextEntryQuestion.h"


@implementation LJPollTextEntryQuestion

+ (LJPollTextEntryQuestion *)textEntryQuestionWithSize: (int)theSize maxLength: (int)theLength
{
    LJPollTextEntryQuestion *teQ = [[LJPollTextEntryQuestion alloc] init];
    [teQ setQuestion: @"Text Question"];
    [teQ setSize: theSize];
    [teQ setMaxLength: theLength];

    return [teQ autorelease];
}

- (int)size
{
    return size;
}

- (void)setSize:(int)newSize
{
    size = newSize;
}

- (int)maxLength
{
    return maxLength;
}

- (void)setMaxLength: (int)newMaxLength
{
    maxLength = newMaxLength;
}

- (NSString *)htmlRepresentation
{
    return [NSString stringWithFormat: @"<lj-pq type=\"text\" size=\"%d\" maxlength=\"%d\">%@</lj-pq>", size, maxLength, theQuestion];
}

// Memento
- (NSDictionary *) memento
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject: [[self question] copy] forKey: @"LJPollQuestion"];
    [dictionary setObject: [NSNumber numberWithInt: [self size]] forKey: @"LJPollTextSize"];
    [dictionary setObject: [NSNumber numberWithInt: [self maxLength]] forKey: @"LJPollTextLength"];

    return dictionary;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    [self setQuestion: [memento objectForKey: @"LJPollQuestion"]];
    [self setSize: [[memento objectForKey: @"LJPollTextSize"] intValue]];
    [self setMaxLength: [[memento objectForKey: @"LJPollTextLength"] intValue]];
}

// ----------------------------------------------------------------------------------------
// NSCoding
// ----------------------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject: [NSNumber numberWithInt: maxLength] forKey:@"LJPollTextLength"];
        [encoder encodeObject: [NSNumber numberWithInt: size] forKey:@"LJPollTextSize"];

        [encoder encodeObject: [self question] forKey:@"LJPollQuestion"];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"LJKit requires keyed coding."];
    }
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        [self setQuestion: [decoder decodeObjectForKey:@"LJPollQuestion"]];

        maxLength = [[decoder decodeObjectForKey: @"LJPollTextLength"] intValue];
        size = [[decoder decodeObjectForKey: @"LJPollTextSize"] intValue];
    }
    return self;
}
@end
